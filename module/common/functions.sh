#!/system/bin/sh
# ============================================================
# Game Shield 公共函数库
# 兼容性: 仅使用 POSIX sh 语法（Android 默认 sh = mksh）
# 本库所有函数必须容错：任何环境异常都不允许导致启动失败
# ============================================================

SELF_ID="gs_guard"
GS_VERSION="1.0.0"
GS_DIR="/data/adb/$SELF_ID"
GS_CONF="$GS_DIR/config"
GS_LOG_DIR="$GS_DIR/logs"
GS_LOG="$GS_LOG_DIR/gs.log"
GS_STATE="$GS_DIR/state"
GS_RUN="$GS_DIR/run"
MODULES_DIR="/data/adb/modules"
KSU_DIR="/data/adb/ksu"
DL_DIR="/sdcard/Download"

# ---------- 基础工具 ----------
now_ts() { date '+%Y-%m-%d %H:%M:%S'; }
now_epoch() { date '+%s'; }

log() {
  # log <级别> <消息>
  mkdir -p "$GS_LOG_DIR" 2>/dev/null
  echo "[$(now_ts)] [$1] $2" >> "$GS_LOG" 2>/dev/null
  SZ=$(wc -c < "$GS_LOG" 2>/dev/null || echo 0)
  if [ "$SZ" -gt 262144 ]; then
    tail -n 1500 "$GS_LOG" > "$GS_LOG.tmp" 2>/dev/null
    mv -f "$GS_LOG.tmp" "$GS_LOG" 2>/dev/null
  fi
}

ensure_dirs() {
  mkdir -p "$GS_DIR" "$GS_LOG_DIR" "$GS_STATE" "$GS_RUN" 2>/dev/null
  touch "$GS_LOG" 2>/dev/null
}

conf_get() {
  sed -n "s/^[[:space:]]*$1=//p" "$GS_CONF" 2>/dev/null | head -n1
}

ensure_config() {
  if [ ! -f "$GS_CONF" ]; then
    mkdir -p "$GS_DIR" 2>/dev/null
    cat > "$GS_CONF" <<'EOF'
# ================= Game Shield 配置 =================
# 目标游戏包名（必须与实际一致，可用: gs.sh find-pkg tencent 核对）
TARGET_PACKAGE=com.tencent.tmdf

# 游戏模式管理的模块: all=除自身与 EXCLUDED_MODULES 外全部；或写空格分隔的模块 id
MANAGED_MODULES=all

# 永远不管理的模块 id（空格分隔）
EXCLUDED_MODULES=gs_guard

# 诊断采样间隔（秒）
DIAG_INTERVAL=2

# 重启后自动恢复诊断会话（1=是 0=否）
DIAG_RESUME_ON_BOOT=0

# 自动恢复：游戏模式开启超过 N 小时后自动恢复原环境（0=禁用）
AUTO_RESTORE_HOURS=0

# 日志保留天数
LOG_KEEP_DAYS=7
EOF
    log INFO "已创建默认配置"
  fi
}

load_conf() {
  ensure_config
  TARGET_PACKAGE=$(conf_get TARGET_PACKAGE); [ -z "$TARGET_PACKAGE" ] && TARGET_PACKAGE="com.tencent.tmdf"
  MANAGED_MODULES=$(conf_get MANAGED_MODULES); [ -z "$MANAGED_MODULES" ] && MANAGED_MODULES="all"
  EXCLUDED_MODULES=$(conf_get EXCLUDED_MODULES); [ -z "$EXCLUDED_MODULES" ] && EXCLUDED_MODULES="gs_guard"
  DIAG_INTERVAL=$(conf_get DIAG_INTERVAL); [ -z "$DIAG_INTERVAL" ] && DIAG_INTERVAL=2
}

# ---------- 模块管理 ----------
# 列出全部模块目录名（有 module.prop 才算模块）
module_ids() {
  ls -1 "$MODULES_DIR" 2>/dev/null | while read -r n; do
    [ -d "$MODULES_DIR/$n" ] || continue
    [ -f "$MODULES_DIR/$n/module.prop" ] || continue
    echo "$n"
  done
}

mod_prop() { # mod_prop <dir> <key>
  sed -n "s/^$2=//p" "$1/module.prop" 2>/dev/null | head -n1
}

mod_is_disabled() { # echo 1/0
  if [ -e "$MODULES_DIR/$1/disable" ]; then echo 1; else echo 0; fi
}

mod_disable() {
  # 停用模块：写 disable 标志（KernelSU/Magisk 在启动时读取的标志文件，版本无关的可靠机制）
  d="$MODULES_DIR/$1"
  [ -d "$d" ] || return 1
  : > "$d/disable" 2>/dev/null
  # 新版 KernelSU 支持 ksud module disable（尽力而为，失败不影响标志文件机制）
  if command -v ksud >/dev/null 2>&1; then
    ksud module disable "$1" >/dev/null 2>&1
  fi
  return 0
}

mod_enable() {
  d="$MODULES_DIR/$1"
  [ -d "$d" ] || return 1
  rm -f "$d/disable" 2>/dev/null
  if command -v ksud >/dev/null 2>&1; then
    ksud module enable "$1" >/dev/null 2>&1
  fi
  return 0
}

# ---------- 疑似注入/Hook/隐藏 判定 ----------
SUSPECT_MOD_RE="zygisk|shamiko|riru|lsposed|lsp|xposed|edxposed|substrate|frida|gadget|hook|cheat|maphack|aimbot|触摸|连点|自动|注入|隐藏|roothide|denylist"
SUSPECT_PKG_RE="org.lsposed.manager|org.lsposed.lspatch|de.robv.android.xposed.installer|re.frida.server|com.topjohnwu.magisk"

mod_is_suspect() {
  # mod_is_suspect <模块目录> → 输出原因（空=不疑）
  d="$1"
  txt=$(cat "$d/module.prop" 2>/dev/null | tr 'A-Z' 'a-z')
  if [ -n "$txt" ] && echo "$txt" | grep -Eq "$SUSPECT_MOD_RE"; then
    echo "声明中包含疑似注入/Hook/隐藏相关关键词"
  fi
}

# ---------- 进程 ----------
find_procs_by_pattern() {
  # find_procs_by_pattern <正则> → 输出 "PID CMD" 行
  re="$1"
  for p in /proc/[0-9]*; do
    [ -d "$p" ] || continue
    [ -r "$p/cmdline" ] || continue
    pid=${p##*/}
    cmd=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null)
    [ -n "$cmd" ] || continue
    if echo "$cmd" | grep -Eqi "$re"; then
      echo "$pid $cmd"
    fi
  done
}

game_pids() {
  # game_pids → 输出目标游戏全部 PID（按 argv[0] 精确匹配包名）
  for p in /proc/[0-9]*; do
    [ -d "$p" ] || continue
    [ -r "$p/cmdline" ] || continue
    pid=${p##*/}
    argv0=$(tr '\0' '\n' < "$p/cmdline" 2>/dev/null | head -n1)
    if [ "$argv0" = "$TARGET_PACKAGE" ]; then echo "$pid"; fi
  done
}

# ---------- 系统状态 ----------
selinux_state() {
  if [ -r /sys/fs/selinux/enforce ]; then
    E=$(cat /sys/fs/selinux/enforce 2>/dev/null)
    if [ "$E" = "1" ]; then echo "Enforcing"; elif [ "$E" = "0" ]; then echo "Permissive"; else echo "未知"; fi
  else
    echo "不可读"
  fi
}

prop_dump() { getprop 2>/dev/null | sort; }
