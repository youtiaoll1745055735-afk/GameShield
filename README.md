# Game Shield 游戏环境隔离与诊断 / Game Shield — Game Environment Isolation & Diagnostics

**中文** | **English** (scroll down for the English section)

> KernelSU 游戏环境隔离与兼容性诊断工具（模块 + 图形化控制台 App）。
> A KernelSU game-environment isolation and compatibility diagnostics toolkit (module + GUI control app).
>
> **制作：DeepSeek V4 Pro（Aether AI Agent）** / Built with DeepSeek V4 Pro (Aether AI Agent)

---

## 中文文档

### 这是什么

Game Shield 是一套面向已解锁 + KernelSU（root）设备、用于排查"游戏运行环境问题"的工具，包含两部分：

- **`module/`** — KernelSU 模块本体（id: `gs_guard`），shell 实现，无二进制依赖
- **`app/`** — Android 图形化控制台（Kotlin + Jetpack Compose），通过 `su` 调用模块命令，自身无需任何权限

### 功能

1. **环境检测**：KernelSU / Root / Bootloader / SELinux / 完整性 / 模块列表 / Hook 注入痕迹，分级显示（正常 / 警告 / 异常）
2. **游戏兼容模式**：临时停用指定模块、清理其进程、可靠备份与一键恢复（基于停用标志文件，KernelSU / Magisk 通用）
3. **问题定位诊断**：后台采样系统状态 → 生成诊断报告（只读，不触碰游戏）
4. **WebUI**：KernelSU Manager → 模块 → Game Shield → WebUI 直接操作
5. **控制台 App**：环境 / 游戏模式 / 诊断 / 设置四个页面，一键部署模块（App 内置模块包）、配置在线编辑、模块自检、查找游戏包名

### 明确边界（重要）

- **不隐藏 Root / 不解锁状态伪造**：解锁 + Root 本身可能被游戏检测，本工具无法改变这一点
- **不绕过反作弊、不防封**：无任何注入 / Hook / 内存修改 / 自动操作
- **模块停用需重启才完全生效**（机制限制）
- 诊断报告只是关联性提示，不构成对封禁/冻结原因的断言

### 安装

**模块**：KernelSU Manager → 模块 → 从本地安装 `gs_guard-v1.0.0.zip` → 重启

**控制台 App**：安装 `GameShield-debug.apk`（或自行编译），首次打开在 KernelSU 弹窗中授权，App 内「设置 → 一键部署模块」→ 重启

### 构建

```bash
# 控制台 App（Android Studio / AGP 8.7.3 / Kotlin 2.0.21 / compileSdk 35）
cd app && ./gradlew assembleDebug

# 模块打包（生成 release/gs_guard-vX.Y.Z-时间戳.zip）
./build.sh
```

### 命令参考

```bash
su -c gs.sh            # 查看用法
su -c gs.sh env        # 环境检测
su -c gs.sh game on    # 开启兼容模式
su -c gs.sh game off   # 关闭并恢复
su -c gs.sh diag start # 开始诊断
su -c gs.sh diag report# 生成报告
```

### 目录结构

```
├── module/            # KernelSU 模块（scripts + webroot）
├── app/               # 控制台 App（Kotlin + Compose）
├── build.sh           # 模块打包脚本
└── LICENSE            # MIT
```

### 许可证

[MIT](./LICENSE)

---

## English

### Overview

Game Shield is a toolkit for unlocked + KernelSU-rooted devices to diagnose game-environment issues. Two parts:

- **`module/`** — the KernelSU module (id: `gs_guard`), pure shell, no binaries
- **`app/`** — a GUI control app (Kotlin + Jetpack Compose) that runs module commands via `su`; requires no permissions itself

### Features

1. **Environment check**: KernelSU / Root / Bootloader / SELinux / integrity / module list / hook traces, graded (OK / warning / abnormal)
2. **Game compatibility mode**: temporarily disable selected modules, kill their processes, reliable backup & one-tap restore (disable flag-file mechanism, works on KernelSU & Magisk)
3. **Diagnostics**: background sampling → report generation (read-only, never touches the game)
4. **WebUI**: KernelSU Manager → Modules → Game Shield → WebUI
5. **Control app**: 4 tabs (Env / Game / Diag / Settings), one-tap module deployment (zip embedded), online config editing, self-test, package lookup

### Explicit Boundaries (Important)

- **No root hiding / no attestation spoofing** — unlocked + rooted status may be detected by games; this tool cannot change that
- **No anti-cheat bypass, no ban protection** — no injection, no hooks, no memory modification, no automation
- Full module disable requires a **reboot** (mechanism limitation)
- Diagnostic reports are correlation hints only — not an assertion of ban/freeze causes

### Install

**Module**: KernelSU Manager → Modules → install from local `gs_guard-v1.0.0.zip` → reboot

**Control app**: install `GameShield-debug.apk` (or build yourself), grant root on the first launch, then Settings → One-tap deploy → reboot

### Build

```bash
# Control app (Android Studio / AGP 8.7.3 / Kotlin 2.0.21 / compileSdk 35)
cd app && ./gradlew assembleDebug

# Module package (outputs release/gs_guard-vX.Y.Z-<timestamp>.zip)
./build.sh
```

### CLI Reference

```bash
su -c gs.sh            # usage
su -c gs.sh env        # environment check
su -c gs.sh game on    # enable compatibility mode
su -c gs.sh game off   # disable & restore
su -c gs.sh diag start # start diagnostics
su -c gs.sh diag report# generate report
```

### Structure

```
├── module/            # KernelSU module (scripts + webroot)
├── app/               # control app (Kotlin + Compose)
├── build.sh           # module packaging script
└── LICENSE            # MIT
```

### License

[MIT](./LICENSE)
