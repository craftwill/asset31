# Asset31 — Vertical Slice Package

This package contains the implementation brief and visual reference frames for a faithful, playable recreation of the world shown in the supplied video.

## Canon setting

**Asset31** is the project title and the planet's official designation is **Asset 31**. Inhabitants call the colossal structure **the Mantle**. Its steel roofs stand 60 kilometres above the planet's original surface. The surface is fully covered beneath the structure; workers descend by elevator to mine it for steel, which is used to expand the Mantle as the planet progressively becomes thinner from within.

## Contents

- `docs/Vertical_Slice_Implementation_Brief.md` — agent-facing vision, scope, architecture, implementation phases, and acceptance criteria.
- `reference_images/Video_Reference_Contact_Sheet.jpg` — overview of selected video stills.
- `reference_images/video_frames/` — individual extracted stills from the supplied reference video.
- `reference_images/README.md` — reference provenance and usage notes.

## Core target

Build a small, playable vertical slice that recreates the supplied video references 1:1 as closely as technically possible. The references are the authoritative visual target—not merely inspiration. The only intentional visual change is reducing z-fighting/depth flicker for visual comfort; do not redesign or add visual features. The slice must prove:
- true-scale, continuous megastructure world;
- visible distant structures that are real and reachable;
- a home district, industrial/maintenance transition, and physically connected route toward a neighboring stack;
- final-intent dark, ominous industrial ambience;
- first-person exploration, simple looting, grid inventory, and minimal survival foundations.

The world and atmosphere are the priority. Expand floors and content only after the slice proves its core promise.

## Recommended workflow

1. Read the implementation brief.
2. Inspect the reference contact sheet and individual frames.
3. Establish scale, coordinate strategy, and streaming before content expansion.
4. Build the graybox traversal proof.
5. Replace the hero path with final-intent art, lighting, fog, and sound.
6. Add minimal interaction and survival systems.
7. Validate against the acceptance criteria in the brief.
