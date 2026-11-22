# ASSET31

## Vertical Slice Implementation Brief for an Autonomous Development Agent

**Project vision, technical direction, implementation scope, and
acceptance criteria**

------------------------------------------------------------------------

## 0. Mission

Implement a **high-quality, playable vertical slice** that faithfully
recreates the supplied video references as a playable world. The defining
promise of *Asset31* is:

> The player inhabits a genuinely enormous, continuous artificial
> civilization. The world they see is real, physically located, and
> potentially reachable. Distance and danger make remote places
> difficult---not fake, inaccessible set dressing.

This is a faithful reconstruction project, not a loose adaptation or
visual inspiration exercise. The video references are the authoritative
source for the world’s appearance and atmosphere. Recreate their
architecture, spatial arrangement, proportions, density, lighting,
color, camera composition, materials, and environmental mood as closely
as the playable implementation allows. Do not redesign, stylize,
modernize, simplify for taste, or introduce a different art direction.
Build only the amount of playable content needed for the vertical slice,
but what is built must match the references—not merely evoke them.

The slice must establish: 1. A true-scale stack/floor environment with
credible large-world handling. 2. A faithful recreation of the actual
reference imagery, including its defining stack forms, scale,
architecture, density, and vistas. 3. A continuous, physically
connected route from the playable area toward/into the neighboring
stack. 4. A journey that can be attempted for a long time and is hard
due to distance, route, exposure, and preparation---not an invisible
wall or scripted level transition. 5. The same visual atmosphere and
presentation as the references. 6. A first-person survival/exploration
foundation with simple looting and Tarkov-like grid inventory
interaction, without overbuilding content. 7. A playable environment
that reproduces the reference locations and their residential,
industrial, unfinished/maintenance, and stack-edge character.

**Do not dilute the project into a generic survival game.** The
megastructure and the feeling of inhabiting it are the product.
Survival, inventory, and scavenging support that fantasy.

------------------------------------------------------------------------

## 0.1 Canon setting: Asset 31 / the Mantle

The project is titled **Asset31**. The planet's official designation is **Asset 31**; people who live inside the structure commonly call it **the Mantle**.

The Mantle's steel roofs are approximately **60 kilometres above the planet's original surface**. The planet beneath the structure is not a void or an artificial floor: it is a real, fully covered planetary surface, buried under the accumulated megastructure.

The civilization continually mines deeper into the planetary surface to obtain steel for further construction. The extracted material is used to build more structures above, while the remaining planet becomes progressively thinner from the inside. This is a defining part of the setting: the Mantle is expanding by consuming the world it covers.

Workers travel down from the Mantle to the mining surface by elevator. Elevators are therefore major physical connections between inhabited upper structures and the increasingly excavated planet below. Their shafts, landings, machinery, and journeys should feel immense and consequential.

Keep these facts consistent in all worldbuilding, level layout, environmental storytelling, signage, and implementation. Do not portray the planet beneath the Mantle as empty space, a separate unrelated world, or a conventional underground cave system. The exact geology, mining process, and deeper planetary conditions are not yet specified; do not invent definitive lore for them unless necessary, and keep any implementation assumptions easy to revise.

## 1. Vision and non-negotiable principles

### 1.0 Reference fidelity is the project vision

The supplied video and extracted reference frames are the visual source
of truth. The goal is to recreate the world shown in them 1:1 as a real-time,
explorable game, allowing only unavoidable technical translation from
video to interactive 3D. Treat the references as
a target to reproduce, not a mood board or loose inspiration.

Match the visible architecture, silhouette, scale relationships,
structural layout, density, lighting, palette, fog, contrast,
composition, and ambience. When a choice is not shown in the references, make the smallest
practical assumption necessary to make the world playable, and keep it
consistent with the visible reference. Do not invent new visual
features, landmarks, architecture, color schemes, or stylistic details
that are not supported by the references. Gameplay features must be integrated discreetly and must not visually redesign the referenced world.

