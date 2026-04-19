#!/usr/bin/env bash
set -euo pipefail

USER_HOME="${HOME:-$(pwd)}"

info()       { printf "[INFO] %s\n" "$1"; }
warn()       { printf "[WARN] %s\n" "$1"; }
error_exit() { printf "[ERROR] %s\n" "$1" >&2; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

# --- Shared tool installers ---

install_starship() {
  command_exists starship && { info "✓ Starship 已安装，跳过"; return; }
  info "安装 Starship"

  # Try package manager first on Linux
  if [[ "$(uname -s)" == "Linux" ]]; then
    if command_exists apt-get && apt-cache show starship >/dev/null 2>&1; then
      sudo apt-get update -q && sudo apt-get install -y starship && { info "✓ Starship 已通过 apt 安装"; return; }
    elif command_exists snap; then
      sudo snap install starship --classic && { info "✓ Starship 已通过 snap 安装"; return; }
    fi
  fi

  # Fallback to official installer
  if curl -sS https://starship.rs/install.sh | sh; then
    info "✓ Starship 已通过官方脚本安装"
  else
    warn "Starship 安装失败: 官方脚本执行出错"
    return 1
  fi

  # 创建配置文件
  mkdir -p "${USER_HOME}/.config"
  [ ! -f "${USER_HOME}/.config/starship.toml" ] && \
    curl -sS https://raw.githubusercontent.com/starship/starship/master/starship.toml -o "${USER_HOME}/.config/starship.toml"
  info "✓ Starship 配置文件: ~/.config/starship.toml"
}

install_zoxide() {
  command_exists zoxide && { info "✓ zoxide 已安装，跳过"; return; }
  info "安装 zoxide"

  # Try package manager first
  if [[ "$(uname -s)" == "Linux" ]]; then
    if command_exists apt-get && apt-cache show zoxide >/dev/null 2>&1; then
      sudo apt-get update -q && sudo apt-get install -y zoxide && { info "✓ zoxide 已通过 apt 安装"; return; }
    fi
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    if command_exists brew; then
      brew install zoxide && { info "✓ zoxide 已通过 brew 安装"; return; }
    fi
  fi

  # Fallback to official installer
  if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
    info "✓ zoxide 已通过官方脚本安装"
  else
    warn "zoxide 安装失败: 官方脚本执行出错"
    return 1
  fi
}

init_zoxide_for_fish() {
  command_exists fish || { info "  fish 未安装，跳过 zoxide fish 配置"; return 0; }
  command_exists zoxide || { info "  zoxide 未安装，跳过"; return 0; }

  local FISH_CONFIG="${USER_HOME}/.config/fish/config.fish"
  local FISH_COMPLETIONS="${USER_HOME}/.config/fish/completions"

  mkdir -p "$(dirname "$FISH_CONFIG")" "$FISH_COMPLETIONS"
  touch "$FISH_CONFIG"

  # 检查是否已配置
  if grep -Fxq "zoxide init fish | source" "$FISH_CONFIG" 2>/dev/null; then
    info "✓ zoxide 已配置到 fish（跳过）"
    return 0
  fi

  printf '\n# Zoxide initialization\nzoxide init fish | source\nalias cd z\n' >> "$FISH_CONFIG"
  info "✓ zoxide 已配置到 fish"
}

install_yazi() {
  command_exists yazi && return
  info "安装 yazi"

  case "$(uname -m)" in
    x86_64)         arch="x86_64" ;;
    aarch64|arm64)  arch="aarch64" ;;
    *) warn "未知架构，跳过 yazi"; return ;;
  esac

  local version
  version=$(curl -fsSL "https://api.github.com/repos/sxyazi/yazi/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
  [ -z "$version" ] && { warn "无法获取 yazi 版本，跳过"; return; }

  local os_name
  case "$(uname -s)" in
    Linux)  os_name="linux" ;;
    Darwin) os_name="macos" ;;
    *)  warn "不支持的操作系统，跳过 yazi"; return ;;
  esac

  info "从 release 下载 yazi v${version}"
  curl -fsSL "https://github.com/sxyazi/yazi/releases/download/v${version}/yazi-${arch}-unknown-${os_name}.zip" \
    -o /tmp/yazi.zip 2>/dev/null || { warn "下载失败，跳过 yazi"; return; }

  unzip -o /tmp/yazi.zip -d /tmp 2>/dev/null || { warn "解压失败，跳过 yazi"; rm -f /tmp/yazi.zip; return; }

  if [ -f "/tmp/yazi" ]; then
    mkdir -p "${USER_HOME}/.local/bin"
    mv /tmp/yazi "${USER_HOME}/.local/bin/yazi"
    chmod +x "${USER_HOME}/.local/bin/yazi"
    info "✓ yazi 已安装"
  else
    warn "无法找到 yazi 可执行文件，跳过"
  fi

  rm -f /tmp/yazi.zip /tmp/yazi-${arch}-unknown-${os_name} 2>/dev/null
}

