#!/bin/zsh
# ============================================================
# save.sh — 缠论分析快速存档脚本
# 用法：./save.sh "提交说明"
#   或：./save.sh          （不传参数则自动生成时间戳说明）
# ============================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# 检查是否有变动
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "✅ 没有需要保存的变动，工作区已是最新状态。"
  exit 0
fi

# 提交说明
if [ -n "$1" ]; then
  MSG="$1"
else
  MSG="snapshot: $(date '+%Y-%m-%d %H:%M') 分析进度存档"
fi

git add -A
git commit -m "$MSG"

echo ""
echo "✅ 已保存版本：$MSG"
echo ""
git log --oneline -5
