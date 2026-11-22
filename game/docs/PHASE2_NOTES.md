# Phase 2: hero vista, final ambience, reference comparison

The screenshots in `docs/phase2_shots/` are named after the reference frame they're compared against.
Regenerate them with `godot --path game -- --shots=<dir>`.

## What was built
| Zone (brief §2.2) | Implementation | Reference |
|---|---|---|
| A. Home pocket | One-room shelter: riveted plates, bed, table, shelf, bucket, pipe, hanging bulb (shadowed), tally marks, tree drawing, window onto the city. Side street with sparse lamps. | 000s, 575s |
| B. Vista | Freight lift beside the home block (stand on it for 1 s) up to a 42 m roof with a parapet, looking over the city to the ceiling lamp grid and megatowers. | 300s, 100s |
| B. Market | The avenue through the home district becomes a ~28 m market street: storefronts, overhead tube light, banners, rails, 100 pedestrians. | 550s |
| C. Industrial | Pipe runs along the avenue, then a 400 m foundry hall: colonnade, trusses, hanging crucible pouring molten steel, moulds, furnace mouths, sparks, worker silhouettes, one shadowed hot light. | 025s |
| D. Stack edge | Gate plaza with a hazard edge, open railing with a glowing handrail, gate frame, route sign, light masts, shelter booth, freight yard and gantry. The bridge has a glowing handrail. Two elevator shafts in the gap with lamp strings and moving cars. | 125s, 175s, 225s, 375s |
| E. Arrival | Cool-palette stack, lamps hanging on long cables, checkpoint figures, arrival sign. | 500s |

**Material family:** low-res pixel textures generated at startup (`world/texture_factory.gd`): brick, concrete,
facade panel, riveted plate, pavers, dark steel, wood, fabric, grating, shop goods, hazard and paper.
Everything is sampled nearest-mipmap.

**Audio:** synthesized offline by `tools/gen_audio.gd` (22 kHz WAV):
- **Beds** (rumble, vent, room tone, wind, market murmur, machinery) crossfade by zone (`ambience_zones` in the data).
- **Reverb** follows the space: the room is dry and small, the foundry and gap are long and wet.
- **One-shots:** sparse distant ones (metal resonance, impacts, a far horn, creaks) placed in 3D. The foundry pour and machinery are positional.
- **Footsteps** sound different on stone and metal.

## Applied review feedback
- **Uneven lights:** window and ceiling lamps vary in intensity, and lamp density varies by region.
- **No debug grid on the ground:** pavers, plates, grating and softened concrete seams replace it.
- **Depth variation:** stepped building bodies, rooftop structures, and courtyards around authored sites.
- **Eye comfort:**
  - Ceiling lamps never shrink below ~1 px; energy is conserved when they're enlarged.
  - Lamp grids denser than ~3 px resolve to their average glow.
  - Window lights use hierarchical LOD.
  - Glow is reduced (intensity 0.35, threshold 1.3).
  - Vertex snap defaults to the subtle 1-pixel grid; the heavy mode is opt-in (F6).
- **Effects only where the references show them:** lamp glows (225s/550s), dust motes (575s/275s) and low ground mist (575s).
  There is no global volumetric haze.

## Known deviations from the references
- The 300s/100s vista is darker and less amber than the video; the haze tone needs a grading pass.
- The 550s crowd figures are blocky stand-ins without faces or props; the video shows varied clothing and hats.
- The 175s lattice elevator interior (a vast cylindrical shaft) isn't built; the gap shafts are square lattices seen from outside.
- Frames 350s (agricultural), 450s and 475s (nature floor) and 075s/625s (planet from orbit) are outside the slice's playable route and not built.
- The room window shows only a few lit windows across the street; the 000s frame shows more.

## Verification
- Route autopilot (`--autopilot=12`): room → door → side street → market → avenue → foundry → gate → bridge → STK-0413.
  It arrived after 652 s simulated, with 4 rebases and 0.001 m drift. Ambience profiles switched room → market → city → industrial → foundry → gap.
- The exported release build (`build/Asset31.exe`) passes the same autopilot headless.
- Frame times at the 10 reference viewpoints: 0.8–1.7 ms (RTX 3060, 960×540 internal).
- Headless runs print an "ObjectDB instances leaked" warning at exit: audio playbacks held by the dummy audio driver.
  This is test-harness only, not a game leak.

## Fix: ground stability (playtest video)
- **Symptom:** the floor swam while moving, and sidewalk, rail and hazard overlays flickered against the street.
- **Cause:** vertex snapping on 500 m ground quads, plus overlays only 1–1.5 cm above them.
- **Fix:**
  - Floors are never vertex-snapped (`ground.gdshader`).
  - Every floor overlay uses the same unsnapped shader and sits 3–5 cm above the ground.
  - Textures use nearest-mipmap with anisotropic filtering, so grout lines no longer crawl at grazing angles.
- **Check:** `godot --path game -- --motion=<dir>` saves 8 consecutive frames of a slow move along the market street.
