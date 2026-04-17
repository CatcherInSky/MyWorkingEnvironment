#!/usr/bin/env bash
# Migrates PATH entries and exported variables from bash configs to fish.
#
# Strategy:
#   - PATH:        compare clean-bash PATH vs sourced-bash PATH; add new entries
#                  via fish_add_path (idempotent, writes to $fish_user_paths)
#   - Other vars:  extract names from explicit `export` lines, evaluate their
#                  actual expanded values in a bash subprocess, write set -gx
#                  to config.fish (skips vars already present)

set -uo pipefail

FISH_CONFIG="${HOME}/.config/fish/config.fish"
RC_FILES=()
for f in "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"; do
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
command_exists() { command -v "$1" >/dev/null 2>&1; }

is_skip_var() {
  local var="$1"
  for skip in "${SKIP_VARS[@]}"; do
    [ "$var" = "$skip" ] && return 0
  done
  [[ "$var" =~ ^(LC_|XDG_|DBUS_|SSH_|SUDO_) ]] && return 0
  return 1
}

# Build `source FILE; source FILE; ...` string for bash -c
build_source_cmd() {
  local src=""
  for f in "${RC_FILES[@]}"; do
    src+="source '$f' 2>/dev/null || true; "
  done
  echo "$src"
}

# Single-quote a value for fish: replace ' with '\''
fish_single_quote() {
  local val="${1//\'/\'\\\'\'}"
  echo "'${val}'"
}

migrate_path() {
  info "迁移 PATH 条目"
  local src
  src=$(build_source_cmd)

  local base_path full_path
  base_path=$(env -i HOME="$HOME" bash --norc -c 'echo "$PATH"' 2>/dev/null)
  full_path=$(env -i HOME="$HOME" bash --norc -c "${src} echo \"\$PATH\"" 2>/dev/null)

  IFS=':' read -ra full_parts <<< "$full_path"
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

    # Get expanded value by sourcing rc files in bash subprocess
    local value
    value=$(env -i HOME="$HOME" bash --norc -c "${src} printf '%s' \"\${${var}:-}\"" 2>/dev/null) || continue
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

main() {
  command_exists fish || { warn "fish 未安装，请先安装 fish shell"; exit 1; }

  if [ ${#RC_FILES[@]} -eq 0 ]; then
    warn "未找到 bash 配置文件（~/.bashrc, ~/.bash_profile, ~/.profile）"
    exit 1
  fi

  info "从以下文件迁移：${RC_FILES[*]}"
  migrate_path
  migrate_env_vars
  info "迁移完成。请重启终端或运行 exec fish 使更改生效。"
  info "如需撤销某个变量，在 fish 中运行: set -e VAR_NAME"
}

main "$@"
