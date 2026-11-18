# Sound assets and attribution

All in-game audio uses downloaded sound libraries. No procedurally generated oscillator/noise clips remain.

- **Kenney Vleugels / Kenney.nl**: RPG Audio, Impact Sounds, Sci-Fi Sounds. CC0. Sources: https://kenney.nl/assets/rpg-audio , https://kenney.nl/assets/impact-sounds , https://kenney.nl/assets/sci-fi-sounds . Downloaded via https://github.com/GeorgeQLe/assets-sfx-combat ; original pack license files are in `licenses/`.
- **Jan Schupke / Vehicle**, Tinysized SFX Library. CC0. Source: https://opengameart.org/content/fantasy-sound-effects-tinysized-sfx . Water pouring, filling, sword whooshes/clashes. Original readme is in `licenses/tinysized-CC0.txt`.
- **Vincent Sevedge (Tabasco), copyright 2009**, Gunshot Sounds. Source: https://opengameart.org/content/gunshot-sounds . Rifle clip uses an excerpt from `sounds/sks.wav`. The webpage labels the pack CC0, but the archive explicitly says **Creative Commons Attribution 3.0 Unported**, so we follow the archive and credit the author. License: https://creativecommons.org/licenses/by/3.0/ . Changes: excerpt, fade, loudness normalization and mono conversion. Original license is in `licenses/gunshots-CC-BY-3.0.txt`.

`audio_sources.json` maps game events to original filenames and records hashes of the shipped converted files. Audio is resampled to mono 44.1kHz PCM for Godot web sample playback. Gunfire is a recorded rifle sample, not a claim that an actual AK-47 was recorded for this project. Original downloaded packs are not redistributed in full.

- **isaiah658**, Ambient Bird Sounds, CC0: https://opengameart.org/content/ambient-bird-sounds — 10-second excerpt, fades, mono conversion.
- **syncopika**, cricket sounds, CC0: https://opengameart.org/content/cricket-sounds — 10-second excerpt, fades, mono conversion.
- Hedge rustle reuses the licensed Kenney grass footstep variation (not synthesized).

Rustle: qubodup, 20 Rustles of dry leaves, CC0. https://opengameart.org/content/20-rustles-dry-leaves — trimmed and normalized.

Current bush rustle: Moving Leaves Stereo by Augmentality (Brandon Morris), CC0. https://opengameart.org/content/random-sounds-samples — full recording processed to mono, filtered, normalized and joined with a 180 ms equal-power cyclic crossfade. `tools/make_rustle_loop.py` reproduces the seamless recording from the included source. Runtime uses one looping voice with smooth gain attack/release, driven by foliage contact and movement; it never periodically restarts the clip.

Eating: StarNinjas, 7 Eating Crunches, CC0, https://opengameart.org/content/7-eating-crunches (normalized). Rake: mix of existing licensed Moving Leaves and Tinysized SFX scrape recordings. Reload: Tinysized SFX metal mechanism recording.

Short effect recordings (eating, sword swings, hit and reload) have had leading silence trimmed. Original recording sources and licenses remain listed above; current checksums are in audio_sources.json.

RPG launch: short mix of Kenney explosionCrunch_004 and a 0.13 s thruster transient, CC0. RPG impact: Kenney explosionCrunch_002, CC0. RPG insertion: short excerpt of the credited Tinysized SFX metal mechanism recording. Flight loop: Kenney thrusterFire_003 (Sci-Fi Sounds, CC0), trimmed to 0.43 s and faded, played only while a rocket is airborne with distance attenuation.

Gate opening: Kenney RPG Audio `creak1.ogg`, CC0, normalized and faded; shipped as `gate_open.wav`.

`gate_unlock.wav`: Kenney RPG Audio, `metalLatch.ogg`, CC0.

Optional tools: `axe.wav` (wood-twigs-break-02.wav), `shears.wav` (scissors-close-01.wav) from the existing CC0 fantasy SFX pack; `drill_loop.wav` from Kenney Sci-Fi Sounds (engineCircular_004.ogg), CC0; loop seam crossfaded over 90 ms for continuous playback.

Gate update: Kenney RPG Audio creak1 + creak3, slowed recorded layers. RPG launch/flight: Kenney Sci-Fi Sounds explosionCrunch_004 + thrusterFire_002 / thrusterFire_004. Pistol: existing recorded rifle sample, raised pitch. All CC0; no synthesized tones.

Whistle-led RPG flight loop: recorded `tin-whistle-whoosh-02.wav` by Jan Schupke / Vehicle (Tinysized SFX, CC0), mixed with Kenney `thrusterFire_004.ogg` (CC0). Band filtering, normalized recorded layers and an 80 ms cyclic crossfade; no synthesized oscillator. Reproduce with `tools/make_rpg_whistle.py`. Runtime flight gain increased by 6 dB with distance attenuation retained.

Current RPG audio (balance 5): launch uses **qubodup**, Rocket launch, CC0, https://opengameart.org/content/rocket-launch (`launch.wav` from launch.7z; trimmed leading silence, 0.8s excerpt, mono conversion and tail fade). Flight uses **theMinesAreShakin**, Rocket Engine, CC0, https://opengameart.org/content/rocket-engine (`rocket_engine.001.wav`; full sustained recording, 130Hz–8.5kHz filter, mono conversion and 220ms cyclic crossfade). The flight loop is 5.87 seconds rather than a short repeated whistle. It plays continuously while any rocket is airborne; additional launches do not restart it. Source recordings are included in tools/audio_source/.

### Current RPG launch and explosion reference

`rpg_launch.wav` and `rpg_explosion.wav` now use the second clean shot from the user-supplied reference [RPG - 3d sound](https://youtu.be/4Vu0Hr9660U): 5.88–7.38 s and 8.40–10.50 s. Original pitch, mono 44.1 kHz, peak normalization and short tail fade. These excerpts are **not CC0**; rights remain with their respective recording/game owners. Rebuild with `python3 tools/make_reference_rpg.py`. Earlier launch/explosion source entries above describe replaced recordings.

The impact is a separate excerpt with leading silence removed and peak 30000. On collision, the engine and launch tail stop immediately and the impact starts at the actual hit position. The impact is never delayed to the end of the original reference's flight time.

### Current three-phase playback

The second reference shot is now split into three independent assets: launch 5.88–6.18 s, flight 6.18–8.40 s (80 ms loop seam), impact 8.40–10.50 s. `rpg_flight.wav` now also comes from this supplied reference, replacing the earlier CC0 engine recording. Each phase uses original pitch, with peak normalization. Flight stops on actual collision at any distance; the separate impact starts immediately. Rights remain with respective recording/game owners; these reference excerpts are not CC0.

Digging and separate punch/sword swings use CC0 Tinysized SFX recordings (soil-steps-01, tube-plastic-whoosh-01/02). Punch contact uses Kenney impactSoft.
