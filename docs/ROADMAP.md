# Prioritized Continuation Roadmap

> **Current boundary (2026-11-21).** 778/778 tests, 7,976 assertions, 60 scripts,
> exit 0; `--validate-campaigns` and `--validate-diagnostics` both PASS, and the
> windowed probes run at 1280×720 at 100 % and 160 %. Creature soft cover on
> ranged attacks (and its inspector clause) is accepted within its recorded
> scope. Fighting defensively and total defense are accepted as committed
> stances; candidate `defensive_actions_2026-11-21c` (`58cb1a7`) passes its probe,
> both validators and a matching before/after exe hash, and carries the
> source-tested combat-scope cleanup. `-b` is preserved and superseded. Both that
> batch and its cleanup are closed as accepted within the recorded limits.
> Player-initiated bull rush is done and closed as accepted within its recorded
> limits (778/778, both validators, bound candidate `bull_rush_2026-11-21b`); the
> right-side panel gained a `Bull rush` control. Earlier candidates
> `creature_cover_inspector_2026-11-21` (`e64a6c9`) and `creature_cover_2026-11-21`
> (`4e56d1e`) remain preserved and are still unbound. (The 2026-11-14
> boundary was 538/538, 6,263 assertions, 44 scripts.) Earlier
> milestones below keep their own numbers as written: a smaller test count or
> "thirty-seven feats" is history, not current status. The shipped feat catalogue
> holds **41** entries. Items marked **Done** are complete and are kept for the
> record rather than as outstanding work.
>
> `--validate-content` is **not** a supported option. Content errors fail CI
> through `--validate-campaigns` and `--validate-diagnostics`. Since 2026-11-14
> an unknown application option prints the closest supported alternatives and
> exits 2 instead of starting the game.

The foundation is playable end-to-end and Phase 2 is complete. The next work should extend content and
rules breadth without destabilizing the tested core.

**Historical.** Phase 3 status: clean import and **206/206 tests (2,224 assertions)** pass. The
source-grounded E3 loop was completed through normal controls: victory, Ashlyn
dialogue, barricade repair, travel out and back without repeating the trigger or
rewards, auto-save, quit, relaunch and loaded state.

Batches 1–5 of the feats-and-skills foundation are complete: all 45 Table 4-2
skills are cataloged, checks share one engine (ranks, armor, synergies, take
10/20, Aid Another, opposed checks), and forty-one feats are implemented and
verified, including all fourteen +2/+2 skill feats, the proficiency feats, the
turning feats, Power Attack's committed attack/damage trade and Combat Expertise's
committed attack/dodge trade.
The full PHB feat table and the dependency blocking each deferred feat are in
[FEATS_SKILLS_COVERAGE.md](FEATS_SKILLS_COVERAGE.md). The repaired-barricade flag
is preserved: the 2026-11-03 miss was an autosave-ordering defect in the repair
path, now fixed and pinned by interaction-path, manual-save and reload tests (see
[PHASE3_VERIFICATION.md](PHASE3_VERIFICATION.md)). It is not an open persistence
gap. Mage Armor targeting and Restore Default Controls were fixed. A fresh
Windows build launches outside the source tree.

## Adventure assessment — The Ashwick Ferry: The Second Ring (2026-11-14)

Assessment only. The implementation milestone stays closed; no content, runtime,
rules, UI or tooling was changed. Method and raw run:
`builds/qa/runs/2026-11-14_ashwick_assessment/`.

**Working.** The landing → Maela → ledger → tack room/token → account → bell
route is legible from the intro, the five objectives, Maela's task node and the
bell's waiting text; the forced return to Maela before the bell is justified in
fiction and adds meaning rather than movement. The ledger (struck-through lawful
crossing, after-bell fare) and the optional page (silver toll, two rings,
"Maela's draught") form one investigation; the page complicates motive without
making the ledger-only account false, and both late-page variants stay
consistent with the commitment. The account options state their content (truth
names the fare, mercy names the lie, the page option says "all of it"), so no
internal-flag knowledge is needed. The three bell answers are distinct, the
epilogues vary consistently by account/outcome/page, the finale is a required
conversation, and the post-ending exchange is repeatable. Mercy + ring once
reopening the ferry while the page says two rings were needed reads as an
intentional unresolved claim, not a contradiction.

**Prioritized finding: the mandatory drowned-ferrymen fight is a composition
trap for small supported parties.** Ashwick allows 1–4 adventurers
(`campaign.json` min 1; party selection says "one to four"), but the token that
opens the bell exists only in that encounter's victory effects, and each drowned
zombie has 16 HP with DR 5/slashing (MM pp. 265–266). Printed guidance
calibrates CR and encounter level to four-PC parties (DMG pp. 49–50) and notes
that parties of three or fewer are challenged by lower-CR monsters; the 16-HP
stat line and the 200/300 encounter XP here are this project's adaptations.
Sera's only weapons are
piercing; her short sword (1d6+1) does at most 2 damage per hit after DR, the
crossbow at most 4 but costs a move to reload, and undead are immune to her
sneak attack, so the pair needs at least 16 maximum-roll short-sword hits while
her 17 HP face about 3 damage per round. Bounded
session check (real encounter through GameSession, seed 11, attack/move only —
no spells, potions or heals): solo Sera defeat at round 14 (-3 HP); solo Aldric
defeat at round 14; solo Ysolde attack-only defeat; solo Kaelen victory at round
9 (28/28); Sera + Aldric defeat at round 52; default four victory at round 38
(Kaelen 22/28). The authored four-party experience is not blocked: it wins the
bell answer too (29 rounds fresh, 30 after the tack room), and the combat log
names DR 5/slashing so the wall is discoverable. Severity: a blocker for the
advertised single-character start (at least solo Sera; solo Aldric and Ysolde
were not played with their turning or spells), not for the default party.

**Smallest correction.** Enforce the already-authored `party.min` at party
selection/`new_game` (it is validated on load but currently ignored; the UI
hard-codes non-empty and ≤4) and set Ashwick's min to 3. Every three-character
subset of the five pregens contains Kaelen (slashing) or Ysolde/Mira (force and
fire), so the DR wall has an answer; no encounter, shared rules, shared content
or UI content change. If the runtime change is out of scope, the content-only
fallback is to state "designed for three or four adventurers" in the campaign
description, which informs rather than fixes.

**Applied 2026-11-14 (bounded correction).** `party.min` is enforced at party
selection and in `new_game` (one shared interpretation, campaign-specific), and
Ashwick now declares `min: 3` with the description stating the designed size.
All ten three-character subsets won the mandatory encounter in two scripted
seeds, so three is supported as a reasonable authored minimum; that is bounded
evidence, not a balance validation. `content_version` stays 2 and compatible v2
saves still load. See `PROGRAM_PROGRESS.md` and `TEST_REPORT.md`.

**Optional bell answer.** Ghoul + zombie is optional and warned in the notice,
the option text and Maela's "why not ring it now" answer; the authored four wins
fresh and after the tack room without spells. Paralysis DC 12 (MM p. 118; elves
immune) is the real spike, and Ashwick has no recovery site, so a depleted small
party is at risk — acceptable for an optional, warned fight, but a one-line risk
note on the ring-twice option would be a worthwhile refinement.

**Limits.** One seed per composition; scripted attack-only tactic; no human
playtest; no target win rate; not a full balance validation. Solo caster/cleric
results would improve with their implemented spells, turning and healing and
are not claimed as proof.

## Next bounded task — roadmap review after the defensive closure (2026-11-21)

Review only; the recommendation was then implemented as its own batch (see P2 and
`BULL_RUSH_PLAN.md`). Nothing was rebuilt or re-checked for the review itself, and
no manual testing was requested.

**Recommendation: player-initiated bull rush**, as the next single bounded batch.

- **Player impact.** It is the only remaining P2 special attack a player can
  reach with shipped content, and it changes the grid rather than a number: push
  a blocker out of a doorway, break a flank, shove a foe off cover. Concealment,
  hard and low-wall cover and big-creature cover stay blocked on terrain and wall
  data that no campaign authors; iterative attacks need a full-attack action model
  that does not exist (one attack per turn today); AoE templates need grid areas
  plus new spell content.
