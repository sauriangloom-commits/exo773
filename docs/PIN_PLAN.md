# Pin — planning note for batch 8b (planning only)

**Status: implemented and accepted as batch 8b-1 on 2026-11-24.** The note was accepted
as the planning baseline in `607ea19` with its timing language clarified - expiry is at
the start of the pinner's next turn, and no fixed number of pinned turns is promised -
then implemented in `f149d1d`. Sections 1-8 are what shipped; section 10 records the
implemented seams, adaptations, evidence and classification. It builds on
`docs/GRAPPLE_PLAN.md` (batch 8a, closed as accepted) and the review recorded in
`dfadbe3` (`docs/ROADMAP.md`). Batch 8a's scope is not widened retrospectively: this
note plans a separate batch that depends on the shipped two-participant grapple.

Scope: one player-initiated pin against the creature the player already holds, its
effect on that creature's turn, its AC consequence against third parties, escape from
the pin, the holder's release, the AI's pinned turn and every existing cleanup path.
Out of scope: pin damage, using the pinned creature's weapon, moving a pinned creature,
breaking another creature's pin, joining a grapple, multiple grapplers, casting and
Concentration, any change to the AI's attack policy, the selectable feat chain, and
monster-initiated grappling. The last four are separate batches or deferred features,
not dependencies of pin.

## 1. Printed rules, verified

Sources: 3.5 System Reference Document, Combat → Special Attacks → Grapple
(d20srd.org, which reproduces the PHB text), and PHB pp. 155-157 for the special attack;
the pin paragraph is PHB p. 156. As `GRAPPLE_PLAN.md` does for its own citations, the
printed index should be confirmed against the physical book when the batch opens.

The quoted fragments are the SRD's wording:

| Element | Printed rule | Consequence for this engine |
| --- | --- | --- |
| Pin attempt | "You can hold your opponent immobile for 1 round by winning an opposed grapple check (made in place of an attack)." | Only a creature that is already grappling may pin, and the check is the same opposed grapple check 8a already rolls. |
| Duration | "held immobile (but not helpless) for 1 round" | Needs an expiry point tied to turn order, not a wall-clock duration. |
| Pinned AC | "While you're pinned, you take a –4 penalty to your AC against opponents other than the one pinning you." | A flat penalty against third parties only; the pinner is excluded. |
| Pinned Dexterity | Pinned creatures do not lose their Dexterity bonus against the creature pinning them; the general grapple rule already removes it against everyone else. | Existing `denies_dex_to` produces the Dexterity half; the –4 is a second, separate printed effect. |
| Pinned actions | "A pinned character … can't take any action except to attempt to escape." | Every action path must refuse, not only the paths 8a refused for grappling. |
| Escape from a pin | "On your turn, you can try to escape the pin by making an opposed grapple check in place of an attack. You can make an Escape Artist check in place of your grapple check … but this requires a standard action. If you win, you escape the pin, but you're still grappling." | Success clears the pin only; the pair survives. Two check methods, one action cost. |
| Pinning restrictions | "You can't draw or use a weapon (against the pinned character or any other character), escape another's grapple, retrieve a spell component, pin another character, or break another's pin while you are pinning an opponent." | The pinner cannot use the ordinary attack paths 8a left open (partner attack at –4). |
| Release | "You may voluntarily release a pinned character as a free action; if you do so, you are no longer considered to be grappling that character (and vice versa)." | Holder's free release ends the whole hold, not just the pin. |
| Break another's pin | Opposed grapple check in place of an attack; success leaves the creature "still grappling, but … no longer pinned". | Deferred here: it needs a third participant in the pair model. |

## 2. Code seams the batch would reuse

