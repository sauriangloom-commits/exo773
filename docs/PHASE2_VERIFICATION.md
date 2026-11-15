# Phase 2 Verification, Rules Audit and Hardening

Date: **2026-11-03**  
Working directory: `C:\Users\Noot Goblin\Downloads\Project Ravenloft\ravenloft-foundation`  
Baseline revision: **83c5534720083b766593f19eb524f5ecd7883d27** (372 tracked files)  
Baseline result: 72 tests / 72 passing / 501 assertions / 8 scripts, exit 0.  
Phase 2 result: **84 tests / 84 passing / 615 assertions / 9 scripts, exit 0.**
Post-Phase 2 extensions (**not part of the Phase 2 audit below**): area travel
was followed by the source-grounded Phase 3 town square. Current suite:
**98 tests / 98 passing / 724 assertions / 11 scripts**. The Phase 2 figures
below remain the historical audit snapshot.

The duplicate `Project Ravenloft - Copy\ravenloft-foundation` was identified as a
stale copy and was **not** modified or synchronized. The canonical project above
is the only project changed in this phase.

## 1. Reproduced environment and clean run

| Item | Actual value |
| --- | --- |
| Godot | `4.7.2.stable.official.ed1daf0bf` |
| GUT | 9.6.1 vendored (update notice for 9.7.1 ignored) |
| Import | `Godot --headless --path . --import`, exit 0, no script/parse errors |
| Tests | `Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` |
| Test result | 84/84 passing, 615 assertions, 9 scripts, exit 0 |
| JSON content | 10 files parsed successfully after removing the temporary probe |
| Test saves | redirected to `user://test_saves`; player `user://saves` was not written by GUT |

The teardown warning is intermittent: normal runs printed 2–3 `ObjectDB
instances were leaked at exit` plus `1 resources still in use at exit`, while two
normal runs and one `--verbose` run were clean. The verbose run named no project
object. This is recorded as **intermittent teardown noise, not reproduced**, rather
than silently discarded or claimed fixed.

### Added regression coverage

`tests/test_hardening_regressions.gd` adds 11 source-derived tests. The UI suite
also now checks that a 1.6× text exploration screen still contains all four party
cards and a scroll container. The temporary authoring probe was run separately
(84/84, 624 assertions) and then removed.

## 2. Rules audit

Classification: **Correct**, **Documentation error**, **Implementation defect**,
**Intentional adaptation** or **Unsupported**. Tests are in `tests/` unless a
screenshot is named.

