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
  rules work is blocked on content rather than code: no shipped monster has an
  equipped weapon item, so disarm and sunder have no legal target; overrun needs
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
**Status (2026-11-23).** Implemented at `87da7ea` and accepted on candidate
`2026-11-23_batch7_weapon_specialization` (110,853,000 bytes, SHA-256
`a53836eaf3a1cb2018c23e3f488ec025f76440272f68fba1bcc1e04f40aed311`). The
`class_level` evaluation and the same-weapon prerequisite are recorded in
`ADAPTATION_LOG.md` 62; the red/green receipts and the probe's input split are in
`TEST_REPORT.md`.
### Batch 7b closed, and a rules-work review (2026-11-23)

Batch 7b is closed as accepted within the evidence recorded in `cf6c5c2`
(implementation `334da1d`, candidate `2026-11-23_batch7b_feat_display`). Nothing was
rebuilt, re-exported or re-run for the closure, and **no checks were run for this
review**.

**Confirmed defects.** None open. The two batch-4 defects stay closed, and nothing
below has a failing case.

**Deferred features.** Unchanged: levels 5 and above; more than one level per step;
NPC advancement; Greater Weapon Focus and Greater Weapon Specialization; Improved
Bull Rush; Quick Draw; Two-Weapon Fighting and iterative attacks; a level-up autosave;
a sheet shortcut; gating the town square behind the gatehouse; correcting the
town-square award; grapple, disarm, sunder and overrun; concealment and hard cover; AoE
templates; encumbrance; disease; the content pipeline; a save shortcut; the campaign
layer; skill parameters still showing content ids in feat text.

**Maintenance debt.** The `Encounter` header comment (`src/core/encounter.gd:13-14`)
still lists bull rush, trip, cover and turn undead as deferred although all four are
implemented; a comment is not a defect, but it misleads a reader and should be fixed by
the next batch that edits that file. The feat-label string exists twice
(`Feats.display_label` and the precomputed row `label`). The advancement probe and the
level-up probe choose different fighter feats past the Feat step.

**Evidence gaps.** Rendered appearance, ordinary-combat victory and human playtesting
remain unclaimed; the reload-then-reapply path is walked by no test; the advancement
probe runs at one scale and without the sorcerer.

#### What the engine models, against what shipped content can use

| Area | Engine today | Authored content that would use it | Reachable by a player? |
| --- | --- | --- | --- |
| Grapple | Nothing: no grapple or pinned state, no opposed grapple check, no restricted-action path, no UI action | None. The four monsters (`zombie`, `infected_zombie`, `ghoul`, `store_looter`) carry no weapon item and none has a grab ability; the looter swings an authored longsword attack | A player could initiate it against any monster if it existed, but no content initiates, rewards or teaches it, and no monster would grapple back |
| Disarm | Nothing | None. No monster has an equipped weapon and no attack is an item: the undead use natural attacks, and the looter's longsword is an authored `attacks` entry whose `equipment` holds only a chain shirt. So there is no weapon to disarm; no authored enemy ever disarms the party | No - only a test could reach it |
| Sunder | Nothing | Nothing. No combatant carries a struck object and there is no object hit-point model | No |
| Concealment | Nothing: no miss chance anywhere in the engine | None. No area, spell or monster authors darkness or concealment | No |
| Hard cover | Soft cover only: `creature_cover` gives +4 when another creature is in the line (`encounter.gd:2503`, `BattleMap.creature_cover`), and `Rules.attack` accepts the `cover` term (`rules.gd:711`) | The three combat maps are open rooms; the town square's barricade is an exploration object, not a combat obstacle | Soft cover yes (and probed); hard or terrain cover no |
| AoE templates | One shape only: `bless` applies to every party ally (`_cast_bless`); the engine has no radius, template or multi-target resolution | Bless's printed "all allies in a 50-ft. burst"; no damaging area spell is authored - magic missile, scorching ray, cure light wounds, aid and mage armor are all single-target | Bless yes; templates no |
| Conditions | Implemented: dead, dying, stable, unconscious, nonlethal unconscious, disabled, staggered, prone, paralyzed, cowering, turned, plus the bless / mage armor / aid buffs, fighting defensively, total defence, Combat Expertise, flat-footed, flanking and helpless | Ghoul paralysis is authored and exercised in the crypt fight; the ghoul's own notes record that ghoul fever is not implemented, and the infected zombie's disease is deferred with it | Everything listed yes; disease no |
| Encumbrance | Nothing: items carry `weight_lb`, and no rule reads it; `ADAPTATION_LOG.md` 18 records the decision | None: no content gates on weight and the party's kit is light | No consequence either way |
| Items in play | Equipment and inventory work; `give_item` awards the clapper, keys, potions and the ferry token | The party carries longsword, short sword, heavy mace, daggers and a light crossbow. `light_flail` exists in `content/shared/items.json` and is granted by nothing, so no player can encounter it | The party's own weapons yes; `light_flail` no |

Read together, the only listed rules area with a real target in shipped content is
grapple, and even there the content never initiates one. Disarm, sunder, concealment,
hard cover, AoE templates and encumbrance would be features only a test could reach
until content creates a reason for them. Conditions are already broad; the one
content-authored gap is disease, which has no day-scale pressure in these campaigns.

#### The reload-then-reapply gap

- **What the save path guarantees.** Victory pays every character the encounter's XP
  and only then writes `save_game("auto")` (`game_state.gd:1734-1756`), so that
  autosave holds level 3 with the paid XP and eligibility. `LevelUp.apply` mutates the
  character and the screen writes nothing, so an applied level reaches disk at the next
  manual save or auto boundary. Loading the pre-apply autosave therefore restores the
  entitlement with an empty draft, and the same choices are legal again.
- **What tests cover.** Eligibility from a loaded level-3 save and the level-4
  round-trip (`test_level_up_core.gd` cases 33 and 34), and the probes' post-apply
  save/reload. Nothing loads the *pre-apply* autosave and applies again.
- **Can a focused test close it?** Yes, with no new save policy: a game-level test can
  reach the threshold through a QA victory, let the autosave write, reload `auto`,
  apply the same draft, reload again and apply once more. Every API it needs exists.
- **Does it deserve its own batch?** No. It verifies an existing recovery path and
  changes no player-visible behaviour; it belongs as a case inside the next batch that
  touches saving, or as a rider on a test-only change.

#### Recommendation: planning only for the special-attack family, grapple first

**Why planning rather than a bounded implementation.** Grapple is the only listed
rules area that can be reached in shipped content - a player can attempt it against
every monster in all three campaigns - but it is bigger than either special attack
already built: trip and bull rush each landed from a dedicated plan (`BULL_RUSH_PLAN.md`
is 268 lines for bull rush alone), and grapple adds a persistent two-character state,
movement into the defender's square, action restrictions on both participants, an
escape check, and a turn-loop that must not let a grappled actor act normally. It is
also the only one of the three that would work against content as authored, since no
monster carries a weapon.

**Planning deliverable.** One note that decides, with printed citations: the
player-initiated single-defender grapple (touch attack, opposed check and size
modifiers), the `grappled` state and exactly which actions it forbids, the escape
check and who may attempt it, whether a pin is in the first batch, which feats count
(Improved Grapple is cataloged and would become reachable), how the AI responds when
it is the defender, the UI action and its keyboard path, the probe plan, and what stays
out. It should also record that no monster initiates a grapple and why that is
acceptable for this slice, and correct the stale `encounter.gd` header.

**The first implementation batch it would produce.** Grapple and escape only, no pin
and no pin damage: a player-initiated grapple against one defender in the existing
combat screen, the `grappled` action restrictions, a defender escape attempt on its
turn, and Improved Grapple's +4. Everything else - pin, constriction, multiple
grapplers, monster-initiated grapple, improved grab, swallow whole - stays deferred and
is named in the plan.

**Player impact.** A new tactical option in every fight, and the first use for a feat
the catalog already carries; modest rather than large, because the authored monsters
never grapple and the campaign's fights are short. Exported candidate: required for the
implementation batch (combat behaviour a player sees), not for the planning note.
Exclusions for that batch: no disarm, no sunder, no concealment, no AoE templates, no
encumbrance, no disease, no content, schema or save change, no threshold or award
change.

**Not recommended now.** Disarm and sunder (no authored target), concealment, hard
cover, AoE templates and encumbrance (no authored content), disease (no day-scale
pressure), and a reload-then-reapply batch of its own (a test case, not a feature).

## Grapple follow-up review (2026-11-24)

Batch 8a is closed as accepted within `514ebc9`, including the exported 98-check
`--grapple-probe`. Candidate `2026-11-24_batch8a_acceptance_b`: source `a71b942`,
110,874,840 bytes, SHA-256
`6d7e0df7e071115c190a6ede40d965e6a28893fe92ce73f72e885f5438debd92`; its disclosed
working-tree difference is the uncommitted README quick-start removal (file
`d7cd5f89…`, diff `0e8ff3e1…`). No checks were run for this review or the closure.

Read for this review: `GRAPPLE_PLAN.md` (especially §4 and §10), `encounter.gd`'s
grapple state and refusals, `Feats.CATALOG` and `LevelUp`/`ClassProgression`, the combat
screen's action grid and potion path, and `content/shared/characters.json` /
`monsters.json`.

### Pin (8b)

- **Printed requirements** (plan §10): opposed check in place of an attack, immobile for
  1 round, -4 AC against everyone but the pinner, escape from the pin leaving the
  creature still grappling, breaking another creature's pin, free release of a pin.
- **Current code**: `grapples` records only `{holder, held}`; there is no pin state, no
  pin action, and `Escape` covers release and escape from the hold only. The restrictions
  that would carry over are movement, step, stand, pick up, sheathe, load, third-party and
  ranged attacks, casting and turning; Dexterity denial already exists through
  `denies_dex_to`.
- **Player impact in shipped content**: one more round of control over a monster that is
  already unable to act except to escape, with no damage (all three shipped monsters are
  undead and ignore the nonlethal hold damage). Tactical, but small, and no shipped
  encounter is built around it.
- **Rules decisions needed**: action cost ("in place of an attack" cannot apply because
  iteratives are not modelled, so a standard action must be chosen and recorded); whether
  the pin lives on the existing pair or in a second array; what a pinned creature may
  still do (the printed list is escape only, which interacts with the current cast,
  potion and item paths); whether -4 AC and the existing Dexterity denial stack as
  separate statements; how "escape from a pin leaves the grapple" is expressed without a
  third state; who may break a pin and how the target is chosen; what the AI does after
  escaping a pin but not the grapple; and how one stable `Escape` label explains two
  different outcomes.
- **Dependencies**: 8a only. **Boundary**: engine state and refusals, a `Pin` control and
  the `Escape` semantics, AI branch, a focused test file, extension of
  `--grapple-probe`, layout count 31 -> 32, export. **Acceptance**: the pin check, the
  immobility, the AC and Dex statements, pin escape leaving the grapple, breaking a pin,
  free release, AI behaviour, layout at both scales, and an exported probe.

