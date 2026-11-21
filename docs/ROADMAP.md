# Prioritized Continuation Roadmap

> **Current boundary (2026-11-21).** 754/754 tests, 7,886 assertions, 59 scripts,
> exit 0; `--validate-campaigns` and `--validate-diagnostics` both PASS, and the
> windowed probes run at 1280×720 at 100 % and 160 %. Creature soft cover on
> ranged attacks (and its inspector clause) is accepted within its recorded
> scope. Fighting defensively and total defense are accepted as committed
> stances; candidate `defensive_actions_2026-11-21c` (`58cb1a7`) passes its probe,
> both validators and a matching before/after exe hash, and carries the
> source-tested combat-scope cleanup. `-b` is preserved and superseded. Both that
> batch and its cleanup are closed as accepted within the recorded limits; the
> recommended next batch is player-initiated bull rush (review below). Earlier candidates
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

Review only. Nothing was implemented, rebuilt or re-checked for this section, and
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
   sunder and bull rush remain open; bull rush is the recommended next batch.
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
