#!/usr/bin/env bash
# docs/design/*.d2 から SVG を書き出す（_style.d2 は読み込み用なので除く）。
# 使い方：docs/design/render.sh            → 同じ場所に *.svg
#         docs/design/render.sh png <dir>  → <dir> に *.png（見た目の確認用。コミットしない）
# レイアウトは elk（tala はライセンスが要るので使わない）。
set -euo pipefail
cd "$(dirname "$0")"
fmt="${1:-svg}"
out="${2:-.}"
mkdir -p "$out"
for f in [0-9]*.d2; do
  nix run nixpkgs#d2 -- --layout elk --pad 40 "$f" "$out/${f%.d2}.$fmt"
done