| Seam | Location | What pin reuses or extends |
| --- | --- | --- |
| Pair state | `src/core/encounter.gd:61` (`grapples`), helpers `:376-398` | Add a `pinned` flag to the existing `{holder, held}` dictionary; no second array. |
| Turn start | `encounter.gd:225-262` (`_begin_turn`) | Expiry point for the one-round pin, beside the other start-of-turn expiries. |
| Dexterity denial | `encounter.gd:372` (`denies_dex_to`) | Extend to "pinned and attacker is not the holder"; do not set flat-footed. |
| Grapple check modifier | `encounter.gd:403` (`_grapple_bonus`) | Unchanged; the pin uses the same base attack + Strength + size (+4 Improved Grapple). |
| Grapple refusals | `encounter.gd:416` (`_grapple_blocks`) | Pattern for a `_pin_blocks` message; movement paths already call the grapple one at `:490`, `:937`, `:1004`, `:1157`, `:1207`, `:2499`. |
| Pair clearing | `encounter.gd:425`, `:432`, `:441` | `_remove_pair`, `_clear_grapple_for`, `_prune_grapples` already run on death and finish; a pin is inside the pair, so they clear it for free. |
| Attacks | `encounter.gd:738` (`attack_active`), partner block `:765-800`, context `:2771-2810`, bonus dict `:860-895` | Refuse every attack while the actor is pinned and while the actor is pinning. |
| AC composition | `src/core/rules.gd:258` (`armor_class`), `:294` (`touch_ac`), `:713-718` | New option for the –4, applied to both AC and touch AC; `deny_dex` stays the Dexterity half. |
| Pin action | `encounter.gd:1884` (`grapple_active`), `:2069` (`grapple_exit`) | Shape for a new `pin_active`; `grapple_exit` gains the pinned branch. |
| Item and potion actions | `encounter.gd:3655` (`use_potion_active`), `:3716` (`stabilize_active`), `:3063` (`total_defense`) | Audit gap: none of these checks `is_grappled` today, so a pinned creature must be refused here explicitly. |
| AI turn | `encounter.gd:3964` (`_run_monster_turn`), escape branch `:3969-3972` | A pinned monster attempts a pin escape instead of a grapple escape, then stops. |
| Turning and finish | `encounter.gd:4114` (`_run_turned_turn`), `:4337` (`finish`) | Existing pair clearing covers a pinned pair. |
| Session wrappers | `src/game_state.gd:1899` (`combat_grapple`), `:1910` (`combat_grapple_exit`) | `combat_pin` and a pin branch beside them. |
| Action grid | `src/ui/combat_screen.gd:258-286`, Grapple/Escape `:277-282`, cell dispatch `:687-745`, handlers `:820-838` | One `Pin` control next to `Grapple`; no target mode because the partner is fixed. |
| Enable map | `combat_screen.gd:599-656`, `standard` `:600`, `Escape` `:656` | `Pin` enable rule beside `Grapple`; `Escape` stays keyed by its stable label. |
| Grapple probe | `src/main.gd:6888`, helpers `:7123-7175`; fixture `:6728` | Extend the existing probe scenarios; no new demo flag. |
| Layout probe | `src/main.gd:2557` | Counts controls from the live grid; 31 becomes 32. |
| Test precedent | `tests/test_grapple.gd` | Same fixture pattern: open map, seeded `rng`, `Encounter.setup`, direct action calls, seeded search loops for rolls. |

## 3. Decisions, with adaptations labelled

The labels are this note's own (A-H); they do not renumber `GRAPPLE_PLAN.md`'s A-G.

### 3.1 Who may pin, and what it costs

Only the **holder** of an existing two-participant grapple may pin, on its own turn,
against its held partner. A held creature cannot pin; a third party cannot pin either
participant without joining the grapple, which is out of scope.

**Adaptation A — the pin costs the standard action.** The printed rule makes the pin a
check "in place of an attack". This engine has one attack per turn, resolved by the
standard action, and no iterative attacks, so "in place of an attack" and "standard
action" are the same cost here. The pin is therefore declared as the standard action:
`turn_state["standard_used"] = true` before the opposed check, exactly as
`grapple_active` spends it before its reaction and touch attack.

