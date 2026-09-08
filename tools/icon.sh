#!/usr/bin/env bash
# Render a 1024x1024 app icon from a gradient + one glyph.
#   factory/tools/icon.sh <out.png> "<glyph or short text>" "<css gradient>"
set -euo pipefail
out=${1:?out.png}; glyph=${2:-A}; grad=${3:-linear-gradient(160deg,#1fbf8f 0%,#0f6a47 100%)}
B="${BROWSE:-$HOME/.claude/skills/gstack/browse/dist/browse}"
tmp="$(pwd)/.icon-$$.html"
cat > "$tmp" <<HTML
<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;background:#000}
#icon{width:1024px;height:1024px;background:$grad;display:flex;align-items:center;justify-content:center;
 font-family:-apple-system,"SF Pro Rounded","SF Pro Display",Inter,sans-serif;font-weight:800;font-size:560px;color:#fff;letter-spacing:-0.04em}
</style></head><body><div id="icon">$glyph</div></body></html>
HTML
"$B" viewport 1024x1024 >/dev/null
"$B" goto "file://$tmp" >/dev/null
"$B" screenshot "$out.tmp.png" --selector "#icon" >/dev/null
ffmpeg -y -loglevel error -i "$out.tmp.png" -pix_fmt rgb24 "$out"
rm -f "$out.tmp.png" "$tmp"
echo "Icon written: $out ($(sips -g pixelWidth -g pixelHeight "$out" | awk '/pixel/{printf "%s ", $2}'))"
