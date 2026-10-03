#!/system/bin/sh
# ============================================================
# Game Shield 卸载阶段（uninstall.sh）
# KernelSU 会在移除模块前调用本脚本
# 职责：恢复被停用的模块、备份日志与报告、清理数据目录
# ============================================================
GS_DIR=/data/adb/gs_guard
GS_STATE="$GS_DIR/state"
MODULES_DIR=/data/adb/modules

echo "Game Shield 卸载清理中..."

# 1) 若游戏模式仍开启，先恢复被停用的模块
ST="$GS_STATE/game.state"
if [ -f "$ST" ] && [ "$(sed -n 's/^APPLIED=//p' "$ST" 2>/dev/null)" = "1" ]; then
  PREV=$(sed -n 's/^MODULES_PREV_STATE=//p' "$ST" 2>/dev/null)
  for item in $PREV; do
    id=${item%%:*}
    if [ "${item##*:}" = "enabled" ]; then
      rm -f "$MODULES_DIR/$id/disable" 2>/dev/null
      echo "  已恢复模块: $id"
    fi
  done
fi

# 2) 结束残留的诊断循环
pkill -f "gsdiag.sh" 2>/dev/null

# 3) 移除快捷命令
rm -f /data/adb/ksu/bin/gs.sh 2>/dev/null

# 4) 备份日志与报告到公共存储
BK="/sdcard/Download/gs_guard_uninstall_$(date '+%Y%m%d-%H%M%S')"
mkdir -p "$BK" 2>/dev/null
cp -r "$GS_DIR/logs" "$BK/" 2>/dev/null
cp -r "$GS_DIR/state" "$BK/" 2>/dev/null
echo "  日志已备份到: $BK"

# 5) 清理
rm -rf "$GS_DIR" 2>/dev/null
echo "  已清理 $GS_DIR"
echo "卸载完成"
exit 0
