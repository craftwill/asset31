# Asset31 scale sheet

**Convention: 1 world unit = 1 metre.** Logical Y = height above the planet's original surface.

## Human scale
| Item | Value |
|---|---|
| Player height / eye height | 1.80 m / 1.68 m (crouch 1.15 m) |
| Walk / sprint / crouch speed | 1.8 / 4.6 / 0.9 m/s |
| Door | 1.0 × 2.1 m (Phase 2) |
| Residential room | ~3 × 4 × 2.8 m (ref frame 000s) |
| Storey height / window bay | 3.5 m / 4.0 m |

## City scale
| Item | Value |
|---|---|
| Block pitch / street width | 62.5 m / 14 m |
| Lot (residential) | ~24 × 24 m, buildings inset 1–3.5 m |
| Main avenue (to the edge gate) | ~62 m clear, lamps every 36 m |
| Residential buildings | 9–37.5 m |
| Urban buildings | 14–164 m (mostly low) |
| Megatowers (~1.2% of urban lots) | 300–860 m (up to the ceiling) |
| Industrial blocks (≤1.1 km from gate) | one 40–48 m footprint per block, 12–42 m tall |

## Stack scale
| Item | Value |
|---|---|
| Stack footprint (interior) | 6000 × 6000 m |
| Floor height (slab top to ceiling) | 900 m |
| Floor slab / ceiling slab thickness | 60 m |
| Outer wall thickness | 40 m |
| Structural pillars | 50 × 50 m, every 1000 m |
| Edge gate | 600 m wide × 420 m tall |
| Stack shell below / above the playable floor | 6000 m / 6000 m |
| Ceiling lamp grid | 64 m |

## World layout (logical)
| Item | Value |
|---|---|
| Mantle roof altitude | 60 000 m |
| Floor 77 slab top (both stacks) | 41 000 m |
| Home stack STK-0412 centre | (0, 41000, 0) |
| Neighbouring stack STK-0413 centre | (9080, 41000, 0) |
| Gap between stack outer walls | 3000 m |
| Bridge BR-077-A | 3000 m long, 12 m wide, piers every 300 m |
| Spawn → home gate → bridge → arrival | 4.5 km + 3.0 km + 0.2 km ≈ 7.7 km |
| Journey time | ~71 min walking, ~28 min sprinting |

## Precision budget
- Render coordinates stay within ±1536 m of the origin (rebase in 1024 m sectors).
- Float32 step at 1.5 km ≈ 0.12 mm, far below anything visible or physical.
- Anchors keep logical positions in float64; stack-local content stays within ±6 km of its anchor (≤0.5 mm step).
- Camera near/far 0.05 m / 40 km with Godot's reversed-Z depth buffer.
