# Aid Another — planning note (2026-11-24)

Planning only. Nothing here is implemented, and no test, probe, validator, build or export
was run while writing it. The repository seams below were read in the working tree at
`17abb5b`; line numbers are of that tree and will drift.

This note closes the next-task review recorded in `17abb5b` by turning its recommendation
("combat Aid Another, PHB p.154, one bounded batch") into a plan with verified rules, exact
seams, resolved decisions, a failing-first test list and a measured-requirements acceptance.
It is a features plan, not a defect fix: the audit found no open executable defect.

## Printed rules

Source: *Player's Handbook* (3.5) p. 154, "Aid Another", and the SRD's *Special Attacks*
section (`d20srd.org/srd/combat/specialAttacks.htm`), read on 2026-11-24. The SRD text is the
same as the printed paragraph:

> In melee combat, you can help a friend attack or defend by distracting or interfering with
> an opponent. If you're in position to make a melee attack on an opponent that is engaging a
> friend in melee combat, you can attempt to aid your friend as a standard action. You make an
> attack roll against AC 10. If you succeed, your friend gains either a +2 bonus on his next
> attack roll against that opponent or a +2 bonus to AC against that opponent's next attack
> (your choice), as long as that attack comes before the beginning of your next turn. Multiple
> characters can aid the same friend, and similar bonuses stack.
>
> You can also use this standard action to help a friend in other ways, such as when he is
> affected by a spell, or to assist another character's skill check.

