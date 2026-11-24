# Opposed-check tie audit

Status: **inspection only, 2026-11-24**. No executable, test, probe, content,
schema or save change was made. No tests, probes, validators, builds or exports
were run. This audit does not reopen the accepted trip, bull rush, grapple, pin or
escape behaviour; it records whether the shared helper's tie contract is correct
for each caller and what remains latent.

Related: `docs/OVERRUN_PLAN.md` §18 (overrun remains deferred), `docs/ROADMAP.md`,
`docs/GRAPPLE_PLAN.md`, `docs/PIN_PLAN.md`, `docs/FEATS_SKILLS_COVERAGE.md`.

## 1. Sources and rule categories

- PHB p. 64 / SRD Using Skills, Opposed Checks: the higher total wins; on a tie
  the **higher skill modifier** wins; if those are equal, roll again.
- PHB p. 158 / SRD Trip: opposed Strength check against the defender's better of
  Dexterity or Strength; size bonuses and the defender's stability bonus apply to
  the check. The trip text has no separate tie sentence.
- PHB p. 154 / SRD Bull Rush: opposed Strength checks; size bonuses and the
  defender's stability bonus apply. The bull-rush text has no separate tie
  sentence.
- PHB p. 155-156 / SRD Grapple: a grapple check is base attack bonus + Strength
  modifier + special size modifier. The Hold step says: "In case of a tie, the
  combatant with the higher grapple check modifier wins. If this is a tie, roll
  again to break the tie."
- Pin and escape are opposed grapple checks under the same grapple-check rules.

The distinctions matter:

- **Skill check:** p. 64 names the skill modifier.
- **Ability check:** p. 64 does not name an ability modifier. The project's
  documented reading (`Rules.opposed_ability_check`, `src/core/rules.gd:578-582`)
  substitutes the ability modifier for the missing skill modifier. That is a
  project interpretation, not a printed maneuver-specific exception.
- **Grapple check:** the printed rule is explicit and uses the full grapple check
  modifier (base attack + Strength + special size + applicable grapple bonuses).
- **Trip/bull rush:** no specific tie sentence; they inherit the general
  ability-check reading above, not the grapple rule.

No production caller is a skill check. Escape Artist is the separate skill-based
alternative for escaping a grapple; it uses `_escape_artist_check`, not this
helper, and is outside this audit.

## 2. The shared helper

`Rules.opposed_ability_check(rng, attacker, attacker_abilities, defender,
defender_abilities, opts)`:

- picks the best allowed ability modifier on each side;
- adds `opts.attacker_bonus` / `opts.defender_bonus` to form
  `attacker_modifier` / `defender_modifier`;
- rolls d20 + that modifier for the total;
- on equal totals, compares the two **full modifiers**;
- if those are equal, rerolls both d20s, up to 20 attempts, then returns
  `ok=false`.

It therefore compares the same value it adds to the total. There is no separate
"check modifier" and "tie-break modifier" input.

## 3. Production callers

All production callers are in `src/core/encounter.gd`. Tests call the helper
directly, but they are not production callers.

| Caller | Attacker abilities | Defender abilities | Attacker bonus | Defender bonus | Printed tie | Helper compares |
|---|---|---|---|---|---|---|
| `trip_active` (`:1442`) | `[str]` | `[str, dex]` | `4 * size_steps` + Improved Trip +4 | `4 * size_steps` + stability | ability modifier (project reading) | full modifier including size/feat/stability |
| `trip_active` counter (`:1502`) | `[str]` | `[str, dex]` | original defender's size + stability | original attacker's size | ability modifier (project reading) | full modifier including size/stability |
| `bull_rush_active` (`:1709`) | `[str]` | `[str]` | `4 * size_steps` | `4 * size_steps` + stability | ability modifier (project reading) | full modifier including size/stability |
| `grapple_active` (`:2058`) | `[str]` | `[str]` | `_grapple_bonus` | `_grapple_bonus` | higher grapple check modifier | full modifier = printed grapple modifier |
| `pin_active` (`:2163`) | `[str]` | `[str]` | `_grapple_bonus` | `_grapple_bonus` | higher grapple check modifier | full modifier = printed grapple modifier |
| `grapple_exit` pin branch (`:2251`) | `[str]` | `[str]` | `_grapple_bonus` | `_grapple_bonus` | higher grapple check modifier | full modifier = printed grapple modifier |
| `grapple_exit` escape branch (`:2333`) | `[str]` | `[str]` | `_grapple_bonus` | `_grapple_bonus` | higher grapple check modifier | full modifier = printed grapple modifier |

`_grapple_bonus` (`:441`) is base attack + grapple special size modifier +
Improved Grapple's +4 when active. The helper adds Strength itself, so the total
is the printed grapple check modifier; it is not double-counting Strength.