- **Reachability.** Every shipped encounter has an adjacent Medium monster and a
  PC holding a standard action, so the action is usable as soon as it exists.
  `Character.size_category` already carries size with a Medium default and no
  monster authors one, so the printed "Large or smaller" gate is satisfied today
  and the Large refusal can be pinned with a test fixture instead of new content.
- **Dependencies already in place.** Size data, occupancy-aware pathing and
  blocked-square checks, the AoO machinery (`_provoke_single_opportunity`), and
  the trip batch's contested-check plus pending-decision pattern. The genuinely
  new pieces are forced movement of the defender with the rusher following, and
  one action control shaped like `Defend`/trip. Improved Bull Rush stays deferred
  behind the action, exactly as `FEATS_SKILLS_COVERAGE.md` records.
- **Automated verification.** Opposed Strength checks are seeded and
  deterministic. One focused `tests/test_bull_rush.gd` can pin push distance (5
  ft per 5 the check exceeds), stopping at a wall, an occupied square or the map
  edge, the defender's provoked attack on initiation, standard-action and
  once-per-turn gating, refusal against a Large defender, and the movement the
  rusher spends — all against the real `Encounter`, with no probe change. A
  windowed scenario is only warranted if the new control is not covered by the
  existing sidebar probe.

**Bull rush against the newly found regression or evidence gap.** No new
regression exists. The only defect from these batches was the superseded `-b`
build letting a live stance into the victory autosave; it is fixed in `7fae8d1`,
pinned by four real-path tests, contained in candidate
`defensive_actions_2026-11-21c`, and closed with the batch. The one new **evidence
gap** is that the cleanup has source-tree evidence only: the exported defensive
probe never reaches encounter resolution and never writes a save, so no exported
run demonstrates it. Closing that gap — a headless exported resolution smoke that
plays the QA encounter and re-reads `auto.json` — is cheaper than a rules batch
but changes nothing a player can do, and would re-prove what the 754-test suite
already pins. It ranks second, and should be taken before a second batch that
again depends on resolution-time behaviour, or folded into the first batch that
must be proved in the binary.

**Bounded scope if this is chosen (not started).** Player-initiated only, standard
action only (charge does not exist), Medium and smaller defenders, 5 ft per 5 of
excess, stop at wall/occupied/edge, defender's attack of opportunity on
initiation, no Improved Bull Rush, no AI use, no mounted interaction. Rules
citation to confirm when the batch opens: PHB p. 154 (bull rush) and the PHB
Improved Bull Rush entry. The plan is in
[BULL_RUSH_PLAN.md](BULL_RUSH_PLAN.md), including the verified printed text, the
pending-decision flow, the shared movement helpers, log wording, exclusions and
the deterministic test list. Done means focused tests, the full suite, both validators,
docs and a traceability row, and no rebuild unless the sidebar changes.

**Implemented as candidate `resolution_smoke_2026-11-21a` (2026-11-21).** The
bounded scope above was followed without widening it: `--resolution-smoke=<profile>`
in `src/main.gd`, the `qa_victory` fixture, a pre-decided follow through
`combat_bull_rush` + `combat_resolve_bull_rush(true)`, total defense held to
resolution, the autosave read and reloaded, 32 checks, isolated profile only. It
refuses a missing profile, a profile that does not contain `user://`, and a profile
inside the platform's roaming app-data folder, all before the first save access.
Neither the Push 5 ft / Follow buttons nor any click are exercised, so that decision
UI stays engine-test evidence. Source: suite 778/778, 7,979 assertions, both
validators, smoke PASS. Exported: clean `de79c17`, hash bound before/after,
validators and smoke PASS from the exe (see TEST_REPORT).

**State after the closure, kept separate.**

- *Confirmed defects:* none open in these areas. The stance leak is fixed and
  pinned; nothing else was reproduced and left unrepaired.
- *Deferred features:* mounted and NPC-initiated trip; concealment; hard cover,
  low walls, reach-melee cover and big-creature cover; Improved Precise Shot;
  grapple, disarm, sunder, bull rush; two-weapon fighting; iterative attacks; AoE
  templates; the deferred feats in `FEATS_SKILLS_COVERAGE.md`; any save-migration
  production step; the turning extensions.
- *Maintenance debt:* the migration table ships empty (`SAVE_VERSION` stays 1);
  exported acceptance is not repeated after every batch; `follow_focus`
  redundancy and the single-pane focus walk; minimal settings versioning; simple
  combat AI; no content hot reload; placeholder raycaster; shallow UI interaction
  coverage; GUT runs only in the source tree.
- *Evidence gaps:* the combat-scope cleanup is not demonstrated by any exported
  run; exported binaries are probe-covered, not suite-covered; physical held-key
  acceptance is pending; Enter activation of a focused modal button is
  native-only; no OS-level crash injection for save writes; case-sensitive
  filesystem behaviour is asserted through `_classify_names` only; the two
  creature-cover candidates remain unbound; the earlier `modal_focus` binary is
  missing; the Tumble +3/+6 stance values are reachable only through a fixture.

## Next bounded task — roadmap review after the bull rush closure (2026-11-21)

Review only. Nothing was implemented, rebuilt or re-checked for this section, and
no manual testing was requested.

**Recommendation: an exported resolution and action smoke** — one headless
application flag that, in the exported binary, plays the QA victory encounter
through the real `Game` wrappers, exercises the combat-scope cleanup and a bull
rush, resolves the fight, and then reads `auto.json` and reloads it.

- **Player impact.** It adds no play, but it protects the two most recent
  player-facing systems (stances that used to leak into the save, and the new
  bull rush) in the artefact players actually run. The alternative player-facing
  rules work is blocked on content rather than code: every shipped monster uses
  natural weapons, so disarm and sunder have no legal target; overrun needs
  movement through an occupied square and a defender's avoid choice; grapple is a
  subsystem; concealment needs terrain tags; iterative attacks need a full-attack
  action model. A rules batch now would add little reachable play.
- **Reachability.** The QA victory encounter, the `Game` combat wrappers, the
  autosave and `Game.load_game` all exist and are already used by
  `test_combat_scope_cleanup.gd`. The smoke only has to drive them behind a flag.
- **Dependencies.** One CLI flag in `main.gd` shaped like the existing `--demo-*`
  probes, an isolated `APPDATA`, the `qa_victory` fixture and no content, UI or
  save-schema change. The bull rush decision can be pre-decided through
  `bull_rush_active(target, {"follow": true})`, so no clicking is needed.
- **Automated verification.** The smoke is itself the check: it asserts the
  exported binary removes the stance effects before the save, that base AC is
  restored, that the bull rush moved the defender and the rusher by the printed
  distance, and that a reload shows the same state. It complements the suite
  instead of replacing it: the suite stays the rules authority, and the smoke
  proves the same paths survive packaging.

**Against a newly found regression.** There is none. The bull rush batch introduced
no confirmed defect: its 160 % layout failure was a probe artifact, fixed in
`9b0f046`, and the pre-fix export was withdrawn rather than accepted. The only
open confirmed defect remains the older one — reveal runs only while a modal is
open, because the campaign creator keeps its own keyboard path. That is a narrow
creator-scope inconsistency, not a regression from this batch, and it is smaller
and cheaper than the smoke, but it affects one screen a player may never open
while the smoke protects the main loop. If a rule change lands first, the reveal
defect stays the next fix.

**Bounded scope if the smoke is chosen (not started).** One exported flag, one
scenario, assertions on the saved effects list, AC, both cells after the rush and
the reloaded state; isolated profile only; no new content, no UI, no changes to
the suite. Done means the flag passes from a bound candidate, its log records the
executable hash before and after, and the docs label it as packaging evidence for
those two behaviours only — not as a replacement for the rules suite.

**State after the closure, kept separate.**

- *Confirmed defects:* the reveal-outside-modals inconsistency in the campaign
  creator (older, unfixed, creator-only). The stance leak is fixed and closed;
  bull rush introduced none.
- *Deferred features:* the charge form, Improved Bull Rush (unblocked but still
  deferred), the 25 % redirect, mounted and AI bull rushes, multi-square
  creatures, terrain effects; concealment, hard/low-wall and reach-melee cover;
  grapple, disarm, sunder, overrun; two-weapon fighting and iterative attacks; AoE
  templates; any save-migration production step; the turning extensions.