**Adaptation B — the pinner keeps its square.** Pin is a state of an existing hold, and
8a already keeps both participants in their own squares (its adaptation A). Pin adds no
movement and no shared cell.

**Failure leaves the pair untouched.** A lost opposed check spends the action, logs the
loser, and changes neither `pinned` nor the pair. A second pin attempt in the same turn
is refused with the standard-action message; a second pin while already pinned is
refused by name.

Guards, in order, matching 8a's shape: pending decision; active combatant; can act and
not paralyzed; standard unused; staggered; the actor holds a pair; the partner is not
dead; the partner is not already pinned.

### 3.2 State, duration and expiry

The pair becomes `{holder, held, pinned: false}`; a pin sets `pinned: true`. No
`Character` condition and no second array: the pin cannot outlive the encounter, cannot
ride into a save (combat is not saved at all), and is cleared by every path that already
clears a pair.

**Adaptation C — expiry at the start of the pinner's next turn.** "Immobile for 1 round"
is implemented as: the flag clears in `_begin_turn` when the turn belongs to the pair's
holder, logging that the pin ends. This is the same convention the engine already uses
for total defense and Combat Expertise ("until the start of the character's next turn",
`encounter.gd:225-262`), and it needs no stored round counter.

Turn-order consequences, stated without promising a fixed number of pinned turns. The
pin expires at the start of the pinner's next turn, whatever the initiative order. In
the supported orderings the pinned creature's next turn falls before that expiry, so it
takes that turn pinned; but the amount of control the pin buys still depends on whether
it escapes the pin and on how many of its turns remain in the encounter, so this plan
does not claim "exactly one pinned turn" or a guaranteed extra round.

If the pinner cannot act - paralyzed, dying, stable, unconscious - its turn still
begins and `_begin_turn` still runs, so the expiry fires and the pin ends on schedule;
the pinner simply cannot attack, pin again, or escape anything that turn. If the pinner
dies, is turned, or the encounter ends, the pair is cleared and the pin with it. If the
pinned creature is skipped (dying, paralyzed, dead), the pin still expires at the
pinner's next turn start, and a pinned creature that cannot act cannot escape.

A pinned creature that cannot act (dying, stable, unconscious, paralyzed) stays pinned,
cannot escape, and is released only by expiry, the holder's release, or cleanup. That
mirrors 8a's treatment of a held creature that cannot act.

### 3.3 The pinned action set (audited, not assumed)

| Action | Today while merely grappling | While pinned (this plan) |
| --- | --- | --- |
| Attack, any target | Partner only, –4, unarmed/natural/light (`:765-800`) | Refused: "pinned and can take no action except to escape". |
| Escape | Standard action, opposed or Escape Artist (`:2069`) | Allowed; success clears the pin only and leaves the pair. |
| Move, 5-ft step, stand | Refused (`:490` covers move and the 5-ft step, `:1207` stand) | Refused by the same grapple message. |
| Cast spell | Refused by scope (`:3308-3317`) | Refused; the pin message takes precedence so the player is not told to solve a scope limit. |
| Turn undead | Refused by scope (`:3843-3851`) | Refused with the pin message. |
| Potion | **Allowed** — `use_potion_active:3655` has no grapple check | Refused: this path must gain an explicit pin check; it is the audit gap. Administering a potion *to* a pinned ally by another character is unaffected. |
| First aid | Allowed — `stabilize_active:3716` has no grapple check | Refused with the pin message; the pinned character cannot take the action. |
| Total defense | Allowed — `total_defense:3063` has no grapple check | Refused with the pin message. |
| Draw, sheathe, load, pick up | Refused (`:937`, `:1004`, `:1157`, `:2499`) | Refused by the grapple message. |
| Free actions | Holder release only, free | Holder release is free and ends the whole hold (printed). No speech model exists, so the optional "unable to speak" clause is not implemented. |
| End turn | Allowed | Allowed. |

