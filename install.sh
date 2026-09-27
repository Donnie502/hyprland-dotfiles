#!/usr/bin/env bash
# ==================================================================
#  Instalador de los dotfiles de Hyprland para Fedora (43 / 44)
#
#  Uso (como tu usuario, NO con sudo, idealmente desde GNOME):
#     git clone https://github.com/Donnie502/hyprland-dotfiles ~/dotfiles
#     ~/dotfiles/install.sh
#
#  Se puede volver a correr sin romper nada. Todo lo que imprime se
#  guarda tambien en ~/dotfiles-install.log
#
#  Lo que agrega queda anotado en ~/.local/share/hyprland-dotfiles/registro
#  para que uninstall.sh quite exactamente eso y nada mas.
# ==================================================================
set -Ee

DOTS="$(cd "$(dirname "$0")" && pwd)"
OLDHOME="/home/donnie502"
HYPR_COPR="ashbuk/Hyprland-Fedora"
HYPR_MIN="0.55"   # la config es Lua (hyprland.lua): existe desde Hyprland 0.55
HYPR_PKGS="hyprland hyprlock hypridle xdg-desktop-portal-hyprland"
BRAVE_REPO="https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
LOG="$HOME/dotfiles-install.log"
REGISTRO="$HOME/.local/share/hyprland-dotfiles/registro"
TOTAL=10

# ---------------------------------------------------------------- utilidades
exec > >(tee -a "$LOG") 2>&1

paso()  { echo; echo "==> [$1/$TOTAL] $2"; }
info()  { echo "    $*"; }
aviso() { echo "    !! $*"; }
falla() {
  trap - ERR
  # anotar lo que si se alcanzo a instalar, para poder desinstalarlo
  [ -z "${CANDIDATOS:-}" ] || registrar_paquetes || true
  echo
  echo "=================================================="
  echo " ERROR: $*"
  echo " Nada quedo a medias que impida volver a correrlo."
  echo " Log completo: $LOG"
  echo "=================================================="
  exit 1
}
trap 'falla "fallo inesperado en la linea $LINENO: $BASH_COMMAND"' ERR

# Version de Hyprland instalada ("0.56.2"), o vacio si no hay
hypr_ver() { Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }
# ver_ge A B  ->  verdadero si A >= B
ver_ge() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]; }
# De una lista de paquetes, imprime los que estan instalados
instalados() { for p in "$@"; do rpm -q "$p" >/dev/null 2>&1 && echo "$p"; done; return 0; }

# Registro para uninstall.sh: una linea "clave valor" por cosa agregada
anotar()  { grep -qxF "$*" "$REGISTRO" 2>/dev/null || echo "$*" >> "$REGISTRO"; }
anotado() { grep -qE "^$1( |$)" "$REGISTRO" 2>/dev/null; }
# Anota los paquetes que no estaban antes de correr el instalador
registrar_paquetes() {
  local p
  for p in $(instalados $CANDIDATOS); do
    case "$PREVIOS" in *" $p "*) ;; *) anotar "pkg $p" ;; esac
  done
}

# ---------------------------------------------------------------- 0. revision
echo "=================================================="
echo " Dotfiles Hyprland  -  $(date '+%Y-%m-%d %H:%M')"
echo "=================================================="
[ "$(id -u)" -ne 0 ] || falla "No lo corras con sudo ni como root. Correlo asi: ~/dotfiles/install.sh"
. /etc/os-release
[ "${ID:-}" = "fedora" ] || falla "Este instalador es solo para Fedora (detectado: ${ID:-desconocido})."
VIRT="$(systemd-detect-virt --vm 2>/dev/null || true)"
[ -n "$VIRT" ] || VIRT="none"
info "Fedora $VERSION_ID  |  maquina virtual: $VIRT"
curl -fsS --max-time 20 -o /dev/null https://github.com \
  || falla "Sin internet: no se alcanza github.com."

