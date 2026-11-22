# Agent handoff: Asset31 vertical slice

Read this first, then `docs/Vertical_Slice_Implementation_Brief.md` (the authoritative brief),
`game/docs/PHASE3_4_NOTES.md` (latest milestone notes), and `review/feedback/` (the latest external
review). Last updated after Phases 3–5, review feedback round 2 fixes, and the Procedural Window
Interior System.

## 1. What this is
A first-person exploration/survival vertical slice set inside **the Mantle**, a planet-covering
megastructure (canon in `README.md`, brief §0.1).

**The product is a faithful recreation of the reference video frames in `reference_images/`.** It is
not a loose interpretation.

**The one allowed visual deviation is removing z-fighting and depth or flicker instability, for eye comfort.**

## 2. Status
| Phase (brief §11) | State |
|---|---|
| 1. Scale and world proof | Done: floating origin, 2 stacks, real 3 km bridge, streaming, scale sheet |
| 2. Hero vista and final ambience | Done: authored sites per reference frame, material family, synthesized audio |
| 3. Traversal polish | Done: Round 2 stability fixes, procedural window interiors (+ quiet silhouettes), bridge 500 m gantries + 1.0/2.0 km 46 m cable-stay pylons + warm→cool transition + 1.5 km shelter + repairable 3 km **TRAM-077** rail car, foundry North Service Bypass, reachable 175s Mining Shaft 77-N (220 m lift to Undercroft 76-B), **Hydroponic Bay 413-A** (`350s`), and **Ecological Preserve 413-B** (`450s`/`475s` 220 m atrium) |
| 4. Looting, grid inventory, hunger/thirst | Done: 10 persistent containers, 8 readable notes, 8 items + pixel icons, 6×5 Tarkov grid UI, diegetic Floor 77 map (`M`), Field Expedition Log (`J`), work-lamp (`F`), slow survival + shelter/heat/exposure zones, spatial soundscape (11 beds, zone-weighted one-shots, sparse discovery music), v2 save/load |
| 5. Validation and handoff | Done: `--import`, `--selftest`, `--autopilot`, muted `--shots` (18 viewpoints, `455–1041 fps`), `--motion`, docs, and verified `build/Asset31.exe` |
| 6. Deep Planetary Mining Surface (`0 m`) | Done: **EL-DEEP-00** Salvaged-Relay express cage descending 41 km in float64 space (`40,780 m ↔ 0 m`) to **CRUST-00** (excavated planetary basalt benches, 3 rotating 145 m core-drill rigs, 60 m Mantle underside keel & 52 m foundation legs, Survey Outpost & crew) |

## 3. Environment and commands
- **Engine:** Godot **4.6.3 standard build**, at
  `C:\Users\william\Desktop\Godot_v4.6.3-stable_win64\Godot_v4.6.3-stable_win64_console.exe`.
  **Language:** typed GDScript.
- **Paths:** the project is in `game/`, and the repo root is this folder. Remote:
  `https://github.com/craftwill/asset31.git`, branch `main`.
- **Export templates** for 4.6.3 are installed; the preset is `game/export_presets.cfg`.
- **ffmpeg** is on PATH. Python is **not** installed; use GDScript `--script` tools or ffmpeg.

Run everything from `game/` (`G` = the console exe above):
```
"$G" --headless --path . --import                                   # parse/compile check (do after edits)
"$G" --path .                                                       # play (Ctrl+1..0 quick-jump, Tab/I pack, E loot)
"$G" --headless --path . -- --selftest                              # verify containers, grid inventory, survival, save/load
"$G" --headless --path . --fixed-fps 60 -- --autopilot=12           # walks the full route; prints ARRIVED/FAILED
"$G" --path . -- --shots=<abs dir> [--no-post] [--snap=0|1|2]       # 12 stills + UI shot + ms/frame
"$G" --path . -- --motion=<abs dir>                                 # consecutive motion frames (market, vista, bridge)
"$G" --path . res://scenes/window_interior_test.tscn                # standalone procedural window interior showcase
"$G" --path . --fixed-fps 30 --write-movie <abs>.avi -- --tour      # ~85 s captioned review video (960x540)
"$G" --headless --path . --export-release "Windows Desktop" ../build/Asset31.exe
"$G" --headless --path . --script res://tools/gen_audio.gd          # regenerate res://audio/*.wav
```
To turn a tour recording into the 1080p MP4 that was shared for review:
`ffmpeg -i tour_raw.avi -vf "scale=1920:1080:flags=neighbor" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac out.mp4`

