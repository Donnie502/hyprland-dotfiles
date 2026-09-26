#!/usr/bin/env bash
# Recoge el estado del sistema y lo sube a una URL corta, para poder
# compartirlo sin tener que copiar y pegar pantallas.
OUT="$(mktemp)"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

{
  echo "===== sistema ====="
  . /etc/os-release 2>/dev/null && echo "$PRETTY_NAME"
  echo "virt: $(systemd-detect-virt 2>/dev/null)"
  echo "sesion: ${XDG_SESSION_TYPE:-?} / ${XDG_CURRENT_DESKTOP:-?}"
  echo "DISPLAY=${DISPLAY:-vacio}  WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-vacio}"
  echo "PATH=$PATH"

  echo; echo "===== hyprland ====="
  hyprctl version 2>&1 | head -3
  echo "-- monitores --"; hyprctl monitors 2>&1 | head -25
  echo "-- LIBGL_ALWAYS_SOFTWARE en la sesion --"
  hyprctl getoption env 2>/dev/null | head -5
  echo "LIBGL_ALWAYS_SOFTWARE=${LIBGL_ALWAYS_SOFTWARE:-no definido}"

  echo; echo "===== config ====="
  echo "-- primeras lineas de hyprland.lua --"
  head -6 "$HOME/.config/hypr/hyprland.lua" 2>&1
  echo "-- local.lua --"
  cat "$HOME/.config/hypr/local.lua" 2>&1
  echo "-- environment.d --"
  cat "$HOME/.config/environment.d/"*.conf 2>&1
  echo "-- terminal configurada --"
  grep -n 'local terminal' "$HOME/.config/hypr/hyprland.lua" 2>&1

  echo; echo "===== binarios ====="
  for c in Hyprland kitty foot thunar rofi waybar swaync cava wallust eww hyprlock vmtoolsd wl-copy cliphist; do
    command -v "$c" >/dev/null 2>&1 && echo "ok    $c" || echo "FALTA $c"
  done

  echo; echo "===== paquetes hypr ====="
  rpm -qa 'hypr*' 'aquamarine*' 'xdg-desktop-portal*' 2>&1 | sort

  echo; echo "===== procesos ====="
  pgrep -a 'waybar|swaync|vmtoolsd|wl-paste|eww|Hyprland' 2>&1 | head -20

  echo; echo "===== portapapeles ====="
  echo "prueba-portapapeles-$$" | wl-copy 2>&1
  echo "wl-paste devuelve: $(wl-paste 2>&1)"

  echo; echo "===== kitty ====="
  timeout 8 kitty --start-as=minimized -o confirm_os_window_close=0 sh -c 'exit' 2>&1 | head -10
  echo "(salida de kitty arriba; vacio = arranco bien)"

  echo; echo "===== sesiones del gestor de inicio ====="
  ls /usr/share/wayland-sessions/ 2>&1
} > "$OUT" 2>&1

echo
echo "Diagnostico guardado en: $OUT"
URL=$(curl -s -F "file=@$OUT" https://0x0.st 2>/dev/null)
if [ -n "$URL" ]; then
  echo
  echo "=================================================="
  echo " Pasale esta liga a Claude:"
  echo "   $URL"
  echo "=================================================="
else
  echo "No se pudo subir. Abre el archivo y copia su contenido:"
  echo "   $OUT"
fi
