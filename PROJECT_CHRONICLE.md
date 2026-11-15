# Ravenloft Foundation — Project Chronicle

**Third comprehensive project document, written after the Phase 3 source-grounded area.**
**Document date:** 2026-11-04
**Latest verified run:** 2026-11-03
**Canonical project path:** `C:\Users\Noot Goblin\Downloads\Project Ravenloft\ravenloft-foundation`
**Engine:** Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`)
**Test framework:** GUT 9.6.1 (vendored)
**Phase 3 baseline:** `0ed3b0e59c4826714aa3a5606f86d853a668901f`
**Current automated result:** **98/98 tests, 724 assertions, 11 scripts, exit 0**
**Current state:** playable foundation plus one bounded, source-adapted Ravenloft area; Phase 3 work is uncommitted

> **Purpose.** This is the third comprehensive text document in the project.
> `PROJECT_OVERVIEW.md` is the original foundation overview.
> `PROJECT_COMPENDIUM.md` is the post-Phase 2 technical compendium and reference.
> This chronicle explains how the project reached its current state, what the
> Phase 3 work actually added, how the source-grounded content is bounded, and
> what should happen next. It is a narrative and engineering record, not a
> replacement for the authoritative scope statement in
> `docs/SUPPORTED_FEATURES.md`.

> **Canon and ownership notice.** This is a personal, noncommercial foundation
> project. The Old Gatehouse, its characters, quest and prose are original
> placeholders. The Village of Barovia town square (E3) is a small
> source-adapted excerpt with placeholder prose. The East Gate is a labelled,
> non-canonical developer staging area. The work is inspired by *Expedition to
> Castle Ravenloft* but is not a complete canonical campaign, setting or
> rules implementation. The reference PDFs are private project material and are
> not redistributed.

---

## 1. How to read the project documents

| Document | Role | Authority |
| --- | --- | --- |
| `README.md` | Player-facing entry point, controls, quick start | Current summary |
| `PROJECT_OVERVIEW.md` | Original comprehensive overview | Historical; some counts superseded |
| `PROJECT_COMPENDIUM.md` | Post-Phase 2 technical compendium | Current technical detail |
| `PROJECT_CHRONICLE.md` | This document; project history through Phase 3 | Current narrative and engineering record |
| `docs/SUPPORTED_FEATURES.md` | Exact supported and unsupported scope | Authoritative scope |
| `docs/PHASE2_VERIFICATION.md` | Phase 2 audit evidence | Historical verification |
| `docs/PHASE3_VERIFICATION.md` | E3 selection, adaptation, save policy and Phase 3 evidence | Current phase evidence |
| `docs/TRACEABILITY.md` | Feature-to-source-to-adaptation ledger | Source traceability |
| `docs/AUTHORING_GUIDE.md` | Content authoring and validation | Authoring reference |
| `docs/TEST_REPORT.md` | Latest test commands and results | Verification summary |

If these documents disagree, use `docs/SUPPORTED_FEATURES.md` for scope and the
latest phase verification document for evidence. The older overview intentionally
preserves historical figures and should not be read as the current inventory.

---

## 2. Executive summary

Ravenloft Foundation is a first-person, party-based, data-driven RPG foundation
built in Godot with a deliberately bounded subset of D&D 3.5. It is a vertical
slice, not a campaign. Its purpose is to prove the architecture: exploration,
turn-based combat, dialogue, quests, persistent state, save/load, content
validation and now multi-area travel.

The current build has two kinds of content:

1. **Original demonstration content.** The Old Gatehouse is an invented 11×12
   dungeon with Miruna, Corvin the ghoul, the drowned bell quest, two tactical
   encounters, doors, a shrine and a complete victory loop.
2. **Source-adapted content.** The Village of Barovia town square (E3) is a
   bounded 11×11 excerpt from *Expedition to Castle Ravenloft*. It has Ashlyn,
   a breached eastern barricade, a well, mercantile and tavern references, an
   infected-zombie encounter and a one-time repair consequence.

The two are connected only by explicitly labelled developer waystones. The
project does not claim that the invented gatehouse sits on a canonical road into
Barovia. The East Gate is a developer staging map and is not canonical geography.

At the latest verified snapshot:

- headless import and launch succeed;
- the suite passes 98 tests with 724 assertions across 11 scripts;
- the E3 loop can be entered, played, left, re-entered, saved, loaded and
  completed without repeating its encounter or XP;
- old version-1 saves without area keys load the gatehouse;
- malformed or unknown area destinations are refused rather than guessed;
- no Windows export exists.

The strongest part of the project is its tested state and content pipeline. The
largest unfinished areas are final content, campaign breadth, full native UI
interaction coverage and export packaging.

### Status at a glance

| Area | State |
| --- | --- |
| Godot project and entry scene | Complete and importable |
| Main menu, party select, Continue/Load | Implemented |
| First-person exploration | Implemented with placeholder raycaster |
| Doors, objects, NPCs, triggers | Implemented |
| Tactical combat and combat log | Implemented; bounded rules subset |
| Dialogue, checks and effects | Implemented and data-driven |
| Quest journal and objective tracker | Implemented |
| Multi-area registry and travel | Implemented in Phase 3 |
| Per-area persistence | Implemented for doors, removed/search objects and visited cells |
| Source-grounded E3 excerpt | Implemented and tested |
| Save/load/continue | Implemented; save version 1 |
| Settings and key rebinding | Implemented; interaction coverage incomplete |
| Automated suite | 98/98, 724 assertions, 11 scripts, exit 0 |
| Full native UI click-through | Not performed |
| Windows export | Blocked by missing preset/templates |
| Final art, audio and campaign writing | Out of scope for the current phase |

---

## 3. What the player can do now

### 3.1 Start a new game

The main menu offers New Game, Continue, Load, Settings and Quit. New Game opens
party selection. The player chooses one to four level-3 adventurers from five
pregens:

- Kaelen Dorn, human fighter;
- Sera Vane, rogue;
- Brother Aldric, cleric;
- Ysolde, elf wizard;
- Mira, sorcerer.

The default validation party is Kaelen, Sera, Aldric and Ysolde. The seed is
shown in the header and is saved; the Phase 3 tests use seed `424242`.

### 3.2 Play the original gatehouse loop

The gatehouse remains the main demonstration and regression area. The player can:

1. Explore the 11×12 map, turn, move, look, open doors and inspect objects.
2. Talk to Miruna and accept *The Drowned Bell*.
3. Fight the flooded-stores zombies and recover the bell clapper.
4. Open the crypt, parley with or fight Corvin the gate-warden, and resolve the
   warden objective.
5. Ring the bell, receive victory narration and continue exploring or save.
6. Use the character sheet, inventory, journal, party sidebar and combat log.
7. Save, quit, relaunch, Continue or Load, and recover from defeat.

The gatehouse is original placeholder material. It is not a canonical Ravenloft
location and its quest is not the E3 story.

### 3.3 Reach the source-adapted E3 square

The gatehouse contains a **Demo Waystone (Developer Route)** at the former east
road position. It leads to the **Developer Demo — Village of Barovia Staging
Area**, a 9×9 non-canonical map. The staging area's north waystone leads to the
Village of Barovia town square at arrival position `(5, 9)`, facing north. The
square has a return waystone at `(9, 9)`.

This route exists for QA, demonstration and regression testing. It is not a
canonical road and is labelled in-game as a developer route. A direct QA flag is
also available:

```bash
"../Godot_v4.7.2-stable_win64.exe" --headless --path . --quit-after 90 -- --demo-town-square
```

### 3.4 Play the E3 loop

On arrival, the area entry effect starts *The Lightbringers* and the sidebar
features that quest instead of the gatehouse demo objective. The player can:

1. See the breached eastern barricade directly ahead.
2. Study the breach, or step into it to start `town_square_zombies`.
3. Fight two infected zombies using the normal tactical combat loop.
4. Receive the persistent `town_square_saved` and `ashlyn_survived` flags,
   encounter XP and the Lightbringer quest update.
5. Talk to Ashlyn after the battle. Her dialogue covers the square, Thendrick
   and Mathilda, the church, Madam Eva and the Sunsword as reported leads, not
   implemented destinations.
6. Inspect the well, Bildrath's Mercantile and the Blood of the Vine tavern.
7. Help repair the breached barricade once the square is safe. The repair is a
   one-time interaction and removes the breach object.
8. Save, leave through the demo waystone, return, and observe that the encounter
   and rewards do not repeat.

The complete loop is covered by an automated completion-gate test. The arrival
screen was captured and visually inspected at 1280×720. The full native modal
click-through was not automated.

### 3.5 Save, quit and continue

The game supports `auto`, `slot1`, `slot2` and `slot3`. Autosave occurs after
dialogue completion and combat victory. Manual saving is allowed only while
exploring; saving during combat is refused with a message. Loading restores the
active area, position and facing, per-area state, party, inventory, conditions,
quests, flags, gold, log and RNG state.

---

## 4. Project chronology

The repository has a short recorded history. Earlier work exists in the
project's documentation and source, but the recoverable audit trail begins with
the commits below.

| Stage | Revision | Main work | Evidence |
| --- | --- | --- | --- |
| Foundation before recorded Phase 2 audit | `83c5534` | Original gatehouse vertical slice, party, combat, dialogue, quest and saves | Phase 2 audit baseline: 72 tests, 501 assertions, 8 scripts |
| Phase 2 hardening | `3c0e55d` | Rules corrections, persistence hardening, text-scale layout fixes, regression tests | 84 tests, 615 assertions, 9 scripts; temporary probe reached 84/624 |
| Phase 3 baseline | `0ed3b0e` | Preserved Phase 2 baseline with preliminary area travel | 89 tests, 639 assertions, 10 scripts |
| Phase 3 source area and multi-area work | current working tree | E3 town square, registry, entry effects, tracker, persistence, tests and docs | 98 tests, 724 assertions, 11 scripts |

### 4.1 Foundation

The foundation established the project's boundaries:

- Godot 4.7.2 with a Control-based UI and an autoload session;
- JSON-authored characters, items, spells, monsters, encounters, dungeon,
  dialogue, quests and narration;
- a first-person grid exploration view and a separate tactical combat view;
- a bounded 3.5 rules layer rather than an attempted full implementation;
- save slots, autosave, defeat recovery and settings;
- procedural placeholder art and locally generated placeholder audio.

The original overview describes this period as a complete vertical slice with
two encounters and *The Drowned Bell*. Its inventory and test figures are
historical.

### 4.2 Phase 2 audit and hardening

Phase 2 was an independent verification and correction pass, not just a feature
phase. It checked the rules claims, save behavior, UI layouts and content
pipeline. The recorded baseline was 72 tests; the phase finished at 84 tests and
615 assertions. A temporary content probe raised the count to 624 assertions,
then was removed so the clean suite remained 84/615.

Consequential outcomes included:

- corrected rules behavior and regression coverage;
- atomic save writing and malformed-save handling;
- test save isolation through `user://test_saves`;
- layout corrections at the captured resolutions and 1.6× text;
- an explicit statement that UI construction tests are not full click-through
  tests;
