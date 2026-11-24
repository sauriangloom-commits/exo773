# Player-initiated grapple — implementation plan

**Status: implemented 2026-11-23 (batch 8a)** for the initiation, grappled-state and
escape sections. Tests were written and run failing first, then the engine, the `Game`
wrappers and the two sidebar buttons were added. §3-§9 are what shipped; the notes below
record where the code is more specific than the plan and where the acceptance evidence
lives. Pin, the remaining printed actions, casting from a grapple, the feat catalog entry
and multiple grapplers (§10, 8b-8f) remain unimplemented. Batch 8a is **closed as
accepted 2026-11-24** within the evidence recorded in `514ebc9`, including the exported
98-check `--grapple-probe`; no checks were run for that closure. Candidate identity:
`2026-11-24_batch8a_acceptance_b`, source `a71b942`, 110,874,840 bytes, SHA-256
`6d7e0df7e071115c190a6ede40d965e6a28893fe92ce73f72e885f5438debd92`.

**Implementation notes.** The automatic hold damage reuses a new `Rules.roll_damage`,
extracted from `Rules.attack` so there is one damage path and the attack results are
unchanged. `_provoke_single_opportunity` now returns its attack result, because only "did
the reaction deal damage" decides the attempt (PHB p. 155). Escape and release share one
control; the holder's release is free and rolls nothing, while a held creature spends its
standard action on the check. The AI escape attempt goes through the same wrapper, so a
failed escape ends the monster's turn with no attack. No save field exists: combat is not
saved at all.

**Acceptance probe (2026-11-24).** `--grapple-probe` confirms initiation resolves inside
the turn and needs no pending decision, as section 4 specified, and exercises the printed
sequence, the partner attack, the refusals, escape and release, the AI escape, and the
turning, death and finish cleanup. It also confirms the living-target hold damage, which
no shipped campaign can reach because all shipped monsters are undead.

Scope: a player-initiated grapple against one defender, as a standard action, with the
grappled state and an escape attempt for either participant. Pin, pin damage,
constriction, multiple grapplers, joining a grapple, monster-initiated grapple,
improved grab and swallow whole are out (see §10).

## 1. Printed rules, verified

Sources: 3.5 System Reference Document, Combat → Special Attacks → Grapple
(d20srd.org, which reproduces the PHB text), PHB pp. 155-157 for the special attack,
and the SRD/PHB feat entry for Improved Grapple (PHB p. 95). The page numbers follow
the printed index ordering the repo already uses for trip (pp. 158-159) and bull rush
(p. 154) and should be confirmed against the printed index when the batch opens, as
`BULL_RUSH_PLAN.md` requires for its own citations. The quoted fragments below are the
SRD's own wording.

