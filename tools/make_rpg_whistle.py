"""Rebuild launch, flight loop and impact from the current supplied RPG reference."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().with_name("make_reference_rpg.py")),run_name="__main__")
