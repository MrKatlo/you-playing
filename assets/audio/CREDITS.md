# Audio credits

The files in this folder are included as part of *The Last Signal*, not redistributed as a standalone sound pack.

| Files | Source | License |
| --- | --- | --- |
| `footstep_00.ogg`, `footstep_02.ogg`, `footstep_06.ogg`, `footstep_09.ogg` | [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) | CC0 1.0 |
| `door_open.ogg`, `machine_start.ogg`, `elevator.ogg`, `metal_hit.ogg`, `mimic_reveal.ogg` | [Kenney Sci-Fi Sounds](https://kenney.nl/assets/sci-fi-sounds) | CC0 1.0 |
| `furnace_door_creak.ogg` | [Creaky Door Hinge Spooky](https://opengameart.org/content/creaky-door-hinge-spooky) | CC0 1.0 |
| `furnace_door_close.ogg` | [Iron Door](https://opengameart.org/content/iron-door) | CC0 1.0 |
| `machete_swing.wav` | Synthesised in-project (filtered noise arc) | Original work |
| `flesh_impact.wav`, `player_hurt.wav`, `slime_coil.wav`, `slime_slam.wav` | Synthesised in-project by `tools/create_creature_audio.py` | Original work |
| `net_swish.wav`, `cricket_chirp.wav` | Synthesised in-project by `tools/create_net_audio.py` | Original work |

The five Sci-Fi source clips were converted from M4A to OGG for Godot import. Kenney's pack pages list these assets under Creative Commons CC0; attribution is not required.

The four creature-combat clips are generated from filtered noise and tuned sine bodies, with no sampled or downloaded material: `flesh_impact.wav` is a blade entering a gel body, `player_hurt.wav` a short pained exhale, `slime_coil.wav` the wet wind-up before a pounce, and `slime_slam.wav` a gel body landing on concrete. Re-running `python tools/create_creature_audio.py` regenerates them identically.

The net-catch pair is generated the same way: `net_swish.wav` is gauze pushed through
the air behind the hoop (band-passed noise with a fast cloth flutter and a low handle
swing), and `cricket_chirp.wav` is a trilled 4.2 kHz insect chirp that repeats four times,
each one quieter as the insect settles. `python tools/create_net_audio.py` regenerates both identically.

`furnace_door_creak.ogg` is a 1.5 s excerpt of the OpenGameArt hinge recording, trimmed and faded for the furnace door. `furnace_door_close.ogg` is the OpenGameArt iron-door clip used unedited for the closing clank.