| Element | Printed rule | Consequence for this engine |
| --- | --- | --- |
| Action | "Starting a grapple requires a successful melee attack roll." | The attack action, so a standard action. Iterative attacks are deferred, so one attempt per turn; the printed "if you get multiple attacks, you can attempt to start a grapple multiple times" clause is out. |
| Step 1 — reaction | "You provoke an attack of opportunity from the target you are trying to grapple. If the attack of opportunity deals damage, the grapple attempt fails. (… nor do characters with the Improved Grapple feat.)" | Resolved before the touch attack through `_provoke_single_opportunity` (`encounter.gd:2684`). That helper must hand back its attack result so "deals damage" can be tested; today it returns nothing. |
| Step 2 — grab | "You make a melee touch attack to grab the target. If you fail to hit the target, the grapple attempt fails." | `Rules.attack` with `touch: true` (`rules.gd:699-711`), exactly as trip does (`encounter.gd:1204-1214`), using the unarmed strike as the pseudo-weapon. |
| Step 3 — hold | "Make an opposed grapple check as a free action. If you succeed, you and your target are now grappling, and you deal damage to the target as if with an unarmed strike. If you lose, you fail to start the grapple. You automatically lose an attempt to hold if the target is two or more size categories larger than you are. In case of a tie, the combatant with the higher grapple check modifier wins. If this is a tie, roll again…" | `Rules.opposed_ability_check` (`rules.gd:567`) already implements the PHB p. 64 tie procedure — higher modifier wins, then reroll — which is the printed grapple tie rule; no new tie code. Size and base attack enter as `attacker_bonus`/`defender_bonus`. |
| Grapple check | "Base attack bonus + Strength modifier + special size modifier", with the special size modifier "Colossal +16, Gargantuan +12, Huge +8, Large +4, Medium +0, Small -4, Tiny -8, Diminutive -12, Fine -16". | New `Rules.grapple_size_modifier(category)`, computed as `4 * Rules.size_category_steps(category)` (`rules.gd:56`), which reproduces all nine printed values from the existing order. A test asserts every row of the printed table. |
| Step 4 — maintain | "To maintain the grapple for later rounds, you must move into the target's space. (This movement is free and doesn't count as part of your movement in the round.) … If you can't move into your target's space, you can't maintain the grapple and must immediately let go." | **Adaptation A**: the grid holds one creature per square, so the holder does not enter the target's square. The pair is linked by encounter state and both keep their own squares. The entry move is not performed, so the "cannot move in" clause cannot trigger. |
| Threatened squares | "You don't threaten any squares while grappling." | `threat_capability` (`encounter.gd:585`) returns empty for a grappled creature, so it grants no opportunity attacks. |
| Dexterity | "You lose your Dexterity bonus to AC (if you have any) against opponents you aren't grappling. (You can still use it against opponents you are grappling.)" | A new `deny_dex` option on `Rules.armor_class`/`touch_ac` (`rules.gd:251`, `rules.gd:283`) subtracts only a positive Dexterity modifier and denies Dodge, without setting flat-footed, so sneak attack is untouched. The encounter passes it only when attacker and target are not grapple partners. |
| Movement | "You can't move normally while grappling." | Move, 5-ft step and the `Stand up` action are refused while grappled, each with its own message. |
| Actions allowed | "you can perform any of the following actions": activate a magic item; attack your opponent with an unarmed strike, natural weapon or light weapon at -4; cast a spell (1 standard action, no somatic component, Concentration DC 20 + spell level); damage your opponent with an opposed check in place of an attack; draw a light weapon; escape; move half speed; retrieve a spell component; pin; break another's pin; use the opponent's weapon. | Batch 8a permits only the partner attack at -4 and the escape/release; movement, ranged attacks, attacks on third parties, `Pick up`, `Sheathe weapon`, `Load weapon`, `Stand up` and spellcasting are refused. §2 names which of those refusals are printed and which are scope. |
| Escape | "You can escape a grapple by winning an opposed grapple check in place of making an attack. You can make an Escape Artist check in place of your grapple check if you so desire, but this requires a standard action. … If you escape, you finish the action by moving into any space adjacent to your opponent(s)." | Escape uses the standard action (the attack action) and is open to either participant on its own turn. Escape Artist exists (`skills.gd:27`, untrained) and is offered as the standard-action alternative through `Skills.total` (`skills.gd:287`). Under Adaptation A the escaper already stands in an adjacent square, so no movement follows. |
| Release | "Opponents don't have to try to hold you if they don't want to." | The holder can let go as a free action on its turn; no check, no dice. |
| Improved Grapple | "You do not provoke an attack of opportunity when you make a touch attack to start a grapple. You also gain a +4 bonus on all grapple checks, regardless of whether you started the grapple." Prerequisites: Dex 13, Improved Unarmed Strike. | Hooks only in 8a: no Step-1 reaction and +4 on every grapple check, on either side. The feat is **not** added to `Feats.CATALOG` — see §2. |

### What the printed text does not say

These are **project adaptations**, not printed rules, and every one must be recorded
in `ADAPTATION_LOG.md` when the first batch lands. The bull-rush entries are 19i/19j;
this plan does not reserve numbers.

- **A — One creature per square.** The holder stays in its own square and the grapple
  is encounter state, not a shared cell. Escape therefore needs no follow-up move, and
  Step 4's entry is never performed.
- **B — Auto-loss timing.** A defender two or more size categories larger is rolled
  against on the touch attack (which can still miss) and then loses the hold
  automatically, without an opposed roll and without consuming dice for it. The
  printed text allows the attempt; the engine simply has no contested roll to make.
