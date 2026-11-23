# Inter-Stack Express (`EXP-077`) — Architectural & Gameplay Design Proposal

> **Status:** Design Proposal ONLY (Phase 8 — NOT YET IMPLEMENTED).
> Awaiting user review and approval before any runtime code or geometry is added.

---

## 1. Core Concept & Landmark Preservation Rule

The **Inter-Stack Express (`EXP-077`)** is the horizontal planetary-scale counterpart to the 41 km vertical **`EL-DEEP-00`** deep-descent elevator: a colossal, human-safe elevated megastructure rail train that links the **preserved Twin-Stack Landmark (`STK-0412` / `STK-0413`)** across a **17.5 km abyssal viaduct** to the genuinely distant northern stack **`STK-0414`**.

### Non-Negotiable Spatial Rules
1. **Preserve the Twin-Stack Landmark untouched**: `STK-0412` (warm amber), `STK-0413` (cool blue-white), and their existing 3.0 km pedestrian/tram bridge **`BR-077-A`** remain exactly as they are. `EXP-077` does **not** widen the 3 km gap, relocate either stack, or replace `BR-077-A` / `TRAM-077`.
2. **True Planetary-Scale Horizontal Journey**: Unlike `TRAM-077` (a 3.0 km utility spur across the close twin-stack canyon), `EXP-077` departs **northward** out of the Twin-Stack region across a 17.5 km open-void viaduct toward **`STK-0414`**, delivering the overwhelming reference-video scale of watching a distant stack grow from a faint 17.5 km silhouette in the amber haze into a 6 km-wide cliff wall.

---

## 2. Route, Stations & Spatial Integration

- **Origin Station — `STA-0413-N` (STK-0413 North Concourse / Viaduct Head)**:
  - Positioned on the north-west edge of `STK-0413` (logical `x ≈ 6,200 m, y = 41,000 m, z ≈ -2,980 m`), reachable via a clean pedestrian concourse spur branching north from `SITE-PRESERVE-413` / `STK-0413 West Arrival`, keeping the existing arrival plaza and `BR-077-A` sightlines clean.
  - Features a monumental elevated boarding platform, departure board (`EXP-077 · STK-0414 · 17.5 KM · TRANSIT 03:40`), waiting benches, supply locker, and power/dispatch console.
- **The 17.5 km Abyssal Viaduct (`VD-077-N`)**:
  - Runs along `x = 6,200 m` from `z = -3,040 m` (`STK-0413` north wall) to `z = -14,700 m` (`STK-0414` south portal at `[6200, 41000, -17500]`, outer south face at `z = -14,700 m` — **11.66 km clear open-void viaduct span**, **17.5 km center-to-center**).
  - Heavy dark-steel double-deck box-truss viaduct (`18 m` wide) supported on colossal abyssal piers every `900 m` dropping `6,000 m` into the orange abyss, with sparse amber/red navigation beacons and occasional cross-chasm cable stays & distant vertical elevator shafts passing in parallax (`EL-GAP-3`, `EL-GAP-4`).
  - Uses distance-staged MultiMesh LODs + floating-origin rebasing (`WorldOrigin` shifts automatically every `500 m`, zero precision jitter at 17.5 km!).
- **Destination Station — `STA-0414-S` (STK-0414 South Terminal)**:
  - Compact, high-impact authored arrival terminal carved into `STK-0414`'s south cliff face (`z = -14,700 m`): monumental cool-lit arrival concourse, sweeping exterior observation balcony looking **17.5 km south back at the Twin-Stack pair (`STK-0412` + `STK-0413`)** glowing side-by-side in the distance, explorer terminal log, and supply cache.
  - *Note:* `STK-0414` stays an atmospheric `DistantStack` shell plus a dedicated authored arrival terminal (~300 × 200 m) — no need to generate a full third 6 km procedural city until later milestones!

---

## 3. Train Architecture, Walkable Consist & Human-Safe Kinematics

### 3.1 Multi-Car Walkable Consist (3 Cars, ~66 m Total Length)
Players can **walk freely through the train while it is moving at high speed**, moving between enclosed observation windows, an open-air rear gangway/balcony, and the forward cab:
1. **Car 1 — Forward Drive & Observation Cab (`22 m`)**: Panoramic dark-mullioned front window looking straight down the viaduct toward `STK-0414`, control desk with live speed (`m/s` / `km/h`), distance remaining (`km`), G-load (`0.00 G`), and `[E]` Departure / Reverse console.
2. **Car 2 — Mid Passenger / Freight Saloon (`22 m`)**: Warm-lit utilitarian seating, overhead grab bars, side viewports framed for watching distant stacks and passing abyssal shafts, plus an onboard expedition locker & field note.
3. **Car 3 — Rear Open-Deck Observation Platform (`22 m`)**: Partially sheltered steel observation deck with guardrails where players can step out into the roaring chasm wind and watch the Twin-Stack Landmark recede into the 17.5 km haze behind them.

