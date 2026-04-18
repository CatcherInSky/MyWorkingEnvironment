#!/usr/bin/env bash
set -euo pipefail

USER_HOME="${HOME:-$(pwd)}"

info()       { printf "[INFO] %s\n" "$1"; }
warn()       { printf "[WARN] %s\n" "$1"; }
error_exit() { printf "[ERROR] %s\n" "$1" >&2; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

# --- Shared tool installers ---

install_starship() {
  command_exists starship && return
  info "安装 Starship"
  curl -sS https://starship.rs/install.sh | sh
  
  # 创建配置文件
  mkdir -p "${USER_HOME}/.config"
  [ ! -f "${USER_HOME}/.config/starship.toml" ] && \
    curl -sS https://raw.githubusercontent.com/starship/starship/master/starship.toml -o "${USER_HOME}/.config/starship.toml"
  info "✓ Starship 已安装，配置文件: ~/.config/starship.toml"
}

install_zoxide() {
  command_exists zoxide && return
  info "安装 zoxide"
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  info "✓ zoxide 已安装"
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
  command_exists atuin && return
  info "安装 atuin"
  
  curl -fsSL https://setup.atuin.sh | bash || { warn "atuin 安装失败，跳过"; return; }
  
  info "✓ atuin 已安装"
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
  [ -d "${USER_HOME}/.nvm" ] && return
  info "安装 nvm"
  local version
  version=$(curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"\(v[^"]*\)".*/\1/')
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | bash
  export NVM_DIR="${USER_HOME}/.nvm"
  [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
}

install_zvm() {
  command_exists zvm && return
  info "安装 zvm (Zig Version Manager)"
  curl -fsSL https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash
}

install_npm_globals() {
  command_exists npm || { warn "npm 未安装，跳过全局包安装"; return; }
  info "安装全局 npm 包: pnpm yarn typescript tsx"
  npm install -g pnpm yarn typescript tsx 2>/dev/null || true
}

install_pipx() {
  command_exists pipx && return
  command_exists python3 || { warn "python3 未找到，跳过 pipx"; return; }
  info "安装 pipx"
  python3 -m pip install --user pipx 2>/dev/null \
    || sudo apt-get install -y python3-pipx 2>/dev/null \
    || true
  python3 -m pipx ensurepath 2>/dev/null || true
}

install_yt_dlp() {
  command_exists yt-dlp && return
  info "安装 yt-dlp"
  if command_exists pipx; then
    pipx install yt-dlp || true
  elif command_exists pip3; then
    pip3 install --user yt-dlp || true
  else
    warn "pipx/pip3 均未找到，跳过 yt-dlp"
  fi
}

install_neovim() {
  command_exists nvim && return
  info "配置 Neovim"
  mkdir -p "${USER_HOME}/.config/nvim" "${USER_HOME}/.local/share/nvim"
  info "✓ Neovim 目录已准备"
}

install_lazyvim() {
  command_exists nvim || { warn "Neovim 未安装，无法安装 LazyVim"; return; }

  if [ -d "${USER_HOME}/.config/nvim" ]; then
    if [ "$(ls -A "${USER_HOME}/.config/nvim")" != "" ]; then
      warn "~/.config/nvim 已存在且非空，备份到 ~/.config/nvim.bak"
      if mv "${USER_HOME}/.config/nvim" "${USER_HOME}/.config/nvim.bak" 2>/dev/null; then
        info "  旧配置已备份"
      else
        warn "备份失败，尝试移除旧目录以继续安装"
        rm -rf "${USER_HOME}/.config/nvim"
      fi
    fi
  fi

  mkdir -p "${USER_HOME}/.config"
  info "安装 LazyVim"
  if git clone https://github.com/LazyVim/starter "${USER_HOME}/.config/nvim" 2>/dev/null; then
    rm -rf "${USER_HOME}/.config/nvim/.git" 2>/dev/null || true
    info "✓ LazyVim 已安装至 ~/.config/nvim"
    info "  首次启动 nvim 时将自动下载和配置插件"
  else
    warn "LazyVim 安装失败，检查网络或权限"
  fi
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
  sudo apt-get update -q
  sudo apt-get install -y git python3 python3-pip curl wget fish neovim ffmpeg nodejs npm
}

install_lazygit_linux() {
  command_exists lazygit && return
  info "安装 lazygit"
  
  # 尝试使用官方脚本（推荐方法）
  if curl -s https://raw.githubusercontent.com/jesseduffield/lazygit/master/scripts/install_update_linux.sh | bash 2>/dev/null; then
    info "✓ lazygit 已安装"
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
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz" \
    | tar xz -C /tmp lazygit 2>/dev/null || { warn "下载失败，跳过 lazygit"; return; }
  
  sudo install /tmp/lazygit /usr/local/bin/lazygit 2>/dev/null || warn "无法安装 lazygit，请检查权限"
  rm -f /tmp/lazygit
  info "✓ lazygit 已安装"
}

install_gh_linux() {
  command_exists gh && return
  info "安装 GitHub CLI"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -q
  sudo apt-get install -y gh
}

install_linux() {
  install_apt_base
  install_gh_linux
  install_starship
  install_zoxide
  init_zoxide_for_fish
  install_lazygit_linux
  install_yazi
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
  local formulas=(git fish starship zoxide lazygit neovim python node pnpm yarn pipx rustup gh ffmpeg yt-dlp atuin yazi)
  # docker via cask = Docker Desktop (includes CLI); ghostty is the terminal emulator
  local casks=(ghostty docker copyq snipaste macs-fan-control scroll-reverser stats keyclu kap)

  info "安装 Homebrew formulas"
  for pkg in "${formulas[@]}"; do
    brew install "$pkg" 2>/dev/null || warn "brew 无法安装 $pkg，跳过"
  done
  info "安装 Homebrew casks"
  for pkg in "${casks[@]}"; do
    brew install --cask "$pkg" 2>/dev/null || warn "brew cask 无法安装 $pkg，跳过"
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
  command_exists powershell.exe || return 1
  powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -Command "winget install --id '$id' --exact --silent -e" >/dev/null 2>&1
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
    install_windows_pkg "$id" \
      && info "  已安装: $id" \
      || warn "  安装失败（请手动安装）: $id"
  done
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

  info "安装完成。后续步骤："
  info "  迁移 fish 环境变量：bash migrate_to_fish.sh"
  info "  配置 Claude Code：  bash setup_claude.sh"
}

main "$@"
