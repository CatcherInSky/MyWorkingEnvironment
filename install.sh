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
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
}

install_zoxide() {
  command_exists zoxide && return
  info "安装 zoxide"
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
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

# --- Linux ---

install_apt_base() {
  info "安装 apt 基础包"
  sudo apt-get update -q
  sudo apt-get install -y git python3 python3-pip curl wget fish neovim ffmpeg nodejs npm
}

install_lazygit_linux() {
  command_exists lazygit && return
  info "安装 lazygit"
  local arch version
  case "$(uname -m)" in
    x86_64)         arch="x86_64" ;;
    aarch64|arm64)  arch="arm64" ;;
    *) warn "未知架构，跳过 lazygit"; return ;;
  esac
  version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz" \
    | tar xz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin/lazygit
  rm -f /tmp/lazygit
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
  install_lazygit_linux
  install_nvm
  install_zvm
  install_pipx
  install_yt_dlp
  install_npm_globals
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
  local formulas=(git fish starship zoxide lazygit python node pnpm yarn pipx rustup gh ffmpeg yt-dlp)
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

  install_nvm
  install_zvm
  install_npm_globals
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
