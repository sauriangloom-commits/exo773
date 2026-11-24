# Narrative Authoring Guide

All narrative content is JSON inside a campaign package under
`content/campaigns/<campaign_id>/`. Shared rules content (items, spells,
characters, monsters) lives once in `content/shared/`. Writers can add dialogue,
quests, narration and consequences without editing the dialogue runner or UI.
The runner is `src/core/dialogue.gd`; effects and conditions are executed by
`src/game_state.gd`; packages are registered in
`content/campaigns/_registry.json` and loaded and validated by
`src/core/content_db.gd`. See `docs/CAMPAIGN_PACKAGE.md` for the package
contract, identifier rules and commands.

## Getting started: build a small campaign

The editor is a long single page. **Save draft**, **Validate draft**, **Playtest
draft**, **Back** and the latest status message stay pinned at the top while the
content scrolls; use them from any section. The status line is where validation
results and refusals appear, so read it before changing anything else.

1. **Campaigns → Create campaign.** Give a title; the id is generated from it
   (`Acceptance Chapel` → `acceptance_chapel`). The id becomes the save identity,
   so keep it stable. **Create and edit** opens the creator.
2. **Areas.** Rename the template area, click a floor cell and press **Set entry
   here** with the intended **Entry facing**. **Add area** creates the second
   9x9 map; select a floor cell, choose the other area under **Passage from the
   selected cell to another area** and press **Add / update passage**. Add a
   passage back so the player can return.
3. **NPCs and dialogue.** In the first area, select a floor cell and press
   **Place NPC here**. Set the display name and look, then **Apply NPC**. The
   generated conversation gets a start node; edit its text and **Apply node**.
   Add named nodes (`success`, `failure`, `thanks`) and give the start node
   responses. A response with **Skill check** selected needs a skill, DC, actor,
   and success/failure destinations. **Add response** then **Apply response** for
   each one.
4. **Campaign flags.** Define the flag the encounter will set (for example
   `beacon_lit`) before binding it to an objective. **Define flag**.
5. **Quests.** **New quest**, set the title and summary, select it as **Campaign
   start** and **Campaign completion**, then **Apply quest**. Edit the generated
   objective: give it an id, text, and the same flag, then **Apply objective**.
6. **Encounters.** **New encounter**, name it, set XP and intro, **Apply
   encounter**, choose a monster and **Add monster**. Set **Victory flag** to the
   objective flag and the victory quest to the quest, then **Apply victory**. The
   victory flag defaults to the quest's first objective flag if left empty.
7. **Encounter triggers.** Select a floor cell in the current area and press
   **Place here**. Leaving the guard empty copies the victory flag, so a cleared
   encounter does not repeat after reload.
8. **Validate draft.** Fix every listed problem, then **Save draft**. Save writes
   the package; Playtest never does.
9. **Playtest draft.** The in-memory draft is staged and launched through the
   ordinary loader with saves disabled. Talk, resolve the check, travel, win the
   encounter, then talk again: a response with **Requires flag** shows the
   changed line. **Pause → Return to campaign creator** returns with the draft
   and without touching the saved package.
10. **Back → Edit** reopens the saved campaign; the campaign card's **New game**
    starts ordinary play, where saving and loading are enabled.

Concrete connection to copy: define `beacon_lit`; objective flag `beacon_lit`;
encounter victory flag `beacon_lit`, victory quest = the quest; trigger guard
empty; dialogue response **Requires flag** `beacon_lit` for the changed line.

### Reading diagnostics and returning to the field

**Validate draft** now lists structured results in the pinned area. Each result
starts with **ERROR** or **WARNING** and keeps its explanation available.
Selecting a result opens the owning section (entry, area, NPC, dialogue, node,
response, quest, objective, flag, encounter or trigger), selects that entity,
scrolls its field into view and focuses it. If an entity form has unapplied text,
the creator first offers **Apply / Discard / Cancel** and navigates only after
the chosen resolution. Cancel keeps the text, selection and focus; Discard is
explicit; Apply validates before changing the draft. A failed Apply keeps the
text and does not navigate. The guarded Apply is all-or-nothing: if any pending
form fails, the complete applied draft is restored, all entered text remains,
and selection/navigation stays put. Campaign-level text and the dirty draft are
still never silently saved by navigation.

A reference selector whose stored id is missing shows **Unresolved reference:
<id>** and keeps that id selected. Opening the entity, editing another field, or
applying an unrelated change does not silently replace it. Choose a valid entry
to repair it intentionally; validation continues to report the missing target.
Clearing a reference is limited to selectors whose schema permits an empty
value.

- **Errors** block save/playtest. **Warnings** do not, and are listed so a
  declared-but-unused flag, undeclared trigger guard or file-only content is
  visible rather than hidden.
- If an entity was deleted or renamed after validation, selecting its old result
  says it no longer exists and asks you to **Validate draft** again. It will not
  silently select a similar-looking entity.
- Results marked **advanced** come from runtime-only/file-only content (doors,
  non-travel objects, instance arrays, or an unmapped legacy rule). The panel
  names the package source; edit that package JSON and revalidate. They cannot
  be fixed from the form editor in this milestone.
- The fixed map, four-monster and flag-only objective limits are unchanged. The
  editor does not auto-repair references or rename ids.

### Recovering from common refusals