| Mechanic | Source | Expected tabletop behavior | Implementation and result | Overview accuracy | Test / evidence |
| --- | --- | --- | --- | --- | --- |
| 0 HP, negative HP, dying, death | PHB pp. 145–146 | 0 HP is disabled; −1 to −9 is dying; −10 is dead; healing to 0 does not make a character stable | `Character.take_damage`/`heal` distinguishes disabled, dying, stable and dead; healing exactly to 0 stays disabled. **Correct.** | Accurate after Phase 2 | `test_damage_and_disabled_at_zero`, `test_dying_and_death_thresholds`, `test_healing_stabilizes_then_revives`, `test_healing_exactly_to_zero_leaves_disabled_not_stable` |
| Stabilization and death cleanup | PHB pp. 145–146 | 10% stabilization per round; −10 dead; dead creatures cannot remain stable/disabled | Stabilization is rolled at turn start; death clears stable/disabled. First aid checks end conditions. **Correct.** | Accurate | `test_stabilize_action`, `test_skill_based_stabilisation`, `test_healing_exactly_to_zero...` |
| Critical threats, confirmation, immunities | PHB p. 140; MM pp. 305, 317 | Confirm a threat; only weapon damage terms multiply; undead/constructs are crit-immune | Confirmation is implemented; a natural 20 confirms; undead and constructs are immune. **Correct.** | Accurate | `test_critical_threat_has_confirmation_and_multiplied_dice`, `test_undead_are_immune_to_critical_hits` |
| Standard/move/full-round accounting, double move | PHB pp. 138–144 | A double move spends the standard action; movement cannot be repeated indefinitely | `Encounter` spends standard for a second move and blocks a third move. **Correct.** | Accurate | `test_double_move_spends_standard_action_and_blocks_third_move`, `test_movement_budget_is_enforced` |
| 5-ft step and movement | PHB p. 144 | One 5-ft step per turn; no other movement; does not provoke | Step is once per turn, blocks further movement and does not provoke. **Correct.** | Accurate | `test_five_foot_step_does_not_provoke`, movement tests |
| Monster single attack vs full routine | PHB pp. 143–144; MM p. 119 | A monster that moves may make one attack; a full natural routine requires a full-round action from an adjacent start | Ghoul/zombie move-then-attack yields one attack; full routine is only from an adjacent start. Ghoul secondary claws use half Strength. **Correct.** | Accurate after Phase 2 | `test_ghoul_moves_then_makes_only_one_attack`, combat damage tests |
| Attacks of opportunity and per-round limits | PHB pp. 137–141 | One AoO per creature per round; movement out of threatened squares and ranged attacks in melee provoke | `aoo_used` is keyed per combatant and cleared at the start of each round; all threatening enemies are considered; potion use provokes per PHB p. 140. **Correct.** | More precise than the old overview | `test_moving_out_of_threatened_square_provokes_attack_of_opportunity`, `test_moving_out_of_two_threats_provokes_from_both`, `test_potion_in_melee_provokes_an_opportunity_attack` |
| Initiative ties | PHB p. 136 | Resolve ties by a table rule (normally another roll or agreed order) | Deterministic seeded tie-break, logged. **Intentional adaptation** for reproducibility. | Accurate | `test_initiative_order_is_descending`, seeded combat tests |
| Flat-footed at combat start | PHB p. 133 | Each combatant starts out flat-footed and remains flat-footed before their first regular turn; they lose their Dexterity bonus to AC. Awareness determines whether a surprise round precedes regular rounds. If everyone is aware, there is no surprise round, but combatants are still flat-footed before their first regular turn. | Not applied at combat start. `Rules.armor_class` supports a flat-footed option and helpless targets use Dex 0, but `Encounter.begin` does not apply combat-start flat-footed to any combatant. **Documented, bounded adaptation.** Awareness only removes a surprise round; it does not make this omission rules-faithful. | Corrected 2026-11-08 after reading PHB p. 133 | `test_helpless_target_has_dexterity_zero`; no combat-start flat-footed test at that date. **Applied 2026-11-13** (`tests/test_flat_footed.gd`, `Encounter.begin`); see TRACEABILITY row 2a. |
| Spell legality, slots, prepared vs spontaneous | PHB pp. 177–196 | Only class/level legal spells; prepared casters expend prepared slots; sorcerers cast spontaneously from known spells | Content declares classes, levels, slots, prepared lists and Mira's spontaneous known list; casting validates class/level legality and consumes the right resource. **Correct within the six-spell scope.** | Accurate after correcting the old "spontaneous unsupported" wording | `test_spell_preparation_and_consumption`, `test_spontaneous_caster_uses_slots_without_preparation`, `test_magic_missile_consumes_slot_and_kills_target` |
| Ranges, durations, targeting, potion use | PHB pp. 148–176, 195–196, 205, 225, 227 | Enforce range; duration by caster level where stated; legal targets only; potion use provokes | Range is enforced; mage armor/aid durations and aid temporary HP scale with caster level; dead/undead/invalid targets are rejected without spending resources; potion use provokes. **Correct.** | Accurate | `test_spell_range_is_enforced`, `test_mage_armor_and_aid_use_caster_level_durations`, dead-target regressions, potion AoO regression |
| Bonus types, stacking, temporary HP, expiry | PHB pp. 132–134, 195–196 | Same-type bonuses do not stack; temporary HP are separate and expire | Bless/aid morale bonuses do not stack; aid temp HP is cleared on expiry; mage armor is an armor bonus and does not stack. **Correct.** | Accurate | `test_mage_armor_is_an_armor_bonus_and_does_not_stack`, `test_effects_do_not_stack_and_expire`, `test_aid_expiry_clears_its_temporary_hit_points` |
| Rest and recovery | PHB pp. 145–146; project adaptation | Tabletop rest restores resources with campaign pressure | Shrine fully restores HP, slots and prepared lists as a deliberate recovery point. **Intentional adaptation.** | Accurate | `test_rest_restores_hp_slots_and_prepared_list`, `test_shrine_rest_restores_party` |
| Saving throws, paralysis, immunities | PHB p. 136; MM p. 119 | Fortitude save; ghoul paralysis 1d4+1 rounds; elves and undead immune | Fort DC 12, duration, elf/undead immunity and once-per-hit handling implemented. **Correct.** | Accurate | `test_ghoul_paralysis_affects_humans_but_not_elves` |
| Helpless and touch AC | PHB pp. 133–134 | Helpless Dex is 0; touch AC excludes armor, shield and natural armor | Natural armor is separated from `ac_misc`; helpless uses Dex 0 (−5); touch AC excludes natural armor. **Correct.** | Accurate after Phase 2 | `test_helpless_target_has_dexterity_zero`, `test_fighter_armor_class...` |
| Ghoul statistics | MM p. 119 | AC 14/touch 12/flat 12; bite +2 (1d6+1); claws +0 (1d3); Fort +0/Ref +2/Will +5; Cha 12 | Corrected to the source values, including secondary claw Strength and saves. **Correct.** | Previously inaccurate; corrected | Content validation and combat tests |
| Zombie statistics | MM p. 266 | AC 11/touch 9; slam +2 (1d6+1); Fort +0/Ref −1/Will +3; DR 5/slashing; single actions | Authored values and DR/single-action behavior match the supported subset. **Correct.** | Accurate | `test_damage_reduction_5_slashing`, `test_zombie_single_action_flag_is_data_driven` |