## 4. Finding by maneuver

### Grapple, pin and escape: correct

The explicit printed rule is the higher **grapple check modifier**, and the
helper's full modifier is exactly that value. Both totals and the tie comparison
use base attack + Strength + special size + Improved Grapple. If those values are
equal, the helper rerolls, matching "roll again to break the tie."

No discrepancy is established here. The generic tie tests do not exercise a
different base attack or Improved Grapple, but the caller construction itself is
the printed modifier.

### Trip and counter-trip: current content agrees; latent contract mismatch

For a Medium attacker and Medium defender with no stability bonus and no Improved
Trip, the helper's modifier is just the ability modifier. The helper therefore
matches the project's ability-check tie reading in every shipped-content case.

The helper would diverge if a non-ability bonus differed and the totals tied:

- size category;
- the defender's stability bonus;
- Improved Trip's attacker-only +4.

Those are check bonuses, not ability modifiers. Under the project's ability-check
reading they must not decide a tie. The current helper uses them in the tie.

### Bull rush: current content agrees; latent contract mismatch

The same analysis applies. The shipped actors are all Medium, no character or
monster has a stability bonus, and the implemented bull rush does not add the
printed charge +2. With the helper's size/stability bonuses at zero, the tie
comparison is the raw Strength modifier and matches the project reading.

A future Large/stable defender, or a future charge implementation, would expose
the same mismatch.

### Is this a confirmed defect?

**No confirmed defect in a current player-reachable maneuver.** The mismatch is
latent because the shipped content has no non-zero size/stability/Improved Trip
bonus in a trip or bull-rush tie. This audit does not invalidate the earlier
acceptances and does not assert that the existing maneuvers are wrong.

It is a **suspected rules discrepancy for future content** and a **shared-helper
API design issue**, not a naming concern alone: the names `attacker_bonus` and
`defender_bonus` do not say whether a bonus is part of the tie comparison. The
current helper cannot express both contracts.

## 5. Numerical examples

All arithmetic uses the helper's displayed modifiers; totals include the d20.

### A. Trip with a size bonus

Medium attacker Str 14 (+2), Large defender Str 10 (+0), defender size +4.

- Attacker roll 10: total 10 + 2 = **12**.
- Defender roll 8: total 8 + 0 + 4 = **12**.
- Ability-check tie: attacker +2 vs defender +0 -> **attacker wins**.
- Helper tie: attacker +2 vs defender +4 -> **defender wins**.

This is a meaningful participant difference, but it requires a Large defender.
No shipped encounter or monster is Large.

### B. Trip with Improved Trip and equal raw ability

Medium attacker Str 14 (+2), Improved Trip +4; Medium defender Str 14 (+2).

- Attacker roll 8: total 8 + 2 + 4 = **14**.
- Defender roll 12: total 12 + 2 = **14**.
- Ability-check tie: +2 vs +2 -> **reroll**.
- Helper tie: +6 vs +2 -> **attacker wins**.

Improved Trip is in `Feats.CATALOG` (`feats.gd:473`) and is fighter-selectable,
but the shipped Kaelen has Int 10, no Combat Expertise, and only one fighter feat
slot at level 4. The normal level-up path cannot reach it. `test_improved_trip`
and the QA training fixture append the feat directly; those are raw hooks, not
ordinary progression.

### C. Bull rush with stability

Medium attacker Str 14 (+2), Medium defender Str 10 (+0), stability +4.

- Attacker roll 10: total **12**.
- Defender roll 8: total 8 + 0 + 4 = **12**.
- Ability-check tie: +2 vs +0 -> **attacker wins**.
- Helper tie: +2 vs +4 -> **defender wins**.

No shipped character or monster has a stability bonus; `test_bull_rush` assigns
it directly.

### D. Grapple with different grapple modifiers: helper correct

Attacker Str 14 (+2), base attack +3, Medium -> grapple modifier **+5**.
Defender Str 16 (+3), base attack +1, Medium -> grapple modifier **+4**.

- Attacker roll 10: total **15**.
- Defender roll 11: total **15**.
- Printed tie: higher grapple check modifier, attacker +5 -> **attacker wins**.
- Helper tie: attacker +5 vs defender +4 -> **attacker wins**.

This is the case where using raw ability would be wrong: the defender has the
higher Strength (+3) but the lower grapple modifier (+4). The helper selects the
printed participant.

### E. Equal grapple modifiers

Both grapple modifiers +5, rolls 10 and 10 -> totals 15 and 15. The printed rule
says the modifiers are equal, so roll again; the helper rerolls. This is correct.

## 6. Reachability

