# Overrun — implementation plan (planning only)

**Status: planning only, 2026-11-24.** This note implements nothing. It is based on
the review recorded in `d51d77e`, the printed 3.5 rules, and a source read of the
current tree. **No checks were run for this plan**, no executable behaviour changed,
and no candidate was exported. The first implementation batch is named in §15; it
has not started.

Scope: one player-initiated overrun against one adjacent enemy, with the printed
avoid/block and counter clauses, the existing movement and opportunity-attack
machinery, and one action-grid control. Not in scope: charging, mounts, Trample,
Improved Overrun, multi-square creatures, AI-initiated overrun, readied actions, a
destination picker, or a general movement/AI refactor.

## 1. Printed rules, verified

Sources: the 3.5 System Reference Document, Combat → Special Attacks → Overrun at
https://www.d20srd.org/srd/combat/specialAttacks.htm (which reproduces the PHB text),
the Improved Overrun feat at https://www.d20srd.org/srd/feats.htm, PHB p. 157 for
Overrun, PHB p. 96 for Improved Overrun, PHB p. 64 for the general opposed-check tie
rule, and PHB p. 151 for prone. The quoted fragments below are the SRD's wording.
Page numbers should be confirmed against the printed index when the implementation
batch opens, as the repo does for its other citations.

| Element | Printed rule | Consequence for this engine |
| --- | --- | --- |
| Action type | "You can attempt an overrun as a standard action taken during your move. (In general, you cannot take a standard action during a move; this is an exception.)" | Modelled as a standard action that also consumes movement. The exception is why the action and the movement are both charged. |
| Frequency | "You can make only one overrun attempt per round." | A per-round `overrun_used` record keyed by combatant index, not a per-turn boolean. |
| Size limit | "You can only overrun an opponent who is one size category larger than you, the same size, or smaller." | Compare `Rules.size_category_steps`; refuse when the defender is two or more steps larger. A defender one step larger is legal. |
| Entry and reaction | Step 1: "Since you begin the overrun by moving into the defender's space, you provoke an attack of opportunity from the defender." | The entry provokes through the existing movement-reaction pass. The defender's reaction resolves before the avoid/block choice. |
| Avoid | Step 2: "The defender has the option to simply avoid you. If he avoids you, he doesn't suffer any ill effect and you may keep moving ... The overrun attempt doesn't count against your actions this round (except for any movement required to enter the opponent's square)." | Avoid is a real branch: the defender suffers nothing, the mover passes through, and the standard action is **not** spent. The movement is still spent. |
| Block check | Step 3: "make a Strength check opposed by the defender's Dexterity or Strength check (whichever ability score has the higher modifier)." | Attacker uses Strength; defender uses the better of Strength and Dexterity. Reuse `Rules.opposed_ability_check`, which already implements "higher modifier". |
| Size modifiers | "A combatant gets a +4 bonus on the check for every size category he is larger than Medium or a –4 penalty for every size category he is smaller than Medium." | Add `4 * size_category_steps` to each side, as trip and bull rush already compute their own size parts. |
| Stability | "The defender gets a +4 bonus on his check if he has more than two legs or is otherwise more stable than a normal humanoid." | Use the authored `Character.stability_bonus`, the same field trip uses. No shipped monster sets it, so shipped defenders add 0. |
| Win | "If you win, you knock the defender prone." | Set prone on the defender; the defender keeps its square. The mover continues into the free square beyond. |
| Loss and counter | "If you lose, the defender may immediately react and make a Strength check opposed by your Dexterity or Strength check (including the size modifiers noted above, but no other modifiers) to try to knock you prone." | Defender may counter with Strength against the mover's better of Strength/Dexterity. **Size only**: no stability, no feat bonus, no other modifier. A counter win knocks the mover prone. |
| Failure placement | Step 4: "If you fail ... you have to move 5 feet back the way you came and fall prone, ending your movement there. If that square is occupied, you fall prone in that square." | Retreat to the origin, ending movement; fall prone if the origin is occupied. The mover never ends in the defender's square. |
| Success continuation | "If you succeed in knocking your opponent prone, you can continue your movement as normal." | Bounded to one square beyond the defender (§2, A2). Further movement is deferred. |
| Improved Overrun | "When you attempt to overrun an opponent, the target may not choose to avoid you. You also gain a +4 bonus on your Strength check to knock down your opponent." | Deferred. It removes avoid and adds +4; it does **not** remove the entry's attack of opportunity. No supported dependency requires it for the base action. |
| Mounted overrun | "If you attempt an overrun while mounted, your mount makes the Strength check ..." plus Trample | Deferred with mounted combat. |

