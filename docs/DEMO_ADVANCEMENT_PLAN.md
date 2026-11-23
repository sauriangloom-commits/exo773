# How the demo reaches 4th level

Planning note, 2026-11-22. Status: **batch 6a implemented** at
`9139136f932bf2aa641ae7796f59f16e7d154d7d` - the bell's 2,300 XP milestone, tests
1-4 and `--advancement-probe`; batches 6b and 6c remain proposals. The note itself
changed no code, content, schema, save, XP threshold or UI, and asked for no manual
testing. It follows the review committed as `2877bbc` and corrects that review's
route arithmetic and its save sentence; those corrections, and two route details
the probe corrected, are listed in §14.

## 1. What this note decides

1. The verified award ledger of `ravenloft_demo`, with the authored total kept
   apart from what one ordinary-player route can actually earn.
2. One XP policy - a completion milestone - with its printed basis and its
   project-specific adaptations.
3. The exact content change, the route eligibility is reached on, and the
   playable content that remains at 4th level.
4. The proposed `--validate-diagnostics` reporting, labelled so a static total is
   never read as reachability.
5. A required-choice completability check for shipped 3rd-level characters, with
   its limits stated.
6. The tests and the follow-on probe, including what still needs a direct call.
7. Ordered, independently acceptable implementation batches.

**The problem in one line.** The level-up feature is accepted, but the party is
authored at 3,000 XP, the threshold is 6,000, and the demo's best ordinary route
awards 1,850 - so no player can reach 4th level in play, and every acceptance run
so far did it from a fixture.

## 2. Verified award ledger - `ravenloft_demo`

