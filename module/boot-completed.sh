#!/system/bin/sh
# ============================================================
# Game Shield 开机完成阶段（boot-completed）
# 记录启动快照；任何失败静默退出
# ============================================================
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SELF_DIR/common/functions.sh"
ensure_dirs
ensure_config

log INFO "系统启动完成（boot-completed）"
{
  echo "  boot_completed=$(getprop sys.boot_completed)"
  echo "  selinux=$(selinux_state)"
  echo "  modules=$(module_ids | wc -l)"
} >> "$GS_LOG" 2>/dev/null

if [ -f "$GS_STATE/game.state" ] && [ "$(sed -n 's/^APPLIED=//p' "$GS_STATE/game.state" 2>/dev/null)" = "1" ]; then
  log INFO "提醒: 游戏兼容模式生效中，游戏结束后请执行 su -c gs.sh game off 恢复原环境"
fi
exit 0