install_atuin() {
  command_exists atuin && { info "✓ atuin 已安装，跳过"; return; }
  info "安装 atuin"

  # Try package manager first
  if [[ "$(uname -s)" == "Linux" ]]; then
    if command_exists apt-get && apt-cache show atuin >/dev/null 2>&1; then
      sudo apt-get update -q && sudo apt-get install -y atuin && { info "✓ atuin 已通过 apt 安装"; return; }
    fi
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    if command_exists brew; then
      brew install atuin && { info "✓ atuin 已通过 brew 安装"; return; }
    fi
  fi

  # Fallback to official installer
  if curl -fsSL https://setup.atuin.sh | bash; then
    info "✓ atuin 已通过官方脚本安装"
  else
    warn "atuin 安装失败: 官方脚本执行出错"
    return 1
  fi
}

init_atuin_for_fish() {
  command_exists fish || { info "  fish 未安装，跳过 atuin fish 配置"; return 0; }
  command_exists atuin || { info "  atuin 未安装，跳过"; return 0; }

  local FISH_CONFIG="${USER_HOME}/.config/fish/config.fish"

  mkdir -p "$(dirname "$FISH_CONFIG")"
  touch "$FISH_CONFIG"

  # 检查是否已配置
  if grep -Fxq "atuin init fish | source" "$FISH_CONFIG" 2>/dev/null; then
    info "✓ atuin 已配置到 fish（跳过）"
    return 0
  fi

  printf '\n# Atuin initialization\natuin init fish | source\n' >> "$FISH_CONFIG"
  info "✓ atuin 已配置到 fish"
  info "  提示：运行 'atuin account register' 或 'atuin account login' 来启用云同步"
}

install_nvm() {
  [ -d "${USER_HOME}/.nvm" ] && { info "✓ nvm 已安装，跳过"; return; }
  info "安装 nvm"

  # Try package manager first on Linux
  if [[ "$(uname -s)" == "Linux" ]]; then
    if command_exists apt-get && apt-cache show nodejs >/dev/null 2>&1; then
      sudo apt-get update -q && sudo apt-get install -y nodejs npm && { info "✓ Node.js 和 npm 已通过 apt 安装，nvm 可选"; return; }
    fi
  fi

  # Fallback to official installer
  local version
  version=$(curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"\(v[^"]*\)".*/\1/')
  if [ -z "$version" ]; then
    warn "无法获取 nvm 版本，跳过"
    return 1
  fi
  if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | bash; then
    info "✓ nvm 已通过官方脚本安装"
    export NVM_DIR="${USER_HOME}/.nvm"
    [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
  else
    warn "nvm 安装失败: 脚本执行出错"
    return 1
  fi
}

install_zvm() {
  command_exists zvm && { info "✓ zvm 已安装，跳过"; return; }
  info "安装 zvm (Zig Version Manager)"

  if curl -fsFL https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash; then
    info "✓ zvm 已通过官方脚本安装"
  else
    warn "zvm 安装失败: 脚本执行出错"
    return 1
  fi
}

