#!/system/bin/sh
# ============================================================
# Game Shield 主入口
# 用法: gs.sh <命令> [参数]
#   env [--raw]          环境检测
#   game on|off|status|preview  游戏兼容模式
#   diag start|stop|status|report  诊断
#   log [N|clear]        查看/清空日志
#   find-pkg [关键词]     查找已安装包（核对游戏包名）
#   self-test            模块自检
# ============================================================

SELF_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$SELF_DIR/common/functions.sh"

usage() {
  echo "Game Shield v$GS_VERSION 用法:"
  echo "  gs.sh env                完整环境检测"
  echo "  gs.sh env --raw          WebUI 用原始输出"
  echo "  gs.sh game preview       预览将要管理的模块"
  echo "  gs.sh game on            开启游戏兼容模式（停用指定模块）"
  echo "  gs.sh game off|restore   关闭并恢复原环境"
  echo "  gs.sh game status        查看当前状态"
  echo "  gs.sh diag start         开始诊断（随后去启动游戏）"
  echo "  gs.sh diag stop          停止诊断"
  echo "  gs.sh diag status        诊断会话状态"
  echo "  gs.sh diag report        生成/查看诊断报告"
  echo "  gs.sh log [行数|clear]   查看或清空日志"
  echo "  gs.sh find-pkg [关键词]  查找已安装包"
  echo "  gs.sh self-test          模块自检"
}