### Improved Unarmed Strike -> Improved Grapple (8e)

- **Current code**: neither feat is in `Feats.CATALOG`. Only raw feat text works:
  `_grapple_bonus` and the reaction gate call `Feats.has_feat("improved_grapple")`, and
  `test_grapple.gd` / `--grapple-probe` seed that text. That is a hook, not reachability.
- **Legality inside the supported range**: `LevelUp` supports exactly 3rd -> 4th level.
  At 4th only the fighter gains a feat (`feat_levels` general [1,3], class [1,2,4]);
  rogue, cleric, wizard and sorcerer gain none. Improved Unarmed Strike has no
  prerequisites; Improved Grapple needs Dex 13 and Improved Unarmed Strike, i.e. two
  feats. Kaelen (Dex 13) could take Improved Unarmed Strike at 4th and would need a
  further feat at 6th, which the level-up step does not support. No shipped character can
  therefore legally own Improved Grapple in the supported range.
- **Player impact**: zero until a level-range batch exists; adding the catalog entries
  alone would only add a selectable feat whose second half stays out of reach.
- **Decision needed**: whether to extend level-up first (a separate feature, not 8e).
  **Recommendation**: keep 8e deferred and record the reason rather than schedule it.

### Deferred grapple attack and casting options (8c/8d)

- **Casting and turning**: `cast_active_spell` and `turn_undead` refuse while grappling by
  stated scope. That blocks every shipped caster's class feature in a hold: Aldric
  (cleric), Ysolde (wizard), Mira (sorcerer) all have spells, and Aldric loses turning.
  The printed path needs a component model and a Concentration DC 20 + spell level, so
  this is a design decision, not a small patch.
- **Monster natural weapon**: `attack_active` already permits a monster to attack its
  partner with a natural weapon at -4, but `_run_monster_turn` returns after the escape
  attempt, so a held ghoul never takes that attack and its paralysis cannot trigger from a
  hold. Making it reachable is an AI decision (attack versus escape), with the paralysis
  save exposed as a consequence.
- **Potions**: `use_potion_active` spends the standard action and provokes but does not
  refuse a grappled actor, and PHB p.156 lists activating a magic item in a grapple, so
  the implementation is consistent with the printed list. Plan §4 previously claimed
  potions were refused; that statement is corrected in this commit.
- **Remaining 8c actions**: damage by opposed check (currently only the automatic hold
  damage exists), use the opponent's weapon, move the grapple at half speed, draw a light
  weapon, retrieve a spell component, and magic-item activation beyond potions.

### Classification

- **Confirmed defects**: none in executable grapple behaviour. One documentation defect:
  plan §4 said potions were refused while `use_potion_active` permits them; corrected
  here, no code change. The `Combat Casting` benefit text still says grappling is not
  modelled, which is stale and is recorded as maintenance debt, not a defect (the bonus
  stays unreachable because casting from a grapple is refused).
- **Deferred features**: pin (8b), the remaining actions (8c), casting/monster natural
  weapon (8d), the feat chain (8e), multiple grapplers/improved grab (8f).
- **Maintenance debt**: the stale `Combat Casting` benefit string; the plan/implementation
  wording drift corrected above.
- **Evidence gaps**: exported grapple behaviour exists only through the 98-check probe at
  1280x720 headless; no living shipped opponent; feat text seeded by tests and the probe
  is not player reachability; nothing here is ordinary play or human testing.

### Recommendation

**Planning only for 8b (pin).** It is the next printed step and needs 8a alone, but it
carries at least six decisions above - action cost without iteratives, state shape, the
pinned action set, AC/Dex composition, break-pin targeting and the AI's post-escape turn -
and those decide its tests and UI. A planning note should settle them before any
implementation. Do not start 8e (no legal reach inside 3rd -> 4th level) and do not fold
8c/8d in: casting needs a component/Concentration model and 8d needs an AI policy.

**Batch 8b-1 (pin) implemented 2026-11-24.** The recommendation above was followed:
pin shipped alone on the existing two-participant pair, with `tests/test_pin.gd` (30
tests), the extended `--grapple-probe` (147 checks), layout 32 controls and candidate
`2026-11-24_batch8b1_acceptance_c` (source `f149d1d`, 110,885,688 bytes, SHA-256
`8f9de152fa89b1c273eaf85208826c3645216170e759a925b1cf1a3b781aa2e0`). Break-pin (8b-2)
and 8c-8f remain deferred; `PIN_PLAN.md` section 10 and `TEST_REPORT.md` carry the
record.

## Next bounded task - roadmap review after batch 8b-1 (2026-11-24)

Review only. Nothing was implemented, rebuilt, re-exported or re-checked for this
section, and no checks or manual testing were requested. It reads the current
`ROADMAP.md`, `PROGRAM_PROGRESS.md`, `TEST_REPORT.md`, `SUPPORTED_FEATURES.md`,
`TRACEABILITY.md`, `FEATS_SKILLS_COVERAGE.md`, `PIN_PLAN.md`, `GRAPPLE_PLAN.md`,
`DEMO_ADVANCEMENT_PLAN.md`, the authored campaign and encounter files, and the
combat UI/input code.

### Turn Undead investigation closed

Closed as **no product defect found**, on the evidence recorded in `a24243b` for
`5d0f54a` and candidate `2026-11-24_turn_undead_wrapper_b`. The wrapper's
`auto_advance()` returns at the acting able party member, so neither refusals nor
legal attempts move initiative; the seeded pinned-monster wrapper call stays a
disclosed non-player bypass. This is resolved, not open maintenance debt.

### What shipped play can actually reach

- Three campaigns ship authored encounters; every monster in shared content is
  undead and fights with natural weapons. No monster has anything to disarm,
  sunder, steal or use against the party, and the AI never initiates a grapple.
- Grapple and pin are ordinary player actions in every fight and need no feat;
  Improved Grapple is **not** legally acquirable in the supported 3rd -> 4th step,
  because the fighter's one new feat cannot cover Improved Unarmed Strike and
  Improved Grapple together. The feat's +4 and reaction skip remain seeded text.
- The demo now reaches 4th level in play through the bell completion milestone:
  the completing route lands on 6,000 and the named combat route on 6,550, so the
  level-up is no longer fixture-only. Levels 5 and above remain out.
- Combat maps are open rooms and short corridors. Trip, bull rush, grapple,
  pin, cover from a creature, paralysis, turning and the level-up screen are
  reachable; disarm, sunder, concealment, hard cover from terrain, AoE templates,
  encumbrance and disease still have no authored target or pressure.

### Candidate 1 - keyboard targeting on the battle grid (recommended)

**Implemented 2026-11-24 in `072c15b`.** The batch delivered the cursor and activation
path described here: a visible, map-bounded cursor, Enter/Space through
`_on_cell_clicked`, Escape cancelling without an action cost and returning focus,
the grid ignored off-turn, with a modal, with a pending decision and after the fight,
and mouse targeting unchanged. It added no hotkey, save shortcut, new binding or
focus framework. Evidence and the exact keyboard boundary are in `TEST_REPORT.md`.
Remaining keyboard gaps are recorded there and below: choosing a mode still needs its
button, the combat log has no keyboard scroll path, and no human or rendered-cursor
review exists. Further grapple (8c, 8b-2/8f), overrun, the save shortcut and
readied/delayed actions stay deferred.

- **Player benefit.** A keyboard-only player cannot finish a fight today. The
  action buttons are ordinary focusable buttons, but every mode they open ends in
  a click on a grid cell: `CombatView._gui_input` handles only mouse motion and
  the left button (`src/ui/combat_view.gd:54-65`), and `CombatScreen` has no
  `_unhandled_input` at all (exploration does, `exploration_screen.gd:311`). This
  blocks movement, stepping, attacking, spell and item targeting and every other
  grid action for keyboard users, and it is the largest remaining item in P3's
  accessibility line ("full keyboard-only coverage remains open").
- **Reachability.** Every combat in all three campaigns; no content, feat or
  fixture is needed. It also helps players who prefer the keyboard, not only
  players who cannot use a mouse.
- **Design decisions to settle in the batch.** Arrow keys move a visible cursor
  (starting on the active creature); Enter or Space activates the same path as
  `cell_clicked`; Escape leaves the current mode; the cursor is ignored while a
  modal is open or it is not the player's turn; the mouse remains unchanged; no
  new key bindings beyond the existing `ui_*` actions; no rule, range or target
  validation moves out of the encounter.
- **Implementation boundary.** One cursor field and highlight in `CombatView`,
  one input handler in `CombatScreen` that routes to the existing
  `_on_cell_clicked`/mode exit, and no change to the action grid's 32 controls or
  to any resolution code.
- **Acceptance cost.** Focused tests for cursor movement, activation and cancel
  through the same path as a click, plus a real-key probe step in the combat
  fixture; the suite, both validators, all three probes, both layout scales and
  an exported candidate, because it is player-visible. No content, schema, save,
  award, threshold or XP change.

### Candidate 2 - further grapple (8c, then 8b-2/8f)

- **Player benefit.** 8c would add grapple damage by opposed check and moving a
  grapple at half speed. The player can already initiate a grapple and pin in
  every fight, the entry already deals hold damage, and a grappled attacker can
  already strike the partner at -4; the marginal choice is modest.
- **Reachability.** Grapple and pin are ordinary play. Pin damage is not a
  separate batch; break-another's-pin and multiple grapplers are not reachable at
  all while the AI never grapples, so they would be probe-only.
- **Design decisions.** Whether damage is a standard action, its base (unarmed or
  light weapon), lethal/nonlethal handling, size, whether it is legal while
  pinning, and how moving the pair interacts with reach, opportunity attacks and
  the existing pair-clearing paths.
- **Implementation boundary and cost.** Encounter plus at most one more control,
  focused tests and probe checks, a candidate. Comparable to 8a/8b-1, but it
  extends a just-finished batch rather than opening a new player capability.
- **Verdict.** Not the next task. Extending grapple is reasonable later if play
  shows the current options are used; numbering alone is not a reason to continue.

### Candidate 3 - overrun

- **Player benefit.** A standard-action way to move through an opponent and knock
  it prone, useful in a corridor or when the party is body-blocked.
- **Reachability.** Any monster is a legal target, so ordinary play can reach it.
  The maps are largely open, and trip already produces prone and bull rush already
  moves a defender, so the benefit overlaps both.
- **Design decisions and cost.** Opposed check, size and stability, movement and
  opportunity attacks, failure placement, prone timing, and whether the AI ever
  uses it. Bull rush needed its own 268-line plan; overrun needs at least a short
  plan, then an engine/UI batch and a candidate.

### Candidate 4 - save shortcut

- **Player benefit.** One key opens the existing Save modal instead of Escape ->
  Save game.
