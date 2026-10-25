#!/bin/bash
# usage: tests/run.sh <strategy> <max_sim_seconds>
G=${GODOT:-/home/claude/godot_bin/Godot_v4.2.2-stable_linux.x86_64}
timeout 900 $G --headless --fixed-fps 60 --path "$(dirname "$0")/.." -s tests/bot.gd -- "$1" "$2" 2>&1 | grep -v "^WARNING\|     at:\|Resources still\|^Godot Engine" | cut -c1-160