**The only intentional change to the reference visuals is reducing
z-fighting and related depth-rendering artifacts that can cause eye
strain.** Correct the underlying technical causes—such as overlapping
faces, coplanar surfaces, depth precision, z-buffer configuration,
geometry placement, or suitable depth techniques—while preserving the
original surfaces, silhouettes, lighting, and composition. Do not use
this as permission to alter the art direction.


### 1.1 The megastructure is the world, not a backdrop

The world consists of colossal stacks and floors: vast regions of city,
infrastructure, agriculture, industry, and unfinished development
contained within an artificial structure. A floor is a geographic
region, not a conventional game level. It can contain multiple districts
and environments.

The slice only needs one developed floor/region and a glimpse of the
next, but the underlying world model must support adding further regions
later without redesigning the core.

### 1.2 Visible places are real places

A distant stack, tower, bridge, shaft, or city silhouette must
correspond to a location in the same world coordinate system. It must
not be a skybox painting, an unrelated impostor that swaps to a
different map, or a decorative object with no physical destination.

Distant rendering may use simplified geometry and LOD. That is an
optimization, not a change in world identity. As the player approaches,
simplified representations must resolve into the same structures at
higher detail and remain in the same spatial location.

### 1.3 Difficult, not impossible

The player may choose to travel for hours toward another stack. The
route can be arduous, dangerous, confusing, and resource-intensive. It
must remain possible through continuous world traversal and/or real
in-world transport that connects to the same destination.

No invisible boundary should be used to make the neighboring stack
unreachable. Do not fake distance by endlessly moving landmarks,
teleporting the player, or swapping to a disconnected scene that breaks
spatial continuity.

A vertical slice does not have to make the full journey convenient or
complete every remote district. It must demonstrate a genuine route,
show that the route is physically connected, and make the player able to
begin and continue the expedition.

### 1.4 The world should be mysterious, not empty

The player should see more than they can immediately understand. Use
scale, occlusion, lighting, architecture, sound, distant movement,
signage, and infrastructure to imply a functioning civilization beyond
the explored area.

Do not fill the world with random props just to make it busy. A few
deliberate, readable landmarks are more effective than noisy detail.

### 1.5 Final ambience now; content later

The slice should already look and sound like the intended release. Do
not use a bright greybox, temporary default materials, placeholder sky,
generic ambient loop, or debug UI as the final presentation.

Temporary assets may be used during implementation, but replace them in
the final slice with coherent authored materials, lighting, fog, sound,
and composition. Keep the quantity of content small.

------------------------------------------------------------------------

## 2. Vertical slice definition

### 2.1 Player experience

The player starts in a modest residential district inside a gigantic
stack. The first moments communicate ordinary human scale against
colossal architecture. They can leave their shelter, walk through
streets and buildings, inspect lootable containers, collect a few
supplies, and look toward the enormous industrial city around them.

From a meaningful viewpoint, the player sees: - Their home stack
continuing far beyond the immediate district. - The immense interior
volume and distant structural ceiling/curvature. - A neighboring stack
across a vast gap or intervening infrastructure. - A visible
route---bridge, freight line, maintenance platform, elevator network, or
combination---leading toward the neighboring stack. - Distant lights,
machinery, and signs of life, without explaining everything.

The player can set out toward the neighboring stack. Travel should feel
genuinely long. The route contains a small number of authored landmarks
and one or two meaningful hazards or resource decisions. A player may
turn back, shelter, or continue. The neighboring stack should be
physically reachable within the prototype world, even if the trip takes
substantial real time.

### 2.2 Required playable spaces

Build a compact but spatially ambitious slice with these zones:

**A. Home/residential pocket** - A safe-ish starting point, one small
interior, one street/alley, and a few believable residential façades. -
Human-scale details contrasted against huge structures. - At least one
lootable container and a readable route outward.

