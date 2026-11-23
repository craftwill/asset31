# Steam Cloud saves (Auto-Cloud)

Asset31 uses **Steam Auto-Cloud**: the Steam client syncs the save file itself when the game
launches and exits. The game has no Steamworks SDK, no GodotSteam, and no code that talks to Steam.

> **Status (2026-11-23):** the game side is done. The Steamworks settings below are **not configured yet**,
> so nothing syncs until they are set and published.

## What the game guarantees
- **Fixed location.** `project.godot` pins `user://` to a custom dir (`application/config/custom_user_dir_name="Asset31"`):

  | OS | Save path |
  |---|---|
  | Windows (and Proton) | `%APPDATA%\Asset31\asset31_save.json` |
  | Linux (native, if ever shipped) | `~/.local/share/Asset31/asset31_save.json` |
  | macOS (if ever shipped) | `~/Library/Application Support/Asset31/asset31_save.json` |

- **One file.** There is only one save file, `asset31_save.json`, about 7 KB. Godot also writes `logs/`, `shader_cache/` and `vulkan/`
  into the same folder, so the cloud pattern names the save file exactly. The `--selftest` save
  (`asset31_selftest_save.json`) and the temp file are excluded by that exact pattern.
- **Atomic writes.** `main.gd::_save` writes `asset31_save.json.tmp` and then renames it over the
  real file. A crash mid-write can't leave a truncated save for Steam to upload.
- **Migration.** On startup, if there is no save in the new folder, `_migrate_legacy_save` copies one from the old
  default dir (`%APPDATA%\Godot\app_userdata\Asset31\`). The old file is left in place.

Don't rename `SAVE_PATH`, `custom_user_dir_name`, or the save filename without updating
the Steamworks settings below. If you do, players' cloud saves silently stop matching.

## Steamworks partner site setup
App Admin → **Steam Cloud**:

1. **Byte quota per user:** `1048576` (1 MB is plenty). **Number of files per user:** `4`.
2. Enable **Auto-Cloud**, then add a root path:

   | Root | Subdirectory | Pattern | OS | Recursive |
   |---|---|---|---|---|
   | `WinAppDataRoaming` | `Asset31` | `asset31_save.json` | Windows | No |

3. Only if a native Linux/macOS build ships later, add **Root Overrides** for root `WinAppDataRoaming`:
   - OS `Linux` → new root `LinuxXdgDataHome`
   - OS `macOS` → new root `MacAppSupport`

   Leave the path unchanged in both. The Windows build running under Proton or on Steam Deck needs no override.
4. Save, then **Publish** the change (Publishing tab). Steam Cloud settings don't take effect until you publish.

## Testing
1. Launch through the Steam client, press F5, then quit.
2. Check the file at <https://store.steampowered.com/account/remotestorage> (log in, then pick Asset31).
3. On a second machine, or after deleting `%APPDATA%\Asset31\asset31_save.json`, launch via Steam and press F9.
4. To test a conflict, save on two machines while offline. Steam shows its own conflict dialog at launch.

Sync happens only at launch and exit, so F5 during play is unaffected. Launching the exe directly
(outside Steam) still saves locally; that save syncs the next time the game runs through Steam.

## When to switch to the SDK
If you later need in-game cloud status, multiple save slots chosen at runtime, or achievements,
add GodotSteam and `ISteamRemoteStorage`. Until then, Auto-Cloud is the simpler and safer choice.
