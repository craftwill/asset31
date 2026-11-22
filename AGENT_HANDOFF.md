# Agent handoff: Asset31 vertical slice

Read this first, then `docs/Vertical_Slice_Implementation_Brief.md` (the authoritative brief) and
`review/feedback/` (the latest external review). Last updated after Phase 2, plus a ground-stability fix
and review feedback round 2.

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
| 3. Traversal polish | **Next.** See §7 |
| 4. Looting, grid inventory, hunger/thirst | Not started (no interaction or inventory code exists yet) |
| 5. Validation and handoff | Not started |

## 3. Environment and commands
- **Engine:** Godot **4.6 standard build** (not .NET, despite the folder name), at
  `C:\Users\willi\Desktop\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_win64_console.exe`.
  **Language:** typed GDScript.
- **Paths:** the project is in `game/`, and the repo root is this folder. Remote:
  `https://github.com/craftwill/asset31.git`, branch `main`.
- **Export templates** for 4.6 are installed; the preset is `game/export_presets.cfg`.
- **ffmpeg** is on PATH. Python is **not** installed; use GDScript `--script` tools or ffmpeg.

Run everything from `game/` (`G` = the console exe above):
```
"$G" --headless --path . --import                                   # parse/compile check (do after edits)
"$G" --path .                                                       # play
"$G" --headless --path . --fixed-fps 60 -- --autopilot=12           # walks the full route; prints ARRIVED/FAILED
"$G" --path . -- --shots=<abs dir> [--no-post] [--snap=0|1|2]       # 10 reference-named stills + ms/frame
"$G" --path . -- --motion=<abs dir>                                 # 8 consecutive frames while moving (stability)
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

## 7. Next work: Phase 3, ordered by `review/feedback/` round 2
1. **Rendering stability and comfort.** Run `--motion` variants over distant city lights, building LOD
   edges (`SMALL_VIS_END` 2600 m in `stack_runtime.gd` has no fade) and the stack walls. Fix shimmer and pops
   without changing the look; for example, dithered visibility fades or a larger LOD distance with fog.
2. **Traversal readability.** Add sparse, restrained landmarks and practical lights along the avenue and
   the 3 km bridge, plus a few at the gate threshold. No objective markers or bright paths (brief §9).
3. **Dark spaces readable.** Add local practical lights at key traversal points (foundry portals,
   pipe-run transitions, gate) instead of raising exposure.
4. **Depth variation.** Add more gaps, courtyards and layering in distant silhouettes (`city_layout.gd`)
   in the same style.
5. **Lived-in details.** Add small signs of use: market stalls, laundry, debris.
6. **Brief §9 route decisions** (still missing): a safer/longer versus exposed option, one shelter stop,
   and a reason to prepare. That leads into Phase 4 (containers, grid inventory, hunger/thirst,
   save/load of looted state).

**Known deviations still open** (`game/docs/PHASE2_NOTES.md`):
- The 300s vista is less amber than the video.
- The people are blocky stand-ins.
- The 175s cylindrical lift interior isn't built.
- The room window shows few city lights.

## 8. Housekeeping
- **The local `build/Asset31.exe` (12:45) is older than the foundry bounce-light change in `main`.**
  Re-export before handing out a build.
- **After any visual change,** update the stills: run `--shots=<repo>/game/docs/phase2_shots`, or start a
  `phase3_shots` folder.
- **Keep docs current:** `game/docs/ARCHITECTURE.md` (file list, phase status), `game/docs/PHASE2_NOTES.md`
  (deviations), and this handoff.
