------------------
---- MONITORS ----
------------------
-- Regla comodin: cualquier monitor que no este listado abajo usa su
-- mejor modo. Va primero para que las reglas especificas la pisen.
-- Sin esto, en otra maquina (o en una VM) Hyprland arranca con la
-- resolucion minima y todo se ve gigante.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1200@165.00",
    position = "auto",
    scale    = 1,
})

-- Ajustes propios de esta maquina (monitores, variables de entorno).
-- Lo genera install.sh; no vive en el repo, asi que no se pisa al
-- actualizar. Va aqui: despues de los monitores y antes del autostart.
pcall(dofile, os.getenv("HOME") .. "/.config/hypr/local.lua")

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "rofi -show drun -config " .. os.getenv("HOME") .. "/.config/rofi/config.rasi"
local browser     = "brave-browser"

-------------------
---- AUTOSTART ----
-------------------

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(89b4faee)", "rgba(cba6f7ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
        },
        blur = {
            enabled = true,
            size    = 5,
            passes  = 2,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },
})

hl.curve("rebote", { type = "spring", mass = 1, stiffness = 170, dampening = 20 })
hl.curve("quick", { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "rebote" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, spring = "rebote", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, spring = "rebote", style = "popin 80%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, spring = "rebote", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "quick" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeOutQuint" })

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout = "us,latam",
        follow_mouse = 1,
        sensitivity = 0.5,

        natural_scroll = false,

        touchpad = {
            natural_scroll = true,
        },
    },
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("kitty --class cava --title cava -e cava"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("/home/donnie502/.config/hypr/scripts/apply-wallpaper.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client --toggle-panel"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("/home/donnie502/.config/hypr/scripts/nmtui-themed.sh"))
hl.bind(mainMod .. " + CTRL + V", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/clipboard.sh"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/monitor-menu.sh"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | tee ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png | wl-copy"))

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Redimensionar ventana activa con teclado
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

-- Sensibilidad específica del mouse inalámbrico
hl.device({
    name = "yichip-wireless-device-mouse",
    sensitivity = 1.0,
})

-- Teclas multimedia (volumen y brillo)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/volume.sh up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/volume.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/volume.sh mute"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/brightness.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/brightness.sh down"), { locked = true, repeating = true })

-- Indicadores de Caps Lock y Num Lock
hl.bind("Caps_Lock", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/capslock.sh"), { locked = true })
hl.bind("Num_Lock", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/numlock.sh"), { locked = true })

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/autostart.sh"); hl.exec_cmd("hypridle"); hl.exec_cmd("wl-paste --watch cliphist store")
end)

-- Gesto de 3 dedos para cambiar de espacio de trabajo
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

----------------------
---- LAYER RULES -----
----------------------
hl.layer_rule({
    name = "swaync-cc-blur",
    match = { namespace = "^swaync-control-center$" },
    blur = true,
    ignore_alpha = 0.2,
})
hl.layer_rule({
    name = "swaync-notif-blur",
    match = { namespace = "^swaync-notification-window$" },
    blur = true,
    ignore_alpha = 0.2,
})
hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "^waybar$" },
    blur = true,
    ignore_alpha = 0.2,
})

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("/home/donnie502/.local/bin/eww open --toggle dashboard"))
hl.layer_rule({ name = "dash-blur", match = { namespace = "^dashboard$" }, blur = true, ignore_alpha = 0.1 })
