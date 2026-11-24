# The Last Signal: one-year production plan

## The goal

Turn the current mechanical prototype into a cohesive 3D horror game with a polished 45–90 minute vertical slice by month 6, then expand it into a 4–6 hour release-quality game by month 12.

The game should use **authored reusable assets**, not one-off programmatic boxes. GDScript remains responsible for layout assembly, interactions, lights, puzzles, AI, saves, and menus. Models and materials should live as importable game assets.

## Asset strategy

### 1. Modular station kit

Build a constrained kit at a single real-world scale: 4 m wall bays, 4 m floor panels, doorway bays, corners, ceiling panels, support beams, cable trays, pipes, railings, and doors. Every room is assembled from this kit, then differentiated through lighting, props, decals, leaks, damage, and sound.

This gives the game real architecture while keeping the amount of modelling manageable. A new room becomes a composition task instead of a new modelling task.

### 2. Prop families

Create a small number of high-value prop families with variants:

- electrical: breaker boxes, generator, consoles, fuse racks, cable bundles
- industrial: pumps, tanks, grates, vents, tool carts, lockers
- story: crew desks, photographs, logs, medical supplies, warning signs
- horror: scratches, wet trails, broken glass, discarded radios, clawed doors

Each family should contain intact, worn, and damaged forms. Reuse with varied rotation, tint, and decals.

### 3. Characters and creatures

Model the Mimic as a rigged creature with an idle, stalking walk, sprint, turn, investigate, strike, and retreat. Nix needs only idle, look, scurry, and vent-entry animations. Keep both deliberately stylized so they match the station instead of looking like unrelated realistic assets.

### 4. Materials and textures

Use a compact material library: painted steel, oxidized steel, concrete floor, wet concrete, rubber, frosted glass, and emissive console screens. The generated `station_floor_concrete.png` is the first material in this library. Add authored roughness and normal maps where surface detail matters; use decals for unique narrative marks.

## Production schedule

| Months | Focus | Exit criterion |
| --- | --- | --- |
| 1 | Art direction, scale guide, station floor and wall material tests, menu/save foundation | One room looks intentional and performs well. |
| 2 | Modular station kit: floor, wall, doorway, corner, ceiling, doors, rails, pipes | Build three visually distinct rooms from the same kit. |
| 3 | Prop pass and environmental storytelling | Entry, Operations, and Pump rooms have readable purposes. |
| 4 | Mimic model, rig, animation, Nix model, and encounter staging | The first reveal is frightening without relying on UI text. |
| 5 | Replace prototype route with the art kit; add meaningful branches and shortcuts | A complete 20–30 minute playable slice. |
| 6 | Audio, lighting, objective readability, performance, playtests | Polished vertical slice ready for outside feedback. |
| 7–8 | Build the lower levels, puzzles, and optional Nix interactions | Full game route is playable end to end. |
| 9 | Add narrative logs, final encounters, ending sequence, and accessibility options | Content complete. |
| 10 | UI, save/load edge cases, controller support, settings, bug fixing | Feature complete. |
| 11 | Optimisation, lighting polish, sound mix, repeated playtests | Release candidate. |
| 12 | Trailer captures, store assets, final QA, Windows export | Shippable build. |

## Immediate next assets

1. Operations wall bay with a working console recess and conduit channels.
2. Freight elevator door and control column.
3. Pump assembly with moving fan, dripping pipe, and a real power-cell socket.
4. Maintenance locker, tool trolley, and vent for Nix.
5. Mimic silhouette model and animation test.

## First kit completed

The current build includes the first reusable environmental set:

- `station_wall_bay.glb`: framed panel wall with seams, conduit, and service plate.
- `security_grill_gate.glb`: barred industrial gate with warning plates and status lamps.
- `ceiling_worklight_bay.glb`: ceiling panel with recessed work light and cable tray.
- `industrial_control_console.glb`: screen, keys, indicators, cabinet, and conduit.
- `pump_assembly.glb`: motor, pipework, valve wheel, skid, and status light.
- `locker_bank.glb`: three damaged service lockers with vents and handles.
- `service_pipe_rack.glb`: wall-side service pipes, brackets, and tray.

This replaces the primary visible station shell and creates a consistent scale and material language for later rooms.

## Technical structure

- `assets/models/`: imported GLB files for the modular kit, props, Mimic, and Nix.
- `assets/materials/`: Godot material resources and PBR texture sets.
- `assets/textures/`: source texture maps such as the station floor.
- `scenes/modules/`: reusable wall, door, elevator, and room scenes.
- `scripts/`: logic only. Scripts select variants, connect interactions, and place modules; they should not be the source of final visible geometry.

This keeps the current fast iteration speed while letting the visual quality grow into a real place.
