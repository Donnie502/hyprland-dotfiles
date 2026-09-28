#!/usr/bin/env bash
# ==================================================================
#  Desinstalador de los dotfiles de Hyprland para Fedora
#
#     ~/dotfiles/uninstall.sh             muestra el plan y pide confirmación
#     ~/dotfiles/uninstall.sh --simular   solo muestra el plan, no cambia nada
#     ~/dotfiles/uninstall.sh --si        sin preguntar (para automatizar)
#
#  Quita lo que agregó install.sh (anotado en su registro) y regresa tu
#  configuración anterior si había una. Nunca quita paquetes que Fedora
#  o GNOME necesitan. Córrelo desde GNOME, como tu usuario (sin sudo).
# ==================================================================
# shellcheck disable=SC2088  # el "~" de los mensajes es solo texto
set -Ee

DOTS="$(cd "$(dirname "$0")" && pwd)"
REGISTRO="$HOME/.local/share/hyprland-dotfiles/registro"
HYPR_COPR="ashbuk/Hyprland-Fedora"
LOG="$HOME/dotfiles-uninstall.log"

# Paquetes que solo sirven para este escritorio: se quitan aunque no haya
# registro (instalaciones hechas con la versión vieja del instalador).
EXCLUSIVOS="hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprland-guiutils
            hyprland-qtutils waybar SwayNotificationCenter rofi wlogout wob swaybg
            cliphist nwg-look nwg-displays foot cava"
# Nunca se quitan, aunque los haya instalado el instalador: el sistema,
# GNOME o la máquina virtual los necesitan.
NUNCA="NetworkManager python3 git curl unzip gnome-keyring dnf-plugins-core tuned
       open-vm-tools open-vm-tools-desktop spice-vdagent qemu-guest-agent
       virtualbox-guest-additions"
# Carpetas de ~/.config que pueden tener cosas tuyas además de las del repo:
# de estas solo se borran los archivos que puso el repo.
COMPARTIDAS="kitty MangoHud environment.d btop"

# ---------------------------------------------------------------- opciones
SIMULAR=0; SI=0
for a in "$@"; do
  case "$a" in
    --simular|-n) SIMULAR=1 ;;
    --si|-y)      SI=1 ;;
    -h|--help)    sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $a  (usa --simular, --si o --help)"; exit 2 ;;
  esac
done

# ---------------------------------------------------------------- utilidades
[ "$SIMULAR" = 1 ] || exec > >(tee -a "$LOG") 2>&1

info()  { echo "    $*"; }
aviso() { echo "    !! $*"; }
falla() {
  trap - ERR
  echo
  echo "=================================================="
  echo " ERROR: $*"
  [ "$SIMULAR" = 1 ] || echo " Log completo: $LOG"
  echo "=================================================="
  exit 1
}
trap 'falla "fallo inesperado en la línea $LINENO: $BASH_COMMAND"' ERR

en_lista() { case " $(echo $2) " in *" $1 "*) return 0;; esac; return 1; }
valor()    { grep -E "^$1 " "$REGISTRO" 2>/dev/null | head -1 | cut -d' ' -f2-; }
anotado()  { grep -qE "^$1( |$)" "$REGISTRO" 2>/dev/null; }
# líneas del registro con una clave dada
entradas() { grep -E "^$1 " "$REGISTRO" 2>/dev/null | cut -d' ' -f2- || true; }

# Protección: solo se borra dentro de estas rutas, aunque el registro
# estuviera dañado o editado a mano. Nunca $HOME ni ~/.config completos.
permitido() {
  local f="$1" n
  case "$f" in ""|*..*) return 1 ;; esac
  case "$f" in
    "$HOME/.local/bin/eww"|"$HOME/.local/bin/wallust"|"$HOME/.cargo/bin/wallust"|\
    "$HOME/.local/share/icons/candy-icons"|"$HOME/.local/share/fonts/JetBrainsMonoNF")
      return 0 ;;
    "$HOME/Pictures/wallpapers/"?*)
      [ -f "$DOTS/wallpapers/${f##*/}" ]; return ;;
    "$HOME/.config/"?*)
      n="${f#"$HOME/.config/"}"; n="${n%%/*}"
      [ -n "$n" ] && [ -e "$DOTS/.config/$n" ]; return ;;
  esac
  return 1
}
# Filtra una lista de rutas: deja solo las permitidas y que existan
filtrar() {
  local f out=""
  for f in $1; do
    en_lista "$f" "$out" && continue
    if ! permitido "$f"; then aviso "Se ignora una ruta fuera de lo permitido: $f" >&2; continue; fi
    if [ -e "$f" ] || [ -L "$f" ]; then out="$out $f"; fi
  done
  echo "$out"
}

