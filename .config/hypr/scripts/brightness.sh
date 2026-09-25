#!/bin/bash
WOBSOCK=/tmp/wob.sock
case $1 in
  up) brightnessctl -e4 -n2 set 5%+ ;;
  down) brightnessctl -e4 -n2 set 5%- ;;
esac
cur=$(brightnessctl g)
max=$(brightnessctl m)
echo "$((cur * 100 / max)) brightness" > "$WOBSOCK"
