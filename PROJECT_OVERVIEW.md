# Ravenloft Foundation — Comprehensive Project Document

**Snapshot date:** 2026-11-03  
**Canonical project path:** `C:\Users\Noot Goblin\Downloads\Project Ravenloft\ravenloft-foundation`  
**Engine:** Godot 4.7.2 stable (`4.7.2.stable.official.ed1daf0bf`)  
**Test framework:** GUT 9.6.1  
**Status:** playable vertical slice complete; documentation complete; automated suite green

> **Post-Phase 2 companion.** This overview is retained as the original
> comprehensive document. For the current verified state, corrected rules claims,
> Phase 2 evidence and residual issues, see `PROJECT_COMPENDIUM.md` and
> `docs/PHASE2_VERIFICATION.md`. Some historical counts below are superseded.

> **Canon and ownership notice.** This is a personal, noncommercial foundation
> project. All locations, characters, quests, prose and art in the game are
> original placeholders. The work is *inspired by* the tone of *Expedition to
> Castle Ravenloft* but is not canonical Ravenloft material. The reference PDFs
> remain private project material and are not redistributed.

> **Workspace note.** A working duplicate exists at
> `C:\Users\Noot Goblin\Downloads\Project Ravenloft - Copy\ravenloft-foundation`.
> A recursive diff before this documentation pass reported no differences, but
> the canonical tree has since received these documentation corrections and this
> overview, so the duplicate is now stale. Treat the canonical path above as
> authoritative; do not edit only the copy.

---

## 1. Executive summary

Ravenloft Foundation is a first-person, party-based RPG foundation built to the
D&D 3.5 rules where practical, with a deliberately bounded rules and content
subset. It is a vertical slice, not a campaign.

The player can:

1. Create a party of one to four level-3 adventurers from five pregens.
2. Explore an original 11×12 gatehouse in first-person grid movement.
3. Talk to an NPC and a speech-capable ghoul, including skill-check branches.
4. Accept and track *The Drowned Bell* quest.
5. Fight two complete tactical encounters: two zombies, then a ghoul and a zombie.
6. Search for the bell clapper, unlock the crypt, parley or fight the warden, and
   ring the bell to complete the objective.
7. Save, quit, load, continue, and recover from defeat.
8. Inspect characters, equipment, inventory, quests and an auditable combat log.
9. Adjust master/music/SFX/ambience volume, text size, display mode and key
   bindings.

The implementation is data-driven: characters, items, spells, monsters,
encounters, the dungeon, quests, narration and dialogue are JSON under `content/`.
Rules and state live in `src/core/` and `src/game_state.gd`; presentation lives in
`src/ui/`; authored content is separate from both.

### Status at a glance

| Area | State |
| --- | --- |
| Runnable project / entry scene | Complete |
| Exploration, interactions, doors, triggers | Complete |
| Party selection, sheets, equipment, inventory | Complete |
| Two combat encounters and combat log | Complete |
| NPC and monster dialogue with checks | Complete |
| Quest, persistence, victory/defeat/recovery | Complete |
| Save/load/continue | Complete |
| Placeholder art and audio | Complete |
| Automated tests | 84/84 passing, 615 assertions, 9 scripts |
| Full D&D 3.5 ruleset | Not attempted; bounded subset |
| Final campaign, art, audio, export | Not delivered |

---

## 2. Acceptance criteria

| Requirement | Evidence | State |
| --- | --- | --- |
| Obvious entry scene and runnable project | `project.godot`, `scenes/Main.tscn`, verified windowed launch | Met |
| Small explorable location | Old Gatehouse 11×12 map, doors, objects, NPCs, trigger | Met |
| Configurable party | Party select, 5 pregens, 1–4 active | Met |
| Character sheet, equipment, inventory | `Panels.character_sheet`, `Panels.inventory`, equip/use APIs | Met |
| Exploration interactions | Look, doors, search, shrine, bell | Met |
| At least one complete combat | Two encounters, victory/defeat | Met |
| Representative attacks/spells/effects/equipment | Weapons, six spells, conditions, DR, potions | Met |
| NPC dialogue | Miruna, six nodes | Met |
| Dialogue-capable creature | Corvin the ghoul, four nodes, parley or fight | Met |
| DM narration | Intro, room looks, combat log, victory/defeat | Met |
| One persistent quest | *The Drowned Bell*, four flag objectives | Met |
| Save/quit/load/continue | Four slots, autosave, RNG/world state restoration | Met |
| Victory, defeat, recovery | Victory screen; defeat screen with load/restart | Met |
| GUT tests | 84 tests, 615 assertions, exit 0 | Met |
| Reference index / traceability | `docs/REFERENCE_INDEX.md`, `docs/TRACEABILITY.md` | Met |
| Adaptation/support docs | `docs/ADAPTATION_LOG.md`, `docs/SUPPORTED_FEATURES.md` | Met |
| Authoring/asset guides | `docs/AUTHORING_GUIDE.md`, `docs/ASSET_GUIDE.md` | Met |
| Setup/test/build instructions | `docs/SETUP.md`, this document | Met |
| Prioritized roadmap | `docs/ROADMAP.md` | Met |
| Final campaign / final assets / export | Out of scope; see limitations | Not delivered |

---

## 3. Quick start and verification

### Run

```bash
cd "C:\Users\Noot Goblin\Downloads\Project Ravenloft\ravenloft-foundation"
"..\Godot_v4.7.2-stable_win64.exe" --path .
```