install_npm_globals() {
  command_exists npm || { warn "npm 未安装，跳过全局包安装"; return; }
  info "安装全局 npm 包: pnpm yarn typescript tsx"
  npm install -g pnpm yarn typescript tsx 2>/dev/null || true
}

install_pipx() {
  command_exists pipx && { info "✓ pipx 已安装，跳过"; return; }
  command_exists python3 || { warn "python3 未找到，跳过 pipx"; return; }
  info "安装 pipx"

  # Try package manager first on Linux
  if [[ "$(uname -s)" == "Linux" ]] && command_exists apt-get && apt-cache show python3-pipx >/dev/null 2>&1; then
    sudo apt-get update -q && sudo apt-get install -y python3-pipx && { info "✓ pipx 已通过 apt 安装"; return; }
  fi

  # Fallback to pip
  if python3 -m pip install --user pipx 2>/dev/null; then
    info "✓ pipx 已通过 pip 安装"
    python3 -m pipx ensurepath 2>/dev/null || warn "pipx ensurepath 失败"
  else
    warn "pipx 安装失败: pip 安装出错"
    return 1
  fi
}

install_yt_dlp() {
  command_exists yt-dlp && { info "✓ yt-dlp 已安装，跳过"; return; }
  info "安装 yt-dlp"

  # Try package manager first
  if [[ "$(uname -s)" == "Linux" ]]; then
    if command_exists apt-get && apt-cache show yt-dlp >/dev/null 2>&1; then
      sudo apt-get update -q && sudo apt-get install -y yt-dlp && { info "✓ yt-dlp 已通过 apt 安装"; return; }
    fi
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    if command_exists brew; then
      brew install yt-dlp && { info "✓ yt-dlp 已通过 brew 安装"; return; }
    fi
  fi

  # Fallback to pipx or pip
  if command_exists pipx; then
    if pipx install yt-dlp; then
      info "✓ yt-dlp 已通过 pipx 安装"
    else
      warn "yt-dlp 通过 pipx 安装失败"
      return 1
    fi
  elif command_exists pip3; then
    if pip3 install --user yt-dlp; then
      info "✓ yt-dlp 已通过 pip3 安装"
    else
      warn "yt-dlp 通过 pip3 安装失败"
      return 1
    fi
  else
    warn "pipx/pip3 均未找到，跳过 yt-dlp"
    return 1
  fi
}

install_neovim() {
  command_exists nvim && { info "✓ Neovim 已安装，跳过"; return; }
  info "安装 Neovim"

  # Try package manager first
  if [[ "$(uname -s)" == "Linux" ]]; then
    if command_exists apt-get && apt-cache show neovim >/dev/null 2>&1; then
      sudo apt-get update -q && sudo apt-get install -y neovim && { info "✓ Neovim 已通过 apt 安装"; return; }
    fi
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    if command_exists brew; then
      brew install neovim && { info "✓ Neovim 已通过 brew 安装"; return; }
    fi
  fi

  # Fallback: assume Neovim is installed or warn
  warn "Neovim 未通过包管理器安装，请手动安装"
  return 1
}