| Case | Classification | Why |
|---|---|---|
| Grapple/pin/escape tie with different base attack | Normal player path | Both participants use their own base attack; shipped party and monsters have different base attacks. Helper is correct. |
| Trip/bull rush tie with all bonuses zero | Normal player path | All shipped characters/monsters are Medium; no stability; Kaelen cannot reach Improved Trip at level 4. Helper coincides with the project's ability-check reading. |
| Trip with Large defender | Synthetic/future content | Trip legally allows one size larger, but no shipped actor is Large. Tests assign size directly. |
| Trip with Improved Trip | Raw hook/future progression | Catalog feat, but not reachable by the shipped party at the current level cap; tests/QA append the feat directly. |
| Bull rush with stability | Synthetic/future content | Stability is an authored field, but no shipped actor sets it. Tests assign it directly. |
| Grapple with Improved Grapple | Raw hook only | The feat is not in `Feats.CATALOG`; `FEATS_SKILLS_COVERAGE.md` records it as not selectable. Tests append the feat text directly. |

## 7. Test coverage

The tests establish the helper's baseline and the callers' initial modifiers, but
not a tie where the possible interpretations differ:

- `tests/test_prone_and_size.gd:202` checks tied totals with different raw
  Strength modifiers; no `opts` bonuses.
- `tests/test_prone_and_size.gd:220` checks equal modifiers and rerolls; no
  `opts` bonuses.
- `tests/test_grapple.gd:273` checks the helper's tie path with no bonuses; it
  does not exercise `_grapple_bonus` or differing base attacks.
- `tests/test_grapple.gd:262` checks that base attack is in the grapple modifier,
  but not a tied total.
- `tests/test_improved_trip.gd:145` checks the +4 is in the trip modifier, but not
  a tied total.
- `tests/test_bull_rush.gd:304` and `:328` check size and stability in the
  modifier, but not a tied total.

There is therefore **no test where the ability-only and full-modifier
interpretations select different participants**. That absence is consistent with
the shipped-content reachability above; it is not evidence that the latent
contract is correct.

## 8. Smallest explicit API design, not implemented

If the project accepts the ability-check reading and later adds a reachable
non-ability bonus, the smallest explicit change is to separate the total from the
tie value:

```gdscript
Rules.opposed_ability_check(rng, attacker, attacker_abilities, defender, defender_abilities, {
    "attacker_bonus": total_attacker_bonus,
    "defender_bonus": total_defender_bonus,
    "tie_attacker_modifier": raw_attacker_ability_modifier,
    "tie_defender_modifier": raw_defender_ability_modifier,
    "label": "...",
})
```

Defaults should preserve the current behaviour (tie value = full modifier), so
grapple, pin and escape keep their printed rule. Only trip/bull-rush callers that
have accepted the ability-check reading would pass the raw tie modifiers. The
result should record the tie modifiers alongside the totals for audit.

This is an API design sketch only. No helper, caller, test or content was changed.
Changing the helper globally to raw ability would make the explicit grapple rule
wrong; changing only trip/bull rush without an explicit API would duplicate the
tie/reroll contract.

## 9. Classification

- **Confirmed product defects:** none in existing player-reachable trip, bull
  rush, grapple, pin or escape. Grapple/pin/escape match the explicit printed tie;
  trip/bull rush coincide with the project reading with shipped content.
- **Suspected discrepancy:** trip/bull rush use full check modifiers as tie
  breakers when a size, stability or Improved Trip bonus differs. This is latent,
  not currently reachable.
- **Deferred features:** overrun remains deferred under `OVERRUN_PLAN.md` §18;
  Large/stable actors and reachable Improved Trip/Improved Grapple are future
  content/progression work.
- **Maintenance debt:** the shared helper has one field serving both "total
  modifier" and "tie modifier"; there is no test for the differing case; the
  20-reroll cap is a guard rather than printed behaviour.
- **Evidence gaps:** no test with non-zero size/stability/Improved Trip and a tied
  total; no normal-progression route to Improved Trip; no shipped Large or stable
  actor.

## 10. Recommendation

**No focused failing-first investigation is warranted now**, because no
player-reachable maneuver appears to resolve ties incorrectly. Keep the ability-
check tie distinction as a future design constraint and do not change the helper
or any caller from this audit.

**Next bounded feature: Candidate A, keyboard-combat information access** in
`docs/ROADMAP.md`. It is the strongest genuinely bounded roadmap item outside
overrun: the combat log has no keyboard scrolling path, and focused pending-
decision/target controls can remain outside the sidebar viewport. It needs no
rule, content, save or schema change. Its key/focus choices should be settled
first; this audit authorizes no implementation.

Readied/delayed actions have a higher tactical ceiling but are a subsystem, not a
bounded batch. Further grapple still lacks a content payoff, and the save shortcut
is a ride-along. Overrun remains deferred.