- **C — No somatic components.** The project models no spell components, so "no
  somatic component" cannot gate casting from a grapple. Spellcasting while grappling
  is refused by scope in 8a and its DC 20 + spell level path is deferred (§10, 8d).
  This is a scope decision, not a printed prohibition.
- **D — Turning overrides a hold.** A turned creature must flee, which it cannot do
  while held, so the pair separates and the state clears before the fleeing turn runs
  (`_run_turned_turn`, `encounter.gd:3607`). Nothing in the printed text covers it.
- **E — Death, dying and paralysis.** Death clears the state immediately. A dying,
  stable, unconscious or paralyzed held creature stays held and simply cannot escape;
  it is not released. Printed text covers only the voluntary release and the escape.
- **F — Grapple and bull rush do not mix.** A grapple attempt against a participant of
  an existing grapple, and a bull rush against one, are refused with a named message;
  there is no forced movement of a held creature and no multiple-grappler arithmetic.
  Trip stays legal: it is an independent condition.
- **G — Escape Artist is not a grapple check.** It uses the skill's own modifier and
  its own armor penalty, and it can be attempted untrained; no grapple bonus applies
  to it, including Improved Grapple's +4.

## 2. Engine surface, verified before planning

| Layer | Today | Addition |
| --- | --- | --- |
| Rules — size | `size_modifier` `rules.gd:41` (the size **AC** modifier), `size_category_steps` `rules.gd:56`, `SIZE_CATEGORIES`/`SIZE_ORDER` `rules.gd:16-30` | `grapple_size_modifier(category)` = `4 * size_category_steps(category)`, documented against the printed table. No new table. |
| Rules — opposed check | `opposed_ability_check` `rules.gd:567`, PHB p. 64 tie procedure, `attacker_bonus`/`defender_bonus` added to the ability modifier | Unchanged. Grapple passes `base_attack + size + feat` in those two bonuses with `["str"]` on both sides. |
| Rules — attack | `attack` `rules.gd:640`; touch selects `touch_ac` at `rules.gd:703-705`; damage roll inline at `rules.gd:771-791` | `deny_dex` option in `armor_class`/`touch_ac`; extract the damage block into `Rules.roll_damage(...)` so the hold's automatic unarmed damage reuses one path. `Rules.attack` keeps its current results; the suite is the guard. |
| Rules — AC | `armor_class` `rules.gd:251`, `touch_ac` `rules.gd:283` | `deny_dex` subtracts positive Dexterity and Dodge only, never sets flat-footed. |
| Encounter — actions | `trip_active` `encounter.gd:1123`, `resolve_trip_decision` `:1735`, `resolve_improved_trip_attack` `:1786`; `bull_rush_active` `:1423`, `resolve_bull_rush_decision` `:1624` | `grapple_active(target_index)` and `grapple_exit(use_escape_artist := false)` shaped the same way: guard block, spend the standard action on declaration, log, `_after_action`, `_check_end`, `changed`. |
| Encounter — state | `pending_trip` `:50`, `pending_cleave` `:52`, `pending_bull_rush` `:55`; `has_pending_decision` `:2007`; voided at `_begin_turn` `:225-233` and in `finish()` `:3827` | `var grapples: Array = []` holding `{holder, held}` indices, plus `is_grappled(index)` and `grapple_partner(index)`. No pending-decision entry: initiation resolves inside the turn. Cleared by `finish()` and by `begin()`, logged like the pending decisions. |
| Encounter — helpers | `_primary_weapon` `:535`, `threat_capability` `:585`, `_unarmed_strike` `:615`, `_apply_damage` `:2387`, `_provoke_single_opportunity` `:2684`, `_run_monster_turn` `:3462` | `_grapple_check_bonus(ch)` = `base_attack + Rules.ability_modifier(ch, "str") + Rules.grapple_size_modifier(size) + (4 with Improved Grapple)`; `_provoke_single_opportunity` returns its result (existing callers ignore it); `threat_capability` returns empty while grappled. |
| Feats | `has_feat` `feats.gd:618` (raw text, catalog-independent), `has_active` `:661`, `improved_trip_check_bonus` `:975` as the pattern, `improved_trip` catalog `:473` | `Feats.has_feat(ch, "improved_grapple")` inside `_grapple_check_bonus` and the Step-1 gate, following the Improved Unarmed Strike precedent (`feats.gd:614-618`). **No catalog entry**: the 42 catalog keys do not include `improved_unarmed_strike`, so Improved Grapple's prerequisite could never be selected and no content authors either feat. Tests author the raw feat text, as `test_unarmed_attack.gd:164` does. `FEATS_SKILLS_COVERAGE.md:190-191` records Improved Unarmed Strike as supported and Improved Grapple as deferred; the note changes from "deferred: grapple special attack" to "hooks implemented, feat not selectable". |
| Game wrappers | `combat_trip` `game_state.gd:1855`, `combat_resolve_trip` `:1866`, `combat_bull_rush` `:1877`, `combat_resolve_bull_rush` `:1888` | `combat_grapple(target_index)` and `combat_grapple_exit(use_escape_artist := false)`, same `last_ui_message` / `state_changed` shape. |
| UI | action buttons `combat_screen.gd:254-276` (`Trip` `:271`, `Bull rush` `:272`), enable map keyed by **button text** `:618-645`, cell dispatch `:699-717`, `_trip` `:782`, `_bull_rush` `:792`, `_set_mode` `:1175` | Two buttons, one new mode branch, no new modal. §8. |
| AI | `_run_monster_turn` `:3462` picks a nearest target, moves and attacks; turned monsters branch to `_run_turned_turn` `:3607` | Grappled monsters escape instead of attacking. §7. |
| Save | Combat is not saved; `save_game` writes characters only (`game_state.gd:488`) | No new save field. A battle in progress cannot be saved at all, so a grapple cannot outlive the process. |

