#!/system/bin/sh
# ============================================================
# Game Shield 安装阶段（customize.sh）
# 在模块刷入时执行；MODPATH 为模块解压目录
# ============================================================
ui_print() { echo "$@"; }

MODDIR="${MODPATH:-$PWD}"
GS_DIR=/data/adb/gs_guard

ui_print "=========================================="
ui_print " Game Shield 游戏环境隔离与诊断"
ui_print " 版本: 1.0.0 | 模块ID: gs_guard"
ui_print "=========================================="

# --- KernelSU 检查 ---
KSUVER=""
[ -f /data/adb/ksu/ksu_version ] && KSUVER=$(cat /data/adb/ksu/ksu_version 2>/dev/null)
if [ -z "$KSUVER" ]; then
  ui_print "! 警告: 未检测到 KernelSU（ksu_version）"
  ui_print "! 本模块为 KernelSU 设计，其他 Root 方案不保证可用"
else
  ui_print "- KernelSU 版本: $KSUVER"
fi
if command -v ksud >/dev/null 2>&1; then
  ui_print "- ksud: 可用"
else
  ui_print "! ksud 不可用（旧版本 KernelSU？模块核心功能不受影响，"
  ui_print "! 停用/恢复通过标志文件机制实现，但 WebUI 可能不可用）"
fi

# --- 配置初始化（保留已有配置，不覆盖）---
mkdir -p "$GS_DIR" 2>/dev/null
if [ ! -f "$GS_DIR/config" ]; then
  if [ -f "$MODDIR/common/config.default" ]; then
    cp "$MODDIR/common/config.default" "$GS_DIR/config" 2>/dev/null
  else
    cat > "$GS_DIR/config" <<'EOF'
TARGET_PACKAGE=com.tencent.tmdf
MANAGED_MODULES=all
EXCLUDED_MODULES=gs_guard
DIAG_INTERVAL=2
DIAG_RESUME_ON_BOOT=0
AUTO_RESTORE_HOURS=0
LOG_KEEP_DAYS=7
EOF
  fi
  ui_print "- 已创建配置文件: $GS_DIR/config"
else
  ui_print "- 检测到已有配置，保留不覆盖"
fi

# --- 脚本权限 ---
chmod +x "$MODDIR/bin/gs.sh" "$MODDIR/bin/gsdiag.sh" 2>/dev/null
chmod +x "$MODDIR"/*.sh 2>/dev/null

# --- 目标游戏检测 ---
TPKG=$(sed -n 's/^TARGET_PACKAGE=//p' "$GS_DIR/config" 2>/dev/null)
if [ -n "$TPKG" ] && pm list packages 2>/dev/null | grep -qx "package:$TPKG"; then
  ui_print "- 目标游戏已检测到安装: $TPKG"
else
  ui_print "! 目标游戏未检测到（包名 $TPKG）"
  ui_print "! 安装后执行: su -c gs.sh find-pkg tencent 核对包名并修改配置"
fi

ui_print "- 快捷命令: su -c gs.sh help"
ui_print "- 状态目录: $GS_DIR"
ui_print "=========================================="