- **Reachability.** Exploration only; saving is deliberately disabled in combat,
  and the pause menu already exposes Save. The benefit is convenience, not a new
  capability.
- **Boundary and cost.** One input action and one handler, plus a focus/modal test
  and a probe key step; no save-policy change. Small enough to ride with a larger
  input/accessibility batch rather than lead one.

### Candidate 5 - readied/delayed actions

- **Player benefit.** High tactical value: hold an attack for a trigger, or act
  later in the round.
- **Reachability.** Every fight. **But** it needs a trigger model, interrupt
  ordering, pending-decision integration, AI use and UI; it is not a bounded
  change and should get a planning note before any batch.

### Recommendation

**Implement keyboard targeting for the battle grid.** It is the only reviewed
candidate that opens a capability ordinary play currently lacks, affects every
combat without new content, and fits one bounded UI/input batch. Scope it to the
cursor and activation path described above; do not add toolbar hotkeys, rebinding
changes, rules changes or content in the same batch. Further grapple, overrun,
the save shortcut and readied/delayed actions stay deferred; the reload-then-reapply
save case and the seeded probe limits stay evidence work, not features.

### Classification, kept separate

- **Confirmed defects.** None open. The Turn Undead wrapper claim is closed as no
  product defect found; no other failing case was found in this review.
- **Deferred features.** Grapple 8b-2/8c/8d/8e/8f; overrun, disarm, sunder,
  concealment, terrain hard cover, AoE templates, encumbrance, disease; readied
  and delayed actions; full attacks and two-weapon fighting; levels 5 and above;
  a save shortcut. Keyboard combat and combat information access are closed
  (2026-11-24); see the closure below.
- **Maintenance debt.** The stale `Combat Casting` benefit text; the singular
  modal field; probe-heavy `main.gd`; source-text guards that cannot see a
  string-built call; shallow UI suite coverage; the placeholder renderer. None
  is promoted to a defect here.
- **Evidence gaps.** Grapple, pin and AI-escape behaviour is exercised through
  seeded probes, not ordinary recorded play; keyboard combat has automated input
  evidence but no rendered-cursor or human review; no rendered appearance or
  human playtesting is claimed. The
  reload-then-reapply save case remains a test to fold into future save work.

## Next bounded task - roadmap review after keyboard targeting (2026-11-24)

Review only. Nothing was implemented, rebuilt, re-exported or re-checked for this
section, and **no checks were run**. It reads the current `ROADMAP.md`,
`PROGRAM_PROGRESS.md`, `SUPPORTED_FEATURES.md`, `TEST_REPORT.md`, `TRACEABILITY.md`,
`FEATS_SKILLS_COVERAGE.md`, `GRAPPLE_PLAN.md`, `PIN_PLAN.md`, the authored encounters
and monsters, and the combat/input code.

### Keyboard battle-grid targeting closed

Closed within the evidence recorded in `b2db538` for implementation `072c15b` and
candidate `2026-11-24_combat_keyboard_a` (110,887,928 bytes, SHA-256
`a4f485b6416a8985e043757f7746167e93e6a04eb6ccdbdcf117438630d5f1ad`): 12/12 focused
tests (52 asserts), suite 985/985 (9,864 asserts, 74 scripts), both validators,
`--grapple-probe` 154 checks, `--keyboard-probe` 31 checks, `--level-up-probe` 349
checks, `--advancement-probe` PASS, layout 32 controls/0 failures at 100 % and 160 %,
and the same checks from the exported candidate with its hash unchanged. No rebuild,
re-export or check was run for this closure.

The acceptance remains automated input behaviour and geometry. It is not evidence of
complete keyboard-only play, the rendered cursor, human accessibility or the other
screens, and this review does not broaden it. Turn Undead stays closed as **no product
defect found**; the earlier grapple and pin acceptances are unchanged.

### What the keyboard boundary is now (code reading, not a new test)

- **Action buttons.** Ordinary focusable `Button`s. A disabled action is skipped by
  Godot's focus traversal (the repository's campaign-list test pins that rule), and
  `End turn`/`Inspect` are enabled on a live player turn and sit in the action grid,
  so Tab reaches them. No missing activation path was found.
- **Combat dialogs.** Cast spell, Use potion, First aid, Inspect and Pause all use the
  shared modal: its body is a `ScrollContainer` with `follow_focus = true`, Close takes
  focus, and `_cycle_modal_focus` traps Tab while `_reveal_focused_control` scrolls the
  focused control into view. Existing modal-focus tests already exercise that path; it
  was not re-run here.
- **Pending decisions.** Trip counter-trip, Improved Trip's follow-up, Cleave and Bull
  rush choices are plain `Button`s in `decision_box`, focusable but never focused
  automatically. When the grid releases the ring after a keyboard trip no action button
  is enabled, so the ring is unset. Godot's viewport then starts Tab from the first
  visible top-level Control and focuses the first focusable descendant
  (`Viewport::_gui_input_event`), so Tab recovers to the HUD; it does not dead-end. The
  buttons live in the scrolling sidebar, which sets no `follow_focus`, and
  `Main._reveal_focused_control` reveals only inside a modal or the campaign creator. A
  focused decision or target row can therefore stay off-screen; it can still be
  activated. This is a visibility gap, not a blocked turn.
- **Combat log.** `log_label` is a `RichTextLabel` with `scroll_following = true` and the
  default `focus_mode` (NONE); it has no key handler. The newest lines are visible, but
  earlier rolls are mouse-wheel only. This is a real keyboard capability gap for
  information, not a blocked action.
- **Target rows.** The per-enemy Inspect/Attack rows sit in the same scrolling sidebar
  without a reveal; attacking is duplicated by the grid cursor and Inspect by the action
  button, so neither is a unique path.

### Candidate A - bounded keyboard-combat information access

- **Player benefit.** A keyboard-only player could review earlier rolls and see which
  pending-decision or target control currently has the ring.
- **Evidence and reachability.** Every combat; the two gaps above are set by the code,
  not inferred from a missing test. `RichTextLabel` already scrolls, and `ScrollContainer`
  already has a reveal routine used for modals and the creator.
- **Unresolved decisions.** Whether the log takes a Tab stop or scrolls from screen-level
  Page keys; what happens to `scroll_following` when the player scrolls up; which keys
  (Page/arrow); how focus is drawn; whether the sidebar follows focus or only reveals
  decisions/targets.
- **Dependencies and boundary.** `CombatScreen` and one small reveal hook; no rule,
  content, save or focus-framework change. Focused tests plus a real-key probe step, the
  suite, both validators, all probes, both layout scales and a candidate.
- **Verdict.** Bounded and honest, but it closes information/visibility, not a blocked
  path. It stays a deferred usability item rather than leading a batch.

### Candidate B - overrun (deferred after scope review)

- **Player benefit.** A standard-action way to move through an occupied square and knock
  the blocker prone, using a capability no current action has: trip makes prone at reach
  and bull rush pushes, but neither lets the mover pass.
- **Reachability.** Any monster is a legal target, so every shipped fight can use it. The
  demo maps have real chokepoints (`storeroom_dead` and `crypt_warden` carry pillar rows
  with three-square gaps), which is where passing a blocker matters. Ordinary play is
  less demanding than that suggests: every shared monster is a melee undead with natural
  weapons, encounters are kill-all, and the AI never initiates special attacks, so there
  is no back line to reach.
- **What is already in place.** `Character.size_category`, occupancy-aware movement, the
  AoO machinery, the contested-check and pending-decision patterns from trip and bull
  rush, and the action-grid control shape.
- **Decisions.** The plan settles declaration, the standard-on-block timing, one attempt
  per round and defender states, but the printed continuation, raw tie rule and
  participant geometry remain open. Improved Overrun stays deferred behind the action
  (`FEATS_SKILLS_COVERAGE.md`).
- **Dependencies and cost.** The planning note is complete. A future implementation would
  first need a movement-continuation decision, a shared tie decision and a participant-
  geometry decision, then an `Encounter` batch with its own tests, probe and candidate.
  Bull rush needed its own 268-line plan; this is comparable, not smaller.
- **Verdict.** The 2026-11-24 scope review does not support a bounded player-facing
  implementation. The printed success/avoid continuation is not implemented, the
  fixed exit is not accepted as equivalent, the tie rule needs a shared-helper
  decision, and the origin-only opportunity geometry is unproven. The shipped
  content also has no back line, the prone blocker still occupies the lane, and the
  undead are immune to sneak attack. **Defer overrun; no implementation batch.**
- **Plan status.** `docs/OVERRUN_PLAN.md` records the printed rules, the project
  adaptations, the exact engine/UI seams, the historical test matrix and §18's
  explicit Option A/B/C scope decision. §18 supersedes the earlier two-batch
  recommendation; no overrun code, tests, probe or candidate exists or is authorized.

### Candidate C - readied and delayed actions

- **Player benefit.** The highest tactical ceiling in the remaining roadmap: hold an
  attack for a trigger, or act later in the round.
- **Reachability.** Every fight.
- **Decisions and cost.** Trigger list and selection UI, interrupt ordering against the
  existing `pending_*` decisions, reaction timing, action economy, duration, AI policy and
  log wording. This is a subsystem, not one action; it needs its own plan first and is a
  larger commitment than overrun.

### Candidate D - further grapple (8c, 8b-2/8f)

- **Benefit.** Grapple damage and half-speed movement of the pair.
- **Why not now.** Every shared monster is undead and ignores the nonlethal damage the
  existing hold already deals; the AI never grapples, so break-another's-pin and multiple
  grapplers have no player-reachable target. Pin shipped in 8b-1. Numbering alone is not
  a reason to continue.

### Candidate E - save shortcut

- **Benefit.** One key opens the existing Save modal instead of Escape -> Save game.
- **Why not now.** Saving is exploration-only by design and the pause menu already exposes
  it; the gain is convenience. Small enough to ride with a later UI batch, not to lead one.

### Recommendation

**Keep overrun deferred; implement nothing and select the next roadmap item outside
overrun.** The planning note is complete, but it did not produce a bounded
player-facing acceptance unit: the printed continuation needs movement work, the tie
contract is shared with trip/bull rush/grapple, and the opportunity geometry is not
settled. The shipped fights also lack the back-line/repositioning payoff that would
justify that cost. Readied/delayed actions carry more tactical value but are a larger
subsystem with their own planning need; further grapple is not prioritised without
content that rewards it, and the save shortcut stays a ride-along.

### Classification, kept separate

- **Confirmed defects.** None open. The Turn Undead wrapper claim stays closed as no
  product defect found; this review found no failing case.
- **Deferred features.** Overrun (deferred after the 2026-11-24 scope review;
  `docs/OVERRUN_PLAN.md` §18; no implementation authorized); readied/delayed actions;
  further grapple
  (8b-2/8c/8f); disarm, sunder, concealment, terrain hard cover, AoE, encumbrance,
  disease; levels 5+; a save shortcut; reachable opposition (see the review below).
