#!/usr/bin/env bash

waybar -c ~/.config/waybar/config.jsonc -s ~/.config/waybar/style.css >/dev/null 2>&1 &
swaybg -i ~/.config/mango/backgrounds/ito_town.png 2>&1 &
