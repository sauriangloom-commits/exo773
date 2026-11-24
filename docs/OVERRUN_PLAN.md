# Overrun plan

Status: **deferred after scope review; planning only**. This note specifies the
3.5 overrun special attack for `Ravenloft`, but does not implement it. **No
overrun tests, probes, validators, builds or exports were run or produced for
this review**; no overrun code, content, schema or save data changed, and no
overrun candidate was exported. It supersedes the first planning pass at
`75be1a6`; §18 records the 2026-11-24 scope decision that supersedes the earlier
implementation-batch recommendation.

**Prerequisite status (2026-11-24).** The shared opportunity-attack defect
described in §7 was investigated and corrected separately in commit
`d14b7fcb1c08fdafce9f42f6ad0611a1d56635ea`; candidate
`2026-11-24_aoo_helpless_b` is hash-bound to that correction. The separate
into-melee engagement defect was corrected in `4c42965`; its record is
`8571232`. Neither correction is an overrun defect or an authorization to
implement overrun.

**Ranged-probe closure (2026-11-24).** The 720px failures recorded in `247fad3`
for implementation `1a2a2393e461328f0bf747d8414a2c83b5246f2a` and candidate
`2026-11-24_ranged_720_probe_a` are closed within that evidence as a **probe
navigation defect**, not a product targeting defect. The old control clicked an
offscreen enemy-row button; the visible grid path worked. This closure did not
rebuild, re-export or repeat any check, and it does not authorize overrun.

**Threat/engagement review (2026-11-24).** `_threatening_enemies` remains only a
provocation-candidate list; its paralyzed entry is message-only and does not feed
flanking or engagement. The separate into-melee engagement defect is corrected
in `4c42965`, so it is no longer a pending prerequisite. No overrun work follows
from that correction.

**Scope decision (2026-11-24).** Overrun is **deferred**. The fixed-exit stop is
not accepted as satisfying the printed success/avoid continuation merely because
this plan called it an adaptation. See §18 for the explicit comparison of a
bounded continuation, a general movement-continuation prerequisite, and
deferral.

Related documents: `docs/ROADMAP.md` candidate B, `docs/PROGRAM_PROGRESS.md`,
`docs/ADAPTATION_LOG.md`, `docs/FEATS_SKILLS_COVERAGE.md`,
`docs/SUPPORTED_FEATURES.md` and `docs/TRACEABILITY.md`.

## 1. Scope

The following was the proposed bounded scope. It is not an authorized
implementation after the 2026-11-24 scope review; see §18.

- an adjacent enemy is the target; the exit square is fixed directly beyond it;
- the attacker pays 10 ft of movement for the passage and knocks the defender
  prone on a win, retreats 5 ft on a loss, or passes without effect when the
  defender avoids;
- a standard action is required at declaration and is spent only if the defender
  blocks;
- the printed entry reaction, size limits, opposed checks, counter-check, prone
  results and one-attempt-per-round limit are modeled;
- the existing action, movement, pending-decision, AI and opportunity-attack
  machinery is reused, not refactored.

Out of scope and not to be added while resolving this note: approach movement as
part of the overrun, player-selected destination squares, Improved Overrun,
charge/mounted/Trample interactions, AI initiation of overrun, player-defender
avoid/block decisions, a general movement-budget refactor, a new pending
decision type, or the printed success/avoid continuation.

## 2. Printed rules and sources

Sources: the 3.5 System Reference Document, Combat → Special Attacks → Overrun at
https://www.d20srd.org/srd/combat/specialAttacks.htm (which reproduces the PHB
text), the Improved Overrun feat at https://www.d20srd.org/srd/feats.htm, PHB
p. 157 for Overrun, PHB p. 96 for Improved Overrun, PHB p. 64 for the general
opposed-check tie rule, and PHB p. 151 for prone. The quoted fragments below are
the SRD's wording. Page numbers should be confirmed against the printed index
when the implementation batch opens, as the repo does for its other citations.

What the printed text establishes:

1. Overrun is a **standard action taken during your move**. You can attempt it
   once per round.
2. You may overrun a defender one size category larger than you, the same size,
   or smaller.
3. You begin by moving into the defender's space, which **provokes an attack of
   opportunity from the defender**.
4. The defender may **avoid** you. Avoiding has no ill effect, you keep moving,
   and the attempt **does not count against your actions** except for the
   movement required to enter the opponent's space.
5. If the defender does not avoid, make an opposed check: your **Strength** vs.
   the defender's better of **Dexterity or Strength**. Apply **+4 per size
   category** by which one creature is larger, measured from Medium, and the
   defender gets **+4 if it has more than two legs or is otherwise exceptionally
   stable**.
6. Win: the defender is knocked **prone**, and you **continue your movement as
   normal**.
7. Lose: the defender may immediately make a **counter-check** to knock **you**
   prone. The counter is the defender's **Strength** vs. your better of
   **Dexterity or Strength**, with **size modifiers only**. If you are knocked
   prone, your movement **ends there**; if the square is occupied, you are prone
   in the last legal square.
8. Improved Overrun removes the defender's option to avoid and grants **+4** on
   the overrun check. It does **not** remove the attack of opportunity. It is
   deferred here, not a dependency.

The SRD does not state a 10-ft price, a fixed exit square, a diagonal-cost rule,
a rule for helpless defenders, a rule for an interrupted entry, or a rule for
what happens to unused actions after avoidance. Those are project decisions below.

## 3. Resolved contract

