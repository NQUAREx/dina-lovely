#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export GALLIUM_DRIVER=softpipe LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=1
exec xvfb-run -a ./tools/godot.sh --audio-driver Dummy --rendering-method gl_compatibility --script res://tools/qa/native_capture.gd
