#!/bin/bash
selected=$(cliphist list | rofi -dmenu -config ~/.config/rofi/config.rasi -p "Portapapeles")
if [ -n "$selected" ]; then
    echo "$selected" | cliphist decode | wl-copy
fi
