# 快速参考

## 新工具集成说明

### 已完成的改进
- ✅ zoxide：自动 fish 集成，支持 `z` 命令快速跳转
- ✅ yazi：新增下载和安装脚本，现代文件管理器
- ✅ atuin：新增下载和安装，Fish 自动初始化
- ✅ migrate_to_fish.sh：增强配置迁移，自动初始化所有工具

---

## 验证安装

在 fish shell 中测试：

```fish
# 1. zoxide
which z
zoxide query --list  # 查看访问记录

# 2. yazi  
yazi --version
yazi ~  # 启动文件管理器

# 3. atuin
atuin --version
atuin search  # 交互式搜索历史

# 4. 检查 fish 配置
cat ~/.config/fish/config.fish
```

---

## 配置文件位置

- `~/.config/fish/config.fish` - Fish shell 配置
- `~/.config/starship.toml` - Starship prompt 配置  
- `~/.config/nvim/` - Neovim/LazyVim 配置
- `~/.nvm/` - Node Version Manager
- `~/.local/bin/` - 本地命令（zoxide, yazi）

---

## 后续可选配置

### atuin 云同步
```bash
atuin account register  # 或 atuin account login
atuin sync
```

### yazi 扩展配置
```bash
mkdir -p ~/.config/yazi/{plugins,themes}
# 可从 https://github.com/sxyazi/awesome-yazi 添加插件
```

### fish 自定义函数
编辑 `~/.config/fish/config.fish` 添加自定义函数和别名

---

## 故障排除

| 问题 | 解决方案 |
| --- | --- |
| zoxide 命令未找到 | `zoxide init fish \| source` |
| yazi 无法下载 | 检查网络连接或手动下载 |
| atuin 历史为空 | 新工具需要运行一些命令后才有记录 |
| fish 配置未加载 | 运行 `source ~/.config/fish/config.fish` |