| Message / situation | What to do |
| --- | --- |
| “Entry must be on a floor cell” | Select an interior `.` cell (border cells are walls) and press **Set entry here** again. |
| “Select a floor cell…” / trigger refused on the entry or an occupied cell | Pick another interior floor cell; the entry, NPCs and other triggers already occupy theirs. |
| “Cannot delete quest/encounter/dialogue…; still referenced by…” | Remove or repoint the named reference first; the creator never silently breaks references. |
| “used but not defined” | Either **Define flag** deliberately or fix the typo in the objective/response/trigger. |
| “Draft has N problem(s)” | The full list is in the pinned status line; fix the first one, validate again. |
| “Playtest needs a valid draft” | Save is not required, but the draft must validate; fix the reported error and press **Playtest draft** again. |
| Unsaved changes dialog on **Back** | **Save and leave**, **Discard changes and leave**, or **Keep editing**; the draft and its dirty state are preserved until you choose. |
| Pending form edits before switching, saving or playtesting | **Apply** validates and keeps the text, **Discard** explicitly reverts only those form fields, and **Cancel** keeps the text, selection and focus. A failed Apply explains the error and stays on the form. A multi-form Apply is all-or-nothing. |
| **Unresolved reference: missing_id** | The stored id is not in the current draft. The picker is showing the actual invalid value, not a valid substitute. Select a real target to repair it, or fix the referenced content. Saving remains blocked until the reference is valid. |
| “A campaign with that id already exists” | Choose a different id, or open the existing campaign with **Edit**; the dialog stays open so nothing is lost. |
| Campaign folder is missing from the campaign list, or the validator prints “CAMPAIGN PACKAGE ERROR…” | The package’s `campaign.json` could not be read. The validator names the file, the JSON error and its line (for example “not valid JSON: Expected key (line 3)”); the campaign screen shows the same reasons above the list. Fix the JSON, or make the declared `id` match the folder name. The package reappears on the next refresh — no restart and no automatic rewrite. |
| “has no campaign.json” | Every folder under `user://campaigns/<id>/` needs its own manifest. Restore or recreate `campaign.json`; the folder is ignored until it parses. |


### Story-file diagnostics

Area and dialogue files are read by the same loader as the game. A damaged file
is refused, never repaired or replaced with defaults, and the message names the
package-relative file:

- **Syntax:** `Area file areas/area_01.json is not valid JSON: Expected key (line 3).`
  The line is the parser's, converted to the usual 1-based human line.
- **Shape:** `... is valid JSON but not an object; ...` — the file parsed, so no
  line is invented; fix the top-level structure.
- **Missing referenced file:** `Area file areas/missing_area.json is missing ...`
  when an area manifest lists an id with no file.
- **Semantic errors** (bad ids, missing references, entry on a wall) name the
  entity, node or field instead of a line.

`--validate-campaigns` prints these and exits nonzero; `--validate-diagnostics`
carries the same findings as JSON with `code`, `source`, `line`, `campaign`,
`entity_type` and `entity_id`. The campaign screen's **Validate** control shows
the same messages, and selecting a broken package is refused with the first ones.
Repair the file and validate again: the diagnostic clears on the next load, and
other packages are unaffected.

## Ground rules

- Use stable lowercase snake_case ids (`miruna`, `drowned_bell`, `found_clapper`).
- Every file and node is validated on load. Broken links, unknown condition or
  effect types, and missing item/quest/encounter ids produce explicit errors.
- Mark placeholder prose with `(EXAMPLE DIALOGUE)` or `(EXAMPLE CONTENT)`. This
  project's text is not a substitute for final campaign writing.
- Do not copy long passages from the source PDFs. Write original text that fits
  the established tone.
- A new dialogue must also be referenced by an NPC in the campaign's
  `dungeon.json` or one of its `areas/<id>.json` files
  (`"dialogue": "<id>"`), or it will be unreachable even if valid. A package may
  list its areas in an optional `areas/_manifest.json`; without one, every
  `areas/*.json` is loaded.
- Story ids are campaign-local: two campaigns may both define `square`, `guard`
  or `meet_the_keeper`. Shared item, spell, character, monster and skill ids are
  global and come from `content/shared/`.
- A campaign may add *instances* of supported mechanics without editing shared
  files: named NPCs in `characters.json` (`"playable": false` for NPC-only),
  monster variants in `monsters.json`, and unique items in `items.json`, using
  the shared schemas. A local id must not collide with a shared id, and local
  entries add no new mechanics. Local `spells.json` is refused: spells are shared
  rules content, not campaign instances. See `docs/CAMPAIGN_PACKAGE.md`.
- In the game, **Create campaign** starts a writable package under
  `user://campaigns/<id>/`; **Edit** opens it in the Campaign Editor, which
  covers metadata, 9x9 areas, entry/facing, passages, speaker NPC placement and
  a bounded conversation editor (nodes, choices, one skill check, flags and
  narration), quests with flag-bound objectives, declared flags, fixed-layout
  encounters with victory consequences and once-only triggers. Doors, objects
  and unique items remain file-authored and are validated when the draft is
  validated or played.
- Adding flags/quests/items is save-compatible. Changing character or save schema
  fields may require a save-version bump in `SaveSystem`.

## Creature data for turning

Monsters in `content/shared/monsters.json` declare the Hit Dice from their 3.5 stat
block. Never derive Hit Dice from `hp` or `max_hp`.

