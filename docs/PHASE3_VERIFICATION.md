> Historical phase record. The final milestone addendum at the end supersedes
> earlier statements that E3, defaults restoration or export verification were
> incomplete.

# Phase 3 Verification — Source-Grounded Barovia Town Square

Date: **2026-11-03**
Project: `C:\Users\Noot Goblin\Downloads\Project Ravenloft\ravenloft-foundation`
Recoverable baseline: **`0ed3b0e59c4826714aa3a5606f86d853a668901f`**
Godot: `4.7.2.stable.official.ed1daf0bf`
GUT: **9.6.1** (vendored)
Final suite after save-defect closure: **108/108 tests passing, 783 assertions, 11 scripts, exit 0**

## Release-readiness addendum (2026-11-04)

Phase 3 is committed at `d52168d74da0c0c955395f0c130b21fd7ab21e9e`. The
release pass found and fixed one gameplay defect: movement could enter an NPC's
occupied cell. `GameSession._step()` now rejects occupied NPC cells and reports
`"<name> is in the way."`; `test_occupied_npc_cell_blocks_movement` covers it.

A real windowed playthrough confirmed new game/party selection, exploration,
Miruna dialogue branches, inventory, equipment display, potion targeting, save,
pause/return to menu, relaunch, and loading slot2. The gatehouse storeroom was
completed through normal movement, door interaction, combat actions and attacks;
victory awarded 300 XP and autosaved. Combat controls exercised: Move, 5-ft step,
Attack, Cast spell, Use potion, First aid, End turn and Inspect. E3 was entered
through both labelled waystones and its breach trigger started the adapted
infected-zombie encounter.

The second acceptance pass found a real defeat-stall defect: `_check_end()`
treated dying and stable characters as still able to fight, so an all-down party
could loop indefinitely (observed at round 410). It now requires a conscious,
acting party member. `test_defeat_when_party_is_only_dying_or_stable` covers the
regression. The real defeat screen appeared, and both offered recovery paths were
exercised: Load recovered directly, and Main menu → Load recovered to the same
pre-combat slot. The defeat screen has no Restart button in this build.

E3 victory and post-battle return persistence were **not completed** in the
graphical run; E3 combat was reached and fought, but the party was not brought to
victory before the acceptance window ended. This is recorded as **blocked**, not
passed. No direct state changes were used to force victory or defeat.

Key rebinding initially failed for a real reason: pressing a binding set
`awaiting_rebind`, but `refresh_modal()` called `close_modal()`, which cleared it
before rebuilding the Settings panel. `open_modal()` now preserves the pending
action during a refresh, and `test_rebind_button_enters_capture_mode` covers the
button-to-“Press a key…” transition. In the rebuilt export, R replaced Move
forward's W bind, R moved from `(5,9)` into the breach and started combat, W left
the position unchanged, and R remained bound after quit/relaunch. Navigation
buttons and the other movement/turn bindings remained available.

**Defaults restoration is blocked.** The Settings panel has no Restore defaults
control, and no session-level reset-defaults API exists. Adding one would be a
new feature, not a verification fix, so it was not added during this bounded
phase.

**Export status: produced.** The matching official Godot 4.7.2 templates were
installed and the Windows x86_64 build was exported to
`workspace/releases/windows_legacy_2026-11-05/RavenloftFoundation.exe` (105 MB, embedded PCK), then copied to
`C:\Users\Noot Goblin\Downloads\RavenloftFoundation-Release`. With the source
folder renamed away, it launched from `Downloads` under an isolated APPDATA and
started a new game; the source folder was restored afterward. Rebinding,
persistence and old-key behavior were repeated in this export. Full E3
victory/return remains unverified in the export.

## 1. Baseline check

Before editing, the working tree was committed as the Phase 3 baseline. The
committed project was then checked directly:

- Headless import: exit 0, no script/parse errors.
- Headless launch (`--quit-after 30`): exit 0.
- Existing suite: **89/89, 639 assertions, 10 scripts**, exit 0.
- Existing gatehouse demonstration and the preliminary two-area travel tests
  passed.

No blocking defect was found. The baseline commit remains recoverable at
`0ed3b0e`.

## 2. Source selection

Selected area: **E3 — Zombies in Town Square**, Village of Barovia.