**Adaptation D — the pinner cannot attack at all.** The printed pinning restriction
forbids drawing or using a weapon while pinning; the printed alternatives (damage by
opposed check, use the opponent's weapon, move the grapple) are 8c and out of scope.
With those absent, the pinner's attack paths must refuse for the duration, including the
partner attack 8a allows. This is a real cost of pinning and must be stated in the
tooltip, not left as a surprise.

**Adaptation E — one escape action, two methods, standard action either way.** The
printed pin escape is "in place of an attack" for the grapple check and a standard action
for Escape Artist. With one attack per turn there is nothing to replace, so both methods
cost the standard action here, consistent with 8a's escape.

### 3.4 The –4 AC rule

Add `Encounter.pinned_ac_penalty(target_index, attacker_index) -> int`, returning 4 when
the target is pinned and the attacker is **not** the pinning holder, otherwise 0.

- `denies_dex_to` gains the pinned case: a pinned creature loses Dexterity against every
  attacker except its holder. This is the printed Dexterity half and already exists for
  non-partners.
- `Rules.armor_class` and `Rules.touch_ac` gain a `pinned_penalty` option subtracted from
  AC, so the touch attack path agrees with the normal one (`rules.gd:258`, `:294`).
- `_attack_context` (`encounter.gd:2771-2810`) computes both: `deny_dex` for
  non-holders, `pinned_penalty` only for non-holders. The pinner passes neither, so the
  penalty is never double-applied and never applied to the pinning creature.
- The penalty is a plain AC penalty, not flat-footed: sneak-attack eligibility and the
  flat-footed flag are untouched, exactly as 8a's `deny_dex` is.

### 3.5 Escape from a pin, release, and the AI

- A pinned creature's `Escape` performs the pin escape: opposed grapple check (or
  untrained Escape Artist), standard action, same modifiers as 8a, log line
  "escapes the pin; still grappling" on a win and "fails to escape the pin" on a loss.
  A win clears `pinned` only; the pair and the –4 against third parties end together
  because both come from the flag.
- The holder's `Escape` remains the free release, and per the printed release rule it
  ends the whole hold ("no longer grappling"), not just the pin. There is no
  release-the-pin-but-keep-the-hold action: it would need a second control, and both
  printed releases are free, so the simpler control is also legal.
- **Adaptation F — the AI's pinned turn.** `_run_monster_turn`'s escape branch becomes:
  if pinned, attempt the pin escape; a win leaves the creature grappled and the turn
  ends because the standard action is spent; a loss ends the turn pinned. The monster
  never attacks while held or pinned, which is 8a's policy and is not changed here.
  Shipped consequence: a pinned zombie or ghoul loses a second round of actions before it
  can even attempt the grapple escape.

### 3.6 Breaking another's pin

**Deferred, and explicitly not modelled now.** Breaking a pin requires a third creature
that is already part of the same grapple and a target-selection rule among participants;
the current model is one pair, and `grapple_active` refuses a creature already in a
grapple (`:1907-1911`). Introducing a break-pin action without that model would mean
implicit multiple-grappler state, which the plan forbids. The only permitted behaviour is
recorded: a third party attacking a pinned creature gets the –4 and the Dexterity denial,
and cannot break the pin.

### 3.7 Cleanup

Every existing transition already operates on the pair, so the flag cannot outlive it:
death of either participant (`_prune_grapples`, `:441`), turning
(`_run_turned_turn`, `:4114-4119`), encounter finish (`:4349-4351`), and the holder's
release (`_remove_pair`, `:425`). The new expiry is the only additional transition:
start of the pinner's next turn clears `pinned` and logs it. `begin()` clears
`grapples` wholesale (`:145`), so an encounter restart has no pin.

## 4. Player effect in shipped content

