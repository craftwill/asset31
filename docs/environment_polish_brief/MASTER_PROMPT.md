# Environment Polish & World Cohesion — Master Implementation Brief

## Goal
Take the existing Asset31 vertical slice from an impressive technical/procedural megastructure to a visually cohesive, believable, memorable science-fiction world. Prioritize environmental quality and coherence over adding new systems or expanding the map.

The current project already includes (verify in project before assuming):
- Stable rendering and eye-comfort work, analytical window AA, dithered LOD fades, stable retro snapping, sub-pixel rails, reversed-Z, restrained bloom.
- A 41 km EL-DEEP-00 elevator round trip, bridge traversal infrastructure, gantries, pylons, shelter, signage, service bypass and TRAM-077 rail spur.
- Localized lamps, zone-specific atmosphere, stepped tower silhouettes, podiums/courtyards, 900 m floor bands, procedural windows/interiors/silhouettes.
- Hydroponic Bay and Ecological Preserve at expanded scale, plus lived-in details, crews, kiosks, notes, inventory, map and field log.
- Planet View and other recent work may have changed since the last review. Inspect the current branch and current project state.

## Critical instructions
1. Inspect the repository, current scene structure, asset pipeline, procedural generation systems, recent changes, and review videos/notes before editing.
2. Read existing review/feedback files, especially `review/feedback/Asset31_Review_Tour_Feedback-round2.md`, and inspect the latest available review tour. Do not assume the reported status is fully accurate.
3. Preserve all existing working features and the project's established visual identity. Do not regress the elevator, traversal, rendering stability, Planet View, or performance.
4. Do not perform a wholesale rewrite, replace established systems, or create a new architecture without a demonstrated need.
5. Do not equate polish with adding more pipes, lights, decals, noise, geometry, or random clutter. Every change must improve composition, readability, function, or storytelling.
6. Work in small, reviewable phases. For each phase: state the findings, propose concrete changes, implement, run the project/build/tests where available, inspect screenshots or a tour, and report changed files and remaining issues.
7. Preserve performance and rendering budgets. Profile before and after significant changes. Avoid increasing draw calls, memory, shader complexity, or asset startup cost without justification.
8. Keep all changes compatible with the project's existing conventions and tools. Do not invent APIs or pretend a test was run.
9. Do not commit unless explicitly asked. Do not delete existing assets or review material without approval.
10. If a requirement conflicts with the current implementation, explain the conflict and recommend the smallest safe change.

## North-star visual criteria
The environment should read at three scales:
- **Macro (500 m–kilometers):** strong skyline and district silhouettes, recognizable landmarks, convincing depth, intentional negative space, and clear visual hierarchy.
- **Meso (20–200 m):** legible building masses, distinct architectural rhythms, clear circulation and infrastructure, useful facade variation, and believable transitions.
- **Micro (0.5–20 m):** purposeful structural details, material variation, maintenance evidence, signage, wear, and lived-in elements without visual noise.

The world should feel like one civilization with regional variation—not unrelated procedural sets. Architecture should communicate function, age, resources, maintenance, and adaptation.

## Phase 0 — Audit and baseline (do not edit yet)
- Inspect current project, branch/status, scene hierarchy, procedural systems, art/material conventions, LODs, asset sizes, and performance bottlenecks.
- Review feedback-round2 and the latest tour/video. Identify what has improved and what still looks unfinished.
- Capture baseline views: Planet View, major stack exterior, bridge, 41 km elevator, Hydroponics, Ecological Preserve, major district transitions, and representative close-ups.
- Create a concise issue list ranked by visual impact, frequency, cost, and risk.
- Identify repeated patterns, weak silhouettes, over-bright/under-readable areas, scale inconsistencies, unfinished transitions, and environmental storytelling gaps.
- Deliver a proposed change plan and wait for approval before large or risky changes.

## Phase 1 — Macro composition and landmark hierarchy
- Improve skyline composition and silhouette variation without randomly changing the whole city.
- Establish a small hierarchy of primary, secondary, and tertiary landmarks.
- Add or improve foreground framing and mid-distance forms where vistas feel empty or visually flat.
- Make distant stacks and structures recognizable through silhouette, proportion, and lighting—not excessive detail.
- Check sightlines from actual player routes and the Planet View.
- Ensure major landmarks remain distinct from multiple viewpoints and do not all compete for attention.
- Avoid uniform tower heights, evenly spaced silhouettes, repetitive rooftop profiles, and arbitrary visual clutter.

## Phase 2 — Architectural identity and district differentiation
- Define a concise architectural vocabulary for each major district: massing, materials, structural rhythm, window proportions, infrastructure density, color temperature, and age/condition.
- Make district differences legible from far away and convincing up close.
- Audit procedural generation for obvious repetition, mirrored patterns, identical spacing, repeated facade modules, and uniform damage/wear.
- Introduce controlled variation based on building function and neighborhood—not unbounded randomness.
- Improve transitions between industrial, residential, transit, hydroponic, ecological, and exterior zones.
- Ensure buildings have believable structural logic: load paths, supports, access, maintenance clearance, drainage, and connection to surrounding infrastructure.

## Phase 3 — Facades, materials, and scale cues
- Improve large facade patterns and structural subdivisions before adding small details.
- Ensure windows, doors, rails, platforms, pipes, and people/vehicles use consistent scale references.
- Refine material separation and roughness/value hierarchy so metal, concrete, glass, painted panels, and organic surfaces read distinctly.
- Add restrained age, repairs, grime, weathering, patchwork, and localized damage where they tell a story.
- Prevent procedural materials from becoming uniformly noisy, overly glossy, or excessively high contrast.
- Verify window interiors and silhouettes remain readable at distance and do not create distracting flicker or excessive light noise.

