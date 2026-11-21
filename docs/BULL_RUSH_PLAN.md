# Player-initiated bull rush — implementation plan

**Status: plan only.** Nothing in this document is implemented. It is the bounded
scope proposed by the 2026-11-21 roadmap review, written so the batch can be
started, reviewed or rejected without another exploration pass.

Scope: player-initiated bull rush against a single defender, as a standard action.
No charge integration, no AI use, no mounts, no multi-creature pushes.

## 1. Printed rules, verified

Sources: 3.5 System Reference Document, Combat → Special Attacks → Bull Rush
(d20srd.org, which reproduces the PHB text), PHB p. 154 for the special attack, and the PHB feat description
for Improved Bull Rush. Both page numbers should be confirmed against the printed
index when the batch opens, as the repo does for its other page citations. Pathfinder pages were not used. The quoted fragments
below are the SRD's own wording.

| Element | Printed rule | Consequence for this engine |
| --- | --- | --- |
| Action type | "You can make a bull rush as a standard action (an attack) or as part of a charge." | Standard action only. Charge is not implemented, so the charge clause is out of scope. The standard action is spent on declaration, like trip. |
| Size limit | "You can only bull rush an opponent who is one size category larger than you, the same size, or smaller." | Compare `Rules.size_category_steps`; refuse when the defender is two or more steps larger. Trip happens to carry a guard of the same shape, but this gate is justified by the printed sentence above, not inherited from trip, and the refusal text names the bull-rush limit. |
| Provoked attack | "First, you move into the defender's space. Doing this provokes an attack of opportunity from each opponent that threatens you, including the defender." | The defender's reaction resolves before the opposed check, through the existing opportunity machinery. Improved Bull Rush would remove the defender's reaction, but the feat is deferred, so it always applies today. |
| Redirect clause | "Any attack of opportunity made by anyone other than the defender against you during a bull rush has a 25% chance of accidentally targeting the defender instead…" | **Excluded** (see §6). No redirect roll is made for third-party reactions; they resolve against the rusher normally. |
| Opposed check | "you and the defender make opposed Strength checks. You each add a +4 bonus for each size category you are larger than Medium or a -4 penalty for each size category you are smaller than Medium. … The defender gets a +4 bonus if he has more than two legs or is otherwise exceptionally stable." | `Rules.opposed_ability_check` with Strength on both sides, size bonuses as trip computes them, plus a defender stability bonus from an optional authored flag. The +2 charge bonus does not apply (no charge). |
| Push distance | "you push him back 5 feet. If you wish to move with the defender, you can push him back an additional 5 feet for each 5 points by which your check result is greater than the defender's check result. You can't, however, exceed your normal movement limit." | 5 ft always on success; extra 5 ft per full 5 points of excess, each step capped by the rusher's remaining movement and by legal squares. |
| Movement reactions | "The defender provokes attacks of opportunity if he is moved. So do you, if you move with him. The two of you do not provoke attacks of opportunity from each other, however." | The pushed defender and the following rusher provoke from other threatened enemies; the defender and the rusher never provoke from each other during this movement. |
| Failure | "If you fail to beat the defender's Strength check result, you move 5 feet straight back to where you were before you moved into his space. If that space is occupied, you fall prone in that space." | On a lost check the rusher ends in his starting square (net no displacement) and falls prone there if that square is occupied. The standard action is spent either way. |
| Exceeding | "You can't … exceed your normal movement limit." | The entry step and every follow step draw on the same `moved_ft` budget as ordinary movement. |

### What the printed text does **not** say

The SRD says nothing about a wall, an occupied square or difficult terrain
stopping the push. Those cases are **adaptations**, not printed rules, and must be
recorded in `ADAPTATION_LOG.md` when the batch lands:

- **Blocked push.** Movement rules forbid entering a blocked or occupied square,
  so a push stops in the last legal square, and the rusher follows only as far as
  he can legally stand. The log names the obstacle. Evidence keeps this separate
  from the printed push distance.
- **No room behind the defender.** If the square directly behind the defender is
  blocked or occupied, the first 5-ft push is impossible and the attempt is refused
  before any reaction or roll, because the engine cannot model two creatures in
  one square. Printed bull rush has no such refusal; this is an engine limitation
  and must be described as one.
- **Entry costs movement.** "You move into the defender's space" is movement, so an
  adjacent rusher needs at least 5 ft of budget left. A character who has spent the
  full move cannot bull rush. This reading is an adaptation decision, recorded once.
