"""Cut recorded Freesound garden foley and package it for Godot."""

from dataclasses import dataclass
from hashlib import sha256
from pathlib import Path
from tempfile import TemporaryDirectory
from urllib.request import Request, urlopen
import argparse
import array
import json
import math
import subprocess
import wave


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
RATE = 44100


@dataclass(frozen=True)
class Source:
    creator: str
    slug: str
    title: str
    clip_id: int
    preview_id: str

    @property
    def page(self) -> str:
        return f"https://freesound.org/people/{self.slug}/sounds/{self.clip_id}/"

    @property
    def preview(self) -> str:
        return f"https://cdn.freesound.org/previews/{self.clip_id // 1000}/{self.preview_id}-hq.mp3"


RAKE = Source("Garuda1982", "Garuda1982", "raking leaves field recording", 448966, "448966_2061858")
TRIM = Source("CarikaDarvall", "CarikaDarvall", "Cutting tree", 764469, "764469_15688439")
WATER = Source("Bricklover", "Bricklover", "Watering with a Watering Can", 532890, "532890_8919922")
FRUIT = Source("jopimblett", "jopimblett", "Jo_drop_grapes.wav", 388744, "388744_5460466")
BASKET = Source(
    "Nox_Sound", "Nox_Sound", "Foley_Object_Basket_WithWood_PickUp_Release_Sequence_Stereo",
    846926, "846926_9250976",
)


@dataclass(frozen=True)
class Cut:
    source: Source
    start: float
    duration: float
    highpass: int
    lowpass: int
    fade_in: float
    fade_out: float


CUTS = {
    "garden_rake": Cut(RAKE, 4.47, .65, 145, 6500, .022, .13),
    "garden_trim": Cut(TRIM, 4.26, .97, 220, 8000, .012, .09),
    "garden_water": Cut(WATER, 4.21, 1.51, 135, 7900, .095, .24),
    "garden_harvest": Cut(FRUIT, .061, .76, 105, 6100, .012, .105),
    "garden_deposit": Cut(BASKET, 4.52, .65, 80, 5500, .014, .13),
    "garden_pickup": Cut(BASKET, 5.56, .48, 145, 6200, .015, .09),
}


def build_sample(source: Path, cut: Cut, name: str) -> str:
    filters = (
        f"highpass=f={cut.highpass},lowpass=f={cut.lowpass},"
        f"afade=t=in:d={cut.fade_in},afade=t=out:st={cut.duration-cut.fade_out}:d={cut.fade_out}"
    )
    decoded = subprocess.check_output([
        "ffmpeg", "-v", "error", "-ss", str(cut.start), "-i", str(source),
        "-t", str(cut.duration), "-af", filters, "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-",
    ])
    samples = array.array("f")
    samples.frombytes(decoded)
    peak = max(map(abs, samples))
    rms = math.sqrt(sum(value * value for value in samples) / len(samples))
    gain = min(.86 / peak, .163 / rms)
    pcm = array.array("h", (round(value * gain * 32767) for value in samples))
    path = ASSETS / f"{name}.wav"
    with wave.open(str(path), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(pcm.tobytes())
    return sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--previews", type=Path, help="Use local previews named <preview_id>.mp3")
    args = parser.parse_args()
    sources_path = ASSETS / "audio_sources.json"
    manifest = json.loads(sources_path.read_text())
    with TemporaryDirectory(prefix="love-garden-foley-") as temp:
        for name, cut in CUTS.items():
            source = cut.source
            preview = (args.previews or Path(temp)) / (source.preview_id + ".mp3")
            if not preview.exists():
                if args.previews:
                    raise FileNotFoundError(preview)
                request = Request(source.preview, headers={"User-Agent": "Mozilla/5.0", "Accept": "audio/mpeg,*/*"})
                with urlopen(request, timeout=20) as response:
                    preview.write_bytes(response.read())
            manifest[name] = {
                "source_file": source.title,
                "pack": f"Freesound / {source.creator}",
                "source_url": source.page,
                "license": "CC0",
                "processing": (
                    f"{cut.start:.3f}s to {cut.start + cut.duration:.3f}s; "
                    "mono conversion, filtering, fades and gain"
                ),
                "sha256": build_sample(preview, cut, name),
            }
    sources_path.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