- **Maintenance debt.** Unchanged: the stale `Combat Casting` benefit text, the singular
  modal field, the probe-heavy `main.gd`, shallow UI suite coverage and the placeholder
  renderer.
- **Evidence gaps.** No human keyboard-only playthrough, rendered cursor or accessibility
  check; Tab traversal and decision focus recovery were read from the engine and code,
  not key-tested; exported acceptance covers probes, not the suite; overrun has no
  implementation, tests or content pressure yet, and its continuation, tie and
  opportunity-geometry questions remain open by the §18 deferral.

## Opposed-check tie audit and next feature (2026-11-24)

Inspection only; **no tests, probes, validators, builds or exports were run**.
`docs/OPPOSED_CHECK_TIE_AUDIT.md` enumerates all seven production callers of
`Rules.opposed_ability_check`, their modifiers and tie behaviour.

**Finding.** No current player-reachable maneuver is demonstrably wrong.
Grapple, pin and escape match the explicit printed rule: the higher grapple check
modifier wins, then reroll. Trip and bull rush coincide with the project's
ability-check reading in shipped content because every character and monster is
Medium, no actor has a stability bonus, and Kaelen cannot reach Improved Trip at
the current level cap. The helper's use of size/stability/Improved Trip as tie
breakers is a **latent contract mismatch**, not a confirmed defect. The ability-
check interpretation itself is a project reading of PHB p. 64, not an explicit
printed trip/bull-rush sentence. The earlier maneuver acceptances are not
invalidated.

**Future constraint.** If reachable non-ability bonuses are added, separate the
total modifier from the tie modifier in the helper API; the default must preserve
grapple/pin/escape. Overrun remains deferred under `docs/OVERRUN_PLAN.md` §18.

**Selected next feature: Candidate A, keyboard-combat information access.** It is
the strongest genuinely bounded roadmap item outside overrun: the combat log has
no keyboard scrolling path, and focused pending-decision/target controls can stay
outside the sidebar viewport. It changes no rule, content, save or schema. Its
key/focus choices should be settled first; this audit authorizes no
implementation. Readied/delayed actions have a higher tactical ceiling but are a
subsystem; further grapple still lacks a content payoff; the save shortcut is a
ride-along.

**Batches decided 2026-11-24 (review of `d9dfb39`).** `docs/COMBAT_INFO_ACCESS_PLAN.md`
splits Candidate A into two independently acceptable batches. The sidebar and
pending-decision reveal plus focus stability lands first: it removes a hard stop (an
invisible focus owner, focus lost to `queue_free`, a decision the player cannot see or
resolve), while the log batch removes a comprehension gap. The log batch follows and
pins its engine assumptions — `RichTextLabel` focus mode and indirect-child reveal —
before any behaviour. The engine is Godot **4.7.2**; the `4.7` in `project.godot:18` is
only the major.minor feature tag. Review only: **no tests, probes, validators, builds or
exports were run**.

**Batch 1 implemented 2026-11-24 in `bad3a05`, closed on the `da95ed4` record.** The sidebar and pending-decision
reveal plus focus stability shipped as scoped: follow focus on the outer sidebar and
both inner lists, stable focus keys, rebuild signatures that include every written
value including disabled flags, focus restoration after layout, and decision seating
only when no usable owner remains. Suite 1001/1001, layout 32 controls at both scales,
probe 38 checks, candidate `2026-11-24_combat_info_batch1`.

**Batch 2 implemented 2026-11-24 in `4de76f1`, accepted on candidate
`2026-11-24_combat_log_focus_batch2`.** The combat log is one focus stop with the
widget's own Up/Down/Page/Home keys, freezes its rendered text when the reader leaves
the newest line, counts the lines that arrive while frozen and resumes with End; the
grid disables the stop while its cursor is active, so the accepted targeting path keeps
its focus owner. Suite 1011/1011, both validators, four existing probes plus the
extended `--combat-info-probe` (62 checks, 31 per scale), layout 32 controls at both
scales. Candidate 110,903,688 bytes, SHA-256 matched to `BUILD.txt` before and after
acceptance. Overrun remains deferred.

## Next bounded task - roadmap review after combat information access (2026-11-24)

Review only. Nothing was implemented, rebuilt, re-exported or re-checked for this
section, and **no tests, probes, validators, builds or exports were run**. It reads
`ROADMAP.md`, `PROGRAM_PROGRESS.md`, `SUPPORTED_FEATURES.md`, `TEST_REPORT.md`,
`TRACEABILITY.md`, `FEATS_SKILLS_COVERAGE.md`, `COMBAT_INFO_ACCESS_PLAN.md`,
`OVERRUN_PLAN.md`, the authored characters, monsters, spells and
encounters, and the combat, exploration, modal, victory, defeat and level-up code.

### Combat information access closed

Both batches are closed within their recorded evidence. Nothing was rebuilt, re-run or
re-exported for this closure.

- **Batch 1 (sidebar and pending-decision reveal plus focus stability)** - implementation
  `bad3a05c4488a4b4c5397d740b6ae2d1889375d4`, accepted on the `da95ed4` record,
  candidate `2026-11-24_combat_info_batch1` (110,900,648 bytes, SHA-256
  `0a4b83196b2158795b481a161365cc50018091684ffad979d9e47387fd417a53`). 9 focused tests
  (7 red before the change, 56 asserts green), suite 1001/1001, both validators,
  keyboard 31, grapple 160, level-up 349, advancement 228 and combat-info 38 checks,
  layout 32 controls at 100 % and 160 %. The candidate's disclosed working-tree entry is
  the uncommitted README quick-start removal, and its `.uid` anomaly is reconciled as a
  stale status snapshot, not a wrong source binding.
- **Batch 2 (log focus and scrolling)** - implementation
  `4de76f1314c44125f6fd0f70eb378a9c4e5c5dee`, accepted on the `fbbbbeb` record,
  candidate `2026-11-24_combat_log_focus_batch2` (110,903,688 bytes, SHA-256
  `caf129b85b5ee2de71e431a79f39811e91f784db3c5ff43558aeafd361bfad42`). 10 focused tests
  (2 red before the change, both engine pins; 42 asserts green), suite 1011/1011, both
  validators, four existing probes plus combat-info at 62 checks (31 per scale), layout
  32 controls at 100 % and 160 %, executable hash unchanged across acceptance. The
  generated `.uid` was committed with the implementation, so no untracked file appeared.

The acceptance remains automated input and geometry. It is not evidence of a rendered
focus ring, a human keyboard-only playthrough or screen-reader use, and this review does
not broaden it.

### Keyboard play of one demo combat, start to victory

Code reading only; **no run was made**. Each step below was checked for a keyboard path
that does not require the mouse.

| Step | Path | Verdict |
| --- | --- | --- |
| Explore to the encounter | `ExplorationScreen._unhandled_input` binds `move_forward/back`, `strafe_*`, `turn_*` and `interact` (`src/ui/exploration_screen.gd:311-352`) | Keyboard path exists |
| Start the fight | Authored triggers, dialogue effects and `Game.start_encounter`; nothing waits on a grid click | **No mouse step found** |
| Read the state | HUD labels, sidebar and the log, which is now a focus stop with its own scroll keys | Keyboard path exists |
| Choose an action | Action buttons are ordinary focusable `Button`s; disabled ones are skipped by Tab | Keyboard path exists |
| Pick a target | Grid cursor, arrows and Enter/Space through `_on_cell_clicked` (accepted in `072c15b`) | Keyboard path exists |
| Resolve a pending decision | Decision buttons are focusable, revealed by follow focus and seated when no usable owner remains (batch 1) | Keyboard path exists |
| End the turn | `End turn` is an action-grid button on a live player turn | Keyboard path exists |
| Victory | Ordinary victory returns to exploration with narration and the autosave; a campaign-completion victory opens `_show_victory` through `open_modal`, whose focus trap and initial focus are the shared modal path (`src/main.gd:10247`) | Keyboard path exists |
| Level-up, when the threshold is crossed | Opened from the sheet's `Level up` button; the level-up screen is keyboard-driven and probe-covered | Keyboard path exists |
| Defeat | `_show_defeat` builds `Load a save` and `Main menu` but sets no initial focus, and `_set_screen` focuses nothing (`src/main.gd:10181`, `:5558`) | **Not blocked** - Tab starts from the first focusable control; a presentation gap, not a dead end |

**Conclusion: no blocked step found.** What remains is untested behaviour (no continuous
human or scripted start-to-victory run exists; the probes cover pieces), and presentation
evidence (no rendered focus ring, no review of the log or hint, and the defeat screen's
missing initial focus). Those are not the same as a blocked path, and this review does
not propose work only to close them.

### What content and the supported level range actually make reachable

- **Three monsters exist and all three are undead** (`content/shared/monsters.json`:
  Drowned Dead, Infected Zombie, Corvin the Gate-Warden, all `monster_type` Undead,
  `equipment: {}`, natural weapons). The party's rogue carries `sneak_attack_dice: 2d6`
  (`content/shared/characters.json`), and `Encounter._resolve_attack` grants it only when
  the target is flanked, helpless or flat-footed **and not tagged `undead` or
  `construct`** (`src/core/encounter.gd:3004-3013`). In every shipped encounter the
  rogue's signature damage therefore never applies. That is a content gap, not a code
  defect: the rule is implemented and correctly gated.
- **No monster carries equipment or a manufactured weapon**, so disarm and sunder have no
  player-reachable target even though bull rush, trip, grapple, pin and cover are live.
- **No shipped spell is an area spell** (`content/shared/spells.json`: magic missile, mage
  armor, scorching ray, cure light wounds, bless, aid), so AoE templates have no
  authored user. Concealment and terrain hard cover have no terrain tags in the maps.
- **Levels 5 and above stay unreachable**: 10,000 XP against about 4,850 on one ordinary
  route, and no 3rd-level spell exists in content for the casters. The 4th-level step is
  now reached in play through the bell milestone.
- **At 4th level only the fighter gains a feat** (general levels [1, 3], class [1, 2, 4]).
  Weapon Specialization shipped in batch 7. Quick Draw is legal (BAB +1) and absent from
  `Feats.CATALOG`, but no shipped character can obtain a second weapon: Kaelen carries
  one longsword, nothing grants a weapon, and there is no item transfer, so the feat
  would be selectable and unusable. Rapid Reload is not a fighter bonus feat and no
  character has a general feat slot at 4th, so it is not legally obtainable either.
