"""Convert a downloaded CC0 rocket-engine recording into a long continuous flight loop.

Source: theMinesAreShakin, https://opengameart.org/content/rocket-engine
No generated tones, amplitude pulsing or repeated short whistle fragments.
"""
from pathlib import Path
from array import array
import subprocess,tempfile,wave,math,hashlib,json
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as tmp:
 out=Path(tmp)/'engine.wav'
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(root/'tools/audio_source/rocket_engine.001.wav'),'-af','highpass=f=130,lowpass=f=8500','-ac','1','-ar','44100','-c:a','pcm_s16le',str(out)],check=True)
 with wave.open(str(out)) as w:pcm=array('h',w.readframes(w.getnframes()))
 # Use the full sustained recording; join only its ends over 220ms.
 width=int(.22*44100)
 mixed=[pcm[-width+i]*math.cos(i/width*math.pi/2)+pcm[i]*math.sin(i/width*math.pi/2) for i in range(width)]+list(pcm[width:-width])
 gain=27000/max(abs(v) for v in mixed);samples=array('h',[round(v*gain) for v in mixed])
 target=root/'assets/rpg_flight.wav'
 with wave.open(str(target),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(44100);w.writeframes(samples.tobytes())
 meta=root/'assets/audio_sources.json';entries=json.loads(meta.read_text());entries['rpg_flight.wav']={'source':'rocket_engine.001.wav, theMinesAreShakin','url':'https://opengameart.org/content/rocket-engine','license':'CC0','processing':'Full recording, mono 44.1kHz, 130Hz high-pass/8.5kHz low-pass, 220ms equal-power seam, peak 27000','sha256':hashlib.sha256(target.read_bytes()).hexdigest()};meta.write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')
 print('Flight loop:',round(len(samples)/44100,3),'s; peak',max(abs(v) for v in samples),'seam',abs(samples[-1]-samples[0]))

# Rebuild the separate reference launch and impact recordings.
import runpy
runpy.run_path(str(root/'tools/make_reference_rpg.py'), run_name='__main__')
