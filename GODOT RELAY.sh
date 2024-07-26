#!/bin/sh
echo -ne '\033c\033]0;GODOT RELAY\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/GODOT RELAY.x86_64" "$@"