**The verification loop the user expects:**
1. Import check.
2. Autopilot passes.
3. Shots, compared against `reference_images/video_frames/`.
4. `--motion` for anything that could shimmer.

Describe problems found in the screenshots honestly.

## 4. Architecture (details in `game/docs/ARCHITECTURE.md`)
- **Units and coordinates:** 1 unit = 1 m. Logical Y = altitude above the planet surface; Floor 77 is at 41 000 m.
- **`core/world_origin.gd` (autoload `WorldOrigin`):** floating origin.
  - Rebases in 1024 m sectors when the player is more than 1536 m from the render origin.
  - Everything static is a `WorldAnchor` or a child of one.
  - Saves use logical (float64) coordinates.
- **`data/world/mantle_slice.json`:** stacks, sites, connections, elevator structures, ambience zones and
  profiles, spawn, the autopilot `route`. Add content here first.
- **Stacks:** `world/stack_runtime.gd` builds each stack.
  - Shell (walls, gate, ceiling, pillars) plus the city in 500 m chunks.
  - Layouts come from `world/city_layout.gd`, which is deterministic and feeds both the visuals
    (MultiMesh) and the streamed collision.
- **Authored sites:** `world/sites/`: `home_site.gd` (room and lift), `market_site.gd`, `foundry_site.gd`
  (also pipe runs), `gate_site.gd` (departure and arrival). They're registered by `kind` in
  `StackRuntime._build_sites()`.
- **Other world systems:**
  - `world/connection_runtime.gd`: the bridge.
  - `world/elevator_shaft.gd`: shafts in the gap.
  - `world/crowd.gd`: instanced people, vertex-animated.
  - `world/atmosphere.gd`: environment, ground mist FogVolume, dust.
- **Materials:** `world/slice_materials.gd` is the only place materials are defined (ids like `&"plate"`).
  Textures are generated in code by `world/texture_factory.gd`; there are no image assets.
- **Audio:** `audio/ambience_manager.gd` handles zone beds, the reverb bus, distant one-shots and
  footsteps. Body meta `surface = "metal"` picks the metal footsteps.
- **Entry point:** `main.gd` handles build, spawn, overlays, save/load (F5/F9), and the test hooks
  (`SHOTS`, `TOUR`, `_run_motion`).

## 5. Hard-won gotchas (do not regress)
- **MultiMesh custom data loses precision.** Pass per-instance size in `INSTANCE_CUSTOM.yzw`. Decode the
  seed with rounding and a `flat` varying, or faces show two interleaved patterns.
- **Never vertex-snap floors.** `ground.gdshader` deliberately doesn't snap: snapping huge quads made the
  floor swim and overlays z-fight.
- **Floor overlays sit 3–5 cm up and use the GROUND shader:** sidewalks, rails, hazard bands, plaza,
  foundry and room floors.
- **Avoid coplanar faces everywhere:**
  - Buildings sink 1 m into the slab.
  - Upper building bodies start 0.5 m inside the lower body.
  - X walls cover the stack corners and Z walls fit between them.
  - Check any new box against its neighbours.
- **Distant lights:**
  - Ceiling lamps have a minimum 1 px size with energy conserved, and resolve to their average below ~3 px spacing.
  - Windows use hierarchical LOD (`window_lights()` in `facade.gdshader`).
  - Keep glow low (intensity 0.35, threshold 1.3).
- **`alt_fraction` in the facade shader adds lit windows on top of `lit_fraction`.** It isn't a share of
  the lit windows, so keep it small.