All three shipped monsters are undead, so the hold deals no damage and the pin adds no
damage either; no new damage benefit is claimed. The current value of 8a's hold is that a
grappled monster's whole turn is one escape attempt: on a success it is free that same
turn. With pin, that turn becomes a pin escape; a success leaves it **still grappled**, so
it has not escaped the hold, and a failure leaves it pinned and unable to act. In shipped
fights (2 HD zombies, the ghoul, the 6 HD infected zombie; escape checks +2 to +6) the
pin costs the player's standard action and all of the player's attacks while pinning,
and in return it can deny the monster a normal turn and make a successful pin escape
leave it still held. How much that is worth depends on turn order and on the escape
rolls; no fixed extra round is promised. That is the incremental effect, and it is
small because the fights are short and no monster initiates a grapple.

No selectable-feat reachability is claimed. Improved Grapple remains raw-feat text only;
`FEATS_SKILLS_COVERAGE.md:191` records that neither it nor Improved Unarmed Strike is in
`Feats.CATALOG`, and the only supported level step is 3rd to 4th, where only the fighter
gains one feat — not enough for a two-feat chain.

## 5. UI: the Pin control, Escape, enable rules, refusals

- **New control**: `Pin`, added immediately after `Grapple` in the action grid
  (`combat_screen.gd:258-286`). It needs no target mode: the partner is fixed, so the
  button calls the wrapper directly, like `Escape`. That also means the probe drives it
  by button activation only, with no board click — a different input path from 8a's
  initiation, and it must be described that way in the evidence.
- **Enable rule**: `"Pin": standard and active is the holder and the partner is not
  already pinned`. `Escape` keeps its current rule (`player_turn and grappled`) and its
  stable label, because the enable map is keyed by the label text (`:656`).
- **Tooltips**: `Pin` states the cost and the cost of pinning: "Hold the creature you
  are grappling immobile for 1 round (standard action). While pinning you cannot attack.
  PHB p.156." `Escape`'s tooltip becomes role-aware: pinned → "attempt to escape the
  pin; a success still leaves you grappling"; holder → "let go for free; releasing a pin
  also ends the hold"; held → the existing text.
- **Refusals**, each naming its reason:
  - pinned actor: "%s is pinned and can take no action except to escape (PHB p.156)."
    for attacks, potions, first aid, total defense, casting and turning;
  - pinner: "%s is pinning %s and cannot attack (PHB p.156).";
  - not the holder: "Only the creature holding the grapple can pin.";
  - no grapple: "%s is not grappling.";
  - already pinned: "%s is already pinned.";
  - no standard action: the existing standard-action message.
- **Layout**: the grid gains one control, 31 → 32. The sidebar's reserved scrollbar
  carries the new row at 1280×720 at both 100 % and 160 %; the layout probe must show 32
  controls, 0 failures, and the deliberate count change is recorded rather than assumed.
  No new focus system: the button joins the existing grid and its focus order.

## 6. Failing-first tests and probe extensions

`tests/test_pin.gd`, written before the implementation and run to a logged failure first.
Red evidence must be the logger's text (for example a parse error naming
`pin_active()` as missing, or a GUT failure line), never the exit code.

Planned cases, roughly 24:

1. successful pin records `pinned`, spends the standard action, logs both totals;
2. a lost pin check leaves the pair and the flag unchanged and spends the action;
3. a second pin in the same turn is refused;
4. a pin while already pinned is refused by name;
5. a held creature cannot pin;
6. a non-participant cannot pin;
7. pin without an existing grapple is refused;
8. pin against a dead partner is refused;
9. pinned AC: –4 against a third party, 0 against the pinner;
10. pinned AC applies to touch AC too;
11. pinned keeps Dexterity against the pinner and loses it against others (no double
    penalty, not flat-footed);
12. pinned attack refused (partner and third party);
13. pinner attack refused while pinning;
14. pinned move, step, stand, pick up, sheathe, load refused;
15. pinned casting and turning refused with the pin message;
16. pinned potion refused; a potion given to the pinned creature by an ally still works;
17. pinned first aid and total defense refused;
18. pin escape success clears the pin, keeps the pair, spends the standard action;
19. pin escape failure stays pinned and spends the action;
20. Escape Artist pin escape uses the skill and no grapple bonus;
21. holder release ends the pair for free, pinned or not;
22. pinned AI attempts the pin escape and does not attack; success leaves it grappled
    and ends its turn;