| Source | Printed page | PDF page | Used for |
| --- | ---: | ---: | --- |
| *Expedition to Castle Ravenloft*, Ch. 2, area E3 | 25 | 26 | First entry from the east; a 10-ft breach in the eastern barricade; Ashlyn holding the square; NPC identity and follow-up |
| *Expedition to Castle Ravenloft*, tactical encounter E3 | 36–37 | 37–38 | Infected-zombie statistics, Ashlyn's role, barricades, well, neighboring mercantile and tavern, post-battle interaction |
| *Monster Manual I*, zombie entry | 265 | 266 | Existing zombie baseline for comparison |
| *Player's Handbook*, combat and skills | 133–160 | 134–161 | Existing supported combat/check mechanics only |

### Why this area

E3 is early-accessible, spatially small, and already fits the supported systems:
grid exploration, object interaction, a trigger-started encounter, turn-based
combat, persistent flags, dialogue and save/load. It supplies all four required
elements without requiring the church understory, the full village, Madam Eva,
the Sunsword, or new rules for entombing, disease, allied NPCs or barricade
cover.

### Included

- The breached eastern barricade as a one-time encounter trigger.
- The square choke point, village well, Bildrath's Mercantile and the Blood of
  the Vine tavern as bounded spatial/factual references.
- **Ashlyn, Undead Hunter**, a Lightbringer paladin, as an NPC and dialogue.
- Her companions **Thendrick** and **Mathilda**, the church lead, **Madam Eva**,
  and the **Sunsword** as reported facts, not implemented destinations/quests.
- A bounded encounter with **infected zombies** using the source's CR 2, 42 HP,
  AC 16, slam +6 (1d6+4), DR 5/slashing and plodding profile.
- A persistent “square saved” state, a one-time barricade repair, a Lightbringer
  quest, and Ashlyn's post-battle dialogue.

### Adapted or deferred

| Element | Decision |
| --- | --- |
| Encounter size | Source: nine infected zombies plus an entomber (EL 8). Implementation: **two infected zombies**, no entomber, for the level-3 party and the existing bounded combat engine. The premise—holding the breach with Ashlyn—is preserved; the scale is explicitly reduced. |
| Ashlyn in combat | Source stat block is CR 6 with paladin spells, smite, lay on hands and turn undead. Implementation: she is an NPC/dialogue presence, **not an allied combatant**. No ally AI was added. Her survival is represented by the `ashlyn_survived` flag after party victory. |
| Necromantic disease | Deferred. The source disease/rising rules are not implemented for this encounter. |
| Entomber | Deferred entirely. Its entomb, burrow and exhume abilities are not implemented; no substitute creature is presented as an entomber. |
| Full village | Deferred. The church, understory, cemetery, Madam Eva, the Sunsword and the broader zombie incursion are leads only. |
| Barricade cover/hardness | Deferred. The barricade is a persistent object and encounter trigger, not a destructible cover object. |
| Prose | Placeholder prose, marked `(SOURCE-ADAPTED, PLACEHOLDER PROSE)` or equivalent. No long source passages are reproduced. |

### Facts versus implementation assumptions

**Source-supported facts:** E3 is the first town-square encounter from the east;
the eastern barricade is breached; Ashlyn is a Lightbringer paladin holding the
square; the mercantile and Blood of the Vine tavern border the square; Ashlyn's
companions went to the church; Madam Eva is west of town; the Sunsword is her
larger goal; infected zombies are the encounter creatures.

**Implementation assumptions:** a compact 11×11 map; a specific well position;
the exact barricade gap cell; the reduced two-zombie squad; Ashlyn remaining
available after victory; the barricade repair interaction; the Lightbringer quest
as a two-objective journal abstraction. These are game adaptations, not new
canon.

## 3. World and persistence changes

### Area registry

`content/areas/_manifest.json` is now the explicit registry of additional areas:

- `default`: `old_gatehouse`
- registered: `barovia_east_gate`, `barovia_town_square`
- `demo_only`: `barovia_east_gate`
- `source_grounded`: `barovia_town_square`

`ContentDB` loads registered files by id, rejects an id mismatch, duplicate id,
missing file or malformed manifest, and no longer treats `_manifest.json` as an
area. `area_manifest` is exposed for diagnostics/tests.

### Travel and state

- Stable IDs: `old_gatehouse`, `barovia_east_gate`, `barovia_town_square`.
- Explicit `travel` effects carry destination area, position and facing.
- `travel_to` rejects unknown areas, same-area travel, blocked/non-walkable
  arrivals and non-exploration modes.
- The current area and a dictionary of per-area dungeon states are saved.
- Per-area state: open doors, removed objects, searched objects and visited
  cells.
- Shared campaign state: party, inventory, HP/conditions, gold, quests, world
  flags and RNG.