# ============================================================
# env: 环境检测
# ============================================================
cmd_env() {
  RAW=0; [ "$1" = "--raw" ] && RAW=1
  load_conf; ensure_dirs
  BUF=""
  add() { # add <分区> <键> <值> <级别ok|warn|bad|info>
    v=$(echo "$3" | tr '|' '/')
    BUF="$BUF
$1|$2|$v|$4"
  }

  # --- 设备信息 ---
  add 设备信息 型号 "$(getprop ro.product.model)" info
  add 设备信息 系统 "Android $(getprop ro.build.version.release) SDK$(getprop ro.build.version.sdk)" info
  add 设备信息 内核 "$(uname -r)" info
  add 设备信息 检测时间 "$(now_ts)" info

  # --- KernelSU ---
  KSUVER=""
  [ -f "$KSU_DIR/ksu_version" ] && KSUVER=$(cat "$KSU_DIR/ksu_version" 2>/dev/null)
  if [ -n "$KSUVER" ]; then
    add KernelSU 内核版本 "$KSUVER" ok
  else
    add KernelSU 内核版本 "未找到 ksu_version（KernelSU 可能未正常加载）" bad
  fi
  if command -v ksud >/dev/null 2>&1; then
    add KernelSU ksud "$(ksud -V 2>/dev/null)" ok
  else
    add KernelSU ksud "不可用" warn
  fi
  MGR=$(pm list packages 2>/dev/null | grep -i "me.weishu.kernelsu" | head -n1)
  if [ -n "$MGR" ]; then add KernelSU Manager "已安装" ok; else add KernelSU Manager "未检测到" warn; fi
  if [ -d "$MODULES_DIR" ]; then
    add KernelSU 模块目录 "存在" ok
    if touch "$MODULES_DIR/.gs_rotest" 2>/dev/null; then
      rm -f "$MODULES_DIR/.gs_rotest" 2>/dev/null
      add KernelSU 模块目录可写 是 ok
    else
      add KernelSU 模块目录可写 "否（权限异常，停用/恢复功能将失效）" bad
    fi
  else
    add KernelSU 模块目录 "缺失" bad
  fi

  # --- Root ---
  UIDN=$(id -u 2>/dev/null)
  if [ "$UIDN" = "0" ]; then add Root 当前UID "0（root）" ok; else add Root 当前UID "$UIDN（非root）" warn; fi
  SUP=""
  command -v su >/dev/null 2>&1 && SUP=$(command -v su)
  [ -z "$SUP" ] && [ -x /data/adb/ksu/bin/su ] && SUP="/data/adb/ksu/bin/su"
  if [ -n "$SUP" ]; then add Root su路径 "$SUP" ok; else add Root su路径 "未找到" warn; fi
  if [ -d /data/adb/magisk ]; then
    add Root Magisk并存 "检测到 Magisk 目录（双 Root 共存，属高风险环境特征）" warn
  else
    add Root Magisk并存 "未检测到" ok
  fi

  # --- Bootloader ---
  FL=$(getprop ro.boot.flash.locked)
  case "$FL" in
    "") add Bootloader flash.locked "属性不可读" warn;;
    0) add Bootloader flash.locked "0（已解锁）" warn;;
    1) add Bootloader flash.locked "1（已锁定）" ok;;
    *) add Bootloader flash.locked "$FL" info;;
  esac
  VB=$(getprop ro.boot.verifiedbootstate)
  case "$VB" in
    green) add Bootloader verifiedbootstate "green（验证启动·锁定）" ok;;
    orange) add Bootloader verifiedbootstate "orange（验证启动·已解锁）" warn;;
    yellow) add Bootloader verifiedbootstate "yellow（自定义信任根）" warn;;
    "") add Bootloader verifiedbootstate "属性不可读" warn;;
    *) add Bootloader verifiedbootstate "$VB" info;;
  esac
  VMD=$(getprop ro.boot.vbmeta.device_state)
  if [ -n "$VMD" ]; then add Bootloader vbmeta.device_state "$VMD" "$([ "$VMD" = "locked" ] && echo ok || echo warn)"; else add Bootloader vbmeta.device_state "属性不可读" warn; fi
  WB=$(getprop ro.boot.warranty_bit)
  [ -n "$WB" ] && add Bootloader warranty_bit "$WB" info

  # --- SELinux ---
  SE=$(selinux_state)
  case "$SE" in
    Enforcing) add SELinux 当前模式 "Enforcing（强制）" ok;;
    Permissive) add SELinux 当前模式 "Permissive（宽容·高危特征）" bad;;
    *) add SELinux 当前模式 "$SE" warn;;
  esac
  add SELinux ro.build.selinux "$(getprop ro.build.selinux)" info

  # --- 系统完整性 ---
  TAGS=$(getprop ro.build.tags)
  case "$TAGS" in
    release-keys) add 系统完整性 build.tags "release-keys（正式签名）" ok;;
    test-keys) add 系统完整性 build.tags "test-keys（测试签名·非官方构建）" warn;;
    "") add 系统完整性 build.tags "属性不可读" warn;;
    *) add 系统完整性 build.tags "$TAGS" warn;;
  esac
  DBG=$(getprop ro.debuggable)
  if [ "$DBG" = "0" ]; then add 系统完整性 ro.debuggable "0（不可调试）" ok; elif [ "$DBG" = "1" ]; then add 系统完整性 ro.debuggable "1（可调试构建）" warn; else add 系统完整性 ro.debuggable "不可读" warn; fi
  SEC=$(getprop ro.secure)
  if [ "$SEC" = "1" ]; then add 系统完整性 ro.secure "1" ok; elif [ "$SEC" = "0" ]; then add 系统完整性 ro.secure "0（非安全模式）" warn; else add 系统完整性 ro.secure "不可读" warn; fi
  add 系统完整性 加密状态 "$(getprop ro.crypto.state)" info
  add 系统完整性 安全补丁 "$(getprop ro.build.version.security_patch)" info

  # --- 启动状态 ---
  add 启动状态 boot_completed "$(getprop sys.boot_completed)" info
  if [ -r /proc/uptime ]; then
    read -r UP _ < /proc/uptime 2>/dev/null
    add 启动状态 已开机时长 "$((UP/60)) 分钟" info
  fi
  add 启动状态 首次开机时间 "$(getprop ro.runtime.firstboot)" info

  # --- 模块列表 ---
  IDS=$(module_ids)
  CNT=0; DIS=0
  for id in $IDS; do
    CNT=$((CNT+1))
    [ "$(mod_is_disabled "$id")" = "1" ] && DIS=$((DIS+1))
  done
  add 模块列表 "总数" "$CNT（启用 $((CNT-DIS)) / 停用 $DIS）" info
  for id in $IDS; do
    d="$MODULES_DIR/$id"
    nm=$(mod_prop "$d" name)
    [ -z "$nm" ] && nm="$id"
    st="启用"; [ "$(mod_is_disabled "$id")" = "1" ] && st="停用"
    [ -e "$d/update" ] && st="$st+待更新"
    [ -e "$d/remove" ] && st="$st+待卸载"
    if [ "$id" = "$SELF_ID" ]; then
      add "模块·$nm" 状态 "$st（本模块）" ok
    else
      SUS=$(mod_is_suspect "$d")
      if [ -n "$SUS" ]; then
        add "模块·$nm" 状态 "$st" warn
        add "模块·$nm" 提示 "$SUS" warn
      else
        add "模块·$nm" 状态 "$st" ok
      fi
    fi
  done

  # --- Hook / Overlay / 注入检查 ---
  ZYD=""
  for id in $IDS; do
    [ -d "$MODULES_DIR/$id/zygisk" ] && ZYD="$ZYD $id"
  done
  if [ -n "$ZYD" ]; then add Hook检查 Zygisk类模块 "$ZYD" warn; else add Hook检查 Zygisk类模块 "无" ok; fi
  LSP=$(pm list packages 2>/dev/null | grep -Ei "$SUSPECT_PKG_RE" | sed 's/^package://' | tr '\n' ' ')
  if [ -n "$LSP" ]; then add Hook检查 疑似Hook类应用 "$LSP" warn; else add Hook检查 疑似Hook类应用 "无" ok; fi
  NB=$(getprop ro.dalvik.vm.native.bridge)
  if [ -n "$NB" ]; then
    add Hook检查 native_bridge "$NB（非空，可能被注入框架使用，也可能是设备默认）" warn
  else
    add Hook检查 native_bridge "未设置" ok
  fi
  OVL=$(cmd overlay list 2>/dev/null | grep '^\[x\]' | grep -Ev 'android|oneplus|oplus' | sed 's/^\[x\] //' | head -n8 | tr '\n' ' ')
  if [ -n "$OVL" ]; then add Overlay 已启用第三方RRO "$OVL" warn; else add Overlay 已启用第三方RRO "无" ok; fi
  SUSP=$(find_procs_by_pattern "frida|gadget|xposed|zygisk|lsposed|riru" | head -n5 | sed 's/ /·/g' | tr '\n' ' ')
  if [ -n "$SUSP" ]; then add 注入检查 可疑特征进程 "$SUSP" warn; else add 注入检查 可疑特征进程 "无" ok; fi
  LTP=$(ls /data/local/tmp 2>/dev/null | grep -Ei "frida|gadget|\.so$" | head -n5 | tr '\n' ' ')
  if [ -n "$LTP" ]; then add 注入检查 /data/local/tmp可疑文件 "$LTP" warn; else add 注入检查 /data/local/tmp可疑文件 "无" ok; fi
  MNT=$(grep -c "modules" /proc/self/mountinfo 2>/dev/null || echo 0)
  add 注入检查 模块挂载点 "$MNT 处（存在模块文件挂载属正常现象）" info

  # --- 目标游戏 ---
  add 目标游戏 配置包名 "$TARGET_PACKAGE" info
  if pm list packages 2>/dev/null | grep -qx "package:$TARGET_PACKAGE"; then
    add 目标游戏 安装状态 "已安装" ok
  else
    add 目标游戏 安装状态 "未安装或包名不符（请用 gs.sh find-pkg tencent 核对并修改配置）" bad
  fi
  GP=$(game_pids | tr '\n' ' ')
  if [ -n "$GP" ]; then add 目标游戏 当前进程 "运行中 PID:$GP" info; else add 目标游戏 当前进程 "未运行" info; fi

  # --- 输出 ---
  if [ "$RAW" = "1" ]; then
    printf '%s\n' "$BUF" | sed '/^[[:space:]]*$/d'
  else
    echo "════════ Game Shield 环境检测 ════════"
    LAST=""
    printf '%s\n' "$BUF" | sed '/^[[:space:]]*$/d' | while IFS='|' read -r SEC KEY VAL LV; do
      if [ "$SEC" != "$LAST" ]; then
        echo ""
        echo "▸ $SEC"
        LAST="$SEC"
      fi
      case "$LV" in
        ok) MARK="✓";;
        warn) MARK="⚠";;
        bad) MARK="✗";;
        *) MARK="·";;
      esac
      printf "   %-24s %s  %s\n" "$KEY" "$VAL" "$MARK"
    done
    echo ""
    echo "═══════════════════════════════════════"
    echo "⚠ 说明：以上为客观环境状态。解锁/Root 状态本身可能被游戏"
    echo "  检测到，本模块不会隐藏、也不会伪造这些状态。"
  fi
}

