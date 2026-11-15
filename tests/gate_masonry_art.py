"""Entire pillars, not just their brick strips, use projected wall blocks."""
from pathlib import Path
from PIL import Image
A=Path(__file__).resolve().parents[1]/'assets'
w=Image.open(A/'wall_exposed.png').convert('RGBA')
tile=Image.new('RGBA',(32,64));tile.alpha_composite(w.crop((0,0,32,34)),(0,8))
tile.alpha_composite(w.crop((0,34,32,64)).resize((32,18),Image.Resampling.NEAREST),(0,42))
expected=Image.new('RGBA',(48,112))
for y in (38,26,14,2):expected.alpha_composite(tile,(8,y))
for f in A.glob('junction_*.png'):assert Image.open(f).convert('RGBA').tobytes()==expected.tobytes(),f.name
print('PASS full pillars match wall roof, bevels, side faces and perspective pixel-for-pixel')