## 2. Project decisions, kept separate from the printed text

These are engine choices, not SRD claims. Each must be entered in
`docs/ADAPTATION_LOG.md` when the batch lands.

- **A1 — Adjacent-only declaration.** The printed action can happen during a move.
  This build requires the defender to be adjacent (8 directions) when Overrun is
  declared. The player may move adjacent first with the move action and still
  overrun if 10 ft remain. Moving up to the defender as part of the overrun is
  deferred; it would need an approach path and per-step reactions.
- **A2 — One fixed exit square, no destination picker.** The mover ends in the cell
  directly beyond the defender on the same 8-way axis (`target_cell + direction`).
  That square must be free. The printed "continue your movement as normal" is
  reduced to one square; choosing a further destination or turning after the pass is
  deferred. This is the smallest UI that still delivers the action.
- **A3 — Ten feet of movement.** Entry (5 ft) plus exit (5 ft), or entry plus the
  printed 5-ft retreat on failure, is charged to `moved_ft`. A character with less
  than 10 ft of budget is refused before anything is spent. The SRD does not price
  the entry explicitly; the 5-ft grid does, and the failure text explicitly moves
  5 ft back.
- **A4 — The standard action is committed only when the defender blocks.** The
  printed avoid clause says the attempt does not count against the character's
  actions. The movement action is committed at declaration (`move_used = true` if it
  was free), and the 10 ft is charged. If the defender avoids, `standard_used` stays
  false and the character may still attack. If the defender blocks, `standard_used`
  is set before the opposed check. If an opportunity attack ends the attempt before
  the choice, the standard is not spent.
- **A5 — No transient overlap.** The grid holds one creature per square. The engine
  never stores the mover in the defender's square: on a win or avoid it commits the
  mover to the exit; on a loss or counter it keeps the mover at the origin and
  charges the retreat. The log narrates the entry.
- **A6 — Shipped defenders block; a defender that cannot act avoids.** The AI
  policy is "block" for every shipped monster (all are melee undead), and "avoid"
  when the defender cannot act (`can_act()` false: dead, dying, unconscious,
  paralyzed, helpless). Tests may force either branch through
  `opts.defender_avoids`. Ordinary play therefore almost always sees block; the
  avoid branch is a rules path with fixture coverage, not a shipped-content
  behaviour. No player controls the defender's choice.
- **A7 — The defender always counters when it can.** The printed "may" is an AI
  choice; the shipped policy takes it. `opts.counter_trip = false` exists for tests
  and for a future tactical policy, not for the UI.
- **A8 — One per round is enforced per combatant.** `overrun_used[index]` is set
  once the attempt passes validation and starts, including an avoided or
  opportunity-interrupted attempt. A refusal before the start does not consume it.
  It is cleared in `begin()`, when `_advance()` rolls into a new round, and in
  `finish()`.
- **A9 — Refused states.** Prone attackers, grappled or pinned attackers or
  defenders, staggered attackers, and characters who already used a 5-ft step are
  refused with a specific message. These are bounded project limits; the printed
  text does not address all of them. Grapple/pin interaction is deferred rather
  than guessed. `Character.trip_immune` is a trip property and is not consulted;
  overrun's prone result is separate, and no shipped monster sets the flag.
- **A10 — No charge, no mount, no feat, no unsupported movement.** No +2 charge
  bonus, no mounted check, no Trample, no Improved Overrun. Charging, mounted
  movement, difficult terrain, climbing/swimming/flying and other unsupported
  movement modes are excluded; overrun uses the ordinary grid budget. The feat
  stays deferred in `FEATS_SKILLS_COVERAGE.md` and is not a dependency for the base
  action. If it is added later, its +4 applies to the initial check only, not the
  counter.

## 3. Player benefit in shipped content