# ============================================================
# game: 游戏兼容模式
# ============================================================
game_managed_list() {
  if [ "$MANAGED_MODULES" = "all" ]; then
    for id in $(module_ids); do
      [ "$id" = "$SELF_ID" ] && continue
      case " $EXCLUDED_MODULES " in
        *" $id "*) continue;;
      esac
      echo "$id"
    done
  else
    for id in $MANAGED_MODULES; do echo "$id"; done
  fi
}

game_preview() {
  echo "管理模式: MANAGED_MODULES=$MANAGED_MODULES"
  echo "将管理的模块:"
  for id in $(game_managed_list); do
    nm=$(mod_prop "$MODULES_DIR/$id" name)
    [ -z "$nm" ] && nm="?"
    st="启用"; [ "$(mod_is_disabled "$id")" = "1" ] && st="停用"
    printf "  - %-24s %-20s [%s]\n" "$id" "$nm" "$st"
  done
}

game_on() {
  if [ -f "$GS_STATE/game.state" ] && [ "$(sed -n 's/^APPLIED=//p' "$GS_STATE/game.state")" = "1" ]; then
    echo "✗ 游戏兼容模式已开启。如需重新应用，先执行: gs.sh game off"
    return 1
  fi
  TS=$(date '+%Y%m%d-%H%M%S')
  BK="$GS_STATE/backup_$TS"
  mkdir -p "$BK" 2>/dev/null
  LIST=$(game_managed_list)
  DISABLED=""; PREV=""
  for id in $LIST; do
    was=$(mod_is_disabled "$id")
    cp "$MODULES_DIR/$id/module.prop" "$BK/$id.prop" 2>/dev/null
    if [ "$was" = "0" ]; then
      if mod_disable "$id"; then
        DISABLED="$DISABLED $id"
        PREV="$PREV $id:enabled"
        log INFO "游戏模式: 停用模块 $id"
        for pp in $(find_procs_by_pattern "/data/adb/modules/$id"); do
          PIDX=${pp%% *}
          if kill -9 "$PIDX" 2>/dev/null; then
            log INFO "游戏模式: 已结束模块相关进程 PID=$PIDX"
          fi
        done
      else
        log ERROR "游戏模式: 停用 $id 失败"
      fi
    else
      PREV="$PREV $id:already-disabled"
    fi
  done
  cat > "$GS_STATE/game.state" <<EOF
APPLIED=1
TIMESTAMP=$TS
START_EPOCH=$(now_epoch)
BACKUP_DIR=$BK
TARGET_PACKAGE=$TARGET_PACKAGE
MODULES_DISABLED=$DISABLED
MODULES_PREV_STATE=$PREV
EOF
  log INFO "游戏兼容模式已开启。停用模块: [$DISABLED]"
  echo ""
  echo "✓ 游戏兼容模式已开启"
  echo "  本次停用模块:${DISABLED:-（无——所有管理模块本就处于停用状态）}"
  echo "  状态备份: $BK"
  echo ""
  echo "  ┌─ 生效范围 ─────────────────────────┐"
  echo "  │ 已立即生效：停用标志已写入；相关模块进程已结束      │"
  echo "  │ 重启后完全生效：模块脚本与文件挂载将不再加载        │"
  echo "  └────────────────────────────────────┘"
  echo ""
  echo "  建议流程: game on → 重启设备 → 启动游戏 → 结束后"
  echo "            game off → 重启恢复"
  echo "  （可配置 AUTO_RESTORE_HOURS 超时自动恢复）"
}

