# 🧹 GitBroom - Git分支清理工具

一个强大的Git分支清理工具，帮助你轻松管理和清理已合并的分支。

## ✨ 特性

- 🔍 智能分支检测：自动识别已合并到主分支的分支
- 🛡️ 分支保护：内置对主要分支（master/main等）的保护机制
- 📊 分支统计：按日期和作者展示分支分布情况
- 💾 自动备份：清理前自动备份所有分支到refs/backups/
- 🔄 交互式操作：提供确认机制，防止误删分支
- 👀 预览模式：支持详细(detail)和摘要(summary)两种预览方式

## 🚀 快速开始

### 前置要求

- Git环境
- Bash 4.0+

### 安装步骤

1. 下载脚本
```bash
# 克隆仓库
git clone https://github.com/lifesign/git-broom.git
cd gitbroom

# 或直接下载脚本文件
curl -O https://raw.githubusercontent.com/lifesign/git-broom/refs/heads/main/gitbroom
```

2. 设置执行权限
```bash
chmod +x gitbroom
```

3. 配置环境变量（可选）
```bash
# 将以下内容添加到 ~/.bashrc 或 ~/.zshrc
export PATH="$PATH:/path/to/gitbroom"

# 使配置生效
source ~/.bashrc  # 或 source ~/.zshrc
```

### 使用方法

```bash
gitbroom <仓库URL> [选项]
```

### 命令选项

- `-p <mode>`: 预览模式
  - `summary`: 按日期和作者统计（默认）
  - `detail`: 显示每个分支的详细信息
- `-t <num>`: 分支数量阈值（默认10），超过此值时切换日期格式
- `-f <format>`: 日期格式
  - `month`: 按月显示（默认）
  - `year`: 按年显示

## ⚙️ 配置说明

### 核心配置项

```bash
clone_dir="cleanup-repo"          # 临时克隆目录
protected_branches=("master" "main") # 受保护的分支
preview_mode="summary"            # 预览模式：summary/detail
main_branch="master"              # 主分支名称
date_threshold=10                 # 分支数量阈值
date_format="year"                # 日期格式：month/year
```

## 🔍 功能详解

### 1. 初始化和同步
- 克隆目标仓库到临时目录
- 同步所有远程分支到本地

### 2. 分支备份
- 自动备份所有分支到refs/backups/
- 清理旧的备份记录

### 3. 分支分析
- 识别已合并到主分支的分支
- 排除受保护分支
- 收集分支统计信息（提交日期、作者等）

### 4. 统计展示
- 按日期统计分支分布
- 按作者统计分支数量
- 支持不同日期格式（年/月）的动态切换

### 5. 交互式操作
- 预览待删除分支
- 确认删除操作
- 清理临时目录

## 🤝 贡献指南

欢迎提交Issue和Pull Request来帮助改进这个工具！

## 📝 许可证

[MIT](LICENSE)