- a documented Windows export blocker: no export preset and no installed export
  templates.

The Phase 3 baseline commit then preserved the state after preliminary area
travel had been added: 89 tests, 639 assertions, 10 scripts.

### 4.3 Phase 3 selection

The Phase 3 goal was not to build the campaign. It was to prove that the
architecture could accept another location without destabilizing the gatehouse.
The selected location needed to be early, small, source-grounded and compatible
with existing systems.

**E3 — Zombies in Town Square** was selected because it is an early village
location with a compact tactical footprint and a clear social follow-up. It
could demonstrate:

- arrival and spatial orientation;
- exploration and inspectable objects;
- an NPC interaction with source-supported leads;
- a rules-driven encounter using the existing combat engine;
- persistent consequences and one-time rewards;
- leaving, returning and saving across areas.

It did not require the church understory, the full village, Madam Eva, the
Sunsword, disease rules, ally AI or barricade cover.

### 4.4 Phase 3 implementation

Phase 3 added four kinds of work:

1. **Content.** A source-adapted E3 area, Ashlyn dialogue, an infected zombie, a
   town-square encounter and the Lightbringers quest.
2. **General engine support.** A manifest-driven area registry, explicit area
   entry effects, a featured area quest tracker, validation for those fields,
   ambient arrival logging and multi-area save/load behavior.