| Element | Printed rule | Page |
| --- | --- | --- |
| Cost | Standard action | PHB p. 154; SRD *Actions in Combat* table |
| Position | Helper must be "in position to make a melee attack" on the opponent, and the opponent must be "engaging a friend in melee combat" | PHB p. 154 |
| Check | Attack roll against **AC 10** (not the opponent's AC) | PHB p. 154 |
| Bonus kinds | Either +2 on the friend's **next attack roll against that opponent**, or +2 **AC against that opponent's next attack**; helper's choice | PHB p. 154 |
| Duration | Only while the attack "comes before the beginning of your next turn"; each bonus answers one attack | PHB p. 154 |
| Stacking | "Multiple characters can aid the same friend, and similar bonuses stack" | PHB p. 154 |
| Other uses | Helping against a spell, or a skill check, uses the same action | PHB p. 154 |
| Opportunity attack | The *Actions in Combat* table lists Aid another as a standard action with "Maybe" in the AoO column (footnote 2); the Aid Another paragraph itself says nothing about provoking | PHB p. 141 table, p. 154 |

The printed text does not name a size limit, a range, a per-round limit or a cap on helpers.
It does not say the helper must be a particular class, and it does not forbid aiding a
helpless, prone or grappled friend.

## Project adaptations

Separate from the printed rules, and each one must be visible in the code and the log:

- **A1 — no opportunity attack for the check.** The project has no unarmed-provocation model
  and no "assist" attack kind; the check is an assist, not an attack. `Rules.attack` is not
  used for it beyond its d20 conventions. This resolves the table's "Maybe" toward "no".
- **A2 — the check uses the helper's melee attack bonus with the equipped weapon but deals no
  damage.** Bonuses from the weapon (masterwork, magic, Weapon Focus) count, as they would for
  a real attack; Power Attack, Combat Expertise and fighting defensively are **not** offered on
  the check (the project has no per-attack trade UI outside an attack).
- **A3 — "engaging" is positional.** The friend counts as engaged when the foe threatens the
  friend's square **or** the friend threatens the foe's square, reusing the "either threatens
  the other" rule already used for the shooting-into-melee penalty
  (`encounter.gd:3429-3437`). All shipped foes are Medium with 5-ft reach, so in practice this
  is adjacency.
- **A4 — party only.** The monster AI never takes the action. This is an acknowledged
  asymmetry, not a claim about the printed rule; see "Monster AI" below.
- **A5 — the spell and skill-check uses are out of scope.** Only the melee assist is planned.
- **A6 — the bonus kind is chosen after a successful check**, through the existing pending
  decision, rather than at declaration. The printed rule fixes only that the helper chooses
  before the bonus is spent, so this is rules-equivalent and cheaper in UI.
- **A7 — the helper must have a melee weapon equipped.** With A1 there is no unarmed-strike
  provocation to model, so requiring a weapon keeps the check inside the modelled weapon path.

## Repository seams

Exact seams to touch, all read at `17abb5b`:

| Concern | Seam |
| --- | --- |
| Action list and grid | `combat_screen.gd:311-340` — 19 `_add_action_button` calls in a four-column grid |
| Enable map | `combat_screen.gd:989-1040` — the `enabled` dictionary ("Attack": `standard`, and the pending guard) |
| Standard action budget | `encounter.gd:90-96` `_fresh_turn_state()`; consumed through the action helper, reported at `combat_screen.gd:989` |
| Target modes | `combat_screen.gd:1713-1719` `_set_mode`; dispatch at `:1108-1121` (pending guard), attack branch `:1164-1180` |
| Pending decisions | `encounter.gd:51-53` (state), `:2710` `has_pending_decision()`, `:232-234` discard at turn start; UI `combat_screen.gd:1412-1433` `_rebuild_decision`, `:1441+` `_build_decision`, spec `:1309` `_decision_spec` |
| Attack modifiers | `rules.gd:668` `Rules.attack`, `:710` `bonus_base`, `:718-723` flank term; opts assembled at `encounter.gd:3031-3047` |
| AC modifiers | `rules.gd:726-746` AC/touch selection, `:270-296` `armor_class` (flat-footed, deny-dex, dodge, `pinned_penalty`), `:299-315` `touch_ac` |
| Round and turn expiry | `encounter.gd:225-270` `_begin_turn` (pending discard, pin expiry, flat-footed, Power Attack, Combat Expertise, stances), `character.gd:197` `tick_effects` |
| Cleanup — death | `encounter.gd:3119` `_apply_damage`, `:4635` `_check_end`, `:4661-4679` defeat predicates, `:491` `_prune_grapples` |
| Cleanup — turning and finish | `encounter.gd:4166` `turn_undead`, `:4681-4696` `finish`, `:2951-2959` `_clear_combat_scope_states` |
| Monster AI | `encounter.gd:4300` `_run_monster_turn`, `:4562` `_monster_single_attack`, `:4585` `_monster_full_attack` |
| Reach and threat | `encounter.gd:753` `_threatens_cell`, `:3403-3443` `_into_melee_penalty` |
| Helplessness | `rules.gd:219-226` `is_helpless` |
| Probe infrastructure | `main.gd:62-118` `APP_FLAGS`; dispatch `:368-372`; pattern `:10921-10993` `_flanking_probe` with `_flanking_probe_force_turn` fixture |
| Layout infrastructure | `main.gd:2569-2674` `_layout_probe`, the `LAYOUT PROBE … controls=%d failures=%d` line |
| Key targeting | `combat_screen.gd:393-408` `_begin_grid_keyboard`, `:442-461` Escape/`ui_cancel` cancel path, `:1412-1452` decision focus restore |

## Resolved decisions

### D1 — Who may aid whom, and which foe

- **Helper:** the active party combatant, `can_act()`, not helpless (`rules.gd:219`), not
  grappled or pinned, with a melee weapon equipped (A7). A helper who cannot take a standard
  action is refused before the mode opens.
- **Friend:** any other living party combatant, including one who is prone, grappled, pinned,
  paralyzed or otherwise helpless. A dead combatant is refused. The printed rule does not
  restrict the friend, and the +2 AC bonus is meaningful precisely for a friend who cannot
  defend herself.
- **Foe:** an enemy for which `_threatens_cell(helper, helper_cell, foe_cell)` is true (the
  helper is in position to melee it) and the friend is engaged with it per A3. A foe that is
  dead or `nonlethal_unconscious` is refused, matching the attack path's refusal.
- The helper may not aid itself.

### D2 — Where the bonus kind is chosen

After a **successful** check, through the existing pending-decision surface: a new
`pending_aid` state and a `"aid"` decision kind, with two buttons ("+2 attack",
"+2 AC") and no decline (the printed bonus is automatic). This mirrors Cleave's
target choice, reuses the focus keys and reseating path (`combat_screen.gd:1412-1452`),
and adds no persistent control to the sidebar. A failed check never opens a decision.

Rejected alternatives: a checkbox or `OptionButton` in the action row (an always-visible
control in the tightest part of the layout, for a choice made at most once per turn), and two
separate "Aid (attack)" / "Aid (defense)" buttons (two more grid buttons, two modes, and the
same decision content decided twice).

### D3 — State, owner and expiry

Encounter-owned, like `power_attack_committed` and `combat_expertise_*`
(`encounter.gd:51-53`, `:2951-2959`):

- `pending_aid: Dictionary` — `{helper, friend, foe}` while the choice is open; cleared with
  the other pending states at `_begin_turn` (`:232-234`) and at `finish` (`:4681`).
- `aid_attack: Dictionary` — friend index → `Array[Dictionary]` of
  `{foe: int, amount: 2, helper: int}`, summed when the friend attacks that foe.
- `aid_ac: Dictionary` — protected friend index → the same array shape, summed when that foe
  attacks the friend.

Expiry, exactly:

1. **Helper's next turn starts** — `_begin_turn` removes every entry whose `helper` equals the
   starting index from both maps and logs it, beside the pin and Power Attack expiry
   (`:225-270`). This is the printed "before the beginning of your next turn".
2. **Attack bonus** — consumed after the friend's next attack roll against that foe, whether
   it hits or misses, in `_resolve_attack` after `Rules.attack` returns
   (`encounter.gd:3048-3060`).
3. **AC bonus** — consumed after that foe's next attack against the friend, in the same
   function; monster attacks arrive through `_monster_single_attack` (`:4562`), so the same
   consumption point covers them.
4. **Death or removal** of either participant, or encounter finish: entries naming that index
   are dropped in `_check_end`/`_clear_combat_scope_states`, and `pending_aid` is voided in
   `finish`, following the existing grapple and decision cleanup (`:4681-4696`).
5. **Turning** does not remove aid: a cowering/panicked creature can still be defended, and the
   bonus expires on its own schedule.

### D4 — Stacking and interactions

- **Stacking:** summed per (friend, foe) pair, one entry per helper, no cap — printed
  "similar bonuses stack". Two helpers give +4 to one attack, not two separate attacks.
- **Flanking:** unchanged and independent. Aiding does not make the helper a flanker, does not
  create a flank for the friend, and does not open sneak attack. The attacker-specific flank
  model from `1e7dc4b` stands.
- **Grapple and pin:** a grappled or pinned helper is refused (A7 plus the reality that the
  check needs a free weapon swing); a grappled or pinned friend can be aided and keeps its own
  AC penalties, so the +2 partially offsets them. A pinned friend's `pinned_penalty` still
  applies (`rules.gd:290`).
- **Helplessness:** a helpless friend can receive the +2 AC; the +2 attack is granted but will
  go unused if she cannot act, and the log should say so rather than silently waste it. A
  helpless helper is refused.
- **Integration:** a new `aid_attack_bonus` opt added beside the flank term after `bonus_base`
  (`rules.gd:718-723`), so a Cleave follow-up evaluates its own target; a new `aid_ac_bonus`
  opt added in both `armor_class` and `touch_ac`, mirroring `pinned_penalty`
  (`rules.gd:290-296`, `:313-315`); both passed from `attack_opts`
  (`encounter.gd:3031-3047`) and logged like the flank line (`:3069`).

### D5 — Failure and the action's cost

A check total below 10 (natural 1 always fails, natural 20 always succeeds, matching
`Rules.attack`'s convention at `rules.gd:756-759`) spends the standard action, logs
"aid fails" with the roll, grants nothing, opens no decision and leaves the turn state
otherwise unchanged — no bonus, no partial state, no movement. The helper's standard action is
spent whether the check succeeds or fails. A refused declaration (wrong target, bad position)
spends nothing and only sets the UI message.

### D6 — Controls and layout

- Today: 19 action buttons (`combat_screen.gd:311-340`) in a four-column grid, 32 controls in
  the accepted `LAYOUT PROBE` runs at 1280×720 and both scales.
- Planned: one "Aid" button, the 20th, which fills the grid's five rows exactly (20 = 5 × 4)
  instead of leaving a ragged last row. The pending decision adds buttons only inside
  `decision_box` while it is open, and it replaces nothing.
- **Expected** control count: 33 (32 + 1). **Not measured.** No probe was run for this note,
  and the expectation is not a result: the implementation's acceptance requires
  `LAYOUT PROBE`/combat-info runs with `failures=0` at both scales, and the measured count
  recorded in the acceptance, not assumed here. The risk is real — the sidebar is at its
  340 px minimum and every added row competes with the log — so the button must be measured
  before the batch is called done.

### D7 — Keyboard and mouse

- **Mouse:** Aid enters mode `"aid"` (`_set_mode`, `combat_screen.gd:1713-1719`); clicking an
  enemy resolves the check through `_on_cell_clicked` (`:1108-1121` guard, `:1164-1180`
  attack-branch template), with the existing "not your turn" / "resolve the pending decision
  first" guards intact.
- **Keyboard:** mode entry begins grid targeting (`_begin_grid_keyboard:393-408`); arrows move
  the cursor, Enter confirms through the same cell path, Escape cancels via the `ui_cancel`
  branch    (`:442-461`) without opening the pause menu. The new button joins the action focus
  ring automatically because it is created by `_add_action_button`.
- **Decision:** both bonus buttons carry `combat_focus_key` metadata and are reached in the
  existing decision ring; focus is restored by `_rebuild_decision`'s key lookup and reseated
  by `_reseat_after_resolution` after the choice, so resolution never strands focus.
- The button is disabled in the enable map when the standard action is spent, a decision is
  pending, the helper is grappled/pinned/helpless, or no valid (foe, friend) pair exists; the
  UI message names the first failing reason.

### D8 — Monster AI

No AI change (`_run_monster_turn:4300`, `_monster_single_attack:4562`). Monsters keep
attacking. Party-only use is acceptable for this batch because the printed action is optional,
the shipped opposition is small and mostly solo (four monster types; eight encounters, sixteen
placements; only the looter is a living humanoid), and giving monsters the action would be a
difficulty change that needs its own measurement — the same reasoning that kept the flanking
parity unmeasured in `5b68e22`. It is an asymmetry to record, not a defect to fix.

## Is it worth taking in the shipped encounters?

Numbers from the shipped content at this tree:

| Combatant | Melee attack bonus | Source |
| --- | --- | --- |
| Kaelen (Fighter 3) | +8 | BAB 3 + Str +3 + Weapon Focus +1 + masterwork +1 |
| Sera (Rogue 3) | +5 | BAB 2 + Dex +3 (Weapon Finesse, short sword) |
| Aldric (Cleric 3) | +4 | BAB 2 + Str +2 |

| Monster | AC | HP | Derived from |
| --- | --- | --- | --- |
| Soaked Looter | 15 | 8 | 10 + chain shirt 4 + Dex 1 |
| Zombie | 11 | 16 | 10 − Dex 1 + natural 2 |
| Ghoul | 14 | 13 | 10 + Dex 2 + natural 2 |
| Infected Zombie | 16 | 39 | 10 + Dex 0 + natural 6 |

Hit chances: Kaelen 70/90/75/65 %, Sera 55/75/60/50 %, Aldric 50/70/55/45 % against
looter/zombie/ghoul/infected zombie.

The trade is one standard action from the helper against +2 to a single attack. Against the
infected zombie, Aldric aiding Sera moves her hit chance 50 % → 60 %: roughly +1.25 expected
damage with a flanking sneak attack (1d6+2 plus 2d6), against roughly 2.9 expected damage from
Aldric attacking at 45 % with 1d8+2. Against the ghoul the gap is wider. The +2 AC side is
weaker still: it cuts a looter's chance to hit Sera from 40 % to 30 %, about 0.55 expected
damage prevented.

**Honest conclusion:** in the shipped encounters Aid Another is rarely the best action. It is
worth taking when the helper's own attack is heavily penalised or impossible (out of reach,
prone with a non-crossbow, −4 shooting into melee without Precise Shot, or a target the helper
cannot hurt), when the friend's single attack carries a large rider (Sera's sneak dice, a coup
de grace), or when preventing one hit prevents a drop. The batch adds a printed option and a
party tactic; it does **not** fix balance, and no benefit beyond those cases should be claimed.
A future content pass that wants the action to matter needs fights with mixed AC or helpers
who cannot reach — not a rules change.

