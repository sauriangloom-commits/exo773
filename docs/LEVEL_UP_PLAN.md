# Level-up and feat selection - plan (2026-11-21)

Planning only. This document changes no code, content, schema or save file, and it
requests no manual testing. It decides the level 3 to 4 step for the five shipped
classes, the feat choice that has been missing, and the batches that would
implement them. Every rule taken from the printed book is cited; every departure
from it is labelled **Adaptation** with the reason.

Page numbers come from the printed PHB and should be confirmed against the book
before the first implementation batch, in the same way `BULL_RUSH_PLAN.md` records
table-value checks. Numeric table values were read from the 3.5 SRD mirror and
match the values already authored in `content/shared/characters.json`.

## 1. What the repository already has

### 1.1 XP

- `Character.xp` (`src/core/character.gd:53`), serialized in `to_dict` and read in
  `from_dict`; every shipped party member is authored with `"xp": 3000` and
  `"level": 3`.
- Written by encounter victory: `src/game_state.gd:1734` awards
  `encounter.xp_award` to every party member; authored per encounter
  (`game_state.gd:1689`, creator field `campaign_creator.gd:647`).
- Written by effects: `src/game_state.gd:1391` applies an `xp` effect.
- Read only for display: the character sheet prints the number
  (`src/ui/panels.gd:63`); the campaign creator validates encounter XP in
  0..100000 (`campaign_store.gd:2522`).
- **No threshold anywhere.** Nothing compares XP to a table, and no code writes
  `level`.

### 1.2 Level

- `Character.level` (`character.gd:13`), default 1, serialized and restored from
  content (`character.gd:681`).
- Read by `display_class` (`:594`), cleric turning (`cleric_level`, `:127`), feat
  level prerequisites (`feats.gd:598`), and the skill rank cap
  (`skills.gd:187`, `level + 3`).
- Written only by content and save loading. No code raises it.

### 1.3 Feats

- `Character.feats` is an array of printed names (`Character.gd:36`), authored in
  content, serialized, and displayed on the sheet (`panels.gd:146`).
- `Feats.CATALOG` (`src/core/feats.gd`) is the closed set of implemented feats; an
  unknown name is a content error. Prerequisites are re-checked on every use and
  already support `ability`, `bab`, `level`, `feat`, `skill_ranks`, `turn_undead`,
  `natural_attacks` and proficiency requirements (`_check_requirement`,
  `feats.gd:578` onward).
- **No selection surface.** No screen or modal adds a feat; QA probes append them
  in code (`main.gd:4092`, `:4131`, `:6515`).

### 1.4 Class data

- There is **no class table** in `content/`. `content/shared/` holds
  `characters.json`, `monsters.json`, `items.json` and `spells.json` only.
- A character carries its class as free text (`"class": "Fighter"`) and its
  derived numbers as authored data: `level`, `base_attack`, `base_saves`,
  `max_hp`, `skill_ranks`, `feats`, `spells`, `proficiencies`.
- The authored values match the printed tables at level 3: BAB and saves for all
  five (Table 3-1), e.g. fighter 3 / 3-1-1, rogue 2 / 1-3-1, cleric 2 / 3-1-3,
  wizard 1 / 1-1-3, sorcerer 1 / 1-1-3.
- Class skills exist in code: `Skills.CLASS_SKILLS` covers all five classes
  (`skills.gd:105`).
- Authored HP is consistent with maximum at 1st level and the fixed average after
  it: kaelen 28 (10+2, 6+2, 6+2), ysolde 13 (4+1, 3+1, 3+1).
- Authored feats do **not** match the printed feat slots: a 3rd-level fighter has
  four slots and kaelen carries two.

### 1.5 Rules that depend on level

| Rule | Where | Effect of level 4 |
| --- | --- | --- |
| Skill rank cap | `skills.gd:187` (`level + 3`, half for cross-class) | caps rise from 6/3 to 7/3 |
| Feat prerequisites | `feats.gd:598` | level-4 requirements become satisfiable |
| Cleric turning | `character.gd:127` | turning level rises to 4 |
| Display | `character.gd:594` | "Fighter 4" |
| Integer BAB/saves | authored fields, not derived | must be written by level-up |

Nothing else in the rules reads `level`; attack, AC, saves, HP and spell slots are
all authored or derived from authored values.

## 2. Decisions

### 2.1 XP threshold and the scope of levels

- **Level 3 is 3,000 XP and level 4 is 6,000 XP** (PHB Table 3-2, p. 22). The
  threshold is the total, not the increment: a character at 6,000 XP has earned
  level 4.
- **Scope: the 3 to 4 step only.** The table is validated for levels 1-4 because
  that is all the demo can reach, and a single step keeps the plan testable. Level
  5+ rows stay out of scope and are added when a campaign can reach them.
- **One step at a time.** A character with 12,000 XP after a later award still
  advances one level per confirmation; the next offer appears immediately after.
- **Adaptation:** XP is awarded to the whole party (existing behaviour); each
  character crosses the threshold independently and is offered their own level-up.
  The printed "level or not, XP is XP" model does not care who dealt the damage,
  so this is faithful in effect, but the engine has no party-size or ECL
  adjustment.

### 2.2 HP gain

- **Rule:** each level adds one Hit Die plus the Constitution modifier (PHB p. 9,
  "Hit Points"). Hit Dice: fighter d10, rogue d6, cleric d8, wizard d4,
  sorcerer d4 (class entries).
- **Decision: fixed average rounded up**, the same shape the authored characters
  already follow - fighter 6, rogue 4, cleric 5, wizard 3, sorcerer 3, plus the
  Con modifier. At 4th level with current scores: kaelen +8, sera +5, aldric +6,
  ysolde +4, mira +4.
- **Adaptation:** the printed rule rolls the die. Fixed average is chosen so a
  level-up is deterministic for saves, probes and reload tests; it also matches
  the authored level-3 HP exactly, so existing characters need no recomputation.
- Minimum 1 HP per level even with a negative Con modifier.

### 2.3 Base attack, saves, skill points and feat slots

| Class | BAB at 4 (Table 3-1) | Base saves at 4 (good/poor) | Skill points at 4 | Feat at 4 |
| --- | --- | --- | --- | --- |
| Fighter | +4 | Fort +4, Ref +1, Will +1 | 2 + Int | bonus fighter feat |
| Rogue | +3 | Fort +1, Ref +4, Will +1 | 8 + Int | none |
| Cleric | +3 | Fort +4, Ref +1, Will +4 | 2 + Int | none |
| Wizard | +2 | Fort +1, Ref +1, Will +4 | 2 + Int | none |
| Sorcerer | +2 | Fort +1, Ref +1, Will +4 | 2 + Int | none |

- Base attack and base saves are set, not incremented blindly, from the class row:
  a save can stay flat from 3 to 4 (fighter Ref, all poor saves) and setting the
  row prevents drift when a save's good/poor status differs from expectation.
- **Skill points** (PHB p. 62): class points plus Int modifier, minimum 1 per
  level. Current party: kaelen 2, sera 10, aldric 2, ysolde 5, mira 2. Points must
  be spent during the level-up; unspent points do not carry.
- **Rank caps** already follow `level + 3` and need no change; the level-up only
  raises the cap.
- **Feat slots** (PHB Table 3-2 and the class tables): general feats at 1st, 3rd
  and 6th; fighter bonus feats at 1st, 2nd, 4th. **At 4th level only the fighter
  gains a feat** (PHB Table 3-9, p. 39). No class gains a general feat at 4.
- **Adaptation: eligible fighter bonus feats are the implemented catalog only**
  (`Feats.CATALOG`), filtered by prerequisites. The printed fighter list includes
  many feats this slice does not implement, and offering them would create
  unusable slots.
- **Adaptation: no retroactive slot audit.** Authored feat lists are accepted as
  they are; level-up grants only the new slot. Kaelen's two feats are not topped
  up to four.
- **Adaptation: class features that are not modeled are not granted.** Rogue
  uncanny dodge at 4th, wizard Scribe Scroll at 1st (already absent), cleric
  domain slots and turning improvements beyond the existing level read are out of
  this step. `sneak_attack_dice` is authored, and 4th level does not change it
  (the printed progression changes at 5th).

### 2.4 Ability score increase

- Every 4th level grants +1 to one ability score (PHB Table 3-2, p. 22). The
  player chooses the score.
- **Decision:** the increase is applied before skill points and HP for this level
  are computed, so an Int increase raises this level's skill points and a Con
  increase raises the HP gained now.
- **Constitution is retroactive** (PHB p. 9: a Con modifier change changes hit
  points accordingly). The engine stores no roll history, so the implementation
  applies `level * delta` to `max_hp` when the modifier changes.
- **Adaptation:** the retroactive term is computed from the modifier delta, not
  from re-rolling history, because HP is authored and stored as a total.