## 3. Initiation sequence

Every refusal happens before anything is spent or rolled, matching trip and bull rush:

1. Refuse without an active combatant, with a pending decision, when the character
   cannot act or is paralyzed, when the standard action is spent, and when staggered
   blocks a standard action — the same guard block and message strings trip uses.
2. Refuse an invalid index, a dead or allied target, a target outside melee reach, a
   target already in a grapple (adaptation F), or an attempt against a creature that
   is already holding someone.
3. Spend the standard action on declaration, so an interrupted attempt still costs it,
   as trip and bull rush do.
4. Step 1: provoke the target's opportunity attack unless it cannot act or the holder
   has Improved Grapple. If the reaction deals damage, log the failure, run
   `_after_action` and `_check_end`, and return — no touch attack, no opposed check.
5. Step 2: roll the melee touch attack with the unarmed strike at `touch: true`. A miss
   ends the attempt; the action stays spent.
6. Size gate: if the defender is two or more size categories larger, log the automatic
   loss of the hold (adaptation B) and finish without an opposed roll.
7. Step 3: opposed grapple check. Log both totals, the ability used and each modifier
   separately, in the shape trip's check line uses. A loss ends the attempt.
8. A win records `{holder, held}` in `grapples`, deals the automatic unarmed-strike
   damage through `Rules.roll_damage` and `_apply_damage`, logs the pair, then runs
   `_after_action`, `_check_end` and `changed`.

Nonlethal consequence, stated once here because it decides every shipped fight: the
hold's damage is unarmed damage, which is nonlethal (`encounter.gd:577-600`,
`rules.gd:197`), and all three shipped monsters are undead, so the automatic damage is
ignored against every one of them. Only a holder with Improved Unarmed Strike, dealing
lethal by choice, would change that, and no shipped character has it.

## 4. The grappled state

Stored on the encounter, not on `Character`: a condition would ride `to_dict` into a
save (`character.gd:638`) and combat is not saved at all. The state ends when either
participant escapes, the holder releases, either participant dies, either is turned,
or the encounter finishes; each of those logs its own line.

Forbidden while grappled, each with a named refusal:

- `Move`, `5-ft step` and `Stand up` — printed "you can't move normally".
- Any attack against a creature other than the grapple partner, including ranged
  attacks — printed action list is exhaustive and names only "attack your opponent".