echo "    Te va a pedir tu contrasena una sola vez."
sudo -v || falla "Se necesita sudo."
# Mantener sudo vivo: la compilacion de eww tarda mas que el timeout de sudo
( trap - ERR; while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
SUDO_KEEP=$!
trap 'kill $SUDO_KEEP 2>/dev/null || true' EXIT

# Registro de lo que se agrega (lo usa uninstall.sh)
mkdir -p "$(dirname "$REGISTRO")"
if [ ! -f "$REGISTRO" ] \
   && { [ -f "$HOME/.config/hypr/scripts/autostart.sh" ] || [ -x "$HOME/.local/bin/eww" ]; }; then
  # Ya habia una instalacion de una version vieja del instalador, que no
  # anotaba nada: no sabemos como estaba el sistema antes de ella.
  anotar "previa 1"
fi
REQ="$(grep -vE '^[[:space:]]*(#|$)' "$DOTS/packages.txt" | grep -v '^?' || true)"
OPT="$(grep -E '^\?' "$DOTS/packages.txt" | sed 's/^?//' || true)"
CANDIDATOS="$HYPR_PKGS $REQ $OPT brave-browser dnf-plugins-core"
PREVIOS=" $(instalados $CANDIDATOS | tr '\n' ' ') "

# ---------------------------------------------------------------- 1. Hyprland
paso 1 "Hyprland (COPR $HYPR_COPR)"
# Fedora retiro Hyprland de sus repos oficiales desde F43. El COPR de
# ashbuk empaqueta Hyprland >= 0.55 con sus librerias hypr* propias
# (vendorizadas), asi que no choca con las viejas de Fedora.
V="$(hypr_ver)"
if [ -n "$V" ] && ver_ge "$V" "$HYPR_MIN"; then
  info "Hyprland $V ya instalado (>= $HYPR_MIN). No se toca."
else
  [ -z "$V" ] || aviso "Hyprland $V es muy viejo para esta config (Lua, pide >= $HYPR_MIN). Se reemplaza."
  sudo dnf install -y 'dnf-command(copr)'
  # COPRs que dan un Hyprland viejo (sin config Lua) o de rawhide
  for R in mpapacc/hyprland solopasha/hyprland; do
    if compgen -G "/etc/yum.repos.d/*${R/\//:}*.repo" >/dev/null; then
      info "Quitando el COPR $R (no sirve con esta config)"
      sudo dnf copr remove -y "$R" 2>/dev/null || sudo dnf copr disable -y "$R" || true
    fi
  done
  compgen -G "/etc/yum.repos.d/*${HYPR_COPR/\//:}*.repo" >/dev/null || anotar "copr $HYPR_COPR"
  sudo dnf copr enable -y "$HYPR_COPR" \
    || falla "No se pudo activar el COPR $HYPR_COPR. Puede que aun no tenga paquetes para Fedora $VERSION_ID."
  VIEJOS="$(instalados $HYPR_PKGS)"
  if [ -n "$VIEJOS" ]; then
    info "Quitando la version anterior: $(echo $VIEJOS)"
    sudo dnf remove -y $VIEJOS
  fi
  sudo dnf install -y $HYPR_PKGS
  V="$(hypr_ver)"
fi
{ [ -n "$V" ] && ver_ge "$V" "$HYPR_MIN"; } \
  || falla "Hyprland ${V:-no se instalo}. Esta config necesita Hyprland >= $HYPR_MIN."
registrar_paquetes
info "OK: Hyprland $V"

# ---------------------------------------------------------------- 2. paquetes
paso 2 "Paquetes de Fedora"
# --skip-unavailable solo para no abortar por un opcional; abajo se
# revisa uno por uno y los obligatorios que falten detienen todo.
sudo dnf install -y --skip-unavailable $REQ $OPT
registrar_paquetes
FALTA_OPT=""; for p in $OPT; do rpm -q "$p" >/dev/null 2>&1 || FALTA_OPT="$FALTA_OPT $p"; done
FALTA_REQ=""; for p in $REQ; do rpm -q "$p" >/dev/null 2>&1 || FALTA_REQ="$FALTA_REQ $p"; done
[ -z "$FALTA_OPT" ] || aviso "Opcionales que no estan en los repos (se omiten):$FALTA_OPT"
[ -z "$FALTA_REQ" ] || falla "No se pudieron instalar paquetes obligatorios:$FALTA_REQ"
info "OK: $(echo $REQ | wc -w) obligatorios instalados"

# ---------------------------------------------------------------- 3. navegador
paso 3 "Navegador (Brave, para SUPER+B)"
if rpm -q brave-browser >/dev/null 2>&1; then
  info "Brave ya instalado."
else
  sudo dnf install -y dnf-plugins-core
  if [ ! -f /etc/yum.repos.d/brave-browser.repo ]; then
    if sudo dnf config-manager addrepo --from-repofile="$BRAVE_REPO"; then
      anotar "repo brave-browser"
    else
      aviso "No se pudo agregar el repo de Brave."
    fi
  fi
  sudo dnf install -y brave-browser \
    || aviso "No se pudo instalar Brave: SUPER+B no abrira nada hasta que instales un navegador."
  registrar_paquetes
fi

# ---------------------------------------------------------------- 4. energia
paso 4 "Perfiles de energia"
if command -v tuned-adm >/dev/null 2>&1; then
  sudo systemctl enable --now tuned || aviso "No se pudo arrancar tuned."
  sudo tuned-adm profile balanced || true
fi
if [ "$VIRT" = "none" ] && rpm -q thermald >/dev/null 2>&1; then
  sudo systemctl enable --now thermald || aviso "thermald no arranco (normal si tu CPU no es Intel)."
fi

# ---------------------------------------------------------------- 5. wallust
paso 5 "wallust (colores segun el wallpaper)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
# Si ~/.cargo no existia, lo crea cargo para nosotros (y guarda ahi cientos
# de MB de cache): se anota para que el desinstalador lo borre completo.
[ -d "$HOME/.cargo" ] || anotar "dir $HOME/.cargo"
if [ ! -x "$HOME/.cargo/bin/wallust" ]; then
  cargo install wallust
  anotar "file $HOME/.cargo/bin/wallust"
fi
# cargo lo deja en ~/.cargo/bin, que NO esta en el PATH de la sesion de
# Hyprland; ~/.local/bin si. Los scripts llaman "wallust" a secas.
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.cargo/bin/wallust" "$HOME/.local/bin/wallust"
anotar "file $HOME/.local/bin/wallust"

# ---------------------------------------------------------------- 6. eww
paso 6 "eww (visualizador y dashboard; compilar tarda varios minutos)"
if [ -x "$HOME/.local/bin/eww" ]; then
  info "eww ya instalado."
else
  rm -rf /tmp/eww-src
  git clone --depth 1 https://github.com/elkowar/eww /tmp/eww-src
  ( cd /tmp/eww-src && cargo build --release --no-default-features --features wayland )
  cp /tmp/eww-src/target/release/eww "$HOME/.local/bin/"
  rm -rf /tmp/eww-src
  anotar "file $HOME/.local/bin/eww"
fi

# ---------------------------------------------------------------- 7. iconos y fuente
paso 7 "Iconos (candy-icons) y fuente (JetBrainsMono Nerd Font)"
mkdir -p "$HOME/.local/share/icons"
if [ ! -d "$HOME/.local/share/icons/candy-icons" ]; then
  git clone --depth 1 https://github.com/EliverLara/candy-icons.git "$HOME/.local/share/icons/candy-icons"
  anotar "file $HOME/.local/share/icons/candy-icons"
fi
if ! fc-list | grep -i "JetBrainsMono Nerd Font" >/dev/null; then
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
  anotar "file $HOME/.local/share/fonts/JetBrainsMonoNF"
  curl -fL -o /tmp/jbm.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -oq /tmp/jbm.zip -d "$HOME/.local/share/fonts/JetBrainsMonoNF"
  rm -f /tmp/jbm.zip
  fc-cache -f >/dev/null
fi

# ---------------------------------------------------------------- 8. configs
paso 8 "Configuraciones y wallpapers"
mkdir -p "$HOME/.config" "$HOME/Pictures/wallpapers"
BACKUP="$HOME/.config-respaldo-$(date +%Y%m%d-%H%M%S)"
DIRS=""
for d in "$DOTS/.config/"*; do
  n="$(basename "$d")"
  DIRS="$DIRS $n"
  if [ -e "$HOME/.config/$n" ]; then
    mkdir -p "$BACKUP"
    cp -a "$HOME/.config/$n" "$BACKUP/"
  fi
done
if [ -d "$BACKUP" ]; then info "Respaldo de tu config anterior: $BACKUP"; fi
# El respaldo "original" (el de antes de la primera instalacion) es el que
# restaura uninstall.sh. Si ya habia una instalacion vieja sin registro,
# ese respaldo contendria nuestra propia config, asi que no cuenta.
if ! anotado respaldo; then
  if anotado previa || [ ! -d "$BACKUP" ]; then anotar "respaldo ninguno"
  else anotar "respaldo $BACKUP"; fi
fi
cp -r "$DOTS/.config/." "$HOME/.config/"
# Anotar lo copiado. Estas carpetas pueden tener cosas tuyas ademas de las
# del repo: de ellas se anotan solo los archivos, no la carpeta entera.
COMPARTIDAS="kitty MangoHud environment.d"
for n in $DIRS; do
  case " $COMPARTIDAS " in
    *" $n "*) while IFS= read -r f; do anotar "conf $HOME/.config/${f#"$DOTS/.config/"}"
              done < <(find "$DOTS/.config/$n" -type f) ;;
    *)        anotar "conf $HOME/.config/$n" ;;
  esac
