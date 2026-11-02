#!/usr/bin/env bash
# Runs the headless project load plus every tests/*_smoke.gd and tests/*_check.gd.
# Visual review/preview scripts need a GPU and are excluded.
# Usage: tools/run_checks.sh [name-filter]   (GODOT env var overrides the executable)
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/c/Users/Nauda/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
FILTER="${1:-}"
failed=()
if [ ! -d .godot ]; then
	"$GODOT" --headless --path . --import >/dev/null 2>&1
fi
if ! "$GODOT" --headless --path . --quit >/dev/null 2>&1; then
	echo "FAIL project load"; exit 1
fi
for f in tests/*_smoke.gd tests/*_check.gd; do
	name="$(basename "$f" .gd)"
	[ -n "$FILTER" ] && [[ "$name" != *"$FILTER"* ]] && continue
	log="$(timeout 300 "$GODOT" --headless --fixed-fps 60 --path . --script "res://$f" 2>&1)"
	code=$?
	if [ $code -ne 0 ] || grep -q "SCRIPT ERROR\|Parse Error" <<<"$log"; then
		echo "FAIL $name (exit $code)"
		grep -m5 "ERROR\|FAIL\|assert" <<<"$log" | sed 's/^/    /'
		failed+=("$name")
	else
		echo "ok   $name"
	fi
done
echo "---- ${#failed[@]} failed"
[ ${#failed[@]} -eq 0 ]