- `Pick up`, `Sheathe weapon`, `Load weapon` — not in the printed list; arms are
  occupied by the hold.
- Spells and `Turn undead` — refused by scope in 8a (adaptation C); the printed spell
  path needs components and a DC 20 + level check the engine cannot yet express.
  Potions stay permitted through the existing potion path, which spends the standard
  action and provokes; 8c extends that path to the other magic items PHB p.156 lists.
  An earlier version of this section said potions were refused; that was wrong and is
  corrected here, with no code change (see `ROADMAP.md`, grapple follow-up review).

Permitted:

- `Attack` against the partner only, at -4, with the unarmed strike, a natural weapon
  or a light weapon. Other weapon modes are refused with a message naming the printed
  restriction.
- `Escape` (or Escape Artist) as a standard action.
- `Release` for the holder, free.
- `End turn`.
- Being attacked by third parties, which is where she loses her Dexterity bonus
  against them (adaptation J) while keeping it against the partner.

## 5. Escape and release

- Hidden creature's turn: `Escape` spends the standard action and rolls an opposed
  grapple check (Strength-based, same modifiers as initiation, including Improved
  Grapple's +4 if present). The Escape Artist alternative spends the same action and
  uses `Skills.total(ch, "escape_artist")` with no grapple bonus (adaptation G).
- Success clears the pair and logs who got free. Failure keeps the hold and spends the
  action; the creature can still end its turn, and its Dex denial against others
  persists.
- An escape attempt made by a creature that cannot act (paralyzed, dead, dying) is
  refused before the roll.
- The holder's `Release` costs nothing, rolls nothing, and clears the pair on its own
  turn. It exists because the printed rule says opponents do not have to hold you.
- Only one escape or release per turn: iteratives are deferred, so there is no printed
  "in place of each attack" chain.

## 6. Death, dropping and turning

| Event | Decision |
| --- | --- |
| Holder dies or is destroyed | Clear the pair immediately, before `_check_end`, and log it. The held creature is free and its turn is unaffected. |
| Held creature dies or is destroyed | Clear the pair and log it. `_check_end` then resolves victory normally. |
| Held creature drops to dying, stable, unconscious or paralyzed | Keep the hold; the creature cannot escape while it cannot act but is not released. If the encounter ends, `finish()` clears the state with the other pending state and logs it. |
| Either participant is turned | Clear the pair before the fleeing turn runs (adaptation D), so `_run_turned_turn` never tries to move a held creature. |
| Holder falls prone (trip) | The hold survives; prone is an independent condition. The holder cannot stand while grappling (movement refused), which is the printed consequence. |
| Encounter finishes for any reason | `finish()` clears `grapples` alongside the pending decisions and logs one line. |

## 7. Who may initiate, and every shipped monster

**Decision: the AI never initiates a grapple in any batch of this plan.** The AI acts
only as the defender: on its turn, a grappled monster attempts to escape; if the escape
fails, its turn ends without an attack. Monster-initiated grapple, improved grab and
swallow whole are deferred until content authors a creature that needs them, and no
shipped monster does. This is what keeps the batch bounded and keeps the touch attack,
the reaction and the size gate on one code path.

Consequences for every shipped monster (`content/shared/monsters.json`):

| Monster | Grapple check | Behaviour under this plan |
| --- | --- | --- |
| `zombie` (2 HD, CR 1/2, Medium, Str 12, BAB +1) | +2 | Never initiates. Grappled, it spends its **whole** turn on one escape attempt (it is single-action-only), then stops. Being undead, it ignores the hold's nonlethal damage. It cannot be disarmed or sundered; it owns no weapon. |
| `infected_zombie` (6 HD, CR 2, Medium, Str 17, BAB +3) | +6 | Same as the zombie with a stronger check: one escape attempt per turn, no attack, immune to the hold's nonlethal damage. Its authored disease stays deferred and unused. |
| `ghoul` (2 HD, CR 1, Medium, Str 13, BAB +1, Dex 15) | +2 | Never initiates. It is not single-action-only, but under this plan it still spends its turn escaping, so its bite/claw paralysis (DC 12, implemented) **cannot trigger from a grapple** — the natural-weapon attack from a grapple is deferred to §10, 8d. If turned while holding, the grapple clears and it flees. |

A player character grappling any of them deals no damage with the hold itself (all
three are undead) and gains control of the monster's action for as long as it fails to
escape, which is the real tactical value of the batch until content adds a living
opponent.

## 8. UI and keyboard path

- `Grapple` joins the action grid beside `Trip` and `Bull rush`
  (`combat_screen.gd:271-272`), one word, enabled by `"Grapple": standard` in the
  enable map (`:618-645`) exactly as `Trip` is.
- `Escape` is a second button, enabled only when the active character is in a grapple.
  **Its label stays `Escape` even when the actor is the holder**, because the enable map
  is keyed by `button.text` (`:645`, `:653-657`); a label that changed with the role
  would silently lose its enable entry. The tooltip and status line explain that the
  holder releases while the held creature escapes, and one wrapper decides which
  happens.
- One new `mode == "grapple"` branch in `_on_cell_clicked` (`:699-717`) refusing
  anything but a living enemy, and calling `Game.combat_grapple(index)`; refusal
  messages reuse `Game.last_ui_message` and `refresh_screen`.
- No new modal, no new focus system, no arrow-key handling, no board overlay in 8a.
  The grapple is reported in the log and by the `Escape` button's presence. The target
  list marker is deferred polish.
- **Keyboard today:** combat has none of its own. `main.gd:9739` handles rebinding,
  modal scrolling, modal focus cycling and modal `ui_accept`; nothing else. Buttons get
  Godot's built-in Tab focus and Enter/Space activation; board squares are mouse-only
  (`CombatView.cell_clicked`). The two new buttons inherit exactly that path, so
  keyboard reach is "Tab to the button, Enter to arm it, click a square" — unchanged
  from `Trip`.
- **1280×720 at 100 % and 160 %:** the grid is four columns inside a 340 px sidebar
  with horizontal scrolling disabled and a permanently reserved vertical bar
  (`:112-142`), so two more buttons add a fifth row that the sidebar scroll already
  reaches. `Grapple` (7 characters) and `Escape` (6) are shorter than the existing
  worst-case label `Sheathe weapon`, so the grid's minimum width does not grow; no
  new minimum size, no new control type, nothing to reflow. The check is the existing
  `--layout-probe --layout-scenario=combat` at both scales, whose control count rises
  from 29 to 31 and must still report 0 failures.

## 9. Tests, probes and red evidence

New `tests/test_grapple.gd`, built on `test_trip.gd`'s harness: a `ContentDB`
character and monster, a walled map from `BattleMap.from_rows`, `Encounter.new()` with
`setup(...)`, a seeded `RandomNumberGenerator`, and `_force_turn`. A `_seed_for(check)`
helper searches seeds 1-200 and pins the found value as a constant, so an RNG or
modifier change fails loudly.

| # | Test | Asserts |
| --- | --- | --- |
| 1 | `test_a_won_hold_records_the_pair_and_spends_the_action` | `grapples` holds the two indices, `standard_used`, log lines, `is_grappled` on both sides |
| 2 | `test_the_hold_deals_unarmed_damage` | a living fixture loses HP equal to the logged unarmed roll; nonlethal flag set |
| 3 | `test_a_dead_undead_defender_takes_no_hold_damage` | zombie fixture HP unchanged, log says the damage is ignored |
| 4 | `test_a_missed_touch_attack_ends_the_attempt` | no pair, standard spent, "touch attack misses" line |
| 5 | `test_a_damaging_reaction_fails_the_attempt_before_the_touch` | reaction logged, no touch roll, no pair, `aoo_used` set |
| 6 | `test_a_missed_reaction_allows_the_touch_attack` | pair recorded, reaction line present |
| 7 | `test_improved_grapple_removes_the_reaction_and_adds_four` | raw feat text fixture: no reaction line, defender total 4 higher than the same seed without it |
| 8 | `test_a_defender_two_size_categories_larger_loses_the_hold_automatically` | touch rolled, no opposed line, message names the size rule |
| 9 | `test_grapple_size_modifiers_match_the_printed_table` | all nine categories: Fine -16 … Colossal +16 through `Rules.grapple_size_modifier` |
| 10 | `test_the_grapple_check_uses_base_attack_strength_and_size` | logged modifier equals BAB + Str + size for a non-Medium fixture |
| 11 | `test_a_tie_with_equal_modifiers_rerolls` / `test_a_tie_with_a_higher_modifier_wins` | `rerolls`, `tie_broken_by` |
| 12 | `test_escape_succeeds_and_clears_the_pair` | pair cleared, log line, standard spent |
| 13 | `test_escape_fails_and_keeps_the_hold` | pair intact, standard spent, failure line |
| 14 | `test_escape_artist_uses_the_skill_without_the_grapple_bonus` | the Dex path's total differs from the grapple path by the expected modifiers |
| 15 | `test_release_is_free_and_needs_no_roll` | pair cleared, no dice consumed, no standard spent |
| 16 | `test_a_grappled_creature_cannot_move_or_step` | `Move`/`5-ft step`/`Stand up` refusals, turn state untouched |
| 17 | `test_a_grappled_creature_cannot_attack_a_third_party` | refusal message, no attack logged |
| 18 | `test_attacking_the_partner_takes_four` | hit rolls carry -4, only unarmed/light/natural modes accepted |
| 19 | `test_a_grappled_creature_threatens_nothing` | moving enemy past it provokes nothing |
| 20 | `test_a_grappled_defender_loses_dex_to_third_parties_only` | third-party AC 2 lower on a Dex 14 fixture; partner attack unchanged |
| 21 | `test_a_grappled_monster_escapes_and_does_not_attack` | monster turn: one escape attempt, no attack line, turn ends |
| 22 | `test_turning_a_held_monster_clears_the_grapple_first` | no pair when the fleeing turn starts |
| 23 | `test_death_of_either_participant_clears_the_grapple` | both directions, log line, `_check_end` result |
| 24 | `test_finish_clears_grapples_and_logs` | victory path, empty `grapples`, one log line |
| 25 | `test_a_pending_decision_blocks_a_grapple` and `test_a_grapple_is_refused_against_an_existing_grapple` | the two guards |

Game-level, in the batch that touches saving (see below), not in `test_grapple.gd`:
`test_reloading_the_pre_apply_autosave_reapplies_the_level` — reach the threshold
through a QA victory, let the victory autosave write, reload `auto`, apply the same
draft, reload again and apply once more. It verifies behaviour the engine already has:
victory pays XP before `save_game("auto")` (`game_state.gd:1734-1756`), and
`LevelUp.apply` mutates only the loaded character, so the reloaded autosave re-offers
the step. **No new save policy and no new save field.** It belongs in
`tests/test_save_recovery.gd` or the level-up flow tests rather than in this plan's
first batch, per the roadmap review.

Red evidence: the failing run is recorded by its **logged failure text** — for example
`Static function "grapple_size_modifier()" not found in base "Rules".` — and by the
runner's PASS/FAIL lines. The exit code is not evidence and must not be quoted as the
red result.

Probes and candidate, in the shape bull rush used:

- Source tree: focused `tests/test_grapple.gd`, then the full suite, then
  `--validate-campaigns` and `--validate-diagnostics`, each recorded with its output
  and its PASS/FAIL text.
- `--layout-probe --layout-scenario=combat` at 1280×720 on 100 % and 160 %, 31
  controls, 0 failures.
- One exported candidate from the clean batch commit: both validators from the exe,
  the same layout scenario at both scales, and the executable's SHA-256 recorded before
  and after and required to match.
- No new `--demo-*` flag: the rules are covered by the suite, and the probe would show
  layout, not grapple outcomes.

## 10. Ordered batches

Each batch is independently acceptable: it leaves the suite green, the validators
passing and the game shippable, and the next one is not required for it to be correct.
**The first is 8a.**

**8a — grapple and escape (the first batch, shipped 2026-11-23).** Everything in §3-§8: initiation
(touch, reaction, size gate, opposed check, hold damage), the grappled state and its
allowed/forbidden actions, escape and release for both sides, the AI's escape-only
turn, death/turn/finish cleanup, the two buttons and one mode branch, the wrappers, the
`Rules` additions (`grapple_size_modifier`, `deny_dex`, `roll_damage` extraction), the
`threat_capability` and `_provoke_single_opportunity` changes, `tests/test_grapple.gd`,
the docs rows, the layout runs and the candidate. Improved Grapple's hooks ship here;
its catalog entry does not.

**8b — pin.** Opposed check in place of an attack; "held immobile for 1 round"; -4 AC
against everyone but the pinner; escape from the pin still leaves the creature
grappling; break another's pin; voluntary release of a pin as a free action. No pin
damage, no use-opponent's-weapon. Needs 8a.

**8c — the remaining printed grapple actions.** Damage your opponent with an opposed
check (nonlethal by default, -4 for lethal), use the opponent's light weapon, move the
grapple at half speed, draw a light weapon, retrieve a spell component, activate a
magic item beyond the existing potion path. Needs 8a and 8b.

**8d — casting from a grapple, and the monster's natural weapon.** Concentration DC 20
+ spell level, with the component question recorded as an adaptation; and letting a
grappled monster attack its holder with a natural weapon at -4, which is what makes the
ghoul's paralysis reachable from a hold. Needs 8a.

**8e — the feat chain.** `improved_unarmed_strike` and `improved_grapple` into
`Feats.CATALOG` with their printed prerequisites so the +4 can be chosen at level-up;
today neither is selectable and no content authors either. Independent of 8a but
pointless before it.

**8f — multiple grapplers, joining, and monster-initiated grapple.** Four-per-round
arithmetic, joining an existing grapple, improved grab and swallow whole. Deferred
until content authors a creature that needs them; no shipped monster does.

### Exclusions, carried from the roadmap review

No disarm, sunder, concealment, hard cover, AoE templates, encumbrance or disease. No
content, schema, save, threshold or award change. No prompt change, no new save field,
no new `--demo-*` flag, no manual testing, no backup changes. Pin, pin damage,
constriction, multiple grapplers, monster-initiated grapple, improved grab and swallow
whole are excluded from 8a and scheduled above.

## 11. Classification, kept separate

- **Confirmed defects:** none. Nothing in this plan reproduces a reachable failure in
  the existing code; the stale `Encounter` header was a misleading comment, not a
  defect.
- **Deferred features:** everything in §10 from 8b on; Improved Grapple's selection;
  the shipped monsters' own special attacks (disease, ghoul fever); disarm, sunder and
  overrun; concealment and hard cover; AoE templates; encumbrance; iterative attacks;
  two-weapon fighting; readied actions.
- **Maintenance debt:** resolved in this commit — the `Encounter` header
  (`encounter.gd:6-14`) listed bull rush, trip, cover and turn undead as deferred, all
  four of which are implemented, and now says so. Debt this plan must not add: a second
  damage-roll path (hence the `Rules.roll_damage` extraction), a second threat
  predicate (hence `threat_capability`), a duplicated occupancy or movement rule, a
  `Character` condition that would ride into a save, and a text-keyed enable entry that
  changes with the actor's role (hence the stable `Escape` label).
- **Evidence gaps this plan leaves:** the exported binary's grapple behaviour is
  unproven (the probe shows layout only); no human playtest is planned or requested;
  every adaptation in §1 rests on a documented decision, not on SRD text; the hold's
  damage against a living opponent has no shipped opponent to exercise it; and the
  reload-then-reapply case is specified here but remains unwritten until the next
  save-touching batch.

## 12. Definition of done for 8a

Focused `tests/test_grapple.gd` green, full suite green, both validators PASS,
`SUPPORTED_FEATURES.md` and `TRACEABILITY.md` rows added, `ADAPTATION_LOG.md` entries
for adaptations A-G, `FEATS_SKILLS_COVERAGE.md` note that Improved Grapple is hooked
but not selectable, the combat layout scenario at 1280×720 on both scales, one exported
candidate with a bound before/after hash and both validators run from the exe, and the
candidate ledger updated. No manual testing, no backup changes, no README change.