**B. Colossal urban/industrial vista** - A carefully composed view where
the stack's scale is unmistakable. - Multiple depth layers: foreground
architecture, mid-distance blocks, distant structures, and the far
interior. - Large vertical elements, repeating structural rhythm,
bridges/rails/pipes, and tiny scale references (lights, windows, people
or silhouettes). - No false horizon; geometry and world coordinates must
agree with the view.

**C. Industrial/maintenance transition** - A route that leaves the
developed district and exposes the underlying infrastructure. - Large
machinery, service platforms, freight access, ventilation, cables, and
structural supports. - Traversable paths with clear navigation cues, not
a maze of arbitrary invisible blockers.

**D. Stack edge / inter-stack route** - A real transition area that
communicates the distance and danger between stacks. - The neighboring
stack is visible before the player reaches it. - A continuous route or
in-world transport connects the two. It may be narrow, elevated, slow,
partially exposed, or require a key/repair/resource, but it must not be
a fake boundary. - At least one place where the player can stop and look
back at the stack they came from.

**E. Neighboring stack arrival** - A small arrival landmark or first
district proving the destination is part of the same world. - It may be
minimally populated and content-light. The purpose is to prove
continuity and scale, not to create a second complete biome.

### 2.3 Content quantity

Keep content intentionally sparse: - One home district. - One
industrial/maintenance route. - One stack edge and inter-stack
connection. - One small destination pocket in the neighboring stack. - A
few interiors and loot points. - A tiny item set. - No campaign,
questline, crafting tree, faction simulation, procedural city generator,
or extensive combat roster in this milestone.

------------------------------------------------------------------------

## 3. Scale and spatial truth

### 3.1 Establish scale before art production

Do not choose arbitrary sizes independently for each asset. Create a
scale sheet first: - Player height and movement speed. - Typical door,
room, street, building, and vehicle dimensions. - Representative
stack/floor dimensions. - Distances between major landmarks. - Height of
the ceiling/inner surface. - Distance and route length to the
neighboring stack.

Use real-world-like units consistently. In Godot, conventionally treat
one world unit as one meter unless the existing project already uses
another documented convention. Record the decision in the project.

The stack should be so large that the player cannot comprehend it from
one viewpoint. Use a coherent set of measurements rather than claiming a
scale that the scene does not support.

### 3.2 A scale ladder

Create a small set of authored scale references: 1. A person or
human-sized prop. 2. A doorway and room. 3. A residential building. 4. A
city block. 5. A large industrial structure. 6. A major stack landmark.
7. The neighboring stack. 8. The visible ceiling/interior curvature.

These references must agree mathematically. Use a debug scale overlay or
measurement tool during development, then remove it from the final
presentation.

### 3.3 Geometry and distant representation

Use a hierarchical representation: - Near: detailed meshes, collision,
interaction, interior access. - Mid: simplified meshes and material
variants, no unnecessary collision. - Far: low-cost but actual 3D
geometry or a deterministic proxy derived from the same source layout. -
Very far: conservative simplified structure, still anchored to the
correct position and silhouette.

Distant structures must not slide, resize, or pop into unrelated
locations. Use stable LOD thresholds, cross-fades/dither where
practical, and test from multiple approach angles.

### 3.4 Continuous world and large-world coordinates

Design for large distances from the start: - Use sector/chunk
coordinates plus local coordinates, or an equivalent robust large-world
scheme. - Avoid relying on a single float position for arbitrarily large
distances. - Implement origin rebasing/coordinate shifting if required
by the engine and target scale. - Keep physics and interaction
calculations local to the active region. - Preserve stable global
identities/coordinates for landmarks and streamed regions. - Ensure
save/load stores logical world coordinates, not only current rebased
transforms.

If the chosen engine's standard transform precision is insufficient for
the planned scale, implement and test the coordinate strategy before
building extensive content. Do not postpone this until the world is
already populated.

### 3.5 Streaming

