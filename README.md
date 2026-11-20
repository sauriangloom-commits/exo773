# Ravenloft Foundation

> **Editable copy.** This is the independent `RL_Edit` working copy of the
> maintained project. Since 2026-11-14 it is a local Git repository (baseline
> commit `a64eead`, no remote) and it uses its own Godot user-data directory
> (`%APPDATA%\RavenloftFoundationEdit`), so saves and settings here cannot reach
> the original. See `EDIT_COPY.md` for exclusions and verification.

A playable, data-driven foundation for a single-player **D&D 3.5 / Ravenloft-inspired**
first-person party RPG, built in **Godot 4.7.2** with **GUT 9.6.1**.

This is a vertical slice, not a campaign. It demonstrates one complete loop:
explore the invented Old Gatehouse, use a clearly marked developer route to a
source-grounded excerpt of the Village of Barovia town square, talk to an NPC and
a speech-capable undead creature, fight three tactical encounters, recover a quest
item, resolve the objective, and save/reload the consequences. All art, audio and
prose are clearly labelled placeholders authored for this project.

> **Canon notice.** The Old Gatehouse, its quest, NPCs and events are invented
> example content. **Village of Barovia — Town Square (E3)** is a small
> source-adapted excerpt; its prose is placeholder text, and its encounter is
> reduced for this level-3 slice. The **East Gate** map is a non-canonical
> developer staging area, not a claim about Barovia's geography. The work is
> inspired by *Expedition to Castle Ravenloft* but is not a full canonical
> campaign, geography or plot. The supplied PDFs are reference material and are
> not redistributed with this project.

> Screenshots are QA evidence and were excluded from this editable copy.

## Quick start (verified environment)

The Godot executable is the installed 4.7.2 build in the original project folder:

```bash
cd "C:\Users\Noot Goblin\Downloads\Ravenloft\RL_Edit"
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path .
```

Or open `project.godot` in Godot 4.7.2 and press **F5**. The entry scene is
`scenes/Main.tscn`; the project starts at the main menu.

No build step is required. GUT is vendored under `addons/gut`.

## Controls

| Action | Keys |
| --- | --- |
| Move forward / back | `W` / `S` or `↑` / `↓` |
| Strafe left / right | `A` / `D` |
| Turn left / right | `Q` / `E` or `←` / `→` |
| Interact / confirm | `F` or `Space` |
| Party and character sheet | `Tab` or `C` |
| Inventory and equipment | `I` |
| Journal | `J` |
| Pause, save, load, settings | `Esc` |

Mouse and on-screen buttons work for every action. Combat also accepts clicks on
the tactical grid. Bindings can be changed in **Settings → Controls**.

## The playable loop

1. **New game** → choose adventurers from five level-3 pregens within the
   campaign's declared range (The Ashwick Ferry: three or four).
2. Read the DM narration, then explore the Old Gatehouse with grid movement and
   discrete facing. A labelled **Demo Waystone** leads to a non-canonical staging
   map and then to the source-grounded **Village of Barovia — Town Square (E3)**.
   Each area retains its own doors, loot, searched objects and visited cells.
3. Talk to **Miruna** (NPC) and accept *The Drowned Bell*. A Sense Motive choice
   demonstrates a party skill check with a named actor.
4. Open the storeroom door, trigger the flooded-stores encounter, and fight two
   zombies in turn-based combat on a 5-ft grid.
5. Search the crate for the bell clapper (a Search check), unlock the crypt with
   the gatehouse key, and confront **Corvin**, a ghoul who can be fought or
   parleyed with (Diplomacy/Intimidate).
6. In the town square, hold the breached barricade against infected zombies,
   speak with **Ashlyn**, and repair the barricade. Then ring the gatehouse bell
   to complete the original quest. Victory, defeat, autosave and manual save/load
   are all wired.
7. Quit and **Continue** or **Load game** to resume; world flags, doors, loot,
   party HP, position, quests and RNG state are restored.

The shrine provides a full-party recovery point. Defeat offers load and main-menu
recovery rather than silently resetting progress.

## Campaign creator pending edits (verified 2026-11-05)