### 2.5 Spell progression

The engine models slots as `spells.slots` with `max`/`used` and prepared lists;
it has no 0-level spells, no domain slots and no spellbook, and authored rows
include what the printed tables call bonus or domain slots. Level 4 therefore
adds slots to the authored row rather than re-deriving the row from the book.

- **Cleric** (PHB Table 3-6, p. 31): printed 4th level is 5 / 3+1 / 2+1. In the
  engine's model (no 0-level, domain slots included, no Wis bonus): **1st 4, 2nd
  3** - one more 1st and one more 2nd than level 3's 3 / 2.
- **Wizard** (PHB Table 3-18, p. 55): printed 4th level is 4 / 3 / 2. With
  Ysolde's Int 17 bonus slot included, as authored at level 3: **1st 4, 2nd 3** -
  one more 1st and one more 2nd than 3 / 2.
- **Sorcerer** (PHB Table 3-16, p. 52; Table 3-17, p. 54): printed 4th level is 6 / 6 / 3
  per day and 6 / 3 / 1 known. Under the engine's no-0-level model: 1st stays 6,
  **2nd 3**, and the character learns **one new 2nd-level spell** - `scorching_ray`
  is the only implemented arcane 2nd-level spell.
- **Level-3 sorcerer row, confirmed:** printed 6 slots at 1st and 5 spells known
  (5 0-level and 3 1st-level). Mira is authored with six 1st-level slots and two
  known spells: the printed 4th-level slot count and one fewer 1st-level known
  spell. Recorded as an accepted authored inconsistency (section 10), not fixed.
- **Prepared casters gain slots, not known spells** (Adaptation): the wizard has
  no spellbook model and clerics pray from the full list; the level-up does not
  add spells to `daily_prepared`/`prepared`, the player prepares from the existing
  list after the level-up.
- **Adaptation:** the missing 0-level row is not added here; it is an existing
  gap recorded in `FEATS_SKILLS_COVERAGE.md` scope, not part of this step.

### 2.6 Existing level-3 characters and old saves

- **No schema change and no migration.** Level-up writes fields that already
  exist and are already serialized: `level`, `xp`, `max_hp`, `hp`, `base_attack`,
  `base_saves`, `abilities`, `skill_ranks`, `feats`, `spells.slots`,
  `spells.known`. Save version stays as it is.
- A save written before this feature loads unchanged and is offered a level-up the
  next time the character is eligible. Nothing is recalculated on load.
- Authored characters keep their authored values; the level-up adds to them. The
  five demo characters start at 3,000 XP, so a demo playthrough that earns 3,000
  more XP crosses the threshold.
- **Atomic apply:** the confirmation writes all changes at once; cancel writes
  nothing. No partial level is ever serialized.
- **Idempotent:** a character at level 4 with 6,000 XP is not offered another
  level-up at the same XP; the offer needs 10,000 XP for level 5, which is out of
  scope, so the offer stays closed until that batch lands.

### 2.7 Who chooses

- **The player chooses** the ability increase, the skill ranks, the fighter bonus
  feat and the sorcerer's new known spell. Those are the printed choices made
  during level advancement.
- **The content author chooses** only what is static: class, starting level,
  starting XP, and the authored feat/spell/equipment lists. The author does not
  pre-script level-up choices, and no content field exists for them in this plan.
- **Automatic items are shown, not chosen:** HP, BAB, saves, skill points and
  spell slots are derived and displayed in the summary step.
- **Adaptation:** the engine has no "the DM chooses" path and no alternate class
  features, so every choice is either player-made or derived.

## 3. Screen flow, keyboard path and 160 % layout

### 3.1 Entry

- The party sheet (existing modal) gains a **Level up** button on each eligible
  character's card, with the button showing the target level.
- After a victory that makes someone eligible, the existing combat log line is
  followed by one line naming the character; no automatic modal opens and no
  modal interrupts combat.
- A character who is not eligible has no button; the modal cannot be opened for
  them.

### 3.2 Modal steps

One modal, reusing the existing modal builder, `_cycle_modal_focus` and
`_reveal_focused_control`:

1. **Summary** - current class and level, target level, HP gained, BAB and save
   changes, skill points gained, feat slot, spell slot changes. Read-only.
2. **Ability increase** - one row of six radio-style buttons; exactly one must be
   chosen.
3. **Skills** - the class skills (and cross-class skills) with a rank stepper,
   remaining points shown, caps enforced; points must reach zero before Next.
4. **Feat** - only when a slot exists (fighter at 4); a list of eligible catalog
   feats with prerequisite failures greyed out and explained.
5. **Spells** - only for casters with a change; slot changes shown, and the
   sorcerer picks one implemented 2nd-level spell.
6. **Confirm** - a final read-only list of every change and an Apply button.

Back and Next move between steps; Cancel (Esc) asks once before discarding. Apply
is disabled until the current step is valid.

### 3.3 Keyboard

- Tab and Shift+Tab stay inside the modal and reveal the focused control through
  the existing walk; no new bindings and no change to traversal.
- Enter or Space activates the focused control.
- PageUp/PageDown scroll the modal body, as they already do.
- Esc cancels (with a confirmation when anything was changed).
- No step needs a pointer; every control is reachable by Tab alone.

### 3.4 160 % layout

- The modal already scales its panel with text scale up to 1.6 and the body
  scrolls; the level-up modal must not set fixed heights that break that.
- Skills and feat steps are the long ones: they use a single column inside the
  scrolling body, so a 160 % list scrolls rather than clipping.
- The probe pins rects, not pixels: every control on every step must be enclosed
  by the viewport at 100 % and 160 % at 1280x720 after the reveal walk runs.

## 4. Test and probe plan

Shaped like the creator focus probe: red first, rect assertions, then exported.

### 4.1 GUT tests

- `tests/test_level_progression.gd` - class rows for levels 1-4 (BAB, saves, HP
  average, skill points, feat slots, spell slots), the XP table, and content
  validation rejecting a class row that disagrees with the printed values.
- `tests/test_level_up.gd` - threshold and eligibility; each class's 4th-level
  result on a real `Character`; Con retroactivity; skill caps; atomic apply and
  cancel; idempotence; save round-trip and old-save load then level.
- `tests/test_feat_selection.gd` - eligible list filters by prerequisites and by
  the implemented catalog; a fighter bonus feat cannot be used for an unimplemented
  feat; known feats are excluded.

### 4.2 Headless probe

`--level-up-probe` (new flag, shaped like `--creator-focus-probe`), 1280x720, at
100 % and 160 % in one invocation:

1. Seeds kaelen at 3,000 XP and opens a real encounter victory worth 3,000, so the
   award path (not a test-only setter) crosses 6,000.
2. Asserts the party sheet shows the Level up button and an ineligible character
   has none.
3. Opens the modal by keyboard, walks every step with Tab/Enter, asserts every
   focused control's rect is inside the viewport at both scales.
4. Asserts the summary numbers against the class row, then applies, saves, reloads
   and asserts the persisted level, HP, BAB, saves, skill ranks, feat and slots.
5. Asserts the offer is gone after applying, and that cancelling at the summary
   leaves the character byte-identical.
6. Asserts the feat list at 4th contains no unimplemented feat and that the
   sorcerer's spell list offers only implemented 2nd-level spells.

### 4.3 Exported acceptance

Suite green, both validators green, probe green from source, then an export from a
clean commit with the executable hash recorded before and after and the probe run
at both scales from the exe. Rects are not pixels; no manual pass is requested.

## 5. Batches

Each batch is separately acceptable: it leaves the suite and both validators green
and changes no more than its own surface.

1. **`level_tables` - class progression tables and validation.** Add
   `src/core/class_progression.gd` with hit die, skill points, BAB and save rows
   1-4, feat slots and printed spell slots/spells known for the five shipped
   classes, plus `validate()` and `authored_inconsistencies()`, wire the
   validator into `--validate-diagnostics`, and add the table tests. No gameplay
   change. **This is the first batch; landed 2026-11-21 (section 10).**
2. **`level_up_core` - XP thresholds and application.** `LevelUp.eligibility`,
   `LevelUp.preview` and the atomic `LevelUp.apply` for the 3 to 4 step (HP, BAB,
   saves, skill points, ability increase incl. Con retroactivity, spell slots,
   feat slot), idempotence and save round-trip tests. No UI. Planned in detail in
   section 12.
3. **`level_choices` - feat, skill and spell choice rules.** Eligible-feat list
   from the catalog with prerequisite explanations, skill point allocation rules,
   sorcerer known-spell choice, and their tests. No UI.
4. **`level_up_ui` - the modal and its probe.** The party-sheet button, the six
   steps, keyboard path, 160 % layout, and `--level-up-probe` red then green.
