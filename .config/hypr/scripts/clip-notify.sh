#!/bin/bash
types=$(wl-paste --list-types 2>/dev/null)
if echo "$types" | grep -q "image/"; then
    notify-send -t 1500 -a "Portapapeles" -h string:x-canonical-private-synchronous:clipboard "󰅍 Copiado" "Imagen copiada"
else
    content=$(wl-paste --no-newline 2>/dev/null | head -c 80)
    [ -z "$content" ] && exit 0
    notify-send -t 1500 -a "Portapapeles" -h string:x-canonical-private-synchronous:clipboard "󰅍 Copiado" "$content"
fi
