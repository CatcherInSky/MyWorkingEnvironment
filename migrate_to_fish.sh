#!/usr/bin/env bash
# Migrates PATH entries and exported variables from bash/zsh configs to fish.
#
# Strategy:
#   - PATH:        compare clean-shell PATH vs sourced-shell PATH; add new entries
#                  via fish_add_path (idempotent, writes to $fish_user_paths)
#   - Other vars:  extract names from explicit `export` lines, evaluate their
#                  actual expanded values in a bash/zsh subprocess, write set -gx
#                  to config.fish (skips vars already present)
#   - Default shell: change default login shell to fish via chsh

set -uo pipefail

FISH_CONFIG="${HOME}/.config/fish/config.fish"
RC_FILES=()

# Collect config files from multiple shells: bash, zsh, and others
for f in \
  "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile" \
  "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.zshenv" \
  "$HOME/.config/bash/bashrc"; do
  [ -f "$f" ] && RC_FILES+=("$f")
done

# Shell internals and system vars we never want to copy
SKIP_VARS=(
  PWD SHLVL _ BASH BASH_VERSION BASH_VERSINFO
  SHELL TERM TERM_PROGRAM TERM_PROGRAM_VERSION
  USER HOME LOGNAME MAIL OLDPWD
  PS1 PS2 PS3 PS4 IFS LINENO COLUMNS LINES
  HISTFILE HISTSIZE HISTFILESIZE HISTCONTROL HISTIGNORE
  LS_COLORS
)