## Failing-first tests

`tests/test_aid_another.gd`, following `tests/test_bull_rush.gd`'s shape. Every test must fail
before the implementation and pass after:

1. A helper cannot aid itself; the declaration is refused and no action is spent.
2. A helper 10 ft from the foe is refused ("not in position").
3. A foe that is not engaging the friend is refused.
4. A successful check opens the decision; "attack" grants +2 only on the friend's next attack
   against that foe, visible as a roll delta and an explicit log line.
5. The attack bonus does not apply when the friend attacks a different foe, and is spent by
   the first attack against the right foe whether it hits or misses.
6. "AC" grants +2 against that foe's next attack only; a different attacker ignores it.
7. A monster's attack consumes the AC bonus and a second attack that round does not receive it.
8. An unused bonus expires at the start of the helper's next turn and logs the expiry.
9. Two helpers stack to +4 on one attack; a third is not capped but sums.
10. A failed check spends the standard action, grants nothing, and opens no decision.
11. Grappled and pinned helpers are refused; a helpless friend can be aided for AC.
12. Death of the friend, death of the foe, and encounter finish drop the state; finish also
    voids an open `pending_aid`.
13. The decision's two buttons resolve through `Game.combat_resolve_aid(...)` and restore
    focus by `combat_focus_key`.
