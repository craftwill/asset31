# Asset31: architecture and engine decision

## Engine: Godot 4.6 (Forward+, typed GDScript)

Chosen over Bevy/Rust and over a custom engine:

- **The bottleneck is authoring, not rendering.** The brief is fidelity to the reference frames, so the
  work is placing, tuning and comparing. Godot's editor, scene tooling, UI (grid inventory) and audio buses
  save months compared with Bevy (no editor) or a custom engine (nothing exists yet).
- **The retro look is cheap.** Rendering at 960×540, low-poly instanced boxes and emissive windows cost
  very little. Measured: 1.2–1.7 ms/frame at every hero viewpoint on an RTX 3060 (see below).
- **Large worlds are solved in-project.** A floating origin (`WorldOrigin`) plus float64 logical
  coordinates handles the 60 km Mantle; a double-precision engine build isn't needed.
- **Escape hatch:** if a hot path ever outgrows GDScript (e.g. generating whole floors), move that one
  system into a GDExtension (C++ or godot-rust) and keep the editor and pipeline.

## Retro rendering pipeline
| Layer | Where | Toggle |
|---|---|---|
| Low internal resolution (960×540, nearest upscale) | `project.godot` display/stretch | n/a |
| Screen-space vertex snapping (the "shaky" look) | `shaders/retro_common.gdshaderinc` | F6: off / subtle / heavy (320×180 grid) |
| Colour quantisation + 4×4 Bayer dither | `shaders/retro_post.gdshader` | F7 |
| Procedural facades with hierarchical window-light LOD | `shaders/facade.gdshader` | n/a |
| Exponential distance fog (amber haze) | `main.gd` environment | n/a |

Affine (PS1) texture warping is intentionally off: on kilometre-sized faces it warps badly, and the
reference frames don't show it. Vertex snapping only moves X/Y in clip space, so it never causes z-fighting.

## Large-world coordinates
- **Logical space:** float64 metres, used for data, saves and anchors.
- **Render space:** `logical − origin`, where origin is a whole number of 1024 m sectors.
- `WorldOrigin` (autoload) rebases when the player is more than 1536 m from the render origin. Every
  `WorldAnchor` re-places itself and the player moves back by the same amount, so velocity is preserved.
- Rule: anything static in the world is a `WorldAnchor` or a child of one. Free movers listen to
  `WorldOrigin.origin_shifted`.

## World model (data-driven)
`data/world/mantle_slice.json` defines stacks, floors, districts, landmarks, connections, the spawn point
and the arrival point.

- `StackRuntime` builds a stack: the shell (walls with the edge gate, ceiling, pillars) plus the city.
- `CityLayout` is a deterministic generator (seeded by stack id + chunk) that feeds **both** visuals and
  collision, so every LOD shows the same building in the same place.
- Visual LOD: buildings under 40 m fade out at 2.6 km; larger silhouettes never disappear.
- Streaming: building collision and practical lights load within 380 m of the player and unload beyond
  560 m. Shell and bridge collision are always present (a few shapes).
- `ConnectionRuntime` builds physical routes (only `bridge` so far), anchored at the route's midpoint.

## Files
```
project.godot              settings, shader globals
main.gd / scenes/main.tscn entry point: build world, player, overlays, save/load, test hooks
core/world_origin.gd       floating origin (autoload)
core/world_anchor.gd       node pinned to a logical position
core/input_setup.gd        key bindings
player/player_controller.gd
world/city_layout.gd       deterministic floor layout
world/stack_runtime.gd     stack builder + streaming
world/connection_runtime.gd
world/slice_materials.gd   shared material family + instancing helpers
world/texture_factory.gd   generated pixel textures
world/sites/               authored places: home (+lift), market, foundry (+pipes), gate plazas
world/crowd.gd             low-poly people (instanced, vertex-animated)
world/elevator_shaft.gd    shafts in the gaps between stacks
world/atmosphere.gd        environment, ground mist, dust motes
audio/ambience_manager.gd  zone beds, reverb, distant one-shots, footsteps
tools/gen_audio.gd         offline sound synthesis
shaders/                   facade, ground, emissive, retro post, common include
data/world/mantle_slice.json
```

## Adding a stack or floor
1. Add a stack entry to `mantle_slice.json` (id, origin, size, opening side, districts).
2. Add a `connections` entry whose endpoints touch the stacks' outer gate faces.
3. Done for Phase 1 greybox. Current limits: avenues run along X through z = 0, the gate is centred, and
   bridges are level.

## Tests and measurements
```
# Traversal proof: walks spawn -> gate -> bridge -> neighbour stack, headless (~1 min real time)
godot --headless --path game --fixed-fps 60 -- --autopilot=20
# Renders the 7 preset viewpoints to PNG and prints frame times
godot --path game -- --shots=C:/some/dir   [--no-post] [--snap=0|1|2]
```
Last results (RTX 3060, 960×540 internal, vsync off):
- Autopilot: ARRIVED in STK-0413 after 385 s simulated, 4 origin rebases, 0.000 m altitude drift.
- World build: ~0.4 s for 67 552 buildings across 2 stacks.
- Frame time: 1.25–1.70 ms, 29–285 draw calls, up to 396k primitives.

## Phase status
Phase 1 (scale and world proof): **done.** Phase 2 (hero vista, final ambience): **done**, see PHASE2_NOTES.md.
Next is Phase 3 (traversal polish: route decisions, shelters) and Phase 4 (looting, grid inventory, survival).
