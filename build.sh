#!/usr/bin/env bash
# 用法：bash build.sh <sitcon|campus-fest>
#   sitcon       → dist/UniBooks-poster-sitcon.pdf        A0 直式 841 × 1189 mm（SITCON 規格）
#   campus-fest  → dist/UniBooks-poster-campus-fest.pdf   A1 直式 594 × 841 mm（致理校慶）
# 兩張海報各自放在同名資料夾（poster.md + poster.css），共用 assets/。
#
# 注意：marp-cli 偶爾在輸出檔寫完後不結束程序（已在 Chrome 156 / marp-cli 4.5 遇到），
# 所以這裡以「輸出檔寫完且大小穩定」判定完成，再結束該程序。
set -uo pipefail
cd "$(dirname "$0")"
name="${1:-}"
if [ ! -f "$name/poster.md" ]; then echo "用法：bash build.sh <sitcon|campus-fest>" >&2; exit 2; fi
mkdir -p dist
out="dist/UniBooks-poster-$name.pdf"
rm -f "$out"
node node_modules/.bin/marp "$name/poster.md" --theme "$name/poster.css" \
  --allow-local-files --html --pdf -o "$out" >/dev/null 2>&1 &
pid=$! last=-1 same=0 t=0
while [ $t -lt 150 ]; do
  sleep 1; t=$((t+1))
  size=$(stat -f%z "$out" 2>/dev/null || echo 0)
  if [ "$size" -gt 0 ] && [ "$size" = "$last" ]; then same=$((same+1)); else same=0; fi
  last=$size
  if [ $same -ge 3 ] || ! kill -0 $pid 2>/dev/null; then break; fi
done
kill $pid 2>/dev/null; wait $pid 2>/dev/null
if [ -s "$out" ]; then echo "ok  $out ($(( $(stat -f%z "$out") / 1024 )) KB)"; else echo "FAILED $out" >&2; exit 1; fi
