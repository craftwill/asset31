# Phases 3, 4 & 5: Stability, Procedural Window Interiors, Traversal, Survival & Validation

Updated stills live in `docs/phase3_shots/` (regenerate with `godot --path game -- --shots=<dir>`).

## 1. Review Feedback Round 2 Fixes (`review/feedback/Asset31_Review_Tour_Feedback-round2.md`)

### Rendering stability and eye comfort
- **Analytical window anti-aliasing (`shaders/facade.gdshader`):** Replaced hard `step()` window masks with exact 1D analytical box-filter coverage (`box_cov()`) using pre-branch `fwidth()`, conserving light energy across pixel boundaries so distant windows never strobe. Added grazing-angle anisotropic blending toward exact mean emission so oblique walls stay steady.
- **Smooth dithered LOD fades (`shaders/retro_common.gdshaderinc`, `facade.gdshader`, `surface.gdshader`):** Added 4×4 ordered Bayer dither fades (`retro_bayer()`). Small buildings (`< 40 m`) smoothly fade window emission then dither-fade out between 3200 m and 4000 m before culling at 4200 m (replacing the 2600 m hard pop); bridge posts and lamp poles fade smoothly as well.
- **No megastructure swimming (`retro_snap_stable`):** Giant quads (> 80 m: stack walls, ceiling slab, industrial walls, long girders) never vertex-snap; in default subtle mode, vertex snapping fades out past 80–220 m so tiny distant silhouettes stay rock-steady.
- **Unbroken thin glowing rails (`shaders/emissive.gdshader`, `world/connection_runtime.gd`):** Added energy-conserving vertical sub-pixel stabilization (`min_px_y`) and split bridge handrails/girders into 25 m MultiMesh segments, removing dashed-line crawling across the gap.
- **Depth precision, dust & coplanar fixes:** Raised `camera.near` from `0.05` to `0.12` (2.4× depth precision in reversed-Z), reduced bloom (`glow_intensity = 0.28`, `threshold = 1.4`), added near-camera alpha fade on dust motes (`1.6..3.8 m`), anti-aliased market tube collar rings (`tube_light.gdshader`), and removed coplanar overlaps on bridge pier caps, railing posts, and the gate gantry trolley.

### Traversal readability & dark-space legibility
- **3 km Bridge (`world/connection_runtime.gd`):** Added 5 structural steel portal gantries every 500 m with restrained overhead work lamps and diegetic bi-directional distance signs (`BR-077-A · 1.5 KM | STK-0413 1.5 KM`), plus a cantilevered **Mid-Span Windbreak Shelter & Lookout Alcove** at 1.5 km.
- **Avenue, Foundry & Gate (`foundry_site.gd`, `gate_site.gd`, `market_site.gd`, `home_site.gd`):** Added overhead pipe-bridge gantries with route signs, market east exit arch, localized foundry portal bulkhead lamps, corridor guide bollards, gate threshold bollards through the 40 m wall passage, sign lights, and a lift landing lamp.

### Depth variation & lived-in details
- **City silhouettes (`world/city_layout.gd`):** Added full-block podiums, merged wide slabs, ~10% urban courtyard/sightline pockets, and 3-tier stepped tower silhouettes (all sinking 0.5–1.0 m into lower tiers/slabs to prevent coplanar faces). Added 900 m floor-slab dark bands and macro district density variation on distant stack walls.
- **Lived-in touches:** Market shopfront awnings, outer-sidewalk vendor stalls/crates, overhead side-street laundry lines, and courtyard/shelter crate clutter.

## 2. Procedural Window Interior System
- **Reusable ray-box module (`shaders/window_interior.gdshaderinc`):** Single-pass tangent-space ray-box intersection simulating back/side walls, floor/ceiling with corner AO, 7 deterministic room categories (Residential, Office, Workshop, Industrial, Empty, Closed curtains/blinds, Dark unlit), mid-room 3D parallax furniture silhouettes, and 5 curtain/blind states.
- **Standalone test scene:** `scenes/window_interior_test.tscn` + `tools/window_interior_test.gd` + `shaders/window_plane.gdshader` demonstrating all 7 categories and curtain states on flat window planes across multiple viewing angles and distances.
- **City-wide integration (`shaders/facade.gdshader`):** Runs only for near/mid windows (`fw_max < 0.26`) and cross-fades seamlessly into the far analytical `window_lights()` LOD with zero extra draw calls, nodes, or dynamic lights.