install_lazyvim() {
  command_exists nvim || { warn "Neovim 未安装，无法安装 LazyVim"; return; }
  if ! command_exists git; then
    warn "git 未安装，尝试通过 Homebrew 安装 git"
    if command_exists brew; then
      if ! brew install git >/dev/null 2>&1; then
        warn "git 安装失败，无法继续安装 LazyVim"
        return
      fi
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"
    else
      warn "brew 未安装，无法安装 git"
      return
    fi
  fi

  if [ -d "${USER_HOME}/.config/nvim" ]; then
    if [ "$(ls -A "${USER_HOME}/.config/nvim")" != "" ]; then
      info "~/.config/nvim 已存在且非空，跳过 LazyVim 安装以避免覆盖现有配置"
      info "  如需安装 LazyVim，请手动备份并运行: git clone --depth 1 https://github.com/LazyVim/starter ~/.config/nvim"
      return
    fi
  fi

  mkdir -p "${USER_HOME}/.config"
  info "安装 LazyVim"
  local clone_err
  if ! clone_err=$(git clone --depth 1 https://github.com/LazyVim/starter "${USER_HOME}/.config/nvim" 2>&1); then
    warn "LazyVim 安装失败，检查网络或权限"
    warn "$clone_err"
    return
  fi

  rm -rf "${USER_HOME}/.config/nvim/.git" 2>/dev/null || true
  info "✓ LazyVim 已安装至 ~/.config/nvim"
  info "  首次启动 nvim 时将自动下载和配置插件"
}

init_lazyvim_for_fish() {
  command_exists fish || { info "  fish 未安装，跳过 Neovim 补全"; return 0; }
  command_exists nvim || { info "  nvim 未安装，跳过 Neovim 补全"; return 0; }

  local FISH_COMPLETIONS="${USER_HOME}/.config/fish/completions"
  mkdir -p "$FISH_COMPLETIONS"

  # 检查补全文件是否已存在
  if [ -f "$FISH_COMPLETIONS/nvim.fish" ]; then
    info "✓ Neovim 补全已存在（跳过）"
    return 0
  fi

  cat > "$FISH_COMPLETIONS/nvim.fish" << 'EOF'
# Neovim completions for fish
complete -c nvim -n "__fish_use_subcommand_from_list" -s c -l command -d "Execute command"
complete -c nvim -n "__fish_use_subcommand_from_list" -s d -l diff -d "Diff mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s e -l ex -d "Ex mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s E -d "Ex mode (no plugins)"
complete -c nvim -n "__fish_use_subcommand_from_list" -s h -l help -d "Show help"
complete -c nvim -n "__fish_use_subcommand_from_list" -s v -l version -d "Show version"
complete -c nvim -f
EOF

  info "✓ Neovim 补全已生成至: $FISH_COMPLETIONS/nvim.fish"
  info "  首次启动 nvim 时 LazyVim 将自动下载和配置插件"
}

# --- Linux ---

install_apt_base() {
  info "安装 apt 基础包"
  
  # Fix Yarn GPG key using modern method
  if [ -f /etc/apt/sources.list.d/yarn.list ]; then
    info "  修复 Yarn GPG 密钥"
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarn-keyring.gpg 2>/dev/null || true
    # Update the yarn.list to use signed-by
    sudo sed -i 's|^deb |deb [signed-by=/usr/share/keyrings/yarn-keyring.gpg] |' /etc/apt/sources.list.d/yarn.list 2>/dev/null || true
  fi
  
  sudo apt-get update -q || { warn "apt-get update 失败，继续安装"; }
  if sudo apt-get install -y git python3 python3-pip curl wget fish neovim ffmpeg nodejs npm; then
    info "✓ apt 基础包安装成功"
  else
    warn "部分 apt 包安装失败，继续"
  fi
}

install_lazygit_linux() {
  command_exists lazygit && { info "✓ lazygit 已安装，跳过"; return; }
  info "安装 lazygit"

  # 尝试使用官方脚本（推荐方法）
  if curl -s https://raw.githubusercontent.com/jesseduffield/lazygit/master/scripts/install_update_linux.sh | bash 2>/dev/null; then
    info "✓ lazygit 已通过官方脚本安装"
    return 0
  fi

  # 备选方案：从 release 下载
  local arch version
  case "$(uname -m)" in
    x86_64)         arch="x86_64" ;;
    aarch64|arm64)  arch="arm64" ;;
    *) warn "未知架构，跳过 lazygit"; return ;;
  esac

  version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
  [ -z "$version" ] && { warn "无法获取 lazygit 版本，跳过"; return; }

  info "从 release 下载 lazygit v${version}"
  if curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz" \
    | tar xz -C /tmp lazygit 2>/dev/null; then
    if sudo install /tmp/lazygit /usr/local/bin/lazygit 2>/dev/null; then
      info "✓ lazygit 已安装"
      rm -f /tmp/lazygit
    else
      warn "无法安装 lazygit，请检查权限"
      rm -f /tmp/lazygit
      return 1
    fi
  else
    warn "下载或解压失败，跳过 lazygit"
    return 1
  fi
}