game_off() {
  if [ ! -f "$GS_STATE/game.state" ]; then
    echo "✗ 无游戏模式记录（可能未开启，或状态文件已丢失）"
    return 1
  fi
  if [ "$(sed -n 's/^APPLIED=//p' "$GS_STATE/game.state")" != "1" ]; then
    echo "游戏模式未处于开启状态"
    rm -f "$GS_STATE/game.state"
    return 1
  fi
  PREV=$(sed -n 's/^MODULES_PREV_STATE=//p' "$GS_STATE/game.state")
  RESTORED=""
  for item in $PREV; do
    id=${item%%:*}; st=${item##*:}
    if [ "$st" = "enabled" ]; then
      if mod_enable "$id"; then
        RESTORED="$RESTORED $id"
        log INFO "游戏模式: 恢复模块 $id"
      else
        log ERROR "游戏模式: 恢复 $id 失败"
      fi
    fi
  done
  mv "$GS_STATE/game.state" "$GS_STATE/game.state.closed" 2>/dev/null
  log INFO "游戏兼容模式已关闭。恢复模块: [$RESTORED]"
  echo ""
  echo "✓ 已恢复模块:${RESTORED:-（无）}"
  echo "  ⚠ 模块挂载与脚本的恢复需要重启后完全生效"
  echo "  备份保留: $(sed -n 's/^BACKUP_DIR=//p' "$GS_STATE/game.state.closed" 2>/dev/null)"
}

game_status() {
  if [ -f "$GS_STATE/game.state" ] && [ "$(sed -n 's/^APPLIED=//p' "$GS_STATE/game.state")" = "1" ]; then
    echo "游戏兼容模式: 已开启"
    echo "  开启时间: $(sed -n 's/^TIMESTAMP=//p' "$GS_STATE/game.state")"
    echo "  停用模块:$(sed -n 's/^MODULES_DISABLED=//p' "$GS_STATE/game.state")"
    echo "  目标游戏: $(sed -n 's/^TARGET_PACKAGE=//p' "$GS_STATE/game.state")"
  else
    echo "游戏兼容模式: 未开启"
  fi
  echo ""
  echo "当前实际处于停用状态的模块:"
  FOUND=0
  for id in $(module_ids); do
    if [ "$(mod_is_disabled "$id")" = "1" ]; then
      FOUND=1
      printf "  - %-24s %s\n" "$id" "$(mod_prop "$MODULES_DIR/$id" name)"
    fi
  done
  [ "$FOUND" = "0" ] && echo "  （无）"
}

cmd_game() {
  load_conf; ensure_dirs
  case "$1" in
    on) game_on;;
    off|restore) game_off;;
    status) game_status;;
    preview) game_preview;;
    *) usage; return 1;;
  esac
}

