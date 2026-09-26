#!/usr/bin/env bash
# Instalador de dotfiles Hyprland para Fedora
set -e
DOTS="$(cd "$(dirname "$0")" && pwd)"
OLDHOME="/home/donnie502"

# ---------------------------------------------------------------
# Fedora retiro hyprland de sus repos oficiales a partir de F43.
# Buscamos un COPR que lo tenga para la version instalada.
# ---------------------------------------------------------------
hypr_ok() {
  rpm -q hyprland >/dev/null 2>&1 && return 0
  dnf list --available hyprland >/dev/null 2>&1
}

echo ">>> [1/9] Configurando repositorio de Hyprland..."
sudo dnf install -y 'dnf-command(copr)' >/dev/null 2>&1 || true
if hypr_ok; then
  echo "    Hyprland ya esta disponible en los repos actuales."
else
  echo "    No esta en los repos base. Probando COPRs conocidos..."
  for REPO in ashbuk/Hyprland-Fedora mpapacc/hyprland solopasha/hyprland; do
    echo "    -> probando $REPO"
    sudo dnf copr enable -y "$REPO" >/dev/null 2>&1 \
      || sudo dnf copr enable -y "$REPO" fedora-rawhide-x86_64 >/dev/null 2>&1 \
      || continue
    if hypr_ok; then
      echo "    OK: usando $REPO"
      break
    fi
    sudo dnf copr disable -y "$REPO" >/dev/null 2>&1 || true
  done
fi
hypr_ok || echo "    !! ADVERTENCIA: no se encontro hyprland en ningun repo."

echo ">>> [2/9] Instalando paquetes de repos..."
sudo dnf install -y --skip-unavailable $(grep -vE '^\s*#|^\s*$' "$DOTS/packages.txt")
# dbus-monitor (para las notificaciones del dashboard)
sudo dnf install -y dbus-tools 2>/dev/null || sudo dnf install -y dbus-x11 2>/dev/null || true

echo ">>> [3/9] Habilitando tuned (perfiles de energia)..."
sudo systemctl enable --now tuned || true
sudo systemctl enable --now thermald || true
sudo tuned-adm profile balanced || true

echo ">>> [4/9] Instalando wallust (cargo)..."
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
command -v wallust >/dev/null 2>&1 || cargo install wallust

# cargo instala en ~/.cargo/bin y eww se copia a ~/.local/bin; ninguno
# de los dos esta en el PATH por defecto en Fedora. Sin esto wallust
# "no existe" para los scripts y los colores nunca se regeneran.
for RC in "$HOME/.bashrc" "$HOME/.profile"; do
  [ -f "$RC" ] || continue
  grep -q '.cargo/bin' "$RC" || \
    echo 'export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"' >> "$RC"
done

echo ">>> [5/9] Compilando eww (visualizador y dashboard)..."
if [ ! -x "$HOME/.local/bin/eww" ]; then
  rm -rf /tmp/eww-src
  git clone https://github.com/elkowar/eww /tmp/eww-src
  ( cd /tmp/eww-src && cargo build --release --no-default-features --features wayland )
  mkdir -p "$HOME/.local/bin"
  cp /tmp/eww-src/target/release/eww "$HOME/.local/bin/"
fi

echo ">>> [6/9] Instalando candy-icons y Nerd Font..."
mkdir -p "$HOME/.local/share/icons"
[ -d "$HOME/.local/share/icons/candy-icons" ] || git clone --depth 1 https://github.com/EliverLara/candy-icons.git "$HOME/.local/share/icons/candy-icons"
if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
  curl -L -o /tmp/jbm.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -o /tmp/jbm.zip -d "$HOME/.local/share/fonts/JetBrainsMonoNF"
  fc-cache -f
fi

echo ">>> [7/9] Copiando configuraciones y wallpapers..."
mkdir -p "$HOME/.config" "$HOME/Pictures/wallpapers"
cp -r "$DOTS/.config/." "$HOME/.config/"
cp -rn "$DOTS/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/eww/scripts/"* 2>/dev/null || true

echo ">>> [8/9] Ajustando rutas ($OLDHOME -> $HOME)..."
grep -rl "$OLDHOME" "$HOME/.config" 2>/dev/null | while read -r f; do
  sed -i "s#$OLDHOME#$HOME#g" "$f"
done