23. expiry at the pinner's next turn start, tested for both supported initiative
    orderings (pinner before and after the pinned creature) and for a pinner that cannot
    act, without asserting a fixed number of pinned turns;
24. death, turning and encounter finish clear a pinned pair; pinned dying cannot escape
    and the pin survives until expiry.

`--grapple-probe` extension (no new demo flag, same `--demo-unarmed` fixture), with the
input path labelled each time:

- P1 — player pins the shipped zombie through the `Pin` button (button activation only);
  assert the flag, the standard action, the log, and that the pair survives.
- P2 — third-party AC: assert `pinned_ac_penalty` is 4 for the brawler and 0 for the
  holder, and that `Rules.armor_class` with the option differs by 4 (direct state check,
  disclosed; no third-party attack exists between the two enemies).
- P3 — pinned refusals: partner attack through the Attack button and pointer (refused by
  name), potion and first aid as direct `Game` calls, total defense and casting as direct
  calls; each message recorded.
- P4 — pin escape: end turn so the pinned zombie takes its AI turn; assert the pin
  escape line, no attack, and that a success leaves it grappled.
- P5 — release: on the player's turn, `Escape` releases the hold for free and clears the
  pair.
- P6 — expiry: pin again, cycle turns, and assert the pin clears with its log line at the
  player's next turn start.
- P7 — cleanup: pin, then the existing turning, death and finish scenarios assert the
  pair clears with the pin.

## 7. Acceptance, source checks and candidate

For the eventual implementation batch:

- `tests/test_pin.gd` green, `tests/test_grapple.gd` and
  `tests/test_save_recovery.gd` unchanged and green, full suite green, both validators
  PASS;
- `--grapple-probe` extended and PASS, with its check count recorded;
- combat layout at 1280×720 on 100 % and 160 %, **32 controls, 0 failures**, the count
  change stated deliberately;
- `--level-up-probe` and `--advancement-probe` PASS (unaffected, but they run);
- one exported candidate with a source commit, working-tree state, byte size and full
  SHA-256 matched to `BUILD.txt`, hash identical before and after every run, and the
  probe, validators, both probes and both layout scales run from the executable;
- docs: `SUPPORTED_FEATURES.md`, `TRACEABILITY.md`, `ADAPTATION_LOG.md`, progress and test
  records, and the candidate ledger.

No content, schema, save policy, award, threshold or XP change. No manual testing, no
backup changes, no README change, no push.

## 8. Batches

**8b-1 — pin (the first batch, and the only one this note proposes).** Everything in
§3-§7: pair flag, `pin_active`, the pinner and pinned restrictions (including the potion,
first aid and total-defense gaps), –4 AC and Dexterity composition, pin escape, release,
AI pinned turn, expiry, cleanup, `Pin` control, tooltips, layout 32, `tests/test_pin.gd`,
the probe extension and the records. It is player-reachable and is accepted only with
the exported probe, so it cannot be split into engine-only and UI halves while both are
independently acceptable.

**8b-2 — breaking another's pin.** Deferred until a multiple-participant grapple model
exists (8f territory). It is not started here and needs its own plan: joining, choosing a
target among participants, and what "break" leaves behind for every participant.

Casting/Concentration (8d), any AI attack-policy change (8d), the selectable feat chain
(8e) and multiple grapplers (8f) stay out. Nothing in the pin scope depends on them: the
pin uses the existing grapple check, the existing pair clearing and the existing escape
wrapper. If that changes during implementation, report the dependency instead of
expanding the batch.

## 9. Classification, kept separate

- **Confirmed defects:** none known in executable grapple behaviour after batch 8a. The
  potion/first-aid/total-defense paths are not defects while merely grappling; they are
  the audit gaps pin must close for a pinned actor, and closing them is part of 8b-1.
  `GRAPPLE_PLAN.md`'s earlier potion claim was already corrected in `dfadbe3`.