## 3. Phase 3 Route Decision & Phase 4 Survival, Looting & Grid Inventory
- **Route decision (`world/sites/foundry_site.gd`):** Added the **Sheltered North Service Bypass** (`z = -68.5..-62.2`) outside the foundry's north wall with ventilation slits, warm bulkhead lamps, a west-approach junction sign, and a maintenance loot locker. Taking the direct foundry floor exposes the player to `FOUNDRY HEAT` (elevated thirst drain); taking the longer bypass keeps the player `SHELTERED`.
- **Data-driven items & icons (`data/items/items.json`, `gameplay/item_db.gd`):** 8 Mantle items across food, water, medical, tool, and scrap categories with deterministic low-res pixel icons.
- **Tarkov-style 2D grid inventory (`gameplay/inventory_grid.gd`, `ui/inventory_ui.gd`):** 6×5 player pack and 4×3 / 5×4 containers with click/drag-and-drop, `R` rotation, stack merging, `RMB` consumable use, and `Shift+LMB` quick transfer.
- **Lootable containers (`gameplay/loot_container.gd`, `gameplay/interaction_system.gd`):** 6 persistent world containers (`CONT-HOME-CABINET`, `CONT-COURTYARD-CRATE`, `CONT-FOUNDRY-BYPASS`, `CONT-GATE-SHELTER`, `CONT-BRIDGE-MIDSPAN`, `CONT-ARRIVAL-CACHE`) with `E` raycast interaction and restrained HUD prompt (`ui/hud_overlay.gd`).
- **Survival & Save/Load (`gameplay/survival_component.gd`, `main.gd`):** Slow atmospheric hunger/thirst drain, hard-landing injury (`> 5 m`), exposure modifiers (`SHELTERED`, `FOUNDRY HEAT`, `EXPOSED SPAN`), and v2 `F5`/`F9` persistence of logical float64 coordinates, survival stats, player pack grid, and all looted container states by stable `container_id`.

## 4. World Immersion & Environmental Life Pass
- **Procedural Window Silhouettes (`shaders/window_interior.gdshaderinc`):** Added subtle, quiet human silhouettes behind ~14% of lit Residential/Office/Workshop windows on the mid-room parallax plane with gentle breathing sway — keeping streets dark and restrained while implying habitation at every distance.
- **Sparse Environmental Life (`world/sites/market_site.gd`, `gate_site.gd`, `mining_shaft.gd`, `crowd.gd`):**
  - Added dark steel industrial ration/service kiosks tucked along outer market sidewalks, beside the `STK-0413` arrival checkpoint shelter, and a Haulage Dispatch terminal on the `EL-CYL-77` hub.
  - Added a sparse 3-worker industrial crew (`Crowd`, `dark = 1.0`) inspecting the Mining Shaft 77-N hub and patrolling the west approach catwalk.
  - Single-MultiMesh conditional clothing silhouettes (brimmed hats, long industrial coats, backpacks, varied height/width).
- **Location-Based Soundscape (`tools/gen_audio.gd`, `audio/ambience_manager.gd`, `data/world/mantle_slice.json`):**
  - Synthesized 4 new spatial audio assets: `cable_tension.wav`, `elec_hum.wav`, `bridge_vib.wav` (looping beds) and `cable_groan.wav` (distant 3D one-shot).
  - Distinct per-zone acoustic identity preserving space for silence: quiet ventilation + faint human life in `residential`; murmur + electrical hum in `market`; heavy machinery + impacts in `foundry`/`industrial`; wind + structural deck vibration on `gap`/`edge`; taut cable tension + cavernous reverb + cable groans in `shaft`; subtle cooler acoustic pitch tint (`1.06×`) and crisp reverb in `STK-0413` (`arrival`).