- **No transient overlap.** The engine does not place the rusher in the defender's
  square while the check is unresolved; on success he is committed to that square,
  on failure he never leaves his own. The log still narrates the entry, and the
  defender's reaction happens first, so the observable order matches the printed
  one.
- **Diagonal pushes.** Grid adjacency includes diagonals, so "straight back" is the
  axis from the rusher through the defender, diagonal included. Recorded as a grid
  adaptation.

## 2. Engine surface

| Layer | Addition |
| --- | --- |
| `Encounter` | `bull_rush_active(target_index: int, opts: Dictionary = {}) -> Dictionary` and `resolve_bull_rush_decision(follow: bool) -> Dictionary`. |
| `Encounter` state | `var pending_bull_rush: Dictionary = {}`; `has_pending_decision()` includes it; `begin()` and `finish()` clear it with `pending_trip`/`pending_cleave`; `pending_decision` naming follows the existing `"type"` convention. |
| `Game` | `combat_bull_rush(target_index)` and `combat_resolve_bull_rush(follow)`, shaped like `combat_trip`/`combat_resolve_trip`, including `last_ui_message` and `state_changed`. |
| UI (`combat_screen.gd`) | One `Bull rush` action button beside `Trip`, gated like the other standard actions, plus a `mode == "bull_rush"` target-selection branch that calls the wrapper. Two-word label; if it wraps, the sidebar's reserved scrollbar already prevents the oscillation the `Total defense` label caused. |
| Content | Optional monster flag `stable: true` (default false) for the defender's +4. No shipped monster sets it; the validator accepts the key as a boolean. No `content_version` change. |

No new save fields: the action is resolved inside a turn, and a pending decision
cannot outlive the turn (voided on turn change, like trip).

## 3. Pending-decision flow

Declaration resolves in this order, and every refusal happens before anything is
spent or rolled:

1. Refuse if no active combatant, a pending decision exists, the character cannot
   act or is paralyzed, the standard action is spent, or staggered rules block a
   standard action — the same guard block trip uses, with the same messages.
2. Refuse an invalid index, a dead or allied target, a target beyond melee reach,
   a target two or more size steps larger, or no legal square behind the defender.
3. Spend the standard action immediately (declared before any reaction, so an
   interrupted rush still costs the action, as trip does).
4. Log the entry, then provoke the defender's opportunity attack if it can act and
   no Improved Bull Rush applies. If that reaction ends the encounter or drops the
   rusher, the rush ends there with no push and no movement spent beyond the entry.
5. Roll the opposed Strength check and log both totals.
6. **Lose:** log the step back, set prone if the starting square is occupied, run
   `_after_action` and `_check_end`, emit `changed`, return.
7. **Win:** compute `excess = attacker_total - defender_total`; the defender is
   pushed 5 ft plus 5 ft per full 5 points of excess. Follow squares are limited by
   the rusher's remaining budget and by legal cells.
   - If at least one extra step is possible and the rusher has budget for it, set
     `pending_bull_rush = {"type": "follow", "actor_index", "target_index",
     "direction", "push_ft", "follow_limit_ft"}` and return with
     `"pending": "follow"`, leaving both positions uncommitted.
   - Otherwise commit the single 5-ft push and finish the action.
8. `resolve_bull_rush_decision(follow)` commits the push. `follow = false` pushes
   5 ft and leaves the rusher in the vacated square. `follow = true` pushes as far
   as the cap allows, moving the rusher step by step behind the defender. Guards:
   no pending decision, wrong type, the actor is no longer active, the actor cannot
   act, or either cell no longer matches the recorded state — each voids the
   decision with a logged line and no partial movement.

The decision is deliberately binary. The printed rule lets the rusher choose
whether to follow at all; pushing "some of the way" is equivalent to following
until the budget or the board stops him, so a second per-step prompt would add
clicks without adding a rule.

## 4. Shared movement and occupancy checks

Extract these small helpers in `Encounter` rather than duplicating the existing
`occupied_except` logic in a third place:

- `_push_direction(from: Vector2i, to: Vector2i) -> Vector2i` — the axis step from
  the rusher through the defender, or `Vector2i.ZERO` when the cells coincide.
- `_push_step(origin: Vector2i, direction: Vector2i, occupied: Dictionary) -> Vector2i`
  — the next legal cell, or `Vector2i(-1, -1)` when the step leaves the map,
  hits a blocked cell (`map.is_blocked`) or lands on an occupied one.
