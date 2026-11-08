#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-/root/toolchains/godot/Godot_v4.7.2-stable_linux.arm64}"
if [[ -n "${PROOT_L2S_DIR:-}" ]]; then
  mkdir -p "$project_dir/.godot"
  shim="$project_dir/.godot/proot_scandir_fix.so"
  if [[ ! -f "$shim" || "$project_dir/tools/proot_scandir_fix.c" -nt "$shim" ]]; then
    cc -shared -fPIC "$project_dir/tools/proot_scandir_fix.c" -o "$shim" -ldl
  fi
  export LD_PRELOAD="$shim${LD_PRELOAD:+:$LD_PRELOAD}"
fi
exec "$godot_bin" --path "$project_dir" "$@"
