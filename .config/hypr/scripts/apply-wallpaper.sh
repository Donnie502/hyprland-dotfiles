#!/bin/bash
export PATH="$HOME/.cargo/bin:$PATH"

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
EXCLUDE="test.png"

if [ -n "$1" ]; then
    IMG="$1"
else
    IMG=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -iname "$EXCLUDE" | shuf -n 1)
fi

[ -z "$IMG" ] && exit 1

# Fondo
pkill swaybg
sleep 0.3
swaybg -i "$IMG" -m fill &
disown

# Paleta de colores
wallust run "$IMG"
sed -i 's/rgb(#/rgb(/g' "$HOME/.config/hypr/hyprlock-colors.conf" 2>/dev/null
cp "$IMG" "$HOME/.config/hypr/lockbg.jpg" 2>/dev/null
~/.local/bin/eww reload 2>/dev/null

# Waybar
pkill waybar
sleep 0.3
waybar &
disown

# Kitty (recarga ventanas abiertas)
touch "$HOME/.config/kitty/kitty.conf"

# Cava (solo si esta abierto)
if pgrep -f "class cava" > /dev/null; then
    pkill -f "class cava"
    sleep 0.3
    kitty --class cava --title cava -e cava &
    disown
fi

# Swaync
swaync-client --reload-css 2>/dev/null

notify-send "Fondo actualizado" "$(basename "$IMG")"