The creator does not silently commit entity-form text. If an NPC, conversation,
node, response, quest, objective, encounter, victory consequence or trigger form
differs from the applied draft, changing entity/area, opening a validation
result, saving, playtesting or leaving first offers **Apply / Discard / Cancel**.
Cancel keeps the text, selection and focus; Discard is explicit; Apply validates
before changing the draft and keeps the text visible if validation fails. Save
and Playtest refuse while text is pending, and the pinned header names the
pending form. This protects input only; it does not add an editor section or
gameplay system. Guarded Apply is all-or-nothing: form values are snapshotted,
the live draft is restored on any failure, and selection/navigation do not
advance. Reference pickers now show an explicit **Unresolved reference: <id>**
instead of substituting the first valid entry; opening or editing an unrelated
field does not repair it. Verified in the exported candidate with asserted probes
and a windowed 1280×720 / 1.6× external-input check. See `docs/TEST_REPORT.md`.

## What is implemented

- First-person 2D raycaster over the same grid used by exploration; no external
  art assets, no copied game assets.
- Grid movement, doors, objects, NPCs, triggers, one-time events and persistent
  world flags, plus a manifest-driven registry of three areas and explicit
  two-way travel with per-area state.
- Five authored pregens, four-person party selection, character sheet, equipment,
  inventory, derived statistics and XP tracking.
- Initiative, no surprise round, standard/move/free actions, 5-ft steps,
  attacks of opportunity, melee/ranged attacks, critical threats and
  confirmation, grid line of sight, range increments, damage reduction,
  dying/stabilization. Shooting or throwing into a melee takes -4 unless the
  target is 10 ft. from the nearest ally or the attacker has Precise Shot, and a
  ranged attack while threatened provokes separately (ranged spells included).
  Combat-start flat-footedness (PHB pp. 133-136) is
  applied: every combatant is flat-footed until the start of their first turn,
  losing a positive Dexterity bonus and any dodge bonus to AC plus its attacks
  of opportunity (a Dexterity penalty still applies), and a rogue can sneak
  attack such a target. Awareness alone does not remove the state.
- Six spells: *magic missile*, *mage armor*, *scorching ray*, *cure light wounds*,
  *bless*, *aid*, with slot tracking and combat/exploration use.
- Conditions with round durations: paralysis (ghoul, DC 12, elf immunity), dying,
  stable, dead, buffs; undead are destroyed at 0 HP.
- Data-driven dialogue with speakers (narrator/NPC/creature/party), conditions,
  skill checks, effects, quest updates, one-time nodes and combat transitions.
- Data-driven campaign packages: three bundled campaigns (`ravenloft_demo`,
  `hollow_lantern`, `ashwick_ferry`) selected in-game, plus
  player-authored campaigns under `user://campaigns/<id>/`. **Create campaign**
  starts a writable package and the **Campaign Editor** covers title/
  description, 9x9 areas, walls/floors, entry/facing, area passages, placing a
  speaker NPC and authoring a branching conversation with a skill check, flag
  condition/consequence and narration, with validation, atomic save and an
  isolated playtest. NPCs are speakers and need no stat block. Quests (up to 12
  flag-bound objectives), campaign flags, fixed-layout encounters, victory
  consequences and encounter triggers are authored in the same editor.
  Validation results are structured: selecting one opens its section, selects
  the entity, scrolls to and focuses the field, and preserves unsaved input;
  errors block save/playtest while warnings remain visible. File-only content is
  labelled advanced rather than presented as editable.
- Validated JSON content, readable errors, seeded RNG, versioned saves.
- Generated placeholder WAV audio, music/ambience loops, volume settings,
  remappable input and a combat log that shows the rolls and modifiers.

## Deliberately not implemented

Grapple, trip, disarm, sunder, bull rush, two-weapon fighting, player iterative/full
attacks, readied or delayed actions, turn undead, cover/concealment,
area-of-effect templates, encumbrance, multiclassing, level-up
choices, crafting, shops, diseases/poisons, mounted/flying combat, and the full
spell list. See [docs/SUPPORTED_FEATURES.md](docs/SUPPORTED_FEATURES.md) for the
exact scope.

## Tests

