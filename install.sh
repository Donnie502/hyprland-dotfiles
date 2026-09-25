#!/usr/bin/env bash
# Instalador de dotfiles Hyprland para Fedora
set -e
DOTS="$(cd "$(dirname "$0")" && pwd)"
OLDHOME="/home/donnie502"

echo ">>> [1/8] Instalando paquetes de repos..."
sudo dnf install -y --skip-unavailable $(grep -vE '^\s*#|^\s*$' "$DOTS/packages.txt")
# dbus-monitor (para las notificaciones del dashboard)
sudo dnf install -y dbus-tools 2>/dev/null || sudo dnf install -y dbus-x11 2>/dev/null || true

echo ">>> [2/8] Habilitando tuned (perfiles de energia)..."
sudo systemctl enable --now tuned || true
sudo systemctl enable --now thermald || true
sudo tuned-adm profile balanced || true

echo ">>> [3/8] Instalando wallust (cargo)..."
export PATH="$HOME/.cargo/bin:$PATH"
command -v wallust >/dev/null 2>&1 || cargo install wallust

echo ">>> [4/8] Compilando eww (visualizador y dashboard)..."
if [ ! -x "$HOME/.local/bin/eww" ]; then
  rm -rf /tmp/eww-src
  git clone https://github.com/elkowar/eww /tmp/eww-src
  ( cd /tmp/eww-src && cargo build --release --no-default-features --features wayland )
  mkdir -p "$HOME/.local/bin"
  cp /tmp/eww-src/target/release/eww "$HOME/.local/bin/"
fi

echo ">>> [5/8] Instalando candy-icons y Nerd Font..."
mkdir -p "$HOME/.local/share/icons"
[ -d "$HOME/.local/share/icons/candy-icons" ] || git clone --depth 1 https://github.com/EliverLara/candy-icons.git "$HOME/.local/share/icons/candy-icons"
if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNF"
  curl -L -o /tmp/jbm.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  unzip -o /tmp/jbm.zip -d "$HOME/.local/share/fonts/JetBrainsMonoNF"
  fc-cache -f
fi

echo ">>> [6/8] Copiando configuraciones y wallpapers..."
mkdir -p "$HOME/.config" "$HOME/Pictures/wallpapers"
cp -r "$DOTS/.config/." "$HOME/.config/"
cp -rn "$DOTS/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/eww/scripts/"* 2>/dev/null || true

echo ">>> [7/8] Ajustando rutas ($OLDHOME -> $HOME)..."
grep -rl "$OLDHOME" "$HOME/.config" 2>/dev/null | while read -r f; do
  sed -i "s#$OLDHOME#$HOME#g" "$f"
done

echo ">>> [8/8] Tema oscuro + generar colores del wallpaper..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita' 2>/dev/null || true
FIRST=$(find "$HOME/Pictures/wallpapers" -maxdepth 1 -type f | head -1)
[ -n "$FIRST" ] && "$HOME/.cargo/bin/wallust" run "$FIRST" 2>/dev/null || true

echo ""
echo "=================================================="
echo " Instalacion terminada."
echo " 1) Cierra sesion."
echo " 2) En el gestor de inicio elige 'Hyprland'."
echo " 3) Navegador (brave u otro) instalalo aparte si lo usas."
echo "=================================================="
