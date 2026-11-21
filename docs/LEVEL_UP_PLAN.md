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
  gains a feat** (PHB p. 37, fighter table). No class gains a general feat at 4.
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

- **Cleric** (PHB cleric table, p. 31): printed 4th level is 5 / 3+1 / 2+1. In the
  engine's model (no 0-level, domain slots included, no Wis bonus): **1st 4, 2nd
  3** - one more 1st and one more 2nd than level 3's 3 / 2.
- **Wizard** (PHB wizard table, p. 57): printed 4th level is 4 / 3 / 2. With
  Ysolde's Int 17 bonus slot included, as authored at level 3: **1st 4, 2nd 3** -
  one more 1st and one more 2nd than 3 / 2.
- **Sorcerer** (PHB sorcerer tables, pp. 53-54): printed 4th level is 6 / 6 / 3
  per day and 6 / 3 / 1 known. Under the engine's no-0-level model: 1st stays 6,
  **2nd 3**, and the character learns **one new 2nd-level spell** - `scorching_ray`
  is the only implemented arcane 2nd-level spell.
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

1. **`level_tables` - class progression tables and validation.** Add the classes
   content (hit die, skill points, BAB and save rows 1-4, feat slots, spell slots
   for levels 1-4), validate it against `ContentSpec` and the diagnostics
   validator, and add the table tests. No gameplay change yet; the existing
   authored characters must validate against it. **This is the first batch.**
2. **`level_up_core` - XP thresholds and application.** `Rules.xp_threshold`,
   eligibility, the atomic `Character.apply_level` for the 3 to 4 step (HP, BAB,
   saves, skill points, ability increase incl. Con retroactivity, spell slots,
   feat slot), idempotence and save round-trip tests. No UI.
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

- **Page confirmation.** Table values are from the SRD mirror; the printed pages
  (Table 3-1 and 3-2 on p. 22; cleric p. 31; fighter p. 37; rogue p. 49; sorcerer
  pp. 53-54; wizard p. 57) must be checked against the book before batch 1 lands.
- **Thin catalog.** The eligible feat list is small, so a fighter's 4th-level
  bonus feat may look sparse; that is a content gap, not a rules gap, and adding
  feats is a separate rules batch.
- **Authored inconsistencies.** Feat counts and the missing 0-level row do not
  match the printed sheets. This plan accepts them and does not repair them; a
  later audit batch would.
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
