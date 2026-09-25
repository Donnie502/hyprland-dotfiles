#!/bin/bash
cava -p "$HOME/.config/eww/cava-config" \
  | stdbuf -oL sed 's/;$//; s/;/,/g; s/^/[/; s/$/]/' \
  | grep --line-buffered -E '^\[[0-9,]+\]$'
