#!/bin/sh
# ============================================================
# Game Shield 打包脚本
# 用法: sh build.sh
# 输出: release/gs_guard-v1.0.0-<时间戳>.zip（可直接在 KernelSU Manager 安装）
# ============================================================
set -e
cd "$(dirname "$0")"

V="v1.0.0"
TS=$(date '+%Y%m%d%H%M%S')
OUT="release/gs_guard-$V-$TS.zip"
mkdir -p release

python3 - "$OUT" <<'EOF'
import zipfile, os, sys
out = sys.argv[1]
src = "module"
required = ["module.prop", "customize.sh", "post-fs-data.sh", "service.sh",
            "boot-completed.sh", "uninstall.sh", "common/functions.sh",
            "common/config.default", "bin/gs.sh", "bin/gsdiag.sh", "webroot/index.html"]
names = []
zf = zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED)
for root, dirs, files in os.walk(src):
    for f in files:
        full = os.path.join(root, f)
        arc = os.path.relpath(full, src)
        zf.write(full, arc)
        names.append(arc)
zf.close()
missing = [r for r in required if r not in names]
if missing:
    print("缺少必要文件:", missing); sys.exit(1)
print("已生成:", out, "(" + str(os.path.getsize(out)), "字节 )")
print("包含文件:", len(names), "个，结构校验通过")
EOF

sha256sum "$OUT" | tee "$OUT.sha256"
echo "完成。在 KernelSU Manager → 模块 → 从本地安装 选择该 zip"
