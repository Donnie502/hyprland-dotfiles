#!/bin/bash
PROFILES="balanced\nbalanced-battery\npowersave\ndesktop\nthroughput-performance\nlatency-performance"
CURRENT=$(tuned-adm active | grep "Current active profile:" | head -1 | cut -d: -f2 | xargs)

CHOICE=$(echo -e "$PROFILES" | rofi -dmenu \
    -p "Perfil de energía" \
    -mesg "Activo: $CURRENT" \
    -theme-str 'window {width: 400px;}')

[ -z "$CHOICE" ] && exit 0
pkexec tuned-adm profile "$CHOICE"
notify-send "Perfil de energía" "Cambiado a: $CHOICE"
