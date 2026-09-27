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
Desde GNOME, como tu usuario (sin `sudo`):

    sudo dnf install -y git
    git clone https://github.com/Donnie502/hyprland-dotfiles.git ~/dotfiles
    ~/dotfiles/install.sh

Pide la contraseña una vez y hace todo solo. Al terminar reinicia y en la
pantalla de inicio (engrane abajo a la derecha) elige **Hyprland**.

- Todo lo que imprime queda en `~/dotfiles-install.log`.
- Tu config anterior se respalda en `~/.config-respaldo-<fecha>`.
- Si falta algo obligatorio, se detiene y dice qué; los opcionales solo se avisan.
- Se puede volver a correr sin romper nada.

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
- Hyprland ya no está en los repos de Fedora (desde F43): se instala desde el
  COPR `ashbuk/Hyprland-Fedora`. La config es Lua y necesita Hyprland 0.55 o
  mayor; si ya tienes uno así instalado, el instalador no lo toca.
- `eww` y `wallust` no están en repos: el instalador los compila/instala.
- En una máquina virtual instala las herramientas de invitado y activa render
  por software para las apps (el 3D de VMware rompe kitty y las apps GTK4).
  Copiar y pegar entre la VM y el anfitrión no funciona dentro de Hyprland
  (limitación de VMware); en GNOME sí.
- Los colores se generan del wallpaper con wallust (cambia fondo con SUPER+W).
- El navegador (brave u otro) se instala aparte.
