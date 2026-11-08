"""Build an isolated test page; never included in the production Web export."""
import pathlib,shutil,subprocess,os
src=pathlib.Path(__file__).resolve().parents[1];dst=src.parent/'love-browser-qa'
shutil.copytree(src,dst,ignore=shutil.ignore_patterns('.git','.godot','docs','screenshots'),dirs_exist_ok=True)
p=dst/'project.godot';p.write_text(p.read_text().replace('res://main.tscn','res://tests/web_qa.tscn'))
p=dst/'export_presets.cfg';p.write_text(p.read_text().replace('tools/*,tests/*,docs/*','tools/*,docs/*'))
(dst/'docs').mkdir(exist_ok=True)
subprocess.run([str(dst/'tools/godot.sh'),'--headless','--export-debug','Web','docs/index.html'],check=True)