- Selectable, legally obtainable abilities were separated from raw hooks throughout:
  Improved Grapple, Improved Bull Rush and Quick Draw are catalog-absent or
  content-blocked; the feats that appear only as seeded text in tests and probes
  (Improved Grapple's +4, Improved Turning and Extra Turning outside authored characters)
  are hooks, not reachability.

### Candidate 1 - reachable opposition: one living, armed opponent (recommended, planning only)

- **Player benefit.** Sera's authored 2d6 sneak attack would apply for the first time in
  ordinary play, through a rule that already exists; a living opponent also gives the
  party a reason to use flanking and non-undead tactics, and it is the prerequisite
  content for any later disarm or sunder batch.
- **Repository evidence.** The three monsters above; the `undead` tag gate at
  `src/core/encounter.gd:3004`; Sera's `sneak_attack_dice`; and the flanked, helpless and
  flat-footed gates that already exist and are tested (no stealth or Hide mechanic is
  modelled, so those gates are the reachable ones).
- **Ordinary-play reachability.** Any encounter in any of the three campaigns; no feat,
  level or fixture is needed.
- **Unresolved decisions.** Which campaign and encounter hosts it; tone (the slice is
  undead horror, so the opponent needs an authored reason to be alive); CR and stat
  block; loot; and the XP ledger, because the bell milestone was sized to land a
  completing route on exactly 6,000, so a new award moves that arithmetic and the
  informational diagnostics line.
- **Dependencies and boundary.** Content only (`monsters.json`, one `encounters.json`,
  its trigger/effects), plus the XP totals and the diagnostics expectations. No rule,
  schema, save or UI change is expected; no code is known to be missing.
- **Acceptance needs.** Both validators, a focused test that the sneak gate applies to a
  living target and still refuses undead, the suite, a probe pass over the encounter,
  layout unchanged at both scales, and an exported candidate. The XP record must be
  re-derived rather than asserted from the old inventory.

**Plan written: [REACHABLE_OPPOSITION_PLAN.md](REACHABLE_OPPOSITION_PLAN.md) (2026-11-24).**
It verifies the printed sneak-attack, immunity and critical-hit rules, cites the schema,
turn-path, flanking, validator, XP-ledger and trigger seams, and resolves the open
decisions: `storeroom_dead` hosts the opponent, the second zombie is swapped rather than
a third combatant added, the encounter's 300 XP and the whole ledger stay unchanged, the
stat block is a CR 1/2 human warrior, only armor is authored as equipment (no weapon item,
no loot), and the AI needs no change. It records grapple hold damage and critical hits as
consequences, states that disarm and sunder stay unreachable, and defines a content-only
batch A with failing-first tests, checks and a hash-bound candidate. Batches B (monster
equipment attacks) and C (disarm) are recorded as separate work. Nothing was implemented
and no checks were run at the time of that review.

**Batch A implemented 2026-11-24 (content only).** `content/shared/monsters.json` now
carries `store_looter` (living human warrior 1, CR 1/2, 8 hp, AC 15, longsword authored as
an `attacks` entry, chain shirt only, no loot) and `storeroom_dead` fields it at (7,1) in
place of the second zombie, with new intro and victory narration. The encounter keeps two
combatants and its 300 XP; every award total and threshold is unchanged. New
`tests/test_reachable_opposition.gd` (6 tests) pins the stat block, `monsters`/
`monster_cells` parity and the trigger, sneak damage on the living flat-footed looter,
sneak refusal on the flat-footed zombie, the nonlethal knockout and the unchanged ledger.
Suite 1017/1017 (10,142 asserts, 78 scripts); both validators PASS; all five probes and
combat layout 32/0 at both scales; candidate `2026-11-24_living_opponent_batch_a`
(110,905,384 bytes, SHA-256 `8a7925de...092a8c`) accepted from the executable. Batches B
and C were not started. No playthrough, balance test, rendered review or human playtest
was done. **Batch A is closed on that evidence** (source `7547797`, candidate
`2026-11-24_living_opponent_batch_a`, records in `4327025`); the closure rebuilt and
re-ran nothing.

### Candidate 2 - further grapple (8c/8d)

Reachable (grapple and pin are ordinary actions) but the payoff is thin: the hold damage
is nonlethal, so "damage by opposed check" does nothing against the undead the crypt and
the town square field (the storeroom's living looter now takes it, which is batch A's
gain, not this candidate's); "move the grapple at half speed" is a movement feature with its own
decisions; "use the opponent's weapon" has no weapon to use. Casting from a grapple is
unreachable because the AI never grapples. Six decisions are already recorded in
`GRAPPLE_PLAN.md` and the 2026-11-24 review. **Not the next task.**

### Candidate 3 - save shortcut

Bounded (one input action and one handler), exploration-only, and the pause menu already
exposes Save from the keyboard, so the gain is convenience. It stays a ride-along, as
earlier reviews concluded. **Not a lead batch.**

### Candidate 4 - party item handoff

`use_potion_active` reads the active character's own inventory
(`src/core/encounter.gd:3906-3925`), and `SUPPORTED_FEATURES.md` lists trading between
characters as not supported. A found potion can therefore only be drunk by the character
who picked it up. Handing an item to another party member is a printed move action, so
the rules anchor exists, but the UI shape (inventory panel, recipient choice, whether
in-combat handoff is included) is an unscoped decision. **Planning only if prioritised;
not the recommendation.**

### Candidate 5 - defeat screen initial focus

`_show_defeat` sets no initial focus while every modal does. Bounded and harmless to fix,
but Tab recovers today, so it is presentation polish and an evidence item, not a batch.
**Do not schedule alone.**

### Recommendation

**Planning only: a short design note for reachable opposition (Candidate 1).** It is the
strongest player-reachable gap the repository actually supports - an implemented class
feature that no shipped encounter can exercise - and it is content work, not a rules
rewrite. It is not implementable as written because the encounter's host, tone, CR, loot
and XP arithmetic are design decisions, and the XP ledger is deliberately tuned. The note
should settle those, name the encounter, state which rules become live (sneak attack;
not disarm or sunder, which remain unimplemented), and define the acceptance above.

**No implementation is recommended from this review.** Overrun stays deferred under
`docs/OVERRUN_PLAN.md` §18; readied/delayed actions remain a subsystem needing their own
plan; the opposed-check helper is unchanged. Do not start levels 5+, disarm, sunder,
concealment, AoE or encumbrance to fill a schedule: content gives them no target.

**Planning note written 2026-11-24: `docs/REACHABLE_OPPOSITION_PLAN.md`.** It settles the
encounter, the swap, the unchanged XP ledger, the stat block, the equipment decision and
the AI dependency, and defines content-only batch A as the next implementation unit. No
content, schema, validator or code change was made, and no checks were run.

### Classification, kept separate

- **Confirmed defects.** None open, and this review found no failing case. Turn Undead
  stays closed as no product defect found; helpless attacks of opportunity, the
  paralyzed-ally firing penalty and the ranged probe stay closed as recorded; the
  keyboard targeting and both combat-information batches are closed above. Overrun stays
  deferred and the opposed-check helper is unchanged.
- **Deferred features.** Reachable opposition (this review's planning candidate); overrun;
  readied and delayed actions; grapple 8b-2/8c/8d/8f; disarm, sunder, concealment,
  terrain hard cover, AoE templates, encumbrance, disease; full attacks and two-weapon
  fighting; levels 5 and above; a save shortcut; party item handoff.
- **Maintenance debt.** Unchanged: the stale `Combat Casting` benefit text, the singular
  `modal` field, the probe-heavy `main.gd`, shallow UI suite coverage, source-text guards
  that cannot see a string-built call, the empty save-migration table and the placeholder
  renderer. The stale "combat-log scrolling and sidebar focus reveal stay deferred" lines
  in this file are corrected by this commit.
- **Evidence gaps.** No rendered review of the focus ring, the log, the hint or the
  defeat screen; no human keyboard-only start-to-victory run; the probes cover pieces.
  The rogue's sneak attack has automated rules coverage but no ordinary-play instance.
  None of these is a defect and none is proposed as work on its own.
## Roadmap review after the living opponent batch (2026-11-24) - Candidate 2 implemented and closed

Review only. Nothing was implemented, rebuilt, re-exported or re-checked for this section,
and **no tests, probes, validators, builds or exports were run**. It reads the current
`ROADMAP.md`, `PROGRAM_PROGRESS.md`, `SUPPORTED_FEATURES.md`, `TRACEABILITY.md`,
`TEST_REPORT.md`, `REACHABLE_OPPOSITION_PLAN.md`, `GRAPPLE_PLAN.md`,
`FEATS_SKILLS_COVERAGE.md`, the shipped content and the source seams it cites. Git status,
hashes, greps and JSON reads are documentation-integrity checks, not game checks.

### State this review starts from

Batch A is closed (source `7547797`, candidate `2026-11-24_living_opponent_batch_a`,
records in `4327025`). The content now holds four monsters - `zombie`, `infected_zombie`,
`ghoul`, `store_looter` - of which exactly one is living, and none has an equipped weapon
item. Across the three campaigns there are **8 encounters and 16 monster placements**: 15
undead and the one looter; `storeroom_dead` is the only encounter with a living opponent,
and it is also the only place a rogue's sneak attack now applies in ordinary play.

### Candidate 1 - batch B and C: equipment-driven monster attacks, then disarm and sunder

- **What a weapon item on a monster would need.** No schema change. `equipment.weapon` is
  already a valid, validated slot: `ContentDB._validate_actor` checks the slot against
  `Character.SLOTS` and the value against the shipped items (`src/core/content_db.gd:817-825`),
  and `Rules.attack_bonus` already falls back to `ch.equipment.get("weapon", {})` when no
  weapon is passed (`src/core/rules.gd:391`). What is missing is the monster turn path:
  `_primary_weapon` returns `attacks[0]` or a hardcoded slam and never reads equipment
  (`src/core/encounter.gd:678-692`), and both monster helpers prefer `ch.attacks`
  (`:4488-4528`). The validator has no rule tying an authored `attacks` entry to an
  equipped weapon, so authoring both today would silently diverge; batch B would add that
  cross-check. The content also has no plain longsword item - only `masterwork_longsword`
  (`attack_bonus: 1`) - so a weapon item would have to be authored or reused.
- **How many encounters disarm could act on.** One opponent in one encounter. Every other
  placement is undead with `equipment: {}`, and caster or natural-attack monsters cannot be
  disarmed at all. Disarm itself is absent: `src/core/encounter.gd:14` is a deferred
  comment, and the Improved Disarm and Improved Sunder catalog rows are marked deferred
  against "disarm special attack" and "sunder special attack"
  (`docs/FEATS_SKILLS_COVERAGE.md:169`, `:222`). Sunder additionally needs an object
  hit-point and hardness model that does not exist.
- **Implementation boundary.** B is one engine batch (weapon selection in the monster path,
  one validator cross-check, one content item, tests). C is a special-attack subsystem: a
  provoking melee attack, an opposed attack roll with the two-handed and light modifiers, a
  dropped-object state, pickup, the AI's response, and a UI path - a planning note plus one
  or two batches. Sunder is a third batch on top for object damage.
- **Verdict: defer, unchanged.** With one living armed opponent in the whole game, B changes
  the provenance of a single enemy's to-hit bonus and C would add a subsystem whose only
  legal target is that same looter. Neither is worth the batch on this evidence. Revisit if a
  campaign is authored with living, weapon-carrying opponents.

### Candidate 2 - flanking made attacker-specific: the printed +2 and a corrected sneak gate (recommended)

- **Player benefit.** Two printed effects that the engine only half-models. Flanking is
  worth +2 on melee attack rolls (PHB p. 153), which the engine never applies; and a rogue's
  sneak attack needs the rogue to actually flank ("when the rogue flanks her target", PHB
  pp. 49-50), which the engine does not check. A player who surrounds an enemy gets nothing
  but the rogue's dice, and a rogue who never flanks - including a ranged rogue across the
  room - collects those dice anyway.
- **Repository evidence.** The gate is `ch.sneak_attack_dice != "" and
  (Rules.is_helpless(target) or _is_flanked(target_index) or target_flat_footed) and not
  undead/construct` (`src/core/encounter.gd:3004-3013`): `_is_flanked` takes only the target
  (`:3171-3193`), so it asks whether any two of the target's enemies straddle it, not whether
  this attacker is one of them, and there is no melee check. `src/core/rules.gd` contains no
  flank term at all (`grep flank src/core/rules.gd` is empty); the attack-roll pipeline
  already has the right seam, with target-specific bonuses (`helpless +4`, `cowering +2`)
  added after `bonus_base` so Cleave does not copy them (`rules.gd:690-716`), and
  `_resolve_attack` already assembles `attack_opts` including a `"bonus"` field
  (`encounter.gd:3020`). The threat relation flanking needs is implemented and tested
  (`_threatens_cell`, `:753-756`; `tests/test_melee_threat.gd:194-206`).
- **Documentation defect this exposes.** `docs/SUPPORTED_FEATURES.md:406` and
  `docs/TRACEABILITY.md:166` both already claim flanking is one of the target-specific
  modifiers "evaluated afresh"; it is not implemented anywhere. The batch should make the
  code match those lines (or correct them), not leave the claim standing.
- **Ordinary-play reachability.** Every encounter: the party is 3-4 and every fight fields
  one or two enemies, so a pair can straddle a target in any room. Batch A makes the
  interaction visible for the first time, because the storeroom's looter is a legal sneak
  target; flat-footed still supplies sneak in round 1, so the fix does not remove the
  feature, it scopes it.
- **Decisions to settle in the batch.** The attacker must threaten the target and be one of
  the flanking pair; the bonus is melee-only; whether a melee touch spell counts; whether the
  AI also gains flanking (the monster helpers call `Rules.attack` directly at
  `encounter.gd:4488-4528`, so this is a separate line of work and a balance change - my
  recommendation is to include it only if the same helper can be reused without new AI
  behaviour, otherwise record it as deferred); whether the combat log names the +2; and
  whether the ranged sneak limit (30 ft, no concealment) ships now or as its own batch, since
  concealment has no content.
- **Implementation boundary.** One helper that answers "does this attacker flank this target"
  (reusing the existing threat test and side test), one gate change in `_resolve_attack`, one
  new `flank_bonus` option added after `bonus_base` in `Rules.attack`, one or two log lines,
  and tests. No content, schema, save, XP or UI-control change; the layout should stay at 32
  controls.
- **Acceptance needs.** Failing-first rules tests: a flanker gets +2 and a non-flanking ally
  does not; a ranged attacker gets none; a second-rank or non-threatening ally does not
  complete the pair; Cleave's granted attack does not inherit the flank bonus; an opportunity
  attack by a flanker does. Sneak tests: third-party flanking without participation grants
  nothing; a ranged rogue gets nothing from teammates' flanking; flat-footed, helpless and
  undead cases keep their current results. Then the suite (some seeded to-hit totals will
  move; re-baseline only the assertions the rule now changes, with the reason recorded), both
  validators, all five probes, both layout scales, and a hash-bound candidate accepted from
  its executable.

### Candidate 3 - save shortcut (usability)

- **Player benefit.** One key opens the existing Save modal instead of Escape, then Save
  game.
- **Reachability.** Exploration only; saving is deliberately disabled in combat and the pause
  menu already exposes the slots. Convenience, not a new capability.
- **Boundary and cost.** One input action, one handler, a modal/focus test and a probe key
  step; no save-policy, schema or content change. Already reviewed and deferred as Candidate
  4 of the 2026-11-24 input review (`docs/ROADMAP.md:1453`); it is small enough to ride with
  a larger input batch rather than lead one.
- **Verdict.** Keep deferred; it is not the strongest use of a bounded batch next to a rule
  the game gets wrong.

### Candidates that stay deferred without a batch

- **Coup de grace and `hold person`.** Both are legal in the supported 3rd-4th level range -
  `hold person` is a 2nd-level spell and the content already ships 2nd-level spells
  (`aid`, `scorching_ray`) - and neither exists. Coup de grace alone has no reachable target:
  nothing a player can do creates a helpless enemy (the ghoul's paralysis points the other
  way, and no AI uses it on the party). `hold person` plus coup de grace is therefore a
  content-plus-rules pair with a save, a duration, a helpless state that already exists and a
  full-round kill action: planning first, not a bounded batch.
- **Levels 5 and above.** Outside the supported range (3rd to 4th,
  `docs/SUPPORTED_FEATURES.md:49`); no content or award supports it.
- **Two-weapon fighting, full attacks, encumbrance, concealment, terrain hard cover, AoE
  templates, disease, party item handoff.** Each lacks a selectable ability, content target
  or model; none becomes reachable because of batch A.
- **Further grapple, overrun, readied and delayed actions.** Deferred exactly as before; this
  review adds nothing and changes nothing about them.

### Selectable abilities, raw hooks and seeded fixtures

- **Selectable in ordinary play.** Attack actions in every encounter; sneak attack through
  flat-footed (round 1) and now through a flanked or helpless living target; nonlethal
  knockouts; grapple and pin; trip; bull rush; fighting defensively, total defence, Combat
  Expertise, Power Attack and Cleave for the characters that have them.
- **Raw hooks without reachable content.** Disarm and sunder (no special attack, and now one
  armed target), equipment-driven monster attacks (no monster weapon item), coup de grace (no
  player-made helpless enemy), `hold person` (no spell), AI grapple, two-weapon fighting (no
  party feat), sunder's object damage (no object model).
- **Seeded fixtures and probes only.** Grapple and pin scenarios, the Turn Undead QA
  encounter, `qa_victory`, the combat-information five-enemy fixture and the level-up walk.
  Their evidence is real but they are not ordinary play.

### Recommendation

**Implement Candidate 2 in one bounded batch: make flanking attacker-specific, applying the
printed +2 on melee attack rolls and requiring the rogue to be one of the flankers for a
flank-based sneak attack.** It needs no new content, fixes a rule the game currently gets
wrong in a way a player can see, pays off the storeroom's living target, and fits the
existing `bonus_base` seam without touching overrun, readied actions, movement continuation
or the opposed-check helper. Correct the two documentation claims in the same batch (or hold
them until it lands). Candidate 1 (batches B and C) stays deferred: one living looter does
not justify a weapon-item engine change plus two special attacks. Candidate 3 stays a small
usability rider for a future input batch. Coup de grace and `hold person` get a planning note
only if that capability is wanted.

### Classification, kept separate

- **Confirmed defects.** (1) Rule defect, found by reading: the sneak gate never checks that
  the attacker is one of the flankers and never checks melee, so a third party's flank or a
  ranged rogue grants sneak damage (`encounter.gd:3004-3013`, `:3171-3193`). It was not
  reproduced by a failing test in this review because no checks were run; the
  implementation batch's failing-first test then reproduced it (see the closure
  below). (2) Documentation defect: `SUPPORTED_FEATURES.md:406`
  and `TRACEABILITY.md:166` claim flanking is re-evaluated as an attack bonus that the code
  never applies. No other failing case was found. Batch A introduced no defect.
- **Deferred features.** Batch B (equipment-driven monster attacks) and C (disarm, sunder,
  object damage); overrun (`docs/OVERRUN_PLAN.md` section 18); readied and delayed actions;
  further grapple (8b-2/8c/8d/8f); coup de grace with `hold person`; the ranged sneak 30-ft
  and concealment limits if not taken with Candidate 2; levels 5 and above; two-weapon
  fighting and full attacks; encumbrance, concealment, terrain hard cover, AoE templates,
  disease; party item handoff; the save shortcut.
- **Maintenance debt.** Unchanged: the stale `Combat Casting` benefit text, the singular
  `modal` field, the probe-heavy `main.gd`, source-text guards that cannot see a string-built
  call, shallow UI suite coverage, the placeholder renderer. Newly recorded: `OVERRUN_PLAN.md`
  cites `encounters.json` lines 2-56 for `storeroom_dead`, which is now lines 2-60 after batch
  A, and the flanking claims above until Candidate 2 lands.
- **Evidence gaps.** No ordinary-play playthrough, balance test, rendered review or human
  playtest of batch A; the sneak gate's wrong grants are a code reading, not a reproduction;
  grapple, pin and Turn Undead behaviour remains probe- or test-only; no rendered check of
  the new narration, the looter's sidebar row or the stat block. These are disclosures, not a
  reason to schedule work.

### Closure - Candidate 2 implemented (2026-11-24)

**Printed rules, recorded separately from the adaptation.** Verified against the
d20srd "Combat Modifiers" page (<https://www.d20srd.org/srd/combat/combatModifiers.htm>),
with PHB pp. 137 and 153 (PDF 138 and 154) and the Rogue class features (PHB pp.
49-50) as the printed references. Quoted text:

- "+2 flanking bonus if your opponent is threatened by a character or creature
  friendly to you on the opponent's opposite border or opposite corner".
- "Only a creature or character that threatens the defender can help an attacker
  get a flanking bonus".
- The melee attack-roll modifiers table lists "Flanking defender | +2".
- A rogue deals extra damage "when the rogue flanks her target"; the printed
  ranged-sneak limit is 30 feet.

**Project adaptation, decided explicitly.** The +2 is computed per attacker: the
attacker must itself threaten the target, and an able ally must threaten it from an
opposite border or corner. Ranged attacks never carry it; melee touch attacks (trip,
grapple) do, because a melee touch attack is a melee attack. A helpless creature -
paralyzed, held, unconscious or dying - neither flanks nor completes a pair: it
cannot make the melee attack that threat is. Monsters use the same helper, so parity
is structural (`_monster_single_attack`, `_monster_full_attack` and the opportunity
attack pass `flank_bonus`), not a party-only concession. A rogue's flank-based sneak
attack requires her own flank and is melee only; helpless and flat-footed targets
remain independent routes, and undead and constructs stay immune. Cleave's granted
attack runs through `_resolve_attack`, so it re-evaluates the new target instead of
inheriting a stale bonus. The 30-ft ranged sneak limit was implemented in the next
batch (see the ranged sneak section below); concealment and the vitals clause remain
unmodelled. Overrun, the opposed-check helper, occupancy,
opportunity-attack eligibility and the engagement model are untouched.

**Defect status.** The review recorded the sneak gate as a suspected defect read from
code. It is now reproduced: `tests/test_flanking.gd` failed before any implementation
(9 tests, 5 pass, 4 fail, 42/47 asserts, exit 1,
`builds/qa/flanking_red/focused_red.log`), showing the flanking attacker's printed
roll carrying +5 where +7 was due, and a crossbow rogue and a third-party flank both
receiving `sneak attack applies: +2d6`.

**Implementation** (commit `1e7dc4b`, one bounded batch):

- `Encounter._threatening_positions` (able, non-helpless, actually-threatening
  enemies), `Encounter._opposite_sides` and `Encounter._flank_bonus` (this attacker's
  own flank). `_is_flanked` stays as the target-side question the older tests use.
- `Rules.attack` adds `opts.flank_bonus` after `bonus_base`, melee only; the
  encounter logs `flanking +2 (PHB p.153)`.
- Passed at `_resolve_attack` (ordinary attack, reaction and Cleave), both monster
  helpers, the opportunity attack, and trip and grapple touch attacks.
- `tests/test_flanking.gd` (10 tests, 49 asserts) and `--flanking-probe` (8 checks),
  which seeds cells and turn ownership and drives `Game.combat_attack`.
- Claims corrected: `SUPPORTED_FEATURES.md` (feature bullet and the Cleave modifier
  list) and `TRACEABILITY.md` row 24 and its Cleave paragraph.

**Verification on `1e7dc4b`** (the README quick-start removal was left uncommitted and
untouched; its file hash and diff hash were re-verified before and after):

- Focused: 10 tests, 10 pass, 49 asserts, exit 0
  (`builds/qa/flanking_green/focused_green.log`).
- Full suite: 1027 tests, 1027 pass, 10,193 asserts, 79 scripts, exit 0, no script
  errors (`builds/qa/flanking_green/suite_final.log`).
- Validators: `--validate-campaigns` and `--validate-diagnostics` both PASS; the
  diagnostics line is unchanged (`authored=4500 ordinary=4350 qa=150 encounters=1500
  effects=3000 start=3000 threshold=6000`).
- Probes: keyboard 31, grapple 160, level-up 349, advancement 228 and combat-info 62
  checks, plus the new flanking probe's 8, all PASS.
- Combat layout at text 1.00 and 1.60: 32 controls and 0 failures at both scales.

**Acceptance from the executable**
(`builds/qa/candidates/2026-11-24_flanking_attacker_specific/RavenloftFoundationEdit.exe`):
BUILD.txt records `source_head=1e7dc4b65efd5376fb57c57ab9a255684efb4981`,
`worktree_entries=1` (the README removal only),
`worktree_diff_sha256=0e8ff3e146d889b0e942158f588ca92122c4eec62eaaa1bde349a91dc9d95e1c`,
`untracked_files=0`,
`exe_sha256=58ce0ce260b9130529a6b753babb80ff2e55a6bd7e50a83e5350807b97d01455`
and `exe_bytes=110911512`; that hash was identical before and after the acceptance
runs (both validators, all six probes, layout at both scales). Logs are in
`builds/qa/flanking_attacker_specific_acceptance/`.

**Evidence gaps and boundaries.** Only automated rules behaviour was checked: no
balance testing, no playthrough and no human playtest, and the new log line was not
reviewed in a rendered window (the probe is headless). No content, schema, save, award
or XP change was made, nothing was pushed, and no backup was taken.


#### Monster parity changes shipped difficulty without measurement (documentation only)

Monsters receive the flanking bonus on the same terms as the party, which is what the
shared `_flank_bonus` helper gives them and what the printed rule asks for, so it is not a
defect. It does change the difficulty of any shipped fight that can produce a monster flank,
and this batch did not measure that change: the only living opponent is `store_looter`,
every other monster is undead and immune to sneak attack, and no fight was replayed to
compare outcomes. No balance testing, playthrough or human playtest was done. A later balance
or content pass should treat this as an unmeasured rules change rather than a regression.

## Ranged sneak limit implemented (2026-11-24)

**Printed rules, recorded separately from the adaptation.** Verified on the d20srd
Rogue page (<https://www.d20srd.org/srd/classes/rogue.htm>), PHB p. 50: "Ranged
attacks can count as sneak attacks only if the target is within 30 feet." The
sentence is a condition on ranged attacks as a class, not on one route into sneak
attack, so it governs a ranged attack against a flat-footed or helpless target just
as it would any other; flanking cannot interact with it because flanking needs melee
threat and a ranged attacker never flanks. The SRD's neighbouring sentences also
withhold sneak attacks against concealment and "the limbs of a creature whose vitals
are beyond reach"; neither clause is modelled.

**Measurement decision (no plan needed).** "Within 30 feet" is attacker-to-target,
which the engine already measures with `BattleMap.distance_ft` (Chebyshev cells x 5
ft., `src/core/battle_map.gd:56`) for range increments and the into-melee penalty.
At 30 ft. the shot qualifies and at 35 ft. it does not; the grid cannot express a
fraction between them.

**Inspection.** The gate sat in `Encounter._resolve_attack`
(`src/core/encounter.gd:2985`) and read only the target's state
(`Rules.is_helpless(target) or flank_bonus > 0 or target_flat_footed`, `:3022-3025`)
while the same function already held the distance it passes to `Rules.attack` for
range modifiers. The ordinary ranged path is `Encounter.attack_active`
(`:788`), which resolves the primary weapon (`_primary_weapon`, `:678`), checks
range increments (`:891`) and then calls `_resolve_attack`; `Game.combat_attack`
forwards to it. Nothing in the path compared the distance with 30 ft.

**Defect status.** Recorded as suspected until reproduced. `tests/test_sneak_range.gd`
ran red first (5 tests, 4 pass, 1 fail, 30/32 asserts, exit 1,
`builds/qa/sneak_range_red/focused_red.log`): the 35-ft crossbow shot against a
flat-footed looter carried `extra [4, 4]` damage dice. The three positive controls
(25 ft., the 30-ft boundary, melee) and the non-rogue case passed in the same run,
so the failure isolated the missing limit.

**Correction** (commit `81b00f6`): `sneak_range_ok` in `_resolve_attack`
(`:3015-3017`) is false only for a ranged attack beyond 30 ft., the gate requires it
(`:3024`), and the encounter logs `no sneak attack beyond 30 ft. (PHB p.50).`
(`:3077`) when it withholds dice. Flanking, range increments, cover, engagement, the
opposed-check helper and the action economy are untouched: the shot still resolves
and still spends the standard action.

**Verification on `81b00f6`** (README quick-start removal left uncommitted and
untouched; file hash and diff hash re-verified before and after):

- Focused: `tests/test_sneak_range.gd` and `tests/test_flanking.gd`, 15 tests, 15
  pass, 82 asserts (`builds/qa/sneak_range_green/focused_green.log`).
- Full suite: 1032 tests, 1032 pass, 10,228 asserts, 80 scripts, exit 0, no script
  errors (`builds/qa/sneak_range_green/suite_final.log`).
- Validators: both PASS; diagnostics line unchanged (`authored=4500 ordinary=4350
  qa=150 encounters=1500 effects=3000 start=3000 threshold=6000`).
- Probes: keyboard 31, grapple 160, level-up 349, advancement 228, combat-info 62,
  flanking 8 and the new `--sneak-range-probe` 9 checks, all PASS.
- Combat layout at text 1.00 and 1.60: 32 controls, 0 failures at both scales.

**Acceptance from the executable**
(`builds/qa/candidates/2026-11-24_ranged_sneak_limit/RavenloftFoundationEdit.exe`):
BUILD.txt records `source_head=81b00f68b89e5c474196a3ea866a4103256e5603`,
`worktree_entries=1` (the README removal only),
`worktree_diff_sha256=0e8ff3e146d889b0e942158f588ca92122c4eec62eaaa1bde349a91dc9d95e1c`,
`untracked_files=0`,
`exe_sha256=1788d811eb35a4f973b24e420e23a346a75fe2bbed7ab344a736d5f87e2e9026`
and `exe_bytes=110914344`; the hash was identical before and after the acceptance
runs (both validators, all seven probes, layout at both scales). Logs are in
`builds/qa/ranged_sneak_limit_acceptance/`.

**Evidence gaps and boundaries.** Automated rules behaviour only: no balance testing,
no playthrough and no human playtest, and the new log line was not reviewed in a
rendered window. Concealment and the vitals clause remain unimplemented; overrun
stays deferred; no content, schema, save, award or XP change was made.

**Closed 2026-11-24 within this evidence.** The audit below re-reads the gate, the documentation and the candidate record without rebuilding or re-running anything, so the acceptance stands on candidate `2026-11-24_ranged_sneak_limit` (source `81b00f6`, records in `5483c6c`).

## Documentation consistency audit and next-task review (2026-11-24)

Documentation only. No tests, probes, validators, builds or exports were run for this
section, and no executable, test, probe, content, schema or save file was changed. The
checks that were made are documentation-integrity checks: `git log`/`git status`, the
README file and diff hashes, greps over documentation and source, JSON reads of the
shipped content, and source reading. Nothing here is a game check.

### What was compared

The claims in `SUPPORTED_FEATURES.md`, `TRACEABILITY.md`, `FEATS_SKILLS_COVERAGE.md`,
`ROADMAP.md` and the plan files were read against the code for the features this session
touched: pin, keyboard targeting, helpless attacks of opportunity, the paralyzed-ally
firing penalty, combat information access, the living opponent, flanking and the ranged
sneak limit. The earlier closures are carried forward unchanged.

### Correction made (a claim the code contradicts)

`SUPPORTED_FEATURES.md`'s combat bullet said a rogue's sneak attack needs her to be one of
the flankers "or the target to be helpless or flat-footed" without qualification. Since
`81b00f6`, a ranged attack against a flat-footed or helpless target beyond 30 ft. carries no
sneak dice (`Encounter._resolve_attack`, `src/core/encounter.gd:3015-3025`), so the bullet
now adds "(inside 30 ft. when the attack is ranged, see above)". That is the only claim the
code clearly contradicted in the audited set.

### Claims checked and confirmed (no change)

| Feature | Claim and where | Code evidence |
| --- | --- | --- |
| Pin | Standard action on the existing hold, win records `pinned`, loss keeps the grapple; ends at the start of the pinner's next turn even if the pinner cannot act; escape clears only the pin; the pinner cannot attack; third parties take -4 to normal and touch AC and the pinner does not (`SUPPORTED_FEATURES.md:343-352`) | `is_pinned`/`pin_holder`/`pinned_ac_penalty` (`encounter.gd:412-434`), `_pin_blocks` (`:466-472`), pin expiry and cleanup (`:238-245`, `:2293`), `Rules.armor_class`/`touch_ac` applying `pinned_penalty` (`rules.gd:291-293`, `:315`), AI escape and no AI pin (`encounter.gd:4305-4306`) |
| Keyboard targeting | Cursor seats on the actor, arrows move it, Enter/Space resolve through the click path, Escape cancels without spending, focus returns; cursor may rest on a blocked cell and ordinary validation refuses it (`SUPPORTED_FEATURES.md:246-256`) | `combat_view.gd:81-133` (key handling, `begin_keyboard_cursor`, `end_keyboard_cursor`), `combat_screen.gd:405-435` (seat, sync, cancel), `:448-461` (`ui_cancel` path) |
| Keyboard combat log | One focus stop; Up/Down/PgUp/PgDn/Home use the widget, leaving newest freezes and counts arrivals in the hint, End resumes; grid cursor disables the stop (`SUPPORTED_FEATURES.md:252-256`) | `combat_screen.gd:149-161`, `:1054-1060` (hint and frozen count), `:406`/`:435` (stop disabled while the cursor is active), `:464-470` (`ui_end`) |
| Helpless attacks of opportunity | A helpless creature cannot take the reaction (`TRACEABILITY.md:47`, adaptation record) | `_provoke_single_opportunity` (`encounter.gd:3473-3498`) refuses `is_helpless` before an attack, a budget entry or a log of a resolved reaction |
| Paralyzed-ally firing penalty | "Helpless targets count as not engaged", and an ally who cannot act cannot create the -4 (`TRACEABILITY.md:59`) | `_into_melee_penalty` (`encounter.gd:3403-3433`): target-side helpless exemption, then `not ally.can_act() or Rules.is_helpless(ally)` skipped when finding engagement |
| Combat information access | Both batches closed; keyboard can review earlier rolls and read target/AC information (`COMBAT_INFO_ACCESS_PLAN.md` status, `SUPPORTED_FEATURES.md:250-256`) | log focus/hint code above; 62-check `--combat-info-probe` in the last accepted run |
| Living opponent | One living monster in shipped content and it is reachable; the encounter keeps its two combatants and 300 XP (`REACHABLE_OPPOSITION_PLAN.md`, `SUPPORTED_FEATURES.md:40-42`) | `content/shared/monsters.json` has 4 monsters, only `store_looter` without an undead tag; the three campaigns hold 8 encounters and 16 placements; `tests/test_reachable_opposition.gd` |
| Flanking | +2 melee bonus only for an attacker that itself threatens with an able ally on the opposite border or corner; ranged never; monsters share it; helpless allies do not complete a pair (`SUPPORTED_FEATURES.md:161-164`, `TRACEABILITY.md:57`) | `_threatening_positions`/`_opposite_sides`/`_flank_bonus` (`encounter.gd:3200-3265`), passed by `_resolve_attack`, both monster helpers, the opportunity attack and the trip/grapple touches, added in `Rules.attack` after `bonus_base` (`rules.gd:710-723`), log at `:3069` |
| Ranged sneak limit | Ranged sneak only within 30 ft., attacker-to-target, flat-footed and helpless included; melee unaffected (`SUPPORTED_FEATURES.md:40-42`, `TRACEABILITY.md:57`) | `sneak_range_ok` (`encounter.gd:3015-3025`) and the withheld-dice log (`:3077`) |

### Maintenance debt found and left unrewritten

- **`OVERRUN_PLAN.md:228-229` line drift.** It cites `content/campaigns/ravenloft_demo/encounters.json` lines 2-56 for `storeroom_dead`; the block now runs lines 2-59. `ROADMAP.md:2104`'s "now lines 2-60" is also one line long. The `monsters.json:3`, `:76` and `:152` references still land inside the intended blocks (zombie, infected zombie, ghoul).
- **Probe-count drift.** `SUPPORTED_FEATURES.md:357-361` records `--grapple-probe` at 154 checks (147 at pin acceptance); the last accepted run reported 160. The earlier counts inside ROADMAP/TEST_REPORT sections stay as historical records.
- **Plan-file line references drift with the code** (`COMBAT_INFO_ACCESS_PLAN.md` section 2 cites `combat_screen.gd:110-120`, `:824-829`, `:303-310`, and similar; `PIN_PLAN.md` and `GRAPPLE_PLAN.md` cite encounter lines that moved).
- **Retired debt: the "stale `Combat Casting` benefit text".** `src/core/feats.gd:49` now reads "+4 on Concentration checks made to cast on the defensive (grappling and pinned are not modeled)", which matches `TRACEABILITY.md:44` and `FEATS_SKILLS_COVERAGE.md:167`. The string is accurate and the debt is retired; older review sections that list it stay as history.
- Unchanged debt: the singular `modal` field, the probe-heavy `main.gd`, shallow UI suite coverage, source-text guards that cannot see a string-built call, the empty save-migration table and the placeholder renderer.

### Concealment against shipped content

Concealment exists only as a deferred comment (`encounter.gd:15`). Nothing authored can
create it: the six shipped spells are `magic_missile`, `mage_armor`, `scorching_ray`,
`cure_light_wounds`, `bless` and `aid`; none of the four monsters has a concealment
ability; no map carries concealment terrain and no condition in the engine represents it.
Concealment is therefore unreachable and stays deferred without a plan or a batch.

### Candidate comparison for the next task

| Candidate | Benefit | Ordinary-play reachability | Boundary and unresolved decisions | Verdict |
| --- | --- | --- | --- | --- |
| Combat Aid Another (PHB p.154) | A new party tactic: trade a standard action for +2 on an ally's next attack against a chosen foe, or +2 AC for that ally against it | Every fight: a party member who threatens an enemy and an ally fighting it | One action, one attack roll against AC 10, one effect with a duration, one choice in the existing pending-decision UI, one log line, tests and a probe. Decisions: the choice is asked after a successful roll, the effect expires at the start of the helper's next turn, and the AI never uses it | **Recommended** |
| Save shortcut | One key opens the existing Save modal | Exploration only; the pause menu already exposes Save, which keeps this convenience-only | One input action and one handler; already reviewed and deferred twice | Not the next batch |
| Defeat screen initial focus | Focus lands on the first usable control instead of needing Tab | Defeat screen only | One focus call and a test; presentation polish with no gameplay effect | Do not schedule alone |
| Party item handoff | A found potion can reach the character who needs it | Exploration inventory; combat feeding already works from the actor's own pack (`use_potion_active`, `encounter.gd:3980-4010`) | Recipient picker and screen host are unscoped, and whether the printed move action applies in combat is a design decision | Plan first if prioritised |
| `hold person` plus coup de grace | Would create and use a helpless enemy | Not reachable today: nothing a player can do makes an enemy helpless | Content plus a spell, a save, a duration and a full-round action | Plan, outside a bounded batch |
| Disarm | Would strip a weapon in a fight | The only living opponent carries an `attacks` entry, not an equipped weapon | Depends on equipment-driven monster attacks, which this review excludes | Blocked by that dependency |
| Concealment | Rimed miss chance, Blind-Fight prerequisite | No authored source | No model and no target | Defer, no plan |
| Further grapple, overrun, readied/delayed actions, movement continuation, shared tie helper, equipment-driven monster attacks | — | — | Excluded by this review's instructions; unchanged | Not considered |

### Recommendation

**Implement combat Aid Another in one bounded batch.** It is the strongest remaining
player-reachable rules option that does not depend on any excluded subsystem: the seam is a
normal attack roll (`Rules.attack` already has the melee bonus it needs), the choice can
reuse the pending-decision pattern that trip and Cleave already use, and the effect is one
timed modifier on an existing attack or AC. Scope: party members only; the helper must
threaten the chosen opponent; d20 + melee attack bonus against AC 10; on success the choice
of +2 attack or +2 AC, lasting until the start of the helper's next turn; failure and
success both spend the standard action; the AI never uses it; no content, schema, save,
award or XP change; the opposed-check helper stays unchanged.

Acceptance for that batch: failing-first tests through `Encounter.attack_active`'s sibling
action path and `Game`'s wrapper for success, failure, both choices, the expiry, the refusal
when no enemy is threatened or no ally is available, and the action spent either way; a
probe through the ordinary action path with seeded setup labelled; the focused tests, full
suite, both validators, all probes and combat layout at both scales with 32 controls.

If the project would rather not add a new action, the honest alternative is a **stopping
point**: no open confirmed defect, no reachable unimplemented rule that is bounded, and the
remaining items are content design, unscoped UI or excluded subsystems. Do not start a
batch merely to close an evidence gap.

### Classification, kept separate

- **Confirmed defects.** None open. This audit found no executable defect and one
  documentation claim the code contradicted (the unqualified ranged sneak sentence),
  corrected above.
- **Deferred features.** Concealment, `hold person` and coup de grace, disarm and sunder,
  further grapple (8b-2/8c/8d/8f), overrun, readied and delayed actions, movement
  continuation, levels 5 and above, two-weapon fighting and full attacks, encumbrance, AoE
  templates, terrain hard cover, disease, party item handoff, the save shortcut.
- **Maintenance debt.** The list above; nothing was rewritten beyond the one corrected claim.
- **Evidence gaps.** Carried forward unchanged: no rendered review of the focus ring, the
  log, the hint or the defeat screen; no human keyboard-only run; no playthrough, balance
  test or human playtest of any rules batch; the probes cover pieces, not play. This review
  adds no new gap and closes none.


### Audit closed (2026-11-24)

**Closed.** The audit above is complete and needs no further action. Its one corrected claim
(the unqualified ranged sneak sentence) stands, its debt list is not rewritten, and the
Combat Casting text debt stays retired. The recommended Aid Another batch now has a
planning-only note, `docs/AID_ANOTHER_PLAN.md`: printed rules from PHB p. 154 verified against
the SRD and separated from seven project adaptations, exact repository seams, resolved
decisions on who may aid whom, when the bonus kind is chosen, state ownership and expiry,
stacking and the grapple/pin/helpless/flanking interactions, failure cost, control and layout
expectations, keyboard and mouse paths, monster AI, an honest reading of when the action is
worth taking in the shipped encounters, failing-first tests, probe scenarios, hash-bound
acceptance and a two-batch split with the attack half recommended first.

Nothing was implemented, and no test, probe, validator, build or export was run to write it;
the checks were documentation-integrity only. The classification stands: no confirmed defect,
the deferred list unchanged, the same maintenance debt, and the action's unmeasured control
count recorded as an evidence gap rather than assumed. Overrun stays deferred, the
opposed-check helper is unchanged, and the earlier acceptance limits carry forward unchanged.

Godot 4.7 EPUB audit (2026-11-24): static, documentation-only findings are recorded in [AUDIT_EPUB.md](AUDIT_EPUB.md); no priority above changed.