| Field | Type | Meaning |
| --- | --- | --- |
| `hit_dice` | int | Total Hit Dice of the creature (ghoul 2, drowned dead 2, E3 infected zombie 6). A `0` makes the creature unturnable, so every undead entry needs an explicit value. |
| `turn_resistance` | int | Turn Resistance (MM glossary p. 317). Added to `hit_dice` only when resolving a turn attempt — eligibility, capacity spent and destruction — so it does not change attacks, saves or HP. The standard ghoul has **+2** (2 HD, treated as 4 for turning); the drowned dead and the ECR infected zombie have none. Use `0` when the stat block has none. |

The creature must also be marked undead through `monster_type` (`"Undead ..."`)
or the `undead` tag, or turn undead will ignore it. A cleric's daily uses are
derived from Charisma (3 + modifier) and saved with the character; do not author
a uses field. Test scenarios use the isolated `qa_turn_undead` and `qa_victory`
encounters, which are never referenced by campaign areas or quests.

## Feats, proficiencies and monster hit points

`content/shared/characters.json` and `content/shared/monsters.json` may author a `feats`
array. Only names present in `Feats.CATALOG` are legal. An unknown feat, a
missing parameter or an unmet prerequisite is a content validation error; it is
never applied as a silent bonus.

- Parameterised feats use `Name (selection)`: `Weapon Focus (longsword)`,
  `Skill Focus (search)`, `Martial Weapon Proficiency (longsword)`,
  `Exotic Weapon Proficiency (bastard sword)`.
- Armor proficiency uses the printed names `Armor Proficiency (light)`,
  `Armor Proficiency (medium)` and `Armor Proficiency (heavy)`; the parser
  resolves these to distinct catalog entries.
- Fourteen feats are simple +2/+2 skill feats with no parameters or
  prerequisites: Acrobatic (Jump, Tumble), Agile (Balance, Escape Artist),
  Animal Affinity (Handle Animal, Ride), Athletic (Climb, Swim), Deceitful
  (Disguise, Forgery), Deft Hands (Sleight of Hand, Use Rope), Diligent
  (Appraise, Decipher Script), Investigator (Gather Information, Search),
  Magical Aptitude (Spellcraft, Use Magic Device), Negotiator (Diplomacy, Sense
  Motive), Nimble Fingers (Disable Device, Open Lock), Persuasive (Bluff,
  Intimidate), Self-Sufficient (Heal, Survival) and Stealthy (Hide, Move
  Silently). Author the exact English name; do not add a parenthesised skill.
- Toughness is repeatable and two entries add +6 HP. Extra Turning is also
  repeatable: each prerequisite-valid copy adds +4 daily turning uses. Improved
  Turning is non-repeatable and adds one effective cleric level. Both turning
  feats require the ability to turn or rebuke undead, so a non-cleric entry is a
  validation error. Martial and exotic weapon proficiency may repeat for
  different weapons, but the same selected weapon does not stack.
- Power Attack requires Strength 13 and is chosen once per turn in the combat
  screen, not authored as a number. The engine caps it at current base attack
  bonus; the committed choice applies to that character's melee attacks and
  opportunity attacks until the start of their next turn, then expires. The
  control locks after the standard action is used. Weapons may author
  `"attack_modes": ["melee", "thrown"]` (or `["ranged"]`); when absent, a
  `range_increment` above zero defaults to ranged and other weapons default to
  melee. A thrown or ranged attack does not receive Power Attack.
  `"two_handed": true` doubles the damage addition; `"light_weapon": true` still
  takes the attack penalty but gains no damage. One-handed weapons wielded in two hands are not
  supported. No shipped two-handed weapon currently authors the metadata.
- Combat Expertise requires Intelligence 13 and is also chosen in the combat
  screen, never authored as a number. The engine caps it at
  `min(5, base attack bonus)`. The selected amount stays pending and grants
  nothing until a qualifying melee attack; ranged and thrown attacks discard it.
  After that melee attack the amount applies to the character's melee attacks,
  opportunity attacks and AC as a dodge bonus until the start of their next turn.
  It is lost while flat-footed or helpless and never adds damage. It is
  independent of Power Attack; both may be committed. Fighting defensively, total
  defence and full attacks are not implemented, so do not author content that
  assumes them.
- `proficiencies` is authored data, not inferred from class. Use categories
  (`simple`, `martial`, `all`, `light_armor`, `medium_armor`, `heavy_armor`,
  `shield`) or exact item ids/names (`longsword`, `short_sword`). Proficiency
  feats add grants on top of this list; they do not rewrite it.
- Weapons must author a `category` (`simple`, `martial`, `exotic`). Armor must
  author `armor_category` (`light_armor`, `medium_armor`, `heavy_armor`); shields
  must author `proficiency` (`shield`). Content validation rejects missing or
  unknown values.
- `proficiency_schema` is 2 for current data. Saves without it receive their
  class armor/shield defaults once on load; do not hand-author schema 1. Tower
  Shield Proficiency is not implemented: there is no tower shield item or cover
  mechanic.
- `Character.from_content` adds Toughness HP once on entry. If a printed stat
  block's HP already includes Toughness, author the base without it (the infected
  zombie authors 39 and enters play at 42), or author the final total and set
  `hp_includes_feats` to `true`. Do not do both.
- Secondary natural attacks author their normal base bonus and set
  `"secondary": true`. `Rules.attack_bonus` applies -5, or -2 with Multiattack;
  never bake that penalty into `attack_bonus`.