The Godot executable is inside `Project Ravenloft`, one level above the project.
The main scene is `scenes/Main.tscn`; the game opens at the main menu.

### Test

```bash
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Verified result:

```
Scripts               9
Tests                84
Passing Tests        84
Asserts             615
---- All tests passed! ----
```

### Import after moving the project

```bash
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . --import
```

This registers `class_name` scripts and imports generated audio. It is normally
unnecessary once `.godot/` exists.

### Developer QA launchers

```bash
# Start a new game directly in exploration.
"..\Godot_v4.7.2-stable_win64.exe" --path . -- --demo

# Start in Miruna's dialogue.
"..\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-dialogue

# Start in the flooded-stores combat.
"..\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-combat

# Capture the actual game viewport to docs/screenshots/<name>.png and quit.
"..\Godot_v4.7.2-stable_win64.exe" --path . -- --demo --capture=explore
```

Valid capture names used by the committed screenshots: `menu`, `explore`,
`dialogue`, `combat`.

---

## 4. Player experience

### 4.1 New game and party selection

The main menu offers Continue, New Game, Load Game, Settings and Quit. Continue
and Load are disabled when no compatible save exists. New Game opens a party
selection screen with five pregens; the player chooses one to four and starts.
The intro narration is shown in the exploration log.

### 4.2 Exploration

Movement is grid-based and turn-free in exploration. Each cell is 5 ft. Facing
is one of four cardinal directions. Walls, closed doors and NPCs block movement.
Interacting looks at the cell ahead and can:

- read a door description and open/unlock it,
- open a normal door,
- search a crate or bier with a Search check,
- rest at the shrine (full HP and spell-slot recovery),
- ring the gate bell if the clapper is held,
- start an encounter through a trigger cell.

The first-person view is a column raycaster over the same grid. It is
presentation-only and reads `Game.dungeon`, `Game.position` and `Game.facing`.

### 4.3 Dialogue

Dialogue is a modal overlay with speaker badge, speaker name, prose, choices and
a leave button. Choices can be condition-gated, skill-checked and can apply
effects before or after branching. Disabled choices remain visible with a
reason. The acting adventurer for a check is named in the choice and in the log.

### 4.4 Combat

Combat is turn-based on a 9×7 authored battle map. The UI shows initiative,
round, active combatant, action buttons, enemies-first combatant list, tactical
grid, reachable squares, tokens, HP, conditions, hover distance, legend and a
full log. Players can move, 5-ft step, attack, cast, use a potion, attempt first
aid, inspect and end the turn. Clicking an enemy attacks; clicking a highlighted
empty square moves.

### 4.5 Quest and ending

*The Drowned Bell* has four objectives:

1. Speak with Miruna (`met_miruna`).
2. Recover the clapper from the flooded stores (`found_clapper`).
3. Face or parley with the crypt warden (`warden_resolved`).
4. Ring the gate bell (`bell_rung`).

Completing all four sets the quest complete and raises `victory_pending`; the
main screen shows victory narration. A party wipe routes to a defeat screen with
load/restart recovery.

---

## 5. Controls and interface

### 5.1 Keyboard and mouse

| Action | Default binding |
| --- | --- |
| Move forward / back | `W` / `S`, `↑` / `↓` |
| Strafe left / right | `A` / `D` |
| Turn left / right | `Q` / `E`, `←` / `→` |
| Interact / confirm | `F`, `Space` |
| Party / character sheet | `Tab` / `C` |
| Inventory | `I` |
| Journal | `J` |
| Pause / save / load / settings | `Esc` |

`Esc` is also `ui_cancel` and `pause_menu`; `Main` handles the pause overlay and
modal stack. Buttons mirror every keyboard action.

### 5.2 Screens and modals

- Main menu.
- Party select.
- Exploration with first-person view, party sidebar, quest tracker, action grid
  and narration log.
- Combat with initiative/action/target/log panels.
- Dialogue overlay.
- Character sheet (tabs per party member).
- Inventory/equipment.
- Quest journal.
- Save and load modals.
- Settings (volumes, text size, fullscreen, rebinding).
- Pause modal.
- Victory and defeat screens.

### 5.3 Presentation and accessibility

- 1280×720 reference viewport; `canvas_items` stretch with `expand` aspect.
- Container-based layout; party cards use HP/AC text and bars, not color alone.
- Combat tokens use initials, HP numbers and condition abbreviations.
- Buttons explain unavailable actions through disabled states and messages.
- Text size is adjustable; theme colors and font sizing are centralized in
  `ThemeBuilder`.
- Inspected at 1280×720, 1366×768, 1920×1080, 1024×600 and 1.6× text; high-DPI, mouse-wheel and focus traversal remain untested.

---

## 6. Architecture

### 6.1 Engine and project configuration

| Setting | Value |
| --- | --- |
| Main scene | `res://scenes/Main.tscn` |
| Autoload `Game` | `res://src/game_state.gd` |
| Autoload `Sfx` | `res://src/ui/sfx.gd` |
| Viewport | 1280×720 |
| Renderer | GL Compatibility |
| Audio buses | Master, Music, SFX, Ambience (created by `Sfx`) |
| Input actions | movement, turn, strafe, interact, party, sheet, inventory, journal, pause |
| Icon | `assets/art/icon.svg` |

The entry scene is a single full-rect `Control` with `src/main.gd`. `Main` owns
screen routing, modals, party selection, defeat/victory, settings, save/load
modals and the optional QA capture/demo harness.

