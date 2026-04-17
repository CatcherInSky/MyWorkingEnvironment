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

## 其他工具
| 软件名称 | 作用 | 运行环境 | 备注 |
| --- | --- | --- | --- |
| @anthropic-ai/claude-code | AI 开发库 | 通用 | 代码辅助 |
| @google/gemini-cli | AI CLI | 通用 | Gemini 命令行 |
| webpack | 前端构建 | 通用 | 打包工具 |
| wrangler | Cloudflare Workers | 通用 | 边缘应用部署 |

# 安装脚本

## 安装脚本功能说明
- 脚本文件：`install.sh`
- 自动检测运行环境：Windows、WSL/Linux、macOS
- Windows 环境：安装“通用”软件和 Windows 专用软件
- WSL 或原生 Linux：安装“终端方案”中的所有包与终端工具
- macOS：安装“通用”软件、macOS 专用软件，以及“终端方案”里的所有包
- 迁移 shell 环境变量：将 `bash` / `zsh` 中的 `export` 内容转换到 `fish` 配置中
- 若无法直接安装，脚本会下载对应安装包到 `~/Downloads/installers`

## 使用方法
1. 下载或克隆仓库到本地：
   ```bash
   git clone <仓库地址>
   cd AI-
   ```
2. 赋予执行权限并运行：
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
3. Windows 原生环境下，如果你使用 Git Bash 或 WSL，也可以同样执行：
   ```bash
   bash install.sh
   ```
4. 运行完成后，脚本会在终端输出安装结果和迁移状态。

# claude

## 1. 通过 hooks 配置桌面 Notification
- 目标：完成或询问中途弹出通知
- 实现方式：通过 shell / 应用 hooks 调用桌面通知命令
- 示例：
  - macOS: `osascript -e 'display notification "任务完成" with title "Claude"'`
  - Linux: `notify-send "Claude" "任务完成"`
  - Windows: 使用 PowerShell `New-BurntToastNotification` 或第三方通知工具
- 说明：需要在任务流程或 API 调用完成时触发 hook，并将结果传给通知命令

```
// ~/.claude/settings.json
"hooks: {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/notify.sh 'Claude Code' '任务已完成，等待您的输入' 2>/dev/null || true",
            "async": true
          }
        ]
      }
    ],
}
```

## 2. 配置 claude-hud
- 安装插件：
  - `/plugin marketplace add jarrodwatts/claude-hud`
  - `/plugin install claude-hud`
- 初始化：
  - `/claude-hud:setup`
- 备注：
  - 该插件用于增强 Claude HUD 交互体验
  - 需要确认是否已安装相应的插件管理器和环境
  - 如果需要 hook 通知，可在 HUD 配置中添加自定义命令调用桌面通知插件

# 设计 (暂不考虑)
- pencil? snitich? figma?

# 测试 (暂不考虑)
- 怎么看浏览器？

