# Campaign Package Contract

A campaign is a **content package**, not a code branch. The engine loads shared
rules content once, then one campaign's story content. Adding a campaign means
adding files under `content/campaigns/<id>/` (bundled, read-only) or under
`user://campaigns/<id>/` (player-authored, writable); it does not mean editing
`main.gd`, `content_db.gd`, or any other script.

The in-game **Create campaign** entry writes a user package from the neutral
template. The **Campaign Editor** covers metadata, 9x9 areas, entry points,
passages, speaker NPCs and branching conversations. Encounter, quest, door,
trigger and object editing remain file-authored. This document is the contract
the loader and validator enforce today.
`docs/CONTINUATION_BRIEF.md` records what is verified and what remains.

## Layout

```
content/
  shared/                      shared rules content (one copy for every campaign)
    items.json
    spells.json
    characters.json
    monsters.json
  campaigns/
    _registry.json             installed campaign ids and the default
    <campaign_id>/
      campaign.json            manifest (see below)
      dungeon.json             optional; one area may live here
      areas/<area_id>.json     campaign-local exploration maps
      dialogue/<dialogue_id>.json
      quests.json              campaign-local quests
      encounters.json          campaign-local tactical encounters
      narration.json           intro / victory / defeat / controls hint
      journal.json             optional; authored Journal notes (facts, questions, internal flags)
```

Player-authored campaigns use the same layout under
`user://campaigns/<id>/` (on Windows, `%APPDATA%\Godot\app_userdata\Ravenloft Foundation\campaigns\<id>`). `CampaignStore` scans that directory at startup and
whenever the campaign list refreshes; no registry edit or compiled list is
needed. Bundled packages stay under `res://content/campaigns/` and are never
written by the game. A user package may not reuse a bundled campaign id, and a
duplicate user id is refused instead of overwritten.

Shared rules tables are global identifiers. Story tables are campaign-local
identifiers. A campaign may reference shared items, spells, characters and
monsters by id, and may **not** replace a shared id. It may define *instances*
of supported mechanics in a campaign-root table:

| Local table | Allowed content |
| --- | --- |
| `items.json` | Named items using the shared item schema (unique equipment, quest objects, consumables) |
| `monsters.json` | Named monster variants using the shared monster schema and supported mechanics |
| `characters.json` | Named NPCs and pregens using the shared character schema; `"playable": false` keeps an NPC out of party selection |
| `spells.json` | **Refused.** Spell definitions are shared mechanics, not campaign instances. |

A local instance id must not exist in the shared table; a collision is a named
validation error. Local entries may use any supported field, but they add no
new mechanics and cannot require engine changes. Only the currently loaded
campaign's story tables and local instances exist in memory, so two campaigns
can reuse the same area, quest, dialogue or instance id without ambiguity or
collisions.

Within one package, duplicate area, dialogue, quest, encounter or objective ids
are errors. Missing references — an NPC dialogue, a travel target, a quest flag,
an encounter monster — are errors, not silent no-ops.

## `campaign.json`

```json
{
  "format_version": 1,
  "id": "hollow_lantern",
  "title": "The Hollow Lantern (Neutral Example)",
  "description": "(EXAMPLE CAMPAIGN) One night at a roadside lighthouse.",
  "status": "example",
  "version": 1,
  "content_root": "res://content/campaigns/hollow_lantern",
  "start_quest": "lantern_watch",
  "completion_quest": "lantern_watch",
  "entry": {"area": "lantern_yard", "pos": [4, 7], "facing": 0},
  "party": {"default": ["kaelen", "sera", "aldric", "ysolde"], "min": 1, "max": 4},
  "requires": {
    "capabilities": ["exploration", "dialogue", "combat", "quests", "saves", "skills", "travel", "narration"]
  }
}
```

| Field | Meaning | Validation |
| --- | --- | --- |
| `format_version` | package contract version | must equal `1` |
| `id` | stable campaign identity | `[a-z][a-z0-9_]*`, equals folder name |
| `title`, `description` | player-facing text | required, non-empty |
| `status` | `example`, `ravenloft-derived`, or similar label | free text |
| `version` | content version, saved in every save | integer ≥ 1 |
| `content_root` | package directory | defaults to the folder |
| `start_quest` | quest started on new game | must exist in the package |
| `completion_quest` | quest whose completion shows victory narration | must exist, or empty |
| `entry` | starting area, position, facing (0=N,1=E,2=S,3=W) | area exists, position walkable |
| `party.default` | preselected party | each character exists |
| `party.min` / `party.max` | new-game party size, enforced by party selection and `new_game` | 1–4, min ≤ max |
| `requires.capabilities` | platform features the package uses | every value must be supported |

Supported capabilities: `exploration`, `dialogue`, `combat`, `quests`, `saves`,
`skills`, `feats`, `travel`, `narration`. An unknown required capability makes
the package invalid instead of failing later at runtime.

