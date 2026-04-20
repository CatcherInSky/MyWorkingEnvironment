# 软件

## 通用
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| copyQ | 剪切板历史管理 | Windows / mac / Linux | 常用剪贴板工具 |
| snipaste | 屏幕截图与贴图 | Windows / mac / Linux | 简洁截图工具 |
| Git | 版本控制 | 通用 | 必装 |
|  | APIKey 集中管理 | 通用 | 暂不考虑 |
|  | 密码保管 | 通用 | 暂不考虑 |

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
| Gopeed | 快捷启动 | Windows | 提高效率 |
| TranslucentTB | 任务栏透明 | Windows | 美化任务栏 |
| ImageGlass | 图片浏览 | Windows | 轻量图片查看器 |
| Flow Launch | 启动器 | Windows | 类似 Spotlight |
| Everything | 文件搜索 | Windows | 快速查找文件 |
| Hotkey Screener | 快捷键测试 | Windows | 检查按键输入 |

# 终端方案

## 主要组件
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| ghostty | 终端性能优化 | Linux / macOS | 速度快 |
| fish | 智能 shell | Linux / macOS | 语法高亮、Tab 补全 |
| Starship | prompt 美化 | Linux / macOS | 上下文感知 |
| zoxide | 目录跳转 | Linux / macOS | 快速切换目录 |
| LazyVim | Neovim 配置 | Linux / macOS | 适合终端编辑 |
| lazygit | Git 管理 | Linux / macOS | TUI Git 工具 |
| autin | 命令行智能助手 | Linux / macOS | 无限日志保留，需配置 APIKey |

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
| pkg | 安装工具 | 通用 | 系统软件安装 |
| winget | 安装工具 | Windows | Windows 包管理 |
| snap | 安装工具 | Linux | 通用软件安装 |
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
| pyenv | | | |

## 其他工具
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| @anthropic-ai/claude-code | AI 开发库 | 通用 | 代码辅助 |
| @google/gemini-cli | AI CLI | 通用 | Gemini 命令行 |
| webpack | 前端构建 | 通用 | 打包工具 |
| wrangler | Cloudflare Workers | 通用 | 边缘应用部署 |

# 安装脚本

无需克隆仓库，直接用 curl 运行。两个脚本相互独立，按需选用。

## init.sh — 终端环境一键安装

安装并配置完整终端方案：ghostty、fish、starship、zoxide、atuin、neovim（LazyVim）、lazygit、yazi 等。自动检测 macOS / Linux / Windows，写入对应平台的配置文件。

```bash
bash <(curl -sSfL https://raw.githubusercontent.com/CatcherInSky/MyWorkingEnvironment/main/init.sh)
```

运行完成后执行 `exec fish` 或重启终端切换到 fish shell。

## setup_claude.sh — Claude Code 配置

写入 `~/.claude/notify.sh`（跨平台桌面通知脚本），并向 `~/.claude/settings.json` 注入两个 hooks：
- **Stop hook**：Claude 停止等待输入时弹出”任务已完成”通知
- **Notification hook**：Claude 发出通知事件时弹出对应消息

```bash
bash <(curl -sSfL https://raw.githubusercontent.com/CatcherInSky/MyWorkingEnvironment/main/setup_claude.sh)
```

运行完成后，在 Claude Code 会话中手动安装 claude-hud 插件：

```
/plugin marketplace add jarrodwatts/claude-hud
/plugin install claude-hud
/claude-hud:setup
```

# 设计 (暂不考虑)
- pencil? snitich? figma?

# 测试 (暂不考虑)
- 怎么看浏览器？