# ============================================================
# diag: 诊断
# ============================================================
diag_status() {
  if [ -f "$GS_STATE/diag.state" ]; then
    echo "会话: $(sed -n 's/^SESSION=//p' "$GS_STATE/diag.state")"
    echo "状态: $([ "$(sed -n 's/^ACTIVE=//p' "$GS_STATE/diag.state")" = "1" ] && echo "采集中" || echo "已停止")"
    echo "循环PID: $(sed -n 's/^PID=//p' "$GS_STATE/diag.state")"
  else
    echo "无诊断会话"
  fi
}

diag_start() {
  if [ -f "$GS_STATE/diag.state" ] && [ "$(sed -n 's/^ACTIVE=//p' "$GS_STATE/diag.state")" = "1" ]; then
    echo "✗ 诊断已在运行。先执行: gs.sh diag stop"
    return 1
  fi
  SID="diag_$(date '+%Y%m%d-%H%M%S')"
  BASE="$GS_STATE/$SID"
  mkdir -p "$BASE" 2>/dev/null
  prop_dump > "$BASE/props.base" 2>/dev/null
  : > "$BASE/modules.base"
  for id in $(module_ids); do
    echo "$id|disabled=$(mod_is_disabled "$id")" >> "$BASE/modules.base"
  done
  selinux_state > "$BASE/selinux.base" 2>/dev/null
  ps -e -o PID,NAME 2>/dev/null > "$BASE/procs.base"
  cat > "$GS_STATE/diag.state" <<EOF
ACTIVE=1
SESSION=$SID
START_EPOCH=$(now_epoch)
PID=0
EOF
  nohup sh "$SELF_DIR/bin/gsdiag.sh" "$SID" >/dev/null 2>&1 &
  PID=$!
  sed -i "s/^PID=.*/PID=$PID/" "$GS_STATE/diag.state" 2>/dev/null
  log INFO "诊断会话开始: $SID"
  echo ""
  echo "✓ 诊断已启动（会话 $SID，采样间隔 ${DIAG_INTERVAL}s）"
  echo "  1) 现在去启动《三角洲行动》，正常游玩"
  echo "  2) 出现冻结/异常后，回来执行: gs.sh diag stop"
  echo "  3) 执行: gs.sh diag report 生成并查看诊断报告"
  echo "  说明: 诊断只读取系统信息，不触碰游戏进程与文件"
}