- Area-specific flags are namespaced: `town_square_saved`,
  `town_square_breach`, `ashlyn_survived`, `ashlyn_met`, `ashlyn_asked`,
  `barricade_repaired`.
- The encounter trigger is gated by `town_square_saved` and the one-shot
  `trigger_town_square_breach` flag, so it cannot repeat. Victory XP and effects
  are awarded once.
- The barricade repair requires `town_square_saved`, sets
  `barricade_repaired`, and removes the breach object once.

### Demo separation

The original gatehouse remains an invented regression/demonstration area. Its
former “East Road” is now a clearly labelled **Demo Waystone (Developer Route)**.
The East Gate map is relabelled a non-canonical **Developer Demo Staging Area**,
and its north waystone leads to E3. The town square has a debug return waystone.
No canonical road is claimed between the invented gatehouse and Barovia.

`--demo-town-square` starts a new game and moves directly to E3 through the
normal session travel method, for QA and screenshots.

## 4. Save compatibility

Save version remains **1**. The Phase 2 `area_id`/`areas` fields were already
additive; Phase 3 adds content, not a new save schema.

Policy:

1. New saves contain `area_id`, `areas`, and the legacy `dungeon` snapshot.
2. Older version-1 saves without `area_id`/`areas` load the default gatehouse
   and its legacy `dungeon` state.
3. A save naming an unknown area or containing malformed area state is refused
   with a clear message; the live session is not replaced.
4. Save versions other than 1 are refused by `SaveSystem`; they are never
   overwritten by a load.
5. Tests write only to `user://test_saves`; player slots are not used.

Verification covers legacy payload loading, saving in the town square, loading
into the correct area/position, leaving and returning, encounter
non-repetition, one-time repair, and shared quest/inventory state.

## 5. Verification results

Commands run from the project root:

```bash
"../Godot_v4.7.2-stable_win64.exe" --headless --path . --import
"../Godot_v4.7.2-stable_win64.exe" --headless --path . --quit-after 30
"../Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
"../Godot_v4.7.2-stable_win64.exe" --headless --path . --quit-after 90 -- --demo-town-square
```

Actual results:

- Import: exit 0, no script/parse errors.
- Headless launch: exit 0.
- GUT after the NPC, defeat and rebind fixes: **Scripts 11, Tests 101, Passing 101, Failing 0, Asserts 734**, exit 0.
- Town-square demo launch: exit 0, no project errors.
- Windowed E3 viewport capture: exit 0; saved and inspected. The area title,
  party HUD, objective panel, barricade prompt, controls and log render
  coherently at 1280×720.
- Content validation: zero errors, including the new area, manifest, NPC,
  encounter, quest and travel targets.

### Completion-gate test

`test_entry_activates_the_source_lead_and_features_it_in_the_tracker` checks
that E3 starts the Lightbringer lead on arrival and that the sidebar shows it
instead of the gatehouse demo quest.

`test_complete_loop_save_quit_load_and_return_without_repeating_rewards`:

1. Enters E3 via travel.
2. Steps onto the breach and starts `town_square_zombies`.
3. Resolves the encounter and records XP.
4. Talks to Ashlyn and completes the Lightbringer lead.
5. Repairs the barricade.
6. Saves, starts a new session, and loads.
7. Verifies area, position, flags, quest completion and removed breach.
8. Leaves to the staging map and returns.
9. Verifies no second encounter and no additional XP.

**Party used:** Kaelen, Sera, Aldric and Ysolde, all level 3, default four-person
configuration, fixed seed 424242 in the Phase 3 tests.

## 6. Changed files

Content:

- `content/areas/_manifest.json`
- `content/areas/barovia_town_square.json`
- `content/areas/barovia_east_gate.json` (relabelled demo staging and forward waystone)
- `content/dialogue/ashlyn_town_square.json`
- `content/dungeon.json` (demo waystone wording)
- `content/encounters.json` (`town_square_zombies`)
- `content/monsters.json` (`infected_zombie`)
- `content/quests.json` (`lightbringers`)
- `content/narration.json` (source/demo distinction in the opening notice)

Code:

- `src/core/content_db.gd` (manifest-driven area registry and area-field validation)
- `src/core/quests.gd` (area-featured tracker text)
- `src/game_state.gd` (entry effects, ambient arrival log and tracker selection)
- `src/ui/exploration_screen.gd` (uses the area/quest tracker)
- `src/main.gd` (`--demo-town-square`; rebind capture survives modal refresh)

Tests/docs:

- `tests/test_phase3_town_square.gd`
- `tests/test_ui.gd` (rebind button enters capture mode)
- `README.md`, `PROJECT_COMPENDIUM.md`
- `docs/REFERENCE_INDEX.md`, `docs/TRACEABILITY.md`,
  `docs/AUTHORING_GUIDE.md`, `docs/SUPPORTED_FEATURES.md`,
  `docs/TEST_REPORT.md`, `docs/SETUP.md`, `docs/PHASE2_VERIFICATION.md`

## 7. Remaining limitations, ranked

1. **Ashlyn is not an allied combatant.** The source's CR 6 paladin and her
   tactical participation are represented narratively only. No ally AI exists.
2. **The source encounter is scaled down.** Two infected zombies replace nine
   plus an entomber. The encounter's CR/EL and the entomber's entomb/exhume
   mechanics are not reproduced.
3. **No disease model.** Necromantic infection, rising as a zombie, and the
   source's disease consequences are deferred.
4. **The town square is a bounded excerpt.** The church, understory, cemetery,
   Madam Eva, the Sunsword, Bildrath's shop inventory and the full village are
   not playable.
5. **Ashlyn's stat block is not imported.** Her exact paladin spells, smite,
   lay on hands, turn undead and equipment are not used.
6. **No source chapter is fully adapted.** This is one E3 excerpt; the campaign,
   later encounters and branching Fortunes of Ravenloft are out of scope.
7. **Some native UI paths remain unverified.** Defeat/recovery and key rebinding
   passed; E3 victory/return remains uncompleted, and defaults restoration has no
   UI control or reset API to exercise.
8. **Export verification is partial.** The Windows build launches with the source
   directory absent and rebinding works in it, but the full E3 victory/return loop
   was not repeated in the export.
9. **Intermittent teardown diagnostics remain.** Some headless runs print
   ObjectDB/resource shutdown warnings while still exiting 0 and passing.
10. **Placeholder prose and art remain.** The area is a mechanics/content
    demonstration, not final writing or art.


## Final milestone addendum (2026-11-04)

- Mage Armor corrected from self-only to PHB p.225 range touch / creature touched;
  UI and a regression test now cover ally targeting.
- Restore Default Controls added to Settings with confirmation, pending-capture
  clearing, project-binding reload, persistence and regression coverage.
- E3 completed through normal controls with Kaelen, Aldric, Ysolde and Mira at
  seed 424242: victory, 600 XP each, Ashlyn dialogue, barricade repair, travel out
  and back with no repeat, auto-save, quit, relaunch and loaded state.

## Save-defect closure (2026-11-04)

### Root cause: the barricade repair was never saved

The missing `barricade_repaired` flag was **not** a serialization or load defect.
Tracing the interaction path showed the write never happened:

1. `GameSession._interact_object()` selects the first matching interaction.
2. `_run_interaction()` runs the skill check, calls `apply_effects()` (which set
   `barricade_repaired` and logged the narration), calls `dungeon.mark_removed()`
   for the `once` object, plays a sound, emits `state_changed`, and returned.
3. No save was requested at that point. `save_game("auto")` existed in only two
   places: `on_dialogue_finished()` and combat victory in `_resolve_encounter()`.

Preserved evidence agrees with the code. The QA autosave
(`.ravenloft-snapshots/2026-11-04-closure-pre/saves/auto.json`) is stamped
`21:33:16` and carries `ashlyn_met`, `ashlyn_survived`, `town_square_saved` and
`trigger_town_square_breach` but **not** `barricade_repaired`. The preserved
`barricade-interact.png` shows `Autosaved.` *above* the repair narration, i.e. the
autosave came from Ashlyn's dialogue ending and the repair happened afterwards.
Payload construction, slot selection and load were all correct; the state simply
never reached disk.

### Fix: an explicit interaction save boundary

`_run_interaction()` now calls `_autosave_after_interaction()` **after** every
effect and the once-only removal have been applied, so a partially resolved
interaction can never be written. The boundary only writes when the interaction
actually changed world state (`once`, or any effect other than narration), only
in `explore` mode, and only when content is loaded. An interaction that hands
control to combat or dialogue is left to those systems' own boundaries. A failed
write logs `Autosave failed: <reason>` and never reports success.

Studying narration-only objects (well, tavern, mercantile) does not autosave, so
the log does not fill with `Autosaved.` on every examine.

### Root cause: manual save was a clipping/automation problem, not a defect