done
# Restos de intentos anteriores: local.lua ya no se usa, y 90-vm-gl.conf
# forzaba render por software tambien al compositor (via systemd).
rm -f "$HOME/.config/hypr/local.lua" "$HOME/.config/environment.d/90-vm-gl.conf"
NUEVOS=""
for f in "$DOTS/wallpapers/"*; do
  dst="$HOME/Pictures/wallpapers/$(basename "$f")"
  [ -e "$dst" ] || NUEVOS="$NUEVOS $dst"
done
cp -rn "$DOTS/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
for w in $NUEVOS; do
  if [ -f "$w" ]; then anotar "fondo $w"; fi
done
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/eww/scripts/"* 2>/dev/null || true
# Las configs traen rutas absolutas de la maquina original
if [ "$HOME" != "$OLDHOME" ]; then
  for n in $DIRS; do
    grep -rl "$OLDHOME" "$HOME/.config/$n" 2>/dev/null | while read -r f; do
      sed -i "s#$OLDHOME#$HOME#g" "$f"
    done
  done
  info "Rutas ajustadas: $OLDHOME -> $HOME"
fi

# ---------------------------------------------------------------- 9. esta maquina
paso 9 "Ajustes de esta maquina"
HCONF="$HOME/.config/hypr/hyprland.lua"
# Solo la linea de codigo (el comentario de hyprland.lua tambien la menciona)
LIBGL_RE='^[[:space:]]+hl\.env\("LIBGL_ALWAYS_SOFTWARE"'
case "$VIRT" in
  vmware)   sudo dnf install -y --skip-unavailable open-vm-tools open-vm-tools-desktop ;;
  kvm|qemu) sudo dnf install -y --skip-unavailable spice-vdagent qemu-guest-agent ;;
  oracle)   sudo dnf install -y --skip-unavailable virtualbox-guest-additions ;;