- **Deferred features:** pin damage, use-opponent's-weapon, moving a pinned creature
  (8c); casting/Concentration and monster attack policy (8d); the feat chain (8e);
  break-pin, joining and multiple grapplers (8f).
- **Maintenance debt:** `Feats.CATALOG.combat_casting`'s benefit text still says
  "grappling and pinned are not modeled" (`src/core/feats.gd:49`); grappling is modelled
  and pinning will be, but the bonus stays unreachable because casting from a hold is
  refused. This note does not change it. A second predicate for refusals must reuse the
  `_grapple_blocks` shape rather than copying messages, and the pin must not add a second
  pair array or a `Character` condition.
- **Evidence gaps:** no living opponent in shipped content, so pinned-hold damage is
  still untested against a living creature and pin adds no damage anyway; exported pin
  behaviour will exist only through the extended probe at 1280×720 headless; raw feat
  text seeded by tests and the probe is not player reachability; no human playtesting is
  planned or requested.

## 10. Implementation record (batch 8b-1, 2026-11-24)

**What shipped.** `Encounter.pin_active()` is a standard action available only to the
holder of an existing pair. It rolls the existing opposed grapple check; a win records
`pinned` on that pair and logs both totals, a loss leaves the pair and flag untouched.
`_begin_turn` clears the flag at the start of the pinner's next turn, even when that
pinner cannot act. A pinned creature is refused attacks, movement, steps, standing,
pick-up, sheathe, load, casting, turning undead, potions, first aid and total defense by
name, while another creature may still administer a potion to it. `grapple_exit`'s pinned
branch clears only the flag for either method (opposed check or Escape Artist), and the
holder's release still clears the pair. Third parties take the printed -4 to normal and
touch AC through `pinned_penalty` in `Rules.armor_class`/`touch_ac`, passed by
`_attack_context`; the pinner is excluded and the existing Dexterity denial, flat-footed
and sneak-attack behavior are unchanged. The AI attempts a pin escape and takes no attack.
The UI adds a stable `Pin` button and role-aware `Escape` tooltips, so combat layout is
32 controls at both scales.

**Adaptations.** A (standard action), B (the pinner keeps its square), C (expiry at the
pinner's next turn start, including an unable pinner), D (the pinner cannot attack, and
the pinned action set is refused by name), E (one escape action, two methods, pin only),
F (the AI's pinned turn). `ADAPTATION_LOG.md` records them as 71-77.

**Evidence.** `tests/test_pin.gd` 30/30 (94 asserts; red run `builds/qa/pin_red_1.log`
recorded 30 failing with `Nonexistent function 'pin_active'`), full suite 966/966 (9,737
asserts), both validators, `--grapple-probe` 147 checks, combat layout 32/0 at 100 % and
160 %, `--level-up-probe` (349 checks) and `--advancement-probe`. Candidate
`2026-11-24_batch8b1_acceptance_c`, source `f149d1d`, 110,885,688 bytes, SHA-256
`8f9de152fa89b1c273eaf85208826c3645216170e759a925b1cf1a3b781aa2e0`, `worktree_entries=1`
(the preserved README removal only), hash equal to `BUILD.txt` and unchanged before and
after every run; the probe, validators, both probes and both layout scales PASS from the
exe.

**Classification.** Confirmed defects: none. Deferred: break-pin (8b-2), pin damage,
opponent's weapon and moving a pin (8c); casting/Concentration (8d); the feat chain (8e);
joining and multiple grapplers (8f). Maintenance debt: the stale `Combat Casting` benefit
text; `Game.combat_turn_undead()` calls `auto_advance()` after a refusal, so the probe
uses `Encounter.turn_undead()` for a pinned turn (no player-reachable difference, not
changed here). Evidence gaps: the AI never pins and no pinned ally arises in play, so
those states are seeded; exported behavior exists only through the 147-check probe at
1280x720 headless; no rendered appearance, ordinary combat feasibility or human
playtesting is claimed.
