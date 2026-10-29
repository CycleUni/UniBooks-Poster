#!/usr/bin/env bash
# 輸出 dist/UniBooks-poster.pdf（A0 直式 841 × 1189 mm，符合 SITCON 規格，也可直接印來擺攤）。
# 用法：bash build.sh
#
# 注意：marp-cli 偶爾在輸出檔寫完後不結束程序（已在 Chrome 156 / marp-cli 4.5 遇到），
# 所以這裡以「輸出檔寫完且大小穩定」判定完成，再結束該程序。
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p dist
out="dist/UniBooks-poster.pdf"
rm -f "$out"
node node_modules/.bin/marp poster.md --theme poster.css \
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