esac
# (las herramientas de VM no se anotan: sirven aunque se quite Hyprland)
if [ "$VIRT" != "none" ]; then
  # El 3D del hipervisor (SVGA3D en VMware) rompe a las apps OpenGL:
  # kitty muere con "invalid arguments for wl_surface.attach". Con render
  # por software arrancan bien. Se pone dentro de hyprland.start para que
  # lo hereden solo las apps y no el compositor (ver hyprland.lua).
  grep -qE "$LIBGL_RE" "$HCONF" \
    || sed -i '/^hl.on("hyprland.start", function()/a\    hl.env("LIBGL_ALWAYS_SOFTWARE", "1") -- VM: agregado por install.sh' "$HCONF"
  grep -qE "$LIBGL_RE" "$HCONF" || falla "No se pudo configurar el render por software en $HCONF"
  info "VM: render por software para las apps (kitty y GTK4)."
fi
# Autologin de GDM impide elegir la sesion Hyprland
if [ -f /etc/gdm/custom.conf ] && grep -q '^AutomaticLoginEnable=[Tt]rue' /etc/gdm/custom.conf; then
  sudo sed -i 's/^AutomaticLoginEnable=[Tt]rue/AutomaticLoginEnable=false/' /etc/gdm/custom.conf
  anotar "gdm_autologin 1"
  info "Autologin de GDM desactivado (para poder elegir Hyprland)."