### 6.2 Runtime flow

```text
Input / UI
   |
   v
Main (screen router) ---> ExplorationScreen / CombatScreen / DialoguePanel
   |                              |
   |                              v
   +----------------------> GameSession (autoload)
                                  |
        +-------------------------+-------------------------+
        |                         |                         |
        v                         v                         v
     Dungeon                  Encounter                  QuestLog
        |                         |                         |
        +-------------> Rules / Character / Dice <---------+
                                  |
                                  v
                            ContentDB (JSON)
                                  |
                                  v
                         SaveSystem (user:// JSON)
```

Signals keep presentation synchronized:

- `Game.state_changed` → screens refresh.
- `Game.mode_changed` → `Main` routes explore/combat/dialogue/defeat/victory.
- `Game.log_added` → exploration log.
- `Game.combat_finished` → victory/defeat routing.
- `Game.dialogue_finished` → exploration restoration.

### 6.3 Module map

| File | Lines | Responsibility |
| --- | ---: | --- |
| `src/main.gd` | 593 | App shell, menus, party select, modals, routing, QA harness |
| `src/game_state.gd` | 1,050 | Session facade: party, dungeon, dialogue, combat, quests, effects, saves, settings |
| `src/core/dice.gd` | 93 | Seeded dice expressions and detail results |
| `src/core/rules.gd` | 335 | Ability/AC/attack/save/skill formulas and checks |
| `src/core/character.gd` | 429 | Character model, HP, effects, inventory, spells, serialization |
| `src/core/battle_map.gd` | 190 | Grid bounds, movement, reach, LOS, paths |
| `src/core/dungeon.gd` | 288 | Exploration map, doors, objects, NPCs, triggers, state |
| `src/core/encounter.gd` | 1,009 | Initiative, turns, actions, attacks, spells, AI, resolution |
| `src/core/quests.gd` | 130 | Quest state, objective flags, journal text |
| `src/core/dialogue.gd` | 223 | Dialogue graph runner, checks, choices |
| `src/core/content_db.gd` | 349 | JSON loading, content access, validation |
| `src/core/save_system.gd` | 94 | Versioned save slots and listing |
| `src/ui/theme_builder.gd` | 111 | Theme/colors/fonts/widgets |
| `src/ui/first_person_view.gd` | 391 | Raycast exploration view and sprites |
| `src/ui/combat_view.gd` | 193 | Tactical grid, tokens, input |
| `src/ui/exploration_screen.gd` | 359 | Exploration screen composition |
| `src/ui/combat_screen.gd` | 500 | Combat screen composition and actions |
| `src/ui/dialogue_panel.gd` | 168 | Dialogue overlay |
| `src/ui/panels.gd` | 461 | Character sheet, inventory, journal, saves, settings |
| `src/ui/sfx.gd` | 117 | Audio buses, streams, playback, volumes |

### 6.4 Content pipeline

`ContentDB.load_all()` reads:

```
content/items.json
content/spells.json
content/characters.json
content/monsters.json
content/encounters.json
content/dungeon.json
content/quests.json
content/narration.json
content/dialogue/*.json
```

`ContentDB.validate()` checks references and structure: characters/items,
encounters/maps/monsters/cells, dialogue start nodes/links, condition and effect
shapes, quests, spells, dungeon doors/NPCs/objects/triggers. Errors are exposed
in `ContentDB.errors`; tests assert zero errors for shipped content. Missing
content produces clear messages rather than crashes.

### 6.5 Design boundaries

- Mechanics never depend on UI nodes.
- UI reads state and calls `GameSession`; it does not resolve rules itself.
- Content is data, not code; effects are dictionaries interpreted by
  `GameSession.apply_effects`.
- Stable ids are lowercase snake_case.
- Authored placeholders are labelled `(EXAMPLE ...)`.
- RNG is seeded and saved; deterministic tests pass explicit seeds.

---

## 7. Rules implementation

### 7.1 Abilities and derived statistics

- Six abilities; modifier = `floor((score - 10) / 2)`.
- AC = 10 + armor + shield + capped Dex + misc + size; Dodge adds +1 generally
  (tabletop chooses one opponent — documented adaptation).
- Touch AC excludes armor/shield; used for ranged touch spells. Flat-footed AC
  exists as an option in `Rules.armor_class` but is not exposed by gameplay.
- HP, temporary HP, healing, dying/stable/dead, and undead destruction.
- Base attack, base saves, skill ranks, feats, speed and equipment are authored
  per character/monster.

### 7.2 Initiative and turn structure

- Initiative: d20 + Dexterity modifier; descending order.
- Ties are broken deterministically for reproducibility; the roll is logged.
- One standard, one move and free actions per turn.
- 5-ft step is a separate no-provoke move, once per turn.
- Player attacks are one attack per attack action. Multiattack monsters use
  their full natural-attack routine (the ghoul uses bite + two claws).
- End turn advances to the next combatant; monsters act automatically.
- Round counter increments when the order wraps.

### 7.3 Movement, space and line of sight

- 5-ft squares; reach and adjacency use `BattleMap`.
- Diagonal movement costs 5 ft (not tabletop 5-10-5).
- Movement budget is speed minus distance moved; a second move action is refused.
- Blocked cells cannot be entered; occupied cells are avoided.
- Diagonal corner-cutting is checked by `BattleMap._blocked_diagonal`.
- Ranged line of sight uses Bresenham through intermediate cells; walls block
  movement, attacks and spells. There is **no cover or concealment** model.