14. With the standard action spent, or a decision pending, the Aid button is disabled and the
    mode does not open.

## Probe and acceptance

- `--aid-another-probe` (added to `APP_FLAGS`, `main.gd:62-118`) with a seeded RNG and a
  labelled fixture (`_aid_probe_force_turn`, the `_flanking_probe_force_turn` pattern at
  `main.gd:10993`) driving the **ordinary** path: `Game.combat_aid(...)` then
  `Game.combat_resolve_aid(...)`, plus one real ally attack and one real monster attack so the
  consumption is observed, not asserted from internals. Target ~10 checks: position, engage,
  success, choice, attack consumption, off-foe immunity, AC consumption, expiry, stacking,
  failure. Prints `PROBE RESULT PASS scenario=aid_another checks=<n>`.
- Fixtures and forced turns are labelled as seeded setup; the probe reports the ordinary path,
  not a raw hook.
- Acceptance for an eventual implementation:
  1. Red first: the new tests fail for the stated reasons, with the red log kept.
  2. Green: focused tests pass; the full suite passes with its count and assert total rising;
     both validators pass.
  3. All existing probes keep their accepted counts; the new probe passes.
  4. `LAYOUT PROBE` at 1280×720 and both scales: `failures=0` at the **measured** control
     count, which is recorded in the acceptance rather than assumed.
  5. One exported candidate `2026-11-24_aid_another` (or the then-current date) with
     `BUILD.txt` binding `source_head`, the worktree entries and diff hash, and the exe
     sha256 and byte size; the candidate is hash-bound, not merely named.
  6. No content, schema, save, award or XP change; the opposed-check helper is untouched.