3. **Demo separation.** Relabelled waystones and a clearly non-canonical staging
   map, so the old demonstration does not masquerade as campaign geography.
4. **Verification and documentation.** Focused Phase 3 tests, a full-loop test,
   source traceability, save policy, authoring notes and a verification report.

The implementation does not add a streaming-world system or a general campaign
scheduler. It adds only what the selected area and the existing project needed.

---

## 5. Architecture

### 5.1 Runtime layers

```text
scenes/Main.tscn
    └── src/main.gd
        ├── menus, party selection, modals, settings and routing
        ├── ExplorationScreen
        ├── CombatScreen
        └── defeat/victory presentation

Game autoload (GameSession, src/game_state.gd)
    ├── party and inventory
    ├── active area and per-area states
    ├── world flags and quests
    ├── dialogue and encounter orchestration
    ├── save/load and autosave
    └── seeded RNG

src/core/
    ├── rules, dice, character, battle map
    ├── dungeon and encounter engines
    ├── dialogue and quest state
    ├── content loading and validation
    └── save system

src/ui/
    ├── first-person view and tactical view
    ├── screens, panels and dialogue overlay
    ├── theme and procedural presentation
    └── audio hooks
```

The design boundary is deliberate: rules and persistent state live in
`src/core/` and `src/game_state.gd`; presentation lives in `src/ui/`; authored
content lives in `content/`. UI code calls the session API and reacts to signals
rather than mutating combat or quest state directly.

### 5.2 Main modules

| Module | Responsibility |
| --- | --- |
| `src/main.gd` | Application shell, screen routing, menus and modals |
| `src/game_state.gd` | Session facade: party, world, dialogue, combat, quests, effects, saves |
| `src/core/rules.gd` | Ability modifiers, AC, attacks, saves, skills and checks |
| `src/core/character.gd` | Character model, HP, conditions and serialization |
| `src/core/dungeon.gd` | Exploration grid, doors, NPCs, objects and triggers |
| `src/core/battle_map.gd` | Tactical grid, line of sight and movement |
| `src/core/encounter.gd` | Turn order, actions, attacks, spells and victory |
| `src/core/dialogue.gd` | Dialogue graph, conditions, checks and effects |
| `src/core/quests.gd` | Quest state, objective flags and tracker text |
| `src/core/content_db.gd` | JSON loading, area registry and validation |
| `src/core/save_system.gd` | Versioned save slots and atomic writes |
| `src/ui/first_person_view.gd` | Stylized placeholder raycaster |
| `src/ui/exploration_screen.gd` | Exploration HUD and interactions |
| `src/ui/combat_screen.gd` | Tactical combat presentation |
| `src/ui/panels.gd` | Character sheet, inventory, journal and settings |

### 5.3 Content pipeline

Content is loaded from `res://content` at startup. `ContentDB` builds indexes by
stable id and validates references before play. The current content set is:

- `characters.json`: five pregens;
- `items.json`: 17 items;
- `spells.json`: six implemented spells;
- `monsters.json`: zombie, infected zombie and ghoul;
- `encounters.json`: three battle maps with monsters, cells, XP and effects;
- `dungeon.json`: the original gatehouse;
- `areas/_manifest.json`: registered area list and demo/source metadata;
- `areas/barovia_east_gate.json`: the developer staging map;
- `areas/barovia_town_square.json`: the E3 excerpt;
- `quests.json`: *The Drowned Bell* and *The Lightbringers*;
- `narration.json`: intro, victory, defeat and controls;
- three dialogue files for Miruna, Corvin and Ashlyn.

