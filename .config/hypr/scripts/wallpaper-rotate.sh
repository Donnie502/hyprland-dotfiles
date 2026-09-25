#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
EXCLUDE="test.png"

IMG=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -iname "$EXCLUDE" | shuf -n 1)

if [ -z "$IMG" ]; then
    notify-send "Rotación de fondo" "No se encontraron wallpapers en $WALLPAPER_DIR"
    exit 1
fi

pkill swaybg
sleep 0.3
swaybg -i "$IMG" -m fill &
disown

wallust run "$IMG"

pkill waybar
sleep 0.3
waybar &
disown

notify-send "Fondo actualizado" "$(basename "$IMG")"
