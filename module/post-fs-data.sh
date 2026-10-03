#!/system/bin/sh
# ============================================================
# Game Shield 早期阶段（post-fs-data）
# 设计原则：最小化操作，任何失败都必须静默退出，绝不影响开机
# ============================================================
GS_DIR=/data/adb/gs_guard
mkdir -p "$GS_DIR/logs" 2>/dev/null
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] post-fs-data 阶段执行" >> "$GS_DIR/logs/gs.log" 2>/dev/null
exit 0