No rule was changed merely because `PROJECT_OVERVIEW.md` described it differently.
The ghoul stat block, natural-armor/touch-AC handling, critical immunity, aid
stacking/expiry, secondary natural attacks and potion provocation were confirmed
against code and tests before correction.

## 3. Persistence audit

Verified by `test_save_load_round_trip_preserves_world_state`,
`test_save_write_is_atomic_and_malformed_load_does_not_mutate_state`,
`test_quest_completes_when_all_flags_set`, the integration loop, and the
pre-existing save validation tests:

- Position, facing, doors, removed/searched objects, inventory, equipment,
  consumables, HP, spell slots/prepared lists, conditions/buffs, flags, quests,
  rewards, resolved encounters and RNG state round-trip.
- Saves are written temp+backup atomically; a malformed payload is validated
  before live state is mutated and leaves the prior state intact.
- Loading cannot duplicate one-time rewards in the tested paths; `only_if_missing`
  and flags gate repeated grants.
- Old saves remain version 1. No format change was required in this phase.
- Missing, malformed and incompatible files are reported rather than crashing.

**Not verified:** completing a save/load through the actual modal with mouse input,
and saving at every possible dialogue/combat transition. These remain UI-flow
gaps, not claims of success.

## 4. Player-flow and presentation verification

Windowed captures were taken from the running game viewport and inspected at:

| Resolution / setting | Evidence | Result |
| --- | --- | --- |
| 1280×720 | `phase2_explore_1280x720.png` | Exploration, party, objective, actions and log render |
| 1366×768 | `phase2_explore_1366x768.png` | Same layout, no missing panels |
| 1920×1080 | `phase2_explore_1920x1080.png` | Expands cleanly; no clipping observed |
| 1024×600 | `phase2_explore_1024x600.png` | Scaled layout; all action buttons remain visible |
| 1280×720 dialogue | `phase2_dialogue_1280x720.png` | Speaker, prose, five choices, party sidebar |
| 1280×720 combat | `phase2_combat_1280x720.png` | Initiative, grid, actions, targets, log |
| 1.6× text, 1280 and 1024 | `phase2c_text16_*`, `phase2b_text16_*` | Scrollable sidebar keeps all four party cards reachable; dialogue scrolls; combat legend wraps |