## Dialogue files

Location: `content/campaigns/<campaign_id>/dialogue/<id>.json`. The file's `id` is the key used by NPCs.

```json
{
  "id": "miruna",
  "speaker": "Miruna",
  "start": "root",
  "nodes": {
    "root": {
      "speaker": "npc",
      "speaker_name": "Miruna",
      "text": "(EXAMPLE DIALOGUE) \"You came up the road...\"",
      "choices": [
        {"text": "What happened here?", "next": "story"},
        {
          "text": "[Sense Motive DC 12] You are not telling me everything.",
          "check": {
            "skill": "sense_motive",
            "dc": 12,
            "success": "secret",
            "failure": "denial"
          }
        },
        {
          "text": "We will find the clapper.",
          "next": "accept",
          "conditions": [{"type": "not_flag", "flag": "met_miruna"}]
        },
        {"text": "We have work to do.", "next": ""}
      ]
    },
    "story": {
      "speaker": "npc",
      "speaker_name": "Miruna",
      "text": "The old warden kept the gate...",
      "next": "root"
    },
    "accept": {
      "speaker": "npc",
      "speaker_name": "Miruna",
      "text": "Search the flooded stores...",
      "effects": [
        {"type": "set_flag", "flag": "met_miruna", "value": true},
        {"type": "quest_start", "quest": "drowned_bell"},
        {"type": "give_item", "item": "potion_of_cure_light_wounds", "qty": 1},
        {"type": "narration", "text": "Quest updated: The Drowned Bell."}
      ],
      "choices": [{"text": "Stay here. We will return.", "next": ""}]
    }
  }
}
```

### Node fields

| Field | Required | Meaning |
| --- | --- | --- |
| `speaker` | No | `npc`, `creature`, `party` or `narrator`; drives the badge/label |
| `speaker_name` | No | Display name; falls back to the file's `speaker` |
| `text` | Yes | The line shown to the player |
| `next` | No | Node to enter automatically when there are **no choices**; empty ends dialogue |
| `choices` | No | Array of choices; takes precedence over `next` |
| `effects` | No | Effects applied when the node is entered (before its text is shown) |

If a node has no choices and `next` is empty, the dialogue ends. A node with a
choice whose `next` is empty also ends the dialogue.

### Choice fields

| Field | Required | Meaning |
| --- | --- | --- |
| `text` | Yes | Player-facing label; include the skill/DC in brackets for checks |
| `next` | Usually | Node to enter. Ignored when `check` is present |
| `conditions` | No | All conditions must pass; otherwise the choice is shown disabled with a reason |
| `effects` | No | Applied **before** the check/branch (loot, flags, quest start) |
| `check` | No | Skill/ability check object; determines `success`/`failure` branch |

A disabled choice stays visible. This is deliberate: the player sees that an
option exists and why it is unavailable, instead of it vanishing silently.

### Check object

```json
{"skill": "diplomacy", "dc": 18, "success": "pact", "failure": "insult", "actor": "best"}
```

| Field | Meaning |
| --- | --- |
| `skill` | A skill id from `Skills.CATALOG` (45 skills; e.g. `sense_motive`, `diplomacy`, `intimidate`, `search`, `heal`, `open_lock`) |
| `ability` | Alternative to `skill`: an ability check (`str`, `dex`, `con`, `int`, `wis`, `cha`) |
| `dc` | Target number |
| `success` / `failure` | Node ids for each outcome |
| `actor` | `best` (default) picks the highest total among conscious party members; a character id pins the actor |
| `label` | Optional display label for the roll |
| `take` | Optional `10` or `20`; uses the take rule and its restrictions instead of rolling |
| `circumstance` | Optional integer circumstance modifier for this check |

The chosen actor and the full roll (`d20`, bonus, total, DC, success/failure) are
written to the log and returned in `Game.dialogue_choose()`'s `check` result.

### Conditions (available types)

```json
{"type": "flag", "flag": "met_miruna", "value": true}
{"type": "not_flag", "flag": "met_miruna"}
{"type": "quest_active", "quest": "drowned_bell"}
{"type": "quest_complete", "quest": "drowned_bell"}
{"type": "has_item", "item": "bell_clapper"}
{"type": "skill_at_least", "skill": "search", "value": 5}
```

All conditions in a choice's `conditions` array must pass. An unknown type is a
content error and disables the choice.

### Effects (available types)

| Type | Fields | Result |
| --- | --- | --- |
| `set_flag` | `flag`, `value` | Sets/updates a persistent world flag |
| `clear_flag` | `flag` | Removes a flag |
| `quest_start` | `quest` | Starts a quest and logs it |
| `give_item` | `item`, `qty`, `only_if_missing` | Gives to the first conscious member |
| `remove_item` | `item`, `qty` | Removes from the party |
| `xp` | `amount` | Awards XP to every member |
| `gold` | `amount` | Adds/removes party gold |
| `narration` | `text` | Adds a DM line to the log |
| `heal_party` | `amount` | Heals every member (default full) |
| `start_combat` | `encounter` | Ends dialogue and starts an encounter |
| `open_door` | `door` | Opens a door by id and sets its flag |
| `remove_object` | `object` | Removes an interactable object |
| `rest` | — | Runs the party rest/recovery routine |
| `travel` | `area`, `pos` `[x,y]`, optional `facing` | Validates and switches to a registered area at a walkable arrival cell |

