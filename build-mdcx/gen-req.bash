#!/bin/bash
# filepath: extract_dependencies.sh

# 提取 project.dependencies 到 requirements.txt 的脚本

set -e

# 默认输入和输出文件
PYPROJECT_FILE="${1:-pyproject.toml}"
REQUIREMENTS_FILE="${2:-requirements.txt}"

# 检查输入文件是否存在
if [[ ! -f "$PYPROJECT_FILE" ]]; then
    echo "错误：找不到文件 '$PYPROJECT_FILE'"
    exit 1
fi

echo "正在从 '$PYPROJECT_FILE' 提取依赖项到 '$REQUIREMENTS_FILE'..."

# 使用 awk 提取 dependencies 部分
awk '
    /^dependencies = \[/ {
        in_deps = 1
        next
    }
    in_deps && /^\]/ {
        in_deps = 0
        next
    }
    in_deps {
        # 移除前导空格和引号
        gsub(/^[ \t]*"/, "")
        gsub(/"[ \t]*,?[ \t]*$/, "")

        # 跳过注释行和空行
        if ($0 !~ /^[ \t]*#/ && $0 !~ /^[ \t]*$/) {
            print $0
        }
    }
' "$PYPROJECT_FILE" > "$REQUIREMENTS_FILE"

# 检查是否成功提取到依赖项
if [[ -s "$REQUIREMENTS_FILE" ]]; then
    echo "成功提取 $(wc -l < "$REQUIREMENTS_FILE") 个依赖项到 '$REQUIREMENTS_FILE'"
    echo ""
    echo "生成的 requirements.txt 内容："
    echo "=========================="
    cat "$REQUIREMENTS_FILE"
else
    echo "警告：没有找到依赖项或提取失败"
    exit 1
fi