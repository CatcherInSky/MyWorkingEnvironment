#!/bin/bash

# init.sh - One-click terminal setup script based on README
# This script installs and configures terminal tools in the specified order
# Errors are non-blocking; the script continues on failures

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "win"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo "Detected OS: $OS"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if nvm is installed
nvm_exists() {
    [[ -s "$HOME/.nvm/nvm.sh" ]] || [[ -s "/usr/local/share/nvm/nvm.sh" ]]
}

# Function to install package managers first
install_package_managers() {
    echo "Installing package managers..."
    if [[ "$OS" == "linux" ]]; then
        # apt is usually pre-installed on Linux
        if ! command_exists apt; then
            echo "apt not found, skipping"
        fi
    elif [[ "$OS" == "mac" ]]; then
        if ! command_exists brew; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
        fi
    elif [[ "$OS" == "win" ]]; then
        if ! command_exists winget; then
            echo "winget not available, please install manually"
        fi
    fi
}

# Language installations
install_python() {
    if command_exists python3 || command_exists python; then
        echo "Python already installed"
        return
    fi
    echo "Installing Python..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt update && sudo apt install -y python3 python3-pip || true
    elif [[ "$OS" == "mac" ]]; then
        brew install python || true
    elif [[ "$OS" == "win" ]]; then
        winget install Python.Python.3 || true
    fi
}

install_zig() {
    if command_exists zig; then
        echo "Zig already installed"
        return
    fi
    echo "Installing Zig..."
    if [[ "$OS" == "linux" ]] || [[ "$OS" == "mac" ]]; then
        # Use zvm for version management
        if ! command_exists zvm; then
            curl -fsSL https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash || true
        fi
        export PATH="$HOME/.zvm/bin:$PATH"
        export PATH="$HOME/.zvm/self:$PATH"
        zvm install 0.13.0 || true
        zvm use 0.13.0 || true
        # Ensure zig is in PATH
        export PATH="$HOME/.zvm/self:$PATH"
    elif [[ "$OS" == "win" ]]; then
        winget install zig.zig || true
    fi
}

install_rust() {
    if command_exists rustc; then
        echo "Rust already installed"
        return
    fi
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || true
    source "$HOME/.cargo/env" || true
}