- Attacks of opportunity are provoked by threatened movement and ranged attacks
  in melee; not every tabletop trigger is implemented.

### 7.4 Attacks, damage and defenses

- Attack = BAB + Strength (melee) or Dexterity (ranged/finesse) + weapon bonus +
  Weapon Focus + bless − range-increment penalties.
- Natural 1 misses; natural 20 threatens. Critical threats are confirmed; damage
  dice are multiplied by the weapon multiplier.
- Damage reduction checks the authored damage type (zombie DR 5/slashing).
- Ranged attacks enforce range increments and maximum range (10 increments) and
  require line of sight.
- Flanking is positional; sneak attack applies when the rogue flanks or attacks a
  helpless target. The engine suppresses sneak attack against undead and
  constructs, matching 3.5 immunity.
- Potions are a standard action; combat use is implemented.

### 7.5 Saving throws and skills

Saving throws are d20 + base save + ability modifier + feat/effect bonuses.
Implemented skills:

`Open Lock`, `Search`, `Spot`, `Listen`, `Diplomacy`, `Intimidate`, `Heal`,
`Move Silently`, `Disable Device`, `Climb`, `Sense Motive`.

Skill totals include ability modifier and armor-check penalty where applicable.
Search and dialogue checks roll d20 + total vs DC and log the actor, die, bonus,
total and outcome. Take 10/20 is not implemented. A stealth subsystem is not
implemented even though Move Silently/Spot exist as skills.

### 7.6 Spells (complete list)

| Id | Name | Level | Resolution |
| --- | --- | ---: | --- |
| `magic_missile` | Magic Missile | 1 | Two missiles at CL 3, each 1d4+1, no attack/save |
| `mage_armor` | Mage Armor | 1 | +4 armor bonus, duration tracked |
| `scorching_ray` | Scorching Ray | 2 | Ranged touch, 4d6 fire, 30 ft |
| `cure_light_wounds` | Cure Light Wounds | 1 | Heal 1d8 + CL (max +5), touch |
| `bless` | Bless | 1 | +1 morale attack to allies; fear saves not modeled |
| `aid` | Aid | 2 | 1d8+3 temporary HP and +1 morale attack |

Prepared casters (Aldric, Ysolde) consume prepared slots; Mira is spontaneous and
uses known spells. Shrine rest restores HP, slots and prepared lists. Components,
concentration, counterspells, metamagic, spellbooks-as-copying, spell resistance
and area templates are not implemented.

### 7.7 Conditions, death and recovery

- `paralyzed`: ghoul bite/claw, Fortitude DC 12, 1d4+1 rounds; elves immune.
- `dying`: 0 to −9 HP; 10% stabilization check at turn start; −10 dead.
- `stable`: no further HP loss; healing can revive.
- `unconscious`, `dead`: cannot act; undead are destroyed at 0 HP.
- Buffs: `bless`, `mage_armor`, `aid`; effects do not stack and expire by round.
- First aid: Heal DC 15, adjacent, standard action, stabilizes a dying character.
- Shrine rest fully restores the party; defeat offers load/restart.

### 7.8 Experience and advancement