## Phase 4 — Lighting, atmosphere, and depth
- Establish consistent rules for near, mid, and far visibility in the dark environment.
- Keep nearby navigation and interactable areas readable without flattening the darkness.
- Use localized light sources with plausible purposes: entrances, work areas, transit, safety, signage, and maintenance.
- Strengthen warm/cool transitions where they communicate district changes or depth.
- Audit bloom, exposure, fog, haze, and contrast from multiple viewpoints and display conditions.
- Avoid uniform fog, excessive bloom, glowing windows everywhere, or distant silhouettes disappearing completely.
- Preserve eye comfort and existing anti-aliasing/LOD stability.

## Phase 5 — Environmental storytelling and lived-in infrastructure
- Add functional details only where they explain how the place operates: ventilation, power distribution, drainage, water, waste, structural bracing, access routes, loading, repair, and emergency systems.
- Make infrastructure connect logically rather than appearing as decorative isolated props.
- Show signs of maintenance and adaptation: replacement panels, temporary repairs, inspection marks, worn paths, tool stations, work lights, and service access.
- Use signage, markings, plaques, and environmental clues consistently and sparingly.
- Ensure crews, kiosks, stalls, and props support the district's purpose and scale.
- Avoid cluttering every surface; preserve readable silhouettes and calm areas.

## Phase 6 — Signature environmental set pieces
Develop the two remaining reference concepts as integrated environmental landmarks, not disconnected content drops:

### A. Multi-lane elevated highway / megablock corridor (reference around 375s)
- Create a convincing multi-level transport corridor between dense megablocks.
- Include clear lane hierarchy, overhead signs, supports, maintenance access, lighting, and believable connections to buildings.
- Establish scale through traffic/vehicles if already supported, distant parallel infrastructure, and visible depth.
- Make it readable from a long-distance vista and from player-level traversal.

### B. Giant misty glass/grid facade wall along a terrace edge (reference around 400s)
- Create a massive glass/grid facade that functions as a memorable landmark and a believable architectural element.
- Use controlled grid rhythm, structural framing, atmospheric depth, and subtle interior/reflective variation.
- Avoid a flat texture wall or a uniformly glowing panel.
- Integrate it into the terrace and surrounding skyline so it has a clear purpose and silhouette.

Before implementation, verify the exact reference frames and project context. Keep the scale and composition faithful to the source inspiration without copying unrelated details.

## Phase 7 — World cohesion and traversal review
- Revisit all existing routes after environment changes: bridge, service bypass, elevator, district transitions, Hydroponics, Preserve, and Planet View.
- Check that the player always understands where they are, where they can go, and what the main visual destination is.
- Make route transitions feel intentional through architecture, lighting, signage, and spatial composition.
- Ensure the 41 km elevator remains a defining vertical experience and the exterior routes communicate horizontal scale.
- Verify environmental landmarks are visible from appropriate routes and not accidentally occluded.
- Check for visual discontinuities, mismatched scale, sudden material changes, and procedural seams.

## Phase 8 — Inter-Stack Express concept/design (design first; implementation later)
Do not build a full train system during the environment polish phase unless the audit proves it is needed for a specific environmental test. First produce a compact design proposal:
- A colossal inter-stack train/viaduct as the horizontal counterpart to the 41 km elevator.
- A journey with a departure portal, exposed chasm crossing, distant parallel traffic/infrastructure, an approaching stack, and a monumental arrival portal.
- A multi-car train with a safe observation area or walkable passenger section only if compatible with existing rider/interpolation systems.
- A plausible route length and pacing that communicates distance without wasting the player's time.
- Opportunities to integrate the highway and glass-grid facade landmarks.
- Reuse existing TRAM-077 and BR-077-A where sensible; do not assume they must be replaced.
- Provide a scope estimate, technical risks, and a minimal prototype plan. Wait for approval before implementation.

## Phase 9 — Final quality gate and updated review tour
- Capture matching baseline views for before/after comparison.
- Record an updated review tour covering Planet View, major exterior vistas, district transitions, highway, glass facade, elevator, Hydroponics, Preserve, and existing traversal.
- Verify visual stability at different camera speeds, distances, and refresh rates.
- Check LOD transitions, z-fighting, seams, flicker, clipping, collision/traversal issues, and asset loading.
- Compare performance/memory against baseline and report any regression.
- Produce a final report: completed changes, screenshots/tour, changed files, performance impact, known issues, and recommended next step.

## Definition of done
- Major environments have distinct identity and strong composition.
- The world reads clearly at macro, meso, and micro scales.
- Procedural repetition is reduced through intentional, bounded variation.
- Lighting and atmosphere support scale without destroying readability or darkness.
- Infrastructure is functionally coherent and supports environmental storytelling.
- The two reference landmarks feel integrated into the world.
- Existing traversal, rendering stability, elevator, and Planet View remain intact.
- Performance is measured and any regressions are explained.
- A new review tour demonstrates the improvement.

## Execution instruction
Start with Phase 0 only. Return the audit, prioritized issues, baseline evidence, and a proposed Phase 1 plan. Do not begin broad implementation until the audit is reviewed. Then proceed phase by phase, keeping changes focused and reversible.