diag_stop() {
  if [ ! -f "$GS_STATE/diag.state" ] || [ "$(sed -n 's/^ACTIVE=//p' "$GS_STATE/diag.state")" != "1" ]; then
    echo "无进行中的诊断会话"
    return 1
  fi
  SID=$(sed -n 's/^SESSION=//p' "$GS_STATE/diag.state")
  DPID=$(sed -n 's/^PID=//p' "$GS_STATE/diag.state")
  # 先置停止标志，让采样循环优雅退出（写入 DIAG_END）
  sed -i 's/^ACTIVE=1/ACTIVE=0/' "$GS_STATE/diag.state" 2>/dev/null
  i=0
  while [ $i -lt 8 ] && [ -n "$DPID" ] && kill -0 "$DPID" 2>/dev/null; do
    sleep 1; i=$((i+1))
  done
  [ -n "$DPID" ] && kill "$DPID" 2>/dev/null
  pkill -f "gsdiag.sh $SID" 2>/dev/null
  log INFO "诊断会话停止: $SID"
  echo "✓ 诊断已停止。执行 gs.sh diag report 生成报告"
}

diag_report() {
  SID=""
  if [ -f "$GS_STATE/diag.state" ]; then
    SID=$(sed -n 's/^SESSION=//p' "$GS_STATE/diag.state")
  fi
  [ -z "$SID" ] && SID=$(ls -1t "$GS_STATE" 2>/dev/null | grep '^diag_' | head -n1)
  BASE="$GS_STATE/$SID"
  [ -d "$BASE" ] || { echo "✗ 无诊断会话数据"; return 1; }
  LOGF="$GS_LOG_DIR/$SID.log"
  OUT="$DL_DIR/gs_report_$SID.txt"
  mkdir -p "$DL_DIR" 2>/dev/null
  {
    echo "═══════════════════════════════════════════"
    echo " Game Shield 诊断报告"
    echo " 会话: $SID"
    echo " 生成时间: $(now_ts)"
    echo " 设备: $(getprop ro.product.model) / Android $(getprop ro.build.version.release)"
    echo " 游戏: $TARGET_PACKAGE"
    echo "═══════════════════════════════════════════"
    echo ""
    echo "【重要声明】本报告仅记录环境变化与关联性事件，"
    echo "不构成对封禁/冻结原因的任何断言；冻结判定由服务器侧"
    echo "做出，客户端无法观测其依据。"
    echo ""
    echo "──────── 会话统计 ────────"
    if [ -f "$LOGF" ]; then
      TOTAL=$(grep -c '|' "$LOGF" 2>/dev/null)
      echo "事件总数: $TOTAL"
      echo "事件类型分布:"
      sed 's/^[^|]*|\([^|]*\)|.*/\1/' "$LOGF" 2>/dev/null | sort | uniq -c | sort -rn | head -n10
      echo ""
      echo "──────── 事件时间线（最多 50 条）────────"
      head -n50 "$LOGF" 2>/dev/null | while IFS='|' read -r TS TY DT; do
        echo "  [$TS] $TY  $DT"
      done
    else
      echo "（本会话无事件日志）"
    fi
    echo ""
    echo "──────── 模块状态（基线记录）────────"
    cat "$BASE/modules.base" 2>/dev/null | while IFS='|' read -r id st; do
      nm=$(mod_prop "$MODULES_DIR/$id" name)
      printf "  %-24s %-18s %s\n" "$id" "$nm" "$st"
    done
    echo ""
    echo "──────── 系统属性变化（相对基线）────────"
    prop_dump > "$BASE/props.now" 2>/dev/null
    ADDED=$(grep -Fvx -f "$BASE/props.base" "$BASE/props.now" 2>/dev/null | head -n20)
    if [ -n "$ADDED" ]; then echo "$ADDED" | sed 's/^/  + /'; else echo "  （无新增属性）"; fi
    DELED=$(grep -Fvx -f "$BASE/props.now" "$BASE/props.base" 2>/dev/null | head -n20)
    if [ -n "$DELED" ]; then echo "$DELED" | sed 's/^/  - /'; else echo "  （无消失属性）"; fi
    rm -f "$BASE/props.now"
    echo ""
    echo "──────── 关联性提示（仅供参考）────────"
    if [ -f "$LOGF" ]; then
      GE=$(grep -c 'GAME_START' "$LOGF" 2>/dev/null)
      GX=$(grep -c 'GAME_EXIT' "$LOGF" 2>/dev/null)
      echo "· 会话期间检测到游戏进程启动 $GE 次 / 退出 $GX 次"
      grep -q 'SELINUX_CHANGE' "$LOGF" 2>/dev/null && echo "· 会话期间 SELinux 状态发生变化，多数反作弊将 SELinux 纳入环境评估"
      grep -q 'SUSPECT_PROC' "$LOGF" 2>/dev/null && echo "· 会话期间出现过可疑特征进程，建议结合进程名人工排查"
      grep -q 'MODULE_FLAG' "$LOGF" 2>/dev/null && echo "· 会话期间存在模块停用/启用状态变化"
    fi
    for id in $(module_ids); do
      [ "$(mod_is_disabled "$id")" = "1" ] && continue
      SUS=$(mod_is_suspect "$MODULES_DIR/$id")
      if [ -n "$SUS" ]; then
        echo "· 模块「$id」当前保持启用且$SUS，游戏运行期间保持启用，可能存在兼容性影响"
      fi
    done
    SE=$(selinux_state)
    [ "$SE" = "Permissive" ] && echo "· 当前 SELinux 为 Permissive，属于高敏感环境特征"
    echo ""
    echo "（以上均为环境关联性提示，不证明任何因果关系）"
    echo "═══════════════════════════════════════════"
  } | tee "$OUT"
  echo ""
  echo "报告已保存: $OUT"
}