```bash
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

The **historical v1** Ashwick checkpoint was 339/339 tests passing, 4,324
assertions and 22 scripts at `fc951aca49877d6a4fa6999254831d7ebe6b9349`. That run
predates The Ashwick Ferry: The Second Ring and is retained as history, not
current status.

The accepted **Second Ring** boundary was **517/517 tests, 5,963 assertions,
42 scripts, exit 0** (Godot 4.7.2, GUT 9.6.1). The current boundary is
**538/538 tests, 6,263 assertions, 44 scripts, exit 0**, adding the campaign
party-limit contract, Ashwick's authored minimum of three and the application
option guard; the full suite and both validators were rerun there. Application options are validated before any
screen opens: an unrecognised option prints the closest supported alternatives
and exits 2 instead of starting the game (see `docs/SETUP.md`). The one recorded ordinary
exported-window route (truth account, single bell ring) reached the specific
epilogue; the mercy account, ring-twice, silence, defeat/interruption,
optional-page combinations, repeat attempts, save/load and v1 refusal are
automated checks only. No human playtest and no balance validation has been
performed. Authoritative records: [docs/PROGRAM_PROGRESS.md](docs/PROGRAM_PROGRESS.md),
[docs/TEST_REPORT.md](docs/TEST_REPORT.md) and
[docs/CONTINUATION_BRIEF.md](docs/CONTINUATION_BRIEF.md). Test runs write to
`user://test_saves`, never to a player's save slots.

> **Post-checkpoint documentation.** This Tests paragraph was corrected after
the sealed `builds/qa/snapshots/2026-11-14_ashwick_second_ring/` checkpoint, so
the working-tree README intentionally differs from that historical snapshot (as
the foundation closure note did). That checkpoint was not regenerated or modified, and neither was the later
`builds/qa/snapshots/2026-11-14_party_contract/` snapshot that records the
bounded party-contract correction.

## Project layout

```
project.godot              Godot config, autoloads, input map
scenes/Main.tscn           entry scene
src/main.gd                screen router, menus, modals, settings
src/game_state.gd          GameSession autoload; world/party/quest/save API
src/core/                  rules, characters, maps, encounters, dungeon,
                           dialogue, quests, content validation, saves
src/ui/                    theme, first-person view, tactical view, screens,
                           panels and dialogue overlay
content/                   items, spells, characters, monsters, encounters,
                           dungeon, areas, quests, narration, dialogue
assets/audio/              generated placeholder WAVs
tests/                     GUT unit, integration and UI smoke tests
docs/                      reference index, traceability, guides, screenshots
tools/capture_window.py    optional desktop screenshot helper
```

## Documentation

- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) — original comprehensive overview
  of architecture, rules, content, testing, sources and roadmap.
- [PROJECT_COMPENDIUM.md](PROJECT_COMPENDIUM.md) — second comprehensive project
  document reflecting the post-Phase 2 verified state, corrections and limitations.
- [PROJECT_CHRONICLE.md](PROJECT_CHRONICLE.md) — third comprehensive project
  document: the project's history, Phase 3 source adaptation, architecture and
  next steps.
- [SETUP.md](docs/SETUP.md) — run, test, save locations, developer demo flags,
  troubleshooting and export notes.
- [REFERENCE_INDEX.md](docs/REFERENCE_INDEX.md) — all 43 supplied PDFs, relevant
  sections, printed-vs-PDF page mapping and extraction gaps.
- [TRACEABILITY.md](docs/TRACEABILITY.md) — implemented behavior linked to its
  source, interpretation or adaptation.
- [ADAPTATION_LOG.md](docs/ADAPTATION_LOG.md) — consequential design decisions.
- [SUPPORTED_FEATURES.md](docs/SUPPORTED_FEATURES.md) — exact supported scope and
  limitations.
- [AUTHORING_GUIDE.md](docs/AUTHORING_GUIDE.md) — adding dialogue, quests,
  narration, conditions and effects without editing core code.
- [ASSET_GUIDE.md](docs/ASSET_GUIDE.md) — replacing placeholder art and audio.
- [PHASE2_VERIFICATION.md](docs/PHASE2_VERIFICATION.md) — independent Phase 2 verification matrix, rules audit and residual issues.
- [PHASE3_VERIFICATION.md](docs/PHASE3_VERIFICATION.md) — source-grounded E3 area, save policy, loop test and ranked limitations.
- [ROADMAP.md](docs/ROADMAP.md) — prioritized continuation plan.

## Assets and licensing

All art is drawn procedurally from simple shapes; all audio is generated locally
with sine/noise synthesis. Placeholder assets are marked in-game
(`PLACEHOLDER ART`, `EXAMPLE CONTENT`, `EXAMPLE DIALOGUE`). No commercial audio or
third-party game assets are included. The PDFs are not part of this project and
must not be redistributed.