XP is authored per encounter (300 for the storeroom, 450 for the crypt), plus
dialogue (200 for Corvin's pact) and the bell (500). XP is saved but there is no
level advancement, feat selection or ability increase. Pregens remain level 3.

### 7.9 Explicitly unsupported rules

Grapple, trip, disarm, sunder, bull rush/overrun, mounted combat, two-weapon
fighting, player iterative/full attacks, readied/delayed actions, turn undead,
domains, spontaneous cleric conversion, familiars, animal companions,
multiclassing, prestige classes, level advancement, crafting, shops, traps,
diseases, poisons, environmental hazards, swimming/climbing, flight, cover,
concealment, area-of-effect spells, spell resistance, counterspells,
concentration, encumbrance, ammunition, item durability, dropping/trading items,
and canonical Ravenloft lore/campaign events.

---

## 8. Content inventory

### 8.1 Adventurers

| Id | Name | Race / class | Level | HP | Role |
| --- | --- | --- | ---: | ---: | --- |
| `kaelen` | Kaelen Dorn | Human Fighter | 3 | 28 | Front-line longsword, chain shirt, heavy shield |
| `sera` | Sera Vane | Human Rogue | 3 | 17 | Scout/lockpick, short sword, 2d6 sneak attack |
| `aldric` | Brother Aldric | Human Cleric | 3 | 21 | Heavy mace, scale mail, cure/bless/aid |
| `ysolde` | Ysolde | Elf Wizard | 3 | 13 | Magic missile, mage armor, scorching ray; elf paralysis immunity |
| `mira` | Mira Vane | Human Sorcerer | 3 | 13 | Alternate arcane caster; spontaneous magic missile/mage armor |

All start with 3,000 XP, standard level-3 base attack/saves, authored feats
(Iron Will, Dodge, Weapon Focus, Weapon Finesse as appropriate) and equipment.
The party select limit is four; Mira is the fifth choice.

### 8.2 Items (17)

Weapons: masterwork longsword, short sword, heavy mace, dagger, light crossbow.
Armor/shields: chain shirt, scale mail, leather armor, heavy steel shield, light
wooden shield. Consumable: potion of cure light wounds. Quest: bell clapper,
gatehouse key. Gear/focus: trail rations, torch, silver holy symbol, traveling
spellbook.

Weapons carry damage, critical range/multiplier, damage type, range increment,
attack bonus and light/finesse flags. Armor carries armor bonus, max Dex, armor
check penalty and arcane spell failure. Weight and value are recorded but weight
is not enforced.

### 8.3 Monsters

| Id | Name | HP | AC | Attacks | Special |
| --- | --- | ---: | ---: | --- | --- |
| `zombie` | Drowned Dead | 16 | 11 | Slam +2, 1d6+1 | DR 5/slashing, undead, single action only, destroyed at 0 |
| `ghoul` | Corvin, the Gate-Warden | 13 | 14 | Bite +3 (1d6+1), 2 claws +1 (1d3+1) | Paralysis DC 12 (1d4+1), undead, destroyed at 0 |

The stat blocks are adaptations of MM pp. 118/265. Ghoul fever is noted but not
implemented. The ghoul is a named, dialogue-capable creature before combat.

### 8.4 Encounters

| Id | Name | Map | Monsters | XP |
| --- | --- | --- | --- | ---: |
| `storeroom_dead` | The Flooded Stores | 9×7, interior pillars | 2 zombies at (6,1), (7,1) | 300 |
| `crypt_warden` | The Gate-Warden's Crypt | 9×7, interior pillars | ghoul at (3,1), zombie at (6,1) | 450 |

Party starting cells are row 5, columns 1–4. Victory effects set
`storeroom_cleared` / `warden_resolved` and `warden_destroyed`, with narration.

### 8.5 Dungeon

```
###########
#....#....#
#.C..#.B..#
#....D....#
####.######
#.....#...#
#.S...#.R.#
#.....D...#
####.######
#.M.......#
#....@....#
###########
```

`#` wall, `.` floor, `D` door cell, letters are floor markers; objects/NPCs are
positioned separately. Start is `(5,10)` facing west (3).

| Element | Position | Notes |
| --- | --- | --- |
| Miruna | (2,9) | NPC, dialogue `miruna` |
| Corvin | (2,1) | Ghoul NPC, dialogue `corvin` |
| Gate Bell | (7,2) | Requires `bell_clapper`; sets `bell_rung` |
| Shrine | (2,6) | Rest and study interactions |
| Supply Crate | (8,6) | Search DC 12; clapper, key, potion, gold |
| Stone Bier | (3,2) | Search DC 14; potion, gold, lore |
| Crypt Door | (5,3) | Locked; Open Lock DC 15 or `gatehouse_key` |
| Storeroom Door | (6,7) | Unlocked |
| Storeroom trigger | (7,7) | Starts `storeroom_dead` if not cleared |

The location and all prose are invented example content, explicitly non-canon.

### 8.6 Quest

`content/quests.json` defines one quest, `drowned_bell`, with title, summary and
four objectives tied to flags: `met_miruna`, `found_clapper`,
`warden_resolved`, `bell_rung`. Completion is flag-driven; the quest journal and
sidebar derive from the flags. Completing the main quest sets victory pending.

### 8.7 Dialogue

- `miruna.json`: 6 nodes; intro, history, Sense Motive secret, denial, rest hint,
  quest acceptance. Sense Motive DC 12; acceptance gives a potion and starts the
  quest.
- `corvin.json`: 4 nodes; introduction, lore, Diplomacy DC 18 / Intimidate DC 20
  parley, failure/insult branch, and a fight option that starts `crypt_warden`.
  The pact yields the clapper and 200 XP without combat.

---

## 9. Narrative framework

### 9.1 Dialogue schema

Dialogue files have `id`, `speaker`, `start`, and `nodes`. Nodes have:

| Field | Purpose |
| --- | --- |
| `speaker` | `npc`, `creature`, `party`, `narrator` |
| `speaker_name` | Display name |
| `text` | Line shown |
| `next` | Auto-advance target when no choices; empty ends |
| `choices` | Player choices |
| `effects` | Applied on node entry |

Choices have `text`, `next`, `conditions`, `effects`, and optional `check`.
Checks have `skill` or `ability`, `dc`, `success`, `failure`, `actor`
(`best` or a character id) and optional `label`. Choice effects apply before the
check; a check overrides the choice's `next`.

### 9.2 Conditions

`flag` (with `value`), `not_flag`, `quest_active`, `quest_complete`, `has_item`,
`skill_at_least`. All listed conditions must pass. Unknown types disable the
choice and are content errors.

### 9.3 Effects

`set_flag`, `clear_flag`, `quest_start`, `give_item` (`qty`,
`only_if_missing`), `remove_item`, `xp`, `gold`, `narration`, `heal_party`,
`start_combat`, `open_door`, `remove_object`, `rest`.

Unknown effects log a content error instead of crashing. Object interactions
add `skill`, `dc`, `once`, success/failure text and success effects; triggers can
start encounters and apply effects.

### 9.4 Validation and authoring

`ContentDB.validate()` checks missing start nodes, broken links, unknown
conditions/effects, missing content ids, invalid cells and malformed actors.
`tests/test_narrative_and_save.gd` asserts the shipped content has zero errors.
The authoring guide documents schemas and a review checklist. New content does
not require core-code edits unless a new effect/condition type is introduced.

---

## 10. Persistence and settings

### 10.1 Saves

- Slots: `auto`, `slot1`, `slot2`, `slot3`.
- Location: `user://saves/*.json`
  (`%APPDATA%\Godot\app_userdata\Ravenloft Foundation\saves`).
- Version: `SAVE_VERSION = 1`; incompatible versions are refused with a message.
- Manual saving is allowed only in exploration; combat/dialogue saves are refused.
- Autosave after dialogue completion and after combat victory.
- Save payload: summary, seed, RNG state, party serialization, dungeon state
  (doors/removed/searched/visited), position, facing, flags, quest state, gold,
  last 80 log lines; `SaveSystem` adds version, slot and timestamps.
- Load reconstructs characters from item definitions, resets encounters/dialogue,
  restores RNG state and returns to exploration.
- Test runs redirect saves to `user://test_saves` by detecting
  `gut_cmdln.gd`; player slots are not touched.

### 10.2 Settings

- Master, music, SFX and ambience volume.
- Text size.
- Fullscreen toggle.
- Per-action key rebinding.
- Settings are stored in `user://` and applied by `GameSession`/`Sfx`.
- Missing audio assets are ignored; invalid saves produce clear messages.

---

## 11. Presentation, art and audio

### 11.1 Visual placeholders

- First-person view: floor/ceiling bands, wall slices, distance fog, sprite
  silhouettes for NPCs and objects, HUD compass, crosshair and interaction prompt.
- Combat view: checker/blocked tiles, reachable overlay, circular tokens with
  initials, HP and condition abbreviations, legend and hover distance.
- UI: dark panel theme, gold headings, blue party/red enemy convention plus text
  and symbols.
- Character sheet/inventory are text-based; there are no portrait textures yet.
- `PLACEHOLDER ART` labels are intentional.

### 11.2 Audio

Fourteen generated WAVs at 22,050 Hz mono: `step`, `hit`, `miss`, `spell`,
`heal`, `bell`, `ui`, `victory`, `defeat`, `door`, `combat`, `music_menu`,
`music_explore`, `ambience_dungeon`. `Sfx` creates Master/Music/SFX/Ambience
buses, loops music/ambience, ignores missing streams and applies volumes.
Audio quality was not subjectively auditioned in the headless verification; the
hooks and import are verified.

### 11.3 Replacement contract

The presentation layer reads gameplay state only. A replacement view can be a
new scene as long as it uses the same `Game` state and, for combat, the
`cell_clicked` signal. Asset ids are stable content ids/sprite strings. The asset
guide covers textures, portraits, audio formats, loop points and missing-asset
fallbacks.

---

## 12. Testing and verification

### 12.1 Automated suite

| Script | Tests | Focus |
| --- | ---: | --- |
| `test_rules.gd` | 14 | Modifiers, AC, touch AC, skills, attacks, finesse, range, saves, crits, seeded rolls |
| `test_character.gd` | 12 | Damage/dying, stabilization, temp HP, equipment, spells, rest, effects, serialization |
| `test_combat.gd` | 15 | Initiative, movement/actions, reach, LOS, AoO, DR, paralysis, spells, victory/defeat, zombie single actions |
| `test_exploration.gd` | 11 | Start, movement, walls, doors, lockpick, search, shrine, trigger, bell, look |
| `test_narrative_and_save.gd` | 12 | Content validation, dialogue effects/conditions/checks, quest, save round trip, refusals, invalid content, audio, party validation |
| `test_integration.gd` | 1 | Full loop from Miruna through storeroom, loot, crypt, parley/fight, bell, save/reload |
| `test_smoke.gd` | 2 | Runner boot and autoload presence |
| `test_ui.gd` | 5 | Main, exploration, combat, dialogue, sheets/inventory/journal/settings/saves construction |

Total: **84 tests, 615 assertions, 9 scripts**. Exit status 0.

### 12.2 Runtime checks performed

- Headless import, main-menu shell, exploration demo, dialogue demo, combat demo.
- Windowed viewport captures at 1280×720 for menu, exploration, dialogue and
  combat; visually inspected.
- Layout fixes: header wrap, view clipping, party overflow, initiative clipping,
  named check actor, Load disabled without saves.
- Save isolation: `user://saves` empty after tests; `user://test_saves` used.

### 12.3 Not verified

- Audible quality of the placeholder audio.
- Exhaustive mouse/keyboard interaction through save/load and rebinding modals.
- Exported Windows build or other platforms.
- Resolutions other than 1280×720 and high-DPI scaling.
- Long-session stability/performance.
- Cover/concealment and the full deferred rules list.
- GUT prints two shutdown diagnostics (`2 ObjectDB instances leaked`, `1
  resource still in use`) after the passing summary; exit remains 0.

---

## 13. Reference sources and traceability

Library: **43 PDFs** in `Downloads\Project Ravenloft\Dungeons and Dragons 3.5`.
All are 3.5-edition books; no separate online-note files were present. The full
inventory with page counts is in `docs/REFERENCE_INDEX.md`.

Primary sources:

| Source | Sections used | Printed / PDF pages |
| --- | --- | --- |
| Player's Handbook | Abilities; Skills; Equipment; Combat; Magic/Spells | 7–10 / 8–11; 61–86 / 62–87; 111–132 / 112–133; 133–160 / 134–161; 169–180 / 170–181; 181+ / 182+ |
| Monster Manual I | Ghoul; Zombie; Undead/DR glossary | 118 / 119; 265 / 266; 305 / 306 |
| Expedition to Castle Ravenloft | Tone/village context; Ch. 1–2 | 5 / 6; 23 / 24; sampled 29 / 30 |
| Dungeon Master's Guide | Light DC/treasure cross-check | no page-specific claim |

Page offset verified as **PDF = printed + 1** in the sampled core pages (PHB PDF
136 footer 135; MM PDF 4 footer 3; ECR PDF 30 footer 29). Extraction used pypdf
because `pdftotext` could not open the folder through the available Windows path
handling; ligatures and image-only pages are recorded as gaps.

Traceability categories in `docs/TRACEABILITY.md`: Supported, Interpreted,
Adapted, Deferred. Canonical Ravenloft lore was not invented; the playable
location is original and labelled.

---

## 14. Consequential adaptations

1. Original neutral gatehouse instead of canonical Ravenloft geography.
2. Four-person party from five level-3 pregens; no level advancement.
3. 5-ft grid; diagonals cost 5 ft instead of 5-10-5.
4. Discrete exploration facing; no combat facing.
5. Bresenham LOS for ranged attacks/spells; no cover/concealment.
6. Partial attacks of opportunity (movement and ranged-in-melee).
7. Deterministic initiative ties.
8. Simple monster AI; zombies use single actions; ghoul uses bite/claws.
9. Six spells; no components/concentration; slots tracked.
10. Shrine full recovery; no campaign-level resource pressure.
11. Dying/stabilization preserved; party wipe routes to recoverable defeat.
12. No encumbrance or ammunition tracking.
13. XP tracked but no advancement.
14. Dialogue checks default to the best conscious actor; named in UI.
15. Autosave after dialogue/victory; manual save only in exploration.
16. Placeholder art/audio, generated locally; no third-party assets.
17. 1280×720 reference UI; scalable containers.
18. GUT 9.6.1 is the verified test version (newer release notice ignored).

Each adaptation is recorded with rationale in `docs/ADAPTATION_LOG.md`.

---

## 15. Known limitations and deferred work

### Content and campaign

- One small dungeon, two encounters, two dialogues, one quest, six spells.
- No canonical Ravenloft setting, campaign, factions, timeline or Strahd plot.
- No character creation beyond choosing pregens; no advancement.
- No shops, crafting, treasure tables, random encounters or multiple areas.

### Rules

- No grapple/trip/disarm/sunder/bull rush, TWF, player iterative/full attacks,
  readied/delayed actions, turn undead, domains, familiars, multiclassing.
- No cover/concealment, AoE templates, spell resistance, counterspells,
  concentration, flight, mounted combat, disease/poison, traps or environment.
- No encumbrance, ammunition, item durability, drop/trade.
- No stealth subsystem despite Move Silently/Spot skills.
- Flat-footed AC is not exposed; Dodge applies generally rather than per target.

### Engineering and QA

- No save migration beyond version refusal.
- No exported build: blocked by missing `export_presets.cfg` and empty export templates.
- GUT teardown leaks/warnings.
- UI interaction coverage is construction-level, not exhaustive.
- Inspected at four window sizes and 1.6× text; mouse-wheel/focus interaction and high-DPI remain untested.
- Simple monster AI; no difficulty system.
- Duplicate project copy can diverge.

### Presentation

- Placeholder shapes and generated audio only; no portraits, icons, animation,
  final music or sound design.
- No localization, controller/touch support, or screen-reader validation.

---

## 16. Prioritized roadmap

### P0 — Harden and verify

1. Manual UI pass: save/load modals, settings, rebinding, every combat action.
2. Audition all placeholder audio and confirm loops/volume behavior.
3. Resolution/DPI pass at 1024×768, 1366×768 and 1920×1080.
4. Decide save-migration policy before public content updates.
5. Produce and test a Windows export; verify `user://`, audio and docs exclusion.

### P1 — Content pipeline

1. Content manifest and `--validate-content` command with non-zero exit on errors.
2. Multiple areas/transitions and persistent per-area state.
3. Quest chains, failure states, prerequisites and journal sections.
4. Encounter waves/terrain tags and per-conversation golden tests.
5. Authoring conveniences (visited/once guards, portraits, node viewer).

### P2 — Rules depth

1. Player iterative/full attacks and two-weapon fighting.
2. Turn undead.
3. Grapple/trip/disarm/sunder/bull rush with contested checks.
4. Cover, concealment and improved LOS.
5. AoE spell templates.
6. Character creation and level advancement.
7. Expanded conditions, disease/poison, fear.
8. Encumbrance/ammunition if the campaign needs it.

### P3 — Presentation and campaign

1. Replace placeholder art with a consistent pixel-art set and portraits.
2. Replace audio with original music/SFX and preserve hooks.
3. Animation driven by gameplay events.
4. Accessibility, localization, controller support.
5. Adapt a bounded original campaign or properly license/adapt ECR; never treat
   the gatehouse as canon.

Every rules change needs a source citation, scope statement, adaptation note and
focused test. Update the supported-features list whenever scope changes.

---

## 17. File manifest

### Source (20 scripts, ~7,000 lines)

```
src/main.gd                          app shell and routing
src/game_state.gd                    session facade
src/core/dice.gd                     seeded dice
src/core/rules.gd                    formulas and checks
src/core/character.gd                character model
src/core/battle_map.gd               grid/LOS/paths
src/core/dungeon.gd                  exploration world
src/core/encounter.gd                combat engine
src/core/quests.gd                   quest state
src/core/dialogue.gd                 dialogue runner
src/core/content_db.gd               JSON load/validate
src/core/save_system.gd              save slots
src/ui/theme_builder.gd              theme/widgets
src/ui/first_person_view.gd          raycaster
src/ui/combat_view.gd                tactical grid
src/ui/exploration_screen.gd         exploration UI
src/ui/combat_screen.gd              combat UI
src/ui/dialogue_panel.gd             dialogue UI
src/ui/panels.gd                     sheet/inventory/journal/settings
src/ui/sfx.gd                        audio
```

### Content (10 JSON files)

```
content/characters.json    5 pregens
content/items.json         17 items
content/spells.json        6 spells
content/monsters.json      2 monsters
content/encounters.json    2 battle maps
content/dungeon.json       11x12 map, doors, NPCs, objects, trigger
content/quests.json        The Drowned Bell
content/narration.json     intro, victory, defeat, controls
content/dialogue/miruna.json   6 nodes
content/dialogue/corvin.json   4 nodes
```

### Tests (8 scripts, 1,118 lines)

`tests/test_rules.gd`, `test_character.gd`, `test_combat.gd`,
`test_exploration.gd`, `test_narrative_and_save.gd`, `test_integration.gd`,
`test_smoke.gd`, `test_ui.gd`.

### Assets

`assets/audio/*.wav` (14), `assets/art/icon.svg`, `docs/screenshots/*.png` (4),
`addons/gut` (vendored), `scenes/Main.tscn`, `tools/capture_window.py`.

### Documentation

`README.md` plus `docs/REFERENCE_INDEX.md`, `TRACEABILITY.md`,
`ADAPTATION_LOG.md`, `SUPPORTED_FEATURES.md`, `AUTHORING_GUIDE.md`,
`ASSET_GUIDE.md`, `SETUP.md`, `ROADMAP.md`, `TEST_REPORT.md`.

---

## 18. Documentation map

| Document | Use |
| --- | --- |
| `README.md` | Player-facing overview, controls, quick start |
| `PROJECT_OVERVIEW.md` | This single-document compendium |
| `docs/SETUP.md` | Run/test/save/troubleshooting/export notes |
| `docs/REFERENCE_INDEX.md` | All 43 PDFs, sections, page mapping, gaps |
| `docs/TRACEABILITY.md` | Feature → source → supported/adapted/deferred |
| `docs/ADAPTATION_LOG.md` | Decisions and rationale |
| `docs/SUPPORTED_FEATURES.md` | Exact scope and limitations |
| `docs/AUTHORING_GUIDE.md` | Dialogue/quest/narration/effect schemas |
| `docs/ASSET_GUIDE.md` | Art/audio replacement contracts |
| `docs/ROADMAP.md` | Prioritized continuation |
| `docs/TEST_REPORT.md` | Actual test commands/results and unverified areas |

---

## 19. Reproduction checklist

1. Open the canonical project path.
2. Run `--import` if `.godot` is absent or class names fail.
3. Run the GUT command; expect 84/84 and 615 assertions, exit 0.
4. Confirm `user://saves` is untouched and `user://test_saves` exists.
5. Run the game windowed; start a new game and choose a party.
6. Explore, talk to Miruna, accept the quest, fight the storeroom, loot the
   clapper, open the crypt, resolve Corvin, ring the bell.
7. Save manually, quit, relaunch, Continue/Load and verify position, HP,
   inventory, doors, flags and quest state.
8. Run the demo/capture flags and inspect `docs/screenshots/`.
9. Report any failure with the exact command, log and state; do not infer a pass
   from a partial run.

---

## Appendix A — Stable content ids

**Characters:** kaelen, sera, aldric, ysolde, mira.  
**Items:** masterwork_longsword, short_sword, heavy_mace, dagger,
light_crossbow, chain_shirt, scale_mail, leather_armor, heavy_steel_shield,
light_wooden_shield, potion_of_cure_light_wounds, bell_clapper, gatehouse_key,
trail_rations, torch, holy_symbol, spellbook.  
**Spells:** magic_missile, mage_armor, scorching_ray, cure_light_wounds, bless,
aid.  
**Monsters:** zombie, ghoul.  
**Encounters:** storeroom_dead, crypt_warden.  
**Quest:** drowned_bell.  
**Doors:** crypt_door, store_door.  
**Flags:** met_miruna, found_clapper, warden_resolved, bell_rung,
storeroom_cleared, warden_destroyed, warden_pact, miruna_trusts,
crypt_door_open, store_door_open, rested_at_shrine, unit_test_flag (test only).  
**Modes:** menu, explore, dialogue, combat, defeat, victory.

## Appendix B — Test inventory summary

`test_rules` 14, `test_character` 12, `test_combat` 15, `test_exploration` 11,
`test_narrative_and_save` 12, `test_integration` 1, `test_smoke` 2, `test_ui` 5.
Total 72. The full test names are in the scripts and summarized by focus in
section 12 and `docs/TEST_REPORT.md`.

## Appendix C — Save payload shape

```text
save_version, slot, saved_at, saved_unix      (added by SaveSystem)
summary, seed, rng_state, party[],            (GameSession.serialize)
dungeon{open_doors, removed, searched, visited},
position[x,y], facing, flags{}, quests{}, gold,
log[] (last 80), mode="explore"
```

Each party entry contains identity, abilities, HP, XP, equipment, inventory,
spell slots/prepared/known, effects and conditions. Loading validates the party
and content, restores the RNG state exactly, and refuses incompatible save
versions rather than silently converting them.

---

*End of comprehensive project document.*