The content loader rejects malformed manifests, missing area files, id
mismatches and duplicate ids. Area validation also checks NPC dialogue links,
effect types, travel destinations, featured quests and entry effects. Content
errors are shown on the menu/log and do not silently become gameplay behavior.

### 5.4 Why the engine remains small

The project could have grown a scene-streaming system, a general event bus or a
full campaign graph. It did not. The Phase 3 requirement was persistent
multi-area travel for a small number of authored maps. The implemented model is:

- a registry of stable area ids;
- a dictionary of saved per-area dungeon state;
- one active dungeon at a time;
- explicit travel effects with destination and facing;
- general entry effects for content that needs to run on arrival;
- a per-area featured quest for the HUD.

That is enough for E3 and the demo route without committing the project to a
large world architecture that has not been justified by content.

---

## 6. Multi-area world model

### 6.1 Registered areas

| Area id | Name | Role | Size |
| --- | --- | --- | --- |
| `old_gatehouse` | The Old Gatehouse | Original demonstration and regression area | 11×12 |
| `barovia_east_gate` | Developer Demo — Village of Barovia Staging Area | Non-canonical developer staging map | 9×9 |
| `barovia_town_square` | Village of Barovia — Town Square (E3) | Source-adapted excerpt | 11×11 |

The manifest names `old_gatehouse` as the default, lists the two additional areas
as registered, marks `barovia_east_gate` as demo-only and marks
`barovia_town_square` as source-grounded. These labels are documentation and
test metadata; the runtime still validates the actual files.

### 6.2 Travel rules

Travel is expressed as an effect:

```json
{"type": "travel", "area": "barovia_town_square", "pos": [5, 9], "facing": 0}
```

`GameSession.travel_to()` refuses:

- an unknown area;
- travel to the area the player is already in;
- travel while in dialogue or combat;
- an out-of-bounds arrival;
- a non-walkable arrival.

Before leaving, the current dungeon is serialized into `area_states`. On
arrival, saved state for the destination is applied, then the arrival position
is recorded as visited. The player's party, inventory, conditions, quests,
flags, gold and RNG are shared across areas.

### 6.3 Persistent per-area state

Saved area state includes:

- open doors;
- removed objects;
- searched objects;
- visited cells.

The E3 breach is removed after its one-time repair. The encounter trigger is
also gated by `town_square_saved` and the one-shot trigger flag, so returning to
the square does not restart the fight or award XP again.

### 6.4 Entry effects and the featured tracker

An area may declare `entry_effects`, applied after a successful arrival. E3 uses
this to start *The Lightbringers*:

```json
"entry_effects": [
  {"type": "quest_start", "quest": "lightbringers"}
]
```

The area may also declare `tracker_quest`. E3 declares `lightbringers`, so the
sidebar shows the local, source-adapted lead rather than the gatehouse's
*The Drowned Bell*. The tracker falls back to normal active quests when the
featured quest has not started. A completed featured quest shows a complete
line. The field is validated against the quest index.

Entry effects are intentionally described as arrival effects, not one-shot
events. Content authors should use idempotent effects such as `quest_start`.
One-time mechanics belong in triggers or interactions with explicit flags.

### 6.5 Demo separation

The original gatehouse is not presented as canon. The former east road is now a
**Demo Waystone (Developer Route)**. The staging map is labelled as a
non-canonical developer area. The E3 return waystone is labelled as a developer
route. No canonical road is invented to connect the two.

This separation matters because the gatehouse's characters, quest and geography
are original placeholders. The E3 square is source-adapted, but it is still a
bounded excerpt and not the full village.

---

## 7. Source dossier: E3 town square

### 7.1 Source references

| Source | Printed page | PDF page | Use |
| --- | ---: | ---: | --- |
| *Expedition to Castle Ravenloft*, Chapter 2, area E3 | 25 | 26 | First entry from the east, breach, Ashlyn, spatial and NPC facts |
| *Expedition to Castle Ravenloft*, tactical encounter E3 | 36–37 | 37–38 | Infected zombies, barricades, well, mercantile, tavern and post-battle interaction |
| *Monster Manual I*, zombie | 265 | 266 | Zombie baseline used for comparison |
| *Player's Handbook*, combat and skills | 133–160 | 134–161 | Existing supported combat and check rules only |

The project has 43 supplied reference PDFs. `docs/REFERENCE_INDEX.md` records the
printed/PDF page mapping and extraction gaps. The PDFs are not redistributed
with the project.

### 7.2 Why E3 was selected

E3 fits the existing systems and the Phase 3 boundary:

- it is an early-accessible village location;
- its tactical footprint is small;
- it has an NPC with a clear post-battle role;
- it contains a ready encounter premise;
- it has physical details that can be explored without a new renderer;
- it provides natural leads to later campaign material without requiring that
  material to be implemented;
- it can be completed within a bounded excerpt.

The project deliberately did not select a visually impressive location whose
dependencies would force incomplete church, castle or campaign systems.

### 7.3 Included source-supported material

