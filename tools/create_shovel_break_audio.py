"""Original game-like tool break: woody snap, brittle chips and falling metal.
No samples from Minecraft are used.
"""
from pathlib import Path
import math, random, struct, wave
rate=44100
rng=random.Random(92371)
samples=[0.0]*int(rate*.48)
for start,length,level,frequency in [(0,.085,.85,185),(.018,.045,.58,530),(.043,.065,.48,920),(.097,.07,.34,670),(.163,.075,.23,430),(.248,.085,.14,280)]:
    low=0.0
    for n in range(int(length*rate)):
        t=n/rate;white=rng.uniform(-1,1);low=low*.6+white*.4
        env=math.exp(-t/(length*.22))*min(1,t/.0008)
        snap=(white-low)*.55+low*.75
        ring=math.sin(2*math.pi*frequency*t)*.20+math.sin(2*math.pi*frequency*1.43*t)*.08
        i=int(start*rate)+n
        if i<len(samples):samples[i]+=level*env*(snap+ring)
peak=max(abs(v) for v in samples)
path=Path(__file__).resolve().parents[1]/'assets/shovel_break.wav'
with wave.open(str(path),'wb') as f:
    f.setparams((1,2,rate,0,'NONE','not compressed'))
    f.writeframes(b''.join(struct.pack('<h',round(v/peak*.86*32767)) for v in samples))
print(path)
