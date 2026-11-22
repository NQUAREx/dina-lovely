#!/usr/bin/env bash
# Run every headless regression check and print one PASS/FAIL/TIMEOUT line each.
#   tests/run_all.sh            all Godot (.gd) and Python checks
#   tests/run_all.sh beam_pond  only checks whose name contains "beam_pond"
# A failed GDScript assert stops the script before quit(), so Godot would
# otherwise keep running: every check gets a timeout and its own disposable
# user data directory (the real save is never touched).
# Environment: JOBS (parallel checks, default 4), TEST_TIMEOUT (seconds, default 120).
set -uo pipefail
cd "$(dirname "$0")/.."
filter="${1:-}"
jobs="${JOBS:-4}"
limit="${TEST_TIMEOUT:-120}"
logs="$(mktemp -d)"
# Screenshot helpers and browser-only scripts are not regression checks.
skip_gd="capture.gd web_qa.gd"
skip_py="firefox_qa.py touch_qa.py"
list=()
for f in tests/*.gd tests/*.py; do
  name="$(basename "$f")"
  [[ " $skip_gd $skip_py " == *" $name "* ]] && continue
  [[ -n "$filter" && "$name" != *"$filter"* ]] && continue
  list+=("$f")
done
run_one() {
  f="$1"; logs="$2"; limit="$3"; name="$(basename "$f")"
  data="$(mktemp -d)"
  if [[ "$f" == *.py ]]; then
    timeout "$limit" python3 "$f" >"$logs/$name.log" 2>&1
  else
    XDG_DATA_HOME="$data" timeout "$limit" ./tools/godot.sh --headless --script "$f" >"$logs/$name.log" 2>&1
  fi
  code=$?
  rm -rf "$data"
  if [[ $code == 124 ]]; then status=TIMEOUT
  elif [[ $code != 0 ]] || grep -qE 'SCRIPT ERROR|Parse Error|Traceback' "$logs/$name.log"; then status=FAIL
  else status=PASS; fi
  detail="$(grep -m1 -E -A2 'SCRIPT ERROR|Parse Error|AssertionError|Error:' "$logs/$name.log" | grep -m1 -oE '(res://tests/[^ )]+|line [0-9]+|[A-Za-z]*Error.*)' || true)"
  printf '%-8s %-40s %s\n' "$status" "$name" "$detail"
}
export -f run_one
printf '%s\n' "${list[@]}" | xargs -P "$jobs" -I{} bash -c 'run_one "$@"' _ {} "$logs" "$limit" | sort -k2
echo "Logs: $logs"