| Element | Implementation |
| --- | --- |
| First entry from the east | The player arrives at the southern/eastern approach, facing the square |
| Breached eastern barricade | Inspectable object and encounter trigger at the gap |
| Ashlyn, Undead Hunter | NPC with dialogue; Lightbringer paladin role preserved |
| Thendrick and Mathilda | Reported in dialogue as having gone to the church |
| Church lead | Dialogue lead only; not a playable area |
| Madam Eva | Dialogue lead only; no fortune-reading implementation |
| Sunsword | Dialogue goal only; not an item or quest chain |
| Village well | Inspectable object in the square |
| Bildrath's Mercantile | Labelled square-facing location; closed during danger |
| Blood of the Vine tavern | Labelled square-facing location; closed during danger |
| Infected zombies | Two creatures using the source's CR 2, 42 HP, AC 16, slam +6 (1d6+4), DR 5/slashing profile |
| Post-battle state | `town_square_saved` and `ashlyn_survived` flags, Ashlyn dialogue and barricade repair |

### 7.4 Deliberate adaptations

The source encounter has nine infected zombies and an entomber. The
implementation uses two infected zombies and no entomber. This is a scale
adaptation for the level-3 validation party and the bounded combat engine, not
a claim that the source encounter has two zombies.

| Source element | Adaptation | Reason |
| --- | --- | --- |
| Nine zombies plus entomber | Two infected zombies | Keep a playable, bounded level-3 fight; avoid unimplemented entomb/exhume |
| Ashlyn as combatant | NPC and dialogue presence | No ally AI or full CR 6 paladin stat block |
| Disease and rising | Deferred | No disease model; would be a new rules subsystem |
| Entomb/exhume | Deferred | Encounter-specific rules not implemented |
| Barricade cover/hardness | Visual and narrative obstacle | Tactical cover/hardness not supported |
| Church, Eva and Sunsword | Leads in dialogue | Dependencies on later campaign material |
| Full village | Bounded square excerpt | Scope control |

The adaptation is documented in `docs/PHASE3_VERIFICATION.md`,
`docs/TRACEABILITY.md` and the Lightbringer quest text. It is not silently
presented as the canonical encounter.

### 7.5 Canon boundary

The E3 excerpt is source-grounded, but it is not a complete adaptation of the
chapter. It preserves the location identity, the breach, Ashlyn's role, the
encounter premise and the reported leads. Placeholder prose stands in for final
writing. The gatehouse and staging map remain invented demo content.

---

## 8. Current content inventory

### 8.1 Counts

| Item | Count |
| --- | ---: |
| Content JSON files | 14 |
| Registered areas | 3 |
| Playable pregens | 5 |
| Items | 17 |
| Spells | 6 |
| Monsters | 3 |
| Encounters | 3 |
| Dialogue files | 3 |
| Quests | 2 |
| Source scripts | 20 |
| Source lines | 7,506 |
| Test scripts | 11 |
| Tests | 98 |
| Assertions | 724 |
| Test lines | 1,632 |
| Generated audio files | 14 |
| Screenshots | 19 |

### 8.2 Adventurers

| Id | Name | Class | Role |
| --- | --- | --- | --- |
| `kaelen` | Kaelen Dorn | Human Fighter | Front-line longsword, chain shirt, heavy shield |
| `sera` | Sera Vane | Rogue | Short sword, light crossbow, skills and sneak attack |
| `aldric` | Brother Aldric | Cleric | Heavy mace, healing, bless and aid |
| `ysolde` | Ysolde | Elf Wizard | Magic missile, mage armor, scorching ray |
| `mira` | Mira | Sorcerer | Alternate arcane caster |

### 8.3 Rules content

- Items: weapons, armor, shields, potions, quest items, rations, torch, holy
  symbol and spellbook.
- Spells: magic missile, mage armor, scorching ray, cure light wounds, bless and
  aid.
- Monsters: zombie, infected zombie and ghoul.
- Encounters: flooded stores, crypt warden and E3 town square.
- Conditions: dying, stable, unconscious, dead, paralyzed, blessed, mage armor
  and aided.
- XP is tracked per character; level advancement is not implemented.

### 8.4 Quests

| Quest | Type | Objectives |
| --- | --- | --- |
| `drowned_bell` | Original demo quest | Speak with Miruna; recover the clapper; face or parley with the warden; ring the bell |
| `lightbringers` | Source-adapted lead | Help hold the square; speak with Ashlyn after the battle |

Quest objectives are driven by world flags. The journal shows active/completed
state, and the compact sidebar shows unfinished objectives for the featured or
active quest.

### 8.5 Stable area and encounter ids

**Areas:** `old_gatehouse`, `barovia_east_gate`, `barovia_town_square`.

**Encounters:** `storeroom_dead`, `crypt_warden`, `town_square_zombies`.

**Dialogues:** `miruna`, `corvin`, `ashlyn_town_square`.

**Doors:** `crypt_door`, `store_door`.

The full stable-id appendix is in `PROJECT_COMPENDIUM.md`.

---

## 9. Rules scope

The project implements a representative subset of D&D 3.5, not the whole
ruleset. The authoritative list is `docs/SUPPORTED_FEATURES.md`.

### Supported in broad terms

- six abilities and standard modifiers;
- AC including armor, shield, Dexterity, size and natural armor;
- HP, healing, dying, stabilization, death and undead destruction;
- initiative and one standard, one move and free actions;
- melee and ranged attacks, critical threats and confirmation;
- damage reduction with bypass types;
- attacks of opportunity for threatened movement and ranged attacks in melee;
- flanking and sneak attack;
- grid line of sight and movement blocking;
- six spells with slots and prepared/known state;
- a bounded set of conditions and durations;
- skill checks for search, Open Lock, Diplomacy, Intimidate, Sense Motive,
  Heal and related actions;
