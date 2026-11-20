# Prioritized Continuation Roadmap

> **Current boundary (2026-11-20).** 550/550 tests, 6,403 assertions, 45 scripts,
> exit 0; `--validate-campaigns` and `--validate-diagnostics` both PASS, and the
> exported `ui_scaling_2026-11-20b` candidate repeats them. (The 2026-11-14
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
was not present in the loaded autosave, so this persistence gap remains open.
Mage Armor targeting and
Restore Default Controls were fixed. A fresh Windows build launches outside the
source tree.

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

## P0 — Verify and harden the current slice

1. **Finish the manual UI interaction pass.** **Done:** Restore Default Controls
   ships in the Settings panel behind a confirmation dialog and is covered by the
   persistence test; E3 victory/return-state persistence is recorded in
   [PHASE3_VERIFICATION.md](PHASE3_VERIFICATION.md). Remaining: the high-DPI and
   mouse-wheel/focus checks in [PHASE2_VERIFICATION.md](PHASE2_VERIFICATION.md).
2. **Audio review.** Listen to all 14 placeholders in a windowed run; confirm loops,
   volume sliders and ducking behavior. Replace only after the hooks are proven.
3. **Resolution/DPI pass.** **Corrected 2026-11-20.** The client area is the
   layout surface (`display/window/stretch/mode="disabled"`), so a bigger window
   now gives the UI more room instead of magnifying a fixed 1280×720 canvas.
   1280×720, 1600×900, 1920×1017 maximized and 1920×1080 fullscreen are verified
   at 100 % and 160 % text by `--layout-probe`; 1024×600 was never a supported
   size (the window minimum is 1280×720). Remaining: high-DPI and
   mouse-wheel/focus checks in [PHASE2_VERIFICATION.md](PHASE2_VERIFICATION.md).
4. **Save migration policy.** Add a schema migration hook before the first public
   content update; keep the version refusal until then.
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
4. Save schema migration hook before the first public content update.
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
2. **Grapple, trip, disarm, sunder, bull rush** as explicit combat actions with
   contested checks and provoked attacks. Power Attack and Combat Expertise are
   implemented, so Improved Trip/Disarm/Bull Rush/Overrun/Sunder become candidates
   once those actions exist; fighting defensively and total defense are still
   unimplemented.
3. **Cover and concealment** for ranged combat and spells (basic Bresenham LOS already exists).
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
   tokens (already letter/HP coded), keyboard-only flows, screen-reader-friendly
   labels where feasible.
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
- Keep missing optional assets non-fatal.
- Update `SUPPORTED_FEATURES.md` and the README scope whenever a mechanic moves
  from deferred to supported.

## Known technical debt

- No save migration beyond version refusal.
- Full exported-build acceptance is not repeated after every rules batch; the
  latest candidate is launch-smoke-tested outside the source tree.
- Settings persistence path/versioning is minimal.
- Combat AI is intentionally simple.
- No content hot-reload; restart after JSON edits.
- Screenshots/docs are excluded from import but not from the source tree; keep
  them out of exported assets.
- The raycaster is a stylized placeholder, not a production renderer.
- Test count is strong for rules and flow, but UI interaction coverage is shallow.
