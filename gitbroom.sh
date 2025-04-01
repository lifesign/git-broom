#!/bin/bash
set -euo pipefail  # 严格模式：任何错误退出、未定义变量报错、管道错误终止

# --------------------------
# 配置变量（可外部传入）
# --------------------------
clone_dir="cleanup-repo"
protected_branches=("master" "main" "dev") # 可扩展的保护分支列表
preview_mode="summary"  # 预览模式：summary/detail

# --------------------------
# 函数定义
# --------------------------
print_header() { echo -e "\n\033[1;36m=== $1 ===\033[0m";}  # 青色标题
print_success() { echo -e "\033[1;32m✓ $1\033[0m";}  # 绿色成功提示
print_warning() { echo -e "\033[1;33m⚠️ $1\033[0m";}  # 黄色警告
print_error() { echo -e "\033[1;31m✗ $1\033[0m" >&2; exit 1; }

usage() {
    echo "用法: $0 <仓库URL> [选项]"
    echo "选项:"
    echo "  -p <mode>   预览模式: summary（摘要，默认） 或 detail（完整详情）"
    exit 1
}

# --------------------------
# 0. 参数解析
# --------------------------
[[ $# -lt 1 ]] && usage
repo_url="$1"
shift
while getopts "p:" opt; do
    case $opt in
        p) preview_mode="$OPTARG" ;;
        *) usage ;;
    esac
done

# --------------------------
# 1. 创建隔离环境
# --------------------------
print_header "初始化仓库克隆"
if [[ -d "$clone_dir" ]]; then
    read -p "目录 $clone_dir 已存在，是否删除？[y/N] " confirm
    [[ "$confirm" == [yY] ]] && rm -rf "$clone_dir" || exit 1
fi

git clone --bare "$repo_url" "$clone_dir" || print_error "仓库克隆失败"
cd "$clone_dir"

# --------------------------
# 2. 同步远端分支到本地
# --------------------------
print_header "同步远程分支"
git fetch origin "+refs/heads/*:refs/heads/*"
print_success "分支同步完成"

# --------------------------
# 3. 备份本地分支到 refs/backups/
# --------------------------
print_header "备份分支"
# 清理旧备份（避免残留）
git for-each-ref --format='delete %(refname)' refs/backups/ | git update-ref --stdin

# 创建新备份
git for-each-ref --format='%(refname) %(objectname)' refs/heads/ | while read -r refname hash; do
    branch_short="${refname#refs/heads/}"
    backup_ref="refs/backups/${branch_short}"
    git update-ref "$backup_ref" "$hash"
    echo "Backup: $refname (${hash:0:7}) → $backup_ref"
done
print_success "分支备份完成"

# --------------------------
# 4. 确认待删除分支
# --------------------------
print_header "检查可删除分支"
# 动态生成保护分支的正则表达式
protected_regex=$(IFS='|'; echo "${protected_branches[*]}")

# 获取已合并到 master 的分支
merged_branches=$(
    git branch --merged master --format='%(refname:short)' | \
    grep -Ev "^($protected_regex)$"
)

if [[ -z "$merged_branches" ]]; then
    print_success "没有需要删除的分支"
    exit 0
fi

# 显示详细信息（提交时间、作者、哈希）
echo "以下分支将被删除："
git branch --merged master --format="%(committerdate:iso) | %(authorname) | %(objectname:short) | %(refname:short)" | \
    grep -Ev "^.*\|($protected_regex)$"

# --------------------------
# 5. 交互式删除确认
# --------------------------
read -p "是否预览删除命令？[y/N] " preview
if [[ "$preview" == [yY] ]]; then
    echo "预览模式（实际不会删除）:"
    echo "$merged_branches" | xargs -n1 printf "git push origin --delete %s\n"
fi

read -p "确认删除以上分支？[y/N] " confirm
if [[ "$confirm" == [yY] ]]; then  # 只有明确输入 y/Y 才执行删除
    echo "$merged_branches" | xargs -n1 git push origin --delete
    print_success "分支删除完成"
else
    print_warning "操作已取消"
    exit 0
fi

# --------------------------
# 6. 清理环境（可选）
# --------------------------
cd ..
read -p "是否删除克隆的临时目录 $clone_dir？[y/N] " clean
if [[ "$clean" == [yY] ]]; then
    rm -rf "$clone_dir"
    print_success "清理完成"
fi
print_success "操作完成"
