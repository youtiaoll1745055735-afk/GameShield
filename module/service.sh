#!/system/bin/sh
# ============================================================
# Game Shield 服务阶段（KernelSU service.sh，late_start 后执行）
# 职责：初始化目录、配置默认值、自动恢复、诊断会话恢复
# 任何异常都不允许影响系统启动
# ============================================================

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SELF_DIR/common/functions.sh"
ensure_dirs
ensure_config

log INFO "service.sh 阶段执行（设备: $(getprop ro.product.model) / Android $(getprop ro.build.version.release)）"

# 清理过期日志
KEEP="${LOG_KEEP_DAYS:-7}"
find "$GS_LOG_DIR" -name 'diag_*.log' -mtime +"$KEEP" -delete 2>/dev/null
find "$GS_STATE" -maxdepth 1 -name 'diag_*' -mtime +"$KEEP" -exec rm -rf {} + 2>/dev/null

# 注册快捷命令（KernelSU 的 su 会话 PATH 含 /data/adb/ksu/bin）
mkdir -p /data/adb/ksu/bin 2>/dev/null
if [ ! -e /data/adb/ksu/bin/gs.sh ] 2>/dev/null; then
  ln -s "$SELF_DIR/bin/gs.sh" /data/adb/ksu/bin/gs.sh 2>/dev/null
fi

# 游戏模式提醒
if [ -f "$GS_STATE/game.state" ] && [ "$(sed -n 's/^APPLIED=//p' "$GS_STATE/game.state" 2>/dev/null)" = "1" ]; then
  log INFO "提醒: 游戏兼容模式当前生效（$(sed -n 's/^MODULES_DISABLED=//p' "$GS_STATE/game.state")）。游戏结束后执行: su -c gs.sh game off"
fi

# 超时自动恢复（AUTO_RESTORE_HOURS > 0 时）
AUTO=$(conf_get AUTO_RESTORE_HOURS)
[ -z "$AUTO" ] && AUTO=0
if [ "$AUTO" -gt 0 ] 2>/dev/null && [ -f "$GS_STATE/game.state" ]; then
  if [ "$(sed -n 's/^APPLIED=//p' "$GS_STATE/game.state")" = "1" ]; then
    START_EPOCH=$(sed -n 's/^START_EPOCH=//p' "$GS_STATE/game.state")
    NOW=$(now_epoch)
    if [ -n "$START_EPOCH" ] && [ "$START_EPOCH" -gt 0 ] 2>/dev/null && [ $((NOW - START_EPOCH)) -gt $((AUTO * 3600)) ]; then
      log WARN "自动恢复触发（游戏模式已持续超过 ${AUTO} 小时）"
      PREV=$(sed -n 's/^MODULES_PREV_STATE=//p' "$GS_STATE/game.state")
      for item in $PREV; do
        id=${item%%:*}
        [ "${item##*:}" = "enabled" ] && rm -f "$MODULES_DIR/$id/disable" 2>/dev/null
      done
      mv "$GS_STATE/game.state" "$GS_STATE/game.state.auto-closed" 2>/dev/null
      log INFO "自动恢复完成（重启后完全生效）"
    fi
  fi
fi

# 诊断会话恢复（可选，默认关闭）
if [ -f "$GS_STATE/diag.state" ]; then
  ACT=$(sed -n 's/^ACTIVE=//p' "$GS_STATE/diag.state" 2>/dev/null)
  RESUME=$(conf_get DIAG_RESUME_ON_BOOT)
  if [ "$ACT" = "1" ] && [ "$RESUME" = "1" ]; then
    SID=$(sed -n 's/^SESSION=//p' "$GS_STATE/diag.state")
    nohup sh "$SELF_DIR/bin/gsdiag.sh" "$SID" >/dev/null 2>&1 &
    sed -i "s/^PID=.*/PID=$!/" "$GS_STATE/diag.state" 2>/dev/null
    log INFO "重启后恢复诊断会话 $SID"
  fi
fi

exit 0