- *Maintenance debt:* empty migration table, acceptance not repeated per batch,
  `follow_focus` redundancy, single-pane focus walk, minimal settings versioning,
  simple AI, no content hot reload, placeholder raycaster, shallow UI coverage,
  source-only GUT; plus `resolve_bull_rush_decision` trusts the recorded cells
  instead of re-checking them, which is unreachable today but is defence in depth
  worth adding when a second pending-decision type can coexist.
- *Evidence gaps:* no exported run exercises the cleanup or bull rush (the
  recommended smoke); exported binaries are probe-covered only; the earlier
  combat layout PASS at 160 % was under-covered for nested scrollers before
  `9b0f046`, and that correction was never applied to the archived candidates;
  physical held-key acceptance is pending; Enter activation is native-only; no
  OS-level crash injection; case-sensitive filesystem behaviour is synthetic;
  the creature-cover candidates are unbound; the `modal_focus` binary is missing;
  the Tumble stance values are fixture-only; no human playtest was run or
  requested.

## Next bounded task - roadmap review after the resolution smoke (2026-11-21)

Review only. Nothing was implemented, rebuilt or re-checked for this section, and
no manual testing was requested. The smoke it follows is closed within its limits
in [TEST_REPORT.md](TEST_REPORT.md): `resolution_smoke_2026-11-21a`, source
`de79c17`, SHA-256 `c1cff4cc...035d9a75`, 32 checks from the exe, hash bound before
and after.

**Recommendation: make focus reveal work on the campaign creator too.** It is the
one confirmed player-facing defect left, and the review found it cheaper than the
roadmap assumed: the nested-pane walk it needs already exists for modals, so the
work is routing focus changes outside a modal through the same walk rather than
building new scrolling machinery.

### Candidate 1 - creator reveal inconsistency (recommended)

- **Defect, confirmed by reading the code.** `_reveal_modal_focus()` returns early
  when `modal == null` (`src/main.gd:7674`), and it is the only focus-changed hook
  (`get_viewport().gui_focus_changed` -> `_on_modal_focus_changed`, `src/main.gd:220`).
  Outside a modal, Tab and Shift+Tab fall through to Godot's automatic traversal
  (`_input` handles Tab only inside its `if modal != null:` branch). The creator's
  own scrolling runs only from the `focus_*_section()` QA aids and from
  `_focus_control()`, which the diagnostics jump uses - nothing on focus change.
  A field below the fold therefore takes the ring while staying invisible.
- **Player impact.** Authors editing a shipped screen: the creator is longer than
  one 720-high view - its own `focus_*_section()` aids exist precisely because
  later sections sit below the fold - so tabbing to a field lower in the form
  silently moves the ring off-screen. It affects authoring rather than play, but
  every player-created campaign goes through it.
- **Reachability.** High and immediate: the creator is reachable from the main
  menu, the defect needs no unusual content, and at 160 % text the form is longer
  still, so it is routine rather than marginal.
- **Dependencies.** None outside `src/main.gd` and `src/ui/campaign_creator.gd`:
  a reveal entry point that accepts the active screen's root and walks its
  `ScrollContainer` ancestors - the same `_reveal_in_pane` step that already
  handles a row inside the list's scroller inside the sidebar's. No content, no
  rules, no save schema, no new control.
- **Automated verification.** A headless probe in the shape of
  `--creator-interaction-probe`: open a long draft, send Tab enough times to leave
  the first viewport, and assert the focused control's global rect is enclosed by
  the viewport at 1280x720 at 100 % and 160 % text; the same run can assert
  Shift+Tab brings the earlier field back and that no modal behaviour changed.
  The existing creator probes and both validators guard the rest of that screen;
  the suite already guards the modal walk.
- **Bounded scope.** One reveal path plus the creator hook, one probe, docs rows.
  Done means the probe passes at both scales from source and one bound exported
  candidate, and the modal walk's existing tests stay green. It should not
  generalise every screen at once: exploration, inventory and settings already go
  through the modal or the body's `follow_focus`, and widening beyond the creator
  is where the risk enters.

**Implemented as candidate `creator_focus_2026-11-21a` (2026-11-21).** The fix is
the bounded scope above: `_on_modal_focus_changed` now calls
`_reveal_focused_control`, which keeps the modal as the root when one is open and
uses the campaign creator screen otherwise, through the same `_reveal_in_pane`
walk. `--creator-focus-probe` was written first and failed (98/182 and 145/182
focused controls outside the viewport at 100 % and 160 %); after the fix it is 0
outside at both scales, with Tab/Shift+Tab order, the dropdown popup, Settings over
the creator and focus restore pinned. Suite 778/778, both validators, and a bound
exe (clean `8f625f4`, `53ae457e...c0017b`) that passes the probe. The probe checks
rects, not rendered pixels. Closed as accepted within those limits (2026-11-21);
see TEST_REPORT.

### Candidate 2 - Improved Bull Rush

- **Player impact.** A fighter with the feat gets +4 on the rush check and the
  defender loses its reaction. Meaningful, but only for a character built around
  it, and it changes an outcome the new smoke already covers as it stands today.
- **Reachability: none for a player today.** No party character in
  `content/shared/characters.json` has Power Attack (kaelen has Iron Will and
  Weapon Focus, ysolde Dodge and Weapon Finesse), and there is no level-up or
  feat-selection screen: feats enter the game from content JSON, and QA probes
  append Power Attack in code (`src/main.gd:4092`, `:4131`, `:6515`). The feat
  would be reachable only after a content edit or through a QA fixture, so the
  batch would ship a rule most players could never select.
- **Dependencies.** A `Feats.CATALOG` entry with the Power Attack prerequisite and
  the +4 modifier (`src/core/feats.gd`, shaped like `improved_trip` at line 420),
  a caller in `bull_rush_active` for the check bonus and a skip of
  `_provoke_single_opportunity` where the deferred note sits
  (`src/core/encounter.gd:1481`), plus content if it is to be playable. Docs rows
  in `FEATS_SKILLS_COVERAGE.md`, `SUPPORTED_FEATURES.md` and `TRACEABILITY.md`.
- **Automated verification.** Unit tests for the catalog entry, prerequisites and
  the +4 on the opposed check; encounter tests for the missing reaction and for a
  rush where the reaction would have dropped the rusher; the existing bull rush
  suite as the regression net; and an exported run only if the smoke's fighter is
  given the feat, which would mean changing the smoke's fixture.
- **Why not first.** It is a rules addition with no player route, it edits the
  resolution path the smoke just bound, and the cleanup defect above is both
  player-facing and smaller. It stays unblocked and available after that fix.

### Candidate 3 - what the review newly found

No new confirmed defect. Two findings do change the shape of the roadmap:

- The reveal gap is a routing gap, not a missing feature: `_reveal_in_pane`
  already walks every ancestor scroller, so the creator fix reuses proven code
  and the 160 % nested-scroller lesson applies to it directly.
- Improved Bull Rush's blocker is content and UI, not rules plumbing. That makes
  it a content batch in disguise, and it should not be scheduled as a rules-only
  task.

The review also re-checked the smoke's own uncovered surface and found nothing to
add: it drives the wrappers, not the buttons, and that stays the stated limit.

**State after the review, kept separate.**

- *Confirmed defects:* none. The reveal-outside-modals inconsistency in the
  campaign creator was fixed in `8f625f4` and accepted as candidate
  `creator_focus_2026-11-21a`; the stance leak and the bull-rush layout probe
  artifact are fixed and closed, and the resolution smoke found no new failure.
- *Deferred features:* the charge form, Improved Bull Rush (unblocked, deferred,
  and gated on content/feat selection), the 25 % redirect, mounted and AI bull
  rushes, multi-square creatures, terrain effects; concealment, hard/low-wall and
  reach-melee cover; grapple, disarm, sunder, overrun; two-weapon fighting and
  iterative attacks; AoE templates; any save-migration production step; the
  turning extensions; a level-up and feat-selection screen.
- *Maintenance debt:* empty migration table, acceptance not repeated per batch,
  `follow_focus` redundancy beside the reveal walk, one pane following focus per
  key press, minimal settings versioning, simple AI, no content hot reload,
  placeholder raycaster, shallow UI coverage, source-only GUT, and
  `resolve_bull_rush_decision` trusting its recorded cells instead of re-checking
  them (unreachable today, defence in depth when a second pending decision type
  can coexist).