# ---------------------------------------------------------------- revisión
echo "=================================================="
echo " Desinstalar dotfiles Hyprland  -  $(date '+%Y-%m-%d %H:%M')"
echo "=================================================="
[ "$(id -u)" -ne 0 ] || falla "No lo corras con sudo ni como root. Córrelo así: ~/dotfiles/uninstall.sh"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || falla "Este desinstalador es solo para Fedora."

# Tres casos:
#   registro -> se quita exactamente lo anotado por install.sh
#   vieja    -> instalación de la versión vieja (no anotaba nada): se
#               reconoce por el autostart.sh de este repo y se quita lo
#               que esa versión copiaba
#   nada     -> no hay rastro de estos dotfiles: no se toca nada
AUTOSTART="$HOME/.config/hypr/scripts/autostart.sh"
if [ -f "$REGISTRO" ]; then
  MODO=registro
  if anotado previa; then
    info "Registro encontrado, con una instalación vieja antes de él: se quita todo"
    info "lo de este escritorio, pero no hay configuración anterior que regresar."
  else
    info "Registro encontrado: se quita exactamente lo que agregó el instalador."
  fi
elif [ -f "$AUTOSTART" ] && grep -q "notif-listener" "$AUTOSTART"; then
  MODO=vieja
  info "Sin registro, pero están estos dotfiles (instalados con la versión vieja):"
  info "se quita solo lo que es exclusivo de este escritorio."
else
  MODO=nada
fi
# En "registro" con instalación previa se suma lo de la versión vieja
AMPLIO=0
{ [ "$MODO" = vieja ] || { [ "$MODO" = registro ] && anotado previa; }; } && AMPLIO=1

# ---------------------------------------------------------------- armar el plan
# 1) paquetes
CAND="$(entradas pkg)"
[ "$AMPLIO" = 0 ] || CAND="$CAND $EXCLUSIVOS"
PKGS=""
for p in $CAND; do
  en_lista "$p" "$NUNCA" && continue
  en_lista "$p" "$PKGS" && continue
  rpm -q "$p" >/dev/null 2>&1 && PKGS="$PKGS $p"
done
PKGS="${PKGS# }"

# 2) repositorios
QUITAR_COPR=0
if compgen -G "/etc/yum.repos.d/*${HYPR_COPR/\//:}*.repo" >/dev/null \
   && { anotado "copr $HYPR_COPR" || en_lista hyprland "$PKGS"; }; then
  QUITAR_COPR=1
fi
QUITAR_BRAVE_REPO=0
if anotado "repo brave-browser" && [ -f /etc/yum.repos.d/brave-browser.repo ]; then QUITAR_BRAVE_REPO=1; fi

# 3) programas y recursos fuera de dnf
CAND="$(entradas file)"
if [ "$AMPLIO" = 1 ]; then
  CAND="$CAND $HOME/.local/bin/eww $HOME/.local/bin/wallust $HOME/.cargo/bin/wallust
        $HOME/.local/share/icons/candy-icons $HOME/.local/share/fonts/JetBrainsMonoNF"
fi
ARCHIVOS="$(filtrar "$CAND")"
CARGO_DIR=0
anotado "dir $HOME/.cargo" && [ -d "$HOME/.cargo" ] && CARGO_DIR=1

# 4) configs: carpetas enteras (las de este escritorio) o archivos sueltos
#    (dentro de carpetas que pueden ser tuyas, como kitty)
CAND="$(entradas conf)"
if [ "$AMPLIO" = 1 ]; then
  for d in "$DOTS/.config/"*; do
    n="$(basename "$d")"
    if en_lista "$n" "$COMPARTIDAS"; then
      while IFS= read -r f; do CAND="$CAND $HOME/.config/${f#"$DOTS/.config/"}"; done < <(find "$d" -type f)
    else
      CAND="$CAND $HOME/.config/$n"
    fi
  done