- `_push_chain(origin: Vector2i, direction: Vector2i, max_steps: int, occupied: Dictionary)
  -> Dictionary` — `{"cells": [...], "stopped_by": "wall"|"occupied"|"edge"|"budget"|""}`,
  used for the defender's push, the rusher's follow and the failure step-back.
- `_occupancy_for(index: int) -> Dictionary` — thin wrapper over
  `occupied_except`, so every push site names its excluded combatant.
- `_advance_cell(entry: Dictionary, cell: Vector2i)` — sets the cell and adds
  `BattleMap.CELL_FT` to `turn_state["moved_ft"]`; one accounting site.
- `_provoke_attacks_of_opportunity(mover_index: int, from_cell: Vector2i, except_index := -1)`
  — an optional exclusion so the defender is not provoked by the rusher and vice
  versa during this movement. Existing call sites keep the default.

Order of updates on a committed push: defender's cell, then the rusher's cell, then
`moved_ft`, then the provoke pass from the defender's old cell and the rusher's old
cell (each excluding the other), then `_after_action`, `_check_end`, `changed`.
Reactions resolve against the final cells, which is the printed order for a
single-round move.

## 5. Log wording

Matched to trip and the opportunity lines already in the log:

```
Kaelen lowers a shoulder and bull rushes Zombie.
  Kaelen moves into Zombie's space.
  Attack of opportunity by Zombie!
  Bull rush: Kaelen Str d20(14)+3 = 17 vs Zombie Str d20(6)+1 = 7
  Zombie is pushed back 15 feet.
  Kaelen follows, ending 5 feet behind Zombie.
  Zombie's movement provokes from nothing that threatens it.
```

Refusals and edge lines:

```
Zombie is too large to bull rush; you can oppose a creature at most one size category larger.
There is no space behind Zombie to push into.
The bull rush fails; Kaelen staggers back 5 feet.
Kaelen's square is occupied, so Kaelen falls prone.
Zombie is stopped by the wall after 5 feet.
Zombie is stopped by an occupied square after 5 feet.
Kaelen has only 5 feet of movement left; the extra push is lost.
Kaelen can no longer act; the Bull rush decision is void.
```

Rules citations in comments follow the repo convention: PHB p. 154 for the action
and the push, the PHB feat entry for Improved Bull Rush, and the adaptation log for
every line the SRD does not contain.

## 6. Exclusions

- Charge-integrated bull rush (charge is not implemented).
- Improved Bull Rush (+4 and no reaction) — stays deferred in
  `FEATS_SKILLS_COVERAGE.md` behind this action.
- The 25 % redirect for third-party reactions.
- Pushing more than one creature, or a creature occupying more than one square.
- Mounted bull rush, mounted defenders, and forced movement of a rider.
- AI-initiated bull rush; the defender never chooses to avoid or resist beyond the
  opposed check.
- Difficult terrain, since no campaign authors terrain tags.
- Repositioning through an ally's square by pushing that ally.
- Bull rush as a readied action, an opportunity attack, or part of a full attack.

## 7. Deterministic automated tests (`tests/test_bull_rush.gd`)

Harness: `test_trip.gd`'s pattern — a `ContentDB` character and monster, a walled
map built with `BattleMap.from_rows`, `Encounter.new()` with `setup(...)`, a
`RandomNumberGenerator` with a fixed seed, and `_force_turn`. Each test asserts on
cells, `turn_state`, `pending_bull_rush`, and the log text.

Determinism: a helper `_seed_for(check: Callable) -> int` searches seeds 1–200 on a
fresh encounter until the requested outcome occurs, and the test then pins the
found value as a constant, so an RNG or modifier change fails loudly instead of
silently changing the fixture. Push geometry is tested without relying on seeds by
calling the extracted `_push_chain` directly.

