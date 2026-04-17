# 脚本更新日志

## 更新内容（2026-04-17）

### install.sh 增强

#### 1. 完善 zoxide 配置  
- **新增函数**: `init_zoxide_for_fish()`
- 自动在 `~/.config/fish/config.fish` 中配置 zoxide 初始化
- 设置 `z` 别名替代 `cd` 命令
- 智能检测，避免重复配置

#### 2. 新增 yazi 安装支持
- **新增函数**: `install_yazi()`
- 自动检测 CPU 架构（x86_64 / aarch64）
- 支持 Linux 和 macOS
- 从 GitHub releases 下载最新版本
- 安装到 `~/.local/bin`
- 已添加到 Linux 和 macOS 的安装流程

#### 3. 新增 atuin 安装支持
- **新增函数**: `install_atuin()`
- **新增函数**: `init_atuin_for_fish()`
- 使用官方安装脚本最大兼容性
- 自动在 fish 中配置初始化
- 提示用户可选的云同步配置
- 已添加到 Linux 和 macOS 的安装流程

#### 4. 平台安装流程更新

**Linux**:
```bash
install_apt_base
install_zoxide && init_zoxide_for_fish
install_yazi
install_atuin && init_atuin_for_fish
# ... 其他工具
```

**macOS**:
- 在 Homebrew formulas 中添加 `atuin` 和 `yazi`
- 调用相同的初始化函数保持一致性

---

### migrate_to_fish.sh 增强

#### 1. 新增工具初始化函数
- **新增函数**: `init_zoxide_for_fish()`
  - 在 fish 配置中初始化 zoxide
  - 检查是否已配置，避免重复

- **新增函数**: `init_atuin_for_fish()`
  - 在 fish 配置中初始化 atuin
  - 提示云同步配置方法

#### 2. main 函数增强
- 迁移环境变量后，自动配置终端工具
- 新增"配置终端工具集成"步骤
- 提高用户体验

---

## 快速开始

### 完整安装（推荐首次运行）
```bash
bash <(curl -sSfL https://raw.githubusercontent.com/CatcherInSky/MyWorkingEnvironment/main/install.sh)
```

### 迁移到 Fish 并配置所有工具
```bash
bash <(curl -sSfL https://raw.githubusercontent.com/CatcherInSky/MyWorkingEnvironment/main/migrate_to_fish.sh)
```

---

## 已安装工具验证

安装后可以验证：

```fish
# 检查 zoxide
z --version
z /tmp  # 跳转到目录

# 检查 yazi
yazi --version
yazi  # 启动文件管理器

# 检查 atuin
atuin --version
atuin history list  # 查看命令历史

# 检查 fish 集成
type z       # 应该显示别名
functions    # 应该包含 __zoxide_* 函数
```

---

## 配置说明

### zoxide
- 在 fish 中使用 `z` 替代 `cd`
- 自动记录访问频率和最近性
- 示例: `z foo` 快速跳转到包含 foo 的目录

### yazi  
- 现代文件管理器，内置预览和搜索
- 快捷键：`q` 退出，`j/k` 上下移动，`l/h` 进入/返回父目录
- 支持文件预览和 MIME 类型关联

### atuin
- 增强的命令历史管理（无限保留）
- 可选云同步：运行 `atuin account register` 或 `atuin account login`
- 在 fish 中自动集成，Ctrl+R 搜索历史

---

## 故障排除

### zoxide 不工作
```bash
# 重新配置
zoxide init fish | source
alias cd z
```

### yazi 安装失败
```bash
# 手动安装
curl -fsSL https://github.com/sxyazi/yazi/releases/download/v26.1.22/yazi-x86_64-unknown-linux.zip -o /tmp/yazi.zip
unzip /tmp/yazi.zip -d ~/.local/bin
```

### atuin 需要云同步
```bash
# 登录或注册
atuin account register  # 新建账户
atuin account login     # 登录现有账户
atuin sync              # 同步数据
```