Unknown effect types log a content error instead of crashing. Adding a new type
requires a handler in `GameSession.apply_effects`, a condition handler if
applicable, and a test.

## Quests

Location: `content/campaigns/<campaign_id>/quests.json`. One object per quest:

```json
{
  "drowned_bell": {
    "id": "drowned_bell",
    "title": "The Drowned Bell",
    "summary": "(EXAMPLE QUEST) ...",
    "objectives": [
      {"id": "speak_miruna", "text": "Speak with Miruna.", "flag": "met_miruna"},
      {"id": "recover_clapper", "text": "Recover the clapper.", "flag": "found_clapper"}
    ]
  }
}
```

- Objectives complete when their `flag` becomes true; there is no separate
  objective API for writers.
- The quest completes when all objectives are complete; the journal and HUD update
  automatically.
- The main quest (`drowned_bell`) sets `victory_pending` on completion; the main
  screen shows the victory narration.
- Keep the journal text short. The sidebar compacts to the title plus up to four
  unfinished objectives.

## Narration

Location: `content/campaigns/<campaign_id>/narration.json`:

```json
{
  "intro": ["Line 1", "Line 2"],
  "defeat": ["..."],
  "victory": ["..."],
  "controls_hint": "Move: W/S ..."
}
```

`intro` is shown at the start of a new game; `defeat` and `victory` are shown by
the corresponding screens; `controls_hint` appears on the main menu. Lines are
plain strings; no BBCode is required.

## Journal notes

Location: `content/campaigns/<campaign_id>/journal.json` (optional):

```json
{
  "format_version": 1,
  "facts": [
    {"flag": "ledger_found", "text": "The ledger names Ivo's debt."},
    {"flag": "told_truth", "text": "You told her what the ledger shows.", "conflicts_with": ["spared_her"]}
  ],
  "questions": [
    {"text": "Who paid for the passage?", "revealed_by": "notice_read", "resolved_by": "epilogue"}
  ],
  "internal": ["tack_room_door_open"]
}
```

The Journal shows `What you know` from `facts` and `Still open` from
`questions`. A fact appears only once its flag is true, in file order, as the
authored sentence — raw flag ids are never printed. `conflicts_with` names the
other half of a mutually exclusive pair; if a save holds both, the fact written
first wins and its partner is suppressed, so the page never shows two versions
of one event.

Questions surface while unresolved: `revealed_by` (optional) must be true before
the question is asked, and `resolved_by` (optional) hides it once answered. Use
`internal` for flags that repeat a fact or only record a door.

Validation rejects a `format_version` other than 1, an entry of the wrong type,
empty text, a flag the campaign never sets, a flag recorded twice, a flag that is
both a fact and internal, and a question revealed and resolved by the same flag.
The shipped-content test additionally requires every flag a campaign can set to be
a fact or internal. A campaign with no `journal.json` keeps working: the Journal
shows the quest log only.

## Areas and travel

Additional locations live in the campaign's `areas/<id>.json`. An optional
`areas/_manifest.json` lists registered files (`default` names the base area,
`areas` lists files, `demo_only` / `source_grounded` are documentation
metadata); without a manifest every `areas/*.json` is loaded and must be
reachable. An area must declare the same `id` as its filename; missing files,
duplicate ids and id mismatches are content errors. Each area has its own
`rows`, `start`, `doors`, `npcs`, `objects` and `triggers`, just like the base
dungeon.

Optional area fields:

- `tracker_quest`: quest id the exploration sidebar should feature in this area.
  It is shown only after the quest starts (or when complete); otherwise the
  normal active-quest tracker is used. The quest must exist.
- `entry_effects`: an effect array applied after a successful arrival. Use
  idempotent effects such as `quest_start`; this is not a one-shot trigger.
  Effects are validated like other content effects.

Use `travel` for explicit exits and entrances:

```json
{"type": "travel", "area": "barovia_town_square", "pos": [5, 9], "facing": 0}
```

Validation rejects missing areas and blocked/non-walkable arrival cells. At
runtime, `GameSession.travel_to` also refuses same-area, unknown-area and
non-exploration travel. The active area and per-area `open_doors`, `removed`,
`searched` and `visited` state are saved; party, inventory, quests and world
flags are shared. Use namespaced flags such as `town_square_saved` for area
consequences.

Keep the invented gatehouse and demo staging separate from source-grounded
content. Label developer shortcuts as such, and mark source-adapted prose and
facts explicitly. Do not invent a canonical road to make the demo geography fit.

## Hooking content into the dungeon

The campaign's optional `dungeon.json` and its `areas/*.json` own the maps and
interactables. Relevant fields:

- `rows`: one string per row. `#` wall, `.` floor, `D` door cell, letters are
  floor markers only. Objects/NPCs are positioned separately and must be on
  walkable cells.
- `start`: `{ "pos": [x, y], "facing": 0 }` where facing is 0 north, 1 east,
  2 south, 3 west.
- `doors`: `id`, `pos`, `name`, `locked`, `lock_dc`, `key_item`, `open_flag`,
  `description`.
- `npcs`: `id`, `name`, `pos`, `dialogue`, `sprite`, `description`.
- `objects`: `id`, `name`, `pos`, `description`, plus search/interaction fields
  used by the example crate/shrine/bell.
- `triggers`: cells that start encounters or apply effects; see the existing
  storeroom and crypt entries.