- *Evidence gaps:* the Push 5 ft / Follow decision UI is not exercised by the
  exported smoke; other actions' exported behaviour is probe-covered only; the
  archived pre-`9b0f046` combat layout PASS at 160 % was under-covered for nested
  scrollers and was never corrected retroactively; physical held-key acceptance is
  pending; Enter activation is native-only; no OS-level crash injection;
  case-sensitive filesystem behaviour is synthetic; the creature-cover candidates
  are unbound; the `modal_focus` binary is missing; Tumble stance values are
  fixture-only; the resolution smoke's winning seed is fixture-selected (7302);
  no human playtest was run or requested.

## Next bounded task - roadmap review after the creator-focus closure (2026-11-21)

Review only. Nothing was implemented, rebuilt or re-checked for this section, and
no manual testing was requested. The creator focus fix is closed within its limits
in [TEST_REPORT.md](TEST_REPORT.md) (`creator_focus_2026-11-21a`, source
`8f625f4`, SHA-256 `53ae457e...c0017b`, 0 of 182 controls outside the viewport at
both scales from source and exe).

The confirmed-defect list is empty, so this review ranks by player value rather
than by defect.

**Recommendation: a planning-only task - design level-up and feat selection (no
code).** It is the largest remaining player-facing gap, it blocks Improved Bull
Rush and every other level- or feat-gated rule, and its implementation spans
content schema, rules, save compatibility and a new screen - too much for one
bounded batch, so it needs a plan before it needs a commit.

### Why planning, now

- **The dead end is already visible to a player.** Encounters award XP
  (`src/game_state.gd:1734`) and effects can add it (`:1391`), the character sheet
  prints it (`src/ui/panels.gd:63`), and the demo party is authored at level 3
  with 3,000 XP - but nothing compares XP to a threshold, changes `level`, or
  grants anything. `level` is only read from content (`src/core/character.gd:681`).
- **The rules engine already assumes levels it cannot gain.** Feat prerequisites
  can require a character level (`src/core/feats.gd:598`), skill rank caps are
  `level + 3` (`src/core/skills.gd:187`), and cleric turning uses `level`
  (`character.gd:127`). Feats are displayed on the sheet
  (`src/ui/panels.gd:146`) but never chosen.
- **What a level-up screen blocks:** Improved Bull Rush (needs Power Attack),
  Weapon Specialization (fighter level 4), iterative attacks (BAB progression),
  skill points and their caps, spell learning and slots, and any class feature
  beyond the cleric turning level - plus the feat-selection screen that would make
  `Feats.CATALOG` reachable to a player at last.
- **Nothing exists to build on at the data layer.** There are no class
  progression tables in `content/`: no classes file, no per-level HP, BAB, saves,
  skills, spells or bonus-feat slots. `base_attack` is authored per character
  (`character.gd:683`), not derived. The characters file holds five party members - all
  level 3 with 3,000 XP - and the monsters.
- **The scale is the point.** A plan has to decide the class-table content shape,
  XP thresholds, HP policy (fixed average or roll), skill points, feat and ability
  increase slots, spell progression, how existing level-3 saves are read, and what
  the screen looks like at 1280x720 and 160 % - before any of it is coded.