Implement region streaming around the player: - Load detailed geometry,
collision, and interactive objects near the player. - Keep visible
distant structures in simplified form. - Unload or pool inactive detail
without changing the world layout. - Use deterministic generation or
authored sector data so revisiting a region yields the same structure. -
Avoid streaming gaps, sudden empty horizons, or visible loading seams
during ordinary traversal. - Do not load every building interior or
every physics body at once.

For the slice, a modest authored region with a working streaming
boundary is sufficient. Architecture must allow expansion.

### 3.6 No artificial travel shortcuts

Do not: - Teleport the player to the neighboring stack. - Replace a long
route with a loading screen while claiming it is continuous. - Make a
distant stack approach infinitely or move toward the player. - Use a
skybox for a destination that is advertised as reachable. - Place
invisible walls across the intended route.

If a real in-world elevator, train, or cargo transport is used, its
endpoint must exist at the destination, and the journey should preserve
the sense of distance and scale. A loading optimization may be
acceptable only if it preserves position, orientation, continuity, and
is not used to fake a shorter world.

------------------------------------------------------------------------

## 4. Floors and stacks: reusable world model

### 4.1 Floor identity

A floor is a huge region with a purpose and a mixture of districts. It
is not a separate level or uniform biome.

The architecture should support floor types such as: - Residential and
mixed urban. - Industrial. - Agricultural. -
Commercial/administrative. - Unfinished construction. -
Maintenance/infrastructure.

Only representative pieces of residential, industrial, unfinished, and
maintenance areas are required in this slice.

### 4.2 Stack identity

A stack is a large structural grouping containing multiple
floors/regions and vertical connections. A stack should have: - A stable
ID. - A spatial origin and bounds. - A floor/region list. - Landmark
definitions. - Connection points to other stacks. - LOD
representations. - Optional future metadata for population, ownership,
condition, and history.

### 4.3 Connections

Connections are world objects, not menu destinations: - Bridge. -
Freight elevator. - Maintenance tunnel. - Rail or cargo route. -
Stair/service shaft. - Platform network.

A connection has endpoints, route geometry, travel constraints, and
state (open, damaged, blocked by a real condition, etc.). It should be
possible to inspect or discover a route and understand why it is
difficult.

Do not build a generic fast-travel system in this milestone. The
connection system may later support transport, but for now it should
prove physical traversal.

------------------------------------------------------------------------

## 5. Visual direction: final-intent ambience

### 5.1 Visual target

Recreate the reference video 1:1. Match its actual visuals, not only
its mood or spatial language. Rebuild the referenced environments as
faithful in-game geometry and materials; do not create a new scene that
merely feels similar. Do not add or change visual elements except to
correct z-fighting/depth artifacts while preserving the reference look: - Dark, ominous, industrial, mysterious. -
Enormous dense architecture. - Warm amber/orange practical lights
against deep shadows. - Occasional cooler or colored
industrial/agricultural lighting. - High contrast between illuminated
human-scale spaces and immense dark volume. - Atmospheric depth that
reveals scale without washing out the image. - Repetition and density,
with deliberate large silhouettes.

The player should feel surrounded by civilization and machinery, yet
small and isolated.

### 5.2 Lighting

Build lighting as a system: - Practical lights embedded in buildings and
infrastructure. - Strong pools of warm light with dark transitions. -
Distant light clusters that communicate populated areas. - Limited large
lights used to reveal major forms. - Controlled volumetric fog or
equivalent atmospheric scattering. - Shadows that preserve readability
without requiring every distant object to cast a real-time shadow.

Avoid uniform brightness, generic blue sci-fi lighting everywhere,
excessive bloom, or an overlit game-engine demo look.

### 5.3 Materials and surface language

Create a coherent material family: - Aged metal, concrete, dark
structural alloys, glass, painted panels, grime, worn flooring. -
Repeated modular architectural patterns. - Subtle roughness and wear at
human scale. - Large-scale materials should read from a distance and not
become noisy. - Avoid high-frequency texture clutter on every surface.

Use a restrained palette. Warm industrial lights should be the main
visual signature; use other colors sparingly to distinguish functions or
regions.