- seeded RNG and auditable combat logs.

### Explicitly not supported

- grapple, trip, disarm, sunder, bull rush, overrun and mounted combat;
- two-weapon fighting and player iterative/full attacks;
- readied or delayed actions;
- turn undead;
- cover, concealment and area-of-effect templates;
- full spell list, components, counterspells and spell resistance;
- character creation, level advancement, multiclassing and prestige classes;
- disease, poison, environmental hazards and long-term campaign state;
- shops, crafting, encumbrance and ammunition;
- ally AI, party splitting and companion control;
- full canonical Ravenloft geography, factions and campaign events.

The E3 encounter uses only supported mechanics. Its scale is adapted rather than
adding unsupported disease, entomb or ally systems for one fight.

---

## 10. Persistence and save compatibility

### 10.1 Save slots and behavior

- Slots: `auto`, `slot1`, `slot2`, `slot3`.
- Manual saves are allowed only in exploration.
- Combat saves are refused with an explanation.
- Autosave occurs after dialogue completion and combat victory.
- Saves are JSON under `user://saves`; tests use `user://test_saves`.
- Settings are stored separately from campaign saves.

### 10.2 Save version 1

The save version remains 1. Phase 3 adds content and area fields without changing
the version. A save contains:

```text
save_version, slot, saved_at, saved_unix
summary, seed, rng_state, party[]
area_id, areas{area_id: dungeon_state}
dungeon{open_doors, removed, searched, visited}
position[x,y], facing, flags{}, quests{}, gold
log[] (last 80), mode="explore"
```

A party entry contains identity, abilities, HP, XP, equipment, inventory, spell
state, effects and conditions. Loading validates content references and party
data before replacing live session state.

### 10.3 Compatibility policy

1. New version-1 saves include `area_id`, `areas` and the legacy `dungeon`
   snapshot.
2. Older version-1 saves without `area_id`/`areas` load the default gatehouse
   and its legacy dungeon state.
3. A save naming an unknown area, or containing malformed area state, is
   refused clearly.
4. Refusal does not overwrite the original file.
5. There is no migration across future schema versions yet; version refusal is
   the current protection.

The save tests cover saving in an area, loading into the correct area and
arrival state, leaving and returning, resolved encounters remaining resolved,
one-time repairs, shared quests and inventory, and a legacy payload without area
keys.

---

## 11. Verification record

### 11.1 Phase 2 evidence

Phase 2 was audited independently and documented in
`docs/PHASE2_VERIFICATION.md`. Its recorded results:

- baseline before the audit: 72 tests / 501 assertions / 8 scripts;
- Phase 2 result: 84 tests / 615 assertions / 9 scripts;
- temporary content probe: 84 tests / 624 assertions, then removed;
- clean import and launch;
- rules and persistence corrections;
- layout verification at multiple resolutions and 1.6× text;
- Windows export still blocked.

The Phase 2 figures are historical and intentionally preserved.

### 11.2 Phase 3 final result

Commands run from the project root:

```bash
"../Godot_v4.7.2-stable_win64.exe" --headless --path . --import
"../Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
"../Godot_v4.7.2-stable_win64.exe" --headless --path . \
  --quit-after 90 -- --demo-town-square
"../Godot_v4.7.2-stable_win64.exe" --path . \
  -- --demo-town-square --capture=phase3_town_square
```

Actual results:

```text
Import:                 exit 0
GUT:                    Scripts 11
                        Tests 98
                        Passing 98
                        Failing 0
                        Asserts 724
                        exit 0
E3 headless demo:       exit 0
Windowed E3 capture:    exit 0, saved
git diff --check:       exit 0
```

The content set validates with zero errors. The final E3 capture shows the area
title, source-grounded arrival notice, party HUD, **The Lightbringers**
objective, barricade interaction prompt and controls at 1280×720.

### 11.3 Completion gate

The test `test_complete_loop_save_quit_load_and_return_without_repeating_rewards`
performs the player-facing sequence:

1. Enter E3 through a travel effect.
2. Step into the breach and start `town_square_zombies`.
3. Resolve the encounter and record XP.
4. Talk to Ashlyn and complete the Lightbringer lead.
5. Repair the barricade.
6. Save, start a new session and load.
7. Verify area, position, flags, quest completion and removed breach.
8. Leave to the staging map and return.
9. Verify no second encounter and no additional XP.

The Phase 3 test file also covers:

- area registry and manifest labels;
- entry effect and featured tracker;
- the demo route in both directions;
- arrival position and facing;
- invalid and blocked transitions;
- encounter persistence and zombie statistics;
- one-time barricade repair and reload;
- Ashlyn dialogue and quest completion;
- legacy saves without area keys.

### 11.4 What was not verified

- The full native UI was not clicked end-to-end: every combat button, save/load
  modal, settings control and focus path is not covered by automation.
- No Windows export was produced or run. The blocker is the missing
  `export_presets.cfg` and empty export-template directory.
- Audio quality was not subjectively reviewed in a final listening pass.
- High-DPI behavior beyond the captured resolutions was not exhaustively tested.
- The source encounter was not reproduced at full tabletop scale.
- There is no full campaign playthrough.

The captured E3 arrival is a visual verification of rendering and layout, not a
claim that the entire interactive loop was exercised through native controls.