fi
CONF_BORRAR=""; CONF_ARCHIVOS=""
for f in $(filtrar "$CAND"); do
  if [ -d "$f" ]; then CONF_BORRAR="$CONF_BORRAR $f"; else CONF_ARCHIVOS="$CONF_ARCHIVOS $f"; fi
done
RESPALDO="$(valor respaldo || true)"
[ "$RESPALDO" != "ninguno" ] || RESPALDO=""
case "$RESPALDO" in
  "") ;;
  "$HOME/.config-respaldo-"*)
    [ -d "$RESPALDO" ] || { aviso "El respaldo anotado ya no existe: $RESPALDO"; RESPALDO=""; } ;;
  *) aviso "Se ignora un respaldo fuera de lo permitido: $RESPALDO"; RESPALDO="" ;;
esac

# 5) wallpapers: los que copió el instalador, y solo si siguen idénticos
#    a los del repo (si los editaste, se quedan)
CAND="$(entradas fondo)"
if [ "$AMPLIO" = 1 ]; then
  for f in "$DOTS/wallpapers/"*; do CAND="$CAND $HOME/Pictures/wallpapers/$(basename "$f")"; done
fi
FONDOS=""
for dst in $(filtrar "$CAND"); do
  if [ -f "$dst" ] && cmp -s "$DOTS/wallpapers/$(basename "$dst")" "$dst"; then FONDOS="$FONDOS $dst"; fi
done

# 6) ajustes del sistema
GS="$(grep -E '^gs ' "$REGISTRO" 2>/dev/null || true)"
GDM=0
if anotado gdm_autologin && [ -f /etc/gdm/custom.conf ] \
   && grep -q '^AutomaticLoginEnable=false' /etc/gdm/custom.conf; then GDM=1; fi

# ---------------------------------------------------------------- mostrar el plan
lista() { local x; for x in $1; do echo "      - ${x/#$HOME/\~}"; done; }
echo
echo "==> Esto es lo que se va a quitar"
if [ -n "$PKGS" ]; then echo "    Paquetes:"; lista "$PKGS"; else info "Paquetes: ninguno"; fi
[ "$QUITAR_COPR" = 0 ]       || info "Repositorio COPR $HYPR_COPR"
[ "$QUITAR_BRAVE_REPO" = 0 ] || info "Repositorio de Brave"
if [ -n "${ARCHIVOS// /}" ]; then echo "    Programas, iconos y fuente:"; lista "$ARCHIVOS"; fi
[ "$CARGO_DIR" = 0 ]         || info "~/.cargo (lo creó el instalador; solo si no queda nada tuyo dentro)"
if [ -n "$CONF_BORRAR" ];   then echo "    Carpetas de configuración:"; lista "$CONF_BORRAR"; fi
if [ -n "$CONF_ARCHIVOS" ]; then echo "    Archivos de configuración (en carpetas que pueden ser tuyas):"; lista "$CONF_ARCHIVOS"; fi
if [ -n "$FONDOS" ];        then echo "    Wallpapers del repo:"; lista "$FONDOS"; fi
echo
echo "==> Esto se va a regresar como estaba"
[ -z "$RESPALDO" ] || info "Tu configuración anterior, desde ${RESPALDO/#$HOME/\~}"
[ -z "$GS" ]       || info "Tema de GNOME (esquema de color y cursor)"
[ "$GDM" = 0 ]     || info "Inicio de sesión automático de GDM"
[ -n "$RESPALDO$GS" ] || [ "$GDM" = 1 ] || info "(nada: no hay estado anterior guardado)"
echo
echo "==> Esto NO se toca"
info "Paquetes del sistema: $(echo $NUNCA)"
info "Respaldos ~/.config-respaldo-*, tus wallpapers propios y este repo (~/dotfiles)"
if [ "${XDG_CURRENT_DESKTOP:-}" = "Hyprland" ]; then
  echo
  aviso "Estás dentro de Hyprland. Funciona igual, pero al terminar cierra sesión y entra a GNOME."
fi

if [ -z "${PKGS}${ARCHIVOS// /}${CONF_BORRAR}${CONF_ARCHIVOS}${FONDOS}${RESPALDO}${GS}" ] \
   && [ "$QUITAR_COPR$QUITAR_BRAVE_REPO$GDM$CARGO_DIR" = "0000" ]; then
  echo; echo " No hay nada que desinstalar (no se encontró una instalación de estos dotfiles)."
  exit 0