cmd_diag() {
  load_conf; ensure_dirs
  case "$1" in
    start) diag_start;;
    stop) diag_stop;;
    status) diag_status;;
    report) diag_report;;
    *) usage; return 1;;
  esac
}

# ============================================================
# log / find-pkg / self-test
# ============================================================
cmd_log() {
  ensure_dirs
  case "${1:-}" in
    clear) : > "$GS_LOG"; echo "日志已清空";;
    *) N="${1:-50}"; echo "── gs.log 最近 $N 行 ──"; tail -n "$N" "$GS_LOG" 2>/dev/null;;
  esac
}

cmd_findpkg() {
  KW="${1:-tencent}"
  echo "已安装包中匹配「$KW」的:"
  pm list packages 2>/dev/null | sed 's/^package://' | grep -i "$KW" | sort
  echo ""
  echo "找到游戏包名后修改配置:"
  echo "  su -c 'sed -i \"s/^TARGET_PACKAGE=.*/TARGET_PACKAGE=<包名>/\" /data/adb/gs_guard/config'"
}

cmd_selftest() {
  ensure_dirs
  echo "Game Shield 自检:"
  [ -d "$GS_DIR" ] && echo "  ok   数据目录" || echo "  bad  数据目录缺失"
  [ -f "$GS_CONF" ] && echo "  ok   配置文件" || echo "  bad  配置文件缺失（首次运行 service.sh 会生成）"
  [ -x "$SELF_DIR/bin/gs.sh" ] && echo "  ok   主脚本可执行" || echo "  bad  主脚本不可执行"
  [ -d "$MODULES_DIR" ] && echo "  ok   模块目录可访问" || echo "  bad  模块目录不可访问"
  sh -n "$SELF_DIR/common/functions.sh" 2>/dev/null && echo "  ok   functions.sh 语法" || echo "  bad  functions.sh 语法错误"
  sh -n "$SELF_DIR/bin/gsdiag.sh" 2>/dev/null && echo "  ok   gsdiag.sh 语法" || echo "  bad  gsdiag.sh 语法错误"
  echo "  info SELinux=$(selinux_state)"
  echo "  info 模块数=$(module_ids | wc -l)"
  echo "  info 日志=$(wc -l < "$GS_LOG" 2>/dev/null) 行"
}

# ============================================================
case "${1:-}" in
  env) shift; cmd_env "$@";;
  game) shift; cmd_game "$@";;
  diag) shift; cmd_diag "$@";;
  log) shift; cmd_log "$@";;
  find-pkg) shift; cmd_findpkg "$@";;
  self-test) cmd_selftest;;
  help|-h|"") usage;;
  *) usage; exit 1;;
esac
