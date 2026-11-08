#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h}"
GODOT_BIN="$PROJECT_ROOT/.tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot runtime was not found:"
  echo "  $GODOT_BIN"
  echo ""
  echo "Install Godot 4.7.2 into .tools/godot-4.7.2/Godot.app first."
  exit 1
fi

exec "$GODOT_BIN" --path "$PROJECT_ROOT" "$@"
