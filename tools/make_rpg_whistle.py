"""Mix two licensed recordings into a smooth whistle-led flight loop; no synthesis."""
from pathlib import Path
from array import array
import subprocess,tempfile,wave,math,hashlib,json
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as tmp:
 samples=[]
 for name,filters in [('rpg_whistle.wav','highpass=f=700,lowpass=f=6500,equalizer=f=2200:t=q:w=1:g=4'),('rpg_thruster.ogg','highpass=f=200,lowpass=f=1600')]:
  out=Path(tmp)/(name+'.wav')
  subprocess.run(['ffmpeg','-v','error','-y','-i',str(root/'tools/audio_source'/name),'-af',filters,'-ac','1','-ar','44100','-c:a','pcm_s16le',str(out)],check=True)
  with wave.open(str(out)) as w:pcm=array('h',w.readframes(w.getnframes()))
  peak=max(abs(v) for v in pcm) or 1;samples.append([v/peak for v in pcm])
 rate=44100;begin=int(.035*rate);length=int(.40*rate)
 mix=[.86*samples[0][begin+i]+.18*samples[1][int(.3*rate)+i] for i in range(length)]
 width=int(.08*rate)
 loop=[mix[-width+i]*math.cos(i/width*math.pi/2)+mix[i]*math.sin(i/width*math.pi/2) for i in range(width)]+mix[width:-width]
 gain=30000/max(abs(v) for v in loop);pcm=array('h',[round(v*gain) for v in loop])
 target=root/'assets/rpg_flight.wav'
 with wave.open(str(target),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(pcm.tobytes())
 meta=root/'assets/audio_sources.json';entries=json.loads(meta.read_text());entries['rpg_flight.wav']={'source':'Tinysized SFX tin-whistle-whoosh-02.wav + Kenney thrusterFire_004.ogg','license':'CC0','processing':'Recorded whistle dominant, band filtering, 80ms cyclic equal-power crossfade, peak 30000','sha256':hashlib.sha256(target.read_bytes()).hexdigest()};meta.write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')
 print('Flight loop:',round(len(pcm)/rate,3),'s; peak',max(abs(v) for v in pcm),'seam',abs(pcm[-1]-pcm[0]))