- **Cylindrical Mining Shaft 77-N & 220 m Vertical Descent (`world/mining_shaft.gd`, `world/sites/lift.gd`, `EL-CYL-77`):**
  - Directly off the north side of STK-0412's East Edge Gate (`x = 3260, z = -180`, 300 m diameter, 3.6 km vertical span).
  - Upgraded the rideable service cage (`Lift`) to a real, continuous **220 m vertical descent** (`41,000 m → 40,780 m`, ~29 s at `7.5 m/s`) with a live in-cage `Label3D` altitude & depth-to-crust readout (`EL-CYL-77 · 40,842 M / CRUST -40.84 KM`).
  - Three clear vertical strata: (I) Inhabited Floor 77 hub, (II) Heavy infrastructure with vertical ore-conveyor pipe columns, strata clearance beacons (`-110 m` to `-1300 m`), and **Undercroft 76-B (`40,780 m`)** featuring a cantilevered grate overlook, `CONT-SHAFT-UNDERCROFT`, and `NOTE-UNDERCROFT-LOG`, and (III) Deep excavation abyss (`-2160 m`) with distant ember-lit planetary excavation floor far below.
  - **41 km Deep Planetary Mining Surface Descent (`world/deep_relay_lift.gd`, `gameplay/relay_console.gd`, `world/mining_surface.gd`):**
    - Docked directly off the east deck of Undercroft 76-B (`EL-DEEP-00`): installing a **Salvaged Relay** (`salvaged_relay`, found in `CONT-SHAFT-UNDERCROFT`, `CONT-BRIDGE-MIDSPAN`, or `CONT-ARRIVAL-CACHE`) unlocks continuous 41,000 m real float64 vertical express transit (`40,780 m ↔ 0 m`, ~64 s with streaming mid-shaft stratum sleeve, live altitude/velocity/stratum panel, and 40 seamless 1024 m vertical origin rebases).
    - **Asset 31 Original Planetary Crust (`CRUST-00`, `y = 0 m`):** Stepped excavated iron-basalt strip-mining pit beneath the colossal 60 m-thick Mantle steel keel (`+380 m`) and 6 titanic 52 m foundation legs, 3 rotating 145 m core-drill excavation rigs with molten bore craters and ore conveyors, enterable Survey Shelter Outpost, dark-clad mining crew, `CONT-CRUST-00`, `NOTE-CRUST-00`, and dedicated `"crust"` ambience + `drill_drone.wav` + `music_crust.wav`.
- **Ecological Preserve 413-B (`world/sites/preserve_site.gd`, faithful `450s`/`475s` recreation):**
  - Connected seamlessly through the north bulkhead of Hydroponic Bay 413-A (`SITE-PRESERVE-413`, 205 × 220 × 220 m luminous pale-concrete atrium): 3 giant overhead skylight grids, 8 stacked hanging terraces edged with magenta grow-strips and foliage, central tapered luminous pale-blue waterfall/light column, green meadow with grass tufts, 15 low-poly trees, 6 grazing deer silhouettes, 90 orbiting high-altitude birds, `CONT-PRESERVE-413`, `NOTE-PRESERVE-413`, smooth daylight atmospheric fog tinting (`atmosphere.gd`), and `"preserve"` waterfall ambience (`water_fall.wav`).
- **Field Expedition Log (`ui/journal_ui.gd`, `J` key):**
  - Minimal dark-industrial expedition log tracking all 10 canon landmarks as you physically discover them, archiving every in-world plaque/note you read, and displaying the full controls & quick-jump reference (persisted in v2 `F5`/`F9` saves).
- **Long-Distance Traversal Landmarks & Physical 3 km Rail Tram (`world/connection_runtime.gd`, `world/bridge_tram.gd`, `gameplay/tram_console.gd`):**
  - Upgraded the `1.0 km` and `2.0 km` bridge portals into monumental **46 m Cable-Stay Suspension Pylon Towers** with diagonal steel stay cables (smoothly dither-faded beyond 1.4–1.8 km) and dim red peak clearance beacons, straddling both the pedestrian bridge deck and the south maintenance rail track.
  - Added **TRAM-077**, a real physical open-flatbed maintenance rail car running along a cantilevered south rail spur (`z = +8.1`) across the entire 3,000 m chasm (`STK-0412 ↔ STK-0413`, `18 m/s`, ~2m 45s continuous real-time ride, zero teleports). Starts unpowered; scavenging a **Fuse Cell** (`CONT-GATE-SHELTER`, `CONT-FOUNDRY-BYPASS`, or `CONT-SHAFT-UNDERCROFT`) restores power via the diegetic station/on-board console (`E` key), persisted in v2 `F5`/`F9` saves.
  - Added a subtle lighting temperature transition on the final 600 m of `BR-077-A` approaching `STK-0413` (warm amber shifting to cool pale lamps and signage).
