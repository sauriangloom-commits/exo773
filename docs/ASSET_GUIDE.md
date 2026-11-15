# Placeholder Asset and Replacement Guide

Final art and audio are out of scope. This guide defines what exists, where it is
drawn or played, and how to replace it without touching gameplay rules.

## Visual presentation contract

The game deliberately separates simulation from presentation:

- `src/game_state.gd` owns position, facing, party, flags, combat and saves.
- `src/ui/first_person_view.gd` only **reads** `Game.dungeon`, `Game.position` and
  `Game.facing` and draws the view. It does not mutate state.
- `src/ui/combat_view.gd` reads `Game.encounter` and emits `cell_clicked`; all
  resolution goes through `GameSession`/`Encounter`.
- `src/ui/exploration_screen.gd` and `combat_screen.gd` build the surrounding UI.

A replacement view can therefore be a new `Control`/`Node2D` scene as long as it
uses the same read-only state and (for combat) the same `cell_clicked` signal.
Do not move rules into the renderer.

## Current placeholder art

| Element | Where | Identifier / source |
| --- | --- | --- |
| First-person walls, floor, ceiling | `FirstPersonView._draw` | Dungeon cells; wall colors by depth/cell |
| First-person NPCs and objects | `_draw_sprites` / `_draw_sprite` | NPC `sprite` field, object `id` |
| Combat grid, terrain, tokens | `CombatView._draw` | `Encounter.map`, combatant team/conditions |
| UI frames, colors, fonts | `src/ui/theme_builder.gd` | Theme constants and font sizes |
| Character sheet / inventory | `src/ui/panels.gd` | Text only; no portraits yet |
| Icons | none | No icon assets are used |

Placeholder labels are intentional and must remain until replaced:
`PLACEHOLDER ART — first-person grid view`, combat `PLACEHOLDER ART`, and all
`(EXAMPLE ...)` prose.

## Sprite identifiers

NPCs in `content/dungeon.json` use `"sprite": "npc"` or `"sprite": "ghoul"`.
Objects are keyed by id:

| Id | Drawn as |
| --- | --- |
| `bell` | Bell silhouette |
| `shrine` | Stone block with a gold disc |
| `supply_crate` | Crate rectangle |
| `bier` | Low slab |
| `npc` / `ghoul` | Humanoid silhouette with/without claws |

To add a new sprite kind, add a case in `_draw_sprite` (placeholder), or replace
the drawing with a texture lookup keyed by the same string. Keep the string in
content; do not branch on display names.

## Replacing first-person art

Options, in increasing fidelity:

1. **Texture the existing raycaster.** Replace `_wall_color` with a texture lookup
   by cell/door type, and draw a 1-pixel-wide slice from a wall atlas. Keep
   `depth_buffer` for sprite occlusion.
2. **Billboard sprites.** Replace `_draw_sprite`'s shapes with `draw_texture_rect`
   using a sprite sheet and the projected `screen_x`, `depth` and `scale`.
3. **Full 2.5D scene.** Replace `FirstPersonView` with a Node2D/SubViewport scene
   that reads the same state. Keep the `ExplorationScreen.view` API (`queue_redraw`)
   or update the screen to call the new scene's refresh method.

Recommended source format: transparent PNG, pixel-art scale 1×–4×, 1280×720
reference composition, consistent light direction. Wall textures should tile at
5-ft intervals so the raycaster's depth slices remain legible.

## Replacing combat art

`CombatView` computes `cell_size` from the available rect and clamps it to 26–78
px. It draws:

- blocked cells (X pattern) and floor cells (checker),
- reachable cells (blue overlay),
- tokens (circle + initial + HP + condition abbreviations),
- legend and hover distance.

Replace the draw calls with tiles/tokens keyed by terrain and combatant id. Keep
click handling in `_gui_input` and the `cell_clicked` signal. The grid must remain
readable without color: keep initials, HP numbers and condition text.

## Character portraits and UI

There are no portrait assets yet. Character cards use names and HP bars;
`Panels.character_sheet` is text-based. To add portraits:

1. Put images under `assets/portraits/<character_id>.png` (stable ids:
   `kaelen`, `sera`, `aldric`, `ysolde`, `mira`).
2. Add a `portrait` field to `content/characters.json`.
3. Use a `TextureRect` in the party card/sheet with a text fallback if the file is
   missing. Missing optional art must not crash.

Theme colors and font sizes live in `ThemeBuilder` (`BG`, `PANEL`, `TEXT`,
`MUTED`, `GOLD`, `BLUE`, `DANGER`, `fs()`). Change them centrally rather than
per-screen.

## Audio hooks

Placeholder audio is in `assets/audio/`, generated locally at 22,050 Hz mono
16-bit WAV. Files:

| File | Hook |
| --- | --- |
| `step.wav` | Grid movement |
| `hit.wav`, `miss.wav` | Attack resolution |
| `spell.wav`, `heal.wav` | Spell casts/healing |
| `bell.wav` | Ringing the gate bell |
| `ui.wav` | Buttons, inventory, quest updates |
| `victory.wav`, `defeat.wav` | Outcome stingers |
| `door.wav` | Door opening |
| `combat.wav` | Combat start |
| `music_menu.wav` | Main menu loop |
| `music_explore.wav` | Exploration loop |
| `ambience_dungeon.wav` | Dungeon ambience loop |

`src/ui/sfx.gd` (autoload `Sfx`) is the only audio entry point. It loads streams
by id, ignores missing files, sets music/ambience loops, and applies the saved
music/SFX volume. `Sfx.play("id")` and `Sfx.play_music("id")` are the hooks.

### Replacement format

- Short SFX: WAV or OGG, mono or stereo, 44.1 kHz acceptable; keep under ~1 s for
  impacts and ~2 s for stingers.
- Music/ambience: OGG recommended for size; loop points are set at runtime by
  `Sfx`, so provide clean loop boundaries. Avoid silence gaps at the ends.
- Do not hotlink or ship commercial audio. Record or synthesize original sound.
- Keep the same filenames to replace without code changes, or update the ids in
  `Sfx` and the call sites together.

## Missing assets

- `Sfx` checks  `ResourceLoader.exists`; a missing sound is ignored without
  crash. This is covered by a test.
- Optional portraits/icons must use a text fallback.
- Do not make gameplay depend on a texture or audio file loading successfully.

## Asset naming and versioning

- Stable ids: `snake_case`, matching content ids (`bell_clapper`, `crypt_door`).
- Store final art under `assets/art/`, portraits under `assets/portraits/`, audio
  under `assets/audio/`.
- Keep a manifest mapping id → file if you add many assets. The id is the contract;
  filenames may change with the manifest.
- The documentation folder has a `.gdignore` so screenshots and docs are not
  imported as game textures.