Overrun is legally obtainable by every pregen; no feat, item or spell is needed.
Kaelen has Strength 16 (+3) and no Improved Overrun; Sera has Strength 12 (+1).
The shared monsters are all Medium undead with `equipment: {}` and natural attacks:
zombie Strength 12 / Dexterity 8 (best +1), infected zombie Strength 17 (best +3),
ghoul Strength 13 / Dexterity 15 (best +2). The check is therefore practical for
Kaelen and a coin flip for Sera, not a caster-only trick.

The strongest shipped geometry is **`storeroom_dead`** (`content/campaigns/ravenloft_demo/encounters.json:2-56`).
Its two pillar rows are `#.##.##.#`, leaving three one-square lanes at x=1, 4 and 7.
The party starts on the bottom row and the two zombies on the top row. A zombie
standing in a lane body-blocks it, and the square beyond can be free. Overrunning
it knocks it prone (-4 AC against melee, PHB p. 151), puts the fighter beyond it,
and lets a second party member threaten from the near side: the prone defender is
then flanked, which matters for Sera's sneak attack. That is a real positional and
accuracy benefit inside a kill-all fight.

It is **not** a back-line objective. Every shared monster is melee, encounters are
kill-all, the AI never initiates special attacks, and the prone defender still
occupies the lane, so the rest of the party cannot walk through it. The claim is
"pass one blocker, knock it prone, and set up a flank", not "reach a caster" or
"open the lane for everyone". `crypt_warden` has wider three-square rooms, and the
town-square map is open, so overrun is optional there rather than necessary.

Normal reachability is the player's own turn, an adjacent enemy, a free exit and
10 ft of budget. The avoid branch is not ordinarily reachable because shipped
defenders block; it is reached in tests through a paralyzed fixture or the
`defender_avoids` override. Improved Overrun is neither selectable on any pregen
nor implemented.

## 4. Exact repository seams

All references are source reads, not new tests.