## Batches (amended 2026-11-24: one acceptance unit)

The earlier two-batch split — attack half first, defence half second — is **withdrawn**. Both
bonus kinds ship as **one acceptance unit**. The printed action is a choice between +2 attack
and +2 AC; shipping only one half would put the printed name on a partial action, and no
migration path makes that honest. The unit therefore contains the whole melee assist: the
position and engagement checks, the d20 against AC 10, both bonus kinds, their consumption and
expiry, stacking, the button, mode, friend and bonus decisions, the keyboard and mouse paths,
cleanup, tests, probe, layout evidence and one hash-bound candidate.

Stopping remains possible, but at the batch boundary before any of it: if the action is not
wanted, the alternative is the stopping point recorded in `17abb5b`. There is no "attack-only"
release.

## What "next attack" covers

The bonus attaches to one attack **roll**, whatever produced it, and is consumed by that roll
whether it hits or misses. A full attack's later swings are separate rolls and receive nothing.

| Attack roll | Friend's +2 attack | Foe's +2 AC |
| --- | --- | --- |
| Weapon attack through `attack_active` → `_resolve_attack` (`encounter.gd:788`, `:2985`) | applies, consumes | applies when that foe attacks the friend |
| Cleave follow-up (`resolve_cleave_attack`, `:2642` → `_resolve_attack`) | applies, consumes | applies |
| Improved Trip follow-up (`resolve_improved_trip_attack`, `:2489` → `_resolve_attack`) | applies, consumes | applies |
| Trip touch attack (`Rules.attack`, `:1403`) | applies, consumes | applies if a foe's trip touch attacks the friend |
| Grapple touch attack (`Rules.attack`, `:2021`) | applies, consumes | applies |
| Opportunity attack (`_opportunity_attack`, `Rules.attack` `:3520`) | applies, consumes — reaction attacks are covered | applies |
| Ranged touch spell (`_cast_scorching_ray`, `Rules.attack` `:3871`) | applies, consumes | applies |
| Monster full attack (AI, `_monster_full_attack` `:4585`) | monsters never aid | first swing only; later swings are uncovered |
| Charge | no charge action exists in this build (deferred), so nothing is claimed | — |
| Attack refused before rolling (prone ranged, illegal target, dead foe) | does not apply and does not consume | does not apply |