### 5.4 Architecture and composition

Recreate the architecture visible in the references as faithfully as
possible. Match its forms, proportions, placement, repetition, density,
and composition. The architecture must communicate scale: - Huge vertical supports and
beams. - Repeating windows and structural bays. - Multi-level streets
and elevated infrastructure. - Bridges, rails, pipes, and service
platforms. - Deep views through structural openings. - Overhead
structures and distant interior surfaces.

Use foreground framing and small scale references. Do not rely solely on
fog to hide a small world.

### 5.5 Atmosphere and visibility

Fog should create depth, not conceal missing world geometry. Tune it
so: - Near navigation remains clear. - Mid-distance structures remain
legible. - Far structures become atmospheric but maintain correct
silhouettes. - The neighboring stack is recognizable from designated
viewpoints. - Visibility changes feel consistent with lighting and
distance.

The player must be able to understand where they are going. Mystery
should come from incomplete knowledge, not unreadable visual noise.

### 5.6 Z-fighting and visual comfort

The reference image is the target. Reduce distracting z-fighting,
shimmering coplanar surfaces, depth flicker, and unstable overlapping
geometry because these artifacts can tire the eyes. Fix them at their
source wherever possible: remove duplicate/overlapping faces, correct
surface offsets, improve depth precision and camera near/far settings,
use appropriate depth-buffer techniques, and ensure LODs do not overlap
incorrectly. Do not hide the problem by changing the reference
architecture, deleting important visible detail, flattening the scene,
or changing the composition. Validate from the same viewpoints as the
reference frames and during movement.

### 5.7 Final-quality bar

Before calling the slice complete: - The scene is recognizably a
faithful recreation of the supplied reference frames, not a merely
similar interpretation. - No distracting z-fighting or depth flicker
remains in the hero views. - No default materials or obvious
greybox surfaces in the hero path. - No placeholder sky or flat fog
plane. - No repetitive asset placement that looks like a test grid. - No
abrupt lighting changes at chunk boundaries. - No visible LOD snapping
in the primary vista. - No major collision mismatch. - The residential
pocket, vista, and stack-edge route must all feel like parts of one
authored world.

------------------------------------------------------------------------

## 6. Sound and ambience

The audio is a core part of the atmosphere, not a finishing task.

### 6.1 Ambient layers

Build a layered, spatial ambience: - Deep distant structural/mechanical
rumble. - Air movement and ventilation. - Occasional metallic resonance
or distant impacts. - Faraway machinery and transport. - Sparse signs of
human activity in developed areas. - Local room tone that changes when
entering buildings. - Exterior/industrial ambience that becomes more
exposed near the stack edge.

Avoid constant loud machinery, generic horror stingers, or an overly
busy soundscape.

### 6.2 Spatial behavior

Use distance, occlusion, and reverb: - Large spaces should have long,
subtle reflections. - Small interiors should sound enclosed. -
Industrial spaces should have distinct resonance. - Distant sources
should be felt more than clearly heard. - Moving between districts
should transition ambience gradually.

### 6.3 Music

Use minimal music or sparse ambient composition. The world ambience
should carry the experience. Music can emerge at rare moments of
discovery or scale, but should not constantly tell the player how to
feel.

### 6.4 Audio acceptance

The player should be able to stand still and hear that they are inside a
vast, functioning structure. The ambience should feel ominous and
mysterious without relying on jumpscares.

------------------------------------------------------------------------

## 7. First-person exploration and movement

Implement a stable, comfortable first-person controller: - Walking,
running, crouching if practical. - Sensible acceleration and stopping. -
Camera height consistent with human scale. - Subtle head motion only;
avoid exaggerated bob. - Clear interaction ray or equivalent. -
Collision that matches visible architecture. - Responsive movement on
stairs, ramps, platforms, and bridges.

Movement should feel grounded. The world is enormous; do not make the
player unrealistically fast merely to compensate for poor scale. If
faster movement is later needed, provide believable transport.