install_node() {
    if command_exists node; then
        echo "Node.js already installed"
        return
    fi
    echo "Installing Node.js..."
    if nvm_exists; then
        # Use nvm if available
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true
        nvm install --lts || true
        nvm use --lts || true
        nvm alias default lts/* || true
    elif [[ "$OS" == "linux" ]]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - || true
        sudo apt-get install -y nodejs || true
    elif [[ "$OS" == "mac" ]]; then
        brew install node || true
    elif [[ "$OS" == "win" ]]; then
        winget install OpenJS.NodeJS || true
    fi
}

install_lua() {
    if command_exists lua; then
        echo "Lua already installed"
        return
    fi
    echo "Installing Lua..."
    if [[ "$OS" == "linux" ]]; then
        # Prefer the distro package first so the `lua` command is available without pinning a specific version.
        if command_exists apt; then
            sudo apt update && sudo apt install -y lua || true
            if ! command_exists lua; then
                sudo apt install -y lua5.4 || true
            fi
        elif command_exists snap; then
            sudo snap install lua --classic || true
        else
            # Fallback to the latest Lua source release if no package manager is available.
            LUA_TARBALL=$(curl -s https://www.lua.org/ftp/ | grep -Po 'lua-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' | sort -V | tail -n1)
            if [[ -n "$LUA_TARBALL" ]]; then
                curl -fsSL "https://www.lua.org/ftp/$LUA_TARBALL" -o "$LUA_TARBALL" || true
                tar zxf "$LUA_TARBALL" || true
                DIR=${LUA_TARBALL%.tar.gz}
                cd "$DIR" || true
                if command_exists make; then
                    make linux || true
                    sudo make install || true
                else
                    echo "make not found; unable to build Lua from source"
                fi
                cd .. || true
            else
                echo "Unable to detect latest Lua release; install manually"
            fi
        fi
    elif [[ "$OS" == "mac" ]]; then
        brew install lua || true
    elif [[ "$OS" == "win" ]]; then
        winget install DEVCOM.Lua || true
    fi
}

install_typescript() {
    if command_exists tsc; then
        echo "TypeScript already installed"
        return
    fi
    echo "Installing TypeScript..."
    # TypeScript is installed via npm, so ensure node is installed first
    if command_exists npm; then
        npm install -g typescript || true
    else
        echo "npm not found, skipping TypeScript"
    fi
}

# Tool and package manager installations
install_pip() {
    if command_exists pip3 || command_exists pip; then
        echo "pip already installed"
        return
    fi
    echo "Installing pip..."
    # Usually comes with Python
    if command_exists python3; then
        python3 -m ensurepip --upgrade || true
    fi
}

install_pipx() {
    if command_exists pipx; then
        echo "pipx already installed"
        return
    fi
    echo "Installing pipx..."
    if command_exists python3; then
        python3 -m pip install --user pipx || true
        python3 -m pipx ensurepath || true
    fi
}

install_cargo() {
    # cargo comes with Rust
    if command_exists cargo; then
        echo "cargo already available"
    else
        echo "cargo not found, install Rust first"
    fi
}

install_nvm() {
    if nvm_exists; then
        echo "nvm already installed"
        return
    fi
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || true
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true
    # Ensure nvm is available
    export PATH="$NVM_DIR:$PATH"
}

install_zvm() {
    # Already handled in zig installation
    echo "zvm handled with Zig"
}

install_npm() {
    # npm comes with Node.js
    if command_exists npm; then
        echo "npm already available"
    else
        echo "npm not found, install Node.js first"
    fi
}

install_pnpm() {
    if command_exists pnpm; then
        echo "pnpm already installed"
        return
    fi
    echo "Installing pnpm..."
    if command_exists npm; then
        npm install -g pnpm || true
    fi
}

install_yarn() {
    if command_exists yarn; then
        echo "yarn already installed"
        return
    fi
    echo "Installing yarn..."
    if command_exists npm; then
        npm install -g yarn || true
    fi
}

install_yt_dlp() {
    if command_exists yt-dlp; then
        echo "yt-dlp already installed"
        return
    fi
    echo "Installing yt-dlp..."
    if command_exists pipx; then
        pipx install yt-dlp || true
    elif command_exists pip3; then
        pip3 install yt-dlp || true
    fi
}

install_ffmpeg() {
    if command_exists ffmpeg; then
        echo "ffmpeg already installed"
        return
    fi
    echo "Installing ffmpeg..."
    if [[ "$OS" == "linux" ]]; then
        if command_exists snap; then
            sudo snap install ffmpeg || true
        else
            # Download static build
            curl -L https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz -o ffmpeg.tar.xz || true
            tar xf ffmpeg.tar.xz || true
            sudo cp ffmpeg-master-latest-linux64-gpl/bin/ffmpeg /usr/local/bin/ || true
        fi
    elif [[ "$OS" == "mac" ]]; then
        brew install ffmpeg || true
    elif [[ "$OS" == "win" ]]; then
        winget install Gyan.FFmpeg || true
    fi
}

install_gh() {
    if command_exists gh; then
        echo "gh already installed"
        return
    fi
    echo "Installing GitHub CLI..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg || true
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null || true
        sudo apt update && sudo apt install -y gh || true
    elif [[ "$OS" == "mac" ]]; then
        brew install gh || true
    elif [[ "$OS" == "win" ]]; then
        winget install GitHub.cli || true
    fi
}

install_docker() {
    if command_exists docker; then
        echo "Docker already installed"
        return
    fi
    echo "Installing Docker..."
    if [[ "$OS" == "linux" ]]; then
        curl -fsSL https://get.docker.com -o get-docker.sh || true
        sudo sh get-docker.sh || true
        sudo usermod -aG docker $USER || true
    elif [[ "$OS" == "mac" ]]; then
        brew install --cask docker || true
    elif [[ "$OS" == "win" ]]; then
        winget install Docker.DockerDesktop || true
    fi
}

# Main component installations
install_fish() {
    if command_exists fish; then
        echo "fish already installed"
        return
    fi
    echo "Installing fish..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt install -y fish || true
    elif [[ "$OS" == "mac" ]]; then
        brew install fish || true
    elif [[ "$OS" == "win" ]]; then
        winget install fish-shell.fish || true
    fi
}

install_starship() {
    if command_exists starship; then
        echo "Starship already installed"
        return
    fi
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y || true
}

install_zoxide() {
    if command_exists zoxide; then
        echo "zoxide already installed"
        return
    fi
    echo "Installing zoxide..."
    if command_exists cargo; then
        cargo install zoxide --locked || true
    elif [[ "$OS" == "linux" ]]; then
        sudo apt install -y zoxide || true
    elif [[ "$OS" == "mac" ]]; then
        brew install zoxide || true
    fi
}

install_neovim() {
    if command_exists nvim; then
        echo "Neovim already installed"
        return
    fi

    echo "Installing Neovim..."
    if [[ "$OS" == "linux" ]]; then
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            TARBALL="nvim-linux-x86_64.tar.gz"
            APPIMAGE="nvim-linux-x86_64.appimage"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            TARBALL="nvim-linux-arm64.tar.gz"
            APPIMAGE="nvim-linux-arm64.appimage"
        else
            echo "Unsupported architecture: $ARCH"
            return
        fi

        if command_exists apt; then
            sudo apt update && sudo apt install -y neovim || true
        fi
        if command_exists nvim; then
            return
        fi

        curl -LO "https://github.com/neovim/neovim/releases/latest/download/$TARBALL" || true
        TARGET_DIR="/opt/${TARBALL%.tar.gz}"
        sudo rm -rf "$TARGET_DIR" || true
        sudo tar -C /opt -xzf "$TARBALL" || true
        sudo ln -sf "$TARGET_DIR/bin/nvim" /usr/local/bin/nvim || true
        if command_exists nvim; then
            return
        fi

        if command_exists snap; then
            sudo snap install nvim --classic || true
            return
        fi

        curl -LO "https://github.com/neovim/neovim/releases/latest/download/$APPIMAGE" || true
        chmod u+x "$APPIMAGE" || true
        sudo install -m 755 "$APPIMAGE" /usr/local/bin/nvim || true
    elif [[ "$OS" == "mac" ]]; then
        if command_exists brew; then
            brew install neovim || true
        else
            echo "brew not found, cannot install Neovim on macOS"
        fi
    elif [[ "$OS" == "win" ]]; then
        winget install Neovim.Neovim || true
    fi
}

install_lazyvim() {
    if [[ -f ~/.config/nvim/init.lua ]]; then
        echo "LazyVim config already exists"
        return
    fi
    echo "Installing LazyVim..."
    if command_exists git && command_exists nvim; then
        rm -rf ~/.config/nvim || true
        git clone https://github.com/LazyVim/starter ~/.config/nvim || true
        # Install plugins
        nvim --headless +q || true
    else
        echo "git or nvim not found, skipping LazyVim"
    fi
}

install_lazygit() {
    if command_exists lazygit; then
        echo "lazygit already installed"
        return
    fi
    echo "Installing lazygit..."
    if [[ "$OS" == "linux" ]] || [[ "$OS" == "mac" ]]; then
        # Use official install script
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') || true
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_$(uname -s)_$(uname -m).tar.gz" || true
        tar xf lazygit.tar.gz lazygit || true
        sudo install lazygit /usr/local/bin || true
    elif [[ "$OS" == "win" ]]; then
        winget install JesseDuffield.lazygit || true
    fi
}

install_atuin() {
    if command_exists atuin; then
        echo "atuin already installed"
        return
    fi
    echo "Installing atuin..."
    if command_exists cargo; then
        cargo install atuin || true
    elif [[ "$OS" == "linux" ]]; then
        # Use official install
        bash <(curl https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh) || true
    fi
}

install_yazi() {
    if command_exists yazi; then
        echo "yazi already installed"
        return
    fi
    echo "Installing yazi (TUI file manager)..."
    if [[ "$OS" == "linux" ]]; then
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            URL="https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
        elif [[ "$ARCH" == "aarch64" ]]; then
            URL="https://github.com/sxyazi/yazi/releases/latest/download/yazi-aarch64-unknown-linux-gnu.zip"
        else
            URL=""
        fi
        if [[ -n "$URL" ]]; then
            curl -L -o /tmp/yazi.zip "$URL" || true
            python3 - <<'PY'
import zipfile
import pathlib
path = pathlib.Path('/tmp/yazi_release')
path.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile('/tmp/yazi.zip', 'r') as z:
    z.extractall(path)
PY
            for binpath in /tmp/yazi_release/*/yazi; do
                if [[ -f "$binpath" ]]; then
                    sudo install -m 755 "$binpath" /usr/local/bin/yazi || true
                fi
            done
            for binpath in /tmp/yazi_release/*/ya; do
                if [[ -f "$binpath" ]]; then
                    sudo install -m 755 "$binpath" /usr/local/bin/ya || true
                fi
            done
        fi
    fi
    if ! command_exists yazi && command_exists cargo && command_exists git; then
        git clone https://github.com/sxyazi/yazi.git /tmp/yazi || true
        cd /tmp/yazi || true
        cargo build --release || true
        sudo cp target/release/yazi /usr/local/bin/ || true
        cd - || true
    fi
}

install_fd() {
    if command_exists fd; then
        echo "fd already installed"
        return
    fi
    echo "Installing fd (fast file search tool)..."
    if command_exists cargo; then
        cargo install fd-find || true
    elif [[ "$OS" == "linux" ]]; then
        sudo apt install -y fd-find || true
    elif [[ "$OS" == "mac" ]]; then
        brew install fd || true
    fi
}

install_ghostty() {
    if command_exists ghostty; then
        echo "ghostty already installed"
        return
    fi
    echo "Installing ghostty..."
    if [[ "$OS" == "linux" ]]; then
        if command_exists snap; then
            sudo snap install ghostty --classic || true
        else
            ARCH=$(uname -m)
            if [[ "$ARCH" == "x86_64" ]]; then
                URL="https://github.com/pkgforge-dev/ghostty-appimage/releases/latest/download/Ghostty-1.3.1-x86_64.AppImage"
            elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
                URL="https://github.com/pkgforge-dev/ghostty-appimage/releases/latest/download/Ghostty-1.3.1-aarch64.AppImage"
            else
                URL="https://github.com/pkgforge-dev/ghostty-appimage/releases/latest/download/Ghostty-1.3.1-x86_64.AppImage"
            fi
            curl -L -o /tmp/Ghostty.AppImage "$URL" || true
            chmod +x /tmp/Ghostty.AppImage || true
            sudo install -m 755 /tmp/Ghostty.AppImage /usr/local/bin/ghostty || true
        fi
    elif [[ "$OS" == "mac" ]]; then
        brew install --cask ghostty || true
    fi
    # Windows not supported yet
}

# Configuration functions
configure_yazi() {
    echo "Configuring yazi..."
    mkdir -p ~/.config/yazi
    cat > ~/.config/yazi/init.lua << 'EOF'
---@diagnostic disable: undefined-global
local ok, git = pcall(require, "git")
if ok and git then
    git:setup({ order = 1500 })
end
local ok2, full_border = pcall(require, "full-border")
if ok2 and full_border then
    full_border:setup()
end
if THEME and THEME.status then
	local th = THEME.status
	th.git = th.git or {}
	th.git.unknown_sign = " "
	th.git.modified_sign = "M"
	th.git.deleted_sign = "D"
	th.git.clean_sign = "✔"
end
EOF

    cat > ~/.config/yazi/yazi.toml << 'EOF'
[mgr]
show_hidden = true
show_symlink = true
linemode = "size"
sort_by = "natural"
sort_dir_first = true
show_git = true
[opener]
edit = [
  { run = 'nvim "$@"', block = true, desc = "Neovim" },
]
[open]
prepend_rules = [
  { name = "*", use = "edit" },
]
[plugin]
prepend_previewers = [
  { name = "*.md", run = "glow" },
  { mime = "{image,audio,video}/*", run = "mediainfo" },
  { mime = "application/x-subrip", run = "mediainfo" },
  { mime = "audio/*", run = "exifaudio" },
  { name = "*.{csv,tsv,json,parquet}", run = "duckdb" },
]
[[plugin.prepend_fetchers]]
id    = "git" # Remove if Yazi > v26.1.22
url   = "*"
run   = "git"
group = "git"
EOF

    if command_exists ya; then
        echo "Installing Yazi plugins..."
        ya pkg add yazi-rs/plugins:smart-enter || true
        ya pkg add yazi-rs/plugins:git || true
        ya pkg add yazi-rs/plugins:full-border || true
        ya pkg add yazi-rs/plugins:chmod || true
        ya pkg add Reledia/glow || true
        ya pkg add yazi-rs/plugins:piper || true
        ya pkg add boydaihungst/mediainfo || true
        ya pkg add Sonico98/exifaudio || true
        ya pkg add wylie102/duckdb || true
    fi
}

configure_ghostty() {
    echo "Configuring ghostty..."
    mkdir -p ~/.config/ghostty
    cat > ~/.config/ghostty/config << 'EOF'
theme = Coffee Theme
keybind = global:option+space=toggle_quick_terminal
keybind = super+a=unbind
quick-terminal-position = top
quick-terminal-size = 40%          
quick-terminal-autohide = true
confirm-close-surface = false
window-save-state = always
adjust-cell-height = 20%
window-padding-x = 10
window-padding-y = 10
EOF
}

configure_fish() {
    echo "Configuring fish..."
    mkdir -p ~/.config/fish
    cat > ~/.config/fish/config.fish << 'EOF'
if status is-interactive
    # Commands to run in interactive sessions can go here
end
zoxide init fish | source
alias cd z
atuin init fish | source
set -gx ZVM_INSTALL "$HOME/.zvm/self"
set -gx PATH $PATH "$HOME/.zvm/bin"
set -gx PATH $PATH "$ZVM_INSTALL/"
set -gx EDITOR nvim
set -gx VISUAL nvim
alias lg='lazygit'
alias yy='yazi'
starship init fish | source # 初始化 Starship 提示符
function right_arrow_smart_cycle
    set -l old_pos (commandline -C)
    commandline -f forward-char
    set -l new_pos (commandline -C)
    if test $old_pos -eq $new_pos
        commandline -f beginning-of-line
    end
end
function left_arrow_smart_cycle
    set -l old_pos (commandline -C)
    commandline -f backward-char
    set -l new_pos (commandline -C)
    if test $old_pos -eq $new_pos
        commandline -f end-of-line
    end
end
bind \e\[C right_arrow_smart_cycle
bind \e\[D left_arrow_smart_cycle
EOF
}

configure_nvim() {
    echo "Configuring Neovim..."
    mkdir -p ~/.config/nvim/lua/config
    mkdir -p ~/.config/nvim/lua/plugins

    if [[ "$OS" == "mac" ]]; then
        cat > ~/.config/nvim/lua/config/keymaps.lua << 'EOF'
local map = vim.keymap.set
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.clipboard = "unnamedplus"
-- Save
map({ "n", "i", "v" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save" })
-- Copy/Paste
map({ "n", "v" }, "<D-c>", '"+y', { desc = "Copy" })
map({ "n", "v" }, "<D-x>", '"+d', { desc = "Cut" })
map({ "n", "v" }, "<D-v>", '"+p', { desc = "Paste" })
map("i", "<D-v>", "<C-r>+", { desc = "Paste" })
-- Undo/Redo
map("n", "<D-z>", "u", { desc = "Undo" })
map("i", "<D-z>", "<Esc>ua", { desc = "Undo" })
map("n", "<D-S-z>", "<C-r>", { desc = "Redo" })
map("n", "<C-r>", "<C-r>", { desc = "Redo" })
-- Misc
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
-- force quit (<C-c> safe on mac: copy uses <D-c>, no conflict)
map({ "n", "i", "v" }, "<C-c>", "<cmd>qa!<cr>", { desc = "Force Quit All" })
EOF
    else
        # Linux / Windows
        # Notes:
        #   <D-...> (Command key) does not exist — replaced with <C-...>
        #   <C-v> normal/visual = Visual Block entry, not remapped (use p/P instead)
        #   <C-z> removed — suspends neovim to background in terminal
        #   <C-c> force quit removed — conflicts with copy in visual mode
        #   clipboard=unnamedplus requires xclip/xsel (X11) or wl-clipboard (Wayland)
        cat > ~/.config/nvim/lua/config/keymaps.lua << 'EOF'
local map = vim.keymap.set
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.clipboard = "unnamedplus"
-- Save
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save" })
-- Copy/Cut: visual mode only to avoid normal-mode conflicts
-- (<C-c> normal = cancel op, <C-x> normal = decrement number)
map("v", "<C-c>", '"+y', { desc = "Copy" })
map("v", "<C-x>", '"+d', { desc = "Cut" })
-- Paste: insert mode only; normal mode use p/P (clipboard=unnamedplus links y/p to system clipboard)
map("i", "<C-v>", "<C-r>+", { desc = "Paste" })
-- Redo (Undo via u in normal mode)
map("n", "<C-r>", "<C-r>", { desc = "Redo" })
-- Misc
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
EOF
    fi

    cat > ~/.config/nvim/lua/plugins/yazi.lua << 'EOF'
return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>e", "<cmd>Yazi<cr>", desc = "Open yazi at current file" },
    { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Open yazi in cwd" },
    { "<leader>y", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi session" },
  },
  opts = {
    open_for_directories = true,
    floating_window_scaling_factor = 0.8,
    yazi_floating_window_winblend = 0,
  },
}
EOF
}

# Migration function
migrate_env_to_fish() {
    echo "Migrating environment variables to fish..."
    # Source bash/zsh profiles to get current env
    ENV_VARS=""
    for profile in ~/.bashrc ~/.bash_profile ~/.profile ~/.zshrc; do
        if [[ -f "$profile" ]]; then
            while IFS= read -r line; do
                if [[ $line =~ ^export ]]; then
                    ENV_VARS+="$line\n"
                fi
            done < "$profile"
        fi
    done

    # Add to fish config
    if [[ -n "$ENV_VARS" ]]; then
        echo -e "$ENV_VARS" >> ~/.config/fish/config.fish
    fi

    # Set fish as default shell
    if command_exists chsh; then
        echo "Setting fish as default shell..."
        sudo chsh -s $(which fish) $USER || true
    fi
}

# Verification function
verify_installation() {
    echo "Verifying installations..."
    tools=("python3" "zig" "rustc" "node" "lua" "tsc" "pip3" "pipx" "cargo" "npm" "pnpm" "yarn" "yt-dlp" "ffmpeg" "gh" "docker" "fish" "starship" "zoxide" "nvim" "lazygit" "atuin" "yazi" "fd" "ghostty")
    for tool in "${tools[@]}"; do
        if [[ "$tool" == "nvm" ]]; then
            if nvm_exists; then
                echo "✓ nvm installed"
            else
                echo "✗ nvm not found"
            fi
        elif command_exists "$tool"; then
            echo "✓ $tool installed"
        else
            echo "✗ $tool not found"
        fi
    done
}

# Main execution
main() {
    install_package_managers

    # Install languages (independent first)
    install_python
    install_zig
    install_rust
    install_lua

    # Install Node.js and related (nvm first for version management)
    install_nvm
    install_node
    install_typescript

    # Install tools depending on languages
    install_pip
    install_pipx
    install_cargo
    install_zvm
    install_npm
    install_pnpm
    install_yarn

    # Install main components (some depend on cargo/zig)
    install_fish
    install_starship
    install_zoxide
    install_atuin
    install_yazi
    install_fd
    install_neovim
    install_lazyvim
    install_lazygit
    install_ghostty

    # install_yt_dlp
    # install_ffmpeg
    # install_gh
    # install_docker

    # Configure
    configure_yazi
    configure_ghostty
    configure_fish
    configure_nvim

    # Migrate and switch
    migrate_env_to_fish

    # Verify
    verify_installation

    echo "Installation complete. Please restart your terminal or run 'exec fish' to switch to fish shell."
}

main "$@"