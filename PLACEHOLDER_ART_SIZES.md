# Placeholder art — measured sizes

Every visual in this build is drawn procedurally by `src/ui/first_person_view.gd`
and `src/ui/combat_view.gd`; no art textures are shipped (the only image asset is
`assets/art/icon.svg`). This sheet records the pixel size of each placeholder as
the shipped game draws it, and `placeholder_art/` holds one PNG per element at
exactly that size.

The PNGs are reference renditions, not runtime textures — nothing loads them.
They exist so a replacement can be drawn at the right canvas size and compared
against the current look.

## Measurement basis

- Reference viewport **1280×720** (`project.godot`), `canvas_items` stretch with
  `expand` aspect, default text scale **1.0**, default font size 16.
- Sizes read from a real windowed run that started a new Ashwick party and the
  mandatory encounter, then printed the control rects and computed cell size:

```
VIEWPORT=(1280.0, 720.0)   TEXT_SCALE=1.0
EXPLORE_VIEW_POS=(14.0, 59.0)    EXPLORE_VIEW_SIZE=(870.0, 360.0)
COMBAT_VIEW_POS=(12.0, 55.0)     COMBAT_VIEW_SIZE=(834.0, 467.0)
MAP=9x7    CELL=56.7142857142857    ORIGIN=(161.7857, 26.0)
TOKEN_DIAMETER=37.4314285714286    TOKEN_FONT=19
```

- Both Ashwick maps are square-ish in a tall view, so the height clamp decides
  the cell: the 9×7 drowned-ferrymen map and the 7×7 bell map both compute
  **56.71 px**. The renderer clamps cell size to **26–78 px**.
- Runtime sizes are floats; the PNG canvases round to whole pixels. Rounding is
  the only difference between the table and the files.

## Screen layout at 1280×720

| Region | Size (px) | Position | Source |
| --- | --- | --- | --- |
| Window / canvas | 1280×720 | — | `project.godot` |
| Exploration view (raycaster) | **870×360** | (14, 59) | measured |
| Exploration sidebar | 350 wide (+12 gap) | right of view | `exploration_screen.gd` |
| Combat view (battle grid) | **834×467** | (12, 55) | measured |
| Combat sidebar | 340 wide (+10 gap) | right of grid view | `combat_screen.gd` |
| Combat log panel | 150 tall | under the grid view | `combat_screen.gd` |

## First-person view (870×360)

Raycaster with **74° horizontal FOV** (`FOV = 1.30` rad), horizon at y=180,
focal length `(870/2)/tan(0.65)` = **572.2 px**. Walls are painted as **1-px-wide
vertical slices**, so there is no fixed wall bitmap; the table gives the size of
one 5-ft wall face seen head-on, plus the slice formula.

| Element | Size (px) | Notes |
| --- | --- | --- |
| Ceiling | 870×180 | 8 bands of 870×22.5, `#0c1218`→`#1a232c` |
| Floor | 870×180 | 8 bands of 870×22.5, `#14181b`→`#2a241d` |
| Horizon line | 870×2 | black at 35% alpha |
| Wall face, one 5-ft cell at 5 ft | **572×572** | `#4a5058`; face at depth 2 is 286×286 |
| Wall slice (per screen column) | 1 × (572.2 / depth) | clipped to the view |
| Door face, one 5-ft cell at 5 ft | **572×572** | `#5a4029` |
| Depth lines | 870×1 each | 8 floor + 8 ceiling lines |
| Crosshair | 4 px dot, 9-px arms | centre of view |
| HUD location plate | 190×30 | at (12, 12) inside the view |
| Interaction prompt plate | text width + 24, × 34 | bottom edge, 84 px up |
| Sprite name plate | text width + 8, × font+4 | font 10–18 px, only within 6 cells |

Projected billboards use `scale = focal / depth`; body width `0.52 × scale`,
height `0.95 × scale`, feet on `horizon + 0.5 × scale`. At **depth 2 (10 ft)**:

| Sprite | Size (px) | File |
| --- | --- | --- |
| NPC (`sprite: npc`) | **149×272** | `npc_sprite_149x272.png` |
| Ghoul (`sprite: ghoul`) | **149×272** | `ghoul_sprite_149x272.png` |
| Bell (`bell`) | **208×272** | `bell_sprite_208x272.png` |
| Shrine (`shrine`) | **179×217** | `shrine_sprite_179x217.png` |
| Supply crate (`supply_crate`) | **208×149** | `crate_sprite_208x149.png` |
| Bier (`bier`) | **238×82** | `bier_sprite_238x82.png` |

Depth table for the same geometry:

| Depth (cells) | Wall slice height | NPC/ghoul body | Bell width |
| --- | --- | --- | --- |
| 1 | 572.2 | 298×544 | 416 |
| 2 | 286.1 | 149×272 | 208 |
| 3 | 190.7 | 99×181 | 139 |
| 4 | 143.1 | 74×136 | 104 |
| 6 | 95.4 | 50×91 | 69 |

## Battle view (834×467, 9×7 map)

```
cell = clamp(min((view_w - 40) / cols, (view_h - 70) / rows), 26, 78)
```

For the Ashwick maps this is **56.71 px**, origin y=26, grid centred horizontally
at x=161.8. Grid frame = `cols × cell + 12` by `rows × cell + 12` = **522×409**.

| Element | Size (px) | Notes |
| --- | --- | --- |
| Floor tile | **56.7** (57 canvas) | checker `#242a2c` / `#202628`, 1-px border |
| Blocked tile | **56.7** (57 canvas) | `#171d23`, X inset 4 px |
| Reachable overlay | **56.7** (57 canvas) | blue 18% fill, blue 35% border |
| Party token | **37.4 diameter** (37 canvas) | `#6f9fc4`, darker rim 0.25 |
| Enemy token | **37.4 diameter** (37 canvas) | `#d07a6f` |
| Dead token | **37.4 diameter** (37 canvas) | `#4b4b4b` plus X |
| Active-turn ring | **47.4 diameter** (47 canvas) | token radius + 5 px, gold 55% |
| Token initial | 19 px font | `clamp(0.34 × cell, 12, 24)` |
| HP plate | text width + 6, × 14 | drawn when cell ≥ 52 |
| HP text | 11 px font | below the token |
| Condition text | 10 px font | `PAR`, `DYE`, `STA`, `BL`, `MA`; cell ≥ 46 |
| Legend lines | 12 px font | bottom-left |
| "PLACEHOLDER ART" label | 11 px font | top-right |

At the 26 px clamp the token is 17.2 px across, the ring 27.2, the initial 12 px,
and the HP plate is suppressed (cell < 52). At the 78 px clamp the token is 51.5,
the ring 61.5, and the initial 24 px.

## Files

All files are in `placeholder_art/`, RGBA PNG, sized exactly as named:

| File | Size (px) | Element |
| --- | --- | --- |
| `first_person_base_870x360.png` | 870×360 | Empty first-person view: ceiling, floor, horizon, depth lines, crosshair, watermark |
| `ceiling_870x180.png` | 870×180 | Ceiling half |
| `floor_870x180.png` | 870×180 | Floor half |
| `wall_face_572x572.png` | 572×572 | One 5-ft wall face at 5 ft |
| `wall_face_door_572x572.png` | 572×572 | Door face at 5 ft |
| `npc_sprite_149x272.png` | 149×272 | NPC billboard at 10 ft |
| `ghoul_sprite_149x272.png` | 149×272 | Ghoul billboard at 10 ft |
| `bell_sprite_208x272.png` | 208×272 | Bell silhouette at 10 ft |
| `shrine_sprite_179x217.png` | 179×217 | Shrine at 10 ft |
| `crate_sprite_208x149.png` | 208×149 | Supply crate at 10 ft |
| `bier_sprite_238x82.png` | 238×82 | Bier at 10 ft |
| `battle_floor_tile_57x57.png` | 57×57 | Checker tile A |
| `battle_floor_tile_alt_57x57.png` | 57×57 | Checker tile B |
| `battle_blocked_tile_57x57.png` | 57×57 | Blocked tile |
| `battle_reachable_tile_57x57.png` | 57×57 | Reachable overlay (transparent) |
| `token_party_37x37.png` | 37×37 | Party token |
| `token_enemy_37x37.png` | 37×37 | Enemy token |
| `token_dead_37x37.png` | 37×37 | Dead token |
| `token_active_47x47.png` | 47×47 | Active-turn token with gold ring |
| `battle_grid_522x409.png` | 522×409 | Assembled 9×7 grid (blocked border, checker floor) |

## Notes

- Text scale (Settings → Text size, 0.8–1.6) changes HUD and token *text* sizes
  only; tile, token and sprite geometry does not change with it.
- Window size changes the view rects, and therefore the cell size and every
  projected sprite (formulas above). The tables are for the 1280×720 reference.
- The wall face is not drawn as a bitmap: the renderer paints 1-px columns whose
  height depends on distance, with four shading bands, a lit top edge, a dark
  bottom edge and mortar at 33% and 70%. A replacement texture should tile at
  5-ft intervals (see `docs/ASSET_GUIDE.md`).
- Keep initials, HP numbers and condition abbreviations when replacing tokens:
  the grid must stay readable without colour (`docs/ASSET_GUIDE.md`).
