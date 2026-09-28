#!/usr/bin/env bash
# Reúne el estado de la instalación en un archivo de texto, para revisarlo
# o compartirlo cuando algo falla. No sube nada a internet: el archivo se
# queda en tu equipo y tú decides con quién compartirlo.
#
#     ~/dotfiles/tools/diag.sh          # crea ~/dotfiles-diagnostico.txt
OUT="$HOME/dotfiles-diagnostico.txt"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

{
  echo "===== sistema ====="
  . /etc/os-release 2>/dev/null && echo "$PRETTY_NAME"
  echo "arquitectura: $(uname -m)   máquina virtual: $(systemd-detect-virt --vm 2>/dev/null)"
  echo "sesión: ${XDG_SESSION_TYPE:-?} / ${XDG_CURRENT_DESKTOP:-?}"

  echo; echo "===== Hyprland ====="
  Hyprland --version 2>&1 | head -1
  hyprctl monitors 2>&1 | head -25

  echo; echo "===== config ====="
  echo "-- render por software en VM (hyprland.lua) --"
  grep -n 'LIBGL_ALWAYS_SOFTWARE' "$HOME/.config/hypr/hyprland.lua" 2>&1
  echo "-- environment.d --"
  ls "$HOME/.config/environment.d/" 2>&1

  echo; echo "===== programas ====="
  for c in Hyprland kitty foot thunar rofi waybar swaync cava wallust eww hyprlock hypridle wl-copy cliphist; do
    if command -v "$c" >/dev/null 2>&1; then echo "ok     $c"; else echo "FALTA  $c"; fi
  done

  echo; echo "===== paquetes de Hyprland ====="
  rpm -qa 'hypr*' 'xdg-desktop-portal*' 2>&1 | sort

  echo; echo "===== procesos ====="
  pgrep -a 'waybar|swaync|wl-paste|eww|Hyprland' 2>&1 | head -20

  echo; echo "===== registro del instalador ====="
  cat "$HOME/.local/share/hyprland-dotfiles/registro" 2>&1 | head -40

  echo; echo "===== últimas líneas del log de instalación ====="
  tail -40 "$HOME/dotfiles-install.log" 2>&1
} > "$OUT" 2>&1

echo "Diagnóstico guardado en: $OUT"
echo "Revísalo antes de compartirlo; incluye tu nombre de usuario y rutas de tu equipo."