The named-save button did open. `main` is assigned to the exploration screen
(`src/main.gd`), `_open_save_modal()` builds `Panels.saves("save", ...)`, and the
modal was fully functional. The real problem was layout: the Sheet / Inventory /
Journal / **Save game** grid sat at the bottom of the scrolling sidebar, which
overflows at 1280×720, so `Save game` rendered below the fold and the
fixed-coordinate QA click landed on empty space. The preserved `save-modal.png`
shows the exploration screen with no modal and the quick-action row clipped.

The quick-action grid now sits above the party list, so Save cannot be the control
that falls below the fold at any text scale, and the quick actions precede all
scrolling party content. The save panel also keeps a failure message on screen
instead of refreshing it away, so a refused write is never implied to have
succeeded.

Verified live in a windowed source run at 1280×720: `Save game` is visible, the
`Save Game` modal opens with three named slots, `Save here` on slot1 wrote
`saves/slot1.json` (area `barovia_town_square`, position `[5, 9]`) and the panel
then displayed `slot1 — 2026-11-03 21:53:29 — Village of Barovia — Town Square
(E3) — 0 gold — Kaelen Dorn, Brother Aldric, Ysolde, Mira Vane`. The log recorded
`Game saved to slot1.`

### Regression coverage added

- `test_barricade_repair_autosaves_through_the_interaction_path` — wins the fight
  (victory autosave carries no repair flag), repairs by interacting only, then
  reads the autosave from disk and asserts the flag **and** the removed `breach`
  are present, then loads it into a fresh session.
- `test_barricade_repair_survives_a_manual_save_from_the_save_panel` — repairs,
  presses the real `Save here` button for slot1, then reloads and asserts flag and
  removed object.
- `test_failed_interaction_autosave_never_reports_success` — points the save
  directory at a regular file so the write must fail, then asserts the repair still
  applies in memory and the log says `Autosave failed` and never `Autosaved.`
- `test_exploration_quick_actions_sit_above_the_scrolling_party_list` and
  `test_save_modal_opens_from_the_exploration_interface` — layout and real modal
  opening coverage for the manual-save issue.

Suite after the fixes: **108/108 tests, 783 assertions, 11 scripts, exit 0**.

### Fresh executable

Windows x86_64 export rebuilt after the fixes from HEAD
`d52168d74da0c0c955395f0c130b21fd7ab21e9e` with a dirty working tree:

- `workspace/releases/windows_legacy_2026-11-05/RavenloftFoundation.exe`, 110,056,320 bytes
- SHA-256 `b70cc9276d5ba5a88af202ec26e3df3b38294baa97601ce4244c40cb122d1065`

It was copied outside the source tree to
`.ravenloft-milestone-qa/accept/` and run with an isolated `APPDATA`; the real
player profile gained no files newer than the launch. Verified in that exact
executable: it launches with the source present only as a build input, the menu
renders, **New game** opens **party selection** with real character data, four
adventurers (Aldric, Kaelen, Mira, Ysolde) start a session, and the E3 scenario
starts through `-- --demo-town-square-mira`. Combat was started with the in-game
**Forward** control and move / attack / DR / attack-of-opportunity resolution was
observed with the party advancing and attacking through the normal buttons.

### Native acceptance checklist — `b70cc927…` (2026-11-04)

All four checks ran against the same frozen executable, SHA-256
`b70cc9276d5ba5a88af202ec26e3df3b38294baa97601ce4244c40cb122d1065`
(110,056,320 bytes, re-hashed before and after the run), with the isolated
profile `.ravenloft-milestone-qa/accept2-appdata` for checks A–C, plus a second
fresh profile `.ravenloft-milestone-qa/accept3-appdata` (seeded only with a copy
of the check-B pre-combat slot) for check D. No source change and no
rebuild were made during acceptance. Evidence screenshots live in
`.ravenloft-milestone-qa/accept2/`; hard state evidence is the profile's
`settings.cfg` and `saves/*.json`.