install_gh_linux() {
  command_exists gh && { info "✓ GitHub CLI 已安装，跳过"; return; }
  info "安装 GitHub CLI"

  if curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt-get update -q \
    && sudo apt-get install -y gh; then
    info "✓ GitHub CLI 已安装"
  else
    warn "GitHub CLI 安装失败"
    return 1
  fi
}

install_linux() {
  install_apt_base
  install_gh_linux
  install_starship
  install_zoxide
  init_zoxide_for_fish
  install_lazygit_linux
  # install_yazi  # 暂时跳过
  install_atuin
  init_atuin_for_fish
  install_neovim
  install_lazyvim
  init_lazyvim_for_fish
  install_nvm
  install_zvm
  install_pipx
  install_yt_dlp
  install_npm_globals

  info ""
  info "✓ Linux 安装完成"
}

# --- macOS ---

install_brew_if_missing() {
  command_exists brew && return
  info "安装 Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"
}

install_macos() {
  install_brew_if_missing
  local formulas=(git fish starship zoxide lazygit neovim python node pnpm yarn pipx rustup gh ffmpeg yt-dlp atuin)  # yazi 暂时跳过
  # docker via cask = Docker Desktop (includes CLI); ghostty is the terminal emulator
  local casks=(docker copyq snipaste macs-fan-control scroll-reverser stats keyclu kap)  # ghostty 暂时跳过

  info "安装 Homebrew formulas"
  for pkg in "${formulas[@]}"; do
    pkg="${pkg:-}"
    if [ -z "$pkg" ]; then
      warn "brew formula 名称为空，跳过"
      continue
    fi

    if brew install "${pkg}" >/dev/null 2>&1; then
      info "  ✓ 已安装: $pkg"
    else
      warn "brew 无法安装 ${pkg}，跳过"
    fi
  done
  info "安装 Homebrew casks"
  for pkg in "${casks[@]}"; do
    pkg="${pkg:-}"
    if [ -z "$pkg" ]; then
      warn "brew cask 名称为空，跳过"
      continue
    fi

    if brew install --cask "${pkg}" >/dev/null 2>&1; then
      info "  ✓ 已安装: $pkg"
    else
      warn "brew cask 无法安装 ${pkg}，跳过"
    fi
  done

  install_starship
  install_zoxide
  init_zoxide_for_fish
  init_atuin_for_fish
  install_neovim
  install_lazyvim
  init_lazyvim_for_fish
  install_nvm
  install_zvm
  install_npm_globals

  info ""
  info "✓ macOS 安装完成"
}

# --- Windows ---