| Question | Decision | Kind |
|---|---|---|
| Declaration | Adjacent enemy only; the exit is the square directly beyond the defender; one target click; no destination picker. | Project |
| Standard action | Must be **available at declaration**. It is spent only when the defender blocks. An actor whose standard is already spent is refused before the reaction. | Printed action + project timing |
| 10-ft price | A **precondition**: at least 10 ft of the current movement budget must remain. The **charge is outcome-dependent and atomic**: 0 if an opportunity attack stops the attempt before the passage; 10 when the attempt reaches avoid, no resistance, a win or a loss. It is **not** deducted at declaration and no 5-ft entry is charged separately. | Project |
| Entry | The grid never contains the attacker in the defender's square. On a resolved passage the attacker is written to the exit (avoid/win/no resistance) or back to the origin (loss/retreat), and the 10 ft is charged at that commit. | Project |
| Avoidance | Printed result: the defender avoids and the mover keeps moving. Not implemented; the fixed-exit stop is **not accepted** as satisfying this row. The untouched standard may be used later, but that is not the printed continuation. Feature deferred (§3.5, §18). | Printed result; project accounting withdrawn |
| Win | Printed result: defender prone and the mover continues movement as normal. Not implemented; the fixed-exit stop is **not accepted** as satisfying this row. Feature deferred (§3.5, §18). | Printed result; project accounting withdrawn |
| Loss | Attacker at the origin, 10 ft charged, standard spent, attempt consumed; attacker prone only if the counter wins. Movement **ends**, whether the attacker is standing or prone. No unused move action remains to convert. | Printed "ending your movement there" + project reading |
| Interruption | If an opportunity attack kills, drops, paralyzes or otherwise prevents the attacker from proceeding, the attacker stays at the origin, **0 ft** is charged, the standard is **unspent**, the attempt is **consumed**, and `move_used` is unchanged. Nothing is charged for an entry or exit that did not occur. | Project |
| Attempt limit | One declared attempt per combatant per round. Avoidance, no resistance and interruption all consume it. The SRD's "doesn't count against your actions" concerns the standard action, not this limit. | Printed limit + project interpretation |
| Ties | Printed rule: on tied totals the higher **raw ability modifier** wins (attacker Strength vs. the defender's better Strength/Dexterity); size and stability are added to the totals but do not decide the tie; equal modifiers reroll. The current helper compares ability modifier plus `opts` bonuses, so this plan's old size-inclusive tie reading is not accepted. A future implementation needs separate raw tie modifiers or an overrun-local check; changing the shared helper would affect trip, bull rush and grapple and is not authorized. | Printed rule; helper contract unresolved |
| Counter modifiers | Defender's Strength + 4 per size step vs. attacker's better of Strength/Dexterity + 4 per size step. **Size only**; no stability, no Improved Overrun +4, no other modifier. | Printed |
| Diagonal | Entry and exit each cost 5 ft under this project's grid, so the passage is 10 ft whether diagonal or orthogonal. The entry and exit each get the existing `_blocked_diagonal` terrain corner check; occupancy corners are not part of that helper. The tabletop 1-2-1 diagonal rule is not used. | Project grid rule |
| Opportunity attacks | The helper's **eligibility** filters are settled: can act, not helpless, not in total defense, melee threat, in reach of the supplied cell, `aoo_used` unused and not flat-footed. **Participant selection is not settled.** A single pass from the origin is a project choice, not a printed or tested contract; the defender's entry reaction and exit/intermediate threats need a separate geometry decision. Helper eligibility does not validate that geometry. | Printed defender + open project question |
| Acceptance | **No implementation batch is authorized.** The earlier two-commit acceptance unit is withdrawn. Any future unit must first settle continuation, tie semantics and participant geometry, then define its own tests, UI, probe and candidate boundary. | Deferred |

### 3.1 The 10-ft reservation, precisely

The 10 ft is **not** an immediate expenditure. At declaration the engine checks
`speed_ft - moved_ft >= 10`; that is the reservation. It then resolves the entry
reaction before writing any cell or movement. If the attempt reaches the
defender-resolution stage (avoid, no resistance or block), the passage commit adds
10 ft exactly once:

- avoid, no resistance, win: `moved_ft += 10`, attacker at the exit;
- loss: `moved_ft += 10`, attacker at the origin (entry + retreat);
- interruption: `moved_ft` unchanged, attacker at the origin (neither entry nor
  exit/retreat occurred in the grid).

No transient 5-ft entry is charged. This is a project abstraction: the grid cannot
represent the attacker sharing the defender's square, so the entry and the
exit/retreat are committed together when the outcome is known. The log narrates
the entry, but the movement account records only the committed passage.

The check is feature-local. `Encounter.move_active_to` does not enforce a
cumulative `speed - moved_ft` budget; it charges a path against one move action.
The 10-ft guard itself can stay local, but the printed success/avoid continuation
cannot: it needs a separate movement transition or a general prerequisite (§3.5,
§18). The old claim that overrun does not depend on movement work is withdrawn.

### 3.2 Movement and action state after each outcome

| Outcome | `move_used` | `moved_ft` | `standard_used` | `overrun_used` | Further movement? |
|---|---|---|---|---|---|
| Refused before declaration | unchanged | unchanged | unchanged | unchanged | Yes, normal actions. |
| Interrupted by AoO/incapacity | unchanged | +0 | false (unspent) | true | Only if the actor can still act; the untouched move action remains, as in the Cleave-pending case. |
| Avoid | true | +10 | false | true | Printed continuation is not implemented; the fixed-exit stop is not accepted. Feature deferred (§3.5, §18). |
| No resistance (helpless defender) | true | +10 | false | true | Same as avoid. |
| Win | true | +10 | true | true | Printed continuation is not implemented; the fixed-exit stop is not accepted. Feature deferred (§3.5, §18). |
| Loss, standing | true | +10 | true | true | No. Movement ends; no unused move action; no double move. |
| Loss, counter knocks prone | true | +10 | true | true | No. Movement ends; standing up needs a move action and cannot happen this turn. |

The success and avoidance rows are historical proposals, not an accepted answer.
The printed result allows success and avoidance to continue moving; the project
does not implement that continuation and does not treat the fixed exit as
equivalent. The printed "ending your movement there" on a loss is read as ending
the overrun's movement **and consuming the move action used for it**; that reading
is not a substitute for the missing success/avoid continuation. See §3.5 and §18.

After an **interruption**, no movement is charged and `move_used` is unchanged.
The supported case where the actor can still act is the Cleave-pending stop: after
the existing decision is resolved, the character still has the actions they had
before the declaration. That is not conversion of residual overrun movement; the
overrun attempt is simply over and the untouched move action is still available.
If the reaction killed, dropped or paralyzed the actor, the existing condition
rules decide whether any action remains.

### 3.3 Standard action at declaration

An available standard action is required at declaration, even though avoidance and
no resistance leave it unspent. The printed action is a standard action, and the
block branch may need it; a character who has already spent their standard is
refused before the opportunity-attack pass. This is deliberately conservative:

- `standard_used == true` → refuse, no attempt consumed, no reaction;
- `standard_used == false` → declare; avoid/no resistance leave it false; block
  sets it true.

A character who has already used their standard cannot overrun even a helpless
defender, because the declaration is still a standard-action attempt. The UI
disables the button for the same reason.

### 3.4 Once-per-round and avoidance

`overrun_used` is set at declaration, before the reaction. It is consumed by every
declared attempt: avoid, no resistance, win, loss, and interruption. The SRD's
statement that avoidance does not count against your actions is recorded
separately: it means the standard action is not spent, not that the once-per-round
attempt is refunded. A second overrun in the same round is refused even after an
avoidance.

### 3.5 Success/avoid continuation: printed vs. project

The printed result is explicit: on a win you "continue your movement as normal,"
and on an avoidance you "may keep moving." In the tabletop rules the rest of the
current move (its budget minus the 10 ft) remains after the fixed exit. Failure is
different: the printed text ends movement there.

The project does not implement that continuation, and the fixed-exit stop is **not
accepted** as equivalent. `Encounter.move_active_to` is atomic: it computes a full
path against `speed_ft`, sets `move_used` or `standard_used` before the opportunity
pass, and charges the full cost at the end. `moved_ft` is accounting only; it is not
a remaining-movement budget. `move_used` gates ordinary movement, and there is no
resumable player-move state. `off_turn_resume` is a monster-move interruption
record; `resume_interrupted` ends the turn and is not a player continuation path.

If overrun were resumed, the consequences would be:

- win: the standard is spent, but the printed residual movement remains; stopping
  at the fixed exit is insufficient;
- avoid/no resistance: the standard is unspent and the printed movement remains;
  a double move is a new action, not residual movement from the overrun;
- failure: movement ends, as printed.

Supporting continuation needs either **A**, a bounded overrun-specific state and
transition, or **B**, a general movement-continuation prerequisite. Neither is
authorized. Overrun is deferred under **C**; §18 compares the options.

## 4. Shipped-content benefit and limits

The demo encounter `storeroom_dead` (`content/campaigns/ravenloft_demo/encounters.json`
lines 2–56) has three one-square lanes left by the rows `#.##.##.#`. A zombie in a
lane body-blocks it. A fixed exit can pass one blocker and knock it prone (−4
melee AC, PHB p. 151), but the shipped content sharply limits the payoff.

Kaelen has Strength 16 (+3) and no Improved Overrun
(`content/shared/characters.json`, feats at line 33); Sera has Strength 12 (+1).
The zombie has Strength 12 / Dexterity 8 (best +1), Medium, and no stability bonus
(`content/shared/monsters.json:3`). With a fixed 10-ft price and a 30-ft speed, the
passage is affordable from a standing start (10 ft) and after a 20-ft approach
(30 ft total). The infected zombie (Strength 17, best +3, line 76) and the ghoul
(Strength 13 / Dexterity 15, best +2, line 152) remain valid but harder.

Limits, not hidden:

- The prone defender still occupies its square; the lane is **not** opened and the
  rest of the party still cannot walk through it.
- The benefit is passing one blocker, not reaching a back-line objective or
  bypassing the encounter. Every shared monster is a melee undead with natural
  weapons, encounters are kill-all, and the AI never initiates special attacks, so
  there is no back line to reach.
- Every shared monster is undead and immune to sneak attack. The old claim that the
  flank sets up Sera's sneak attack is therefore not a damage payoff in shipped
  content; the flank is a positional effect only.
- The top-row blocker positions in both shipped fights (storeroom `(6,1)`/`(7,1)`,
  crypt `(3,1)`/`(6,1)`) have a wall directly beyond them. The fixed exit is not
  available from those positions. The crypt's three-square-wide rooms provide an
  exit only in other geometry; the open town square is not an overrun showcase.
- Shipped monsters always block; avoidance is fixture-only. The benefit is grounded
  in a real lane, but not in an assumed avoid policy.
- Harder defenders and counter-prone outcomes are real risks; the plan does not
  promise a guaranteed pass.

## 5. Repository seams

| Concern | Seam |
|---|---|
| Turn state | `src/core/encounter.gd:92-95` (`move_used`, `standard_used`, `five_foot_used`, `moved_ft`); `begin()` at `:138` |
| Occupancy | `occupied_except` at `:516`; only `dead` is excluded; prone and unconscious still occupy |
| Movement commit | `_advance_cell` at `:1935`; `move_active_to` at `:529`; `speed_ft` at `:615` |
| Action gates | `standard_used` / `move_used`; `_staggered_blocks_standard` at `:1312`; `_staggered_blocks_move` at `:1318` |
| Pending gate | `has_pending_decision` at `:2708`; `_pending_guard` at `:667` |
| Interrupted move/resume | `off_turn_resume` at `:69`; `resume_interrupted` at `:4299`; monster-move only, ends the turn; not a player overrun-continuation path |
| Opportunity attacks | `_provoke_attacks_of_opportunity` at `:3472` and `_provoke_single_opportunity` at `:3400`; `Rules.is_helpless` at `rules.gd:219`; `threat_capability` at `:728`; `aoo_used`; `is_flat_footed` at `:369`; total defense at `:3272`. Eligibility is settled; participant selection is separate and still open |
| Grapple/pin | `is_grappled` at `:387`; `is_pinned` at `:412`; `threat_capability` returns empty while grappling |
| Size/stability | `Character.size_category` at `:26`; `stability_bonus` at `:31`; `trip_immune` at `:32`; `Rules.size_category_steps` at `:56` |
| Opposed checks | `Rules.opposed_ability_check` at `:584`; tie handling at `:629-648`; `best_ability_modifier` at `:651`. The helper compares ability modifier plus `opts` bonuses; it has no separate raw tie modifier |
| Save boundary | `GameState.save_game` refuses non-explore at `game_state.gd:495`; combat/encounter state is not serialized; any new state must be cleared in `begin()`/`finish()` and needs no save migration |
| Prone | `Character.is_prone`/`set_prone` at `:109-117`; `Rules.prone_ac_modifier` at `:240`; stand up at `:1260`; trip at `:1328` |
| AI | `_run_monster_turn` at `:4226`; only `_after_action` ends a monster turn; no AI overrun initiation |
| Action grid | `src/ui/combat_screen.gd:283-284` Trip/Bull rush; `_update_button_states` at `:720`; `_on_cell_clicked` at `:832`; `_trip` at `:947`; `_bull_rush` at `:958` |
| Cursor/budget | `src/ui/combat_view.gd:193` budget highlight; `:250` cursor draw |
| Wrappers | `src/game_state.gd:1773` `combat_move`; `:1855` `combat_trip`; `:1877` `combat_bull_rush` |
| Probe/fixture | `src/main.gd:111` probe list; `:366` dispatch; `:432` layout; `:2505` `_probe_button`; `:2533` `_probe_click`; `:2548` `_probe_click_cell`; `:2560` `_layout_probe`; `:2895` `_probe_shot`; `:2936` `_probe_check`; `:5297` `_trip_probe`; `:8169` `_probe_advance_to`; `:8878` QA trip fixture |

`BattleMap` (`src/core/battle_map.gd`): `CELL_FT = 5` at `:11`, `is_blocked` at
`:44`, `distance_ft` at `:56`, `is_adjacent` at `:60`, `reachable` at `:213`,
`find_path` at `:238`, `_blocked_diagonal` at `:281`. Occupancy is layered on by
`occupied_except`; `is_blocked` is terrain only.

## 6. Declaration and validation

The engine method is `Encounter.overrun_active(target_index: int, opts := {}) ->
Dictionary`, called by `GameState.combat_overrun(target_index, opts)` and the UI.
`opts` is test-only (`defender_choice`, `counter`) and is not exposed to the
player.

Validation, in order; every refusal leaves `overrun_used`, `moved_ft`,
`move_used` and `standard_used` untouched:

1. Active entry exists; no `has_pending_decision()`; the character can act and is
   not paralyzed; not prone; not grappled or pinned; not staggered.
2. `standard_used` is false; `five_foot_used` is false.
3. `overrun_used` does not already contain the actor index.
4. The target index is valid, is an enemy, is not dead, is not grappled or pinned,
   and is adjacent (`map.is_adjacent`).
5. Entry is a legal one-step move:
   `map.find_path(actor_cell, target_cell, occupied_except(actor)).size() == 1`.
   `find_path` permits the occupied target as its goal; the check rejects a
   diagonal entry whose two orthogonal **terrain** corners are both blocked.
   `_blocked_diagonal` does not inspect occupancy, matching `move_active_to`; the
   same helper supplies the exit corner check.
6. Size: `def_steps <= atk_steps + 1`; otherwise refuse "too large".
7. Direction is the sign step from actor to target; it is never zero because the
   cells differ.
8. Exit is `target_cell + direction`; it must be inside the map, free of terrain
   and occupants, and a legal step from the target:
   `map.reachable(target_cell, BattleMap.CELL_FT, occupied_except(actor)).has(exit)`.
   This is the engine's "no space beyond" refusal; the printed text has no such
   refusal, so it is an adaptation.
9. Budget: `speed_ft - moved_ft >= 10`; otherwise refuse with the exact remaining
   feet.

Record `start_cell = entry["cell"]`, `target_cell = target_entry["cell"]` and
`direction` before any write. After validation, set `overrun_used[actor_index] =
true` and log the declaration. **Do not** set `move_used`, **do not** change
`moved_ft` and **do not** move the token yet. The entry reaction resolves first.

Named refusals (messages should name the reason and the character):

- "You have already used your standard action."
- "You have already taken a 5-foot step this turn."
- "You have already attempted an overrun this round."
- "Resolve the pending combat decision first."
- "You cannot overrun while prone/grappled/pinned/staggered."
- "<target> is too large to overrun."
- "There is no space beyond <target>."
- "You cannot overrun an ally."
- "<target> is already in a grapple." / "<target> is pinned."
- "<target> is already dead."
- "You need 10 ft of movement; only N ft remain."
- "<target> is not adjacent."

## 7. Defender states and the AI choice

The printed text gives the defender a choice to avoid. The project does not add a
player-facing defender decision; the AI policy is "block" for every conscious,
able defender. The resolver accepts a test-only `defender_choice` to force
"avoid" in tests; shipped AI never passes it.

Supported defender states:

| State | Can choose? | Can make an AoO? | Can block/counter? | Handling |
|---|---|---|---|---|
| Conscious, able, melee threat | yes | yes | yes | Normal; AI blocks. |
| Conscious, able, no melee threat | yes | no | yes | Normal; no AoO; can block/counter. |
| Flat-footed | yes | no | yes | Normal; the existing helper skips the AoO; it can still block. |
| Total defense | yes | no | yes | Normal; the existing helper skips the AoO; it can still block. |
| Already used its AoO this round | yes | no | yes | Normal; can still block. |
| Prone but conscious | yes | yes | yes | Normal; prone attack penalties apply; a win does not add a second prone. |
| Staggered | yes | yes | yes | Normal; an AoO and a block are reactions, not actions. |
| Paralyzed, unconscious, dying or otherwise helpless | no | no | no | **No resistance**: automatic passage, no new prone, 10 ft, standard unspent; excluded from its own AoO. |
| Dead | no | no | no | Invalid target; refused at declaration. |
| Grappled or pinned | no | no | no | Refused; grapple-target overrun is deferred. |
| Ally | no | no | no | Refused. |

Distinctions the implementation must keep:

- **Inability to choose** (helpless, dead) is not the same as **choosing to
  avoid**. Helpless handling is a project adaptation: no check, no prone, no
  standard, 10 ft. A voluntary avoid is the printed result and also leaves the
  standard unspent.
- **Inability to make an opportunity attack** (no melee threat, flat-footed, total
  defense, already used the reaction) does not prevent blocking or countering.
- **Inability to block or counter** is limited to helpless/dead/grappled/pinned
  states in this design. A conscious prone, staggered, flat-footed or
  total-defense defender can still make the Strength check.

`trip_immune` is a trip property and is not consulted; overrun is not trip, and
no shipped monster sets the flag.

Already-prone defenders are eligible: they can avoid, block and counter; a win
leaves them prone (no change), and a counter can knock the attacker prone. An
unconscious defender is eligible for no resistance, not for a block; if it is
already prone, it stays prone. Grappled/pinned defenders and allies are named
refusals, not incidental helper outcomes.

**Prerequisite finding — confirmed and corrected (2026-11-24).** The reported
shared defect was reproduced. `_provoke_attacks_of_opportunity` checked
`can_act()`, but `Character.can_act()` is true for a paralyzed character and has
no helplessness filter; `_provoke_single_opportunity` checked neither. Both shared
helpers therefore allowed a helpless/paralyzed creature to roll the reaction and
consume `aoo_used`. `Character.can_act()` was **not** changed globally. Both
helpers now refuse `Rules.is_helpless(attacker)` before `aoo_used` or attack
resolution and log the refusal; the single-opportunity helper also refuses a
creature that cannot act. The defender-only fallback is no longer needed.

```gdscript
if Rules.is_helpless(attacker):
    _log("  %s is helpless and cannot make an opportunity attack." % attacker.display_name)
    return {}
```

Regression tests (`tests/test_opportunity_attack_eligibility.gd`) and the
extended `--grapple-probe` cover movement, loading and a real stand-up
provocation, with conscious positive controls. This satisfies the eligibility
prerequisite; it is a shared AoO correction, not an overrun feature, and it does
not decide §3.5 continuation or §3 ties. The printed continuation does require
additional movement work; the earlier claim that the design did not depend on a
movement refactor is withdrawn (§3.5, §18).

## 8. Resolution sequence

1. **Declare.** Validate; set `overrun_used[actor] = true`; log. No movement,
   cell, `move_used` or `moved_ft` change.
2. **Entry reaction.** Call
   `_provoke_attacks_of_opportunity(actor_index, start_cell, -1)`.
   The helper now excludes a helpless participant itself, so `except_index` must
   not be used to express helplessness; it is only for a specific mutual
   non-provocation rule. Participant selection is separate from eligibility and
   remains under review (§9). The historical one-pass-from-origin is not an
   accepted trigger geometry.
3. **Interruption check.** After the pass:
   - `finished` → stop; no charge; attempt consumed; no exit.
   - `has_pending_decision()` (a Cleave opened by an AoO) → stop; no charge;
     standard unspent; attempt consumed; the existing decision UI resolves; no
     overrun resume state. This is a bounded limitation, not a new decision type.
     If the same AoO also dropped the actor, that condition is recorded at the
     origin; the pending decision still resolves through its own UI.
   - `not ch.can_act()` or `ch.has_condition("paralyzed")` or
     `is_grappled(actor_index)` or `is_pinned(actor_index)` → stop; no charge;
     standard unspent; attempt consumed; token at origin. Supported interruption
     states are death, dying, unconscious, paralysis, grapple/pin and the
     pending-Cleave stop. A generic "immobilized" condition does not exist;
     rooted/immobilized effects are deferred and must be added to this check
     explicitly when introduced.
   - Otherwise continue. A surviving, able actor reaches the choice even if the
     AoO damaged it.
4. **Defender choice.**
   - Helpless defender: no choice; automatic passage. Commit the exit:
     `_advance_cell(entry, exit, 10)`;
     set `move_used = true`; leave `standard_used` false; no prone; log
     "<target> cannot stop you."
   - Test-only `defender_choice == "avoid"`: commit the exit; `move_used = true`;
     standard false; no prone; log "<target> gives way."
   - Otherwise **block**: set `standard_used = true`; log
     "<target> braces."
5. **Overrun check (future; not authorized).** With `atk_steps`/`def_steps`
   from `Rules.size_category_steps`, the call shape must match the real helper:
   `Rules.opposed_ability_check(rng, actor, ["str"], target, ["str", "dex"],
   {"attacker_bonus": 4 * atk_steps,
    "defender_bonus": 4 * def_steps + target.stability_bonus,
    "label": "overrun"})`.
   The old total-only call in this plan was invalid. More importantly, the helper's
   tie branch compares the final `attacker_modifier`/`defender_modifier`, so size
   and stability would decide a tied total. The printed rule compares the higher
   raw ability modifier. A future implementation needs separate raw tie modifiers
   or an overrun-local check; changing the shared helper would affect trip, bull
   rush and grapple and is not authorized. Do not implement this call as-is.
   If `ok` is false, log a programming error, do not commit a passage, and consume
   the attempt. The standard remains spent because block was chosen; do not refund
   it. This is a guard for invalid data, not a table outcome.
6. **Win.** Commit the exit (`_advance_cell(entry, exit, 10)`; `move_used = true`);
   `target.set_prone(true)`; log; standard remains true.
7. **Loss.** The defender may counter (`opts.counter` defaults true; tests may
   disable it). If it counters:
   - counter attacker modifier = `Rules.ability_modifier(target, "str")`;
   - counter defender modifier = `Rules.best_ability_modifier(actor, ["str", "dex"])`;
   - counter attacker total = its Strength + `4 * def_steps`;
   - counter defender total = its best modifier + `4 * atk_steps`;
   - `Rules.opposed_ability_check(...)`; **no stability, no feat, no other
     modifier**. The helper's tie branch still folds the supplied bonuses into
     the tie comparison, so the same raw-modifier correction is required before
     this counter can be accepted.
   The counter is a reaction: it spends no standard, no move and no additional
   overrun attempt, and it does not set `aoo_used`. If the counter attacker wins,
   `actor.set_prone(true)`; if the counter helper returns `ok=false` after its
   reroll cap, treat it as no counter (the actor is not knocked prone) and log the
   guard; otherwise no prone.
   In all loss branches, commit the origin: `_advance_cell(entry, start_cell, 10)`;
   `move_used = true`; standard remains true. If the counter knocks the actor
   prone and the origin is occupied, the origin cannot be occupied in this model
   (the actor never left it and no living creature can share it), so no fallback
   square is needed; record the assumption.
8. **Cleanup.** Log the final cell, prone state and movement. `_after_action(ch)`;
   `_check_end()`; `changed.emit()`. The attempt remains consumed and cannot be
   repeated this round. An interruption returns without `_after_action`; a pending
   Cleave is resolved by its own UI; a dead/dying actor still runs `_check_end` so
   the encounter can end.

Ordering notes:

- The standard is marked spent when the defender chooses **block**, before the
  check; avoidance and no resistance never set it.
- The 10 ft is charged only by the final commit, never at declaration and never
  as a separate 5-ft entry.
- The target is not written to the exit until the outcome is known; the grid
  never overlaps.
- A helpless defender is excluded from its own AoO via `except_index`; it still
  occupies its square and is the target of the passage.

## 9. Opportunity attacks: eligibility vs. participant geometry

The shared **eligibility** fix is settled. `_provoke_attacks_of_opportunity` skips
a participant that cannot act, is helpless, is in total defense, has no melee
threat, is out of reach of the supplied cell, has used `aoo_used`, or is
flat-footed. That fix does not establish the overrun **participant set**.

Participant selection is still open. The helper takes one `from_cell` and one
`except_index`; it does not take a set of trigger cells or a traversed path. The
plan's single pass from the origin is a project choice, not a printed or tested
contract. The printed text names the defender's **entry** reaction; testing
eligibility against the origin is not the same trigger. Ordinary reactions from
other enemies are a project extension. A threat that covers only the entry,
intermediate or exit square is omitted by the origin pass. Whether that is correct
has not been decided.

For any future implementation, keep the two steps separate:

1. **Participant selection by geometry.** The defender's entry reaction; plus any
   other trigger cells the project explicitly decides should provoke (origin,
   entry, intermediate, exit, or per-step movement). This is a design decision,
   not a helper-eligibility detail.
2. **Eligibility for each selected participant.** Apply the shared filters above
   against the relevant trigger cell. Do not let the helper's single `from_cell`
   silently define the participant set. If a future design selects participants
   explicitly, the existing `_provoke_single_opportunity` is the per-participant
   seam; it still applies the shared eligibility rules.

`except_index` is for a specific mutual non-provocation rule, not for
helplessness; the helper already filters helpless. A helpless defender needs no
`except_index`. The `AOO1` row in §13 is therefore **not accepted evidence**; no
overrun trigger geometry has been validated. The completed helplessness fix does
not establish that the proposed origin/entry/exit treatment is correct.

A Cleave decision opened during any pass stops the overrun before movement; no
overrun resume state is added in the deferred design. The helper still sets
`aoo_used` before resolving each attack and stops on a dead/dying mover.

## 10. Outcome and accounting table

`Δft` is the change to `turn_state["moved_ft"]`; "origin"/"exit" is
`entry["cell"]`. `std` is `standard_used`; `move` is `move_used`; `used` is
`overrun_used`.

| Outcome | Cell | Δft | move | std | used | Attacker prone | Defender prone | AoO |
|---|---|---|---|---|---|---|---|---|
| Refused | origin | 0 | unchanged | unchanged | unchanged | unchanged | unchanged | none |
| AoO kills/drops/paralyzes | origin | 0 | unchanged | false | true | existing condition | unchanged | participants set `aoo_used`; no exit |
| Cleave pending | origin | 0 | unchanged | false | true | existing condition | unchanged | participant set; no resume |
| Avoid | exit | +10 | true | false | true | no | no | defender/others as applicable |
| No resistance (helpless) | exit | +10 | true | false | true | no | no new prone | defender excluded; others may react |
| Win | exit | +10 | true | true | true | no | yes | participants |
| Loss, no counter | origin | +10 | true | true | true | no | no | participants |
| Loss, counter wins | origin | +10 | true | true | true | yes | no | participants |
| Loss, counter loses | origin | +10 | true | true | true | no | no | participants |

The "no resistance" row is not a voluntary avoid: there is no choice, no check
and no new prone. It is the project's handling of a defender that cannot block.

## 11. UI, keyboard and mouse (historical proposal)

This UI proposal is not authorized; the fixed-exit target mode and the 33-control
acceptance are historical. A future continuation design would need its own
UI acceptance.

One new action button, "Overrun", beside Trip and Bull rush
(`src/ui/combat_screen.gd:283-284`). It enters the existing target mode; the
player clicks an adjacent enemy, or uses the grid keyboard. There is no
destination picker, no exit picker and no new panel. The view's existing budget
highlight and cursor draw are unchanged; the exit is not separately drawn.

Enabled when all of these hold; disabled otherwise with the existing status
message:

- it is the player's turn; no pending decision; the actor can act and is not
  paralyzed/prone/grappled/pinned/staggered;
- `standard_used` false, `five_foot_used` false, `overrun_used` false;
- an eligible adjacent enemy exists (not an ally, dead, too large, or
  grappled/pinned); the actor has at least 10 ft of budget; at least one eligible
  adjacent enemy has a legal fixed exit.

The button's enabled state does **not** predict the check, the defender's choice,
the AoO result or the counter; it checks only the declaration guards and the exit
geometry. The engine remains authoritative.

Keyboard and mouse:

- The button is a focusable `Button`; Enter/Space presses it. The grid cursor
  starts on the active creature. Arrow keys move the cursor through the existing
  grid mode; Enter/Space confirms the enemy cell through the existing
  `cell_clicked` path. Escape cancels before the target is confirmed and returns
  focus to the button. The existing combat screen has no right-click cancel, so
  none is claimed.
- Before the target click: Escape cancels the mode; nothing is spent.
- After the target click: the engine resolves the reaction, choice and check to
  completion. There is no post-target cancel or undo.
- Tab recovery remains the existing code path; it is **code-inspected, not newly
  key-tested** here. Keyboard acceptance is not reopened.

The historical layout expectation was **33 controls** (32 + Overrun), to be
measured at 100 % and 160 %. It is not an active acceptance requirement, and this
note does not claim the measurement. A revived design must measure its own
control grid without clipping at both scales.

## 12. Cancellation, commitment and messages

- Cancelling before a target is chosen is free: no `overrun_used`, no movement,
  no standard.
- Choosing a target commits the declaration. The AI choice, AoO pass and check
  resolve immediately; the player cannot cancel after seeing the defender's
  choice.
- An interrupted attempt is not refunded: the once-per-round attempt is consumed;
  movement is 0 and the standard is unspent.
- A blocked attempt consumes the standard even on a loss; a win consumes it; an
  avoid/no-resistance leaves it.
- Messages must name the actor, target, outcome and remaining movement where
  relevant; no generic "it failed" when the check, AoO or geometry is the cause.

## 13. Failing-first tests

This is the historical matrix, not an acceptance contract. No implementation is
authorized. Rows that assume the fixed-exit stop (`M1`/`M2`) are withdrawn; `T1`,
`T2` and `AOO1` are revised below. If overrun is revived, rebuild the matrix around
the chosen continuation and tie/geometry decisions.

| # | Scenario | Expected |
|---|---|---|
| R1 | standard already used | refused before the AoO; no state change; `overrun_used` unchanged |
| R1b | standard already used, helpless target | still refused; the declaration is a standard-action attempt |
| R2 | not adjacent / ally / dead / too large / grappled / pinned | refused; no state change; no attempt |
| R3 | exit blocked or outside the map | refused; no state change; no attempt |
| R4 | fewer than 10 ft of budget | refused with the exact remainder; no state change |
| R5 | actor prone/grappled/pinned/staggered/5-ft step | refused; no state change |
| R6 | pending Trip/Cleave/Bull-rush decision | refused; no state change |
| I1 | entry AoO kills the actor | origin; Δ0; `move_used` unchanged; `standard_used` false; attempt true; actor dead; no exit; defender's `aoo_used` true if it reacted |
| I2 | entry AoO paralyzes/drops the actor | origin; Δ0; `move_used` unchanged; standard false; attempt true; actor paralyzed/dying; no exit |
| I3 | entry AoO opens a Cleave decision | origin; Δ0; `move_used` unchanged; standard false; attempt true; no prone; decision pending; no resume |
| I4 | AoO damages but does not stop the actor | continues to the choice; only then Δ10; standard/defender outcome follows |
| I5 | effect leaves the actor grappled/pinned | origin; Δ0; `move_used` unchanged; standard false; attempt true; no exit |
| A1 | defender avoids (test-only policy) | exit; Δ10; `move_used` true; standard false; attempt true; defender not prone; `aoo_used` set for reacting defender |
| A2 | helpless defender, no resistance | exit; Δ10; `move_used` true; standard false; attempt true; no new prone; defender excluded from its own AoO; other threats may react |
| W1 | block, attacker wins | exit; Δ10; `move_used` true; standard true; attempt true; defender prone; attacker not |
| L1 | block, attacker loses, no counter | origin; Δ10; `move_used` true; standard true; attempt true; neither prone |
| L2 | block, counter wins | origin; Δ10; `move_used` true; standard true; attempt true; attacker prone |
| L3 | block, counter loses | origin; Δ10; `move_used` true; standard true; attempt true; neither prone |
| P1 | defender already prone, attacker wins | exit; Δ10; defender remains prone; no duplicate prone; standard true |
| P2 | defender already prone, counter wins | origin; Δ10; attacker prone; defender remains prone; standard true |
| F1 | flat-footed defender | no AoO (`aoo_used` false); can still block; W/L as above |
| F2 | total-defense defender | no AoO (`aoo_used` false); can still block; W/L as above |
| F3 | staggered defender | may AoO and block; W/L as above |
| F4 | defender has no melee threat | no AoO; can still block; W/L as above |
| F5 | defender already used its AoO | no new AoO; `aoo_used` remains true; can still block; W/L as above |
| O1 | second overrun in the same round | refused; `overrun_used` stays true; no state change |
| O2 | avoid then second overrun | refused; avoidance consumed the attempt |
| O3 | next round after an attempt | allowed again; `overrun_used` cleared at `begin()` / round wrap |
| D1 | diagonal entry and exit | exit; Δ10 (5+5); both terrain corner checks pass; if either corner pair is terrain-blocked, refused; occupancy corners follow `move_active_to` |
| Z1 | Medium vs. Large | allowed; size +4 to the larger side's check |
| Z2 | Huge vs. Medium | refused (`def_steps > atk_steps + 1`) |
| Z3 | stability +4 | applies to the initial defender only; never to the counter |
| T1 | tied totals, different raw ability modifiers | higher raw ability modifier wins; size and stability bonuses must not decide the tie; assert `tie_broken_by == "modifier"` after the helper supports raw tie modifiers |
| T2 | tied totals and equal raw ability modifiers | reroll; assert `tie_broken_by == "reroll"` and the eventual winner |
| C1 | counter modifiers | defender Strength + size vs. attacker best + size; no stability, no feat, no other modifier |
| C2 | counter is free | no standard, no move, no additional attempt, no `aoo_used` change |
| M1 | after a win | **withdrawn**: no acceptance row until the printed continuation is designed; the old fixed-exit expectation is not accepted |
| M2 | after an avoid | **withdrawn**: a double move is not residual continuation; no acceptance row until the printed continuation is designed |
| M3 | after a loss, standing or prone | no further movement; standing up is refused because `move_used` is true |
| M4 | after an interrupted attempt that leaves the actor able (Cleave-pending) | `move_used` unchanged; after resolving the decision the untouched move action remains; the overrun cannot be re-declared |
| AOO1 | participant geometry | **open**: the old origin-only expectation is not accepted; participant selection must be decided separately from eligibility before this row can exist |
| AOO2 | helpless third enemy | eligibility is corrected: it must not react; this still does not validate participant geometry |

Test classes:

- **Engine tests:** direct calls to `overrun_active` and `_provoke` with seeded
  RNG, valid abilities and explicit `opts`; assert the table above. These are the
  failing-first tests and the primary evidence.
- **Fixture tests:** a seeded QA encounter with a blocker, an exit-only threat and
  a flat-footed/total-defense enemy. The fixture proves geometry and participant
  accounting; it is not proof that the shipped encounter always produces a win.
- **Probe/real-input tests:** the probe drives the button, target mode and click;
  keyboard and mouse paths are separate checks. The probe is not the only
  evidence for the check or the counter.

## 14. Probe plan (historical; not authorized)

No probe is authorized. The following was the proposed probe if the feature were
revived; it would need revision for continuation and participant geometry.

Add `--overrun-probe` to `src/main.gd` and a QA fixture beside the existing trip
fixture (`:8878`). The probe should:

1. Open the combat screen on the fixture; assert the Overrun button is present and
   enabled only under the guards.
2. Press the button, assert the target mode, click the blocker, and assert the
   resulting cell, movement, standard, prone and `aoo_used` values.
3. Exercise avoid via a test-only `defender_choice`, a win, a loss and an
   interrupted attempt with a seeded lethal AoO; assert the same fields as the
   unit tests.
4. Exercise the keyboard path (focus, Enter/Space, cursor, confirm, Escape) and
   the mouse path separately; do not treat one as evidence for the other.
5. Run the layout probe at 100 % and 160 %, assert **33** controls, no clipping
   and a reachable Overrun button in both.
6. Export a fresh hash-bound candidate; never overwrite
   `2026-11-24_combat_keyboard_a`.

The probe is not a substitute for the deterministic tests and does not prove the
shipped encounter's balance.

## 15. Implementation batches (withdrawn)

No implementation batch is authorized. The earlier two-batch proposal is
withdrawn. The shared opportunity-attack fix (`d14b7fc`) and the separate
into-melee fix (`4c42965`) are completed corrections, not an overrun feature.

Any future proposal must first settle continuation, tie semantics and participant
geometry, then define a new acceptance unit with its own engine, UI, probe and
candidate boundary. Do not start engine work under the old Batch 1/Batch 2
labels, and do not mark any engine-only milestone as a shipped overrun feature.

## 16. Classification

**Confirmed product defects:** none in overrun; the feature is absent by scope.
Two separate shared corrections are complete: helpless opportunity-attack
eligibility (`d14b7fc`) and the paralyzed-ally into-melee penalty (`4c42965`).
Neither is an overrun defect.

**Confirmed probe defects:** the 720px ranged-probe control navigated an
offscreen enemy-row button instead of the visible grid. Corrected in `1a2a239`;
the evidence record is `247fad3`. This was not a product target-selection defect.

**Deferred features:** overrun itself, including printed success/avoid
continuation; approach movement; destination selection; Improved Overrun;
charge/mounted/Trample; multi-square or multi-target overrun; AI initiation;
player-defender avoid/block decisions; a shipped avoid policy; difficult terrain;
grapple-target overrun; exit/intermediate opportunity geometry; resuming an
overrun after a Cleave decision; rooted/immobilized effects; and
mounted/flying/swimming/incorporeal cases.

**Open design decisions / evidence gaps:** whether Option A or a general movement
continuation (Option B) is ever worth accepting; the shared tie-helper contract;
the participant trigger geometry; pending-Cleave resume; encounter reset for any
new state; no overrun tests, probe, validator, build or candidate; no human
playtest; avoidance remains fixture-only. The 985-test count belongs to the
earlier keyboard candidate and is not evidence for overrun.

**Maintenance debt the project must not add:** more probe-only branches in
`main.gd` without a fixture, duplicate move-accounting paths, a second
prone/trip path, a new pending-decision type, or a silent change to the shared
tie behavior used by trip, bull rush or grapple.

## 17. Historical done criteria (not active)

These were the proposed criteria before the scope review; they are not an
authorization and none is active. Any revival must replace them with a new
acceptance unit.

The feature would have been done only when:

- the prerequisite AoO filter is tested (shared AoO met by `d14b7fc`; separate
  into-melee met by `4c42965`; no defender-only fallback);
- the engine tests cover every row in §13 and the suite is green;
- the Overrun button, target mode, keyboard and mouse paths work;
- the layout probe measures **33** controls at 100 % and 160 % without clipping;
- the probe exercises avoid, win, loss, interruption and the one-per-round limit;
- a fresh hash-bound candidate is exported and its hashes are recorded;
- no roadmap/coverage document marks overrun complete while it remains deferred;
- the existing keyboard acceptance and the uncommitted README quick-start removal
  are untouched.

No tests, probes, validators, builds or exports were run for this planning
review.

## 18. Scope decision: defer overrun (2026-11-24)

**Decision: C — defer overrun.** The fixed-exit stop is withdrawn as an
unapproved adaptation. No bounded player-facing implementation is supported, and
no implementation batch is authorized. This decision does not preserve the prior
planning effort for its own sake: the plan's benefit claim, movement dependency,
tie contract and opportunity geometry do not justify the required work now.

### Movement contract finding

Residual movement after an atomic overrun **cannot reuse the existing accounting
without changing ordinary movement semantics**.

- `Encounter.move_active_to` (`encounter.gd:529`) computes a full path against
  `speed_ft`, sets `move_used` or `standard_used` before the opportunity pass, and
  charges the whole path at the end. It has no residual budget.
- `turn_state["moved_ft"]` is a total for the turn, not a remaining-movement
  budget. `move_used` is the gate that refuses an ordinary second move.
- `_advance_cell` (`:1935`) writes a cell and adds to `moved_ft`; it is useful
  accounting, but it is not a movement transition.
- `off_turn_resume` (`:69`) stores an interrupted monster route. `resume_interrupted`
  (`:4299`) is monster-move-specific and ends the turn after resuming; it is not a
  player continuation path.
- Combat is not serialized: `GameState.save_game` refuses any mode other than
  `explore` (`game_state.gd:495`). New encounter state needs no save migration,
  but it must be cleared by `begin()`/`finish()`.

A bounded continuation would therefore need at least an `overrun_resume` record
(actor, remaining feet, exit/route, action state) plus a transition that permits a
destination path while bypassing `move_used` only for that state, and UI for
continuing. That is a movement/action change, not a local overrun commit.

### Option A — bounded overrun-specific continuation

- **Player benefit.** Preserves the printed ability to keep moving after a win or
  avoidance, potentially reaching another enemy or leaving the lane. In shipped
  content the gain is small: there is no back line, the prone blocker still occupies
  the lane, and the shared undead are immune to sneak attack.
- **Rules fidelity.** Closer than the fixed-exit stop. It still keeps project
  adaptations (10-ft charge, no transient overlap, fixed entry direction), but it
  would model the printed success/avoid continuation instead of denying it.
- **Exact seams.** `move_active_to` (`:529`), `_fresh_turn_state` (`:90`),
  `_begin_turn` (`:225`), `_advance_cell` (`:1935`),
  `_provoke_attacks_of_opportunity` (`:3472`), `off_turn_resume` (`:69`),
  `resume_interrupted` (`:4299`), `GameState.combat_move` (`game_state.gd:1773`),
  `CombatScreen` target/action controls, `CombatView` movement cursor/budget, and
  `begin()`/`finish()` cleanup.
- **Minimal additional state/transition.** An overrun-specific resumable movement
  state with remaining feet and an explicit transition that does not turn ordinary
  movement into a general budget system. It would either duplicate path/AoO logic
  or extract a shared primitive; either choice touches ordinary movement or adds a
  second accounting path.
- **Risks.** Bypassing `move_used`, confusing residual movement with a double move,
  5-foot-step and action-order interactions, a second movement-accounting path,
  Cleave/AoO interruption during the residual move, and cleanup on death/finish.
  The AI does not initiate overrun, so it is affected only if a shared movement
  primitive changes.
- **Test surface.** Engine tests for residual feet, path legality, AoOs, action
  order, Cleave pending/resume, five-foot step and cleanup; UI/keyboard tests; a
  probe; layout; a candidate. Much larger than the old fixed-exit matrix.
- **Independent batch boundary.** **No.** It changes movement/action semantics and
  cannot be accepted as a small overrun-only batch. It needs its own accepted
  design first.

### Option B — general movement-continuation prerequisite

- **Player benefit.** None by itself; it enables overrun continuation and possibly
  later movement features. It is infrastructure, not a player-facing action.
- **Rules fidelity.** The closest general model: one movement budget can survive an
  intervening special action. It does not by itself settle overrun's 10-ft charge,
  fixed direction or defender outcome.
- **Exact seams.** Every `move_active_to` caller, including `GameState.combat_move`,
  `_run_monster_turn` (`:4226`), `resume_interrupted` (`:4299`), turn/flee movement,
  `_fresh_turn_state` (`:90`), `_begin_turn` (`:225`), `_advance_cell` (`:1935`),
  the opportunity helper, and the movement UI.
- **Minimal additional state/transition.** A general remaining-budget field and a
  movement primitive that can be entered after a special action, with explicit
  action-economy rules and interruption/resume behavior. This is the actual
  prerequisite, not a small flag.
- **Risks.** Broad regressions in ordinary movement, double moves, five-foot steps,
  AI routes, opportunity attacks, pending Cleave resume, and action ordering.
- **Test surface.** Movement suite, AI, AoO, pending decisions, save/cleanup
  boundaries, UI, probes and layout. It is independently testable but is a larger
  subsystem than overrun.
- **Independent batch boundary.** **Yes, but only as a separately planned and
  accepted movement prerequisite.** It is not authorized by the overrun plan and
  should not be started merely to unblock overrun.

### Option C — defer overrun

- **Player benefit.** None now; overrun remains unavailable. The project avoids a
  misleading fixed-exit feature and avoids committing to a movement refactor for a
  low-payoff action.
- **Rules fidelity.** No new fidelity claim. The plan states plainly that printed
  success/avoid continuation is not implemented and that the fixed exit is not
  equivalent. That is more honest than shipping the adaptation as if complete.
- **Exact seams.** Documentation only. No executable seam changes.
- **Risks.** Opportunity cost and an unimplemented special attack. These are
  preferable to a second movement path or a knowingly incorrect acceptance.
- **Test surface.** No game tests, probes, validators, builds or exports. Only
  documentation-integrity checks are relevant.
- **Independent batch boundary.** **Yes.** Deferral is complete without touching
  code, content, schema, saves or candidates.

### Cross-cutting findings

- **Opposed-check tie.** PHB p. 64 compares the higher skill modifier; for overrun's
  raw ability check the ability modifier takes that role. Size and stability are
  bonuses to the check, not ability modifiers, so they must not decide a tied total.
  The current helper compares ability modifier plus `opts` bonuses. This is a shared
  helper-contract question: trip, bull rush and grapple also pass bonuses. A future
  overrun implementation should request separate raw tie modifiers (or an
  overrun-local check); changing shared behavior for the other maneuvers is not
  authorized here.
- **Opportunity geometry.** Eligibility is corrected and tested, but participant
  selection is not. A single pass from the origin is a project choice; it does not
  model every threatened square traversed by the passage and is not established by
  the printed text or the helper. Keep participant selection separate from
  eligibility. `AOO1` is not accepted evidence.
- **Pending decisions and cleanup.** A Cleave opened by an entry AoO already stops
  the attempt before movement. A continuation would need a new resume rule for an
  AoO during residual movement; `off_turn_resume`/`resume_interrupted` cannot be
  reused unchanged. Any new state must be cleared by `finish()` and `begin()`.
- **Saves.** Combat is transient and not saved; no save migration is needed. That
  does not make the movement transition simple, and it does not authorize one.

### Recommendation and next task

**Recommended next task: keep overrun deferred and select a different roadmap
candidate; do not implement Option A or B as part of overrun.** Reopen overrun only
if content creates a real back-line/repositioning payoff *and* the project first
accepts either a bounded continuation design or a general movement-continuation
prerequisite. There is no complete overrun acceptance unit to authorize now.

Confirmed defects, probe defects, deferred features, maintenance debt and evidence
gaps are kept separate in §16. No tests, probes, validators, builds or exports were
run for this review.
