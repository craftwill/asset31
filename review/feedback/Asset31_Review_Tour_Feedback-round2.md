# Asset31 — Review Tour Feedback

## Overall impression

Asset31 is beginning to communicate its identity through the actual playable space. The tour moves from a small, personal shelter into an inhabited street, then opens onto the immense city and eventually reaches the edge of the stack and a neighbouring structure.

That progression is the strongest part of the current experience: the player starts somewhere familiar, gradually understands the scale around them, and is given a distant place worth travelling toward.

The project should continue to pursue a faithful recreation of the visual references. The feedback below is about strengthening what is already present, not redesigning the art direction.

## What is working

### 1. The home shelter

The small shelter is an effective starting point. Its enclosed, modest scale contrasts with the overwhelming world outside and gives the player a personal place within the Mantle.

**Keep:** the intimate scale, dim lighting, and sense of shelter.

### 2. The market street

The market street gives the city signs of ordinary life. Illuminated storefronts and the street layout make it feel inhabited rather than like an empty architectural showcase.

**Keep:** the everyday, lived-in feeling. Small details of use and occupancy can strengthen this without cluttering the scene.

### 3. The rooftop vista

The rooftop view is one of the tour's strongest visual moments. The immense spread of lights makes the city feel far larger than the immediate playable area.

**Keep:** this kind of viewpoint as a major exploration reward. The player should be able to pause and absorb the scale.

### 4. The foundry hall

The foundry hall has a strong industrial mood: deep shadows, warm orange illumination, haze, and a huge interior volume. It feels appropriately imposing for the Mantle.

**Keep:** the dark, warm industrial atmosphere and the sense that the space continues far beyond the player's immediate surroundings.

### 5. The stack edge and bridge

The stack edge is where the premise becomes especially tangible. The player can look across the gap and understand that another structure exists beyond the one they currently inhabit.

The bridge and route toward the neighbouring stack create a clear reason to explore outward.

**Keep:** distant structures as visible destinations, with a physical route that makes the journey feel real.

### 6. Arrival at the neighbouring stack

The arrival provides a satisfying payoff. It reinforces that the structures belong to a connected world rather than being isolated levels.

**Keep:** the sense of having travelled somewhere genuinely different in position, even if the visual language remains consistent.

## Recommended polish

### 1. Make long-distance navigation readable

The bridge and long route should have occasional structural landmarks, silhouettes, or restrained lights that help the player maintain orientation.

Avoid turning the route into a brightly marked game path. The goal is subtle guidance that preserves mystery and scale.

### 2. Preserve darkness while supporting movement

Some of the industrial and transition spaces are extremely dark. That is part of the intended mood, but players still need to read the floor, openings, and route ahead.

Consider localized practical lights, subtle reflected illumination, or slightly clearer contrast at important traversal points. Avoid broadly raising the exposure or flattening the atmosphere.

### 3. Maintain the home-to-vista contrast

The shelter followed by the enormous rooftop view is a strong emotional sequence. Keep the small personal space and the vast city in deliberate contrast.

### 4. Improve distant-light stability

The city contains a very large number of tiny lights. During movement, these can be vulnerable to shimmer, crawling pixels, flicker, or depth instability.

Prioritize:
- reducing z-fighting and overlapping surfaces;
- improving depth precision for distant geometry;
- stable placement of repeated lights and structures;
- careful LOD transitions that do not visibly pop or shift;
- restrained bloom so individual lights remain distinct.

This is especially important for comfort during long sessions. The intent is to preserve the reference appearance while making it stable and less tiring to look at.

### 5. Keep the architecture from reading as a repeated pattern

The current repeated building forms help establish the scale quickly. Over time, variation in height, spacing, silhouette, gaps, and layering can make the city feel more physically extensive.

This should be achieved within the reference's existing architectural style—not by introducing a new art direction.

### 6. Keep the bridge and neighbouring stack as a meaningful journey

The neighbouring structure is a compelling destination. Give the route enough landmarks and environmental changes to feel like a journey, but avoid padding it with empty distance.

The player should feel that the trip is difficult and substantial, yet physically possible and worth completing.

## Priority order

1. **Rendering stability and eye comfort:** z-fighting, distant-light shimmer, depth precision, and LOD stability.
2. **Traversal readability:** make the bridge, stack edge, and route ahead understandable without over-guiding.
3. **Atmospheric readability:** preserve darkness while making essential paths and surfaces legible.
4. **Environmental depth:** add controlled variation and layering to distant city silhouettes.
5. **Small lived-in details:** strengthen the sense that people occupy and use the Mantle.

## Direction to preserve

- Recreate the video references as faithfully as possible: visual style, composition, architecture, scale, lighting, and atmosphere.
- The one intentional visual correction is reducing z-fighting and related rendering instability that may tire the eyes.
- Do not make the world brighter, busier, more colorful, or more conventionally cinematic just to make it look polished.
- The world should feel immense because of its actual spatial relationships, not because of a fake horizon or disconnected backdrop.
- Keep the player's route connected to the visible world wherever possible.

## Final assessment

The review tour has a strong foundation. The home shelter, market, rooftop vista, foundry, stack edge, and neighbouring-stack arrival form a compelling sequence that communicates both daily life and monumental scale.

The next step is not to add more spectacle. It is to make the existing spectacle more stable, navigable, and convincing—while staying faithful to the references.

**Asset31 should feel like a real place inside the Mantle: vast, dark, inhabited, and physically connected.**