install_windows_pkg() {
  local id="$1"
  if ! command_exists powershell.exe; then
    warn "PowerShell 未找到，跳过 winget 安装: $id"
    return 1
  fi
  if powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -Command "winget install --id '$id' --exact --silent -e" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

install_windows() {
  info "安装 Windows 软件（通过 winget）"
  local pkgs=(
    "Git.Git"
    "hluk.CopyQ"
    "Snipaste.Snipaste"
    "NickeManarin.ScreenToGif"
    "TranslucentTB.TranslucentTB"
    "codeoverjoy.ImageGlass"
    "voidtools.Everything"
    "Flow-Launcher.Flow-Launcher"
    "AppWork.Gopeed"
  )
  for id in "${pkgs[@]}"; do
    if install_windows_pkg "$id"; then
      info "  ✓ 已安装: $id"
    else
      warn "  安装失败（请手动安装）: $id"
    fi
  done
}

# --- Migration to Fish ---

FISH_CONFIG="${USER_HOME}/.config/fish/config.fish"
RC_FILES=()

# Collect config files from multiple shells: bash, zsh, and others
for f in \
  "$USER_HOME/.bash_profile" "$USER_HOME/.bashrc" "$USER_HOME/.profile" \
  "$USER_HOME/.zshrc" "$USER_HOME/.zprofile" "$USER_HOME/.zshenv" \
  "$USER_HOME/.config/bash/bashrc"; do
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
  base_path=$(env -i HOME="$USER_HOME" "$shell_to_use" --norc -c 'echo "$PATH"' 2>/dev/null)
  full_path=$(env -i HOME="$USER_HOME" "$shell_to_use" --norc -c "${src} echo \"\$PATH\"" 2>/dev/null)

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
    value=$(env -i HOME="$USER_HOME" "$shell_to_use" --norc -c "${src} printf '%s' \"\${${var}:-}\"" 2>/dev/null) || continue
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

  # 在容器环境中跳过设置默认shell
  if [ -n "${CODESPACES:-}" ] || [ -n "${GITHUB_CODESPACE_TOKEN:-}" ] || [ -f /.dockerenv ]; then
    info "检测到容器环境，跳过设置默认 shell"
    info "请手动运行: chsh -s $fish_path"
    info "或在下次登录时使用: exec fish"
    return 0
  fi

  # First, ensure fish is in /etc/shells
  if ! grep -q "^${fish_path}$" /etc/shells 2>/dev/null; then
    info "添加 $fish_path 到 /etc/shells"
    echo "$fish_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || warn "无法添加 fish 到 /etc/shells，可能需要手动操作"
  fi

  # Try to change the default shell using chsh
  if command -v chsh >/dev/null 2>&1; then
    if chsh -s "$fish_path" 2>/dev/null; then
      info "✓ 默认 shell 已设置为: $fish_path"
    else
      warn "无法使用 chsh 修改默认 shell，请手动运行: chsh -s $fish_path"
      warn "或者在下次登录时使用: exec fish"
      return 1
    fi
  else
    warn "chsh 命令未找到，无法修改默认 shell"
    return 1
  fi
}

init_zoxide_for_fish_migrate() {
  command_exists zoxide || return 0

  if grep -Fxq "zoxide init fish | source" "$FISH_CONFIG" 2>/dev/null; then
    info "✓ zoxide 已配置"
    return 0
  fi

  local FISH_COMPLETIONS="${USER_HOME}/.config/fish/completions"
  mkdir -p "$FISH_COMPLETIONS"

  printf '\n# Zoxide initialization\nzoxide init fish | source\nalias cd z\n' >> "$FISH_CONFIG"

  # 生成 zoxide 补全文件
  zoxide init fish | grep -A 1000 "# ================" > "$FISH_COMPLETIONS/zoxide.fish" 2>/dev/null || true

  info "✓ zoxide 已配置"
  info "  补全文件已生成至: $FISH_COMPLETIONS/zoxide.fish"
}

init_atuin_for_fish_migrate() {
  command_exists atuin || return 0

  if grep -Fxq "atuin init fish | source" "$FISH_CONFIG" 2>/dev/null; then
    info "✓ atuin 已配置"
    return 0
  fi

  printf '\n# Atuin initialization\natuin init fish | source\n' >> "$FISH_CONFIG"
  info "✓ atuin 已配置"
}

