"""Make a seamless mono leaf recording. Requires ffmpeg; no synthesized audio."""
from array import array
import hashlib
import json
import math
from pathlib import Path
import subprocess
import tempfile
import wave

root = Path(__file__).resolve().parents[1]
source = root / 'tools/audio_source/moving_leaves.ogg'
with tempfile.TemporaryDirectory() as directory:
    decoded = Path(directory) / 'leaves.wav'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(source), '-ac', '1', '-ar', '44100', '-af', 'highpass=f=90,lowpass=f=11000', '-c:a', 'pcm_s16le', str(decoded)], check=True)
    with wave.open(str(decoded)) as audio:
        rate = audio.getframerate()
        samples = array('h', audio.readframes(audio.getnframes()))
# Discard the recording's fades, then overlap tail/head with an equal-power crossfade.
samples = samples[int(rate * .06):-int(rate * .04)]
width = int(rate * .18)
joined = [samples[-width + i] * math.cos(i / (width - 1) * math.pi / 2) + samples[i] * math.sin(i / (width - 1) * math.pi / 2) for i in range(width)]
joined.extend(samples[width:-width])
mean = sum(joined) / len(joined)
peak = max(abs(value - mean) for value in joined)
pcm = array('h', (round((value - mean) / peak * 24000) for value in joined))
target = root / 'assets/rustle.wav'
with wave.open(str(target), 'wb') as audio:
    audio.setparams((1, 2, rate, len(pcm), 'NONE', 'not compressed'))
    audio.writeframes(pcm.tobytes())
metadata = root / 'assets/audio_sources.json'
records = json.loads(metadata.read_text())
records['rustle'] = {'source_file': 'Moving Leaves Stereo / tools/audio_source/moving_leaves.ogg', 'pack': 'Augmentality / Brandon Morris', 'license': 'CC0', 'processing': 'Mono, filtered, 180ms equal-power cyclic crossfade; runtime gain envelope', 'sha256': hashlib.sha256(target.read_bytes()).hexdigest()}
metadata.write_text(json.dumps(records, indent=2, ensure_ascii=False) + '\n')
print(f'Loop: {len(pcm)/rate:.3f}s; seam step: {abs(pcm[-1]-pcm[0])}; peak: {max(abs(value) for value in pcm)}')