---

## 12. Phase 3 change ledger

### Content

- `content/areas/_manifest.json`: area registry and demo/source metadata.
- `content/areas/barovia_town_square.json`: E3 map, Ashlyn, objects, trigger,
  entry effect and featured quest.
- `content/areas/barovia_east_gate.json`: demo staging relabel and forward
  waystone.
- `content/dialogue/ashlyn_town_square.json`: five-node post-battle dialogue.
- `content/monsters.json`: `infected_zombie`.
- `content/encounters.json`: `town_square_zombies`.
- `content/quests.json`: `lightbringers`.
- `content/narration.json`: source/demo distinction in the opening notice.
- `content/dungeon.json`: demo waystone wording.

### Code

- `src/core/content_db.gd`: manifest-driven area loading, area/entry/tracker
  validation.
- `src/core/quests.gd`: featured quest tracker support.
- `src/game_state.gd`: entry effects, ambient arrival logging and tracker
  selection.
- `src/ui/exploration_screen.gd`: uses the area-aware tracker.
- `src/main.gd`: `--demo-town-square` QA launcher.

### Tests and documentation

- `tests/test_phase3_town_square.gd`: nine focused Phase 3 tests.
- `docs/PHASE3_VERIFICATION.md`: source selection, adaptation, persistence,
  actual results and ranked limitations.
- `README.md`, `PROJECT_COMPENDIUM.md`, `PROJECT_CHRONICLE.md`.
- `docs/AUTHORING_GUIDE.md`, `docs/SUPPORTED_FEATURES.md`,
  `docs/TEST_REPORT.md`, `docs/SETUP.md`, `docs/TRACEABILITY.md`,
  `docs/REFERENCE_INDEX.md`.
- `docs/screenshots/phase3_town_square.png`: inspected arrival capture.

The Phase 3 work is uncommitted at this snapshot. The baseline commit remains
recoverable.

---

## 13. Risks and limitations, ranked

### 1. The source encounter is not reproduced at full scale

Two infected zombies replace nine plus an entomber. The source CR/EL and
entomb/exhume mechanics are not present. This is the most important content
fidelity limitation. It is documented and intentional for the bounded level-3
slice, but it means E3 must not be described as a complete adaptation.

### 2. Ashlyn is not a combatant

Ashlyn has a dialogue presence and a Lightbringer role, but no CR 6 paladin stat
block, spells, smite, lay on hands, turn undead, equipment or ally AI. The battle
does not simulate her fighting beside the party.

### 3. The E3 area is a bounded excerpt

The church, understory, cemetery, Madam Eva, the Sunsword, Bildrath's inventory
and the full village are not playable. Dialogue leads point to material that has
not been implemented.

### 4. Native UI interaction coverage is incomplete

The automated suite instantiates screens and exercises state-level flows.
Construction smoke tests are not a full click-through. Save/load modals, every
combat control and focus traversal still need a manual windowed pass.

### 5. Windows export is blocked

There is no export preset and no installed export-template directory. The
project runs from source only. A source-run test is not an export verification.

### 6. Save migration is limited

Save version 1 is protected by refusal, not migration. Future schema changes
need a deliberate migration or refusal policy before public updates.

### 7. Placeholder presentation remains

Art is procedural shapes and billboards; audio is generated placeholders. The
E3 barricade is visually a large block at close range. These are explicit
placeholders, not final assets.

### 8. Content breadth is small

Three areas, three encounters, three conversations, two quests and six spells
are a demonstration. They do not constitute a campaign or broad rules
implementation.

### 9. Test-process teardown noise has occurred intermittently

Earlier runs occasionally printed ObjectDB/resource shutdown warnings while
exiting 0 and passing. The final Phase 3 runs exited cleanly. This is recorded as
historical test-process noise, not claimed as fixed.

---

## 14. Recommended next work

### P0 — Preserve and prove the current state

1. Review and commit the Phase 3 working tree, including the area, tests,
   verification report and screenshot.
2. Perform a manual windowed click-through of the complete E3 and gatehouse
   loops, including every save/load modal and combat control.
3. Record any UI dead ends with the exact command, screenshot and log.
4. Check Windows export prerequisites before claiming an export deliverable.

### P1 — Make the next content addition cheap

1. Keep using the manifest and `entry_effects` rather than adding special cases
   to `GameSession`.
2. Add a content validation command-line mode that exits non-zero on errors.
3. Add more focused per-area tests when a second source-grounded area is added.
4. Consider a small exit/arrival presentation hook only if a second area
   demonstrates the need.
5. Keep the demo gatehouse and staging map clearly separated from canon.

### P2 — Source-grounded expansion

The next source area should be chosen only after checking its dependencies
against the supported rules. A church approach or another bounded early village
location is a better next step than the castle interior or a location requiring
disease, ally AI, cover or full campaign state.

Do not add a large campaign layer merely because the E3 excerpt succeeded. Add
the next smallest area that can be complete, tested and honestly labelled.

### P3 — Presentation and campaign

- replace procedural placeholder art with a consistent original set;
- replace generated audio with original music, ambience and SFX;
- add animation hooks driven by gameplay events;
- add accessibility and localization after content schemas stabilize;
- only then expand into a campaign-scale sequence.

---

## 15. Maintainer playbook

### Run the project