echo ">>> [9/9] Tema oscuro + generar colores del wallpaper..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true
FIRST=$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f | head -1)
[ -n "$FIRST" ] && "$HOME/.cargo/bin/wallust" run "$FIRST" 2>/dev/null || true

# Sesion para el gestor de inicio (GDM/SDDM) si el paquete no la creo
if command -v Hyprland >/dev/null 2>&1 && [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
  echo ">>> Creando entrada de sesion para el gestor de inicio..."
  sudo mkdir -p /usr/share/wayland-sessions
  printf '%s\n' \
    '[Desktop Entry]' \
    'Name=Hyprland' \
    'Comment=An intelligent dynamic tiling Wayland compositor' \
    'Exec=Hyprland' \
    'Type=Application' \
    | sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null
fi

# Si estamos en una maquina virtual, instalar los drivers de invitado
# (arregla la resolucion/zoom y el portapapeles compartido)
LOCAL_LUA="$HOME/.config/hypr/local.lua"
mkdir -p "$HOME/.config/hypr"
: > "$LOCAL_LUA"
echo '-- Generado por install.sh: ajustes de ESTA maquina.' >> "$LOCAL_LUA"
echo '-- Se regenera en cada instalacion; no lo edites a mano.' >> "$LOCAL_LUA"

VIRT="$(systemd-detect-virt 2>/dev/null || echo none)"
case "$VIRT" in
  vmware)
    echo ">>> Maquina virtual VMware detectada: instalando open-vm-tools..."
    sudo dnf install -y --skip-unavailable open-vm-tools open-vm-tools-desktop || true
    ;;
  kvm|qemu)
    echo ">>> Maquina virtual QEMU/KVM detectada: instalando spice-vdagent..."
    sudo dnf install -y --skip-unavailable spice-vdagent qemu-guest-agent || true
    ;;
  oracle)
    echo ">>> VirtualBox detectado: instalando virtualbox-guest-additions..."
    sudo dnf install -y --skip-unavailable virtualbox-guest-additions || true
    ;;
esac

# En una VM el driver 3D del hipervisor (SVGA3D/virgl) rompe a los
# clientes que usan OpenGL de escritorio: kitty muere al arrancar con
# "invalid arguments for wl_surface.attach" y la tuberia de Wayland se
# corta. Forzando el render por software (llvmpipe) arrancan bien.
if [ "$VIRT" != "none" ]; then
  echo ">>> VM detectada: forzando render por software para los clientes..."
  {
    echo 'hl.env("LIBGL_ALWAYS_SOFTWARE", "1")'
    echo 'hl.env("WLR_RENDERER_ALLOW_SOFTWARE", "1")'
  } >> "$LOCAL_LUA"
fi

# Desactivar autologin de GDM para poder elegir la sesion Hyprland
if [ -f /etc/gdm/custom.conf ] && grep -q '^AutomaticLoginEnable=[Tt]rue' /etc/gdm/custom.conf; then
  echo ">>> Desactivando autologin de GDM (para poder elegir la sesion)..."
  sudo sed -i 's/^AutomaticLoginEnable=[Tt]rue/AutomaticLoginEnable=false/' /etc/gdm/custom.conf
fi

# ---------------------------------------------------------------
# Verificacion final: avisar de lo que falto (antes se saltaba
# en silencio por --skip-unavailable)
# ---------------------------------------------------------------
echo ""
echo "--- Verificacion ---"
MISSING=""
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
for C in Hyprland waybar swaync rofi cava wallust eww hyprlock; do
  command -v "$C" >/dev/null 2>&1 && echo "  ok   $C" || { echo "  FALTA $C"; MISSING="$MISSING $C"; }
done
if [ -f /usr/share/wayland-sessions/hyprland.desktop ]; then
  echo "  ok   sesion Hyprland en el gestor de inicio"
else
  echo "  FALTA sesion Hyprland en el gestor de inicio"
  MISSING="$MISSING sesion-hyprland"
fi

echo ""
echo "=================================================="
if [ -n "$MISSING" ]; then
  echo " Instalacion terminada CON FALTANTES:$MISSING"
  echo " Instalalos a mano antes de cerrar sesion."
else
  echo " Instalacion terminada correctamente."
fi
echo " 1) Cierra sesion."
echo " 2) En el gestor de inicio (engranaje) elige 'Hyprland'."
echo " 3) Navegador (brave u otro) instalalo aparte si lo usas."
echo "=================================================="
