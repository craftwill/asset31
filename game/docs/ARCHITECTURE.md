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
- Visual LOD: buildings under 40 m smoothly fade emission and 4×4 Bayer dither-fade out over 3.2–4.0 km before culling at 4.2 km; larger silhouettes never disappear.
- Procedural window interiors: near/mid facades run single-pass ray-box interior mapping (`shaders/window_interior.gdshaderinc`) and cross-fade seamlessly into analytical far window lights (`shaders/facade.gdshader`).
- Streaming: building collision and practical lights load within 380 m of the player and unload beyond
  560 m. Shell and bridge collision are always present (a few shapes).
- `ConnectionRuntime` builds physical routes (`bridge` with 500 m portal gantries, 46 m cable-stay pylon towers at 1.0 / 2.0 km, warm→cool lamp transition approaching `STK-0413`, and a 1.5 km mid-span shelter), anchored at the route's midpoint.

## Files
```
project.godot              settings, shader globals
main.gd / scenes/main.tscn entry point: build world, player, gameplay, save/load, test hooks
scenes/planet_view.tscn    standalone orbital space view of Asset 31 (refs 075s, 625s)
scenes/window_interior_test.tscn  standalone procedural window interior showcase
core/world_origin.gd       floating origin (autoload)
core/world_anchor.gd       node pinned to a logical position
core/input_setup.gd        key bindings
player/player_controller.gd
gameplay/item_db.gd        item catalog loader + procedural pixel icon generator
gameplay/inventory_grid.gd Tarkov-style 2D grid inventory model (rotate, stack, transfer)
gameplay/loot_container.gd persistent interactable world containers
gameplay/readable_note.gd  interactable in-world notes and canon plaques
gameplay/interaction_system.gd  first-person raycast interaction (containers + notes)
gameplay/survival_component.gd  health, slow hunger/thirst drain, shelter/heat/exposure zones
ui/hud_overlay.gd          minimal dark-industrial reticle, prompt, note reader, survival bars, toast
ui/inventory_ui.gd         drag-and-drop grid inventory panel
ui/map_ui.gd               diegetic Floor 77 route diagram (no GPS/objective markers)
world/city_layout.gd       deterministic floor layout (slabs, courtyards, 3-tier silhouettes)
world/stack_runtime.gd     stack builder + streaming
world/connection_runtime.gd
world/mining_shaft.gd      reachable 175s cylindrical mining shaft + 3 vertical strata + rideable 220 m lift to Undercroft 76-B
world/planet_view.gd       orbital space view of Asset 31 (shell, 360° arterial network, starburst hubs, starfield)
world/slice_materials.gd   shared material family + instancing helpers
world/texture_factory.gd   generated pixel textures
world/sites/               authored places: home (+lift), market, foundry (+bypass/pipes), gate plazas
world/crowd.gd             low-poly people (instanced, vertex-animated)
world/elevator_shaft.gd    shafts in the gaps between stacks
world/atmosphere.gd        environment, ground mist, dust motes
audio/ambience_manager.gd  zone beds, reverb, distant one-shots, footsteps
tools/gen_audio.gd         offline sound synthesis
tools/window_interior_test.gd
shaders/                   facade, window_interior, window_plane, ground, emissive, surface, retro post
data/world/mantle_slice.json
data/items/items.json
```

## Adding a stack or floor
1. Add a stack entry to `mantle_slice.json` (id, origin, size, opening side, districts).
2. Add a `connections` entry whose endpoints touch the stacks' outer gate faces.
3. Done for Phase 1 greybox. Current limits: avenues run along X through z = 0, the gate is centred, and
   bridges are level.

## Tests and measurements
```
# Traversal proof: walks spawn -> gate -> bridge -> neighbour stack, headless
godot --headless --path game --fixed-fps 60 -- --autopilot=12
# Gameplay & persistence self-test (containers, grid inventory, consumables, env zones, save/load)
godot --headless --path game -- --selftest
# Renders preset viewpoints + UI shot to PNG and prints frame times
godot --path game -- --shots=C:/some/dir   [--no-post] [--snap=0|1|2]
# Captures consecutive motion frames (market, roof vista, bridge)
godot --path game -- --motion=C:/some/dir
```
Last results (RTX 3050 Laptop, 960×540 internal, vsync off, muted):
- World build: ~1.1 s for 117 774 buildings across 2 stacks.
- Frame time: 1.32–3.27 ms (305–760 fps), 31–598 draw calls, up to 987k primitives.
- Selftest: PASS (7 containers, 5 readable notes, grid rotation/stacking/transfer, consumables, env zones, save/load round-trip).

## Phase status
Phases 1–5 are **complete** for the vertical slice. See `PHASE2_NOTES.md` and `PHASE3_4_NOTES.md` for details.
