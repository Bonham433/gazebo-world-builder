#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# uninstall.sh — 卸载 gazebo-world-builder 技能
#
# 仅删除:  ${AGENT_SKILLS_DIR:-$HOME/.agents/skills}/gazebo-world-builder
#
# 安全策略:
#   * 符号链接 -> 直接删除链接本身
#   * 普通目录 -> 仅当其中 SKILL.md 的 name 为本技能时才删除
#   * 其他情况 -> 跳过, 不动用户文件
# ---------------------------------------------------------------------------
set -euo pipefail

SKILL_NAME="gazebo-world-builder"
AGENT_SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
TARGET="${AGENT_SKILLS_DIR}/${SKILL_NAME}"

log()  { printf '\033[1;34m[uninstall]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }

if [[ -L "$TARGET" ]]; then
  log "移除符号链接: $TARGET"
  rm -f "$TARGET"
  log "完成。"
  exit 0
fi

if [[ -d "$TARGET" ]]; then
  # 确认该目录确实由本技能安装 (frontmatter name 匹配)
  if [[ -f "$TARGET/SKILL.md" ]] && \
     grep -qE "^name:[[:space:]]*${SKILL_NAME}[[:space:]]*$" "$TARGET/SKILL.md"; then
    log "移除技能目录: $TARGET"
    rm -rf "$TARGET"
    log "完成。"
  else
    warn "$TARGET 存在但不是本技能 (SKILL.md/name 不匹配), 已跳过。"
  fi
  exit 0
fi

warn "未安装: $TARGET 不存在, 无需卸载。"