`party.min` and `party.max` bound who may start a new game. They are not a
save policy: a save records the party it was played with, loading never
re-checks the minimum, and raising `min` does not invalidate existing saves.
`version` is the load-compatibility field; raise it only when campaign data
changes in a way old saves cannot load.

`_registry.json`:

```json
{"format_version": 1, "default": "ravenloft_demo", "campaigns": ["ravenloft_demo", "hollow_lantern"]}
```

### When a package is not listed

Discovery reads `campaign.json` only. A package whose manifest is missing, is not
valid JSON, is not a JSON object, declares an id that differs from its folder, or
whose folder is not a valid campaign id is skipped — the game never guesses at a
damaged manifest or rewrites it. Instead:

- `--validate-campaigns` prints `CAMPAIGN PACKAGE ERROR: <reason>` for each one,
  including the JSON error line, and exits nonzero.
- The campaign selection screen shows the same reasons above the campaign list.

Fix the file (or the folder/id pair) and refresh: the package is discovered again
on the next scan and the stale diagnostic disappears. The end-to-end failure and
recovery are exercised by `tests/test_campaign_discovery.gd` and by the exported
candidate check recorded in `docs/TEST_REPORT.md`.


Registry order is display order. A missing or invalid default is reported and
the first installed campaign is used.


### Story-file validation

A package whose manifest is readable but whose **story files** are damaged is
listed, then refused when selected or validated. The loader reports the
package-relative file and the parser line for malformed area or dialogue JSON
(`areas/area_01.json ... (line 3)`), a distinct message with no line for valid
JSON of the wrong shape, and the missing filename for an area listed in
`areas/_manifest.json` with no file. `--validate-campaigns` exits nonzero,
`--validate-diagnostics` carries `code`, `source`, `line`, `campaign`,
`entity_type` and `entity_id`, and the campaign screen's **Validate** control
shows the same text. Repairing the file clears the diagnostic on the next load;
the damaged file is never rewritten and the active campaign is never replaced by
a partial load.

## Persistence

- A save lives at `user://saves/<campaign_id>/<slot>.json`.
- The save records `campaign_id` and `content_version`.
- Loading a save from another installed campaign switches campaigns explicitly;
  a save from a missing campaign is refused with a message.
- A content-version mismatch is refused. Neither loading nor saving overwrites
  an incompatible save.
- Saves written before campaigns existed (`user://saves/<slot>.json`) are read
  as `ravenloft_demo` saves and are never rewritten; new writes go to the
  campaign directory.
- Training/demo sessions never write campaign saves or grant campaign rewards
  (`Game.training_mode`).

## Authoring and verification commands

From `RL_Edit`:

```bash
# List installed packages
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -- --list-campaigns

# Validate every package; exits nonzero if any package is invalid
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -- --validate-campaigns

# Start one package through the ordinary new-game path and assert its entry
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -- --campaign-probe=hollow_lantern

# Launch a specific campaign for manual play
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --path . -- --campaign=hollow_lantern

# Focused tests, then the full suite
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_campaign_packages.gd -gexit
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Create from the neutral template, then edit/validate/playtest through the UI
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --path . -- --demo-creator

# End-to-end backend probe: create, add area, link, entry, validate, save,
# playtest travel, save refusal, relaunch discovery, cleanup. Nonzero on failure.
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-probe

# Asserted UI probe: creator controls, save, playtest, pause/return, Edit. Nonzero on failure.
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-ui-probe

# Asserted end-to-end authoring probe: place a speaker, author nodes/choices,
# a skill check and flag consequence, validate, save, reopen, playtest, talk and
# return. Nonzero on failure.
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-interaction-probe

# Asserted authored-story probe: quest -> travel -> placed encounter -> victory
# once -> changed NPC response -> completion, plus playtest isolation, ordinary
# save/reload and cross-campaign isolation. Nonzero on failure.
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-story-probe

# Windowed inspection of the quest/encounter editors
"../Project Ravenloft/Godot_v4.7.2-stable_win64.exe" --path . -- --demo-creator-interaction \
  --creator-focus=encounters --text-scale=1.6
```

The in-game **Campaigns** screen lists every package with New game / Continue /
Load slot / Validate; user packages also show **Edit**. It is the player-facing
proof that bundled and user packages use the same pipeline.

## What the creator covers now

A player can, without editing files:

- Create a writable campaign from the neutral template (title and stable id).
- Reopen it from the campaign list with **Edit**.
- Change the title and description.
- Add 9x9 areas, rename them, toggle interior cells between wall and floor.
- Set the entry area, position and facing.
- Link two areas with a supported travel passage.
- Place a campaign-local speaker NPC on a floor cell with a display name, look
  text and optional conversation. The NPC is only a speaker; no combat stat
  block is required.