info()  { printf "[INFO] %s\n" "$1"; }
warn()  { printf "[WARN] %s\n" "$1"; }
error_exit() { printf "[ERROR] %s\n" "$1" >&2; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

is_skip_var() {
  local var="$1"
  for skip in "${SKIP_VARS[@]}"; do
    [ "$var" = "$skip" ] && return 0
  done
  [[ "$var" =~ ^(LC_|XDG_|DBUS_|SSH_|SUDO_) ]] && return 0
  return 1
}

# Build `source FILE; source FILE; ...` string for bash/zsh -c
build_source_cmd() {
  local src=""
  for f in "${RC_FILES[@]}"; do
    src+="source '$f' 2>/dev/null || true; "
  done
  echo "$src"
}

# Detect which shell to use for sourcing (prefer zsh if available, fallback to bash)
detect_shell_for_sourcing() {
  if command -v zsh >/dev/null 2>&1; then
    echo "zsh"
  else
    echo "bash"
  fi
}

# Single-quote a value for fish: replace ' with '\''
fish_single_quote() {
  local val="${1//\'/\'\\\'\'}"
  echo "'${val}'"
}

migrate_path() {
  info "迁移 PATH 条目"
  
  [ ${#RC_FILES[@]} -eq 0 ] && { info "  未找到任何配置文件，跳过"; return; }
  
  local shell_to_use
  shell_to_use=$(detect_shell_for_sourcing)
  local src
  src=$(build_source_cmd)

  local base_path full_path
  base_path=$(env -i HOME="$HOME" "$shell_to_use" --norc -c 'echo "$PATH"' 2>/dev/null)
  full_path=$(env -i HOME="$HOME" "$shell_to_use" --norc -c "${src} echo \"\$PATH\"" 2>/dev/null)

  [ -z "$full_path" ] && { info "  未获取到 PATH，跳过"; return; }
  
  local full_parts=()
  IFS=':' read -ra full_parts <<< "$full_path"
  [ ${#full_parts[@]} -eq 0 ] && { info "  未发现新的 PATH 条目"; return; }
  
  for p in "${full_parts[@]}"; do
    [[ -z "$p" || ":${base_path}:" == *":${p}:"* ]] && continue
    [ -d "$p" ] || { info "  跳过（目录不存在）: $p"; continue; }
    fish -c "fish_add_path $(fish_single_quote "$p")" 2>/dev/null \
      && info "  fish_add_path $p" \
      || warn "  添加失败: $p"
  done
}

migrate_env_vars() {
  info "迁移 export 变量"
  mkdir -p "$(dirname "$FISH_CONFIG")"
  touch "$FISH_CONFIG"

  [ ${#RC_FILES[@]} -eq 0 ] && { info "  未找到任何配置文件，跳过"; return; }

  local shell_to_use
  shell_to_use=$(detect_shell_for_sourcing)
  local src
  src=$(build_source_cmd)

  # Collect variable names from explicit `export VAR=` lines
  local var_names=()
  for rc in "${RC_FILES[@]}"; do
    while IFS= read -r line; do
      line="${line%%#*}"  # strip inline comments
      if [[ "$line" =~ ^[[:space:]]*export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)= ]]; then
        local vname="${BASH_REMATCH[1]}"
        is_skip_var "$vname" && continue
        var_names+=("$vname")
      fi
    done < "$rc"
  done

  [ ${#var_names[@]} -eq 0 ] && { info "  未发现需要迁移的变量"; return; }

  # Deduplicate
  local unique_vars
  IFS=$'\n' read -r -d '' -a unique_vars < <(printf '%s\n' "${var_names[@]}" | sort -u && printf '\0')

  for var in "${unique_vars[@]}"; do
    [ "$var" = "PATH" ] && continue  # handled by migrate_path

    # Get expanded value by sourcing rc files in the detected shell subprocess
    local value
    value=$(env -i HOME="$HOME" "$shell_to_use" --norc -c "${src} printf '%s' \"\${${var}:-}\"" 2>/dev/null) || continue
    [ -z "$value" ] && continue

    local fish_line="set -gx ${var} $(fish_single_quote "$value")"

    # Skip if already present in config.fish
    if grep -Fxq "$fish_line" "$FISH_CONFIG" 2>/dev/null; then
      info "  已存在，跳过: $var"
      continue
    fi

    printf '%s\n' "$fish_line" >> "$FISH_CONFIG"
    info "  写入 config.fish: $var"
  done
}

set_default_shell() {
  info "设置默认 shell 为 fish"
  
  local fish_path
  fish_path=$(command -v fish)
  
  if [ -z "$fish_path" ]; then
    warn "fish 命令未找到，无法设置默认 shell"
    return 1
  fi
  
  local current_shell
  current_shell=$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}' || echo "$SHELL")
  
  if [ "$current_shell" == "$fish_path" ]; then
    info "默认 shell 已是 fish，无需修改"
    return 0
  fi
  
  # First, ensure fish is in /etc/shells
  if ! grep -q "^${fish_path}$" /etc/shells 2>/dev/null; then
    info "添加 $fish_path 到 /etc/shells"
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || warn "无法添加 fish 到 /etc/shells，可能需要手动操作"
  fi
  
  # Try to change the default shell using chsh
  if command -v chsh >/dev/null 2>&1; then
    chsh -s "$fish_path" 2>/dev/null \
      && info "✓ 默认 shell 已设置为: $fish_path" \
      || { warn "无法使用 chsh 修改默认 shell，请手动运行: chsh -s $fish_path"; return 1; }
  else
    warn "chsh 命令未找到，无法修改默认 shell"
    return 1
  fi
}

init_zoxide_for_fish() {
  command_exists zoxide || return 0
  
  if grep -Fxq "zoxide init fish | source" "$FISH_CONFIG" 2>/dev/null; then
    info "✓ zoxide 已配置"
    return 0
  fi
  
  local FISH_COMPLETIONS="${HOME}/.config/fish/completions"
  mkdir -p "$FISH_COMPLETIONS"
  
  printf '\n# Zoxide initialization\nzoxide init fish | source\nalias cd z\n' >> "$FISH_CONFIG"
  info "✓ zoxide 已配置"
}

init_atuin_for_fish() {
  command_exists atuin || return 0
  
  if grep -Fxq "atuin init fish | source" "$FISH_CONFIG" 2>/dev/null; then
    info "✓ atuin 已配置"
    return 0
  fi
  
  printf '\n# Atuin initialization\natuin init fish | source\n' >> "$FISH_CONFIG"
  info "✓ atuin 已配置"
}

main() {
  command_exists fish || { error_exit "fish 未安装，请先安装 fish shell"; }

  info "====== 开始迁移至 Fish Shell ======"
  info ""
  
  # If we have config files, migrate them
  if [ ${#RC_FILES[@]} -gt 0 ]; then
    info "发现配置文件：${RC_FILES[*]}"
    info "开始迁移..."
    info ""
    migrate_path
    info ""
    migrate_env_vars
    info ""
  else
    info "未找到 bash/zsh 配置文件"
    info "如需手动配置，请："
    info "  1. 在 fish 中运行: fish_add_path /your/custom/path"
    info "  2. 或在 ~/.config/fish/config.fish 中添加: set -gx VAR_NAME value"
    info ""
    mkdir -p "$(dirname "$FISH_CONFIG")"
    touch "$FISH_CONFIG"
    info "✓ fish 配置文件已创建: $FISH_CONFIG"
    info ""
  fi
  
  # Initialize terminal tools for fish
  info "验证终端工具配置"
  if command_exists zoxide; then
    init_zoxide_for_fish || warn "zoxide 配置失败"
  else
    warn "zoxide 未安装，若需要请先运行 install.sh"
  fi
  
  if command_exists atuin; then
    init_atuin_for_fish || warn "atuin 配置失败"
  else
    warn "atuin 未安装（可选工具）"
  fi
  info ""
  
  # Set fish as default shell
  set_default_shell
  info ""
  
  info "====== 迁移完成 ======"
  info ""
  info "✓ fish 已配置完成"
  info ""
  info "下一步操作："
  info "  1. 切换 shell：exec fish"
  info "  2. 验证配置：cd / && z / && nvim"
  info "  3. 如需撤销变量，运行：set -e VAR_NAME"
  info ""

main "$@"
