"""Build separate RPG events from the second clean shot in the supplied reference.

Source: https://youtu.be/4Vu0Hr9660U
The source excerpts retain their original sound; only peak gain and tail fade change.
Rights remain with the respective recording/game owners; these are not CC0 assets.
"""
from pathlib import Path
from array import array
import hashlib,json,wave
root=Path(__file__).resolve().parents[1]
meta=root/'assets/audio_sources.json'
entries=json.loads(meta.read_text())
for name,source,timestamp in [('rpg_launch','rpg_reference_launch.wav','5.88–7.38'),('rpg_explosion','rpg_reference_impact.wav','8.40–10.50')]:
    with wave.open(str(root/'tools/audio_source'/source)) as w:
        rate=w.getframerate(); samples=array('h',w.readframes(w.getnframes()))
    gain=29000/max(abs(v) for v in samples)
    fade=int(rate*.06)
    samples=array('h',[round(v*gain*min(1,(len(samples)-1-i)/fade)) for i,v in enumerate(samples)])
    target=root/'assets'/f'{name}.wav'
    with wave.open(str(target),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(samples.tobytes())
    entries[f'{name}.wav']={'source':source,'url':'https://youtu.be/4Vu0Hr9660U','excerpt_seconds':timestamp,'license':'Reference recording supplied by user; rights remain with respective owners (not CC0)','processing':'Mono 44.1kHz, peak 29000, 60ms tail fade; original pitch','sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
    print(name,len(samples)/rate,'seconds')
meta.write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')
