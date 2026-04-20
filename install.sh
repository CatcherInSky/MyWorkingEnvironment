#!/usr/bin/env bash
set -euo pipefail

USER_HOME="${HOME:-$(pwd)}"
DOWNLOAD_DIR="${USER_HOME}/Downloads/installers"
FISH_CONFIG="${USER_HOME}/.config/fish/config.fish"

info() { printf "[INFO] %s\n" "$1"; }
warn() { printf "[WARN] %s\n" "$1"; }
error_exit() { printf "[ERROR] %s\n" "$1" >&2; exit 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

make_download_dir() {
  mkdir -p "$DOWNLOAD_DIR"
}

download_file() {
  local url="$1"
  local dest="$2"
  info "Downloading $url to $dest"
  curl -fsSL "$url" -o "$dest" || {
    warn "下载失败: $url"
    return 1
  }
}

add_fish_config_line() {
  local line="$1"
  mkdir -p "$(dirname "$FISH_CONFIG")"
  if ! grep -Fxq "$line" "$FISH_CONFIG" 2>/dev/null; then
    printf '%s\n' "$line" >> "$FISH_CONFIG"
  fi
}

migrate_shell_envs_to_fish() {
  info "开始将 Bash / Zsh 中的环境变量迁移到 fish"
  local shells=("$USER_HOME/.zshrc" "$USER_HOME/.bashrc" "$USER_HOME/.bash_profile" "$USER_HOME/.profile")
  local found=false

  for rc in "${shells[@]}"; do
    if [ -f "$rc" ]; then
      found=true
      while IFS= read -r line; do
        line="${line%%#*}"
        if [[ "$line" =~ ^[[:space:]]*export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
          local key="${BASH_REMATCH[1]}"
          local value="${BASH_REMATCH[2]}"
          value="${value%"}"; value="${value#"}"
          value="${value%\'}"; value="${value#\'}"
          add_fish_config_line "set -gx $key '$value'"
        elif [[ "$line" =~ ^[[:space:]]*PATH= ]]; then
          local path_value="${line#*=}"
          path_value="${path_value%"}"; path_value="${path_value#"}"
          path_value="${path_value%\'}"; path_value="${path_value#\'}"
          IFS=':' read -r -a path_parts <<< "$path_value"
          for p in "${path_parts[@]}"; do
            [ -n "$p" ] && add_fish_config_line "set -gx PATH \$PATH $p"
          done
        fi
      done < "$rc"
    fi
  done

  if ! $found; then
    warn "未找到 Bash 或 Zsh 配置文件，无法自动迁移环境变量。"
    return 1
  fi

  info "环境变量迁移已写入 $FISH_CONFIG"
}

install_brew_if_missing() {
  if command_exists brew; then
    return
  fi
  info "Homebrew 未安装，开始安装 Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
  eval "$(/usr/local/bin/brew shellenv 2>/dev/null || true)"
}

install_apt_packages() {
  local packages=("git" "python3" "python3-pip" "curl" "wget" "fish" "starship" "zoxide" "neovim" "lazygit" "ffmpeg" "yt-dlp" "gh" "docker.io" "nodejs" "npm")
  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
}

install_nvm() {
  if [ -d "$USER_HOME/.nvm" ] || command_exists nvm; then
    return
  fi
  info "安装 nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash
  export NVM_DIR="$USER_HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

install_zvm() {
  if command_exists zvm || [ -d "$USER_HOME/.zvm" ]; then
    return
  fi
  info "安装 zvm"
  curl -fsSL https://raw.githubusercontent.com/maralla/zvm/main/zvm.zsh | bash
}

install_npm_globals() {
  if ! command_exists npm; then
    warn "npm 未安装，跳过全局 npm 包安装"
    return
  fi
  info "安装全局 npm 包"
  npm install -g pnpm yarn typescript tsx || true
}

install_pipx() {
  if command_exists pipx; then
    return
  fi
  if command_exists python3; then
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
  fi
}

install_macos() {
  install_brew_if_missing
  info "使用 Homebrew 安装通用软件、macOS 软件和终端方案"
  local casks=("copyq" "snipaste" "macs-fan-control" "scroll-reverser" "stats" "keyclu" "kap")
  local formulas=("git" "fish" "starship" "zoxide" "lazygit" "python" "node" "pnpm" "yarn" "pipx" "rustup-init" "gh" "docker" "nvm" "zvm" "ffmpeg" "yt-dlp" "typescript" "tsx")
  for pkg in "${formulas[@]}"; do
    brew install "$pkg" || warn "Homebrew 无法安装 $pkg，继续下一项"
  done
  for pkg in "${casks[@]}"; do
    brew install --cask "$pkg" || warn "Homebrew Cask 无法安装 $pkg，继续下一项"
  done
  install_nvm
  install_zvm
  install_pipx
  install_npm_globals
}

install_linux() {
  install_apt_packages
  install_nvm
  install_zvm
  install_pipx
  install_npm_globals
}

install_windows_package() {
  local id="$1"
  local name="$2"
  if ! command_exists powershell.exe; then
    warn "powershell.exe 未找到，Windows 安装将受限。"
    return 1
  fi
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { winget install --id '$id' --exact --silent -e } catch { exit 1 }" >/dev/null 2>&1 || return 1
}

download_windows_installer() {
  local url="$1"
  local dest="${DOWNLOAD_DIR}/$(basename "$url")"
  download_file "$url" "$dest"
}

install_windows() {
  info "检测到 Windows 环境，安装通用软件和 Windows 专用软件"
  make_download_dir
  local items=(
    "Git.Git|Git"
    "OpenClipboard.CopyQ|copyQ"
    "Snipe.\.???|snipaste"
    "ScreenToGif.ScreenToGif|ScreenToGif"
    "TranslucentTB.TranslucentTB|TranslucentTB"
    "ImageGlass.ImageGlass|ImageGlass"
    "CheckPoint.Gopeed|Gopeed"
    "Everything.Everything|Everything"
    "HotkeyScreener.HotkeyScreener|Hotkey Screener"
  )

  for entry in "${items[@]}"; do
    IFS='|' read -r id name <<< "$entry"
    info "尝试安装 $name"
    if install_windows_package "$id" "$name"; then
      info "$name 安装成功"
    else
      warn "$name winget 安装失败，改为下载安装包"
      case "$name" in
        "copyQ") download_windows_installer "https://github.com/hluk/CopyQ/releases/latest/download/CopyQ-win.zip" || true ;;
        "ScreenToGif") download_windows_installer "https://github.com/NickeManarin/ScreenToGif/releases/latest/download/ScreenToGif.zip" || true ;;
        "ImageGlass") download_windows_installer "https://imageglass.org/download" || true ;;
        "Everything") download_windows_installer "https://www.voidtools.com/Everything-1.4.1.1009.x64.zip" || true ;;
        *) warn "未指定 $name 的下载链接，已跳过。" ;;
      esac
    fi
  done
}

main() {
  local os_type="unknown"
  if command_exists uname; then
    case "$(uname -s)" in
      Darwin) os_type="macos" ;;
      Linux)
        if grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]; then
          os_type="wsl"
        else
          os_type="linux"
        fi
        ;;
      CYGWIN*|MINGW*|MSYS*) os_type="windows" ;;
      *) os_type="unknown" ;;
    esac
  elif [ "${OS:-}" = "Windows_NT" ]; then
    os_type="windows"
  fi

  info "当前检测到运行环境：$os_type"

  case "$os_type" in
    macos)
      install_macos
      ;;
    linux|wsl)
      install_linux
      ;;
    windows)
      install_windows
      ;;
    *)
      error_exit "无法识别运行环境，请在 macOS、Linux、WSL 或 Windows 下执行。"
      ;;
  esac

  if command_exists fish; then
    migrate_shell_envs_to_fish || warn "环境变量迁移未完成，请手动检查 $FISH_CONFIG"
  else
    warn "fish 未安装，跳过 shell 环境迁移。"
  fi

  info "安装脚本执行完成。请根据输出检查是否存在未成功安装的项目。"
}

main "$@"