### 3.2 Human-Safe Motion & Zero-Phasing Rider Physics
Directly reuses the battle-tested architecture proven on **`EL-DEEP-00`** (0.0000 m floor error, zero camera phasing, zero texture scrolling):
- **S-Curve Kinematics**:
  - `MAX_SPEED = 110.0 m/s` (`396 km/h` — classic maglev/high-speed rail feel; visually dramatic passing `900 m` piers every `8.2 s` without strobing).
  - `MAX_ACCEL = 1.6 m/s²` (`0.16 G` longitudinal — gentle enough to walk comfortably between cars without losing footing).
  - `MAX_JERK = 0.6 m/s³` (silky smooth start and braking transitions).
  - Exponential hydraulic soft-docking at station platforms (`0.00 m` threshold error).
  - **One-way transit time**: ~`2 min 55 s` (`175 s`) for the `11.66 km` clear viaduct span — long enough to feel genuinely epic, walk all 3 cars, and take in the planetary vista, without dragging!
- **Train-Local Rider Lock (`player.riding_transport`)**:
  - While aboard `EXP-077`, `player` movement is integrated in train-local coordinates and transformed via `car_anchor.to_global(local_pos)` each physics tick (identical to `DeepRelayLift` — eliminating all collision tunneling/phasing at `110 m/s` AND surviving `WorldOrigin` 500 m rebases seamlessly!).
  - All moving train surfaces use local-space materials (`&"plate_local"`, `&"wood"` with `use_world = 0.0`) so textures never scroll as the train moves.
- **Audio & Atmosphere**:
  - Deep rhythmic rail-clack / magnetic-traction hum (`AudioStreamPlayer3D` attached to bogies, pitch-modulated by speed), chasm wind surge on the rear open deck, and soft station chime on docking.
  - Smooth `"gap"` atmospheric fog (`0.000105–0.000135`) throughout the span so `STK-0414` emerges gradually from a distant misty monolith into full 3D cliff relief.

---

## 4. Technical Risks & Mitigations

| Risk | Mitigation |
|---|---|
| **WorldOrigin 500 m rebases at 110 m/s** (~every 4.5 s) | Express train inherits `WorldAnchor` (exact logical `Float64` `lx/ly/lz` + `_sync_position()`). Rider offset stored in train-local `Vector3` so rebases are 100% invisible. |
| **Viaduct draw-call / memory cost across 11.7 km** | Single batched `MultiMeshInstance3D` per material (deck, truss, piers, lights) + 1 shared `StaticBody3D` only near stations (viaduct deck needs collision only if player can walk it; during ride train floor handles collision). Total cost: **~6 draw calls**. |
| **Camera clipping / phasing while walking between moving cars** | Reuse `DeepRelayLift`'s proven `player.riding_transport` local-space integration (`move_and_slide` in local frame or clamped interior AABB + gangway doors). Verify with a dedicated 12,000-frame `--selftest` automated round-trip rider assertion. |
| **Destination emptiness on arrival at `STK-0414`** | Author a compact, atmospheric `STA-0414-S` South Concourse & Twin-Stack Overlook Balcony with lore plaque, supply cache, and return dispatch console so arriving feels rewarding immediately. |

---

## 5. Minimal Prototype Implementation Plan (Upon Approval)

1. **Step 1 — Viaduct & Station Shells (`game/world/inter_stack_express.gd`)**: Add `VD-077-N` viaduct geometry + `STA-0413-N` / `STA-0414-S` platforms anchored to `STK-0413` and `STK-0414`.
2. **Step 2 — 3-Car Express Consist & Kinematics**: Build the walkable 3-car train using `&"plate_local"` + `&"glass"`, S-curve kinematics (`110 m/s`, `1.6 m/s²`), and train-local rider lock.
3. **Step 3 — Integration, Save/Load & Selftest**: Wire into `mantle_slice.json`, `main.gd` (save/load state, landmark discovery, Ctrl quick-jump, new verification shot `exp077_viaduct`), and add a full automated round-trip kinematics & rider-tracking test to `--selftest`.

> **Ready for approval:** Say the word if you'd like any adjustments to the route, train speed/length, or station placement — or approve as-is to begin Step 1.