init_lazyvim_for_fish_migrate() {
  command_exists fish || return 0
  command_exists nvim || return 0

  local FISH_COMPLETIONS="${USER_HOME}/.config/fish/completions"
  mkdir -p "$FISH_COMPLETIONS"

  # 检查补全文件是否已存在
  [ -f "$FISH_COMPLETIONS/nvim.fish" ] && return 0

  # 为 nvim 生成 fish 补全
  cat > "$FISH_COMPLETIONS/nvim.fish" << 'EOF'
# Neovim completions for fish

complete -c nvim -n "__fish_use_subcommand_from_list" -s c -l command -d "Execute command"
complete -c nvim -n "__fish_use_subcommand_from_list" -s d -l diff -d "Diff mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s e -l ex -d "Ex mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s E -d "Ex mode (no plugins)"
complete -c nvim -n "__fish_use_subcommand_from_list" -s h -l help -d "Show help"
complete -c nvim -n "__fish_use_subcommand_from_list" -s i -l insert -d "Insert mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s l -l lisp -d "Lisp mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s m -d "Modula-2 mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s M -d "Binary mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s N -d "No swap file (recovery disabled)"
complete -c nvim -n "__fish_use_subcommand_from_list" -s o -d "Open files in split"
complete -c nvim -n "__fish_use_subcommand_from_list" -s O -d "Open files in vertical split"
complete -c nvim -n "__fish_use_subcommand_from_list" -s p -d "Open files as tabs"
complete -c nvim -n "__fish_use_subcommand_from_list" -s P -d "Run binary as pipe"
complete -c nvim -n "__fish_use_subcommand_from_list" -s q -l quit -d "Quit (exit code)"
complete -c nvim -n "__fish_use_subcommand_from_list" -s r -d "Recover swap file"
complete -c nvim -n "__fish_use_subcommand_from_list" -s R -d "Readonly mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s s -d "Source file before editing"
complete -c nvim -n "__fish_use_subcommand_from_list" -s S -d "Skip plugins (no plugins)"
complete -c nvim -n "__fish_use_subcommand_from_list" -s t -l tag -d "Jump to tag"
complete -c nvim -n "__fish_use_subcommand_from_list" -s T -d "Terminal mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s u -d "Use init file"
complete -c nvim -n "__fish_use_subcommand_from_list" -s U -d "Don't use init file"
complete -c nvim -n "__fish_use_subcommand_from_list" -s v -l version -d "Show version"
complete -c nvim -n "__fish_use_subcommand_from_list" -s w -d "Write all and exit"
complete -c nvim -n "__fish_use_subcommand_from_list" -s W -d "Write and exit all"
complete -c nvim -n "__fish_use_subcommand_from_list" -s x -d "Edit encrypted file"
complete -c nvim -n "__fish_use_subcommand_from_list" -s y -d "Easy mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s z -d "Restricted mode"
complete -c nvim -n "__fish_use_subcommand_from_list" -s Z -d "Vim mode (restricted)"

# File completion
complete -c nvim -f
EOF

  info "✓ Neovim 补全已生成至: $FISH_COMPLETIONS/nvim.fish"
}

migrate_to_fish() {
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
    init_zoxide_for_fish_migrate || warn "zoxide 配置失败"
  else
    warn "zoxide 未安装，若需要请先运行 install.sh"
  fi

  if command_exists atuin; then
    init_atuin_for_fish_migrate || warn "atuin 配置失败"
  else
    warn "atuin 未安装（可选工具）"
  fi

  if command_exists nvim; then
    init_lazyvim_for_fish_migrate || warn "Neovim 补全配置失败"
  else
    warn "Neovim 未安装，若需要请先运行 install.sh"
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
}

# --- Setup Claude ---

# Embedded notify.sh content as a variable
NOTIFY_SH_CONTENT='#!/usr/bin/env bash
# Cross-platform desktop notification.
# Usage: notify.sh "Title" "Message"

TITLE="${1:-Claude Code}"
MESSAGE="${2:-通知}"

escape_xml() {
  echo "$1" | sed '\''s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'\''
}

notify_macos() {
  osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\""
}

notify_linux() {
  notify-send "$TITLE" "$MESSAGE"
}