| Need | Existing seam | How overrun uses it |
| --- | --- | --- |
| Turn state and budget | `src/core/encounter.gd:92-95` (`standard_used`, `move_used`, `five_foot_used`, `moved_ft`); `:615` budget; `:655` movement charge | Charge 5 ft for the entry and 5 ft for the exit/retreat to `moved_ft`; set `move_used`; set `standard_used` only on block. |
| Single movement-accounting site | `src/core/encounter.gd:1935` `_advance_cell(entry, cell, cost_ft)` | Commit the exit with `_advance_cell`; charge the entry/retreat with the same helper using the unchanged cell, so no second arithmetic site is added. |
| Occupied cells | `src/core/encounter.gd:516` `occupied_except(index)` | The exit must not be in the occupancy map; the origin check for the printed "occupied" clause uses it. |
| Map legality | `src/core/battle_map.gd:11` `CELL_FT`; `:44` `is_blocked`; `:56` `distance_ft`; `:60` `is_adjacent`; `:213` `reachable`; `:238` `find_path`; `:281` `_blocked_diagonal` | Adjacency is 8-way; entry legality is a one-step `find_path`; exit legality is `reachable(target_cell, CELL_FT, occupied).has(exit)`, which reuses the map's corner rule and occupancy exclusion. |
| Attack of opportunity | `src/core/encounter.gd:3460` `_provoke_attacks_of_opportunity(mover_index, from_cell, except_index := -1)`; `aoo_used`; `threat_capability` at `:728` | One pass from the mover's origin after the entry charge. It reaches the defender and any other enemy that threatens the origin, respects `aoo_used`, flat-footed, total defense and grapple, and resolves each reaction as an ordinary attack. |
| Size and stability | `src/core/character.gd:26-32` (`size_category`, `stability_bonus`); `src/core/rules.gd:56` `size_category_steps`; `:32` `is_valid_size_category` | Eligibility: `def_steps <= atk_steps + 1`. Modifiers: `4 * steps` each side; defender adds `stability_bonus` only to the initial check. |
| Opposed checks | `src/core/rules.gd:584` `opposed_ability_check(rng, attacker, abilities, defender, abilities, opts)` | Initial: attacker `["str"]`, defender `["str", "dex"]`, with size/stability in `opts`. Counter: defender `["str"]`, attacker `["str", "dex"]`, size only. The helper already handles the printed general tie rule (PHB p. 64). |
| Prone | `src/core/character.gd:109-117` `is_prone` / `set_prone`; `src/core/encounter.gd:1260` `stand_up_active`; `src/core/rules.gd:240` prone AC | Set the defender prone on a win and the mover prone on a counter win. Standing up remains the existing move action that provokes. |
| Pending decisions | `src/core/encounter.gd:51-56`; `:2708` `has_pending_decision`; `:667` `_pending_guard`; `:1829` bull-rush resolver as the shape | Overrun adds **no** pending dictionary. It refuses while any existing decision is open. Its two choices are deterministic AI policies, and its destination is fixed. |
| Turn/finish cleanup | `src/core/encounter.gd:142` (`begin`), `:304-305` (round advance), `:310` `end_turn`, `:4585` `finish` | Clear `overrun_used` in `begin`, on the round wrap, and in `finish`. No new state outlives the encounter. |
| AI | `src/core/encounter.gd:4210` `_run_monster_turn` | Unchanged. Monsters never initiate overrun; only the defender's block/avoid and counter policies are consulted. |
| UI action grid | `src/ui/combat_screen.gd:283-284` (Trip, Bull rush); `:720` `_update_button_states`; `:832` `_on_cell_clicked`; `:947` `_trip`; `:958` `_bull_rush` | Add one `Overrun` button, a `mode == "overrun"` branch, an `_overrun()` entry, and one enabled-state row. |
| Targeting and keyboard | `src/ui/combat_screen.gd:631` `_rebuild_targets`; `:336` `_grid_keyboard_allowed`; `src/ui/combat_view.gd:193` budget highlight and `:250` cursor draw | Reuse the existing target mode and grid cursor. No new key bindings, no new view drawing, no destination step. |
| `Game` wrapper | `src/game_state.gd:1773` `combat_move`; `:1855` `combat_trip`; `:1877` `combat_bull_rush` | Add `combat_overrun(target_index)` with the same `last_ui_message`, failure logging and `state_changed` shape. |
| Probes and fixtures | `src/main.gd:111` probe-name list; `:366` dispatch; `:432` layout; `:2505` `_probe_button`; `:2533` `_probe_click`; `:2548` `_probe_click_cell`; `:2560` `_layout_probe`; `:2895` `_probe_shot`; `:2936` `_probe_check`; `:5297` `_trip_probe`; `:8169` `_probe_advance_to`; `:8878` QA trip fixture | Add `--overrun-probe`, a `--demo-overrun` QA fixture, and a probe that clicks the real controls; keep the existing probe bookkeeping. |
| Docs rows | `docs/FEATS_SKILLS_COVERAGE.md:221`; `docs/TRACEABILITY.md:62`; `docs/SUPPORTED_FEATURES.md:458`; `docs/ADAPTATION_LOG.md:184,196` | Update after implementation: Improved Overrun stays deferred behind overrun; the traceability row moves overrun from deferred to supported for the player-initiated path; the supported-features list changes; the adaptations above are logged. |

## 5. Declaration and validation order

`Encounter.overrun_active(target_index: int, opts: Dictionary = {}) -> Dictionary`.
Every refusal returns `_fail(message)` with no cell, budget, action, RNG or
`overrun_used` change. The order is:

1. Active entry exists; no `has_pending_decision()`; the character can act and is not
   paralyzed; not prone; not grappled or pinned; not staggered.
2. `standard_used` is false; `five_foot_used` is false.
3. `overrun_used` does not already contain the actor index.
4. The target index is valid, is an enemy, is not dead, is not grappled/pinned, and is
   adjacent (`map.is_adjacent`).
5. Entry is a legal one-step move: `map.find_path(actor_cell, target_cell, occupied_except(actor)).size() == 1`.
   This also rejects a diagonal entry whose orthogonal corners are both blocked.
6. Size: `def_steps <= atk_steps + 1`; otherwise refuse "too large".
7. Direction is the sign step from actor to target; it is never zero because the
   cells differ.
8. The exit cell is `target_cell + direction`; it must be inside the map, free of
   blockers and occupants, and a legal step from the target cell:
   `map.reachable(target_cell, BattleMap.CELL_FT, occupied_except(actor)).has(exit)`.
   This is the engine's "no space beyond" refusal; the printed text has no such
   refusal, so it is an adaptation.