The player should be able to look up and down at huge structures without
camera discomfort. Avoid extreme forced camera tilt or motion effects.

------------------------------------------------------------------------

## 8. Survival and looting foundation

This slice should prove the intended survival interaction without
expanding into a full survival economy.

### 8.1 Lootable objects

Implement a small set of reusable loot containers: - Drawer/cabinet. -
Backpack or crate. - Shelf or storage box. - Corpse/container
placeholder with respectful, non-graphic presentation if needed.

Containers should be placed in a few believable locations: a residential
room, a maintenance area, and a risky route landmark.

### 8.2 Interaction

The player can: - Look at an object and receive a restrained interaction
prompt. - Open the container. - View its contents. - Transfer items into
their inventory. - Close it and continue exploring.

Interactions should be quick, readable, and not require a large UI
framework.

### 8.3 Inventory

Implement a Tarkov-inspired grid inventory foundation: - Items occupy
grid cells with dimensions. - Drag and drop between container and player
inventory. - Rotation may be supported if straightforward, but is not
required for the first acceptance pass. - Item stack sizes for simple
consumables. - Clear item icons and hover/selection feedback. - Basic
capacity constraints. - A small number of item categories: food/water,
medical, tool/material, and valuable scrap.

Do not implement dozens of items. A few distinct items are enough to
prove the system.

### 8.4 Survival pressure

Use minimal, readable survival needs: - Hunger and thirst, with slow
drain. - A simple health/injury state. - Food and water items that
restore needs. - Optional exposure/stamina only if it adds meaning to
the route.

The purpose is to make expeditions require preparation, not to force
constant meter maintenance. The player should have time to appreciate
the environment.

### 8.5 Combat

Combat is not a primary deliverable for this vertical slice. If an enemy
is included, use one simple hostile archetype or a clearly marked threat
zone to demonstrate that dangerous areas exist. Do not build a full AI
faction system, weapon roster, or complex combat loop.

Hostile inhabitants should not be represented as universally hostile
simply because they are poor or displaced. Future factions can have
distinct motives and behaviors.

------------------------------------------------------------------------

## 9. World navigation and mystery

The player should understand the immediate route but not the entire
megastructure.

Provide: - A few diegetic signs, markings, and service labels. - A
landmark visible from the home district. - A distant neighboring
stack. - A route that can be discovered and followed. - Occasional map
or navigation aid only if it fits the setting.

Do not use a conventional objective marker that constantly points to the
neighboring stack. Let the player observe, plan, and navigate.

A simple paper map, local terminal, signage, or route diagram may be
used. It should reveal practical information without explaining the
whole world.

The route should include one or two meaningful decisions: - Take a safer
but longer route. - Cross a more exposed section. - Search a shelter for
supplies. - Use a functioning transport system if discovered.

The player should be free to turn back. A successful expedition is not
defined only by reaching the destination.

------------------------------------------------------------------------

## 10. Technical implementation guidance

### 10.1 Engine and project

Use the existing project and engine if one is provided. Do not migrate
engines or replace project architecture without explicit approval.

If this is a new Godot 4.x project, use modular scenes and typed
GDScript or the project's established language conventions. Keep systems
decoupled and documented.

### 10.2 Suggested systems

Create clear modules for: - `WorldCoordinates` / large-world coordinate
utility. - `WorldRegion` / sector data and streaming. -
`StackDefinition` / stable stack metadata. - `FloorDefinition` / floor
region metadata. - `WorldConnection` / physical route between regions. -
`PlayerController`. - `InteractionSystem`. - `LootContainer`. -
`ItemDefinition`. - `InventoryGrid`. - `SurvivalComponent`. -
`AmbienceZone` / audio transition volumes. - `WorldLandmark` / stable
spatial identity and LOD. - Save/load of player and world state.

Names are suggestions; follow existing conventions where appropriate.

### 10.3 Data-driven content