The printed "next attack" is read as the next attack roll, not the next attack action, so a
full attack's first swing consumes it. If an attack is aborted before any roll, the grant
survives.

## Recomputed expected-damage comparison

Stats from `content/shared/characters.json` and `content/shared/monsters.json`; damage is the
average of the printed dice plus the ability modifier.

| Combatant | Attack bonus | Average damage | AC |
| --- | --- | --- | --- |
| Kaelen | +8 = BAB 3 + Str +3 + Weapon Focus 1 + masterwork 1 | longsword 1d8+3 = 7.5 | 17 = 10 + chain shirt 4 + heavy shield 2 + Dex 1 |
| Sera | +5 = BAB 2 + Dex +3 (Weapon Finesse, short sword) | short sword 1d6+1 = 4.5; flanking sneak 4.5 + 2d6 (7) = 11.5 | 15 = 10 + leather 2 + Dex 3 |
| Aldric | +4 = BAB 2 + Str +2 | heavy mace 1d8+2 = 6.5 | 16 = 10 + scale 4 + shield 2 |
| Soaked Looter | +2 = BAB 1 + Str 1 | longsword 1d8+1 = 5.5 | 15 = 10 + chain shirt 4 + Dex 1 |
| Zombie | +1 | slam 1d6 = 3.5 | 11 |
| Ghoul | +3 bite / +3 claw | bite 1d6 = 3.5 | 14 |
| Infected Zombie | +2 | slam 1d6 = 3.5 | 16 |

Hit chance is `(21 − AC + attack bonus) / 20`, floored at 5 % and capped at 95 %; Sera's
flanking damage below assumes the flank is already established, so the aid is not paying for it.