- **`source_color` tints above 1.0** get sRGB-decoded and blow up; check visually.
- **Never enable `sync_to_physics = true` on `AnimatableBody3D` children of a `WorldAnchor`.** Godot 4 caches `last_valid_transform` in render space, so 1024 m floating-origin rebases desync the body from its anchor. Use `sync_to_physics = false` and carry any standing rider by the local delta in `_physics_process` (see `Lift` and `BridgeTram`).
- **Headless exit warnings:** an "ObjectDB leaked" warning from audio playbacks under the dummy driver
  is test-only. Don't chase it.
- **Sed-based multi-line edits on GDScript have broken code before.** Prefer real edits and re-run the import check.

## 6. User preferences (from the user and the reviewer)
- **Stability over spectacle:** "Not prettier by adding more effects; make the existing reference look
  more physically convincing and stable."
  - Only add an effect if a reference frame shows it.
  - Don't make the world brighter, busier or more colourful.
- **Varied lights, no debug-grid surfaces, more silhouette and depth variation**, all within the reference style.
- **Asks:** the user wants builds exported and launched, and short review videos for an external
  reviewer (ChatGPT). Feedback files land in `review/feedback/`; commit them.
- **The repo is public:**
  - Don't commit `reference_images/ref_video.mp4` (third-party footage).
  - Don't commit `build/` or `review/*.mp4`: they're over 100 MB and regenerable.
  - The `.gitignore` already handles this.
- **Commits** end with the Co-Authored-By line from the session's attribution instructions.

## 7. Completed in Phases 3–5 & Next Expansion Points
All Phase 3–5 vertical-slice deliverables are complete (details in `game/docs/PHASE3_4_NOTES.md`):
- Rendering stability: analytical window AA, grazing-angle stabilization, Bayer dithered LOD fades, `retro_snap_stable`, sub-pixel energy-conserved bridge handrails, near-fade dust, `camera.near = 0.12`.
- Procedural Window Interior System: `shaders/window_interior.gdshaderinc` + standalone showcase `scenes/window_interior_test.tscn` + city-wide integration in `facade.gdshader`.
- Traversal & route decision: 500 m bridge portal gantries, 1.5 km mid-span shelter/lookout alcove, Foundry Sheltered North Service Bypass vs. direct hot foundry floor, localized dark-space practical lighting.
- Survival & looting: `data/items/items.json`, `gameplay/` (`ItemDB`, `InventoryGrid`, `LootContainer`, `ReadableNote`, `InteractionSystem`, `SurvivalComponent`), `ui/` (`InventoryUI`, `HudOverlay`, `MapUI`), 7 persistent world containers, 4 readable canon notes, enterable gate/arrival shelter booths, optional tungsten work-lamp (`F`), v2 `F5`/`F9` save/load, and `Ctrl+1..0` / `Ctrl+-` preview teleports.
- Cylindrical Mining Shaft 77-N (`world/mining_shaft.gd`, `EL-CYL-77`): reachable off the East Edge Gate with 24-sided lit inner shaft walls, concentric ring lights, 8 lattice elevator towers, moving cars, and a rideable 80 m service cage down to Undercroft 76-B.
- Crowd & haze polish: conditional single-MultiMesh hats, long industrial coats, and backpacks in `crowd.gd`/`figure.gdshader`, plus warmer amber vista haze tuning.

**Tip:** Pass `--audio-driver Dummy` on interactive Godot `--shots`/`--motion`/`--tour` CLI runs to keep the machine muted.

## 8. Housekeeping
- **Fresh stills** live in `game/docs/phase3_shots/` (13 viewpoints + `ui_inventory.png` + `ui_map.png`).
- **Keep docs current** when expanding beyond the vertical slice (`game/docs/ARCHITECTURE.md`, `game/docs/PHASE3_4_NOTES.md`, and this handoff).
- **Re-export** `build/Asset31.exe` after any code/data edit and verify with `--headless -- --selftest` and `--autopilot=12`.
