#!/bin/bash
WOBSOCK=/tmp/wob.sock
case $1 in
  up) wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac
muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o MUTED)
if [ "$muted" = "MUTED" ]; then
  echo "0 volume" > "$WOBSOCK"
else
  vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2*100}')
  echo "$vol volume" > "$WOBSOCK"
fi
