# The Mimic: visual design

## Core idea

The Mimic is Aster's escaped Resonant: a nearly blind underground predator whose throat and chest have evolved into a biological resonator. The station trained it with staff recordings as a living cave surveyor, so it reproduces voices, announcements, and pleas it has heard. The anatomy makes the power legible: when it imitates a voice or sends an echo pulse, the rings in its throat flex and deepen.

## Silhouette

- Narrow head, shoulders, and pelvis.
- Reverse-jointed legs for an animal gait.
- Long forearms that hang below the knees.
- Three fingers and toes with small dark claws.
- Small recessed amber-red sensory pits, visible only when light catches them; they do not provide useful long-range sight.
- A stack of throat rings between chin and collarbone: this is the creature’s visual signature.

The intent is an unsettling shape at a distance without making it a standard zombie, demon, or over-muscled humanoid.

## In-game behaviour expressed through the model

| State | Model cue |
| --- | --- |
| Dormant | Hidden entirely. |
| Stalk | Slow body sway; throat barely moves. |
| Investigate | Head points at the noise; throat contracts and expands. |
| Chase | Faster throat pulse and forward, animal-like posture. |
| Lured | Throat pulse follows the speaker until it vanishes into the shaft. |

## Production model

`assets/models/characters/the_mimic.glb` is a Blender-authored prototype model. It has separate geometry for the body, limbs, claws, eyes, spine nodes, and `ResonatorThroat` group, plus an articulated transform hierarchy: `Hips`, `Spine`, `HeadPivot`, paired upper/fore arms, and paired upper/lower/ankle legs. Godot drives that hierarchy at runtime for listening, stalking, investigation, sprinting, and throat-pulse motion.

The art reference is [mimic-turnaround-v1.png](../concepts/mimic-turnaround-v1.png). It is a design reference, not a direct texture source.

## Next creature pass

1. Retopologise the prototype into a single skinned mesh.
2. Replace the transform rig with an armature and authored idle, stalk, investigate, sprint, strike, and retreat clips.
3. Create wet-skin, scar, eye, and throat-emissive material maps.
4. Make sound-reactive throat shape keys for voice mimicry.
