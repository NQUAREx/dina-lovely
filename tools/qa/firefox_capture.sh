#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export GALLIUM_DRIVER=softpipe LIBGL_ALWAYS_SOFTWARE=1 LP_NUM_THREADS=1 MOZ_DISABLE_CONTENT_SANDBOX=1 MOZ_DISABLE_RDD_SANDBOX=1
export TEST_URL="${TEST_URL:-https://nquarex.github.io/dina-lovely/}"
exec xvfb-run -a "${QA_PYTHON:-/root/.local/share/love-bloom-qa/venv/bin/python}" tools/qa/firefox_capture.py
