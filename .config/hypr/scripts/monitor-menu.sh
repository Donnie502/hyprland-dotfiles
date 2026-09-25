#!/bin/bash
LAPTOP="eDP-1"
EXTERNAL=$(hyprctl monitors -j | jq -r --arg laptop "$LAPTOP" '.[] | select(.name != $laptop) | .name' | head -1)

if [ -z "$EXTERNAL" ]; then
    notify-send "Monitores" "No se detectó ninguna pantalla externa conectada"
    exit 0
fi

OPTION=$(printf "Extender\nDuplicar (espejo)\nSolo pantalla externa\nSolo laptop" | rofi -dmenu -config ~/.config/rofi/config.rasi -p "Modo de pantalla ($EXTERNAL)")

case "$OPTION" in
    "Extender")
        hyprctl eval "hl.monitor({output = '$LAPTOP', enabled = true, position = '0x0'})"
        hyprctl eval "hl.monitor({output = '$EXTERNAL', enabled = true, position = 'auto'})"
        notify-send "Monitores" "Modo: Extendido"
        ;;
    "Duplicar (espejo)")
        hyprctl eval "hl.monitor({output = '$LAPTOP', enabled = true, position = '0x0'})"
        hyprctl eval "hl.monitor({output = '$EXTERNAL', enabled = true, mirror = '$LAPTOP'})"
        notify-send "Monitores" "Modo: Espejo"
        ;;
    "Solo pantalla externa")
        hyprctl eval "hl.monitor({output = '$EXTERNAL', enabled = true, position = '0x0'})"
        hyprctl eval "hl.monitor({output = '$LAPTOP', enabled = false})"
        notify-send "Monitores" "Modo: Solo pantalla externa"
        ;;
    "Solo laptop")
        hyprctl eval "hl.monitor({output = '$EXTERNAL', enabled = false})"
        hyprctl eval "hl.monitor({output = '$LAPTOP', enabled = true, position = '0x0'})"
        notify-send "Monitores" "Modo: Solo laptop"
        ;;
esac