fi

# ---------------------------------------------------------------- 10. tema
paso 10 "Tema oscuro y colores del wallpaper"
# Guardar los valores de antes (solo la primera vez y si no habia una
# instalacion vieja, que ya los habria cambiado) para poder regresarlos
if ! anotado previa; then
  for k in color-scheme cursor-theme; do
    anotado "gs $k" || anotar "gs $k $(gsettings get org.gnome.desktop.interface "$k" 2>/dev/null || echo "''")"
  done
fi
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true
FIRST="$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f | sort | head -1)"
if [ -n "$FIRST" ]; then
  wallust run "$FIRST" >/dev/null 2>&1 || aviso "wallust no pudo generar colores (se usan los del repo)."
fi

# ---------------------------------------------------------------- verificacion
echo
echo "==> Verificacion final"
FALTA=""
ok() { echo "    ok     $1"; }
no() { echo "    FALTA  $1"; FALTA="$FALTA $1"; }
V="$(hypr_ver)"
if [ -n "$V" ] && ver_ge "$V" "$HYPR_MIN"; then ok "Hyprland $V"; else no "Hyprland>=$HYPR_MIN"; fi
for c in waybar swaync rofi kitty foot thunar swaybg wl-copy grim slurp jq dbus-monitor hyprlock hypridle wallust eww; do
  if command -v "$c" >/dev/null 2>&1; then ok "$c"; else no "$c"; fi
done
if ls /usr/share/wayland-sessions/hyprland*.desktop >/dev/null 2>&1; then ok "sesion Hyprland en GDM"; else no "sesion-Hyprland"; fi
if [ -f "$HCONF" ]; then ok "config $HCONF"; else no "hyprland.lua"; fi
if [ "$VIRT" != "none" ]; then
  if grep -qE "$LIBGL_RE" "$HCONF"; then ok "render por software (VM)"; else no "render-software-VM"; fi
fi
if [ "$HOME" != "$OLDHOME" ] && grep -rq "$OLDHOME" "$HOME/.config/hypr" 2>/dev/null; then no "rutas-sin-ajustar"; fi

echo
echo "=================================================="
if [ -n "$FALTA" ]; then
  echo " Terminado CON PROBLEMAS:$FALTA"
  echo " Log completo: $LOG"
  echo "=================================================="
  exit 1
fi
echo " Instalacion completa."
echo "   1) Reinicia (o cierra sesion)."
echo "   2) En la pantalla de inicio, engrane abajo a la derecha -> Hyprland."
echo "   Para quitar todo despues: $DOTS/uninstall.sh"
[ -z "$FALTA_OPT" ] || echo "   Opcionales que no se instalaron:$FALTA_OPT"
echo "=================================================="
