#!/usr/bin/env bash
set -euo pipefail

# --------------------------
# 配置变量
# --------------------------
clone_dir="cleanup-repo"
protected_branches=("master" "main")
preview_mode="summary"  # 预览模式：summary/detail
main_branch="master"    # 主分支名称
date_threshold=10      # 分支数量阈值，超过此值时切换日期格式
date_format="year"     # 日期格式：month（按月）或 year（按年）

# --------------------------
# 函数定义
# --------------------------
print_header() { echo -e "\n\033[1;36m=== $1 ===\033[0m"; }
print_success() { echo -e "\033[1;32m✓ $1\033[0m"; }
print_warning() { echo -e "\033[1;33m⚠️ $1\033[0m"; }
print_error() { echo -e "\033[1;31m✗ $1\033[0m" >&2; exit 1; }

usage() {
    echo "用法: $0 <仓库URL> [选项]"
    echo "选项:"
    echo "  -p <mode>   预览模式: summary（摘要，默认） 或 detail（完整详情）"
    echo "  -t <num>    分支数量阈值（默认10），超过此值时切换日期格式"
    echo "  -f <format> 日期格式：month（按月）或 year（按年），默认为 month"
    exit 1
}

# --------------------------
# 0. 参数解析
# --------------------------
[[ $# -lt 1 ]] && usage
repo_url="$1"
shift

while getopts "p:t:f:" opt; do
    case $opt in
        p) preview_mode="$OPTARG" ;;
        t) date_threshold="$OPTARG" ;;
        f) date_format="$OPTARG" ;;
        *) usage ;;
    esac
done

# --------------------------
# 1. 初始化仓库
# --------------------------
print_header "初始化仓库克隆"
if [[ -d "$clone_dir" ]]; then
    read -p "目录 $clone_dir 已存在，是否删除？[y/N] " confirm
    [[ "$confirm" == [yY] ]] && rm -rf "$clone_dir" || exit 1
fi

git clone --bare "$repo_url" "$clone_dir" || print_error "仓库克隆失败"
cd "$clone_dir"

# --------------------------
# 2. 同步分支（覆盖本地分支）
# --------------------------
print_header "同步远程分支到本地"
git fetch origin "+refs/heads/*:refs/heads/*"
print_success "分支同步完成"

# --------------------------
# 3. 备份分支（简化版）
# --------------------------
print_header "备份分支"
git for-each-ref --format='delete %(refname)' refs/backups/ | git update-ref --stdin
git for-each-ref --format='%(refname) %(objectname)' refs/heads/ | while read -r refname hash; do
    branch_short="${refname#refs/heads/}"
    backup_ref="refs/backups/${branch_short}"
    git update-ref "$backup_ref" "$hash"
done
print_success "分支备份完成"

# --------------------------
# 4. 检查待删除分支并统计
# --------------------------
print_header "检查可删除分支"
protected_regex=$(IFS='|'; echo "${protected_branches[*]}")
merged_branches=$(
    git branch --merged master --format='%(refname:short)' | \
    grep -Ev "^($protected_regex)$"
)

[[ -z "$merged_branches" ]] && { print_success "无需删除分支"; exit 0; }

# 初始化统计数据结构
declare -a dates_array
declare -a authors_array

# 获取分支总数
branch_count=$(wc -l <<< "$merged_branches" | tr -d ' ')

# 根据分支数量确定日期格式
if [[ $branch_count -gt $date_threshold ]]; then
    if [[ $date_format == "month" ]]; then
        date_format_str="%Y-%m"
    elif [[ $date_format == "year" ]]; then
        date_format_str="%Y"
    else
        date_format_str="%Y-%m"
    fi
else
    date_format_str="%Y-%m-%d"
fi

# 收集分支统计信息
while IFS='|' read -r branch date author; do
    # 使用date命令转换日期格式
    date_key=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "${date}" "+$date_format_str" 2>/dev/null || echo "${date%% *}")
    dates_array+=($date_key)
    authors_array+=($author)
done < <(
    git branch --merged $main_branch --format="%(refname:short)|%(committerdate:iso)|%(authorname)" |
    grep -Ev "^($protected_regex)\|"
)


# --------------------------
# 5. 预览删除分支（含统计）
# --------------------------
print_header "待删除分支预览"
echo "以下分支将被删除 (共$(wc -l <<< "$merged_branches" | tr -d ' ')个):"

case "$preview_mode" in
    "detail")
        printf "%-30s %-15s %s\n" "分支名" "最后提交日期" "作者"
        git branch --merged master --format="%(refname:short)|%(committerdate:iso)|%(authorname)" | \
        grep -Ev "^($protected_regex)\|" | while IFS='|' read -r branch date author; do
            printf "%-30s %-15s %s\n" "$branch" "${date%% *}" "$author"
        done
        ;;
    "summary")
        # 按日期统计
        echo -e "\n\033[1m按最后提交日期统计：\033[0m"
        printf "%s\n" "${dates_array[@]}" | sort -r | uniq -c | while read -r count date; do
            printf "  %-12s : %2d 分支\n" "$date" "$count"
        done

        # 按作者统计（按分支数量倒序）
        echo -e "\n\033[1m按作者统计：\033[0m"
        printf "%s\n" "${authors_array[@]}" | sort | uniq -c | sort -rn | while read -r count author; do
            printf "  %-30s : %2d 分支\n" "$author" "$count"
        done
        ;;

esac

# --------------------------
# 6. 确认删除
# --------------------------
read -p "是否预览删除命令？[y/N] " preview
[[ "$preview" == [yY] ]] && printf "%s\n" "$merged_branches" | xargs -n1 printf "git push origin --delete %s\n"

read -p "确认删除以上分支？[y/N] " confirm
if [[ "$confirm" == [yY] ]]; then
    printf "%s\n" "$merged_branches" | xargs -n1 git push origin --delete
    print_success "分支删除完成"
else
    print_warning "操作已取消"
    exit 0
fi

# --------------------------
# 7. 清理环境
# --------------------------
cd ..
read -p "是否删除克隆的临时目录 $clone_dir？[y/N] " clean
[[ "$clean" == [yY] ]] && rm -rf "$clone_dir"
print_success "操作完成"