```bash
cd "C:\Users\Noot Goblin\Downloads\Project Ravenloft\ravenloft-foundation"
"..\Godot_v4.7.2-stable_win64.exe" --path .
```

### Import and test

```bash
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . --import
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected current result: **98/98 tests, 724 assertions, 11 scripts, exit 0**.

### Launch directly into E3

```bash
"..\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-town-square
```

### Capture the actual viewport

```bash
"..\Godot_v4.7.2-stable_win64.exe" --path . \
  -- --demo-town-square --capture=phase3_town_square
```

The image is written to `docs/screenshots/phase3_town_square.png`.

### Before editing

1. Confirm the working tree and baseline commit.
2. Run the import and suite; do not infer a pass from stale output.
3. Read the relevant module and content schema.
4. Preserve player saves; tests use `user://test_saves`.
5. For source content, record printed and PDF page references before writing.

### After editing

1. Validate JSON parsing and content references.
2. Run `--import` and the focused test file.
3. Run the full suite.
4. Run a headless launch in the changed area.
5. Capture a windowed viewport when presentation changed.
6. Run `git diff --check`.
7. Update the phase verification, traceability, authoring notes and scope docs.
8. Do not commit unless the user authorizes a commit.

### Content authoring rules

- Use stable ids.
- Put locations in `content/areas/<id>.json` and register them in the manifest.
- Use explicit travel destinations with a walkable position and facing.
- Use flags for one-time events and namespace area-specific flags.
- Use `entry_effects` only for idempotent arrival behavior.
- Use `tracker_quest` when an area has a local lead that should own the sidebar.
- Label source-adapted prose and developer shortcuts.
- Do not invent major lore to bridge missing research.
- Keep demo content separate from source-grounded content.

---

## 16. File and documentation map

### Root

```text
project.godot              Godot configuration, autoloads and input map
scenes/Main.tscn           entry scene
README.md                  player-facing overview
PROJECT_OVERVIEW.md        original comprehensive overview
PROJECT_COMPENDIUM.md      post-Phase 2 technical compendium
PROJECT_CHRONICLE.md       this third comprehensive document
```

### Source

```text
src/main.gd                app shell, menus, routing and modals
src/game_state.gd          session facade and persistent world state
src/core/                  rules, characters, maps, encounters, dungeon,
                           dialogue, quests, content validation and saves
src/ui/                    first-person view, tactical view, screens and panels
```

### Content

```text
content/characters.json    5 pregens
content/items.json         17 items
content/spells.json        6 spells
content/monsters.json      3 monsters
content/encounters.json    3 tactical encounters
content/dungeon.json       original gatehouse
content/areas/             manifest, demo staging map and E3 square
content/quests.json        The Drowned Bell and The Lightbringers
content/narration.json     intro, victory, defeat and controls
content/dialogue/          Miruna, Corvin and Ashlyn
```

### Tests and evidence

```text
tests/                     11 GUT scripts, 98 tests
docs/PHASE2_VERIFICATION.md
docs/PHASE3_VERIFICATION.md
docs/TEST_REPORT.md
docs/screenshots/
```

### Reference and authoring

```text
docs/REFERENCE_INDEX.md    all 43 supplied PDFs and page mapping
docs/TRACEABILITY.md       source-to-implementation ledger
docs/ADAPTATION_LOG.md     consequential design decisions
docs/SUPPORTED_FEATURES.md authoritative scope
docs/AUTHORING_GUIDE.md    content schemas and workflow
docs/ASSET_GUIDE.md        art/audio replacement contract
docs/ROADMAP.md            prioritized continuation plan
```

---

## Appendix A — Glossary

**Area:** a registered dungeon map with a stable id, map rows, objects, NPCs and
triggers.

**Area state:** saved per-area dungeon state for doors, removed objects, searched
objects and visited cells.

**Demo waystone:** an explicitly labelled developer transition, not campaign
geography.

**Entry effects:** content effects applied after a successful arrival in an
area. They are not automatically one-shot.

**Featured tracker:** an area-declared quest that owns the sidebar when it is
active or complete.

**Source-grounded:** derived from a cited source and labelled; not necessarily a
complete or final adaptation.

**Tracker quest:** the `tracker_quest` field that selects a featured quest for
an area.

**Validation party:** Kaelen, Sera, Aldric and Ysolde at level 3 with seed
424242, used for Phase 3 verification.

---

## Appendix B — Snapshot metrics

```text
Engine                          Godot 4.7.2 stable
Test framework                  GUT 9.6.1
Content JSON                    14
Registered areas                3
Pregens                         5
Items                           17
Spells                          6
Monsters                        3
Encounters                      3
Dialogue files                  3
Quests                          2
Source scripts                  20
Source lines                    7,506
Test scripts                    11
Tests                           98
Assertions                      724
Test lines                      1,632
Screenshots                     19
Generated audio files           14
```

---

## Appendix C — Current status statement

At the Phase 3 working tree based on `0ed3b0e`:

- the project imports and launches from source;
- the automated suite passes 98/98 tests with 724 assertions;
- the E3 loop is implemented through the normal session APIs;
- area travel, per-area persistence and the source-grounded tracker are tested;
- old version-1 saves without area keys load the gatehouse;
- malformed destinations are refused;
- a windowed E3 arrival capture was saved and inspected;
- the Phase 3 work is uncommitted;
- no Windows export exists;
- full native UI click-through remains outstanding.

This document describes the project as verified, not the project as imagined.