Keep item definitions, landmarks, stack metadata, and connection data
separate from scene logic. Use resources, JSON, or the existing
project's data format.

The goal is to add future floors and stacks by authoring data and
scenes---not by rewriting core systems.

### 10.4 Performance

Set a performance target appropriate to the existing project and target
hardware. Profile early in the hero vista and while moving between
streamed regions.

Prioritize: - Instancing repeated architecture. - LOD and visibility
management. - Baked/static lighting where suitable. - Limited active
collision. - Pooling repeated props. - Avoiding hundreds of unique
materials. - Avoiding real-time shadows from every distant light. -
Loading only nearby interactive interiors.

Do not optimize by making the world fake or by removing distant
structures from the player's view.

### 10.5 Save/load

At minimum, persist: - Player world position and orientation. -
Inventory contents. - Survival values. - Opened/looted container
state. - Any route state required by the slice.

Store logical coordinates and stable object IDs so origin shifting and
streaming do not corrupt persistence.

------------------------------------------------------------------------

## 11. Implementation order

Work in this order. Do not jump into content expansion.

### Phase 1 --- Scale and world proof

1.  Inspect the existing project and report its engine, current
    architecture, and constraints.
2.  Establish the world-unit convention and scale sheet.
3.  Create a player controller and one large structural environment.
4.  Implement the large-world coordinate/streaming approach required by
    the target scale.
5.  Place a real neighboring stack at a known distance.
6.  Verify that the player can traverse toward it without a fake
    boundary.

**Exit condition:** a graybox proves physical scale, continuity, and
traversal. Do not polish content yet.

### Phase 2 --- Hero vista and final ambience

1.  Build the home district's main vista and composition.
2.  Author the final material family.
3.  Implement final-intent lighting, fog, and distant structure LOD.
4.  Build the industrial/maintenance transition and stack-edge route.
5.  Implement the final ambient audio layers and spatial transitions.
6.  Replace all visible greybox materials along the playable path.

**Exit condition:** standing still and looking around already feels like
the intended game. This phase is more important than adding gameplay
content.

### Phase 3 --- Traversal polish

1.  Add readable route landmarks.
2.  Tune movement and collision.
3.  Make the inter-stack route continuous and understandable.
4.  Test distant geometry from multiple viewpoints and during approach.
5.  Add shelter/stop points and one route decision.

**Exit condition:** a player can decide to travel far, understand the
challenge, and make meaningful progress.

### Phase 4 --- Minimal survival and looting

1.  Add a few lootable containers.
2.  Add a small item set.
3.  Implement the grid inventory and drag/drop transfer.
4.  Add hunger/thirst and usable supplies.
5.  Add one simple threat or hazardous section only if it supports the
    expedition.

**Exit condition:** the player can prepare, loot, manage supplies, and
return or continue.

### Phase 5 --- Validation and handoff

1.  Run the complete slice from a fresh start.
2.  Test traversal to the neighboring stack.
3.  Test save/load during and after the journey.
4.  Profile the hero vista and streaming.
5.  Remove debug UI and placeholder content.
6.  Document controls, architecture, known limitations, and next
    expansion points.

------------------------------------------------------------------------

## 12. Acceptance criteria

### Reference fidelity (highest priority)

- [ ] The supplied video frames are treated as the authoritative visual
    target throughout implementation.
- [ ] Major architecture, silhouettes, proportions, scale relationships,
    spatial arrangement, lighting, palette, atmosphere, and composition
    match the references as closely as practical.
- [ ] No alternate art direction, stylistic redesign, or unnecessary
    visual invention has been introduced.
- [ ] The only intentional visual correction is reducing z-fighting and
    related depth artifacts for visual comfort, without changing the
    referenced appearance.
- [ ] The agent compares the playable scene against the reference
    frames repeatedly and records any unavoidable deviations.


The vertical slice is complete only when all critical criteria pass.

### World and scale

-   [ ] The home stack reads as genuinely colossal from human-scale
    viewpoints.
