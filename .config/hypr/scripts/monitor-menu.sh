#!/bin/bash
LAPTOP="eDP-1"
EXTERNAL=$(hyprctl monitors all -j | jq -r --arg laptop "$LAPTOP" '.[] | select(.name != $laptop) | .name' | head -1)

if [ -z "$EXTERNAL" ]; then
    notify-send "Monitores" "No se detecto ninguna pantalla externa conectada"
    exit 0
fi

OPTION=$(printf "Extender\nDuplicar (espejo)\nSolo pantalla externa\nSolo laptop" | rofi -dmenu -config ~/.config/rofi/config.rasi -p "Pantalla ($EXTERNAL)")

case "$OPTION" in
    "Extender")
        hyprctl eval "hl.monitor({output='$LAPTOP', disabled=false, mode='preferred', position='0x0', scale='1'})"
        hyprctl eval "hl.monitor({output='$EXTERNAL', disabled=false, mode='preferred', position='auto', scale='1'})"
        notify-send "Monitores" "Modo: Extendido" ;;
    "Duplicar (espejo)")
        hyprctl eval "hl.monitor({output='$LAPTOP', disabled=false, mode='preferred', position='0x0', scale='1'})"
        hyprctl eval "hl.monitor({output='$EXTERNAL', disabled=false, mirror='$LAPTOP'})"
        notify-send "Monitores" "Modo: Espejo" ;;
    "Solo pantalla externa")
        hyprctl eval "hl.monitor({output='$EXTERNAL', disabled=false, mode='preferred', position='0x0', scale='1'})"
        hyprctl eval "hl.monitor({output='$LAPTOP', disabled=true})"
        notify-send "Monitores" "Modo: Solo pantalla externa" ;;
    "Solo laptop")
        hyprctl eval "hl.monitor({output='$EXTERNAL', disabled=true})"
        hyprctl eval "hl.monitor({output='$LAPTOP', disabled=false, mode='preferred', position='0x0', scale='1'})"
        notify-send "Monitores" "Modo: Solo laptop" ;;
esac
