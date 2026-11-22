# Asset31: vertical slice (Godot 4.6)

**Play the build:** `build/Asset31.exe` (next to this folder).

Run from source with Godot 4.6 (standard build):
```
"C:\Users\willi\Desktop\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_win64.exe" --path .
```
To rebuild the exe, run `--headless --path . --export-release "Windows Desktop" ../build/Asset31.exe`.
To regenerate the audio, run `--headless --path . --script res://tools/gen_audio.gd`.

## Controls
| Key | Action |
|---|---|
| WASD / mouse | move / look (click to capture the mouse, Esc releases it) |
| Shift / Ctrl / Space | sprint / crouch / jump |
| Stand on the lift for 1 s | ride to the roof or back down; it comes to whichever landing you wait at |
| F3 | dev overlay (logical coordinates, origin sector, region, distance to the neighbouring stack) |
| F5 / F9 | quick save / quick load (stores logical coordinates) |
| F6 | vertex snap: off / subtle / heavy |
| F7 | dither post-process on/off |

## The route
1. **Your room.** You wake in a one-room shelter on Floor 77 of stack STK-0412, 41 km above the buried planet surface.
2. **Side street to the market.** Go out the door and turn left down the side street to the market street.
3. **Optional roof detour.** The lift in the courtyard behind your block goes up to the roof.
4. **East along the avenue.** Head east past the pipe runs and through the foundry hall to the stack-edge gate, about 4.5 km.
5. **The bridge.** Cross the 3 km bridge over the gap, between the elevator shafts, to the arrival plaza of STK-0413.

The journey takes about 70 minutes walking or about 28 minutes sprinting.

See `docs/ARCHITECTURE.md`, `docs/SCALE_SHEET.md` and `docs/PHASE2_NOTES.md`.