9. Budget: `speed_ft - moved_ft >= 10`; otherwise refuse with the exact remaining
   feet.

Record `start_cell = entry["cell"]`, `target_cell = target_entry["cell"]` and
`direction` before any write. After validation: `overrun_used[actor_index] = true`;
set `move_used = true` if it was false; log the declaration; charge the 5-ft entry
with `_advance_cell(entry, start_cell, BattleMap.CELL_FT)` (same cell, cost only);
log "moves into the defender's space".

## 6. Resolution sequence

1. **Entry reaction.** `_provoke_attacks_of_opportunity(actor_index, start_cell)`.
   This is the printed defender reaction plus ordinary movement reactions from any
   other enemy that threatens the origin. The defender is included naturally; do not
   call `_provoke_single_opportunity` again, or the defender would react twice. The
   SRD names only the defender; applying the ordinary reaction to other enemies that
   threaten the origin is a reading of the movement rules, recorded as such, not a
   quoted clause.
2. **Interruption.** If `finished`, return interrupted. If the actor is dead, dying,
   unconscious or paralyzed, stop: the actor remains at `start_cell`, `moved_ft` has
   the 5-ft entry, `standard_used` is still false, `_after_action`, `_check_end`,
   `changed`. No exit, no overlap, no check.
3. **Defender choice.** If `opts.defender_avoids` is true, or the target cannot act,
   the defender avoids: log it; commit the exit with
   `_advance_cell(entry, exit, CELL_FT)` (total 10 ft); leave `standard_used` false;
   `_after_action`, `_check_end`, `changed`; return `avoided: true`.
4. **Block.** Otherwise set `standard_used = true` and log the block. (If a
   retaliation effect killed the defender during step 1, re-check `can_act` and treat
   it as avoid instead of blocking.)
5. **Initial check.** `Rules.opposed_ability_check(rng, ch, ["str"], target, ["str", "dex"], {attacker_bonus: 4*atk_steps, defender_bonus: 4*def_steps + target.stability_bonus, label: "overrun"})`.
   Log both rolls and totals in the trip/bull-rush format. If the helper returns
   `ok: false` (a programming-error guard), log the reason, run `_after_action`,
   `_check_end` and `changed`, and return the failure; the standard was already
   committed on block and is not refunded.
6. **Win.** `target.set_prone(true)`; commit the exit (charge 5; total 10); log
   "knocked prone" and "continues through, ending 5 feet beyond"; `_after_action`,
   `_check_end`, `changed`; return `overrun: true, prone: true`.
7. **Loss.** Log the loss. If `opts.get("counter_trip", true)` and the target can act,
   make the counter: `Rules.opposed_ability_check(rng, target, ["str"], ch, ["str", "dex"], {attacker_bonus: 4*def_steps, defender_bonus: 4*atk_steps, label: "overrun counter"})`.
   Size only; no stability; no feat bonus. On a counter win, `ch.set_prone(true)` at
   the origin and log it. On a counter loss, log it.
8. **Retreat.** Commit the retreat with `_advance_cell(entry, start_cell, CELL_FT)`
   (same cell, cost 5; total 10). If `occupied_except(actor).has(start_cell)` — it
   cannot in this bounded flow, but the printed clause is kept — set the actor prone.
   Log "staggers back 5 feet and ends there"; `_after_action`, `_check_end`, `changed`;
   return `overrun: false, countered: ...`.

If the counter helper itself returns `ok: false`, log it and still perform the
printed 5-ft retreat; the counter is a reaction, not a second action.

## 7. Accounting table

| Outcome | Actor cell | Defender cell | `moved_ft` | `move_used` | `standard_used` | Prone |
| --- | --- | --- | --- | --- | --- | --- |
| Refused before start | unchanged | unchanged | +0 | unchanged | unchanged | unchanged |
| Opportunity attack drops the actor | origin | unchanged | +5 | true | false | no (dying/unconscious state only) |
| Defender avoids | exit | unchanged | +10 | true | false | no |
| Block, attacker wins | exit | unchanged | +10 | true | true | defender |
| Block, attacker loses, no counter | origin | unchanged | +10 | true | true | no |
| Block, counter wins | origin | unchanged | +10 | true | true | attacker |
| Block, counter loses | origin | unchanged | +10 | true | true | no |

