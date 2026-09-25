#!/bin/bash
STATEFILE=/tmp/numlock_state
if [ -f "$STATEFILE" ] && [ "$(cat "$STATEFILE")" = "on" ]; then
  echo "off" > "$STATEFILE"
  notify-send -t 1500 --app-name "Teclado" -h string:x-canonical-private-synchronous:numlock "󰎠 Num Lock" "Desactivado"
else
  echo "on" > "$STATEFILE"
  notify-send -t 1500 --app-name "Teclado" -h string:x-canonical-private-synchronous:numlock "󰎠 Num Lock" "Activado"
fi