notify_wsl() {
  local title_esc msg_esc
  title_esc=$(escape_xml "$TITLE")
  msg_esc=$(escape_xml "$MESSAGE")
  powershell.exe -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$xml.LoadXml('\''<toast><visual><binding template=\"ToastText02\"><text id=\"1\">${title_esc}</text><text id=\"2\">${msg_esc}</text></binding></visual></toast>'\'')
[Windows.UI.Notifications.ToastNotification]::new(\$xml) | ForEach-Object { [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('\''Claude Code'\'').Show(\$_) }
" 2>/dev/null
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  notify_macos
elif grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]; then
  notify_wsl
elif command -v notify-send >/dev/null 2>&1; then
  notify_linux
else
  # Fallback: terminal bell
  printf '\''\a'\''
fi
'

setup_claude() {
  info "设置 Claude Code"
  local CLAUDE_DIR="${USER_HOME}/.claude"
  local SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

  # Generate notify.sh from embedded content
  mkdir -p "$CLAUDE_DIR"
  echo "$NOTIFY_SH_CONTENT" > "${CLAUDE_DIR}/notify.sh"
  chmod +x "${CLAUDE_DIR}/notify.sh"
  info "  已生成 notify.sh 到 ${CLAUDE_DIR}/notify.sh"

  # The hooks we want to ensure exist
  local stop_hook='{"type":"command","command":"~/.claude/notify.sh '\''Claude Code'\'' '\''任务已完成，等待您的输入'\'' 2>/dev/null || true","async":true}'
  local notif_hook='{"type":"command","command":"MSG=$(python3 -c \"import sys,json; d=json.load(sys.stdin); print(d.get('\''message'\'','\''需要您的注意'\''))\" 2>/dev/null); ~/.claude/notify.sh '\''Claude Code 需要您的输入'\'' \"${MSG:-需要您的注意}\" 2>/dev/null || true","async":true}'

  if [ ! -f "$SETTINGS_FILE" ]; then
    # No existing settings — write fresh
    cat > "$SETTINGS_FILE" <<EOF
{
  "hooks": {
    "Stop": [{"hooks": [${stop_hook}]}],
    "Notification": [{"hooks": [${notif_hook}]}]
  }
}
EOF
    info "  已创建 ${SETTINGS_FILE}"
    return
  fi

  # Existing settings — merge with jq if available, otherwise warn and append
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq 未安装，无法自动合并 settings.json"
    warn "请手动检查并合并以下内容到 ${SETTINGS_FILE}："
    cat <<EOF

  "Stop": [{"hooks": [${stop_hook}]}],
  "Notification": [{"hooks": [${notif_hook}]}]
EOF
    info "  提示：可使用 'jq' 工具自动合并，或在 settings.json 中手动添加 hooks"
    return
  fi

  local tmp
  tmp=$(mktemp)

  # Merge Stop hook if not already present
  if ! jq -e '.hooks.Stop' "$SETTINGS_FILE" >/dev/null 2>&1; then
    jq --argjson h "[{\"hooks\": [${stop_hook}]}]" \
      '.hooks.Stop = $h' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    info "  ✓ 已合并 Stop hook"
  else
    info "  Stop hook 已存在，跳过"
  fi

  # Merge Notification hook if not already present
  if ! jq -e '.hooks.Notification' "$SETTINGS_FILE" >/dev/null 2>&1; then
    jq --argjson h "[{\"hooks\": [${notif_hook}]}]" \
      '.hooks.Notification = $h' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
    info "  ✓ 已合并 Notification hook"
  else
    info "  Notification hook 已存在，跳过"
  fi

  rm -f "$tmp"
  info "  settings.json 合并完成"

  echo ""
  info "claude-hud 插件需在 Claude Code 会话中手动安装："
  echo ""
  echo "    /plugin marketplace add jarrodwatts/claude-hud"
  echo "    /plugin install claude-hud"
  echo "    /claude-hud:setup"
  echo ""
  info "Claude Code 配置完成"
}

# --- Entry point ---

detect_os() {
  case "$(uname -s 2>/dev/null)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]; then
        echo "wsl"
      else
        echo "linux"
      fi ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) [ "${OS:-}" = "Windows_NT" ] && echo "windows" || echo "unknown" ;;
  esac
}

main() {
  local os
  os=$(detect_os)
  info "运行环境：$os"

  case "$os" in
    macos)     install_macos ;;
    linux|wsl) install_linux ;;
    windows)   install_windows ;;
    *) error_exit "无法识别运行环境，请在 macOS、Linux、WSL 或 Windows 下执行。" ;;
  esac

  info ""
  info "====== 安装完成，开始迁移和配置 ======"
  info ""

  # migrate_to_fish  # 暂时跳过 fish 配置

  setup_claude

  info ""
  info "====== 所有设置完成 ======"
  info ""
  info "✓ 工具安装完成"
  # info "✓ Fish shell 配置完成"  # 暂时跳过
  info "✓ Claude Code 配置完成"
  info ""
  info "下一步操作："
  info "  1. 启动 Claude Code 并安装插件"
  info ""
}

main "$@"