The actor never occupies the defender's cell at rest. The defender never moves.
No path teleports a participant: the exit and origin are the only cells written.
Remaining movement is whatever `moved_ft` leaves in the current move; the 10-ft
charge does not grant or refund an action. The existing Move button and its
double-move case are unchanged.

## 8. Avoid, block and pending decisions

The defender is always an NPC in this batch, so its choice is a policy, not a
player dialogue. The player makes no avoid/block decision; the attacker only chooses
the target (the exit is fixed). Shipped monsters block; a defender that cannot act
avoids. The counter is likewise policy; shipped defenders take it. There is **no new
pending decision**: the attacker's exit is fixed at declaration, the defender's
choice is resolved synchronously, and no roll is left unapplied. The existing
`has_pending_decision()` gate comes first, so an overrun cannot open while a Trip,
Cleave or Bull-rush decision is waiting, and it cannot resume or consume that
decision.

If a future batch adds AI-initiated overrun, the player-defender's avoid/block choice
should use the existing typed `pending_*` pattern, not a new ad-hoc dictionary. That
is explicitly deferred.

## 9. Attacks of opportunity and cleanup

- The entry pass reuses `_provoke_attacks_of_opportunity`, so it inherits
  `aoo_used` (one reaction per enemy per round), flat-footed denial, total-defense
  refusal, grapple no-threat, and the ordinary attack resolution. It does not add a
  second reaction for the defender.
- Only the entry pass provokes. The exit step is part of the same overrun and gets no
  second reaction pass; the SRD names only the entry, and the defender has usually
  spent its reaction already. This is recorded as a reading, not a quoted clause. A
  later movement-reaction pass for the exit would need its own review.
- Improved Overrun would not remove this reaction; the feat is deferred and the
  base action always provokes.
- If the encounter ends during the reaction, `finish()` clears pending decisions,
  grapples, combat-scope effects and the new `overrun_used`; the mover stays at the
  origin and no exit is written.
- If either participant becomes unable to continue, the sequence stops at the
  current branch, runs `_after_action`/`_check_end`, emits `changed`, and returns a
  message naming the interruption. No `pending_*` state is created, so there is
  nothing to void on a later turn.
- `overrun_used` is cleared in `begin()` (`:142`), on the round wrap in `_advance()`
  (`:304-305`), and in `finish()` (`:4585`). It is not cleared at `_begin_turn`
  because the printed limit is per round, not per turn.

## 10. UI, keyboard, mouse and layout

- **One new control.** `_add_action_button("Overrun", _overrun)` beside `Trip` and
  `Bull rush` (`combat_screen.gd:283-284`). Label width is comparable to
  "Bull rush", so the four-column grid should not reflow; the batch must still
  measure it rather than assume it.
- **One new mode.** `_overrun()` refuses while pending, sets `mode = "overrun"`,
  shows "Click an adjacent enemy with a free square beyond to Overrun (PHB p. 157)."
  and calls `_begin_grid_keyboard()`. The existing arrow cursor and Escape
  cancellation then work unchanged.
- **One new branch** in `_on_cell_clicked`: require an enemy, call
  `Game.combat_overrun(index)`, refresh. Invalid targets keep the mode open and show
  the engine's message; the player can pick another or press Escape. No destination
  click, no second mode, no new drawing.
- **Enabled state.** Add `"Overrun"` to `_update_button_states`: `standard`, not
  prone, not staggered, not grappled/pinned, `five_foot_used` false, and
  `speed_ft - moved_ft >= 10`. The engine still refuses a missing adjacent target or
  blocked exit; the UI does not scan for targets.
- **Keyboard.** The button is an ordinary focusable `Button`; Enter/Space opens the
  mode, the grid cursor starts on the active creature, arrows move it, Enter/Space
  confirms the enemy cell through the click path, Escape cancels before the engine
  call and returns focus. No new key bindings. This is the same path the keyboard
  acceptance recorded; it is described from code inspection, not newly key-tested.
