# Asset 31 — Master TODO List (Environment Rework + Transport + The Continuum)

> All items in Sections 1, 2, 3, and 4 are **COMPLETE & VERIFIED** in [`build/Asset31_v8.exe`](file:///C:/Users/william/Desktop/asset31/asset31/build/Asset31_v8.exe).

---

## 1. Environment Rework & Polish
- [x] **Zero-out all `ZFightLint` overlaps (`571 → 0`)** — scanned **6,575 authored boxes** across the entire game with **`0` coplanar face overlaps**
- [x] **Walkability & "Go Anywhere Accessible" Pass** — end-of-corridor ramps + 4 mid-corridor highway ramps + 2.2 km elevated skywalk galleries on `SITE-HIGHWAY-412`, solid Glass Terrace parapet/vent/overlook collision, and north-wing Arrival catwalk spur straight onto `STA-0413-N`
- [x] **District Architectural & Material Cohesion** — clustered macro skyline + spires, Foundry crucible light & overhead bridge-crane girders, bolted Market sign frames, Highway district threshold signs/gallery sconces/service cabinets, Arrival north/south wayfinding, and fixed floating lamp poles
- [x] **Preserve Twin-Stack Landmark (`STK-0412` / `STK-0413` / `BR-077-A`)** with 3D exterior cliff buttresses & ledges + 4 distant stacks (`STK-0414`–`STK-0417`) at 16–19 km

---

## 2. Transport Systems — Inter-Stack Express (`EXP-077`)
- [x] **Phase 8A — `STA-0413-N` Departure Concourse & `VD-077-N` 14.4 km Abyssal Viaduct** — walkable 54 m catwalk from `STK-0413` West Arrival (`z = -250 m`), 14.4 km box-truss viaduct with 900 m abyssal piers, portal clearance frames, beacons, and passing chasm shafts (`EL-GAP-3`, `EL-GAP-4`)
- [x] **Phase 8B — `STA-0414-S` Destination Terminal (17.5 km North)** — south arrival terminal anchored into distant `STK-0414` with sweeping 38 m exterior **Twin-Stack Overlook Balcony** looking 17.5 km south back at `STK-0412` + `STK-0413`, plaque (`NOTE-STK-0414`), cache (`CONT-STA-0414-S`) & return console
- [x] **Phase 8C — Walkable 3-Car Human-Safe Express Train (`EXP-077`)** — 63 m walkable 3-car consist (`&"plate_local"`, zero texture scroll): Car 1 Forward Panoramic Cab (`[E]` dispatch/reverse + live speed/G/km telemetry), Car 2 Mid Saloon (benches, `CONT-EXP-077`, `NOTE-EXP-077`), Car 3 Rear Open-Air Chasm Deck; `110 m/s` (`396 km/h`), `0.16 G` S-curve + hydraulic soft-docking, free-walk train-local rider lock, speed-modulated traction & wind audio
- [x] **Phase 8D — Integration, Map, Journal & Automated Round-Trip Test** — wired into `mantle_slice.json`, v2 save/load, `MapUI`, `JournalUI`, `Ctrl+.` / `Ctrl+/`, and verified in `--selftest` (`217 s` each way, `peak |a| = 1.60 m/s²`, `0.0000 m` floor error) alongside `EL-DEEP-00` (41 km lift) and `TRAM-077`

---

## 3. Final Quality Gate & Release Build (Phase 9)
- [x] Visually inspected all 26 reference & landmark stills (including `375s_highway.png`, `400s_glass_terrace.png`, `twin_stack_horizon.png`, `125s_bridge_shaft.png`, `exp077_station.png`, `stk0414_overlook.png`, and `ui_map.png`)
- [x] Updated `TOUR` camera script in `main.gd` covering all new landmarks & `EXP-077`
- [x] Passed `--import`, `--zfight-lint` (`0` overlaps), `--selftest`, `--autopilot=20`, `--motion`, and exported `build/Asset31_v7.exe` `--selftest`
- [x] Updated `AGENT_HANDOFF.md`

---

## 4. Worldbuilding — The Religion of The Continuum & The Void Bell
- [x] **The Void Bell (`res://audio/religion/religious_long_bell.mp3`)** — dedicated `VoidBell` megalophobic audio bus (`LowPass` zone occlusion -> twin-stack `780 ms / 1480 ms` canyon stereo `Delay` + `1150 ms` feedback tail -> cavernous `Reverb` -> `Compressor`), pitched-down colossal strike (`0.79–0.87x`) + delayed octave-lower structural sub-resonance (`0.62x`), loud & echoing between stacks (`gap`/`edge`/`shaft`/`arrival`), muffled indoors, spaced `2.7–5 min` outdoors / `5.5–9 min` indoors (with a `13–21 s` first-chasm-encounter prime + **`Ctrl+B`** instant on-demand trigger)
- [x] **The Great Belfry of the Continuum (`BELFRY-0414`, [`game/world/void_bell_sanctum.gd`](file:///C:/Users/william/Desktop/asset31/asset31/game/world/void_bell_sanctum.gd), `Ctrl+\`)** — 400 m-wide cylindrical shaft cathedral inside distant `STK-0414` directly behind the `STA-0414-S` Express Terminal (`17.5 km` north), recreating [`religious_huge_bell.png`](file:///C:/Users/william/Desktop/asset31/asset31/reference_images/religion_concepts/religious_huge_bell.png): colossal 88 m-wide 12-sided 5-tier stepped Void Bell + 17 m dark-iron spherical clapper that physically swings with a golden interior shockwave flare when struck (`[E]` on the Resonance Strike Console or `Ctrl+B`), foreground lattice tower + 4-window glowing gondola + side-profile upper box-truss bridge (`+18 m`), cantilevered Pilgrim Overlook Platform with 2 pilgrim silhouettes, and Chime Keeper's Continuum Altar (`NOTE-VOID-BELL-SANCTUM`, `CONT-VOID-BELL-RELIC`)
- [x] **Sacred Symbol of The Continuum (`game/world/continuum_emblem.gd`)** — vertical spine + three connected oxidized-copper rings (Matter, Life, Memory) with zero `ZFightLint` overlaps
- [x] **Environmental Shrines & Plaques** — Wayside Continuum Shrine & plaque at `BR-077-A` Mid-Span Shelter (`NOTE-CONTINUUM-BRIDGE`), Foundry North Service Bypass Maintenance Shrine (`NOTE-CONTINUUM-SHRINE`), monumental Continuum emblems at East/West Edge Gates, Mining Shaft 77-N Hub, `EL-DEEP-00` 41 km elevator cage, and `STA-0414-S` cliff portal
- [x] **Verified `--import`, `ZFightLint = 0` (6,575 boxes), `--selftest` (15 containers, 15 notes, `VoidBell` & `BELFRY-0414` verified), and exported [`build/Asset31_v8.exe`](file:///C:/Users/william/Desktop/asset31/asset31/build/Asset31_v8.exe)**