After editing, run the tests. Content validation must stay at zero errors. The
base dungeon may be `dungeon.json` or a file in `areas/`. Every area referenced
by a `travel` effect or an entry point must exist in the campaign package.

## Editing a conversation in the game

The Campaign Editor's **NPCs and dialogue** section is a node-list/forms editor,
not a graph. It is suitable for short conversations; use JSON for anything
outside its bounded palette.

- Select a floor cell, then **Place NPC here**. The speaker gets a
  campaign-local id, display name, look text and conversation reference. It is
  a speaker only: no character sheet or combat stat block is required.
- A conversation has an id, a start node and nodes. A node has an id, optional
  speaker name, text and an optional `next` for when it has no choices. A node
  with no choices and no `next` ends the conversation.
- A choice either points at a destination node (empty means end) or carries one
  skill check. Choose the skill, DC (1–60), actor (`best` or a default party
  member) and success/failure destinations. The UI and log name the actor who
  rolled.
- The effect/condition palette is limited to: require a flag (stored as
  `not_flag`, so the response hides when the flag is set), show only when a flag
  is set (`flag`), set a flag, and narration. Node effects apply when the node
  opens; choice effects apply before the check. Flags are persistent world
  state and are saved with the campaign.
- Renaming a node rewrites its start, `next`, choice and check references.
  Renaming a dialogue rewrites NPC references. Deleting a referenced node or
  dialogue is refused and names the references; remove or repoint them first.
  Removing an NPC never deletes its conversation. Loops are valid; validation
  reports unreachable nodes separately.
- Editing writes only the draft. **Save draft** writes the package;
  **Playtest** stages a temporary copy of the current draft, launches the
  ordinary loader in playtest mode, refuses all saves, and deletes the copy when
  you return. The deliberately saved package is never overwritten.
- Saving preserves supported content the forms do not expose: doors, object
  interactions and their effects, hand-authored node/choice effects and
  conditions, unknown author keys, declared flags, campaign-local items and
  files the creator does not manage. The package is reopened and rewritten as a
  whole, so changing an unrelated field does not narrow it. If a package stores
  areas, quests, encounters, narration or dialogues inline, uses a newer format
  version, or has a malformed or duplicate content file, loading it for editing
  is refused with a message naming the problem instead of silently dropping it.

## Editing quests, flags and encounters in the game

The creator's **Quests**, **Campaign flags**, **Encounters** and **Encounter
triggers** sections use the same draft/validate/save/playtest flow.

- A quest has an id, title, placeholder description and up to 12 objectives. Each
  objective is bound to one flag (`[a-z][a-z0-9_]*`, 2–64 characters).
  `QuestLog.sync_flags()` credits an objective only after its quest is active, so
  a flag set before the quest starts is not silently completed; it completes on
  the next sync after the quest starts.
- Choose the campaign start quest (required) and optionally a completion quest.
  Only the completion quest raises campaign victory; completing any other quest
  just updates the journal.
- Declare the flags you intend to set. A used flag with no declaration is listed
  as "used but not defined"; define it deliberately or fix the typo. Removing a
  declaration is refused while any content references it.
- Encounters are campaign-local and use one of three fixed layouts. Choose up to
  four shared monsters (`zombie`, `infected_zombie`, `ghoul`), 0–100000 XP, intro
  text, and victory consequences: a flag, narration and an optional quest start.
  Validation checks that every party/monster cell is walkable, unique and inside
  the map.
- Place a trigger on the selected floor cell. It starts the encounter once, sets
  its own spent flag and is skipped on re-entry. The guard flag
  (`requires_flag_not`) is optional; leaving it empty during placement copies the
  encounter's victory flag, which also prevents a repeat after reload.
- Dialogue responses can additionally start a selected quest and start a selected
  encounter; both lists come from the campaign's own definitions.

## Review checklist for a new conversation

1. Every `next`, `success` and `failure` points at an existing node. Run the
   creator's **Validate draft**, which also reports unreachable nodes.
2. Every effect references an existing item/quest/encounter/door/object.
3. At least one path can end the dialogue (`next: ""` or an empty choice exit).
4. Check choices say which skill and DC they use, and the actor is named in the
   UI automatically.
5. Placeholder text is labelled and original.
6. The NPC is placed on a walkable cell and points at the dialogue id.
7. Run:

```bash
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

`test_content_loads_without_validation_errors` fails if the new content is
malformed. Add a focused test when the content introduces a new branch or effect.

### Size, trip and prone data (supported feature)

- `size_category` on characters and monsters is authoritative: one of `fine`,
  `diminutive`, `tiny`, `small`, `medium`, `large`, `huge`, `gargantuan`,
  `colossal`. Authored `size_ac` must equal the category's modifier (content
  validation rejects a mismatch); it is recomputed on load.
- `stability_bonus` is the defender's authored +4 for "more than two legs or
  otherwise more stable than a normal humanoid" (PHB p. 158). Default 0.
- `trip_immune: true` is an explicit property. Never infer it from a name, tag
  or monster type; author it only where the creature's rules say so.
- Weapons used to trip carry `"trip": true` (PHB p. 159 lists spiked chain, dire
  flail, heavy flail, light flail, guisarme, halberd and whip). Weapons usable
  while prone carry `"prone_usable": true` (crossbows and shuriken, PHB p. 151).
- Trip, Stand Up and Pick up are exposed in the combat screen and are verified
  in an exported build for player-initiated Trip against NPCs.
- Improved Trip is authored as the feat string `Improved Trip`; its prerequisites
  are INT 13 and Combat Expertise and are checked on every use, so a character
  without them gains nothing. Do not describe its +4 as a size or general trip
  bonus: it applies only to the attacker's Strength check to trip.
- The Improved Trip follow-up is not tied to the trip method. At the decision the
  player picks any melee attack already in hand — the equipped weapon's legal
  melee modes or an unarmed strike. Do not author content that assumes an unarmed
  trip forces an unarmed follow-up, and do not add a free draw, equip or grip
  change: a different weapon needs the normal equip action.
- QA fixtures: `--demo-trip --trip-scenario=<id>` builds a temporary fighter from
  pregen data (shipped characters and encounters are not edited). Scenarios:
  `success`, `touch_fail`, `counter_drop`, `counter_keep`, `prone`, `stand_aoo`,
  `pickup`, `crawl`, `return`, `improved_trip`, `improved_trip_decline`. Initial
  conditions (AC, stability, prone, ground items, feats) are set up front; no roll
  or outcome is edited afterwards.
- `--trip-probe` is QA-only: it clicks the real buttons, checkbox and map squares
  through the viewport input pipeline, asserts the expected state after each
  step, writes captures to `--trip-shots=<dir>`, and exits nonzero when a check
  fails. Run it in a window: a headless run lays controls out for a larger
  default viewport and cannot judge what a 1280x720 click reaches.
- `--grapple-probe` pairs with `--demo-unarmed` (an empty-handed rogue, a living
  brawler and the shipped zombie). It clicks the real Grapple, Attack, Move and
  Escape buttons and the board squares through the viewport input pipeline, and
  reads the release and the AI escape turn from the encounter log. The fixture
  seeds the grappler's base attack and AC (stated in the check text) so the seeded
  opposed roll lands and the monsters' reactions miss; the living brawler is a QA
  fixture and only the zombie is shipped content. It exits nonzero when a check
  fails; run it in a window for the pointer path.
- `tools/qa/external_input.ps1` drives an exported build with OS mouse events for
  a narrow external-input check; it is not a substitute for the asserted probe.
- Cleave is authored as the feat string `Cleave`; its prerequisites are STR 13
  and Power Attack and are re-checked on every use. The granted attack reuses the
  triggering weapon's data and the attack's own base bonus, so no separate Cleave
  damage entry is authored and no Cleave-only weapon is needed. Target-specific
  modifiers for the new target are recomputed by the engine.
- QA fixtures for Cleave: `--demo-cleave --cleave-scenario=<cleave|
  cleave_decline|cleave_no_target|cleave_from_trip|cleave_offturn|
  cleave_offturn_decline>` and the QA-only `--cleave-probe`, with the same
  windowed requirement, assertions and exit-code contract as the Trip probe.
  `cleave_from_trip` reaches Cleave through Improved Trip's granted attack; the
  two `cleave_offturn` fixtures stage a turned enemy whose flight provokes a real
  opportunity attack that drops it.
- Probe layout switches: `--probe-size=WxH` (does not go below the 1280x720
  minimum) and `--probe-text-scale=<float>` (the largest supported scale is 1.6).
  `--training-probe` drives the visible "Combat Training / Rules Demonstrations"
  menu path instead of a fixture; it asserts training mode is marked and no
  campaign save or XP is involved.
- Any new content that only exists to demonstrate a rules case belongs in the
  training menu (`Main._show_training_menu`), never in the shipped campaign
  parties or pregens, and must not be added to `content/shared/characters.json` feat
  allocations just to showcase it.- A dropped item is ground state, not inventory. Do not add content that assumes a dropped weapon is carried. Recovery after victory is automatic by design and labelled an adaptation; defeat never grants ground items.

## Extending shared systems (extension contracts)

The foundation is the shared places content plugs into. Each contract below has
one owner, one validation path and one kind of test; do not reach around it from
UI or narrative code.

### Authored effects and conditions

`src/core/content_spec.gd` (`ContentSpec`) is the single vocabulary: every
effect and condition type declares its required fields and the content table
each id must exist in. `ContentDB.validate()` uses it for dialogue effects,
conditions, interactions, triggers, area entry effects and encounter victory
effects; `GameSession.apply_effects`/`check_conditions` consult the same registry
before running their handlers.

To add a type:

1. Add the row to `ContentSpec.EFFECTS` or `ContentSpec.CONDITIONS`.
2. Add the handler branch in `GameSession.apply_effects` or `check_conditions`.
3. Add the type to the reference table in this guide.
4. Add a focused test in `tests/test_extensibility.gd`.

Unknown types, missing required fields, wrong field kinds, unknown skills and
missing item/quest/encounter/area ids are validation errors with explicit text
(`dialogue 'x' node 'y' effect 'give_item' references missing item 'z'`).

### Passive and conditional modifiers

A passive feat is a `Feats.CATALOG` row, not a handler: `name`, `page`,
`benefit`, `prereqs`, `repeatable`, `stacks`, and `modifiers` entries of
`{target, value, type}`. Targets are `save:fort|ref|will`, `ac`, `initiative`,
`hit_points`, `attack`, `damage`, `skill:<key>` and `skill` (parameterised Skill
Focus); `weapon_parameter` narrows a weapon-specific bonus, and `condition`
currently supports `ranged` and `max_distance_ft`. Prerequisites are re-checked
on every use, so a lost prerequisite suspends the benefit.

Target-specific circumstances are evaluated where the roll happens
(`Rules.armor_class`, `Rules.attack`, `Rules.damage_bonus`), never baked into a
stored total. That is why Cleave can preserve an attack's own base and still
re-evaluate helpless, cowering, prone, flanking and reach for a new target.

A modifier that needs a new target name or a new condition key is a small
handler change in `Feats.modifier` plus `Rules`; it is not a new subsystem.

### Active actions, costs and decisions

An active combat option is an `Encounter` method that:

- checks `has_pending_decision()` and the actor's `can_act()`;
- spends the action/resource **before** the roll (`turn_state`, `aoo_used`,
  `cleave_used`, spell slots, turning uses);
- returns a result dictionary (`ok`, `message`, and rule fields such as roll,
  bonus, DC, total, damage) that UI, logs and tests all read;
- logs through `_log()` and emits `changed` so no caller recomputes rules.

A player decision is an explicit pending dictionary on `Encounter`
(`pending_trip`, `pending_cleave`), a resolver method, a `has_pending_decision()`
entry and a `CombatScreen._rebuild_decision()` branch. Off-turn decisions must
store a bounded resume record (plain data) and call `resume_interrupted()` after
resolution; never transfer turn ownership and never recurse into another action
call.

### Frequency, reactions and interrupted actions

Once-per-round or per-day limits live on the encounter or character
(`cleave_used`, `aoo_used`, `turn_undead_used`) and are cleared at the documented
boundary (round start, new turn, rest). Reactions resolve through
`_resolve_attack(..., reaction: true)` so they spend no action from the
reactor's own turn. Interrupted routes are data (`off_turn_resume`), resumed
once, and abandoned when the actor, target or encounter is no longer valid.

### Checks and opposition

Use `Skills.check`, `Skills.opposed_check` and `Rules.opposed_ability_check`.
They return the roll, bonus, total, DC and a breakdown; UI and dialogue format
those results with `Skills.format_check`, never by re-deriving totals. Take
10/20, retry rules, synergies, armor penalties and aid-another all live in the
same module.

### Persistence and demonstration isolation

Serialisable state belongs on `Character`/`GameSession` and must round-trip
through `SaveSystem` (schema fields are versioned). Encounter-only state stays
unsaved. Training and command-line demonstrations set `Game.training_mode`,
which suppresses victory effects, XP and the autosave, so a demonstration can
never overwrite a player's slots.

### Where a new option belongs

| Class | Meaning | Example |
| --- | --- | --- |
| A. Data-only | uses a registered shape and existing ids | a dialogue choice gated by `flag` with `set_flag`/`narration` effects; a +2/+2 skill feat row; a `Weapon Focus (longsword)` selection |
| B. Small handler | one new branch behind an established interface | Power Attack's trade (`Feats.power_attack_*` + `Rules.attack` opts); a new attack-mode weapon field; a condition on an existing modifier target |
| C. New subsystem | needs shared state, timing or resolution that does not exist | full attacks/iterative chains (Great Cleave), persistent stealth/cover, item creation, metamagic |
| D. Unsupported/adapted | deliberately out of scope or documented divergence | mounted combat, Tower Shield cover, Dodge applied generally instead of against one designated opponent, dropped-item recovery after victory |

Do not stretch A or B to cover a C. Record the class in the coverage manifest
before implementing, and keep D labelled in `ADAPTATION_LOG.md`.

### Authoring walkthrough (data-only)

1. Add a dialogue choice with `"conditions": [{"type": "flag", "flag": "met_miruna"}]`.
2. Add `{"type": "set_flag", "flag": "example_seen", "value": true}` and a
   `narration` effect to the next node.
3. Run the suite. Validation checks the vocabulary, the field shapes and every
   referenced id; the choice renders disabled with a reason when the flag is
   absent.
4. No engine, UI or test file changed. If the choice needs a new effect type,
   follow the four contract steps above instead.

## Saves and later package edits

A save pins the campaign id, `content_version`, the saved area and the saved
cell. Saving does not copy the package, so editing a campaign after a save is a
content-compatibility question, separate from the save format.

Edits that keep those references valid load normally:

- changing prose (description, narration, dialogue text) — no version bump;
- moving the campaign entry — existing saves stay at their saved cell, not at the
  new entry;
- removing a flag declaration — stored flag values remain; declarations are
  authoring metadata, not the save's flag storage.

Edits that remove the saved world or progress are refused before the live session
is replaced:

- deleting the saved area, or shrinking the area;
- turning the saved cell into a wall, or moving it out of bounds;
- removing or renaming a quest or objective the save recorded;
- changing `content_version` in `campaign.json`;
- an unsupported save format or a missing campaign.

The refusal names the campaign, area, cell, quest or objective where applicable,
states that the save was not modified, and leaves the current session, package,
other campaigns and save slots alone. Restoring the compatible content lets the
same save load again; nothing is auto-repaired or migrated.

The creator can move the entry and can delete an unreferenced quest. Removing an
area, removing a flag declaration, or changing `content_version` is supported
file authoring. For a deliberately incompatible edit, set the integer `version`
in the campaign's `campaign.json` once and record why; do not bump it for prose
or other compatible edits, and do not use a blanket content hash.