| Case | Helper's forgone damage | Gain from +2 | Net |
| --- | --- | --- | --- |
| Aldric aids Sera vs Infected Zombie (AC 16) | 0.45 × 6.5 = **2.925** | Sera 50 % → 60 %: 0.10 × 11.5 = **1.15** | **−1.775** |
| Aldric aids Sera vs Ghoul (AC 14) | 0.55 × 6.5 = **3.575** | 60 % → 70 %: 0.10 × 11.5 = **1.15** | **−2.425** |
| Aldric aids Sera vs Looter (AC 15) | 0.50 × 6.5 = **3.25** | 55 % → 65 %: 0.10 × 11.5 = **1.15** | **−2.10** |
| Aldric aids Sera vs Zombie (AC 11) | 0.70 × 6.5 = **4.55** | 75 % → 85 %: 0.10 × 11.5 = **1.15** | **−3.40** |
| +2 AC vs Looter attacking Sera (AC 15) | 3.25 (Aldric's attack) | 40 % → 30 %: 0.10 × 5.5 = **0.55** | **−2.70** |

Correction: the earlier draft quoted Sera's short sword as 1d6+2 and a 1.25 gain with a 2.9
cost. From the authored Str 12 the weapon is 1d6+1, so the gain is 1.15 and Aldric's cost is
2.925. The conclusion does not change: in the shipped encounters aiding is worse than attacking
unless the helper's own attack is impossible or penalised, or one prevented hit prevents a drop.

## Eligibility (settled)

- **Foe.** Enemy, alive, `can_act()`, not helpless (paralyzed, unconscious, dying, dead) and
  not cowering; a flat-footed foe **is** eligible, because flat-footedness removes opportunity
  attacks, not attacks. A grappled or pinned foe is eligible: it can still attack, and it is
  engaged with the friend. The foe must be within the helper's melee reach
  (`_threatens_cell`, `encounter.gd:753`) and engaged with the friend (either threatens the
  other, `:3429-3437`).
- **Ally.** Party, alive, not the helper; a flat-footed ally is fine. An ally who cannot act
  (paralyzed, helpless, dying, stable) is offered **only the +2 AC**; the attack option is not
  shown, because the bonus would expire unused, and the log says so.
- **After the grant.** If the foe dies or becomes helpless, the grant stays but cannot be used
  against it and is not re-targeted. Turning a foe to cowering does not clear a grant: the AC
  half still applies if that foe attacks, and expiry is unchanged.
- **Self, allies as foes, dead creatures, unengaged foes, out-of-reach foes and grappled or
  pinned helpers** are refused before any action is spent.

## Out of scope

Readied and delayed actions, a general modifier framework, AI use of Aid Another, overrun
(still deferred), the opposed-check helper (unchanged), content or balance changes, XP and
awards, and the spell/skill-check forms of the printed action.

## Classification

- **Confirmed defects.** None. This note plans a feature and found no executable defect; the
  one claim corrected in `17abb5b` stays corrected.
- **Deferred features.** Unchanged: concealment, `hold person` and coup de grace, disarm and
  sunder, further grapple (8b-2/8c/8d/8f), overrun, readied and delayed actions, movement
  continuation, levels 5 and above, two-weapon fighting and full attacks, encumbrance, AoE
  templates, terrain hard cover, disease, party item handoff, the save shortcut. Aid Another
  leaves this list only when its batch ships.
- **Maintenance debt.** Unchanged from the audit: OVERRUN_PLAN's `encounters.json` "lines
  2-56" against the actual 2-59 block, the 154-vs-160 grapple-probe count, plan-file line
  references, singular `modal`, probe-heavy `main.gd`, shallow UI suite, source-text guards,
  empty migration table, placeholder renderer. This note adds one more line-reference set that
  will drift by design.
- **Evidence gaps.** Carried forward, plus: no playtest showing the action is chosen in real
  play; no measured control count for the added button until batch 1 is implemented; monster
  parity for the action untested and out of scope. None of these is a reason to start a batch.

## Implementation record (2026-11-24)

Implemented in `81a76e0` as the single acceptance unit this note requires, so both bonus kinds
shipped together. The failing-first tests were written against
`Encounter.aid_active` / `resolve_aid_friend` / `resolve_aid_choice` before the action existed:
the captured red run had 15 tests, 12 failing and 18/34 asserts, all assertion failures rather
than parse, import or fixture errors. Green: 15/15 focused with 64 asserts, suite 1047/1047
with 10,294 asserts across 81 scripts, both validators PASS, probes at their accepted counts
(keyboard 31, grapple 160, level-up 349, advancement PASS, combat-info 62, flanking 8,
sneak-range 9) plus the new `--aid-another-probe` at 17 checks, and combat layout at **33
controls, 0 failures** at 1280x720 at 100 % and 160 %, matching the expected count.

Candidate `2026-11-24_aid_another` (source `81a76e0`, `BUILD.txt` matched, exe sha256
`90afb671831586c717f32106888c63e3f0da5f37e937e718c156708e524b40ca`, 110,934,728 bytes) was
accepted from the executable with the hash identical before and after. Acceptance records are
in `PROGRAM_PROGRESS.md`.

Limits, kept explicit: automated rules behavior only - no playtest shows the action is chosen,
and there was no balance testing, playthrough, rendered review or human playtest. Monsters
never aid, so monster parity is unmeasured; no charge action exists in this build; the
fine-grained +2 also reached trip and grapple touch attacks and ranged touch spells, as
recorded above, but nothing in the shipped content forces those routes.