Every XP source was read from the content and checked against the code that pays
it (`apply_effects` for `xp` effects, `_resolve_encounter` for encounters, which
pays each party member the encounter's `xp`).

| Award | Amount | Trigger | Ordinary-player accessible | QA-only | Repeatable | Route conditions |
| --- | --- | --- | --- | --- | --- | --- |
| `encounter:storeroom_dead` | 300 | Trigger `storeroom_ambush` at (7,7) of `old_gatehouse`, `requires_flag_not: storeroom_cleared` | Yes - the store door at (6,7) is unlocked; the trigger sits behind it | No | No - victory sets `storeroom_cleared`, and the trigger refuses on it | None; independent of the crypt |
| `dialogue:corvin/pact` | 200 | Corvin's `pact` node, reached by Diplomacy DC 18 or Intimidate DC 20 | Yes - the crypt door opens with the crate key or Open Lock DC 15 | No | No - `pact` sets `warden_resolved`, and both check choices require `not_flag warden_resolved` | **Excludes** `encounter:crypt_warden` |
| `encounter:crypt_warden` | 450 | Corvin's "Destroy it." or the `insult` node's "Attack!" | Yes - same door requirement | No | No - victory sets `warden_resolved` and `warden_destroyed`; the dialogue choices are gated on `warden_resolved` | **Excludes** `dialogue:corvin/pact` |
| `object:bell/ring` | 500 | The bell's `ring` interaction; needs `bell_clapper`, `requires_flag_not: bell_rung` | Yes - the clapper comes from the crate search (DC 12) or from Corvin's pact | No | No - the interaction sets `bell_rung` in the same effect list | None |
| `encounter:town_square_zombies` | 600 | Trigger `town_square_breach` at (5,8) of `barovia_town_square`, `requires_flag_not: town_square_saved` | Yes - through the shipped demo waystones, which have no gate | No | No - victory sets `town_square_saved` | None; the area is reachable from the first minute |
| `encounter:qa_victory` | 150 | **No content trigger exists**; only probe code in `main.gd` starts it | No | **Yes** | Not applicable | Not applicable |
| `encounter:qa_turn_undead` | 0 | Same: no content trigger | No | **Yes** | Not applicable | Not applicable |

**Totals, kept apart.**

- **Authored total: 2,200.** Every award in the campaign, including the QA
  encounter and both sides of the mutually exclusive pair. This is an inventory,
  not something a player can earn.
- Ordinary-only authored total: **2,050** (2,200 minus the 150 XP QA encounter).
- **Best single ordinary route: 1,850** = 300 + 450 + 500 + 600. The pact's 200 XP
  cannot be added to the crypt's 450 XP, and the QA encounter cannot be entered.
- Gatehouse only, best: **1,250** (300 + 450 + 500).
- **Least-awarding completion of `drowned_bell`: 700** (0 from the crate, 200 from
  the pact, 500 from the bell). The crate search awards no XP but is on every
  completion route: the quest's `recover_clapper` objective reads the
  `found_clapper` flag, which only the crate's success effects set - the pact
  hands over the clapper item without that flag.

At the authored 3,000 start, one ordinary route therefore ends at **4,850**, and a
completing player's floor is **3,700**. The threshold is 6,000.

**What is deliberately not counted.**

- **Other campaigns' awards** (`ashwick_ferry` 500, `hollow_lantern` 200). The
  party cannot carry XP between campaigns: `new_game` with a different campaign
  key rebuilds every character from `content/shared/characters.json`
  (`game_state.gd:204-208`), and saves are pinned per campaign - `save_game`
  refuses to overwrite another campaign's slot (`:506-513`) and `load_game`
  resolves slots through the current `campaign_id`. Nor can one save be carried
  into another campaign's content.
- **Monster `xp` fields** (150 / 300 / 600 in `content/shared/monsters.json`).
  They are read by the campaign creator's authoring spinbox only; the engine
  awards `encounter.xp_award` from the encounter's own `xp`
  (`game_state.gd:1689`).
- **The level-up step itself.** It awards no XP; the accepted probe asserts that
  ("the level step awards no XP").

## 3. Route assumptions, verified against the implementation

- **Travel.** The only route to `barovia_town_square` is the marker object
  `east_road` on the gatehouse map, then `to_town_square` on the staging map
  (`travel` effects, no requirement flags). Both are shipped, visible
  interactions a player can use from the first minute - but both are labelled
  "DEVELOPER DEMO ROUTE - NOT CANONICAL GEOGRAPHY" in their own text. They count
  as ordinary accessibility (no QA gate, no debug option); they are not evidence
  of a canonical route between the two maps.
- **Ordering.** Nothing forces the gatehouse first. A player can take the
  waystone immediately and fight the town square before ringing the bell.
- **Once-only behaviour.** Triggers refuse on the victory flag they set, so an
  encounter pays once. `once: true` interactions are removed **only on success**
  (`_run_interaction`), so a failed crate or bier search can be retried - which is
  what makes the clapper and key reachable for every party, not a lucky roll.
- **Doors.** A locked door opens with its `key_item` if the party holds it,
  otherwise with an Open Lock check against `lock_dc` (`_try_open_door`), which is
  repeatable. The crypt door is therefore never a dead end.
- **Payment.** Every party member receives the full award (`for ch in party:
  ch.xp += xp` for encounters, `apply_effects` for effects). The demo allows one
  to four characters, and the award does not scale with party size - an
  adaptation, see §4.
- **Persistence.** In the victory path the XP is granted before the autosave
  (`game_state.gd:1729-1738`, `:1756`), and every award in this ledger is also
  followed by an autosave: encounters at victory, interactions through
  `_autosave_after_interaction`. Paid XP and eligibility therefore survive the
  recorded autosave; an applied level-up that is not saved does not, and neither
  do its choices (§12).

## 4. Policy: a completion milestone for `drowned_bell`

**Chosen: a milestone (climax) award paid by the bell's `ring` interaction, the
last objective of the campaign's `drowned_bell` quest.**

Printed basis, and what is ours:

- **DMG 3.5, Table 2-6 "Experience Point Awards (Single Monster)", p. 37-38**:
  per-monster XP for a party of four, by character level and CR. At the party's
  1st-3rd level row, CR 1 = 300 and CR 2 = 600. The content's per-monster values
  (zombie 150, ghoul 300, infected zombie 600) follow that table at CR 1/2, 1 and
  2.
- **DMG p. 39 (ad hoc awards) and p. 40 (story awards)** allow experience for
  goals other than defeated monsters and give no number for them. The milestone
  amount is therefore a **project adaptation**, not a printed value.
- **PHB Table 3-2, p. 22**: 4th level begins at 6,000 XP. The threshold is
  printed and stays as it is.

**Adaptations, labelled.**

- The party starts authored at 3,000 XP (a 3rd-level pregen party), not at 0.
- An encounter's `xp` is paid in full to every character regardless of party size;
  the printed table assumes four characters and one award per character.
- The infected zombie is 6 HD but worth 600, the printed CR 2 value; a CR 3
  creature would be 900. Authored as an adaptation.
- The bell's 500 and Corvin's pact's 200 are non-combat awards already in the
  content; they are the same kind of award as the milestone, smaller.
- The milestone's size (§5) is chosen to meet the printed threshold, not derived
  from any printed table.

**Rejected alternatives.**

- **Encounter-based awards only.** Even at fully printed per-monster values the
  gatehouse totals 1,250 and the town square would rise from 600 to 1,200 (two
  6-HD undead), giving 5,450 on the best route - still short, and eligibility
  would arrive after the last fight, leaving nothing to play at 4th level.
  Scaling awards by party size would be a rules change and is out of scope.
- **A campaign budget.** "The demo awards 3,000 XP in total" fixes a total but not
  where it attaches; it still needs the milestone's trigger, and it would invite
  silent rebalancing of the encounters that already match the printed table.

## 5. The number: 2,300, derived from the completion floor

The required award is derived from the **least-awarding route that completes
`drowned_bell`**, not from the 2,200 inventory and not from the best route, so
that *every* completing player is eligible when the quest completes:

```
start 3,000 + crate 0 + pact 200 + bell 500 = 3,700
6,000 - 3,700 = 2,300
```

| Route | Awards | Total at the bell | After the town square |
| --- | --- | --- | --- |
| Crate, parley, bell (completion floor) | 0 + 200 + 500 + 2,300 | **6,000 - eligible exactly** | 6,600 |
| Crate, storeroom, parley, bell | 0 + 300 + 200 + 500 + 2,300 | 6,300 | 6,900 |
| Crate, storeroom, crypt fight, bell (named probe route) | 0 + 300 + 450 + 500 + 2,300 | 6,550 | 7,150 |
| Crate, bell, warden never resolved | 0 + 500 + 2,300 | 5,800 | 6,400 (or 6,250 after the crypt fight) |

**Sizing at 1,750 was rejected.** It fits the crypt-fight route exactly
(4,250 + 1,750 = 6,000) but leaves the parley route at 5,750 at the bell - the
player who talks Corvin down, the harder resolution, would be the one who does not
level until after the last fight.

**Consequence, stated as a consequence.** A player who rings the bell without
resolving the warden has not completed the quest and is at 5,800; the warden's
200/450 or the town square's 600 takes them over the line. That is not a defect,
but it is the reason the guarantee is worded "completing the quest", not "ringing
the bell".

## 6. The exact proposed content change

One file, one interaction, two effects added - existing effects untouched:

`content/campaigns/ravenloft_demo/dungeon.json`, object `bell`, interaction
`ring`, in `effects`:

```json
{"type": "set_flag", "flag": "bell_rung", "value": true},
{"type": "xp", "amount": 500},
{"type": "xp", "amount": 2300},
{"type": "narration", "text": "(MILESTONE - PROJECT ADAPTATION) The gatehouse's debt is answered. The vigil is kept; every adventurer gains the experience of a completed charge."}
```

`{"type": "narration", "text": "..."}` already follows; the milestone line is
added beside it so the award is visible in the log as its own line and stays
separable in the ledger.

**Why the bell and not the quest hook.** The engine has no XP-for-quest-complete
hook; the bell's interaction is where `bell_rung` - the quest's last objective -
is set, it refuses on that same flag, and the interaction boundary autosaves what
it pays.

**Not changed.** The 6,000 threshold, `LevelUp`, the screen, any encounter's
`xp`, any character, `campaign.json`, the QA encounters, the save format.

## 7. The route eligibility is reached on, and what is left to play

**Named route (the one tests and the probe walk):** gatehouse, quest order.

1. Start at (5,10) of `old_gatehouse`: every character at 3,000 XP.
2. Store door (6,7), step to (7,7): `storeroom_dead`, win - **300**.
3. Crate (8,6), Search DC 12 - clapper, key, no XP.
4. Crypt door (5,3) with the key; Corvin (2,1), "Destroy it."; win
   `crypt_warden` - **450**.
5. Bell (7,2): ring - **500 + 2,300**. The party is at **6,550** and the quest
   `drowned_bell` completes.

Eligibility is therefore reached **at the bell, inside the gatehouse, before any
area travel** - so it does not depend on the developer waystones at all.

**What remains playable at 4th level:** the town square fight
`town_square_zombies` (600 XP, two 6-HD infected zombies) - the only remaining
encounter and the only place the new feat, ability increase and skill ranks are
used in combat - plus the barricade repair (gated on `town_square_saved`),
Ashlyn's dialogue and the return trip.

**Ordering consequence.** A player who uses the waystone first fights the town
square at 3rd level and levels at the bell with only the repair and a
conversation left. The waystones are not gated; the note does not propose gating
them, and no batch below does.

## 8. QA encounters: they do not count

`qa_victory` and `qa_turn_undead` are **excluded from every total above** and must
stay excluded from acceptance:

- No content trigger, dialogue or object names them; only `main.gd` probe code
  calls `Game.start_encounter("qa_victory")` or `_qa_start_encounter(...)`.
- The accepted `--level-up-probe` crossed the threshold with `qa_victory` and a
  fixture write (`member.xp = 5999`), which is disclosed in its own header. That
  is why the new probe (§11) may not use either.
- Ordinary-player acceptance therefore rests on `storeroom_dead`, `crypt_warden`
  (or the pact) and the bell - all reachable through shipped interactions.

## 9. Proposed `--validate-diagnostics` output

Two new **informational** lines per campaign, printed before the summary. Neither
changes the failure count, the exit code, or `--validate-campaigns`.

```
ADVANCEMENT AWARDS ravenloft_demo authored=2200 ordinary=2050 qa=150 encounters=2200 effects=700 start=3000 threshold=6000 (static inventory of authored awards; not a route, not reachability)
ADVANCEMENT AWARDS hollow_lantern authored=200 ordinary=200 qa=0 encounters=200 effects=0 start=3000 threshold=6000 (static inventory of authored awards; not a route, not reachability)
CAMPAIGN DIAGNOSTICS hollow_lantern | 0 errors, 0 warnings
```

Rules the shape follows:

- **`authored` / `ordinary` / `qa` are static totals** - sums over the campaign's
  `encounters.json` and every effect list that carries an `xp` effect. The line
  says so in its own text, because a sum is not a route.
- **No route is modelled in the validator.** A "best route" computed by scanning
  content would be a guess about triggers, flags and logic, not an established
  route. Route totals belong to the test and the probe (§11), where the
  implementation actually walks them.
- **"Reached" is reserved for the probe.** Only the probe prints:

  ```
  ADVANCEMENT REACHED campaign=ravenloft_demo route=gatehouse_quest awards=storeroom_dead:300,crate:0,crypt_warden:450,bell:500+2300 xp=6550 threshold=6000 eligible=kaelen,sera,aldric,ysolde
  ```

  That line exists because a run walked it; it is the only place the word appears.
- **A short campaign is not an error.** `ashwick_ferry` and `hollow_lantern` stay
  PASS with the line printed: they are legitimately shorter than one level, and
  the line is information for an author, not a gate.

## 10. Required-choice completability check for shipped 3rd-level characters

**What it asks.** For every character authored at 3rd level whose class has a
4th-level row - today all five in `content/shared/characters.json` - does at least
one *completed* draft exist that the rules layer accepts?

**How it answers, and why this form.** For each character, for each of the six
abilities, for each candidate feat (when a slot is granted) and each candidate
spell (sorcerer only), build a draft `{ability, feat, spell, skills: {}}` and call
`LevelUp.stage(ch, draft, true)`. The character is completable if any draft
returns `ok`.

- **Pending ability.** The ability is not "pending" in this check: all six are
  tried in turn. `LevelUp.stage` applies the increase before grading feats, so a
  feat whose prerequisite depends on the raised score is evaluated against the
  raised score - which is what the screen does.
- **Existing feats.** `LevelChoices._feat_rows` filters against the character's
  own list, so an owned feat is not counted as a candidate for the new slot.
- **Known spells.** `_spell_rows` removes known spells, so the sorcerer case that
  motivated this check - every implemented 2nd-level spell already known - yields
  no candidate and is reported by name.
- **Why `LevelUp.stage`, not `LevelChoices.validate`.** `validate` first calls
  `LevelUp.eligibility`, and every shipped character sits at 3,000 XP, below the
  threshold. `stage(..., complete = true)` still enforces every choice rule
  (ability present, feat legal and unowned, spell legal and unknown, skills within
  budget and caps) without requiring eligibility. The check therefore proves a
  **legal completed draft exists**, not that the character is eligible today.

**What it proves, and what it does not.** It proves the rules layer accepts at
least one full draft. It does **not** prove the screen can render it, the keyboard
can reach it, the player can find it, or that the campaign awards enough XP. A
check that only tested "the option lists are non-empty" would be strictly weaker:
it would not catch a combination the validator refuses. Do not describe the pool
check as a completability proof.

**Severity.** For a shipped campaign it is a validation **failure** when no draft
exists, with a line naming the character and the group that emptied:

```
ADVANCEMENT COMPLETABLE ravenloft_demo mira class=sorcerer group=spell result=EMPTY
```

Today it passes everywhere; the negative cases are fixtures, not shipped content.
This is the one new check that may fail the validator, and it is separate from the
informational XP lines in §9.

## 11. Tests and the follow-on probe

**Unit and content tests** (GUT, source only):

1. `test_demo_xp_ledger_matches_the_content`: sums the campaign's authored awards
   and pins 2,200 authored / 2,050 ordinary / 1,850 best route / 700 completion
   floor. It fails if any award in §2 changes without the ledger.
2. `test_the_named_route_reaches_the_threshold`: adds 300 + 450 + 500 + 2,300 to
   the authored 3,000 and asserts 6,550; adds 0 + 200 + 500 + 2,300 and asserts
   exactly 6,000.
3. `test_the_qa_encounters_have_no_content_entry_point`: no trigger, dialogue
   choice or object effect names `qa_victory` or `qa_turn_undead`.
4. `test_drowned_bell_needs_the_crate_flag`: completion requires `found_clapper`,
   which only the crate's success effects set - the test behind the 700 floor.
5. `test_every_shipped_level_three_character_has_a_completed_draft` and the two
   negative fixtures: a synthetic sorcerer knowing `scorching_ray`, and a
   synthetic fighter owning every `fighter_bonus` entry.

**The follow-on probe** (`--advancement-probe`, new app scenario; it earns
eligibility, it does not grant it):

- `Game.load_campaign("ravenloft_demo")`, `Game.new_game(["kaelen", "sera",
  "aldric", "ysolde"], 4242)` - four characters, one seed.
- Movement through the shipped dungeon with `Game.move_forward` /
  `Game.strafe_left` / `Game.strafe_right` / `Game.turn_left` / `Game.turn_right`,
  interactions with `Game.interact` and `Game.interact_with_take(10)` (the crate's
  DC 12 search and the crypt's lock are deliberately deterministic).
- The storeroom trigger starts its own encounter; the crypt fight comes from
  Corvin's dialogue (`Game.dialogue_choose` on the "Destroy it." choice, whose
  label the probe asserts first). Each fight is resolved with the same technique
  the accepted probe uses - `apply_nonlethal` on the enemy and the encounter's own
  `_check_end` - which is a direct call, not a real attack, and must be disclosed
  as such.
- **No XP is assigned anywhere.** No `member.xp = ...`, no `Game.start_encounter`
  for an award, no injected effect. The probe asserts the ledger as it goes:
  `PROBE XP step=storeroom xp=3300`, `PROBE XP step=crypt xp=3750`,
  `PROBE XP step=bell xp=6550`.
- At the bell it asserts, for every party member: `xp == 6,550`,
  `LevelUp.eligibility(...).eligible == true`, and `drowned_bell` complete.
- **Then it reuses the accepted walk unchanged**: party sheet, keyboard path,
  refused Confirm, draft survival, apply, save/reload, second-apply refusal,
  Cancel/Escape no-write, and the C1-C9 geometry - the same steps and labels the
  `--level-up-probe` already checks. The probe prints its own
  `ADVANCEMENT REACHED` line (§9) plus a `PROBE RESULT` in the existing format.

**Input split, stated up front** (the accepted probe's own convention):

| Kind | What | Why it cannot be a key press |
| --- | --- | --- |
| Direct call | `new_game`, `load_campaign` | A probe cannot choose a campaign or a party from the menu |
| Direct call | movement, `interact`, `interact_with_take` | Positional setup for a deterministic route |
| Direct call | `dialogue_choose` | Index chosen after asserting the option's label |
| Direct call | `apply_nonlethal` + `_check_end` | Winning a fight without turn-by-turn combat input |
| Direct call | `save_game`, `load_game`, sheet open | Slot names and screens a probe cannot type |
| Keyboard | every action inside the sheet and the level-up screen | The shipped focus walk is what is being accepted |
| Fixture | none for XP; the seed, the party list and the save directory only | - |

**Exported run.** The milestone changes what a player earns, so its acceptance
needs a candidate: build through `tools/qa/build_candidate.sh`, run the pack audit,
and record the exe's size and full SHA-256 before and after the run, matching
`BUILD.txt` - the guardrail the level-up batch used. The candidate runs
`--advancement-probe` (one scale; it makes no layout claim) and the existing
two-scale `--level-up-probe`, so the accepted walk is re-proved on the same binary.

## 12. Save-policy wording, corrected

The review's sentence was imprecise. The correct statement, which the note and the
record should use:

> Paid XP and eligibility survive the recorded autosave; an unsaved applied level
> and its choices do not.

- The victory path grants XP before it writes `save_game("auto")`
  (`game_state.gd:1729-1738`, `:1756`), so a reload restores the paid XP and
  re-offers the step with an empty draft; the same choices can be made again.
- The applied level, its feat, spell and skill ranks reach disk only at the next
  manual save or auto boundary. Quitting immediately after applying loses them,
  not the entitlement.
- Reload-then-reapply remains an **evidence gap**: no probe walks it, and this
  note does not claim it is tested.

## 13. Ordered implementation batches

Each is independently acceptable and independently revertable.

**Batch 6a (first) - the milestone award and the advancement probe.**

- Content: the 2,300 XP effect and its narration on the bell (§6).
- Tests 1-4 of §11, written first: the ledger and the route test fail before the
  content change (4,250 < 6,000) and pass after.
- The probe of §11, red before the content change and green after.
- Acceptance: suite green; `--validate-campaigns` and `--validate-diagnostics`
  PASS; the probe's `ADVANCEMENT REACHED` line and `PROBE RESULT PASS` from a
  candidate whose hash is identical before and after and matches `BUILD.txt`; the
  pack audit clean.
- Exclusions: no threshold, encounter, character, UI, schema or save change.
- Player impact: this is the batch that makes 4th level reachable.

**Batch 6b - advancement reporting.**

- The `ADVANCEMENT AWARDS` lines of §9, informational only, with tests that
  `hollow_lantern` still passes and that the failure count is unchanged.
- Acceptance: suite, both validators, no player-visible change, so no candidate.
- Exclusions: no route modelling in the validator; no failure for a short
  campaign.

**Batch 6c - the completability check.**

- The check of §10, its positive run over the five shipped characters, and the two
  negative fixtures; it may fail the validator only when no draft exists.
- Acceptance: suite, both validators from source. It changes a developer tool, not
  play; a candidate is optional and, if one is built, follows the same hash rule.
- Exclusions: it is not presented as reachability, and it does not touch the
  screen.

Ordering rationale: 6a is the only batch a player can feel; 6b and 6c are reporting
and can be reordered or dropped without weakening 6a's acceptance.

## 14. Corrections to the record

- **The review's 5,200 was an inventory, not a route.** It summed 1,500 encounter
  XP (including the 150 XP QA fixture), 500 and 200 effects, and could not be
  earned in one campaign: the pact and the crypt fight are exclusive, and the QA
  encounter has no entry point. The verified figures are 2,200 authored and
  **1,850 on one ordinary route**, so the ceiling is **4,850**, not 5,200. The
  "5,900 across all campaigns" figure has no meaning either, because XP cannot
  carry between campaigns.
- **The shortfall is 1,150 on the best ordinary route**, and **2,300 for a player
  who completes the quest**, which is the number the milestone is derived from.
- **The save sentence is corrected** as in §12: the applied level and its choices
  are lost if unsaved; the paid XP and eligibility are not.
- **"A reachable-XP line" is narrowed**: the validator prints static inventory
  only; reachability is established by the probe, because a scanner cannot
  establish a route.

- **The §7 route needed two corrections, found while writing the probe.** It also
  has to speak to Miruna: `drowned_bell` carries a `met_miruna` objective, so the
  bell alone does not complete the quest (0 XP, so the floor is unchanged). And the
  crypt door at (5,3) does not gate Corvin - the crypt room is entered from below
  through (4,3) - it is the door the party crosses on the way from Corvin to the
  bell, where the crate's key is actually used.
- **The ledger test's pins move with batch 6a**: authored 4,500, ordinary 4,350, one
  ordinary route 4,150, least-awarding completion 3,000. The §2 figures stay correct
  as the pre-6a ledger, and §11 test 1 should be read with the new pins.

## 15. Four lists, kept separate

**Confirmed defects.** None. This note adds no defect: no shipped award is wrong
by the rules it claims to follow, and the shortfall is content scope, not a
failing behaviour. The two batch-4 defects stay closed.

**Deferred features.** Levels 5 and above; more than one level per step; NPC
advancement; the implanted printed fighter feats (Weapon Specialization, Improved
Bull Rush, Quick Draw, Two-Weapon Fighting); a level-up autosave; a sheet
shortcut; gating the town square behind the gatehouse; correcting the town square
award from 600 to the printed 1,200; the rest of P1-P4.

**Maintenance debt.** Singular `modal`; draft in the screen; arrows reserved for
scrolling; `follow_focus` beside the reveal walk; string-blind source guards;
`Panels.character_sheet` now mutable; acceptance not repeated per batch; empty
migration table; shallow UI suite; probe-heavy `main.gd`; placeholder renderer; no
content hot reload. New in this note: the demo's encounter XP is authored by hand
and only partly matches the printed table, and nothing checks it.

**Evidence gaps.** Control rectangles rather than pixels; the sorcerer not walked
end to end; the cleric and wizard not walked; no window seen; no playtest; one OS
and one window size; held-key and Enter activation need a person; no
reload-then-reapply probe; no probe yet walks a real award route (this note's
probe is the proposal that would).

## 16. What this note does not do

It does not change the threshold, any award, any character, any encounter, the
screen, the save format or the UI. It does not claim the demo is now beatable to
4th level, because nothing here is implemented. It does not ask for manual
testing, and it does not touch a backup.
