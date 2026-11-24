# Stack 2 (STK-0413) exploration design

The user's design direction for the blue twin stack, recorded 2026-11-24. This is the
authority for what goes where in STK-0413; where it and the older briefs disagree about
stack 2, this wins.

## The principle

Exploration is driven by distance and surprise. The player keeps walking, for tens of
minutes if need be, until they find something truly new that they never thought could be
there. The walk itself has to be worth taking, and the thing at the end has to be worth
the walk.

What already works, and why (the user's own examples):

- **Stack 1, first walk:** home, then the stores, then the car street. Each leg ends in a
  place that looks nothing like the last one.
- **The 3 km bridge:** very long and still fun to walk, and the quick travel back to
  stack 1 afterwards feels earned.
- **The 41 km descent:** a huge commitment with a real reward at the bottom.

Where it stops working: **arriving at stack 2**. It is not evident what should pull the
player onward. Everything below exists to fix that.

## The stack 2 journey, in order

1. **Arrival.** The player comes off the bridge and checks the express train.
2. **Decides to keep walking into stack 2.** They can see the white-lit new glass
   buildings (Glass Curtain Terrace 413-S) from the arrival side.
3. **Walking past the glass, they find the open rooms**: the enterable ground-floor
   interiors of the residential area.
4. **They keep walking down the residential area for a while.**
5. **The abandoned, unpowered extremities.** Barren, and a very long walk. Reference
   577s: tall dead facades, one lamp every hundred metres, wet paving, haze.
6. **Even further: the blue-fog extremities.** Buildings that were never finished, bare
   steel only. People use the pipe to warm up. Reference 581s to 597s. This place is
   huge; the player must never be able to see all of it at once.
7. **Squatters.** The player sees them and avoids them.
8. **The complete extremity: the void.** This side of the stack was never closed, so
   there is no tall outer wall and the floor simply ends at the gap between stacks. The
   blue fog hides the other stacks from a distance; only at the edge does the player see
   the horizon and the other stacks far away.
9. **A vertical elevator** takes the player from there to the **top floor, which is
   super frozen**.
10. **Later: the hydroponics and the garden.**

## Rules that follow from it

- **Hydroponics and the gardens must not be shown on arrival in stack 2.** They are a
  later reward: either a different stack, or an upper floor of stack 2 reached after the
  frozen top floor. They should not sit beside the arrival gate.
- **A faint light at the end of the long corridor.** From the residential area the player
  should be able to see a faint, far-off light down the long axis toward the extremities,
  so they know there is something to walk toward. It leads them into the new zones.
- **Keep the squatter content already built** (the bare-frame works with camps and barrel
  fires). It reads as a place where hobos live around their fires. It is secondary to the
  journey above.
- **Scale is the point.** The extremities are sized so that crossing them takes real
  time. Do not shrink them to make them convenient.
- **Each leg must look unlike the previous one**: white glass, warm residential rooms,
  brown barren blocks, blue never-built steel, black void, frozen top floor, then green.

## Further direction given the same day

- **Lights die with distance.** The deeper into the abandoned blocks, the fewer lit
  windows; past a certain point the street posts still stand but none is lit. Then the
  blue fog.
- **An empty gap before the steel.** Between the edge of the abandoned city and the
  first unbuilt frames there is a big empty space: the player walks a long time, sees
  the frames start to appear, and can look back at how tiny the abandoned buildings
  have become. Then normal generation resumes up to the void.
- **More empty space between the frames** in the fog area.
- **Sound follows the same curve.** Wind drops and the ambience turns more ominous the
  further into the unpowered blocks; in the blue fog it changes completely and is hard
  to bear, but must feel void, not full.
- **Particles** in the blue fog should suit it (not the warm dust of the lit city).
- **The floor change** into the blue plates should look natural, not a ruled line.
- **The pipe must be crossable**: a plank every kilometre or so, plus a proper crossing.
- **From the void edge the player should see one or two stacks** in the distance.
- **The guiding light must be subtle.** The player should not feel led.
- **Clock:** real time (one second is one second), a day runs 00:00:00 to 24:39:35, and
  the time is only visible in the inventory.

## State of the build against this list (v12 test build)

| Step | State |
|---|---|
| 1-2 Arrival, train, glass terrace | Existing content. The arrival sign now points to the express and the residential blocks. |
| 3-4 Open rooms, residential walk | Built: enterable rooms city-wide, dense in district `D-0413-DEEP`; canal and terrace steps nearby. The garden court was removed from the walk (`world/sites/garden_site.gd` is kept for later use). |
| 5 Barren blocks | Built: band `D-0413-BARREN`, z 1000 to 1750, full width. Lit windows and working lamps thin out with depth, then stop. |
| Empty plain | Built: z 1750 to 2350, bare blue plates, thinner fog (`plain` mood) so the city reads small behind. |
| 6 Blue never-built zone, the pipe | Built: frames from z 2350 in loose clumps, Return Line 413-S along z 2562.5, a steel step-over on the x = -1375 axis and plank crossings about every kilometre. |
| 7 Squatters | Partly: people warm themselves along the pipe; the bare-frame squatter works sits on the town side, one block west of the long axis. Nothing yet makes the player want to avoid them. |
| 8 Void edge | Built: south wall removed (`"open_sides": ["+z"]`), fog thins at the brink (`brink` mood), two distant stacks on the horizon (STK-0415, STK-0418). |
| 9 Elevator to the frozen top floor | Built: Brink Lift `EL-0413-S` on a pier past the edge, 18.1 km in about 132 s, to `FLOOR-0413-TOP` at 59,100 m (`world/frozen_floor.gd`): white-out, snow, marker posts, two heated huts. |
| 10 Hydroponics and garden as a later reward | Built: Hydroponic Bay 413-A and Preserve 413-B now sit on the top floor (site `"level": 18100`), at the end of the marked frozen walk. |
| Faint guiding light | Built, deliberately subtle: a dim point high on the lift mast on the axis of the long street, fading further as you approach. |
