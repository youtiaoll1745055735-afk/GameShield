#!/system/bin/sh
# ============================================================
# Game Shield 诊断采样循环（后台进程）
# 由 gs.sh diag start 启动，diag stop 终止
# 只读取系统信息，不触碰游戏进程/文件/内存
# ============================================================

SELF_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SELF_DIR/common/functions.sh"
load_conf

SID="$1"
[ -z "$SID" ] && exit 0
BASE="$GS_STATE/$SID"
LOGF="$GS_LOG_DIR/$SID.log"
INTERVAL="$DIAG_INTERVAL"
[ "$INTERVAL" -gt 0 ] 2>/dev/null || INTERVAL=2

LAST_GAME_PID=""
LAST_SUSPECT=""
CNT=0

log INFO "诊断循环启动（会话 $SID，间隔 ${INTERVAL}s）"
echo "$(date '+%H:%M:%S')|DIAG_BEGIN|interval=${INTERVAL}s target=$TARGET_PACKAGE" >> "$LOGF"

while [ -f "$GS_STATE/diag.state" ]; do
  ACTIVE=$(sed -n 's/^ACTIVE=//p' "$GS_STATE/diag.state" 2>/dev/null)
  [ "$ACTIVE" = "1" ] || break
  TS=$(date '+%H:%M:%S')

  # --- 游戏进程起止 ---
  GPID=$(game_pids | head -n1)
  if [ "$GPID" != "$LAST_GAME_PID" ]; then
    if [ -n "$GPID" ]; then
      echo "$TS|GAME_START|PID=$GPID" >> "$LOGF"
      log INFO "检测到游戏进程启动 PID=$GPID"
    elif [ -n "$LAST_GAME_PID" ]; then
      echo "$TS|GAME_EXIT|上次PID=$LAST_GAME_PID" >> "$LOGF"
      log INFO "检测到游戏进程退出"
    fi
    LAST_GAME_PID="$GPID"
  fi

  # --- 可疑进程（去重：只在变化时记录）---
  SUSP_NOW=$(find_procs_by_pattern "frida|gadget|xposed|zygisk|lsposed|riru" | head -n5 | tr '\n' ';')
  if [ "$SUSP_NOW" != "$LAST_SUSPECT" ]; then
    if [ -n "$SUSP_NOW" ]; then
      echo "$TS|SUSPECT_PROC|$SUSP_NOW" >> "$LOGF"
      log WARN "检测到可疑特征进程"
    fi
    LAST_SUSPECT="$SUSP_NOW"
  fi

  CNT=$((CNT+1))

  # --- 每 5 次采样：模块状态 + SELinux ---
  if [ $((CNT % 5)) -eq 0 ]; then
    for id in $(module_ids); do
      d=$(mod_is_disabled "$id")
      o=$(grep "^$id|" "$BASE/modules.base" 2>/dev/null | sed 's/.*disabled=//')
      if [ -n "$o" ] && [ "$o" != "$d" ]; then
        echo "$TS|MODULE_FLAG|$id disabled:$o→$d" >> "$LOGF"
        log INFO "模块状态变化: $id ($o→$d)"
        sed -i "s/^$id|.*/$id|disabled=$d/" "$BASE/modules.base" 2>/dev/null
      fi
    done
    SE=$(selinux_state)
    SE0=$(cat "$BASE/selinux.base" 2>/dev/null)
    if [ -n "$SE0" ] && [ "$SE0" != "$SE" ]; then
      echo "$TS|SELINUX_CHANGE|$SE0 → $SE" >> "$LOGF"
      log WARN "SELinux 状态变化: $SE0 → $SE"
      echo "$SE" > "$BASE/selinux.base"
    fi

    # --- 每 10 次采样：系统属性变化 ---
    if [ $((CNT % 10)) -eq 0 ]; then
      prop_dump > "$BASE/props.now" 2>/dev/null
      grep -Fvx -f "$BASE/props.base" "$BASE/props.now" 2>/dev/null | head -n6 | while IFS= read -r L; do
        echo "$TS|PROP_CHANGE|$L" >> "$LOGF"
      done
      grep -Fvx -f "$BASE/props.now" "$BASE/props.base" 2>/dev/null | head -n6 | while IFS= read -r L; do
        echo "$TS|PROP_REMOVED|$L" >> "$LOGF"
      done
      mv "$BASE/props.now" "$BASE/props.base" 2>/dev/null
    fi
  fi

  # --- 日志体积保护 ---
  SZ=$(wc -c < "$LOGF" 2>/dev/null || echo 0)
  if [ "$SZ" -gt 524288 ]; then
    tail -n 3000 "$LOGF" > "$LOGF.tmp" 2>/dev/null
    mv -f "$LOGF.tmp" "$LOGF" 2>/dev/null
  fi

  sleep "$INTERVAL"
done

echo "$(date '+%H:%M:%S')|DIAG_END|会话结束" >> "$LOGF"
log INFO "诊断循环退出（会话 $SID）"
exit 0
