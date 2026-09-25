# Hyprland Dotfiles (Fedora)

Configuración completa de un escritorio Hyprland con colores dinámicos.

## Incluye
- **Hyprland** + **Waybar** (módulos flotantes con blur) + **SwayNotificationCenter**
- **eww**: barras de audio en el escritorio + centro de control (dashboard con reloj, clima, reproductor, sliders y notificaciones)
- **wallust**: colores dinámicos según el wallpaper (waybar, rofi, swaync, kitty, cava, wlogout, hyprlock)
- **rofi**, **wlogout**, **hyprlock** (reloj, clima, batería), **kitty**, **cava**
- **MangoHud** (overlay para juegos) y **EasyEffects** (ecualizador con presets)

## Requisitos
- Fedora (probado en Fedora 44)

## Instalación
    git clone <URL-DE-TU-REPO> ~/dotfiles
    cd ~/dotfiles
    ./install.sh

Después cierra sesión y en el gestor de inicio elige **Hyprland**.

## Atajos principales
| Atajo | Acción |
|-------|--------|
| SUPER+Return | Terminal (kitty) |
| SUPER+R | Menú de apps (rofi) |
| SUPER+E | Archivos (thunar) |
| SUPER+B | Navegador |
| SUPER+D | Dashboard / centro de control |
| SUPER+N | Panel de notificaciones |
| SUPER+M | Menú de apagado (wlogout) |
| SUPER+L | Bloquear (hyprlock) |
| SUPER+W | Cambiar wallpaper |
| SUPER+A | Visualizador cava |
| SUPER+CTRL+N | Red (nmtui) |
| SUPER+CTRL+V | Historial de portapapeles |
| Print | Captura de pantalla |

## Notas
- `eww` y `wallust` no están en repos: el instalador los compila/instala.
- Los colores se generan del wallpaper con wallust (cambia fondo con SUPER+W).
- El navegador (brave u otro) se instala aparte.
