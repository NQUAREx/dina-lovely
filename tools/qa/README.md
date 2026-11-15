# Ubuntu ARM64 / Termux proot visual QA

Validated 2026-11-15 on this machine. Game files and mechanics are unchanged.

## Native Godot (actual game)

`./tools/qa/native_capture.sh`

Uses Xvfb, `GALLIUM_DRIVER=softpipe`, `LIBGL_ALWAYS_SOFTWARE=1`, `LP_NUM_THREADS=1`, Dummy audio. Avoid llvmpipe: its LLVM JIT crashes with SIGILL in this proot. Saves `/tmp/bloom-native-{menu,intro,world,arena}.png`. This is software rendering, not a phone performance benchmark. Uses the normal user save location; run with an isolated HOME for disposable save state if required.

## Firefox (actual WebGL2 game)

`./tools/qa/firefox_capture.sh`

Firefox `/usr/bin/firefox-esr`, geckodriver `/root/toolchains/geckodriver`, Xvfb, softpipe and proot sandbox overrides. Android UA selects the launch button; an ordinary iPhone UA selects the installation instructions instead. Defaults to the published site; set TEST_URL for a local HTTP build. Saves `/tmp/love-bloom-firefox-menu.png`; verifies engine loading, no recovery overlay or captured JS errors. Override QA_PYTHON to use another Selenium environment.

Dependency setup:

```bash
python3 -m venv /root/.local/share/love-bloom-qa/venv
/root/.local/share/love-bloom-qa/venv/bin/pip install selenium
```

## Playwright Chromium (browser shell)

```bash
npm install --prefix /root/.local/share/love-bloom-qa playwright@1.64.1
node /root/.local/share/love-bloom-qa/node_modules/playwright/cli.js install chromium
node tools/qa/chromium_capture.cjs
```

ARM64 Chrome for Testing 156, bundled by Playwright. Saves `/tmp/bloom-browser-launch.png` and logs computed button opacity/background. Module can be overridden by PLAYWRIGHT_MODULE. Executable is the installed Chromium v1248 under `/root/.cache/ms-playwright`.

Chromium shell capture works. Full WebGL2 via in-process SwiftShader initializes then crashes on this host; TRY_WEBGL=1 is diagnostic only. Use Firefox for the game runtime and native Godot for world/UI captures. Do not equate successful shell screenshots with a tested game runtime.