- Create and edit a conversation in a node-list/forms editor: dialogue id and
  start node; node id, speaker name, text and `next`; choices with a plain
  destination or a skill check (skill, DC 1–60, actor `best` or a default party
  member, success and failure destinations).
- Use the bounded effect/condition palette: require a flag (hide when absent),
  show only when a flag is set, set a flag, and narration. Node effects apply
  when the node opens; choice effects apply before the check. Flags persist in
  saves.
- Rename nodes and dialogues with incoming references updated, or receive a
  refusal naming every reference. Legitimate loops are allowed; validation
  distinguishes cycles from unreachable nodes. Removing an NPC keeps its
  conversation.
- Define campaign-local quests: title/description, up to 12 objectives each
  bound to an explicit flag, and the campaign start/completion quest. Completion
  is optional, so a finished quest does not end every campaign.
- Declare campaign flags deliberately; used-but-undeclared flags are listed so a
  typo stays visible. Rename quests/encounters with references updated; delete is
  refused while anything references them.
- Create a campaign-local encounter from three fixed battle-map templates (7x5
  room, 9x5 hall, 9x7 crypt), up to four shared monsters (`zombie`,
  `infected_zombie`, `ghoul`), bounded XP, intro text, and legal party/monster
  cells per layout.
- Connect victory to a flag, narration and an optional quest start; place an
  encounter trigger on a floor cell with an optional once-only guard.
- Validate the draft (shape checks plus a temporary package loaded through the
  real `ContentDB`) and see the errors in the creator.
- Save atomically to `user://campaigns/<id>/`.
- Playtest an in-memory snapshot: the draft is validated, staged under
  `user://playtest/<id>/`, loaded through the ordinary loader with
  `Game.playtest_mode`, and deleted on return. The deliberately saved package is
  never overwritten and the draft keeps its dirty state.

### Conversation draft model

Editing changes only the in-memory draft. **Save draft** is the only action that
writes `user://campaigns/<id>/`; it validates first and writes atomically.
**Playtest** validates the same draft, stages a temporary package under
`user://playtest/<id>/` and launches the ordinary loader with
`Game.playtest_mode` set. It does not save, cannot overwrite an ordinary slot,
never grants rewards to the authored package, and **Return** deletes the staged
copy and restores the creator with the draft and its dirty state intact.
Validation failure, cancellation and playtest-start failure leave both the draft
and the saved package untouched.

Saving rewrites the package as a whole and carries forward content the forms do
not expose: doors, object interactions and effects, hand-authored dialogue
node/choice effects and conditions, unknown author keys, `flag_definitions`,
campaign-local `items.json` and unmanaged files such as `dungeon.json`. Because
the creator cannot represent every package shape, loading refuses a package that
stores `areas`, `quests`, `encounters`, `narration` or `dialogues` inline, uses a
newer `format_version`, has a non-object content file (valid JSON of the wrong
shape), or repeats an
area/dialogue id. Refusal names the offending file or field; it never saves a
narrowed copy over the original.

## What is not built yet

- A battle-map editor or monster-stat editor. Encounters use three fixed
  templates with four party cells and at most four monsters; statistics, new
  spells and tactical AI remain code/data owned. Objectives are flag-driven;
  there is no quest scripting language, scheduler or failure-state framework.
- A node-graph canvas or an unrestricted effect/condition picker. The creator
  is deliberately a node list with forms and the bounded palette above;
  hand-authored effects outside that palette are preserved when the form is
  applied (tests cover this round trip), not presented as editable controls.
- Map layouts larger than one 9x9 area, and door/object/unique-item placement in
  the creator. Those remain file-authored and validated.
- A portrait/audio/localisation authoring flow.
- A packaged-campaign export/upload format. Campaign folders currently ship
  inside the project (bundled) or live in the player's user directory
  (authored); there is no mod upload/install flow.
- A universal scripting language. Effects and conditions are a fixed, validated
  vocabulary (`src/core/content_spec.gd`), extended in code when necessary.

### Saves and later package edits

`content_version` is the author's compatibility marker. The creator keeps it at
1 and does not bump it automatically. A save stores the campaign id, that
version, the area, the cell and the quest/objective state.

On load, the existing state is validated before anything live is replaced:

- the saved area must still exist in the package;
- the saved cell must be in bounds and walkable after the saved doors/state are
  applied;
- every saved quest and objective must still be defined;
- the saved `content_version` must equal the installed campaign's version.

A failed check returns an actionable refusal and leaves the save bytes, current
session, package, other campaigns and slots untouched. There is no teleport to
the entry and no silent discard of progress. Prose edits, entry moves and removed
flag declarations remain compatible; removing an area or a referenced quest, or
blocking the saved cell, is refused until the content is restored.

A deliberately incompatible package edit may set `campaign.json`'s integer
`version`. This is a manual authoring decision, not an automatic hash and not a
migration. Saves written before campaigns existed remain read-only legacy saves.