5. **`level_up_export` - exported acceptance.** Bound candidate, probe from the
   exe at both scales, docs closure.

A batch that finds the class table cannot be validated against existing content
must stop and report rather than adjust content in the same batch.

## 6. Exclusions

Not designed here, not to be slipped into the batches above:

- Multiclassing, level adjustment and ECL races.
- Prestige classes and epic levels (21+).
- Retraining, rebuilding, respec, or undoing a level-up.
- Level drain, negative levels and restoration.
- XP for item creation, crafting costs, or XP penalties.
- 0-level spells and cantrips; cleric domain slots and domain spell lists.
- Wizard spellbook, scribing costs or automatic spell learning.
- Class features not modeled today: rogue uncanny dodge and evasion, wizard Scribe
  Scroll and familiar, fighter weapon/armor training, cleric domain powers,
  paladin/ranger/bard/barbarian/monk/druid classes (not shipped).
- Monster advancement by Hit Dice, NPC level-up, companion cohorts.
- Automatic or recommended feat/ability choices; build templates.
- Wealth-by-level, treasure parcels, or item budgets tied to level.
- Feat slot auditing of existing authored characters.

## 7. Risks and open points

- **Page confirmation.** Confirmed 2026-11-21 against the SRD tables and the PHB
  contents listing: Table 3-1 and 3-2 p. 22; cleric Table 3-6 p. 31; fighter
  Table 3-9 p. 39; rogue Table 3-15 p. 49; sorcerer Table 3-16 p. 52 and Table
  3-17 p. 54; wizard Table 3-18 p. 55. Every value recorded in sections 2.3 and
  2.5 matches; the earlier fighter, sorcerer and wizard page numbers were wrong
  and are corrected above.
- **Thin catalog.** The eligible feat list is small, so a fighter's 4th-level
  bonus feat may look sparse; that is a content gap, not a rules gap, and adding
  feats is a separate rules batch.
- **Authored inconsistencies.** Accepted, not repaired; section 10 lists all
  thirteen: four feat counts below the printed slots, three cross-class ranks
  above the level-3 cap (with the point totals that follow), Ysolde's and Mira's
  slot rows above the printed ones, Mira's known list, and the missing 0-level
  row. A later content-audit batch would, not this plan.
- **No undo.** A confirmed level-up is permanent in a save; the plan relies on
  atomic apply plus save/load, not on undo.
- **Scene-wide risk.** The modal work touches the shared modal path; the existing
  modal focus suite and the settings/layout probes are the regression net.

## 8. State after this plan, kept separate

- **Confirmed defects:** none. The creator reveal gap is fixed and closed
  (`creator_focus_2026-11-21a`); the stance leak and the bull-rush layout probe
  artifact remain fixed and closed.
- **Deferred features:** level-up and feat selection (this plan); the charge form;
  Improved Bull Rush (blocked behind feat selection); the 25 % redirect; mounted
  and AI bull rushes; multi-square creatures; terrain effects; concealment,
  hard/low-wall and reach-melee cover; grapple, disarm, sunder, overrun;
  two-weapon fighting and iterative attacks; AoE templates; save-migration
  production steps; turning extensions; Weapon Specialization and the other
  level-gated feats.
- **Maintenance debt:** empty migration table; acceptance not repeated per batch;
  `follow_focus` redundancy beside the reveal walk; one pane following focus per
  key press; minimal settings versioning; simple AI; no content hot reload;
  placeholder raycaster; shallow UI coverage; source-only GUT; probe-heavy
  `main.gd`; `resolve_bull_rush_decision` trusting recorded cells.
- **Evidence gaps:** Push 5 ft / Follow UI not exercised by the exported smoke;
  exported rules behaviour beyond that smoke is probe-covered only; physical
  held-key acceptance pending; Enter activation native-only; no OS-level crash
  injection; synthetic case-sensitive filesystem; unbound creature-cover
  candidates; missing `modal_focus` binary; fixture-only Tumble values; the
  resolution smoke's fixture-selected seed; the creator focus probe checks rects,
  not rendered pixels; no human playtest was run or requested.

## 9. Definition of done

Batches 1-5 accepted, each with the suite and both validators green. The player can
take a 3rd-level character at 6,000 XP to 4th through the listed steps by keyboard
alone at 100 % and 160 %, sees the printed 4th-level numbers, chooses the ability
increase, skill ranks, fighter feat and sorcerer spell, and finds the result after
save and reload. The exported candidate passes the same probe, its hash is bound
before and after, and no content, schema or rules change lands outside the batches
listed here.

## 10. Batch 1 record: `level_tables` (2026-11-21)

Landed as data plus validation. Nothing reads the table for play: XP, level, saves,
the sheet, the UI and every rules path are unchanged, and no character's derived
numbers moved.