-   [ ] The neighboring stack is visible from at least one authored
    viewpoint.
-   [ ] Distant structures correspond to real world positions and
    resolve into the same structures when approached.
-   [ ] The world uses a documented, consistent scale.
-   [ ] Large-world coordinates/streaming are tested at the intended
    distances.
-   [ ] The player can travel continuously toward the neighboring stack.
-   [ ] There is no invisible wall or fake horizon blocking the intended
    journey.
-   [ ] The neighboring stack has a physically connected route and a
    small reachable arrival area.

### Atmosphere and presentation

-   [ ] The final dark, ominous industrial visual style is present in
    the playable path.
-   [ ] Lighting, materials, fog, and distant architecture feel
    coherent.
-   [ ] The environment has layered, spatial ambience.
-   [ ] The residential, industrial, and stack-edge zones sound and look
    distinct.
-   [ ] No obvious greybox or default engine presentation remains in the
    hero path.
-   [ ] Scale is communicated by architecture and geometry, not only
    fog.

### Gameplay

-   [ ] First-person movement works reliably on all route surfaces.
-   [ ] The player can enter at least one interior.
-   [ ] The player can loot at least three container types or
    placements.
-   [ ] Items can be transferred through a functional grid inventory.
-   [ ] Basic hunger/thirst and consumables work.
-   [ ] The player can prepare for an expedition and make a meaningful
    choice about supplies.
-   [ ] The player can turn back without losing the sense of world
    continuity.

### Technical quality

-   [ ] Streaming does not create visible gaps or inconsistent geometry
    in the hero route.
-   [ ] LOD changes do not noticeably shift landmark positions or
    silhouettes.
-   [ ] Collision matches visible geometry.
-   [ ] Save/load preserves player location, inventory, survival values,
    and looted state.
-   [ ] Performance is measured and documented.
-   [ ] No critical errors or persistent warnings remain.

------------------------------------------------------------------------

## 13. Out of scope

Do not implement these unless explicitly requested after the slice: -
Multiple fully populated floors. - A complete procedural megastructure
generator. - Large quest/campaign systems. - Complex faction
simulation. - Full combat and weapon progression. - Extensive
crafting. - Economy simulation. - Multiplayer. - A large catalog of
loot. - Fully simulated distant populations. - A conventional
fast-travel menu. - A complete map of the megastructure.

These features may come later. They must not distract from proving the
world.

------------------------------------------------------------------------

## 14. Agent operating instructions

Before modifying files: 1. Inspect the repository and identify the
engine/version, entry scene, current architecture, asset pipeline, and
existing conventions. 2. Identify any current implementation that can be
preserved. 3. Write a short implementation plan with risks, especially
scale precision, streaming, and the true reachable neighboring stack. 4.
Do not overwrite or delete user work without understanding it. 5. Do not
introduce large dependencies without justification.

During implementation: - Work in small, verifiable milestones. - Keep
the project runnable after each milestone. - Prefer reusable systems
over one-off hacks. - Make the smallest amount of content needed to
prove each system. - Keep the visual quality bar high in the hero
path. - Do not silently substitute fake scale, skybox cities,
disconnected scenes, or inaccessible landmarks. - If an engine
limitation threatens the core promise, stop and explain the tradeoff
before compromising it.

At each milestone, report: - What was implemented. - How to run/test
it. - Which acceptance criteria now pass. - Known issues and next step.

At completion, provide: - A concise architecture overview. - Controls. -
A route walkthrough. - Performance measurements and test conditions. -
Known limitations. - Clear instructions for adding another floor or
stack.

------------------------------------------------------------------------

## 15. Final guiding statement

**Build a small amount of world, but make it feel like a tiny, genuinely
accessible part of something almost incomprehensibly large.**

The player should be able to stand in a dark residential street, look up
at the colossal structures around them, see another stack far away, and
know that---with enough time, preparation, and determination---they
could actually go there.

That feeling is the vertical slice.
