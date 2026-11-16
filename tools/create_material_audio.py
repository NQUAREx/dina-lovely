"""Layer recorded CC0 material foley; no oscillators or synthesized chimes."""
from pathlib import Path
import array, math, subprocess, wave, json, hashlib
R=Path(__file__).resolve().parents[1];S=R/'tools/audio_source/materials';A=R/'assets';RATE=44100

def recording(name,filters):
 data=subprocess.check_output(['ffmpeg','-v','error','-i',str(S/name),'-af',filters,'-ac','1','-ar',str(RATE),'-f','f32le','-'])
 a=array.array('f');a.frombytes(data);return a

def mix(length,layers,peak=.89):
 a=[0.0]*round(length*RATE)
 for source,start,gain in layers:
  start=round(start*RATE)
  for i,v in enumerate(source):
   if start+i>=len(a):break
   a[start+i]+=v*gain
 # Gentle soft compression strengthens the body without digital clipping.
 a=[math.tanh(v*1.6) for v in a];scale=peak/max(abs(x) for x in a)
 return [x*scale for x in a]

def save(name,samples):
 path=A/name
 raw=array.array('h',(round(max(-1,min(1,x))*32767) for x in samples))
 if path.suffix=='.wav':
  with wave.open(str(path),'wb') as f:f.setparams((1,2,RATE,0,'NONE','not compressed'));f.writeframes(raw.tobytes())
 else:
  subprocess.run(['ffmpeg','-v','error','-y','-f','s16le','-ar',str(RATE),'-ac','1','-i','-','-c:a','libvorbis','-q:a','6',str(path)],input=raw.tobytes(),check=True)
 rms=math.sqrt(sum(x*x for x in samples)/len(samples))
 print(name,'duration',round(len(samples)/RATE,3),'peak',round(max(abs(x) for x in samples),3),'RMS dB',round(20*math.log10(rms),1))
# Retain only the physical contact transient of the metal recording, discard
# its resonant tail. Concrete scrapes provide the body and falling grit.
contact=recording('metal-medium-original.ogg','atrim=0:0.065,highpass=f=170,lowpass=f=2900,afade=t=out:st=0.018:d=0.047')
stone=recording('concrete-original.wav','highpass=f=85,lowpass=f=3600,afade=t=out:st=0.08:d=0.16')
wood=recording('wood-heavy-original.ogg','highpass=f=65,lowpass=f=4500,acompressor=threshold=0.1:ratio=3:attack=2:release=65')
twigs=recording('twigs-original.wav','highpass=f=280,lowpass=f=6500,afade=t=out:st=0.09:d=0.21')
scrape=recording('rake-original.wav','highpass=f=500,lowpass=f=4200,afade=t=in:d=0.02,afade=t=out:st=0.12:d=0.2')
pick=mix(.36,[(contact,0,.65),(stone,.008,1.35),(stone,.075,.34),(twigs,.025,.12)])
chop=mix(.40,[(wood,0,1.15),(twigs,.008,.8),(wood,.025,.2)])
craft=mix(.98,[(wood,0,.9),(contact,.008,.12),(scrape,.06,.20),(wood,.24,.70),(contact,.245,.23),(scrape,.36,.30),(wood,.53,1),(contact,.535,.35),(twigs,.59,.22),(scrape,.69,.2)])
save('pick_stone.ogg',pick);save('chop_wood.ogg',chop);save('axe.wav',chop);save('craft_bench.wav',craft)
manifest=json.loads((A/'audio_sources.json').read_text())
for name in ['pick_stone','chop_wood','axe','craft_bench']:
 f=A/(name+('.ogg' if name in ['pick_stone','chop_wood'] else '.wav'))
 manifest[name]={'pack':'Layered recorded material foley, see CRAFTING_AUDIO_LICENSE.txt','license':'CC0','source_file':'tools/audio_source/materials','processing':'tools/create_material_audio.py','sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
(A/'audio_sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
