#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# install.sh — 将本仓库安装为 AI Agent Skill
#
# 目标目录:  ${AGENT_SKILLS_DIR:-$HOME/.agents/skills}/gazebo-world-builder
#
# 用法:
#   ./install.sh            # link 模式 (默认): 建立符号链接
#   ./install.sh copy       # copy 模式: 复制文件 (排除 .git)
#   ./install.sh link
#   AGENT_SKILLS_DIR=/custom/skills ./install.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SKILL_NAME="gazebo-world-builder"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
TARGET="${AGENT_SKILLS_DIR}/${SKILL_NAME}"

MODE="${1:-link}"

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; }

case "$MODE" in
  link|copy) ;;
  -h|--help)
    sed -n 's/^# \{0,1\}//p' "$0"
    exit 0
    ;;
  *)
    err "未知模式: $MODE (仅支持 link / copy)"
    exit 2
    ;;
esac

# 目标已存在且不是符号链接 -> 跳过并警告
if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  warn "目标已存在且不是符号链接: $TARGET"
  warn "为避免覆盖, 已跳过。如确需重装, 请先手动备份或删除该目录。"
  exit 0
fi

mkdir -p "$AGENT_SKILLS_DIR"

if [[ "$MODE" == "link" ]]; then
  log "link 模式: $TARGET -> $REPO_DIR"
  ln -sfn "$REPO_DIR" "$TARGET"
else
  log "copy 模式: 复制到 $TARGET"
  # 先清理可能存在的旧符号链接
  [[ -L "$TARGET" ]] && rm -f "$TARGET"
  mkdir -p "$TARGET"
  for item in SKILL.md scripts README.md LICENSE; do
    [[ -e "$REPO_DIR/$item" ]] || { warn "缺少 $item, 跳过"; continue; }
    cp -R "$REPO_DIR/$item" "$TARGET/"
  done
fi

log "安装完成: $TARGET"
log "请重启你的 AI 工具, 或运行 /skills 查看已安装技能。"