| # | Test | Asserts |
| --- | --- | --- |
| 1 | `test_a_won_check_pushes_five_feet_and_takes_the_square` | defender −5 ft on the axis, rusher in the vacated cell, `standard_used`, `moved_ft` +5, log lines |
| 2 | `test_extra_push_is_five_feet_per_five_points` | 20-point excess in a corridor yields 25 ft; rusher behind; `moved_ft` = entry + follow |
| 3 | `test_the_follow_is_capped_by_remaining_movement` | 10 ft of budget left → 5 ft entry + 5 ft follow; defender's excess push lost; budget message |
| 4 | `test_a_wall_stops_the_push` | defender adjacent to the wall, `stopped_by == "wall"`, wall log line, rusher in the last legal cell |
| 5 | `test_an_occupied_square_stops_the_push` | third combatant behind the defender stops it, `stopped_by == "occupied"` |
| 6 | `test_no_space_behind_the_defender_is_refused_before_the_roll` | refusal message, standard not spent, no dice consumed, no reaction |
| 7 | `test_a_spent_standard_action_is_refused` / `test_no_movement_left_is_refused` | the two guards, with the other turn-state fields untouched |
| 8 | `test_a_defender_two_size_categories_larger_is_refused` | fixture size, refusal text, nothing spent |
| 9 | `test_size_modifiers_are_four_per_category_from_medium` | fixture Small attacker vs Medium defender; the logged totals differ by 4 |
| 10 | `test_a_stable_defender_adds_four` | `stable: true` fixture; logged defender total is 4 higher than the same seed without it |
| 11 | `test_the_defender_makes_an_opportunity_attack_on_entry` | reaction logged, `aoo_used` set, damage applied before the check |
| 12 | `test_an_opportunity_attack_that_drops_the_rusher_ends_the_rush` | no push, no follow pending, standard spent, encounter state consistent |
| 13 | `test_a_lost_check_costs_the_action_and_leaves_the_rusher_where_he_stood` | cells unchanged, standard spent, failure log |
| 14 | `test_a_lost_check_falls_prone_when_the_starting_square_is_occupied` | fixture occupant at the origin → prone, log line |
| 15 | `test_declining_the_follow_pushes_only_five_feet` | decision cleared, defender 5 ft, rusher in the vacated cell |
| 16 | `test_the_follow_decision_voids_when_the_turn_changes` | tampered `turn_ptr` → void message, no movement, decision cleared |
| 17 | `test_a_bull_rush_does_not_commit_fighting_defensively_or_combat_expertise` | cross-batch guard: a selected stance and a pending CE declaration both expire through `_after_action` without activating |
| 18 | `test_a_pending_cleave_blocks_a_bull_rush` | `has_pending_decision()` guard message |

Also in scope for the batch's verification: the full suite and both validators, run
in the source tree exactly as the previous two batches did.

## 8. Does the exported resolution smoke belong here?

**No.** Bull rush touches neither encounter resolution nor the autosave; it ends
inside a turn, writes no pending state and adds no save field. The only exported
risk this batch creates is layout, because it adds a control to the sidebar's
action grid — and that is covered by the existing combat layout scenario. The
batch therefore includes:

- `--layout-probe --layout-scenario=combat` at 100 % and 160 % in the source tree;
- an exported candidate built from the clean batch commit, with both validators run
  from the exe, the same layout scenario at both scales, and the executable's
  SHA-256 recorded before and after the runs and required to match.

It does **not** include an exported encounter-resolution smoke. That smoke is the
evidence-gap item ranked second by the roadmap review; it would prove save cleanup
in the binary, not bull rush, and it should be its own small batch before a second
rules change that depends on resolution-time behaviour.

Limits stated with those results: the probe shows layout and control state, not
rules outcomes; the rules are covered by the suite in the source tree only.

## 9. Classification, kept separate

- **Confirmed defects:** none. This plan found no reproduced, reachable failure in
  the existing code. The stance leak was the last one and is closed.
- **Deferred features:** Improved Bull Rush; the charge-integrated bull rush; the
  25 % redirect; multi-square creatures; mounted bull rush; AI use; difficult
  terrain; overrun, grapple, disarm and sunder after this batch; concealment and
  the remaining cover gaps; iterative attacks; AoE templates.
- **Maintenance debt this batch must not add:** a third copy of the occupancy check
  (hence §4's extraction), a second movement-accounting site (hence `_advance_cell`),
  and another bespoke pending-decision dictionary if the typed decision record from
  P0.5 item 1 lands first — if it does, `pending_bull_rush` should use it instead of
  a new dictionary.
- **Evidence gaps this batch will leave:** the exported binary's rules behaviour is
  still unproven (probe covers layout only); the encounter-resolution smoke remains
  open; no human playtest is planned or requested; the printed blocked-square
  adaptations rest on movement rules and a documented decision, not on SRD text.

## 10. Definition of done

Focused `tests/test_bull_rush.gd` green, full suite green, both validators PASS,
`SUPPORTED_FEATURES.md` and `TRACEABILITY.md` rows added, `ADAPTATION_LOG.md`
entries for the five adaptations in §1, `FEATS_SKILLS_COVERAGE.md` note that
Improved Bull Rush is now unblocked but still deferred, the combat layout scenario
at both scales, one exported candidate with a bound before/after hash, and the
candidate ledger updated. No manual testing, no backup changes.
