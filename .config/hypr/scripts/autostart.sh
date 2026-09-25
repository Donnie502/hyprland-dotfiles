eval $(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export GNOME_KEYRING_CONTROL SSH_AUTH_SOCK
hyprctl setenv GNOME_KEYRING_CONTROL "$GNOME_KEYRING_CONTROL" 2>/dev/null
hyprctl setenv SSH_AUTH_SOCK "$SSH_AUTH_SOCK" 2>/dev/null

#!/bin/bash

# Limpia cualquier instancia vieja y pipes rotos antes de empezar
pkill -9 wob 2>/dev/null
rm -f /tmp/wob.sock /tmp/wob-locks.sock
mkfifo /tmp/wob.sock
mkfifo /tmp/wob-locks.sock

# Barra de volumen/brillo
tail -f /tmp/wob.sock | wob &

# Barra de Caps/Num Lock
tail -f /tmp/wob-locks.sock | wob -c ~/.config/wob/wob-locks.ini &

sleep 1

# Sincroniza el estado real de Caps/Num Lock al iniciar
caps=$(hyprctl devices | grep -A6 "at-translated-set-2-keyboard" | grep -oP '(?<=capsLock: )\w+')
num=$(hyprctl devices | grep -A6 "at-translated-set-2-keyboard" | grep -oP '(?<=numLock: )\w+')
[ "$caps" = "yes" ] && echo on > /tmp/capslock_state || echo off > /tmp/capslock_state
[ "$num" = "yes" ] && echo on > /tmp/numlock_state || echo off > /tmp/numlock_state

# Íconos de bandeja
blueman-applet &
XCURSOR_THEME=Adwaita
wl-paste --watch ~/.config/hypr/scripts/clip-notify.sh &
# Barras de audio en el escritorio (eww + cava)
pkill -9 eww 2>/dev/null
sleep 1
~/.local/bin/eww daemon
sleep 1
~/.local/bin/eww open-many bars-top bars-bottom
python3 ~/.config/eww/scripts/notif-listener.py &
ibus-daemon -drxR & disown
easyeffects --gapplication-service & disown