**Bounded deliverable for the planning task.** One design document (plus rows in
the coverage/roadmap docs as needed) covering: the class progression data shape
and its validation; the XP table for levels 3-4 only (the demo's reachable range);
HP, BAB, save, skill, feat/slot and spell-progression decisions for the five demo
classes (fighter, rogue, cleric, wizard, sorcerer); save compatibility for characters already at level 3; the screen's flow
and keyboard requirements; a test and probe plan shaped like the creator focus
probe; and a risk list that says what stays deferred (multiclassing, prestige
classes, XP for crafting, retraining). No code, no content, no schema change lands
with it. If the plan finds the level-3-to-4 slice still needs more than one
implementation batch, it should say so and split it there.

**Plan written: [LEVEL_UP_PLAN.md](LEVEL_UP_PLAN.md) (2026-11-21).** It confirms
what exists (XP and level are written nowhere but content and saves; no class
table; level feeds only the skill cap, feat prerequisites, cleric turning and the
sheet), then decides the 3-to-4 step for the five shipped classes with PHB
citations and labelled adaptations: 6,000 XP threshold, fixed-average HP, printed
BAB/saves, skill points and the fighter-only feat slot, ability increase, spell
slots under the engine's reduced model, no schema change, player-made choices.
It defines the modal flow, keyboard path and 160 % needs, a GUT and
`--level-up-probe` plan shaped like the creator focus probe, five separately
acceptable batches (`level_tables` first), and the exclusions (multiclassing,
prestige classes, retraining and the rest). Nothing was implemented.

### Candidate 2 - modal reveal debt (`follow_focus` beside the walk)

The one implementation candidate kept warm, not chosen now.

- **What it is.** `open_modal` sets `content_scroll.follow_focus = true`
  (`src/main.gd:7523`) while `_reveal_focused_control` also scrolls the body and
  every wrapper pane. Two mechanisms move the same pane.
- **Player impact: possible, unconfirmed.** In a synthetic modal with a nested
  scroller the coexistence left the focused row above the viewport once at 100 %
  (rect y = -55 after focusing a deep row); the real Settings panel passed at both
  scales, and no player report exists. It is the only debt item with a plausible
  visible symptom.
- **Reachability.** Any modal whose content nests its own `ScrollContainer` - the
  Settings list, the party sheet and inventory per the reveal comment - at a
  window short enough to scroll.
- **Dependencies.** One line in `open_modal` plus removing the assumption in the
  reveal comment; no content, rules or save change.
- **Automated verification.** `--creator-focus-probe` already covers a real nested
  Settings modal over the creator at both scales; `tests/test_modal_focus.gd` and
  the settings probes cover the rest, and the suite must stay green.
- **Why not now.** It fixes an unconfirmed symptom in a path that currently passes
  every check, while progression is a gap every player meets. It remains the best
  small code batch if a rules/UI batch is not wanted yet.

### Candidate 3 - Improved Bull Rush

- **Player impact.** +4 on the rush check and the defender loses its reaction, for
  a fighter built around it.
- **Reachability: still none.** No party member has Power Attack, and with no
  feat selection there is no route to it. It is blocked behind Candidate 1, not
  behind rules work.
- **Dependencies.** A `Feats.CATALOG` entry with the Power Attack prerequisite, a
  bonus in `bull_rush_active`, a skip of `_provoke_single_opportunity`, and a
  content or feat-selection route to acquire it.
- **Automated verification.** Catalog and prerequisite tests, encounter tests for
  the missing reaction, the bull-rush suite, and the exported resolution smoke if
  its fixture gains the feat.
- **Why not now.** It would ship a rule no player can select; its cost falls
  sharply once feat selection exists.

### Candidate 4 - evidence gaps a batch cannot close

Held-key behaviour, Enter activation and OS-level input acceptance need a person
at a keyboard; no automated batch can produce that evidence, and no manual testing
is requested here. Save-migration evidence waits for a schema change. These are
listed, not scheduled.

### Does any debt or gap now have player impact?

- *Maintenance debt with plausible player impact:* the shared modal body's
  `follow_focus` beside the reveal walk (double scroll; the only one with a
  reproduced off-screen row, synthetic); shallow UI coverage, which is why keyboard
  paths are probe-checked rather than suite-checked; the empty migration table,
  which is latent until the first schema change; simple AI, which a player feels as
  enemies that never bull rush, trip or use items.
- *Maintenance debt without player impact today:* source-only GUT, minimal
  settings versioning, no content hot reload, the placeholder raycaster (visible
  but deliberate), the probe-heavy `main.gd`, `resolve_bull_rush_decision`
  trusting recorded cells (unreachable), and acceptance not repeated per batch.
- *Evidence gaps with player impact:* physical held-key acceptance pending and
  Enter activation proven natively only - keyboard players depend on both, and no
  automated substitute exists; the suite's shallow UI interaction coverage, partly
  offset by the creator, layout and settings probes.
- *Evidence gaps without player impact:* no OS-level crash injection, synthetic
  case-sensitive filesystem behaviour, the unbound creature-cover candidates, the
  missing `modal_focus` binary, fixture-only Tumble values, the resolution smoke's
  fixture-selected seed, and the archived pre-`9b0f046` 160 % layout
  under-coverage.

**State after the review, kept separate.**

- *Confirmed defects:* none. The creator reveal gap was fixed in `8f625f4` and
  closed as `creator_focus_2026-11-21a`; the stance leak and the bull-rush layout
  probe artifact remain fixed and closed, and the last two probes found no new
  failure.
- *Deferred features:* level-up and feat selection (the recommended plan); the
  charge form; Improved Bull Rush (blocked behind feat selection); the 25 %
  redirect; mounted and AI bull rushes; multi-square creatures; terrain effects;
  concealment, hard/low-wall and reach-melee cover; grapple, disarm, sunder,
  overrun; two-weapon fighting and iterative attacks; AoE templates; any
  save-migration production step; the turning extensions; Weapon Specialization
  and the rest of the level-gated feats.
- *Maintenance debt:* empty migration table, acceptance not repeated per batch,
  `follow_focus` redundancy beside the reveal walk, one pane following focus per
  key press, minimal settings versioning, simple AI, no content hot reload,
  placeholder raycaster, shallow UI coverage, source-only GUT, probe-heavy
  `main.gd`, and `resolve_bull_rush_decision` trusting its recorded cells instead
  of re-checking them.
- *Evidence gaps:* the Push 5 ft / Follow decision UI is not exercised by the
  exported smoke; exported rules behaviour beyond that smoke is probe-covered
  only; physical held-key acceptance is pending; Enter activation is native-only;
  no OS-level crash injection; case-sensitive filesystem behaviour is synthetic;
  the creature-cover candidates are unbound; the `modal_focus` binary is missing;
  Tumble stance values are fixture-only; the resolution smoke's winning seed is
  fixture-selected; the creator focus probe checks rects, not rendered pixels, and
  pins Tab order only over the map-cell stretch; no human playtest was run or
  requested.

## Next bounded task — roadmap review after the level-up closure (2026-11-22)

Review only. Nothing was implemented, rebuilt, re-exported or re-checked for this
section, and no manual testing was requested. It reads `PROGRAM_PROGRESS.md`,
`TRACEABILITY.md`, `TEST_REPORT.md`, `LEVEL_UP_PLAN.md` 14.11 and
`FEATS_SKILLS_COVERAGE.md`, then the implementation behind the two recorded
level-up deferrals.

**The workstream is closed.** The level-up feature is accepted within the limits
recorded at `9216ced`: source `84d8fb7`, suite 877/877 (9,343 assertions, 65
scripts, 0 failed), both validators PASS, `--level-up-probe` 172 + 173 = 347
checks with 0 failures at 100 % and 160 %, and the same 211 passing check labels
inside candidate `level_up_ui_2026-11-22` (110,832,568 bytes, SHA-256
`2f890629160847962a21a8d9f7ced0178360bd2eb0d1e0a9c1c5b92ba3d24cff`, unchanged
before and after). The evidence is control rectangles and state. The boundary
line at the top of this file (778/778) predates it; the numbers above are the
current ones.

The confirmed-defect list is empty, so this review ranks by player value rather
than by defect.

### Deferral 1 - the sorcerer's 2nd-level spell pool is a content gate, not a defect

- **What the engine does.** `LevelChoices.choices` adds `"spell"` to the blockers
  when a sorcerer has no legal 2nd-level option (`src/core/level_choices.gd:48`),
  `LevelUp.apply` refuses on that blocker, and nothing is written. The pool is
  every authored spell whose `level` is the new spell level and whose class list
  includes `sorcerer`, minus the ones the character already knows
  (`_spell_rows`, `level_choices.gd:266-292`). `content/shared/spells.json`
  holds exactly one such spell: `scorching_ray`.
- **What content holds.** One sorcerer exists in all content - Mira, 3rd level,
  knowing `magic_missile` and `mage_armor` - so her single step offers exactly
  one legal spell, which is the one the accepted probe chooses.
- **What the gap would be.** A sorcerer authored with `scorching_ray` already
  known, or authored after that spell is renamed, would show a Spells step with
  an empty list; the sheet still offers the button, because eligibility is level
  and XP only (`LevelUp.eligibility`), so Confirm could never succeed. That is an
  authoring dead end; no player meets one today.
- **What checks it.** Nothing: `ContentDiagnostics` has no spell or feat rows, and
  neither validator reads the choice pools. The same shape exists for the
  fighter's bonus feat - ten catalog entries carry `fighter_bonus`, and a fighter
  who owned all of them would have an empty feat list with the group still
  required.
- **Verdict.** Not a defect, and not a batch of its own. Fold "every required
  group has at least one legal option" into the next content-diagnostics work,
  where it costs one pass and one fixture.

### Deferral 2 - the level survives without a level-up autosave

- **Order in the victory path.** `_resolve_encounter` grants the XP
  (`src/game_state.gd:1729-1738`), recovers ground items, returns to explore and
  only then writes `save_game("auto")` (`:1756`). The write therefore already
  holds the paid XP, before the level-up is offered.
- **What that guarantees.** Paid XP and eligibility survive the recorded autosave:
  reloading it re-offers the step, the draft starts empty, and the same choices
  can be made again. An unsaved applied level and its choices do not survive;
  they reach disk at the next manual save or auto boundary, so quitting straight
  after applying loses that work, never the entitlement.
- **Where the applied step reaches disk.** The next manual save, or any auto
  boundary: a world-changing interaction (`_autosave_after_interaction`), the end
  of a dialogue (`on_dialogue_finished`), an encounter's start and its victory.
  The level-up screen itself deliberately writes nothing (`LEVEL_UP_PLAN.md` 14.4).
- **Evidence gap, not a defect.** No probe reloads the pre-level-up autosave and
  applies again; the probe's save/reload steps cover the post-apply state. Each
  piece is tested; the recovery path is not walked as one.
- **Verdict.** Not a defect, and a dedicated level-up autosave would add a second
  save policy rather than repair a loss. Keep it deferred; if a later save batch
  lands, add the reload-then-reapply case there.

### New finding: no shipped campaign awards enough XP to reach the threshold

- All five party members are authored at 3,000 XP
  (`content/shared/characters.json`) and `LevelUp.XP_THRESHOLD` is 6,000.
- Authored encounter XP totals 2,200: `ravenloft_demo` 1,500 across five
  encounters (`qa_turn_undead` 0 and `qa_victory` 150 are QA fixtures),
  `ashwick_ferry` 500 across two, `hollow_lantern` 200 across one. Effect XP adds
  700 (`ravenloft_demo/dungeon.json` 500, `dialogue/corvin.json` 200).
- Those figures are an inventory, not a route: `ravenloft_demo`'s pact (200) and
  crypt fight (450) are mutually exclusive, and `qa_victory` has no content
  trigger. One ordinary route earns at most 1,850 (300 + 450 + 500 + 600), so a
  party starting at 3,000 reaches **4,850**; a player who completes `drowned_bell`
  has a floor of 3,700. The other campaigns' 700 is not available either: XP
  cannot carry between campaigns, because `new_game` rebuilds every character
  from content and saves are pinned per campaign.
- Every acceptance run so far crosses the threshold from a fixture - the probe
  sets XP near it and lets one victory pay the rest - which the records state as
  fixture setup. The crossing is therefore evidenced in a test, not in play.
- This is a **content gap, not a code defect**: the engine does what it says, and
  the premise in this file's own planning brief ("the XP table for levels 3-4 only
  (the demo's reachable range)") is short by 1,150 XP on the best ordinary route,
  and by 2,300 XP for a player who completes the quest.

### Four lists, kept separate

**Confirmed defects.** None open. Two were found and fixed inside batch 4 and are
pinned by tests: the validate/apply refusal code (14.15) and the modal body's End
key (14.18). This review produced no failing case, and neither deferral above is
promoted to one.

**Deferred features.** Levels 5 and above; more than one level per step; NPC
advancement; the printed fighter bonus feats this slice does not implement
(Weapon Specialization, Improved Bull Rush, Quick Draw, Two-Weapon Fighting); the
sorcerer pool content check; any play-path autosave after a level-up; a keyboard
shortcut straight to the sheet; and, newly, nothing makes the level-up reachable
in the shipped content (above). Also open from the wider roadmap: grapple, disarm
and sunder; concealment and hard cover; AoE templates; conditions beyond the
current set; encumbrance; the content-pipeline items; a save shortcut; the
campaign layer.

**Maintenance debt.** The singular `modal` field; the draft living in the screen
because the builder rebuilds the body; arrows reserved for body scrolling;
`follow_focus` beside the reveal walk; source-text guards that cannot see a
string-built call; `Panels.character_sheet` now a place where a character
changes; acceptance not repeated per batch; the empty save-migration table;
shallow UI suite coverage; probe-heavy `main.gd`; the placeholder renderer; no
content hot reload. One record inconsistency was found and is fixed in this
commit: `TRACEABILITY.md` rows 3 and 22, `SUPPORTED_FEATURES.md` and `README.md`
still said there was no advancement at all.

**Evidence gaps.** Control rectangles, not pixels, at both scales; the sorcerer
walked through Spells but not end to end; the cleric and wizard not walked at all
(fighter end-to-end, rogue no-write only); no window seen; no human playtest; one
window size and one OS; held-key and Enter activation need a person; no
reload-then-reapply probe for an unapplied level-up.

### Recommendation: a planning-only batch - how the demo reaches 4th level

The largest player-facing feature in the project cannot be reached by playing it.
Before any number moves, one short design note should settle:

1. **The XP model.** Printed DMG by-CR awards per encounter, a campaign XP
   budget, or a quest award at the climax. Encounter XP here is already an
   adaptation, so the note has to pick one and cite it.
2. **The total.** At least 800 XP above the demo's current 2,200, from the
   authored 3,000 start, so one step is reachable without a fixture.
3. **Pacing.** Whether the level-up lands at the campaign's climax or earlier; it
   is one step per character, so it happens once.
4. **The QA fixtures.** Whether `qa_victory` and `qa_turn_undead` count as story
   awards or stay test-only.
5. **The author-facing line.** Each campaign's reachable XP against 6,000 in
   `--validate-diagnostics`, informational rather than a failure, because a short
   campaign legitimately ends below it.
6. **The probe change.** Reach eligibility from authored awards only, then reuse
   the accepted level-up probe; no fixture.
7. **Test churn.** Which tests assert XP totals and would move.

**Why planning rather than code.** The numbers are a pacing decision the
repository has no printed authority for, and changing them without that decision
would trade an unreachable feature for a different balance. It is also where
deferral 1's completability check belongs, since both ask whether a player can
actually complete the step.

**Dependencies.** `LevelUp.XP_THRESHOLD`, the five authored characters, three
`encounters.json` files, two effect awards, the probe's fixture step, and
`--validate-diagnostics`.

**Exclusions.** No threshold change (6,000 is printed); no levels 5 and above; no
new spells or feats; no UI, schema or save change; no other campaign's content;
no manual testing.

**Plan written: [DEMO_ADVANCEMENT_PLAN.md](DEMO_ADVANCEMENT_PLAN.md) (2026-11-22).**
It verifies the award ledger and corrects this review's arithmetic: the demo's
authored 2,200 is an inventory, not a route; one ordinary route earns 1,850; and
a completing player's floor is 700. It chooses a completion milestone on the bell
sized to that floor - 2,300 XP, taking the floor to exactly 6,000 - and names the
route, the play left at 4th level (the town square fight), the exact `dungeon.json`
change, the informational diagnostics line, the completability check, the tests
and the probe. Nothing was implemented; no checks were run.

### Not recommended now

- **Levels 5 and above.** Even if built they would be unreachable: 10,000 XP
  against 4,850 available on one ordinary route, and no 3rd-level spell exists in
  content for the casters' step.
- **Improved Bull Rush.** Still unreachable after the accepted feature: the step
  grants one feat slot at 4th level, and the feat needs Power Attack first, so no
  character can hold both before 6th level without a content edit.
- **The completability guard alone.** No current player impact; it rides along
  with the reachability work for one pass.
- **`follow_focus` beside the reveal walk.** Still unconfirmed - 4c's walk
  revealed all 46 rows at both scales - and it remains the best small code batch
  if a rules batch is not wanted.
- **Grapple, disarm and sunder.** Larger than one batch each, but reachable in
  play, which makes them the strongest rules alternative to this recommendation.

## P0 — Verify and harden the current slice

1. **Finish the manual UI interaction pass.** **Done:** Restore Default Controls
   ships in the Settings panel behind a confirmation dialog and is covered by the
   persistence test; E3 victory/return-state persistence is recorded in
   [PHASE3_VERIFICATION.md](PHASE3_VERIFICATION.md). Remaining: OS-level high-DPI
   and display-scaling checks. The mouse-wheel, Tab/Enter and focus-return checks
   were verified natively on 2026-11-20 (see [TEST_REPORT.md](TEST_REPORT.md)).
2. **Audio review.** Listen to all 14 placeholders in a windowed run; confirm loops,
   volume sliders and ducking behavior. Replace only after the hooks are proven.
3. **Resolution/DPI pass.** **Corrected 2026-11-20.** The client area is the
   layout surface (`display/window/stretch/mode="disabled"`), so a bigger window
   now gives the UI more room instead of magnifying a fixed 1280×720 canvas.
   1280×720, 1600×900, 1920×1017 maximized and 1920×1080 fullscreen are verified
   at 100 % and 160 % text by `--layout-probe`; 1024×600 was never a supported
   size (the window minimum is 1280×720). Remaining: OS-level high-DPI/display
   scaling; the mouse-wheel and focus checks are native-verified (see
   [TEST_REPORT.md](TEST_REPORT.md)).
4. **Save migration policy.** **Foundation landed 2026-11-20; no production step
   ships and `SAVE_VERSION` stays 1.** `src/core/save_migrations.gd` holds the
   ordered table (empty in production), `SUPPORTED_MIN_VERSION = 1`, a test-only
   target override, and `SaveSystem.read_save` now upgrades in memory or refuses
   with the same message as before; a migrated save is never written on load.
   Settings carry `[meta] version=1`, clamp on load, keep unknown sections and
   keys, and refuse to write a file from a newer build. The first real schema
   change is still open; the design it should follow:
   - **Read-only hook.** After parsing, `read_save` hands the payload to a new
     `SaveMigrations.upgrade(data, from, SAVE_VERSION)`: an ordered table of pure
     `Dictionary -> Dictionary` steps (`1 -> 2`, `2 -> 3`, ...), applied in
     sequence, each copying the payload so unknown fields survive. A step returns
     `null` when it cannot honestly upgrade, which keeps today's refusal message.
     A migrated save is **not** written on load - the upgrade lands only when the
     player saves again - so a refused or interrupted save still cannot rewrite
     player data. **Recovery landed 2026-11-20:** that write path is no longer
     unread - a missing/unreadable primary falls back to the backup and then the
     temp file, each validated by the ordinary load checks, and a later save
     reserves a free working name (numbered copies) instead of deleting or
     reusing crash artifacts, and one exact parser (canonical, numbered 2-100 and
     legacy `.w` names) decides what discovery, listing and deletion touch. A newer
     primary keeps the refusal; the file is still never written on load.
   - **Version floor.** `SUPPORTED_MIN_VERSION = 1`: older files are refused with
     "too old to migrate" rather than by accident, and a newer file than the
     binary keeps the current incompatible-version refusal (no downgrade path).
   - **Content stays separate.** `content_version` keeps its refusal. A save names
     item, character and area ids that only the campaign author can re-map, so
     content compatibility is an authoring decision per campaign, not a shared
     hook; this also matches the existing compat-probe expectations.
   - **Settings.** Add `[meta] version=1` to `settings.cfg`, clamp `text_scale`
     (0.8-1.6, as the setter does) and volumes (0-1) on load, keep applying
     keybinds only when `InputMap.has_action` passes, and make `save_settings`
     merge into the loaded `ConfigFile` instead of writing a fresh one, so a newer
     build's sections and keys are not dropped.
   - **Policy, stated once:** saves are forward-migrated on read and rewritten
     only on an explicit save; newer-than-binary and content-version mismatches are
     refused with the file untouched; every migration step stays in the table
     forever and is pinned by a fixture.
   - **Tests (smallest set).** `tests/test_save_migrations.gd` with one shipped
     fixture per step asserting added fields, preserved unknown fields and
     unchanged file bytes on read; refusal for a future version and for a
     below-floor version; a `null` step leaving session and file untouched; and a
     `load_game` on a migrated payload. Extend the settings persistence test with
     an unknown-section round trip and an out-of-range `text_scale`, and add the
     unknown-field case to `--save-compat-ui-probe` rather than a new probe.
5. **Export build.** **Done, with limits.** `export_presets.cfg` is present and
   candidates are exported to `builds/qa/candidates/<id>/` with a `BUILD.txt`
   identity and hash; the latest verified candidate and its probe results are
   recorded in [TEST_REPORT.md](TEST_REPORT.md). What remains is repeating the
   full acceptance pass on a single build after the next rules batch.

**Acceptance:** a fresh user can complete the loop, save, quit, relaunch, continue,
and change a key binding without editing files or hitting an unexplained error.

## P0.5 — Foundation contracts (2026-11-05)

The feat queue is paused; see `PROGRAM_PROGRESS.md` for the reassessment. Shared
groundwork now owns one authored effect/condition registry (`ContentSpec`) with
validation and runtime guards, documented contracts for passive modifiers,
active actions, decisions/reactions, checks and persistence, and demonstration
runs that cannot write player saves.

Ranked next work:

1. One typed pending-decision record with a resolver table (replaces the
   per-decision dictionaries and the duplicated UI branches).
2. Content manifest. The CLI half already exists: `--validate-campaigns` and
   `--validate-diagnostics` exit non-zero on content errors without running GUT.
   A content *manifest* is still open. `--validate-content` does not exist and
   must not be scripted.
3. Data-driven passive feats (move `Feats.CATALOG` rows to JSON, keep compiled
   defaults for compatibility).
4. Save schema migration: the read-only hook, version floor, settings versioning
   and recovery landed on 2026-11-20, but **no production step ships** (`steps`
   is empty and `SAVE_VERSION` stays 1). The first real schema change is still
   open; the design is under P0 item 4.
5. Spell resolution handler table, matching the effect-registry pattern.

## P1 — Campaign content pipeline

1. **External content workflow.** Keep JSON and add a content manifest plus
   stable id checks across files. The command-line half is already available as
   `--validate-campaigns` / `--validate-diagnostics`; do not add or call a
   `--validate-content` alias.
2. **Dialogue authoring conveniences.** Node `once`/visited guards, party-member
   speaker selection, portraits, and a debug node viewer.
3. **Quest chains.** Multiple concurrent quests, prerequisite quests, failure
   states, and journal sections.
4. **Area transitions.** Multiple dungeon maps, stairs/doors, persistent per-area
   state, and a world map.
5. **Encounter authoring.** Named monster templates, waves, terrain tags, and
   victory/defeat effect hooks already partly present.
6. **Content tests.** Golden-path tests per conversation and per encounter, plus a
   validation test that scans every content file.

**Acceptance:** a writer can add a three-scene, two-quest chapter with two
conversations and one encounter using only JSON and documented effects, and the
validation suite catches broken links before runtime.

## P2 — Rules depth

Prioritize mechanics that appear often in play and are testable in isolation.
The shared skill engine and forty-one feats (including all fourteen +2/+2
skill feats, the seven proficiency feats, Extra/Improved Turning, Power Attack
and Combat Expertise) are done; continue in dependency order with the special
attacks, with spell-school feats waiting on a saving-throw spell.

1. **Full attack / iterative attacks** and two-weapon fighting.
2. **Grapple, disarm, sunder, bull rush** as explicit combat actions with
   contested checks and provoked attacks. Trip is implemented for the
   player-initiated path (PHB pp. 158-159), including prone, counter-trip, weapon
   drop/pickup and Improved Trip; NPC-initiated and mounted trip remain out of
   scope. Power Attack and Combat Expertise are implemented, so Improved
   Disarm/Bull Rush/Overrun/Sunder become candidates once those actions exist.
   **Fighting defensively and total defense are done and accepted (2026-11-21):**
   a selection commits only on a legal attack, the active stance is locked until
   the next turn, total defense is a standard action that replaces a selection,
   and both interact with Combat Expertise and normal/touch AC as printed.
   **Closed 2026-11-21** as accepted within the recorded limits, together with the
   encounter-resolution cleanup that removed their leaked bonus. Grapple, disarm,
   sunder and bull rush remain open until the bull rush batch below.
   **Bull rush is done and accepted (2026-11-21) for the player-initiated path:**
   standard action, provoking entry, opposed Strength checks with size and
   stability, 5 ft plus 5 ft per 5 points of excess while the rusher follows, and
   a lost check returning the rusher with a prone fall if the square is occupied.
   The charge form, Improved Bull Rush, the 25 % redirect, mounted and AI use, and
   terrain remain out of scope. Grapple, disarm and sunder remain open.
3. **Cover and concealment.** **Creature soft cover on ranged attacks is done and
   accepted (2026-11-21):** +4 AC on normal and touch AC for ranged, thrown and
   ranged touch attacks, read with the printed corner method, with the inspector's
   attacker-dependent clause. Still open: concealment (miss chance, needs terrain
   tags), hard cover from walls and low walls, reach-melee cover and
   big-creature cover (ADAPTATION_LOG 19d-19f).
4. **AoE spell templates** (e.g. *burning hands*, *sleep*) on the battle grid.
5. **Character creation and level advancement** with bounded options, including
   ability increases, skill points, feats and spell selection.
6. **Conditions** beyond the current set: stunned, blinded, prone, shaken, fear,
   disease/poison, with correct stacking and duration rules.
7. **Encumbrance and ammunition** if the campaign needs resource pressure.

Turn undead (PHB pp. 159–160) is implemented for the good cleric, including
fleeing, cowering, destruction and daily-use persistence. Extra Turning
(repeatable +4 uses/day) and Improved Turning (+1 effective level) are now
implemented through the passive feat engine. The remaining extensions —
rebuking, commanding, bolstering and dispelling turning — stay out of scope
until an evil-cleric path and the relevant action model exist.

Each addition needs a rules citation, a documented scope, an adaptation note if
needed, and focused tests. Do not let the supported list imply the whole 3.5
ruleset.

## P3 — Presentation and content production

1. **Replace placeholder art** with a consistent 2D pixel-art set: wall/floor
   atlases, NPC/creature billboards, combat tiles/tokens, portraits, icons.
2. **Replace placeholder audio** with original music, ambience and SFX; preserve
   the ids and volume behavior.
3. **Animation.** Idle/attack/hit/death frames for billboards and tokens, with
   gameplay events driving animation only.
4. **Accessibility.** Scalable UI/text, high-contrast themes, colorblind-safe
   tokens (already letter/HP coded), keyboard-only flows (**partly landed:**
   Sheet/Inventory/Journal open during dialogue via C/I/J; modal bodies scroll
   with PageUp/PageDown and the arrows, and keep scrolling while a key is held
   (implemented and automated-verified; physical held-key acceptance pending);
   a Save shortcut and full keyboard-only coverage remain open),
   screen-reader-friendly labels where feasible.
5. **Localization.** Externalize strings only after the content schema stabilizes;
   keep ids stable.
6. **Controller support** and a gamepad-friendly combat cursor.

## P4 — Campaign layer

1. Adapt a bounded original Ravenloft-inspired campaign, or license/adapt
   *Expedition to Castle Ravenloft* properly. Do not silently treat the example
   gatehouse as canon.
2. Add a campaign bible, timeline, faction state and DM tools.
3. Add long-term consequences, relationships, reputation and multiple endings.
4. Add difficulty/accessibility options that do not silently change rules;
   expose them as explicit variants.

## Engineering guardrails

- Preserve the boundaries: rules/state in `src/core` and `src/game_state.gd`,
  presentation in `src/ui`, content in `content/`.
- Every rules change needs a traceability row and a test.
- Keep seeded determinism; never use unseeded randomness in resolution.
- Keep saves versioned; never load incompatible data silently.
- Bind acceptance logs: record the exported executable's SHA-256 before and
  after every acceptance run and require the two values to match; a `BUILD.txt`
  hash alone does not bind the run.
- Keep missing optional assets non-fatal.
- Update `SUPPORTED_FEATURES.md` and the README scope whenever a mechanic moves
  from deferred to supported.

## Known technical debt

- The save migration table exists but no production step has shipped, so a
  schema change is still a refusal until the first step lands; settings are
  versioned, but a file from a newer build is read-only rather than migrated.
- Full exported-build acceptance is not repeated after every rules batch; the
  latest candidate is launch-smoke-tested outside the source tree.
- Settings persistence path/versioning is minimal.
- Combat AI is intentionally simple.
- No content hot-reload; restart after JSON edits.
- Screenshots/docs are excluded from import but not from the source tree; keep
  them out of exported assets.
- The raycaster is a stylized placeholder, not a production renderer.
- Test count is strong for rules and flow, but UI interaction coverage is shallow.
### Batch 6 closed, and a roadmap review (2026-11-23)

Batch 6 is closed. Batch 6a is accepted on **exported-candidate** evidence
(`2026-11-23_batch6a_advancement`, 110,838,888 bytes, SHA-256
`fda021540aff8adbc15123e0363dbcfa421fb0494a7e4abb68dfbabda23be7e6`, from
`9139136`): both probes and both validators ran from that executable with the hash
bound before and after. Batches 6b and 6c are accepted on **source-only** evidence -
the GUT suite and both validators from the working tree - because both are developer
tools with no player-visible change, so no candidate was exported and none is
missing. Nothing was rebuilt, re-exported or re-run for any closure, and no checks
were run for this review.

**Confirmed defects.** None open. The two batch-4 defects stay closed, and nothing
below has a failing case.

**Deferred features.** Unchanged: levels 5 and above; more than one level per step;
NPC advancement; the printed fighter feats this slice does not implement (Weapon
Specialization, Improved Bull Rush, Quick Draw, Two-Weapon Fighting); a level-up
autosave; a sheet shortcut; gating the town square behind the gatehouse; correcting
the town square award; grapple, disarm, sunder and overrun; two-weapon fighting and
iterative attacks; AoE templates; concealment and hard cover; encumbrance; the
content pipeline; a save shortcut; the campaign layer.

**Maintenance debt.** The recorded list stands, plus the completability check's one
skill allocation per combination and its dependence on the screen's candidate
helpers (`DEMO_ADVANCEMENT_PLAN.md` §15).

**Evidence gaps.** Rendered appearance, ordinary combat success and human playtesting
remain unclaimed; no probe walks the reload-then-reapply path; the advancement probe
runs at one scale and without the sorcerer.

#### The town-square award: 600 authored against a printed 1,200

- **What the repository authors.** `town_square_zombies` lists two
  `infected_zombie` monsters and `"xp": 600`. The engine pays the encounter's own
  field (`game_state.gd:1689`, `:1734-1738`), not the monsters' `xp` values - those
  feed the creator's authoring spinbox only.
- **What the printed rules support.** DMG 3.5 Table 2-6, at the party's 1st-3rd
  level row, gives CR 2 = 600 per monster, so two CR 2 infected zombies are 1,200.
  The monster's own authored `xp` is already the printed CR 2 value.
- **What the rest of the content does.** `storeroom_dead` pays 300 = 150 + 150;
  `crypt_warden` pays 450 = 300 + 150. The square is the only encounter that does
  not equal the sum of its monsters.
- **Is it a defect?** No failing case exists. Every test pins the authored number,
  nothing asserts a sum rule, and the plan already lists the correction as deferred
  (§15). It is a recorded content inconsistency, not a confirmed defect.
- **What changing it would do.** The demo's encounter ledger would go 1,500 -> 2,100,
  the authored inventory 4,500 -> 5,100 and the ordinary inventory 4,350 -> 4,950;
  the post-climax totals would rise by 600 (completion route 6,600 -> 7,200, named
  route 6,550 -> 7,150), and `test_demo_advancement.gd`'s pins plus the diagnostics
  inventory line would move. It would **not** move eligibility or level-up timing:
  the milestone is fixed at 2,300 and sized from the 700 completion floor, which
  excludes the square; and a party that fights the square first stands at 4,200,
  still below 6,000, so the step still arrives at the bell.
- **Decision.** Keep 600 for now and record the inconsistency. The fight is a
  bounded excerpt (two of the source's nine zombies), XP has no sink past 4th level,
  so the change buys ledger fidelity rather than play. It stays an independent
  one-value batch with its pins if a content-accuracy pass is ever wanted, and it
  must not be used to resize the milestone.

#### What actually has player impact, ranked

1. **Weapon Specialization.** The level-up feature is now reachable and accepted,
   and Kaelen already holds Weapon Focus (longsword), so his 4th-level bonus feat can
   be Weapon Specialization and his damage changes in the town square - the one
   fight left after levelling. This is the first rules addition the accepted
   advancement actually unlocks, and the catalog's own "deferred: fighter bonus-feat
   / level subsystem" blocker is gone.
2. **Grapple, disarm and sunder.** Reachable at every level and the strongest
   tactical alternative, but each is larger than one batch and needs a plan first;
   none is unlocked by anything that just landed.
3. **The reload-then-reapply path.** An evidence gap, not a defect: the victory
   autosave already holds the paid XP, and the post-apply reload is covered. Cheap
   as a rider on a save batch, weak as a batch of its own.
4. **A level-up autosave or a sheet shortcut.** Convenience only; the entitlement is
   already safe, and the screen deliberately writes nothing.
5. **Levels 5 and above.** Still unreachable: 10,000 XP against 4,850 on one
   ordinary route, and no 3rd-level spell exists in content for the casters.
6. **The town-square award.** No mechanical effect at all for the 600 XP difference.

#### Recommended batch 7: Weapon Specialization as the fighter's 4th-level feat

**Player impact.** A fighter who levels takes a feat whose printed effect is real
damage, not another +1 on a sheet: +2 with the selected weapon, applied by
`Rules.damage_bonus` (`rules.gd:451`, which already sums `Feats.modifier(ch,
"damage", {weapon: ...})`). With Kaelen that is his longsword in the town square
fight, so the accepted advancement ends in a character who hits harder.

**Dependencies.** `Feats.CATALOG` (a `fighter_bonus` entry with `parameter:
"weapon"` and the printed prerequisites), one new prerequisite type for class level
(`ch.level` is character level, and only `cleric_level()` exists as a class helper
today), `Rules.damage_bonus` and `Feats.modifier` (both already support
weapon-parameterised damage), `LevelChoices._feat_rows` (it picks up
`fighter_bonus` entries automatically), and Kaelen's authored Weapon Focus.

**Scope.** One catalog entry; a `class_level` prerequisite check with player-facing
refusal text; the coverage table row; tests - the entry's parameters and
prerequisites (a 4th-level fighter with Weapon Focus accepted, a 3rd-level fighter
refused, a weapon without Weapon Focus refused, a multiclass fighter/rogue refused),
damage with the selected weapon only, the level-up screen offering it to Kaelen at
4th, and the probe choosing it and reading the damage change; records.

**Acceptance criteria.** Red-first, with the logged failures captured; focused tests
then the full suite and both validators green; `--level-up-probe` (both scales) and
`--advancement-probe` green from source; an exported candidate whose probes bind its
hash before and after, because damage numbers are player-visible; records updated with
the four lists kept apart; no other feat, no level 5, no threshold or award change, no
UI, schema or save change.

**Exclusions.** Quick Draw (needs weapon-drawing action economy), Two-Weapon Fighting
and iterative attacks (need the full-attack chain), Improved Bull Rush (unreachable
before 6th - it needs Power Attack plus a slot), Greater Weapon Specialization and
Greater Weapon Focus (levels 8 and 12), the town-square award, the reload-then-reapply
probe, and any XP or milestone change.

**Exported candidate.** Yes - the feat changes combat numbers a player sees, so the
batch follows the 6a precedent of binding a candidate's hash to its probe runs.

**Why not planning only.** Weapon Focus is the exact template for the entry, its
damage path already exists, and the printed prerequisites are unambiguous; the only
new mechanism is one prerequisite type. No open design question is being answered by
writing code here.
