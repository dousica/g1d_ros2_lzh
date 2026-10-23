#!/usr/bin/env bash
# ============================================================
# 安全地从师兄工作空间复制包到我的工作空间, 并自动改名
#
# 用法:
#   bash ~/g1d_ros2_lzh/copy_pkg.sh <师兄包名> [新包名]
#
# 例:
#   bash ~/g1d_ros2_lzh/copy_pkg.sh g1d_description
#   → 生成 ~/g1d_ros2_lzh/src/lzh_description
#
# 特点:
#   - 源包只读, 绝不修改师兄的目录
#   - 自动把 g1d_xxx 全部替换为 lzh_xxx
#   - 替换后自动打印所有残留的 g1d_ 字样供人工确认
#   - 自动 git add, 便于你 review 后再 commit
# ============================================================

set -euo pipefail

SRC_WS="$HOME/g1d_ros2_ws/src"
DST_WS="$HOME/g1d_ros2_lzh/src"

if [ $# -lt 1 ]; then
  echo "用法: bash $0 <师兄包名> [新包名]"
  echo "例: bash $0 g1d_description"
  exit 1
fi

OLD="$1"
NEW="${2:-lzh_${OLD#g1d_}}"

SRC="$SRC_WS/$OLD"
DST="$DST_WS/$NEW"

if [ ! -d "$SRC" ]; then
  echo "❌ 源包不存在: $SRC"
  echo "可用的源包:"
  for d in "$SRC_WS"/*/; do echo "   - $(basename "$d")"; done
  exit 1
fi

if [ -e "$DST" ]; then
  echo "❌ 目标已存在: $DST"
  exit 1
fi

echo "==> 源(只读): $SRC"
echo "==> 目标      : $DST"

# 1. 复制(保留权限, 不跟随符号链接到源外)
cp -r "$SRC" "$DST"

# 2. 排除不该进版本库的东西
rm -rf "$DST/build" "$DST/install" "$DST/log" "$DST/.git"

# 3. 批量改名
echo "==> 替换包名 $OLD -> $NEW"
cd "$DST"
grep -rl "$OLD" . 2>/dev/null | while read -r f; do
  sed -i "s/$OLD/$NEW/g" "$f"
done

# 3.5 重命名文件名本身(ament_python 的 resource/<pkg> 标记文件等)
echo "==> 重命名文件名中的 $OLD -> $NEW"
find . -name "*$OLD*" | while read -r f; do
  nf=$(echo "$f" | sed "s/$OLD/$NEW/g")
  [ "$f" != "$nf" ] && mv "$f" "$nf" && echo "    $f -> $nf"
done

# 4. 打印残留(可能是机器人型号名如 G1_D, 或 frame 名, 需人工判断)
echo
echo "==> 残留的 g1d_ 字样(以下可能需要你人工确认):"
if grep -rIn "g1d_" . 2>/dev/null | grep -v "^Binary" | head -40; then
  echo "   (以上为空表示替换干净)"
fi

echo
echo "==> 新包名确认:"
grep -m1 "<name>" package.xml || true

echo
echo "==> 下一步:"
echo "    cd $DST_WS"
echo "    colcon build --symlink-install"
echo
echo "提示: 已自动 git add, 请用 'git diff --cached' review 后再 commit"
cd "$DST_WS" && git add -A
