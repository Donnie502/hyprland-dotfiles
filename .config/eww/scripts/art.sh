#!/bin/bash
art=$(playerctl metadata mpris:artUrl 2>/dev/null)
out=/tmp/eww-art.png
url=/tmp/eww-art.url
prev=$(cat "$url" 2>/dev/null)
if [ "$art" != "$prev" ]; then
  echo "$art" > "$url"
  case "$art" in
    file://*) cp "${art#file://}" "$out" 2>/dev/null ;;
    http*)    curl -s "$art" -o "$out" 2>/dev/null ;;
  esac
fi
[ -f "$out" ] && echo "$out" || echo ""
