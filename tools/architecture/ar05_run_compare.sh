#!/usr/bin/env bash
# AR-05: capture diary desk under three rendering methods. Needs a display.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
GODOT="${GODOT:-$ROOT/.tools/godot-4.7.2/Godot.app/Contents/MacOS/Godot}"
SCENE="res://tools/architecture/ar05_renderer_compare_runner.tscn"
OUT=".tools/ui-captures/ar05_renderer"
mkdir -p "$OUT"

for method in gl_compatibility mobile forward_plus; do
  echo "=== AR-05 capturing method=$method ==="
  "$GODOT" --path "$ROOT" --rendering-method "$method" "$SCENE" \
    >"$OUT/${method}_stdout.log" 2>&1 || {
      echo "FAILED method=$method (see $OUT/${method}_stdout.log)" >&2
      exit 1
    }
done

echo "AR05_ALL_OK out=$OUT"
ls -la "$OUT"