- **Layout expectation.** The combat layout probe currently reports 32 checked
  controls (recorded in `b2db538`); adding one action button makes **33** the
  expected count. The probe prints the count rather than asserting a fixed total, so
  the batch must record the actual number at 100 % and 160 %, update the acceptance
  ledger, and not assume 32 survives.

## 11. Cancellation and messages

- Before a legal target is clicked: Escape cancels the mode (the existing combat
  screen has no right-click cancel, so none is claimed). Nothing is spent;
  `overrun_used` is untouched; focus returns to the button.
- An invalid target click (not an enemy, not adjacent, too large, exit blocked, not
  enough movement): the engine refuses and the mode stays open. Nothing is spent.
- A legal target click commits immediately. There is no post-click cancel and no
  pending decision; the sequence runs to avoid, block/win/loss, or an
  opportunity-attack interruption.
- Representative lines:

```
Kaelen lowers a shoulder and overruns Zombie.
  Kaelen moves into Zombie's space.
  Kaelen leaves a threatened square — attack of opportunity by Zombie!
  Overrun: Kaelen Str d20(14)+3 = 17 vs Zombie Str d20(6)+1 = 7
  Zombie is knocked prone.
  Kaelen continues through, ending 5 feet beyond Zombie.
```

```
  Zombie gives way; Kaelen passes through.
  The overrun fails; Zombie counters.
  Counter-trip: Zombie Str d20(15)+1 = 16 vs Kaelen Dex d20(8)+1 = 9
  Kaelen is knocked prone.
  Kaelen staggers back 5 feet and ends there.
```

Refusals name the reason: too large ("at most one size category larger"), no free
square beyond, fewer than 10 ft remaining, already attempted this round, prone,
staggered, grappling/pinned, or a pending decision.

## 12. Tests and probes (for the implementation batches)

The focused suite is `tests/test_overrun.gd`, built like `tests/test_bull_rush.gd`:
a `ContentDB` character/monster, `BattleMap.from_rows`, `Encounter.setup`, fixed
`RandomNumberGenerator`, `_force_turn`, and a `_first_seed` helper that searches
seeds and pins the found value. Failing-first means a compiled stub that refuses, so
the red log contains **behavioural** failures (cells, budget, action state, rolls),
not a parse error.

| # | Test | Asserts |
| --- | --- | --- |
| 1 | entry/exit geometry, orthogonal and diagonal | one-step entry, exit directly beyond, diagonal corner rule |
| 2 | blocked/occupied/off-map exit | refused before spending; cells, `moved_ft`, `standard_used`, RNG untouched |
| 3 | size eligibility | defender two steps larger refused; one step larger allowed |
| 4 | guards | spent standard, fewer than 10 ft, 5-ft step already used, prone, staggered, grappled/pinned, pending decision |
| 5 | avoid | actor at exit, `moved_ft` 10, `move_used` true, `standard_used` false, defender not prone, log |
| 6 | win | defender prone, actor at exit, `moved_ft` 10, standard spent, no overlap |
| 7 | stability | a `stability_bonus = 4` fixture shifts the defender total by 4 |
| 8 | loss, no counter | actor at origin, `moved_ft` 10, standard spent, not prone |
| 9 | counter wins | actor prone at origin, defender not prone, `moved_ft` 10 |
| 10 | counter loses | actor not prone, at origin, standard spent |
| 11 | counter modifiers | size only: stability and feat bonuses do not leak into the counter |
| 12 | opportunity attack drops the actor | entry 5 ft charged, no exit, standard not spent, no overlap, encounter consistent |
| 13 | one per round | second attempt refused; allowed again after the round advances |
| 14 | cleanup | `begin`/round wrap/`finish` clear `overrun_used`; no pending state |
| 15 | stance interaction | a block spends the standard and clears a pending Combat Expertise/defensive selection through `_after_action`; avoid leaves it alone |
| 16 | frozen state on refusal | no cell, budget, action or RNG change for every refusal |
| 17 | pending-decision gate and resumption | an existing Trip/Cleave/Bull-rush decision refuses overrun; resolving it through its own resolver clears the gate, does not consume or reroll that decision, and overrun then obeys its own standard/budget guards |

