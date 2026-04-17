# 软件

## 通用
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| copyQ | 剪切板历史管理 | Windows / mac / Linux | 常用剪贴板工具 |
| snipaste | 屏幕截图与贴图 | Windows / mac / Linux | 简洁截图工具 |
| Git | 版本控制 | 通用 | 必装 |

## mac
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| Macs Fan Control | 风扇控制 | macOS | 调整风扇转速 |
| Scroll Reverser | 滚动反向 | macOS | 改善滚轮体验 |
| Stats | 系统监控 | macOS | 资源使用可视化 |
| KeyClu | 键盘快捷管理 | macOS | 快捷键增强 |
| Kap | 屏幕录制 | macOS | 录制 GIF / 视频 |

## Windows
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| ScreenToGif | 屏幕录制 | Windows | 录制 GIF / 视频 |
| Gopeed | 下载工具 | Windows | 提高效率 |
| TranslucentTB | 任务栏透明 | Windows | 美化任务栏 |
| ImageGlass | 图片浏览 | Windows | 轻量图片查看器 |
| Flow Launcher | 启动器 | Windows | 类似 Spotlight |
| Everything | 文件搜索 | Windows | 快速查找文件 |
| Hotkey Screener | 快捷键测试 | Windows | 检查按键输入 |

# 终端方案

## 主要组件
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| ghostty | 终端模拟器 | Linux / macOS | 速度快 |
| fish | 智能 shell | Linux / macOS | 语法高亮、Tab 补全 |
| Starship | prompt 美化 | Linux / macOS | 上下文感知 |
| zoxide | 目录跳转 | Linux / macOS | 快速切换目录 |
| LazyVim | Neovim 配置 | Linux / macOS | 适合终端编辑 |
| lazygit | Git 管理 | Linux / macOS | TUI Git 工具 |
| atuin | 命令历史增强 | Linux / macOS | 无限日志保留，需配置 APIKey |

## 包与环境工具
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| Python | 运行时 | 通用 | 环境变量管理必备 |
| zig | 运行时 | 通用 | 编译器 / 工具链 |
| rust | 运行时 | 通用 | 编译与开发 |
| node | 运行时 | 通用 | JavaScript / TypeScript |
| npm | 包管理 | 通用 | Node 包管理 |
| pnpm | 包管理 | 通用 | 快速安装 |
| yarn | 包管理 | 通用 | 备选方案 |
| winget | 安装工具 | Windows | Windows 包管理 |
| homebrew | 安装工具 | macOS / Linux | 包管理器 |
| apt | 安装工具 | Debian / Ubuntu | 系统包管理 |
| pip | Python 包管理 | 通用 | Python 依赖安装 |
| pipx | Python 包隔离安装 | 通用 | 命令行工具安装 |
| cargo | Rust 包管理 | 通用 | Rust 工具安装 |
| nvm | Node 版本管理 | 通用 | Node 版本切换 |
| zvm | Zig 版本管理 | 通用 | Zig 版本管理 |
| yt-dlp | 视频下载 | 通用 | 命令行下载工具 |
| ffmpeg | 媒体处理 | 通用 | 转码与录制 |
| typescript | 语言工具 | 通用 | TypeScript 支持 |
| tsx | 运行时 | 通用 | 直接执行 TS |
| gh | GitHub CLI | 通用 | GitHub 操作 |
| docker | 容器 | 通用 | 开发 / 运行环境 |

## 其他工具
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| @anthropic-ai/claude-code | AI 开发库 | 通用 | 代码辅助 |
| @google/gemini-cli | AI CLI | 通用 | Gemini 命令行 |
| wrangler | Cloudflare Workers | 通用 | 边缘应用部署 |

# 脚本

## 一键安装
```bash
bash <(curl -sSfL https://raw.githubusercontent.com/CatcherInSky/dotfiles/main/install.sh)
```

## install.sh — 软件安装
自动检测运行环境（Windows / WSL / Linux / macOS），安装对应平台的软件。

| 环境 | 行为 |
| --- | --- |
| Linux / WSL | apt 安装基础包，官方脚本安装 starship / zoxide / lazygit，GitHub CLI 通过官方 apt 源安装 |
| macOS | Homebrew 安装所有 formulas 和 casks（含 Docker Desktop、ghostty） |
| Windows | winget 批量安装 |

无法通过包管理器安装的工具（starship、zoxide、lazygit）均走各自官方 `curl | sh` 安装脚本，避免 apt 版本过旧或缺包问题。

## migrate_to_fish.sh — fish 环境变量迁移
将 `~/.bashrc` / `~/.bash_profile` / `~/.profile` 中的环境变量迁移到 fish：
- **PATH 条目**：通过 `fish_add_path` 添加（幂等，不重复）
- **其他 export 变量**：在 bash 子进程中求值（正确展开 `$HOME` 等），写入 `~/.config/fish/config.fish`

```bash
bash <(curl -sSfL https://raw.githubusercontent.com/CatcherInSky/dotfiles/main/migrate_to_fish.sh)
```

## setup_claude.sh — Claude Code 配置
- 将 `notify.sh` 复制到 `~/.claude/` 并设为可执行
- 合并 Stop / Notification hooks 到 `~/.claude/settings.json`（如已存在则跳过，不覆盖）
- 打印 claude-hud 插件安装指引

```bash
bash <(curl -sSfL https://raw.githubusercontent.com/CatcherInSky/dotfiles/main/setup_claude.sh)
```

> claude-hud 插件需在 Claude Code 会话中手动安装：
> ```
> /plugin marketplace add jarrodwatts/claude-hud
> /plugin install claude-hud
> /claude-hud:setup
> ```

## notify.sh — 跨平台桌面通知
| 环境 | 实现 |
| --- | --- |
| macOS | `osascript` |
| WSL2 | PowerShell Toast Notification |
| Linux | `notify-send` |
| 其他 | 终端响铃（fallback） |

# 设计 (暂不考虑)
- pencil? figma?

# 测试 (暂不考虑)
- 怎么看浏览器？
