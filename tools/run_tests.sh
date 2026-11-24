#!/usr/bin/env bash
# Unified headless test entry (ROADMAP R0-01).
# Usage: tools/run_tests.sh [--include-monkey] [filter-substring]
# Env:   GODOT=<path to Godot 4.7.2 binary>   TEST_TIMEOUT=<seconds, default 180>
# Exit:  0 all green, 1 any failure / timeout / guard violation.
set -u
cd "$(dirname "$0")/.."

include_monkey=0
filter=""
for arg in "$@"; do
	case "$arg" in
		--include-monkey) include_monkey=1 ;;
		*) filter="$arg" ;;
	esac
done

if [ -z "${GODOT:-}" ]; then
	GODOT="$(find .tools/godot-4.7.2 -maxdepth 5 -type f -perm -u+x \
		\( -name 'Godot' -o -name 'Godot_v4.7.2-stable_*' \) 2>/dev/null | head -1)"
fi
if [ -z "$GODOT" ] || [ ! -x "$GODOT" ]; then
	echo "run_tests: Godot binary not found; set GODOT=..." >&2
	exit 2
fi
timeout_s="${TEST_TIMEOUT:-180}"
log_dir=".tools/test-logs"
mkdir -p "$log_dir"

# Runners that need a GPU-presented window are excluded (see TARGET_ARCHITECTURE §3.8).
is_excluded() {
	case "$1" in
		*capture*) return 0 ;;
		*monkey*) [ "$include_monkey" -eq 0 ] && return 0 ;;
	esac
	return 1
}

run_with_timeout() {
	local log="$1"; shift
	"$@" >"$log" 2>&1 &
	local pid=$!
	local waited=0
	while kill -0 "$pid" 2>/dev/null; do
		if [ "$waited" -ge "$timeout_s" ]; then
			kill -9 "$pid" 2>/dev/null
			wait "$pid" 2>/dev/null
			return 124
		fi
		sleep 1
		waited=$((waited + 1))
	done
	wait "$pid"
}

# A runner whose script extends SceneTree can only run via --script, even if a .tscn wraps it.
targets=()
while IFS= read -r scene; do
	script="${scene%.tscn}.gd"
	[ -f "$script" ] && grep -q '^extends SceneTree' "$script" && continue
	targets+=("scene:$scene")
done < <(find tests -name '*_runner.tscn' | sort)
while IFS= read -r script; do targets+=("script:$script"); done < <(grep -rl --include='*.gd' '^extends SceneTree' tests | sort)

pass=0; fail=0; skipped=0
failures=()
for target in "${targets[@]}"; do
	kind="${target%%:*}"; path="${target#*:}"
	if is_excluded "$path"; then skipped=$((skipped + 1)); continue; fi
	if [ -n "$filter" ] && [[ "$path" != *"$filter"* ]]; then continue; fi
	name="$(echo "$path" | tr '/' '_')"
	log="$log_dir/$name.log"
	if [ "$kind" = "scene" ]; then
		run_with_timeout "$log" "$GODOT" --headless --path . "res://$path"
	else
		run_with_timeout "$log" "$GODOT" --headless --path . --script "res://$path"
	fi
	code=$?
	if [ "$code" -eq 0 ] && ! grep -qE 'SCRIPT ERROR|Parse Error' "$log"; then
		pass=$((pass + 1)); echo "PASS  $path"
	else
		fail=$((fail + 1)); failures+=("$path (exit $code)"); echo "FAIL  $path (exit $code, log $log)"
	fi
done

# Architecture guards (TARGET_ARCHITECTURE §4). Blocking ones fail the run.
guard_fail=0
guard() {
	local mode="$1" label="$2"; shift 2
	local hits
	hits="$("$@" 2>/dev/null || true)"
	if [ -n "$hits" ]; then
		echo "GUARD[$mode] $label:"; echo "$hits" | sed 's/^/    /' | head -20
		[ "$mode" = "block" ] && guard_fail=1
	fi
}
guard block "gameplay/core must stay pure" \
	grep -rnE 'FileAccess|randi\(|randf\(|RandomNumberGenerator|^extends (Node|Control)' src/gameplay src/core --include='*.gd'
guard block "tests must not pin project version" \
	grep -rn 'config/version=' tests --include='*.gd'
guard report "ui reads files directly (blocking from R2-09)" \
	grep -rn 'FileAccess' src/ui --include='*.gd'
guard report "ui asset path literals (blocking from R2-10)" \
	grep -rlc 'res://assets/game/' src/ui --include='*.gd'
guard report "files over size budget" \
	sh -c "find src -name '*.gd' -exec wc -l {} + | awk '\$2!=\"total\" && ((\$2 ~ /src\\/ui\\// && \$1>800) || (\$2 !~ /src\\/ui\\// && \$1>500))'"

echo
echo "run_tests: pass=$pass fail=$fail skipped=$skipped guard_block=$guard_fail"
if [ "$fail" -gt 0 ]; then printf '  failed: %s\n' "${failures[@]}"; fi
[ "$fail" -eq 0 ] && [ "$guard_fail" -eq 0 ]