Probe: `--overrun-probe` with a `--demo-overrun` QA fixture that builds a one-lane
storeroom-like map, places Kaelen adjacent to a zombie with a free exit, seeds the
RNG, and forces Kaelen's turn. Scenarios: `win`, `lose`, `counter`, `avoid` (a
paralyzed defender in the fixture), `aoo_drop`, `cancel`, `invalid`. The probe uses
`_probe_button`, `_probe_click`, `_probe_click_cell`, `_probe_check`, `_probe_shot`
and `_probe_advance_to`; it asserts the button is enabled and on screen, the modes
and messages, the final cells, `moved_ft`, `standard_used`, prone, the log, and that
Escape before a target spends nothing. Keep these three evidence classes separate in
the report:

- **Seeded fixture state** (the map, cells, RNG seed, paralyzed defender).
- **Direct engine calls** (unit tests calling `overrun_active` with `opts`).
- **Real input events** (probe clicks on the actual button/cell and Escape).

The eventual implementation batch must require: the focused suite green after a red
log with real behavioural failures; the full suite and both validators; the existing
probes (grapple, keyboard, level-up, advancement) unchanged; the new overrun probe;
layout at 1.0 and 1.6 with the recorded control count; a uniquely named candidate
such as `overrun_<YYYY-MM-DD>_a`; the executable's SHA-256 recorded before and after
and required to match; and a source-line review of every seam in §4 before editing.

## 13. Batches

**Batch 1 (recommended first): engine and deterministic tests.** Add the validator,
the resolver, the `overrun_used` record, the `Game.combat_overrun` wrapper, the
focused tests and the adaptation-log entries. Use a compiled refusing stub first so
the red log is behavioural. No UI, no probe, no export. This is independently
acceptable as a complete rules layer; it is not a player-facing feature yet, and it
must not be described as one.

**Batch 2: UI, probes, layout and exported candidate.** Add the button, the mode,
the click branch, the enabled-state row, the QA fixture, the probe scenarios, the
layout run at both scales and the hash-bound candidate. This is the batch that makes
the action playable. Do not ship Batch 1 as a partial UI or a hidden key.

The full action is larger than one safe batch because the engine's branching states
(avoid, block, counter, interruption), the UI mode, and the probe/layout/candidate
evidence each need their own review. The split does not create an unusable partial
feature: Batch 1 is a tested rules layer with no player entry point, and Batch 2 is
the complete entry point on top of it.

## 14. Classification, kept separate

- **Confirmed defects.** None. Overrun is absent by recorded scope, not a defect.
  The keyboard acceptance stays closed; Tab recovery was described from code
  inspection in `d51d77e`, not newly key-tested, and this plan does not reopen it.
- **Deferred features.** Approach-as-part-of-overrun; a destination picker or
  continued movement beyond one square; Improved Overrun's no-avoid/+4; charge and
  mounted overrun; Trample; multi-square creatures; AI-initiated overrun; a
  player-defender avoid/block decision; an avoid policy in shipped content;
  difficult terrain; overrunning a grappled/pinned defender; readied/delayed actions.
- **Maintenance debt this plan must not add.** A second pending-decision dictionary
  (none is needed); a second movement-accounting site (reuse `_advance_cell`); a
  duplicate size or opposed-check formula (reuse `Rules.size_category_steps` and
  `Rules.opposed_ability_check`); a new content schema flag (use
  `Character.stability_bonus`); more probe-only branches in `main.gd` without a
  fixture.
- **Evidence gaps.** No human playtest; the avoid branch is fixture-only in shipped
  content; the exported probe proves UI/layout and the seeded path, not every rules
  branch; the plan's page citations should be checked against the printed index; and
  the storeroom benefit is positional/flanking, not a back-line objective.

## 15. Definition of done (for the eventual implementation)

Batch 1: `tests/test_overrun.gd` green after a real red log; full suite and both
validators green; adaptation entries; no UI or candidate claim. Batch 2: the button
and mode work by mouse and keyboard; `--overrun-probe` passes all scenarios; layout
reports 33 controls/0 failures at 100 % and 160 %; the existing probes and suite are
unchanged; a uniquely named exported candidate with matching before/after SHA-256;
`SUPPORTED_FEATURES.md`, `TRACEABILITY.md` and `FEATS_SKILLS_COVERAGE.md` updated;
no README, save, content or executable change outside the batch. No manual testing,
no backups, no push.