Presentation defects found and fixed in this phase:

1. At 1.6× text the fixed inner party/objective panels hid the fourth party member
   and clipped the objective. The whole exploration sidebar is now one vertical
   scroll container.
2. The combat legend was a single draw string that ran under the sidebar at 1.6×.
   It is now two short lines.
3. The dialogue panel grew past the viewport at 1.6× and clipped its footer. It is
   now capped to the viewport with an internal vertical scroll.

**Not verified:** mouse wheel scrolling, keyboard focus traversal, every modal
button, audio quality, and a complete click-through of the objective with native
input automation. The construction tests and screenshots do not prove those
interactions.

## 5. Content pipeline

A temporary, clearly labelled NPC/dialogue/test was authored using only
`docs/AUTHORING_GUIDE.md` and the existing JSON schemas. The documented workflow
worked: content validated, the NPC was reachable, conditional choice, effects,
item grant and repeat-gating behaved as documented. The temporary probe passed
84/84 with 624 assertions. It was then removed, along with its NPC and test, and
the clean suite returned to 84/84 / 615 assertions. No core feature was added to
make the probe pass; the guide did not need a correction for this workflow.

## 6. Windows export

**Blocked, no build produced.** The export attempt was:

```bash
Godot --headless --path . --export-release "Windows Desktop" build/ravenloft-foundation.exe
```

It exited 1 with:

```text
ERROR: This project doesn't have an `export_presets.cfg` file at its root.
Create an export preset from the "Project > Export" dialog and try again.
```

The Godot export-template directory also exists but is empty. Installing matching
Godot 4.7.2 templates and creating an export preset are prerequisites outside the
project. No `.exe`, PCK or successful exported run is claimed.

## 7. Remaining issues, ranked

1. **High — UI interaction coverage is shallow.** Save/load, settings and combat
   buttons are built and visually inspected, but not clicked end-to-end by an
   automated harness. A user could still find a modal or focus bug.
2. **Medium — flat-footed at combat start is not applied.** Every combatant is
   flat-footed before their first regular turn and loses their Dexterity bonus to
   AC (PHB p. 133). This is omitted as a **bounded adaptation**, not a
      rules-faithful result. Removing the surprise round because everyone is aware
   does not remove combat-start flat-footedness.
   **Resolved 2026-11-13 (`RL_Edit`).** `Encounter.begin` now marks every
   combatant flat-footed and `_begin_turn` clears it at the start of that
   combatant's first turn. The state denies a positive Dexterity bonus and any
   dodge bonus to normal and touch AC, denies opportunity attacks and allows a
   rogue's sneak attack; a Dexterity penalty still applies. All attack paths pass
   it to `Rules.attack`. Corrected 2026-11-13 after the first version wrongly
   removed the raw modifier and kept dodge bonuses (PHB p. 136). Covered by
   `tests/test_flat_footed.gd`; see TRACEABILITY row 2a. This note does not
   change the 2026-11-07 run recorded below, which described the earlier state.
3. **Medium — Windows export is blocked** by missing preset/templates. Packaging
   and exported-runtime behavior are unverified.
4. **Low — intermittent GUT teardown diagnostics.** Seen in normal runs as 2–3
   ObjectDB instances plus 1 resource, while two normal runs and one verbose run
   were clean; the verbose run named no project object. Monitor rather than claim
   fixed.
5. **Low — subjective audio quality and long-session stability are unverified.**
6. **Low — cover/concealment, firing into melee, AoE, full attacks and other
   deferred rules remain outside scope.** They are listed as deferred, not bugs.

## 8. Status summary

- **Verified:** clean import; 84/84 tests; rules corrections; save atomicity and
  round-trip; content pipeline; layouts at 1280×720, 1366×768, 1920×1080,
  1024×600 and 1.6× text; the three presentation fixes.
- **Failed:** none in the automated suite.
- **Blocked:** Windows export (no preset, empty templates).
- **Untested:** full native click-through, modal save/load, rebinding, subjective
  audio, long sessions, high-DPI beyond the captured sizes.