- **Hydroponic Bay 413-A (`world/sites/hydroponic_site.gd`, faithful `350s` recreation):**
  - Discoverable 155 × 120 m agricultural grow-hall tucked off the north edge of `STK-0413`'s West Arrival Plaza (`SITE-HYDRO-413`), featuring grated industrial floors, rust-steel columns with high warm amber sconces, 10 receding rows of raised dark crop troughs with layered low-poly green foliage, overhead suspended magenta-pink grow-light strips (plus the signature foreground white-spectrum strip), foreground break-table vignette, sparse hat-wearing agricultural workers, `CONT-HYDRO-413` harvest crate, `NOTE-HYDRO-413` agronomist log, and dedicated `"hydroponics"` ambience zone.
- **Sparse Atmospheric Discovery Music (`tools/gen_audio.gd`, `audio/ambience_manager.gd`, Brief §6.3):**
  - Synthesized `music_vista.wav` and `music_arrival.wav` (28 s hollow low-pass bowed-metal fifths) triggered at `-21 dB` on rare first-time landmark discoveries (`roof`, `shaft`, `arrival`, `hydroponics`) with a 180 s global cooldown so silence and spatial ambience remain dominant.
- **Floating-Origin `AnimatableBody3D` Fix (`lift.gd`, `bridge_tram.gd`):**
  - Disabled `sync_to_physics` on moving platforms under `WorldAnchor` nodes (which otherwise desynced their global physics/render transforms after 1024 m floating-origin rebases) and implemented explicit local-delta rider carry so both `Lift` and `BridgeTram` remain rock-solid across arbitrary rebases.
- **Enterable Shelters, Diegetic Map, Readable Notes & Work-Lamp:**
  - Open-doorway enterable Gate & Arrival Shelter Booths (`gate_site.gd`), Floor 77 Route Diagram (`ui/map_ui.gd`, `M` key, no GPS, now showing `TRAM-077` spur and `Bay 413-A`), 6 in-world readable notes/plaques (`readable_note.gd`, `E` key), and optional dim tungsten handheld work-lamp (`F` key, off by default).

## 5. Controls
| Key | Action |
|---|---|
| `W A S D` / `Shift` / `Ctrl` / `Space` | Move / Sprint / Crouch / Jump |
| `E` | Interact (open loot container or read in-world note/plaque) |
| `Tab` or `I` | Open / close Field Pack grid inventory |
| `M` / `J` | Open Floor 77 Route Diagram / Field Expedition Log & Controls |
| `F` | Toggle dim tungsten handheld work-lamp (off by default) |
| `LMB` / `R` / `RMB` / `Shift+LMB` (in UI) | Drag & drop / Rotate item / Use consumable / Quick transfer |
| `F5` / `F9` | Quick save / Quick load (logical coords, survival, pack, containers, tram, deep relay, journal) |
| `F3` / `F6` / `F7` | Debug overlay / Cycle vertex snap / Toggle Bayer colour dither |
| `Ctrl+1`..`0`, `-`, `=`, `Bksp`, `[`, `]` | Dev/preview quick-jump to all 15 showcase locations |

## 6. Validation & Measurements (RTX 3050 Laptop, 960×540 internal, vsync off, muted)
- **Import check (`--headless --import`):** 0 errors (all 33 synthesized WAVs, shaders, and scripts imported cleanly).
- **Full route autopilot (`--autopilot=20`):** `ARRIVED at STK-0413 / Floor 77 after 391 s simulated (4 rebases), Altitude drift -0.001 m`.
- **Automated gameplay self-test (`--selftest`):** `PASS` on both editor and exported `build/Asset31.exe` (10 containers, 8 readable notes, `BridgeTram` Fuse Cell repair, `DeepRelayLift` 41 km Salvaged Relay repair, `JournalUI`, grid rotation/collision/stacking/transfer, consumables, all 8 environmental zones, save/load round-trip at `y = 0 m` across 40 vertical rebases).
- **Frame times (`--audio-driver Dummy --shots=game/docs/phase3_shots`):** **0.96–2.20 ms/frame (455–1,041 fps)** across all 18 viewpoints (`300s_roof_vista`: 2.20 ms / 455 fps; `350s_hydroponics`: 1.53 ms / 653 fps; `475s_preserve`: 1.38 ms / 725 fps; `000m_crust`: 0.96 ms / 1,041 fps).
- **Motion stability (`--audio-driver Dummy --motion`):** Verified across market street, roof vista, and bridge/stack wall — zero floor swimming, zero broken rail dashes, steady cable-stay pylons, zero window-light strobing or LOD popping.