fi
if [ "$SIMULAR" = 1 ]; then
  echo; echo " (--simular: no se cambió nada)"; exit 0
fi
if [ "$SI" = 0 ]; then
  echo
  read -r -p " Escribe SI para desinstalar: " RESP || RESP=""
  case "$RESP" in
    SI|si|Si|SÍ|sí|Sí) ;;
    *) echo " Cancelado. No se cambió nada."; exit 0 ;;
  esac
fi

# ---------------------------------------------------------------- ejecutar
if [ -n "$PKGS" ] || [ "$QUITAR_COPR$QUITAR_BRAVE_REPO$GDM" != "000" ]; then
  info "Se necesitan permisos de administrador (sudo) para quitar paquetes y repositorios."
  sudo -v || falla "No se pudo obtener sudo."
fi

echo
echo "==> [1/5] Paquetes"
if [ -n "$PKGS" ]; then
  # wallust se instala con cargo: quitarlo antes de que se vaya cargo
  if [ -x "$HOME/.cargo/bin/wallust" ] && command -v cargo >/dev/null 2>&1; then
    cargo uninstall wallust >/dev/null 2>&1 || true
  fi
  if [ "$SI" = 1 ]; then
    sudo dnf remove -y $PKGS
  else
    info "dnf te va a mostrar la lista final (con lo que dependa de estos) y a pedir confirmación."
    sudo dnf remove $PKGS || aviso "No se quitaron los paquetes (lo cancelaste en dnf). Lo demás continúa."
  fi
else
  info "Nada que quitar."
fi

echo "==> [2/5] Repositorios"
if [ "$QUITAR_COPR" = 1 ]; then
  sudo dnf copr remove -y "$HYPR_COPR" 2>/dev/null || sudo dnf copr disable -y "$HYPR_COPR" || true
  info "COPR $HYPR_COPR quitado."
fi
if [ "$QUITAR_BRAVE_REPO" = 1 ]; then
  sudo rm -f /etc/yum.repos.d/brave-browser.repo
  info "Repositorio de Brave quitado."
fi

echo "==> [3/5] Programas, iconos y fuente"
for f in $ARCHIVOS; do rm -rf "$f"; done
if [ "$CARGO_DIR" = 1 ]; then
  if [ -z "$(ls -A "$HOME/.cargo/bin" 2>/dev/null)" ]; then
    rm -rf "$HOME/.cargo"; info "~/.cargo borrado."
  else
    info "~/.cargo tiene otros programas tuyos; se deja."
  fi
fi
if [ -n "${ARCHIVOS// /}" ] && command -v fc-cache >/dev/null 2>&1; then fc-cache -f >/dev/null 2>&1 || true; fi

echo "==> [4/5] Configuración y wallpapers"
for f in $CONF_BORRAR $CONF_ARCHIVOS $FONDOS; do rm -rf "$f"; done
for n in $COMPARTIDAS; do rmdir "$HOME/.config/$n" 2>/dev/null || true; done
rmdir "$HOME/Pictures/wallpapers" 2>/dev/null || true
if [ -n "$RESPALDO" ]; then
  cp -a "$RESPALDO/." "$HOME/.config/"
  info "Configuración anterior restaurada."
fi

echo "==> [5/5] Ajustes del sistema"
if [ -n "$GS" ]; then
  while read -r _ k v; do
    gsettings set org.gnome.desktop.interface "$k" "$v" 2>/dev/null || true
  done <<< "$GS"
  info "Tema de GNOME regresado."
fi
if [ "$GDM" = 1 ]; then
  sudo sed -i 's/^AutomaticLoginEnable=false/AutomaticLoginEnable=True/' /etc/gdm/custom.conf
  info "Inicio de sesión automático reactivado."
fi
rm -rf "$(dirname "$REGISTRO")"
rm -f "$HOME/dotfiles-install.log"

echo
echo "=================================================="
echo " Desinstalación completa."
echo "   1) Reinicia y entra a GNOME."
if ls -d "$HOME"/.config-respaldo-* >/dev/null 2>&1; then
  echo "   Tus respaldos siguen en ~/.config-respaldo-* (bórralos cuando quieras)."
fi
echo "   Para borrar también este repo:  rm -rf $DOTS"
echo "=================================================="
