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
# ==================================================================
set -Ee

DOTS="$(cd "$(dirname "$0")" && pwd)"
OLDHOME="/home/donnie502"
HYPR_COPR="ashbuk/Hyprland-Fedora"
HYPR_MIN="0.55"   # la config es Lua (hyprland.lua): existe desde Hyprland 0.55
HYPR_PKGS="hyprland hyprlock hypridle xdg-desktop-portal-hyprland"
BRAVE_REPO="https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
LOG="$HOME/dotfiles-install.log"
TOTAL=10

# ---------------------------------------------------------------- utilidades
exec > >(tee -a "$LOG") 2>&1

paso()  { echo; echo "==> [$1/$TOTAL] $2"; }
info()  { echo "    $*"; }
aviso() { echo "    !! $*"; }
falla() {
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
info "OK: Hyprland $V"

# ---------------------------------------------------------------- 2. paquetes
paso 2 "Paquetes de Fedora"
REQ="$(grep -vE '^[[:space:]]*(#|$)' "$DOTS/packages.txt" | grep -v '^?' || true)"
OPT="$(grep -E '^\?' "$DOTS/packages.txt" | sed 's/^?//' || true)"
# --skip-unavailable solo para no abortar por un opcional; abajo se
# revisa uno por uno y los obligatorios que falten detienen todo.
sudo dnf install -y --skip-unavailable $REQ $OPT
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
  [ -f /etc/yum.repos.d/brave-browser.repo ] \
    || sudo dnf config-manager addrepo --from-repofile="$BRAVE_REPO" \
    || aviso "No se pudo agregar el repo de Brave."
  sudo dnf install -y brave-browser \
    || aviso "No se pudo instalar Brave: SUPER+B no abrira nada hasta que instales un navegador."
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
[ -x "$HOME/.cargo/bin/wallust" ] || cargo install wallust
# cargo lo deja en ~/.cargo/bin, que NO esta en el PATH de la sesion de
# Hyprland; ~/.local/bin si. Los scripts llaman "wallust" a secas.
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.cargo/bin/wallust" "$HOME/.local/bin/wallust"

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
fi

# ---------------------------------------------------------------- 7. iconos y fuente
paso 7 "Iconos (candy-icons) y fuente (JetBrainsMono Nerd Font)"
mkdir -p "$HOME/.local/share/icons"
[ -d "$HOME/.local/share/icons/candy-icons" ] \
  || git clone --depth 1 https://github.com/EliverLara/candy-icons.git "$HOME/.local/share/icons/candy-icons"
if ! fc-list | grep -i "JetBrainsMono Nerd Font" >/dev/null; then
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
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
cp -r "$DOTS/.config/." "$HOME/.config/"
# Restos de intentos anteriores: local.lua ya no se usa, y 90-vm-gl.conf
# forzaba render por software tambien al compositor (via systemd).
rm -f "$HOME/.config/hypr/local.lua" "$HOME/.config/environment.d/90-vm-gl.conf"
cp -rn "$DOTS/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
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
  info "Autologin de GDM desactivado (para poder elegir Hyprland)."
fi

# ---------------------------------------------------------------- 10. tema
paso 10 "Tema oscuro y colores del wallpaper"
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
[ -z "$FALTA_OPT" ] || echo "   Opcionales que no se instalaron:$FALTA_OPT"
echo "=================================================="
