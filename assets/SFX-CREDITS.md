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

Current bush rustle: Moving Leaves Stereo by Augmentality (Brandon Morris), CC0. https://opengameart.org/content/random-sounds-samples — excerpt, normalized and faded.

Eating: StarNinjas, 7 Eating Crunches, CC0, https://opengameart.org/content/7-eating-crunches (normalized). Rake: mix of existing licensed Moving Leaves and Tinysized SFX scrape recordings. Reload: Tinysized SFX metal mechanism recording.

Short effect recordings (eating, sword swings, hit and reload) have had leading silence trimmed. Original recording sources and licenses remain listed above; current checksums are in audio_sources.json.