| Check | Setup | Actions performed | Observed outcome | Status |
| --- | --- | --- | --- | --- |
| **A. Controls and defaults** | Menu → Settings on the isolated profile | Rebound `Move forward`, pressed `R`, restarted; then `Restore Default Controls` through the confirm dialog and restarted again | Capture mode showed `Press a key…` and stored `R`; `settings.cfg` held `"move_forward": 82` and Settings still showed `R` after restart. Restore wrote `keybinds={}` and Settings showed `W` after restart | Passed |
| **B. Manual save/load** | `-- --demo-town-square-mira` (pre-combat, no fixture save) | Opened the real Save modal from the exploration quick action, saved slot1, quit, relaunched, opened Load | Slot1 listed area, position, party and timestamp accurately; after loading, the log read `Loaded slot1 (2026-11-03 22:13:38)` with the matching area, position, party and HP | Passed |
| **C. Genuine E3 end-to-end** | Same documented start shortcut; combat entered with the in-game `Forward` control at (5,9) | Full combat through the visible buttons only (move + attack for the two fighters, `Cast spell` → Scorching Ray then Magic Missile from the back rank for the casters, `End turn` each initiative step), then Ashlyn dialogue, barricade repair, travel to the staging area and back, manual save to slot2, quit, relaunch, Load, and Continue | Victory in round 7 with both zombies destroyed, 600 XP per adventurer and `Autosaved.`; dialogue end autosaved `ashlyn_met` with the quest complete; repair autosaved `barricade_repaired: true` with `removed: ["breach"]`; the return visit fired no encounter and added no XP (still 3600 each); the slot2 reload restored repair, removed object, quest, XP and encounter state; `Continue from latest save` loaded slot2 (22:37:20), the newest save, shown by the on-screen `Loaded slot2 (2026-11-03 22:37:20)` | Passed |
| **D. Defeat recovery** | Two independent runs: the check-C fight left to resolve (in-place path), then `.ravenloft-milestone-qa/accept3-appdata` seeded only with a copy of the check-B pre-combat slot (menu path) | Let the party be wiped using only `End turn`, then used each defeat-screen control: `Load a save` in run 1, `Main menu` in run 2 with slot1 loaded from the menu | Run 1: defeat at round 10; `Load a save` → slot1 restored the pre-combat state. Run 2: defeat reached on the clean profile; `Main menu` returned a responsive main menu with no stale modal, `Load game` listed slot1 accurately, and loading gave a controllable pre-combat state at (5,9) with the `[F] Breached Eastern Barricade` prompt, uncompleted objectives and full party HP; walking `Forward` re-triggered the encounter at round 1 with both zombies at 42/42, so no victory or defeat state carried over; the defeat wrote no autosave (only `slot1.json` present) | Passed |

**Scope of this acceptance:** No unresolved failures remain in the native A–D
acceptance checks performed on the identified candidate. This is acceptance of
a vertical slice, not a claim of full D&D 3.5 accuracy or a complete Ravenloft
implementation: the documented rules limitations, the reduced-scale E3
adaptation, the placeholder prose and art, and all behavior outside these four
checks remain as recorded in section 7 of this document and in
`docs/SUPPORTED_FEATURES.md`.

Notes for this record:

- The first combat attempt was lost because the automation kept clicking
  hard-coded grid squares after the zombies had shifted one column, so the
  spell targets were empty squares. Token positions are now read from each
  screenshot (`.ravenloft-milestone-qa/detect.py`, `turn.py`) before any click.
  That was a tooling error, not a game defect, and no rebuild was needed.
- Check C used only shipped mechanics: no forced victory, no edited resources,
  no altered combat rules or enemy statistics.
- Slot1 retains the pre-combat fixture from check B; slot2 holds the verified
  postcombat state from check C. `auto.json` holds the repair autosave.
- **Continue policy:** `SaveSystem.list_saves()` returns every existing slot
  (including `auto`) sorted by `saved_unix` newest-first and `latest_slot()`
  takes the first entry, so `Continue from latest save` resumes the most recent
  save of any kind — it is not an autosave-only button. Check C observed it
  select slot2, which was newer than the repair autosave.
- Check D evidence is in `.ravenloft-milestone-qa/accept3/` (`E1`–`E13b`),
  with the pre-combat fixture and no autosave in that profile's `saves/`.
- The earlier `a580d869…` executable remains superseded and must not be mixed
  with this build's evidence.

### Export contents

The preset exports `all_resources` and includes `content/**/*.json`, excluding
`docs/*`, `tests/*`, `tools/*`, `addons/gut/*`, `*.md`, `*.pdf`, `*.zip`, `.qa*`
and `qa_gui.log`. A separate pack export was parsed for its path table and the
resulting binary was scanned: 14 `content/*.json` paths and the area/world
data are present, and there are no `res://docs/`, `res://tests/`, `res://tools/`,
`res://addons/gut/`, `.pdf`, `.md` or QA-screenshot entries. Reference PDFs and
extracted reference text live outside the project in
`.ravenloft-milestone-qa/pdf/` and `.ravenloft-snapshots/`, and are not packaged.