- **Storage decision (change from section 5's wording).** The table is
  `src/core/class_progression.gd` (`ClassProgression.CLASSES`), beside
  `Feats.CATALOG` and `Skills.CLASS_SKILLS`, not content JSON. Reason: the same
  values feed rules, the validator and the tests, so one typed constant keeps them
  in lockstep; `ContentSpec` and every content schema are untouched. An editable
  content file can replace it later if a data-driven class list is needed.
- **Sources confirmed before coding.** Table 3-1 and Table 3-2, p. 22; Table 3-6,
  p. 31; Table 3-9, p. 39; Table 3-15, p. 49; Table 3-16, p. 52; Table 3-17, p. 54;
  Table 3-18, p. 55. Values recorded for levels 1-4: fighter 10 hp, 2 points, good
  BAB, Fort only; rogue 6 hp, 8 points, average BAB, Ref only; cleric 8 hp, 2
  points, average BAB, Fort and Will, 4 / 3+1 / 2+1 at 3rd and 5 / 3+1 / 2+1 at
  4th; wizard 4 hp, 2 points, poor BAB, Will only, 4 / 2 / 1 at 3rd and 4 / 3 / 2
  at 4th; sorcerer 4 hp, 2 points, poor BAB, Will only, 6 / 5 at 3rd with 5 known
  and 6 / 6 / 3 at 4th with 6 / 3 / 1 known. No value in the plan changed.
- **Contract.** `validate(table = CLASSES)` returns an empty array for the shipped
  table and one error string per problem: a missing shipped class, a missing level
  row, a field that disagrees with the printed progression (base attack rate,
  good/poor save formula, feat levels, hit die, skill points), a row that moves
  backwards, a spell level above what the level can cast, or spell data on a class
  that cannot cast. `--validate-diagnostics` prints the errors and fails the exit
  code; its JSON line is untouched. `authored_inconsistencies(characters)` compares
  the table with the authored characters and returns `{id, field, expected,
  actual, note}` records; it never edits a character.
- **Accepted authored inconsistencies (13).** Reported, not repaired:

  | Character | Field | Table | Authored | Reading |
  | --- | --- | ---: | ---: | --- |
  | kaelen | feats | 4 | 2 | two unspent slots |
  | aldric | feats | 2 | 1 | one unspent slot |
  | ysolde | feats | 2 | 1 | one unspent slot |
  | mira | feats | 2 | 1 | one unspent slot |
  | aldric | skill ranks, sense motive | 3 | 4 | cross-class rank above the cap |
  | aldric | skill points spent | 12 | 26 | over the level-3 budget |
  | ysolde | skill ranks, search | 3 | 4 | cross-class rank above the cap |
  | mira | skill ranks, diplomacy | 3 | 4 | cross-class rank above the cap |
  | mira | skill points spent | 12 | 20 | over the level-3 budget |
  | ysolde | 1st-level slots | 2 | 3 | Int 17 bonus slot |
  | ysolde | 2nd-level slots | 1 | 2 | Int 17 bonus slot |
  | mira | 1st-level slots | 5 | 6 | printed 4th-level count |
  | mira | spells known | 8 | 2 | 0-level known absent, one 1st-level known missing |

  Everything else matches: all five base attack bonuses, base saves and hit
  points, and the cleric's 3 / 2 slot row. Sera has no mismatch. The 0-level row is
  absent from the engine's authored spells by design (section 2.5) and is counted
  only through the known-spells total.
- **Evidence.** Suite 795/795 tests, 8,126 assertions, 61 scripts (baseline
  778/778, 7,981, 60); `--validate-campaigns` PASS; `--validate-diagnostics` PASS
  with `CLASS PROGRESSION PASS | 13 accepted authored inconsistencies`. Red first:
  the new test file failed to compile before the class existed, and the validator
  rejects every injected missing, backwards and inconsistent row.
- **Limit.** Nothing player-visible changed, so no candidate was exported. No
  manual testing was requested and no backups were touched. A one-time `--import`
  refresh was needed so the new `class_name` entered the global class cache; it
  changed no source or content.

## 11. Batch 1 closure and the accepted inconsistencies (2026-11-21)

### 11.1 Closure

Batch 1 is accepted within the limits recorded with it. Evidence is the run already
recorded for the batch, not a new one: commit `7391e39`, suite 795/795 tests with
8,126 assertions across 61 scripts, `--validate-campaigns` PASS, and
`--validate-diagnostics` PASS with `CLASS PROGRESSION PASS | 13 accepted authored
inconsistencies`. Nothing was rebuilt and no check was repeated for this closure.

What it does not cover, unchanged: the table is data only and no play path reads
it; the validator's refusal cases are unit-level table mutations rather than
corrupted content files; the thirteen authored differences below are reported, not
repaired by that batch; and GUT 9.6.1 exits 0 when a test file fails to parse, so a
parse failure has to be read from the log (section 12.8 makes that a rule for
batch 2).

### 11.2 Decision for each accepted inconsistency

| # | Finding (batch 1) | Decision | Effect on level-up |
| ---: | --- | --- | --- |
| 1 | kaelen feats 2 of 4 | Carry forward unchanged | Grants only the one 4th-level fighter slot; no back-fill |
| 2 | aldric feats 1 of 2 | Carry forward unchanged | No feat at 4 (non-fighter); stays 1 |
| 3 | ysolde feats 1 of 2 | Carry forward unchanged | No feat at 4; stays 1 |
| 4 | mira feats 1 of 2 | Carry forward unchanged | No feat at 4; stays 1 |
| 5 | aldric sense motive 4, cap 3 | Repair in the separate content commit | Batch 2 never audits or clamps existing ranks |
| 6 | aldric skill points 26 of 12 | Repair in the same content commit | Budget is spent only on new ranks from level-up |
| 7 | ysolde search 4, cap 3 | Repair in the same content commit | Same rule |
| 8 | mira diplomacy 4, cap 3 | Repair in the same content commit | Same rule |
| 9 | mira skill points 20 of 12 | Repair in the same content commit | Same rule |
| 10 | ysolde 1st slots 3, printed 2 | Carry forward; +1 is the Int 17 bonus slot | Adds the printed +1, reaching 4 |
| 11 | ysolde 2nd slots 2, printed 1 | Carry forward; +1 is the Int 17 bonus slot | Adds the printed +1, reaching 3 |
| 12 | mira 1st slots 6, printed 5 | Carry forward; her row already equals the printed 4th-level count | Adds no 1st-level slot; adds the 2nd-level row |
| 13 | mira known 2 of 8 | Carry forward | Adds exactly one 2nd-level spell; no 0-level, no 1st-level back-fill |

The reasoning, so none of this is silent:

- **Feat counts (1-4) stay.** The authored feat lists are the builds the encounters
  were tuned around; adding feats changes attack, AC, saves or skill numbers, and
  that is a balance change, not a data correction. Level-up adds only what the new
  level grants (one slot, fighter only), matching section 2.3's "no retroactive
  slot audit". A later build-audit batch may revisit the builds deliberately.
- **The five skill findings (5-9) are repaired in one separate content commit.** A
  rank above the printed cap and a spend above the class budget are sheet
  errors, not adaptations, and they can be fixed without touching HP, base attack,
  saves, AC or spells; only the affected skill modifiers change. The commit is
  scheduled after batch 2 is accepted and before batch 3, so the feat/skill/spell
  choice rules and the UI never ship against an illegal sheet. It is not part of
  batch 2 and must not ride along with engine work.
  - aldric: rebuild the block inside 12 points at level 3 (2 + Int 0 per level,
    x4 at 1st), keeping heal 6 as the class anchor; class skills before cross-class.
  - mira: rebuild inside 12 points, using at least one sorcerer class skill
    (bluff, concentration, spellcraft or knowledge arcana); her current four skills
    are all cross-class.
  - ysolde: lower search from 4 to 3 (cap 3); her spend already fits the 30-point
    budget, so nothing else moves.
  - The repair commit updates the expected 13-entry list in
    `tests/test_class_progression.gd` to the 8 that remain (four feat counts, three
    slot/known readings, and the reading for Mira's known list), runs the suite and
    both validators, and records the new accepted set. Existing saves keep the
    ranks they stored: no migration rewrites a character mid-campaign.
- **Bonus-slot readings (10-12) stay.** The engine stores authored rows and has no
  bonus-spell model, so a row above the printed base is the authored
  representation of the Int or Cha bonus. Level-up adds the printed 3rd-to-4th
  increment rather than re-deriving the row.
- **Mira's known list (13) stays**, with the one addition the level calls for. See
  11.3.

### 11.3 The two named cases

**Mira's missing spells.** Level-up adds exactly the spell the new level grants: one
2nd-level spell, chosen from the implemented arcane 2nd-level list (`scorching_ray`
is currently the only entry), appended to `spells.known`. It does not add 0-level
spells (the engine has no 0-level model), does not back-fill the 1st-level spell
her printed 3rd-level row would have, and does not block the level-up because the
known list is short. Her slots become 6 at 1st and 3 at 2nd; that 1st-level value is
the printed 4th-level count, so the slot row ends up matching the book exactly.
The class-progression validator keeps reporting the known-list difference as
accepted so the gap stays visible.

**Ranks above the level cap.** Level-up never audits, clamps or deletes an existing
rank. It computes the new caps (class skill 7; cross-class printed 3.5, enforced as
3 whole ranks, section 12.5), applies
them to ranks added during the level-up only, and lets an existing over-cap rank
stand until the separate content repair lands. Concretely, aldric's sense motive 4
does not refuse his level-up and does not consume his new points; the preview shows
a notice naming the rank, the cap and the deferred repair. Spending new points on
that same skill is still refused (`skill_rank_above_cap`) because the new rank
would also be over the cap.

### 11.4 The separate content repair commit

- **Scope:** only `content/shared/characters.json`, the three characters named
  above, and the expected-inconsistency list in the class-progression test.
- **Acceptance:** suite green, both validators green, `authored_inconsistencies`
  down to the eight that stay, and a diff that touches skill ranks only.
- **Not included:** no engine, schema, UI or class-table change; no save migration;
  no feat or spell change.
- **Order:** after batch 2 is accepted, before batch 3 starts.

### 11.5 Content repair record (2026-11-21)

The five skill findings are repaired in `content/shared/characters.json`; the eight
accepted differences stay. Before and after, with the points the engine charges
(class rank 1, cross-class rank 2) and the level-3 budget
`(class points + Int modifier) x 6`:

| Character | Before (ranks -> points) | Spent | Budget | After (ranks -> points) | Spent |
| --- | --- | ---: | ---: | --- | ---: |
| aldric | heal 6 -> 6, diplomacy 4 -> 4, sense motive 4 -> 8, listen 2 -> 4, spot 2 -> 4 | 26 | 12 | diplomacy 2 -> 2, heal 4 -> 4, sense motive 3 -> 6 | 12 |
| mira | search 2 -> 4, spot 2 -> 4, listen 2 -> 4, diplomacy 4 -> 8 | 20 | 12 | bluff 2 -> 2, diplomacy 3 -> 6, search 1 -> 2, spellcraft 2 -> 2 | 12 |
| ysolde | search 4 -> 8, spot 2 -> 4, listen 2 -> 4, diplomacy 2 -> 4 | 20 | 30 | search 3 -> 6, spot 2 -> 4, listen 2 -> 4, diplomacy 2 -> 4 | 18 |

- **Aldric.** Sense motive 3 is the rank the decision asked for, and at two points a
  rank it costs half his twelve points. With heal and diplomacy funded first as
  class skills (4 and 2), exactly twelve are spent, so listen 2 and spot 2 cannot
  stay; they are dropped rather than left in a block that does not fit. Party
  perception stays with Sera (listen 6, spot 6) and Ysolde (2, 2). His check totals
  move to heal +7, diplomacy +3 and sense motive +6, each one lower than before.
- **Mira.** Diplomacy 3 is the requested rank (6 points). Bluff 2 and spellcraft 2
  are sorcerer class skills, which 11.2 required the rebuild to include, and search
  1 is the only cross-class rank that fits beside them; spot and listen are dropped.
  Her diplomacy total becomes +6, search +1, bluff +5, spellcraft +2.
- **Ysolde.** Only search moves, 4 -> 3, down to the cross-class cap; the rest of her
  block was already inside the 30-point budget, so nothing else changed and her
  search total becomes +6.
- **No other field moved.** The diff touches the three `skill_ranks` blocks only
  (8 lines inserted, 10 deleted). HP, base attack, saves, feats, equipment, spells,
  notes and XP are untouched; there is no save migration, and an existing save keeps
  the ranks it stored.
- **Tests.** `test_class_progression.gd` now expects the eight that remain, and a new
  `test_repaired_skill_blocks_fit_the_level_three_budget` pins each repaired block's
  spend and every rank against its cap. In `test_level_up_core.gd`, test 19 injects
  the over-cap rank in memory (the rule it covers is unchanged) and a new
  `test_repaired_content_has_no_over_cap_rank_notice` pins that the repaired content
  produces no notice.
- **Evidence.** Suite 832/832 tests, 8,350 assertions, 62 scripts (batch 2: 830 /
  8,326 / 62). `--validate-campaigns` PASS. `--validate-diagnostics` PASS with
  `CLASS PROGRESSION PASS | 8 accepted authored inconsistencies`, down from 13: the
  four feat counts, Ysolde's two Int bonus slots, Mira's 1st-level slot reading and
  Mira's short known list. Logs are in
  `builds/qa/runs/2026-11-21_content_repair/`.
- **Limit.** No engine line and nothing in the UI changed, so no candidate was
  exported. No manual testing was requested and no backup was touched.

**Closure (2026-11-22).** The repair is accepted within the limits above, on the
run already recorded for it: no rebuild and no repeated check. What it does not
cover: the three characters have no playtest or exported run with the new ranks,
an existing save keeps the ranks it stored, and the party's perception and social
coverage moved for aldric (no listen or spot, heal 4, diplomacy 2) and mira (no
listen or spot, bluff 2, spellcraft 2). A search of the campaigns, encounters,
scripted dialogue checks and tests found nothing that reads those four ranks on
either character; the one scripted use of a repaired skill is the encounter first-
aid check (`heal` DC 15, `encounter.gd`), which aldric still has and which the
suite exercises.

## 12. Batch 2: `level_up_core` (planned and implemented 2026-11-21)

### 12.1 Scope

Add one pure engine module, `src/core/level_up.gd` (`class_name LevelUp`,
`RefCounted`), that answers three questions for the single supported step, level 3
to level 4: is this character eligible, what would the step change, and apply it
atomically. No scene, no button, no save-schema change, no content edit, no XP
award change, no change to any rule outside the step. Batch 3 owns choice rules
(eligible feat list, allocation policy, known-spell list); batch 4 owns the UI.

Deviation recorded: the batch list in section 5 names `Rules.xp_threshold` and
`Character.apply_level`. The threshold lives in `LevelUp.XP_THRESHOLD` (6,000, the
single supported step; Table 3-2 p. 22) and the step lives in `LevelUp.apply`,
because `Rules` is the combat-math module and `Character` is the serialized data
model. Both names stay available for a later refactor if a second step appears.

### 12.2 Surface

```gdscript
class_name LevelUp
extends RefCounted

const XP_THRESHOLD := 6000
const TARGET_LEVEL := 4
const ABILITIES := ["str", "dex", "con", "int", "wis", "cha"]
const SPELL_SLOT_DELTAS := {
    "cleric": {1: 1, 2: 1},
    "wizard": {1: 1, 2: 1},
    "sorcerer": {2: 3},
}

static func eligibility(ch: Character) -> Dictionary
static func preview(ch: Character, choices: Dictionary = {}) -> Dictionary
static func apply(ch: Character, choices: Dictionary) -> Dictionary
```

`choices` is:

```gdscript
{
    "ability": "con",                     # one of ABILITIES, required at 4th
    "skills": {"listen": 1},              # ranks ADDED this level, integer >= 0
    "feat": "Power Attack",               # authored feat text, fighter only
    "spell": "scorching_ray",             # sorcerer known-spell choice only
}
```

Missing keys default to empty. Skill points may be left unspent (they do not
carry); over-budget is refused. Feat text uses the authored format
(`"Weapon Focus (longsword)"`) and is parsed by `Feats.parse`.

### 12.3 Eligibility and refusal reasons

Order of evaluation is fixed so the message is deterministic: character present,
class tabled, level, XP. `xp >= 6000` is inclusive; 5,999 is refused.

| Code | When | Message intent |
| --- | --- | --- |
| `eligible` | level 3, tabled class, xp >= 6000 | ready |
| `no_character` | null or empty id | no character |
| `class_not_tabled` | `char_class` not in `ClassProgression.CLASSES` | class has no table |
| `not_level_3` | level < 3 (level 2 with 6,000 XP is still refused) | only the 3-to-4 step exists |
| `already_level_4` | level >= 4 | already at the highest supported level |
| `xp_below_threshold` | level 3, xp < 6000 | needs 6,000 XP, has N |

Choice refusals, checked in this order, all after eligibility:

| Code | When |
| --- | --- |
| `missing_ability_increase` | no ability chosen |
| `unknown_ability` | key not in `ABILITIES` |
| `unknown_skill` | key not in `Skills.CATALOG` |
| `negative_rank` | a skill entry below 0 or not an integer |
| `skill_points_over_budget` | spent > class points + Int modifier (min 1) |
| `skill_rank_above_cap` | new total above class cap 7 or cross-class cap 3 |
| `feat_slot_unavailable` | a feat chosen by a non-fighter |
| `feat_required` | fighter with no feat chosen |
| `feat_not_implemented` | parsed key absent from `Feats.CATALOG` |
| `feat_already_owned` | same key and parameter already in `ch.feats` |
| `feat_prerequisites_unmet` | `Feats.prereqs` fails on the staged level-4 character |
| `spell_choice_unavailable` | a spell chosen by a class without a known list |
| `spell_required` | sorcerer with no spell chosen |
| `spell_not_implemented` | id absent from `ContentDB.spells` |
| `spell_level_not_new` | chosen spell's level is not the new spell level (2) |
| `spell_already_known` | id already in `spells.known` |

`eligibility` returns `{eligible, code, message, level, xp, threshold}`.
`preview` and `apply` return the preview shape below plus `ok` and, on refusal,
`code`/`message`; `apply` additionally returns `applied: true`.

### 12.4 Preview data

`preview` is read-only: it works on a staged copy and must leave `ch.to_dict()`
deep-equal before and after. It is callable with no choices so the UI can show the
numbers first; `required` then lists what is still missing.

```gdscript
{
    "ok": true,
    "code": "eligible",
    "message": "",
    "eligible": true,
    "from_level": 3,
    "to_level": 4,
    "xp": 3000,
    "threshold": 6000,
    "hit_points": {"max_before": 21, "max_after": 27, "hp_before": 21, "hp_after": 27, "delta": 6},
    "base_attack": {"before": 2, "after": 3},
    "base_saves": {"fort": {"before": 3, "after": 4}, "ref": {"before": 1, "after": 1}, "will": {"before": 3, "after": 4}},
    "ability": {"key": "con", "before": 13, "after": 14, "modifier_before": 1, "modifier_after": 2},
    "skills": {"budget": 2, "spent": 2, "remaining": 0, "class_cap": 7, "cross_cap": 3, "ranks": {"heal": 1}},
    "feat": {"slots_before": 2, "slots_after": 2, "granted": ""},
    "spells": {"slots_before": {"1": 3, "2": 2}, "slots_after": {"1": 4, "2": 3}, "known_before": [], "known_after": []},
    "required": ["ability"],
    "notices": ["sense motive 4 exceeds the cross-class cap 3; the content repair is deferred"],
}
```

`notices` is where the accepted authored facts surface (section 11.3); they never
refuse the step. No total attack bonus, AC or skill modifiers are stored in the
preview; the UI reads them through the existing `Rules`/`Skills` helpers on the
staged character so there is one source of truth.

### 12.5 The applied step

All numbers come from `ClassProgression` rows at level 4 and the staged character,
never from increments of the character's current values:

| Part | Rule |
| --- | --- |
| Level | set to 4 |
| XP | untouched (the threshold is a gate, never a cost) |
| HP | `ClassProgression.expected_hp(class, 4, con modifier after the ability increase)`; current HP keeps the same damage: `hp_after = new_max - (old_max - hp_before)`, clamped to `[0, new_max]` |
| Base attack | row at 4 (fighter 4, rogue 3, cleric 3, wizard 2, sorcerer 2) |
| Base saves | row at 4 (fighter 4/1/1, rogue 1/4/1, cleric 4/1/4, wizard 1/1/4, sorcerer 1/1/4) |
| Ability increase | +1 to one score, applied before HP, saves and skills are computed |
| Skill points | budget = class points + Int modifier after the increase (min 1); a class rank costs 1 point and a cross-class rank costs 2 (SRD Skills Summary, PHB p. 62); each added rank checked against the caps at level 4 (class 7, cross 3 whole ranks, see below); unspent points are discarded |
| Feat | fighter only, exactly one; prerequisites evaluated on the staged level-4 character; the authored list is otherwise untouched |
| Slots before | authored level-3 rows: cleric 3/2, wizard 3/2, sorcerer 6 (no 2nd-level row) |
| Slots after | cleric +1/+1 = 4/3; wizard +1/+1 = 4/3; sorcerer 1st unchanged at 6, new 2nd-level row 3 |
| Sorcerer known | one 2nd-level spell appended (section 11.3) |
| Everything else | untouched: equipment, effects, conditions, nonlethal, temp HP, proficiencies, prepared lists, tags |

Constitution increase is retroactive because HP and every Con-based number are
recomputed from the new score across all four levels: aldric 13 -> 14 raises his
maximum from 21 to 31 and his Fort save by 1.

The level-4 slot readings are the plan's decision, not the printed bonus-spell
math: the engine's authored rows already fold in the Int bonus (`ysolde`) or sit at
the printed 4th-level count (`mira`), so the deltas are explicit and tested per
class rather than derived from Table 1-1.

**Skill caps at 4th level, confirmed against the printed text (2026-11-21).** The
SRD Skills Summary and PHB p. 62 read: the maximum rank in a class skill is the
character's level + 3, and the maximum in a cross-class skill is half of that
number, "do not round up or down"; each skill point buys 1 rank in a class skill
and 1/2 rank in a cross-class skill, and half ranks do not improve a check. So at
4th level the class cap is 7 and the printed cross-class cap is 3.5, not 3 or 4.
The engine stores whole ranks only (`skill_ranks` is an integer map) and buys a
cross-class rank for 2 points, so the enforceable cross-class cap is 3 whole ranks:
a 4th rank would exceed 3.5, and no half rank can be stored. `Skills.max_ranks`
already floors, which gives exactly 3; batch 2 uses it on the staged level-4
character instead of duplicating the formula. The unrepresentable 0.5 is recorded
as an adaptation in `ADAPTATION_LOG.md`, not as a printed value.

### 12.6 Atomicity, idempotence, XP

- `apply` validates everything on a staged copy first. The original character is
  mutated only in a final commit block that assigns the staged fields; a refusal
  leaves `ch.to_dict()` deep-equal to its before value, including `hp`, `spells`
  and `feats`.
- Applying twice refuses the second call with `already_level_4`; the serialization
  does not change and HP does not grow again.
- No partial level exists in memory or on disk: callers persist after `ok`, as they
  do for any other change.
- XP is never deducted, reset or awarded. A character at 6,000 XP who levels stays
  at 6,000 XP and is not offered another step.

### 12.7 Old saves

- No schema change, no version bump and no migration. The step writes fields that
  `Character.from_dict`/`to_dict` already carry.
- Level 3 with 3,000 XP: loads unchanged, not eligible.
- Level 3 with 6,000 XP or more (for example after the next content update): loads
  unchanged, `eligibility` returns `eligible`, and nothing is applied until the
  caller asks. A load never levels a character by itself.
- Level 4 with 6,000 XP: loads unchanged, `already_level_4`, no recomputation.
- Missing or malformed `base_attack`, `base_saves` or `spells.slots`: the step
  writes the level-4 row from the table and the class's authored slot values, so
  the applied character is well formed. Missing `char_class` refuses with
  `class_not_tabled` instead of guessing.
- A `hp` value above the new maximum is clamped only by the damage-preserving
  formula; max HP always comes from the table and Con.

### 12.8 Failing-first tests

`tests/test_level_up_core.gd`, written before `src/core/level_up.gd` exists. Red
protocol: run the suite, keep the log under `builds/qa/runs/2026-11-21_level_up_core/`,
and accept the red state only from the logged failure text (the parse error naming
`LevelUp` and the `[Failed]` assertion blocks), quoted in the batch record. The exit
code alone is not evidence: GUT 9.6.1 exited 0 on batch 1's unparseable test file.

Engine and eligibility:

1. `test_eligibility_is_inclusive_at_six_thousand_xp` (5,999 vs 6,000 vs 6,001)
2. `test_a_level_four_character_is_not_eligible`
3. `test_a_level_two_character_is_not_eligible_even_with_six_thousand_xp`
4. `test_an_untabled_class_is_refused_without_crashing`
5. `test_the_threshold_is_six_thousand_and_xp_is_never_changed`
6. `test_preview_does_not_mutate_the_character`
7. `test_preview_lists_required_choices_without_choices`
8. `test_preview_matches_the_printed_level_four_rows` (five classes: HP, BAB, saves)
9. `test_redirected_slot_readings_are_per_class` (cleric 4/3, wizard 4/3, sorcerer 6/3)

Apply:

10. `test_apply_fighter_sets_level_bab_saves_hp_and_feat`
11. `test_apply_cleric_adds_the_domain_inclusive_slots`
12. `test_apply_wizard_keeps_the_intelligence_bonus_slots`
13. `test_apply_sorcerer_adds_one_second_level_spell_and_no_first_level_slot`
14. `test_constitution_increase_is_retroactive`
15. `test_hp_after_preserves_damage_taken`
16. `test_skill_points_use_the_budget_at_level_four`
17. `test_intelligence_increase_raises_the_skill_budget`
18. `test_class_and_cross_class_caps_are_enforced_on_new_ranks` (class 7; cross-class
    3 whole ranks because the printed 3.5 cannot be stored)
19. `test_existing_over_cap_ranks_do_not_block_level_up` (aldric, before the repair)
20. `test_unspent_skill_points_are_discarded`

Refusals (each asserts the code and an unchanged `to_dict()`):

21. `test_over_budget_skill_allocation_is_refused_atomically`
22. `test_a_new_rank_above_the_cap_is_refused`
23. `test_unknown_skill_and_negative_rank_are_refused`
24. `test_missing_ability_increase_is_refused`
25. `test_non_fighter_feat_choice_is_refused`
26. `test_fighter_without_a_feat_is_refused`
27. `test_feat_prerequisites_are_evaluated_on_the_staged_character`
28. `test_an_already_owned_feat_is_refused`
29. `test_sorcerer_requires_a_level_two_known_spell`
30. `test_an_unknown_or_already_known_spell_is_refused`
31. `test_second_apply_is_refused_and_changes_nothing`
32. `test_refusal_codes_and_messages_are_stable`

Save round-trip:

33. `test_a_level_three_save_with_six_thousand_xp_is_eligible_after_load`
34. `test_a_level_four_save_loads_without_migration`
35. `test_a_levelled_character_round_trips_through_to_dict_and_from_dict`

The last three build characters with `Character.from_dict` and the shared item
dictionary; none touches `user://` saves, so the probe-only save-cleanup guard is
respected.

### 12.9 Verification and records

After implementation: full suite, both validators, a diff limited to
`src/core/level_up.gd` and its test, and the batch record in `TEST_REPORT.md` with
the quoted red lines and the green totals. No export (nothing player-visible), no
manual testing request, no backup changes. The class-progression test keeps its
current 13-entry expectation until the separate repair commit.

### 12.10 State after this planning step, kept separate

- **Confirmed defects:** none in batch 1. The batch 2 work is a feature, not a
  repair.
- **Deferred features:** the level-up UI and probe (batch 4), eligible-feat picker
  and allocation policy (batch 3), exported acceptance (batch 5), levels 5 and
  above, multi-level steps, NPC/monster advancement, and the content repair commit
  for the five skill findings.
- **Maintenance debt:** GUT's misleading exit status on parse errors; `Skills.max_ranks`
  reading `ch.level` (batch 2 needs staged caps, and a later refactor should take a
  level argument); the plan's two stage names now mapping to `LevelUp`; the
  class-progression report's generic bonus-slot note now that section 11.2 explains
  each case.
- **Evidence gaps:** no level-up probe, no exported run, no UI, no manual playtest,
  no save file produced by this step, and no shipped feat with a level prerequisite
  (so the staged-level prerequisite path is implemented and unit-covered only
  indirectly).

### 12.11 Risks

- **Staged versus current level.** Feat prerequisites, skill caps and skill budget
  read the character's level and ability scores. Validating against the current
  character instead of the staged level-4 copy would refuse legal choices or admit
  illegal ones; test 27 and tests 16-18 pin the staged read.
- **HP double counting.** Adding a fixed average to the authored HP *and*
  recomputing from the class table would double the Con change; only the
  `expected_hp` recomputation is authoritative (test 14).
- **Partially written state.** Any mutation before the last check fails the
  atomicity tests (21, 31). Staging every field, including deep copies of
  `spells`, is required.
- **Slot drift.** The per-class deltas are explicit because the printed bonus-spell
  math would over- or under-count the authored rows; tests 9, 11-13 pin the values.
- **Save equality.** `to_dict()` includes equipment ids and nested dictionaries;
  tests compare deep copies, not references.

### 12.12 Batch 2 record (2026-11-21)

Implemented as planned; nothing player-visible reads it. `src/core/level_up.gd`
and `tests/test_level_up_core.gd` (35 tests, written first). The red evidence is
the log, not the exit code: the new file failed with

    SCRIPT ERROR: Parse Error: Identifier "LevelUp" not declared in the current scope.
       at: GDScript::reload (res://tests/test_level_up_core.gd:32)

and was not collected at all (61 scripts, 795/795 tests, 8,126 assertions), while
GUT still exited 0. After implementation: 830/830 tests, 8,326 assertions, 62
scripts; `--validate-campaigns` and `--validate-diagnostics` pass, with the class
table still at 13 accepted authored inconsistencies because no content was edited.
The skill-cap confirmation stands in 12.5: printed cross-class 3.5, enforced as 3
whole ranks. Nothing calls `LevelUp` outside its own module and tests; no UI,
probe, export, content or save-format change was made.

## 13. Batch 3: `level_choices` (planned 2026-11-21, not implemented)

### 13.1 Scope

One pure module, `src/core/level_choices.gd` (`class_name LevelChoices`,
`RefCounted`), that answers what the level-up screen has to render for the single
3rd-to-4th step: which choices exist, which of them are legal on the level-4
character, and why the illegal ones are refused. `LevelUp` stays the authority that
applies a step; `LevelChoices` never mutates a character and never writes a save.
Batch 4 (`level_up_ui`) owns the scene, focus and probe; batch 5 owns exported
acceptance. No content edit, no new feat or spell, no class-table change.

Deviation to record: batch 3 adds one public seam to `level_up.gd`,
`static func stage(ch, choices) -> Dictionary`, which returns the staged level-4
copy or the refusal (today's private `_stage`). Option eligibility has to be
evaluated on exactly the character `apply` will validate; a second staging routine
in another module would let the two drift. The seam changes no behaviour and batch
2's tests stay as they are.

```gdscript
class_name LevelChoices
extends RefCounted

static func choices(ch: Character, draft: Dictionary = {}) -> Dictionary
static func feat_options(ch: Character, draft: Dictionary = {}) -> Array[Dictionary]
static func skill_options(ch: Character, draft: Dictionary = {}) -> Array[Dictionary]
static func spell_options(ch: Character, draft: Dictionary = {}) -> Array[Dictionary]
static func validate(ch: Character, choices: Dictionary) -> Dictionary
```

`draft` is the caller's partial choice (`{"ability": "dex"}`), so the lists follow
the pending ability increase. `choices` refuses nothing of its own: an ineligible
character gets `{"ok": false, "code": ..., "message": ...}` copied from
`LevelUp.eligibility`.

### 13.2 The fighter feat list

Built from `Feats.CATALOG`, never from a hand-written list in the screen:

- **Slot.** Options exist only when
  `ClassProgression.feat_slots(class, 4) - ClassProgression.feat_slots(class, 3) == 1`,
  which is the fighter. The other four classes get `granted: 0` and an empty list,
  and `LevelUp` still refuses a chosen feat with `feat_slot_unavailable`.
- **Ownership filter.** A non-repeatable feat the character already owns is left
  out, since it could only be refused with `feat_already_owned`. A repeatable feat
  stays, because `Extra Turning`, `Toughness`, `Skill Focus` and `Weapon Focus` may
  be taken again. A parameterized feat is offered once per legal parameter, not once
  for the base key.
- **Parameter expansion.** `parameter: "weapon"` expands over the weapon ids the
  content actually ships (items with `kind == "weapon"`), rendered as the authored
  text (`"Weapon Focus (longsword)"`); `parameter: "skill"` expands over
  `Skills.all_keys()`. A round-trip test asserts
  `Feats.parse(option.text).key == option.key` and `.param == option.param`.
- **Prerequisites.** Each candidate is checked with
  `Feats.prereqs(staged, key, param)` on the staged copy, so the fighter's 4th-level
  base attack and the pending ability increase are already in force. The `reasons`
  array is copied verbatim, so the screen can print "requires DEX 13 (has 12)".
- **The printed fighter bonus-feat restriction.** PHB p. 38 limits the bonus feat to
  a named list. `Feats.CATALOG` carries no such metadata today. Batch 3 adds a
  boolean `fighter_bonus` to each catalog entry (metadata only; no rules path reads
  it), sources the list from the printed page (verified 2026-11-22; 13.9 quotes
  the wording and names the table), and filters the slot's options on it. A fighter's optional *general* feat from 3rd
  level is not this picker's business. If the printed list cannot be sourced, the
  picker offers the whole catalog and the gap is recorded as a deferred rules
  feature instead of being presented as correct.
- **Order.** Sorted by printed name and then parameter, so two renders of the same
  character are identical.

```gdscript
{"text": "Dodge", "key": "dodge", "param": "", "name": "Dodge", "group": "fighter_bonus",
 "eligible": false, "reasons": ["requires DEX 13 (has 12)"], "owned": false}
```

### 13.3 The sorcerer's new 2nd-level spell

- **The pool** is every spell in `ContentDB.spells` whose `level` equals
  `LevelUp.NEW_SPELL_LEVEL` (2) and whose `classes` array contains the character's
  class in lower case. Today that is exactly one entry, `scorching_ray` (evocation,
  wizard and sorcerer), so the picker has one row; the list is derived, not
  hard-coded, so a content addition widens it without a code change.
- **Exclusions** are the three refusals `LevelUp._stage_spell` already produces: an
  id absent from `ContentDB.spells` (`spell_not_implemented`), a spell of any other
  level (`spell_level_not_new`), and an id already in `spells.known`
  (`spell_already_known`). Only the sorcerer has a non-empty list; passing a spell
  for any other class is refused with `spell_choice_unavailable`.
- **Empty pool.** If a later content change removes the only 2nd-level arcane
  spell, the picker reports `options: []` and `complete: false`, and the step
  cannot be finished. The plan does not invent a spell and does not relax
  `spell_required`. A test pins "one option today" so an emptied pool fails
  visibly.
- **What it does not do:** no 0-level or 1st-level back-fill, no prepared-list
  change, no slot arithmetic - the slot delta stays `LevelUp.SPELL_SLOT_DELTAS`.

### 13.4 Choice-validation data for the screen

`choices(ch, draft)` returns one dictionary; the screen reads it and re-derives no
rule of its own:

```gdscript
{
    "ok": true,
    "code": "eligible",
    "message": "",
    "from_level": 3,
    "to_level": 4,
    "ability": {
        "required": true,
        "chosen": "dex",
        "options": ["str", "dex", "con", "int", "wis", "cha"],
        "scores": {"dex": {"before": 12, "after": 13, "modifier_before": 1, "modifier_after": 1}},
    },
    "skills": {
        "budget": 2,
        "spent": 1,
        "remaining": 1,
        "class_cap": 7,
        "cross_cap": 3,
        "chosen": {"heal": 1},
        "options": [
            {"skill": "heal", "name": "Heal", "ability": "wis", "class_skill": true,
             "cost_per_rank": 1, "ranks": 4, "cap": 7, "max_new_ranks": 3,
             "trained_only": false, "affordable": true}
        ],
    },
    "feat": {"granted": 1, "required": true, "chosen": "", "options": []},
    "spell": {
        "new_level": 2,
        "required": true,
        "chosen": "",
        "options": [
            {"id": "scorching_ray", "name": "Scorching Ray", "level": 2,
             "school": "evocation", "eligible": true, "reason": ""}
        ],
    },
    "complete": false,
    "blockers": ["ability", "feat"],
}
```

Rules for that data:

- `max_new_ranks` is `cap - current rank`, further limited by what the remaining
  points buy: `remaining` for a class skill, `floor(remaining / 2)` for a
  cross-class one. Unspent points may remain and are discarded by `apply`.
- Every number comes from `Skills` and `ClassProgression` evaluated on the staged
  copy, so caps and costs are never duplicated in screen code.
- `blockers` equals `LevelUp.preview(ch, draft).required`; a test compares the two
  for all five classes.
- `complete` is `blockers.is_empty()` and never promises that `apply` will accept:
  `LevelUp.apply` stays the only authority.
- No presentation data is added beyond names and ids: no portraits, no prose, no
  colour.

### 13.5 Refusal parity

`LevelChoices.validate(ch, choices)` stages the character through the same seam
`LevelUp.apply` uses and returns `{"ok", "code", "message", "fields"}`, with the
same `code` as `LevelUp` for every refusal. Tests compare the two for each batch-2
code: `missing_ability_increase`, `unknown_ability`, `unknown_skill`,
`negative_rank`, `skill_points_over_budget`, `skill_rank_above_cap`, `feat_required`,
`feat_slot_unavailable`, `feat_not_implemented`, `feat_already_owned`,
`feat_prerequisites_unmet`, `spell_required`, `spell_choice_unavailable`,
`spell_not_implemented`, `spell_level_not_new`, `spell_already_known`. It is
advisory: the screen may grey out a control, but the step always goes through
`LevelUp.apply`.

### 13.6 Failing-first tests

`tests/test_level_choices.gd`, written before the module exists. Red protocol is
batch 2's, extended: keep the log under
`builds/qa/runs/<date>_level_choices/`, and accept the red state only from its text.
The expected shape, to be quoted from that real log at implementation time and not
from this plan:

    SCRIPT ERROR: Parse Error: Identifier "LevelChoices" not declared in the current scope.
       at: GDScript::reload (res://tests/test_level_choices.gd:<line>)

with the totals unchanged and `test_level_choices.gd` never collected, while GUT
still exits 0. When the module exists but a value is wrong, quote the `[Failed]`
block's assertion line with its expected and actual values, never the exit code.

1. `test_fighter_options_come_from_the_catalog_and_are_sorted`
2. `test_only_the_fighter_gets_a_feat_slot` (four classes: `granted` 0, no options)
3. `test_owned_non_repeatable_feats_are_not_offered` (kaelen: Iron Will and Weapon
   Focus (longsword) absent, other weapons present)
4. `test_repeatable_and_parameterized_feats_expand_per_parameter`
5. `test_option_text_round_trips_through_feats_parse`
6. `test_prerequisites_are_evaluated_on_the_staged_level_four_character` (Cleave
   ineligible: "requires the Power Attack feat")
7. `test_pending_ability_increase_changes_the_feat_options` (kaelen's Dodge: refused
   at Dex 12, offered with `{"ability": "dex"}`)
8. `test_fighter_bonus_flag_filters_the_slot`
9. `test_sorcerer_options_are_the_implemented_second_level_arcane_spells` (one row,
   `scorching_ray`; cleric, wizard and fighter have none)
10. `test_known_spells_are_excluded_and_both_modules_agree`
11. `test_skill_options_report_cost_cap_and_affordable_ranks` (class 7, cross 3,
    cost 1 and 2, `max_new_ranks` follows the remaining points)
12. `test_intelligence_increase_raises_the_budget_and_max_ranks` (ysolde Int 17 to
    18: budget 5 to 6)
13. `test_choices_do_not_mutate_the_character_and_are_deterministic`
14. `test_blockers_match_level_up_required_for_every_class`
15. `test_validate_agrees_with_apply_on_every_refusal_code`
16. `test_ineligible_character_gets_the_level_up_code` (level 2, XP 5,999, level 4)
17. `test_the_step_still_goes_through_level_up_apply` (choice data applies nothing
    by itself)

### 13.7 Verification and records

After implementation: full suite, both validators, and a diff limited to
`src/core/level_choices.gd`, the `stage` seam in `src/core/level_up.gd`, the
`fighter_bonus` metadata in `src/core/feats.gd` (13.2), `tests/test_level_choices.gd`
and the records. No export, no manual testing request, no backup changes, no content
or save-format change.

### 13.8 State after this planning step, kept separate

- **Defects:** none known. The single-entry 2nd-level arcane pool is a content
  limitation, not a defect: the rule reads the pool, it does not require more than
  one spell.
- **Deferred features:** the level-up screen and its probe (batch 4), exported
  acceptance (batch 5), levels 5 and above, multi-level steps, NPC advancement,
  half ranks (the engine stores whole ranks), and the printed fighter bonus-feat
  restriction if its page cannot be sourced.
- **Maintenance debt:** `LevelUp._stage` becoming a public seam in this batch;
  `Skills.max_ranks` reading `ch.level`, so every option must be computed on the
  staged copy; `Feats.CATALOG` carrying no class-feat metadata until 13.2 adds it;
  the plan's two original stage names still mapping to `LevelUp`.
- **Evidence gaps:** nothing here is implemented, so there is no red log, no UI, no
  probe, no exported run and no manual playtest for batch 3 yet. The batch-2 run
  does not stand in for any of them.

### 13.9 Batch 3 record (2026-11-22)

Implemented as planned. `src/core/level_choices.gd` (`class_name LevelChoices`)
returns one `choices(ch, draft)` dictionary; `tests/test_level_choices.gd` holds 18
tests - the 17 planned plus one for the empty spell pool - written before the module
existed.

**Source verified before coding.** PHB printed p. 38 reads: "These bonus feats must
be drawn from the feats noted as fighter bonus feats on Table 5-1: Feats (page 90). A
fighter must still meet all prerequisites for a bonus feat, including ability score
and base attack bonus minimums." Table 5-1, printed pp. 90-91, marks them with
footnote 1: "A fighter may select this feat as one of his fighter bonus feats." The
plan's earlier wording ("PHB p. 38 ... a named list") was imprecise: the markers are
in Table 5-1, and p. 38 only points there. `Feats.CATALOG` now carries
`fighter_bonus` on all 41 entries, ten true: Cleave, Combat Expertise, Dodge, Exotic
Weapon Proficiency, Improved Trip, Point Blank Shot, Precise Shot, Power Attack,
Weapon Finesse, Weapon Focus. Implemented feats the table does **not** mark, and that
the picker therefore excludes: Improved Initiative, Toughness, Skill Focus, Alertness,
the three armor proficiencies, Shield Proficiency, Simple and Martial Weapon
Proficiency, Extra Turning, Improved Turning, and the skill feats.

**Seams.** `LevelUp.stage(ch, choices, complete := false)` is the public staging seam
(the former `_stage`); `apply` still calls it with `complete = true` and commits once.
`LevelUp.required_choices(ch, choices)` is the single required-choice list that
`preview`, `apply` and `blockers` read, so the three cannot drift.

**Behaviour.**

- Fighter options: the implemented catalog, filtered by the printed markers, sorted by
  name and then parameter; the other four classes get none. An owned parameter is left
  out (Weapon Focus (longsword) is not offered again, other weapons are). Each
  candidate's prerequisites are checked on the staged level-4 copy with the draft
  ability applied, and `Feats` reasons are copied verbatim.
- Parameterized feats expand over the shipped weapons. The parameter is the content
  id, so `Feats.parse(option.text)` round-trips. A weapon that is not exotic stays
  listed for Exotic Weapon Proficiency with the reason `Feats` already returns,
  instead of being filtered by a second rule.
- Sorcerer: implemented spells of the new level that are open to the class, minus the
  known list - one row today (`scorching_ray`). Every other class gets none.
- Skills: `cost_per_rank`, `ranks`, `cap`, `max_new_ranks`, `trained_only` and
  `affordable` from `Skills` on the staged copy, with `max_new_ranks` also limited by
  the remaining points; the budget is the class points plus the Int modifier after the
  draft increase.
- `blockers` is `LevelUp.required_choices(ch, draft)`, so it equals
  `preview(...).required` for every class. An empty sorcerer pool keeps "spell" as a
  blocker and forces `complete` to false.
- `validate` stages with `complete = true`, so it returns exactly the code `apply`
  would, with `fields` naming the choice group. It never mutates.

**Red, then green.** Before the module existed the suite logged

    SCRIPT ERROR: Parse Error: Identifier "LevelChoices" not declared in the current scope.
       at: GDScript::reload (res://tests/test_level_choices.gd:57)

and never collected the file: `Scripts 62`, `Tests 832`, `Asserts 8350`, with GUT
still exiting 0. The first green run was 849/850 - the shared helper asserted the
character was unchanged after a *successful* `apply` too; it now checks that around
`validate` always and around `apply` only for refusals. Final: 850/850 tests, 8,562
assertions, 63 scripts; `--validate-campaigns` PASS; `--validate-diagnostics` PASS
with `CLASS PROGRESSION PASS | 8 accepted authored inconsistencies`. A one-time
`--import` registered the new `class_name`; it changed no source or content.

**Limits.** No scene, probe, export or play path calls `LevelChoices`; nothing
player-visible changed, so no candidate was exported. No manual testing was requested
and no backup was touched. The screen and its keyboard path are batch 4; exported
acceptance is batch 5.

**Kept separate.**

- **Defects:** none found in this batch.
- **Deferred features:** the level-up screen and probe, exported acceptance, levels 5
  and above, multi-level steps, NPC advancement, half ranks, printed fighter feats
  this slice does not implement (Weapon Specialization, Improved Bull Rush, Quick
  Draw, Two-Weapon Fighting and others), and a content check that keeps a 2nd-level
  arcane spell in the pool.
- **Maintenance debt:** `Feats.CATALOG` now carries a presentation flag
  (`fighter_bonus`) that only the choice module reads; a feat's skill parameter is a
  content id, so a Skill Focus row reads "Skill Focus (search)"; `LevelUp.stage` is
  public and defaults to review mode (`complete = false`), which a caller could mistake
  for validation.
- **Evidence gaps:** no UI, probe, exported run or playtest for batch 3, so the choice
  data is unit-covered only and its ordering and reasons have not been seen on screen.
