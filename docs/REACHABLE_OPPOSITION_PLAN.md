# Reachable opposition: one living, armed opponent (planning note)

**Status: batch A closed 2026-11-24 within the evidence recorded in `4327025` for source
`7547797` and candidate `2026-11-24_living_opponent_batch_a` (content `6ff777a`, tests and
their `.uid` in `7547797`). Batches B and C are not implemented.** This note began as planning only and
resolves the decisions the 2026-11-24 review in `docs/ROADMAP.md` (commit `8c8b3b8`)
listed, no more. Section 9 records what the batch actually changed and what was run.

## 1. Why this exists

Every shipped monster is undead, and the rogue's signature damage is gated on that
tag, so an implemented class feature cannot occur in ordinary play:

- `content/shared/monsters.json` holds exactly three monsters - `zombie`,
  `infected_zombie`, `ghoul` - and all three carry `"tags": ["undead"]`, an
  undead `monster_type`, `"equipment": {}` and natural attacks only.
- Sera, the party rogue, is authored with `"sneak_attack_dice": "2d6"`
  (`content/shared/characters.json`).
- `Encounter._resolve_attack` grants the extra damage only when the attacker has
  sneak dice, the target is helpless, flanked or flat-footed, **and** the target is
  not tagged `undead` or `construct` (`src/core/encounter.gd:3004-3013`).
- `Rules.roll_damage` adds that extra once, outside the critical multiplier
  (`src/core/rules.gd:832-858`), so the printed "not multiplied" clause already
  holds.

The rule is correct and the gate is correct; the content never presents a legal
target. This note is about adding one, not about changing the rule.

## 2. Verified printed rules

Verified against the 3.5 SRD text (d20srd Rogue, https://www.d20srd.org/srd/classes/rogue.htm)
and PHB pp. 49-50, 153:

- **Sneak attack.** Extra damage "any time her target would be denied a Dexterity
  bonus to AC (whether the target actually has a Dexterity bonus or not), or when
  the rogue flanks her target". Sera's 2d6 matches her 3rd level.
- **Living creatures only.** "A rogue can sneak attack only living creatures with
  discernible anatomies - undead, constructs, oozes, plants, and incorporeal
  creatures lack vital areas to attack."
- **Critical-hit link.** "Any creature that is immune to critical hits is not
  vulnerable to sneak attacks." The project encodes the two immunities as separate
  tag checks rather than deriving one from the other: `crit_immune` in
  `src/core/rules.gd:789-791` and the sneak gate above. That is faithful for
  undead and constructs, and it is the one place this note records as a **latent
  mismatch, not a defect**: a future crit-immune creature without either tag
  would keep its sneak vulnerability.
- **Not multiplied.** "Should the rogue score a critical hit with a sneak attack,
  this extra damage is not multiplied" - already true (`rules.gd:832-858`).
- **Flanking.** PHB p. 153 grants the flanking bonus when the opponent is
  threatened by an ally on the opposite border or corner. The project's
  `_is_flanked` requires two threatening enemies of the target on opposite sides
  of it (`src/core/encounter.gd:3171-3193`, with threat at `:753-756`), and it
  uses that only as a **sneak-attack gate**: no +2 flanking attack bonus exists
  anywhere (no match for "flank" in `rules.gd`). The note treats that as an
  existing adaptation, not something this batch fixes.
- **Out of scope here.** The 30-foot ranged limit and the concealment clause are
  printed limits this content cannot exercise (no concealment tag, and the
  opponent is met in melee).

## 3. Seams inspected

### 3.1 Monster schema - expressible with existing fields, no schema change

`content/shared/monsters.json` already carries everything a stat block needs:
`abilities`, `base_attack`, `base_saves`, `max_hp`/`hp`, `hit_dice`, `level`,
`size_category`/`size_ac`, `natural_armor`, `ac_misc`, `attacks`, `equipment`,
`inventory`, `spells`, `feats`, `skill_ranks`, `tags`, `immunities`,
`monster_type`, `challenge_rating`, `xp`, `destroyed_at_zero`, and monster-only
`damage_reduction`/`single_actions_only` (the zombie uses the last two).

`ContentDB._validate_actor` (`src/core/content_db.gd:800-849`) validates every
actor, monster included: abilities present, positive `max_hp`, size category
against `size_ac`, **equipment slots against `Character.SLOTS` and item ids**
(`:817-825`), inventory ids, prepared/known spells, and feats through
`Character.from_content` + `Feats.validate_for_character` (`:848`). Monsters must
also have at least one attack entry (`:609-611`). A living, humanoid, armored
opponent with a weapon-shaped attack therefore validates **without a schema or
validator change**.

Two consequences worth stating before the batch:

- The weapon has to be authored as an **`attacks` entry**, because the monster
  turn path reads `ch.attacks` and falls back to a hardcoded slam, never to
  `equipment.weapon` (below). Authoring both would create two sources of truth
  that no validator compares.
- If the stat block carries `Toughness`, `hp_includes_feats` must be set or the
  constructor adds +3 HP again (`src/core/character.gd:751-768`). The sketch below
  authors no feats, so this does not arise.

### 3.2 Monster turn path - an armed attack needs no AI change

`_run_monster_turn` (`src/core/encounter.gd:4226-4291`) picks the nearest living
party member, attacks if adjacent (`_monster_single_attack` for
`single_actions_only`, else `_monster_full_attack`), otherwise walks and makes one
attack after closing. Both attack helpers read `ch.attacks` and fall back to
`_primary_weapon` only when the array is empty
(`src/core/encounter.gd:4488-4528`). `_primary_weapon` returns `attacks[0]` for a
monster, or a hardcoded slam, **ignoring `equipment` entirely** (`:678-692`).

So a longsword-shaped attack entry works through the existing AI with no change,
and the AI still never initiates a grapple or uses special attacks
(`src/core/encounter.gd:4231-4237`). That is a dependency only if a later batch
wants the opponent to *use an equipped weapon item* (disarm, sunder, loot):
`_primary_weapon` and the attack helpers would then have to consult equipment.

### 3.3 Sneak-attack eligibility, flanking and map geometry

- Gate: `src/core/encounter.gd:3004-3013` (attacker dice, condition, not
  undead/construct tag).
- Flanking set: `_is_flanked` (`:3171-3193`) needs two able enemies of the target
  whose cells threaten it and that sit on opposite sides of its x or y axis;
  threat is reach detection (`_threatens_cell`, `:753-756`, default `reach_ft` 5,
  `character.gd:62`).
- Map: `storeroom_dead` rows are a 9x7 room with pillar pairs
  (`content/campaigns/ravenloft_demo/encounters.json:2-60`), so two party members
  can stand on opposite sides of a Medium target in several rows. Flat-footedness
  at combat start already supplies a second, geometry-free route: every combatant
  starts flat-footed until its first turn, and the sneak gate accepts
  `target_flat_footed`. Sera can therefore sneak-attack the living opponent in
  round 1 without flanking, and flank later.
- Note that the sidebar's enemy rows and the grid cursor already treat enemies
  uniformly, so a living opponent needs no UI change.

### 3.4 Validators

- `GameSession.validate_campaign` (`src/game_state.gd:427-440`) loads
  `ContentDB` and returns its errors; `--validate-campaigns` prints them.
- Monster and encounter checks: `ContentDB._validate_actor` (`:800-849`), the
  attack-required rule (`:609-611`), encounter rows, monster ids, party cells and
  monster cells (`:612-626`), and triggers naming encounters (`:656-659`).
- **No check compares `monsters.size()` with `monster_cells.size()`.**
  `Encounter.setup` silently places a cell-less monster at `(1, 0)`
  (`src/core/encounter.gd:113-118`), which can stack two combatants. That is a
  validator gap worth recording; adding the error is a small **code** change and
  is not part of the content-only batch below (the batch pins parity in its test
  instead).
- `--validate-diagnostics` is informational for awards and does not change on
  this batch (`src/core/content_diagnostics.gd:70-90`).

### 3.5 XP and the award ledger

- Awards are **per encounter**, authored as `xp` in `encounters.json`, and paid to
  every party member (`src/game_state.gd:1689`, `:1732-1738`). A monster's own
  `xp` field is never read as an award; it is only loaded into a `Character`
  (`character.gd:715`) and goes nowhere for enemies.
- `ContentDiagnostics.advancement_line` sums encounter `xp` and `xp` effects
  (`content_db.gd:951`, `content_diagnostics.gd:70-90`). The recorded line is
  `ravenloft_demo authored=4500 ordinary=4350 qa=150 encounters=1500 effects=3000
  start=3000 threshold=6000` (`TEST_REPORT.md:5522`).
- The bell milestone is two effects, `xp 500` and `xp 2300`
  (`content/campaigns/ravenloft_demo/dungeon.json:88-91`). `DEMO_ADVANCEMENT_PLAN.md`
  §2 and §7 size the 2,300 against a completing player's floor of 700 so the floor
  lands on exactly 6,000; the named combat route lands on 6,550.
- Therefore **swapping a monster inside an existing encounter changes no award,
  no threshold and no diagnostics figure.** Adding a *new* encounter would change
  `encounters=` and `authored=`, and changing an encounter's `xp` would change
  both - both are explicit, out-of-scope decisions.

### 3.6 Encounter, map and trigger

`storeroom_dead` is self-contained: its `rows` are the battle map, with
`party_cells` and `monster_cells` (`encounters.json:2-60`). It is started by the
`storeroom_ambush` trigger at `(7, 7)` of `old_gatehouse`, gated on
`requires_flag_not: storeroom_cleared` (`dungeon.json:169-179`). No trigger, area,
door or quest change is needed to alter the encounter's monster list.

`tests/test_exploration.gd:99-106` asserts that entering that cell starts
`storeroom_dead` with exactly **2 enemies**; a swap preserves that, an addition
would have to update it. The campaign creator caps monsters by the layout's cells,
not by the shared list (`tests/test_campaign_creator.gd:999-1003`), so a new
shared monster does not disturb it.

`builds/qa/rev_before/` contains an old snapshot of the same content. It is a QA
artifact and must not be edited or read as current content.

### 3.7 What the engine already does for a living creature

- Nonlethal damage is tracked; undead and constructs are immune by tag
  (`rules.gd:203-212`), so a living opponent takes the grapple hold's nonlethal
  damage and can be knocked unconscious.
- A nonlethal knockout counts as defeat for victory (`_enemy_defeated`,
  `encounter.gd:4585-4587`), and the end-of-fight check treats it as a removed
  combatant (`:4559-4565`).
- Critical hits apply to living targets and are refused to undead/constructs
  (`rules.gd:789-791`).

## 4. Decisions

**D1 - host encounter: `storeroom_dead` (The Flooded Stores).** It is the first
ordinary fight, reached at `(7, 7)` behind an unlocked door, worth 300 XP, and its
room has room for flanking. `crypt_warden` already carries the ghoul's paralysis
and is the wrong place to add a second threat at 3rd level; the town-square fight
is the post-4th-level finale.

**D2 - add or swap: swap the second zombie.** Replace `monsters[1]` (`zombie`) with
the new living opponent and keep both `monster_cells` entries. That keeps the
combatant count, the enemy-row count, the existing two-enemy test assertion and
the encounter's shape. **Recorded alternative, not chosen:** adding a third
combatant at the same 300 XP raises difficulty without raising reward and would
require updating `tests/test_exploration.gd:106`; that is a deliberate difficulty
decision, not an implied one.

**D3 - XP stays unchanged: 300, no threshold or ledger movement.** Because awards
are per encounter, `encounters=1500`, `effects=3000`, `authored=4500`,
`ordinary=4350`, the 6,000 threshold and the 2,300 bell milestone are all
untouched. No new encounter, no `xp` edit, no QA encounter involvement. If a later
decision wants the opponent rewarded separately, that is a ledger change and
belongs in its own note with the route arithmetic re-derived.

**D4 - challenge rating and effect on a 3rd-level party.** A human warrior 1
(CR 1/2), about 8 hp, AC 15 (chain shirt, Dex 12), longsword +2 for 1d8+1, no
damage reduction, no immunities, one action per round. Against the zombie it
replaces (16 hp, DR 5/slashing, one action), it dies faster and hits comparably,
so the encounter stays in the same band for the 28/17/21/13/13 hp party. The two
real changes are qualitative: Sera's sneak attack is 3d6+1 - short sword 1d6+1 plus
2d6, range 4-19, average 11.5 - so it usually but not always drops the looter in one
hit, and the looter can be knocked out nonlethally. (An earlier draft of this note said
"about 13"; that figure was never derived from the authored attack and is corrected
here.)
**Recorded alternative:** CR 1 with about 12 hp if the author wants it to survive
one sneak attack and act; that is a difficulty decision to take explicitly.

**D5 - loot and equipment: armor only; no weapon item, no loot.** Authoring a real
armor item gives honest AC provenance. The weapon is the `attacks` entry, and
`equipment.weapon` is deliberately **not** authored, because the monster turn path
ignores it (`encounter.gd:678-692`) and two sources would drift. Nothing drops on
death and `inventory` stays empty, matching the existing monsters. **What follows
for disarm and sunder: nothing becomes reachable.** Disarm is not implemented
(`encounter.gd:14` lists it as deferred), and without an equipped weapon item there
is no object to disarm. This opponent is the missing *target* for a later batch,
not the missing rule.

**D6 - actions that become meaningful (consequences, not reasons for the work).**
1. **Sneak attack** becomes reachable in ordinary play - the whole point, and the
   only capability change.
2. **Grapple hold damage** becomes effective on a living target and can knock it
   out; victory then counts the knockout (`encounter.gd:4585-4587`). Recorded as a
   side effect. The existing grapple evidence gap (seeded probes only) is **not** a
   reason for this work and is not closed by it.
3. **Critical hits** on a living, non-immune target are already supported and now
   occur in content; sneak damage stays unmultiplied.
4. **Disarm/sunder** do not become reachable (D5).

**D7 - AI: no change.** The attack entry flows through `_monster_single_attack` /
`_monster_full_attack` unchanged; the AI still closes and attacks the nearest
living party member and never grapples or uses special attacks. If a later batch
wants equipment-driven attacks (for disarm or loot), the dependency is
`_primary_weapon` plus the attack helpers (`encounter.gd:678-692`,
`:4488-4528`), and it is reported here as a dependency rather than folded in.

## 5. The smallest content-only batch

A content-only batch exists. It is **batch A**, and it is the recommendation.

### 5.1 Content changes

1. `content/shared/monsters.json`: add one entry, `store_looter` -
   `is_monster: true`, `monster_type: "Humanoid (human)"`, `race: "Human"`,
   `class: "Warrior"`, `level: 1`, `hit_dice: 1`, `challenge_rating: "1/2"`,
   `xp: 150` (decorative; not an award), `tags: ["human"]`, `immunities: []`,
   `destroyed_at_zero: false`, `turn_resistance: 0`,
   abilities Str 13 / Dex 12 / Con 12 / Int 10 / Wis 10 / Cha 8,
   `base_attack: 1`, `base_saves` Fort 2 / Ref 1 / Will 0, `max_hp: 8`, `hp: 8`,
   `speed_ft: 30`, `size_category: "medium"`, `size_ac: 0`, `natural_armor: 0`,
   `ac_misc: 0`, `equipment: {"armor": "chain_shirt"}`, `inventory: []`,
   `spells: {}`, `feats: []`, `skill_ranks: {}`, `portrait_hint: "human"`,
   and one attack:
   `{"name": "longsword", "damage": "1d8", "damage_bonus": 1, "crit_range": 19,
   "crit_mult": 2, "damage_type": "slashing"}`.
   The final attack bonus is whatever the existing stat-block path derives; the
   test pins it rather than assuming a formula.
2. `content/campaigns/ravenloft_demo/encounters.json`: in `storeroom_dead`,
   `monsters` becomes `["zombie", "store_looter"]`; `monster_cells`, `party_cells`,
   `rows` and `xp: 300` are unchanged. Adjust `intro` and the victory narration so
   the prose describes one drowned shape and one living scavenger instead of two
   drowned shapes.
3. No other content file changes. `dungeon.json` already triggers the encounter.

### 5.2 Failing-first tests

New `tests/test_reachable_opposition.gd`, written and run **before** the content
edit, so it fails for the missing content rather than for a parse error:

- **T1 content**: `store_looter` loads; `tags` has neither `undead` nor
  `construct`; `Rules.nonlethal_immune` is false; `attacks` is non-empty; the
  armor id resolves in `items`; `destroyed_at_zero` is false.
- **T2 encounter parity** (the gap in 3.4, pinned in a test because the validator
  does not check it): `monsters.size() == monster_cells.size()`; every cell is
  walkable on the encounter map; exactly one monster is not undead-tagged;
  `xp == 300`; the `storeroom_ambush` trigger still names `storeroom_dead`.
- **T3 behaviour through the real content**: `Game.start_encounter("storeroom_dead")`
  with the campaign's default party (which includes Sera); find the living enemy;
  on round 1 it is flat-footed, so a Sera attack must report the sneak extra and
  deal more than the weapon's own maximum; the same attack against the zombie must
  report no sneak extra and the zombie must stay crit-immune. The RNG is seeded;
  the encounter, monster and party are authored content, not a fixture.
- **T4 consequence**: the living enemy is not nonlethal-immune, so a nonlethal
  total above its HP leaves it `nonlethal_unconscious`, which `_enemy_defeated`
  counts. One assertion, not a new subsystem test.

There is **no failing-first validator test**, because batch A adds no validator
rule. A validator parity error for `monsters`/`monster_cells` would be a code
change and is listed as a separate optional batch (B) below.

### 5.3 Checks and acceptance for batch A

- The focused test above, red before the content edit and green after.
- Full suite, both validators (`--validate-campaigns`, `--validate-diagnostics`,
  expecting PASS and the unchanged `ADVANCEMENT AWARDS` lines), all five probes
  and `--combat-info-probe`, and combat layout at 1280x720 at 100 % and 160 %
  (32 controls expected, unchanged).
- Source checks first; then commit the content and tests (including any generated
  `.uid`), export a uniquely named candidate, write `BUILD.txt` with the source
  commit, worktree difference, byte size and full SHA-256, and re-run the
  validators, probes and layout **from the executable**, verifying its hash before
  and after.
- Documentation: `SUPPORTED_FEATURES.md` playable-content line,
  `PROJECT_OVERVIEW.md`'s encounter table (currently "2 zombies at (6,1), (7,1)"),
  `TEST_REPORT.md`, `ROADMAP.md` and `PROGRAM_PROGRESS.md`.
- Claims stay bounded: automated input and rules-state evidence, no rendered
  review, no human playthrough, no screen-reader check.

### 5.4 Ordinary play, fixtures and hooks, kept apart

- **Legally reachable play:** the `storeroom_dead` encounter through its trigger,
  with Sera in the party (party selection is 3-4 of 5, so she is optional). Sneak
  attack then occurs through the ordinary attack action.
- **Seeded fixtures:** the RNG seed and the forced cell placement in T3/T4. No
  fixture grants a feat, item or XP.
- **Not reachability:** the new monster's `xp` field (unused for awards), future
  disarm/sunder, and any equipment-driven attack behaviour.

## 6. If equipment-driven attacks are wanted (split, not one batch)

If the author decides the opponent must carry a **weapon item** (so that a later
disarm has an object), the work separates:

- **Batch A (content only, recommended first):** this note's swap and tests.
- **Batch B (engine, optional):** make monster attacks consult
  `equipment.weapon` in `_primary_weapon`/the attack helpers
  (`encounter.gd:678-692`, `:4488-4528`) and author the item on the monster; add a
  validator rule that the attack entry and the equipped weapon agree. Independently
  acceptable; no rule change to disarm is implied.
- **Batch C (rules, later):** the disarm action itself, its check, the AI's
  response and the pending-decision shape. This is a rules batch with its own
  plan, not a consequence of adding a target.

Recommendation: **do batch A only.** B and C are recorded so that a later decision
does not silently expand A.

## 7. Classification, kept separate

- **Confirmed defects.** None. This note found no failing case. The duplicate
  crit/sneak tag gates (3.3) and the missing `monsters`/`monster_cells` parity
  check (3.4) are recorded as latent mismatches and validation gaps, not defects.
- **Deferred features.** Disarm, sunder and equipment-driven monster attacks
  (batches B/C above); overrun stays deferred under `docs/OVERRUN_PLAN.md` §18;
  readied and delayed actions; grapple 8b-2/8c/8d/8f; concealment, terrain hard
  cover, AoE templates, encumbrance, disease; full attacks and two-weapon fighting;
  levels 5 and above; a save shortcut; party item handoff.
- **Maintenance debt.** Unchanged: the stale `Combat Casting` benefit text, the
  singular `modal` field, the probe-heavy `main.gd`, shallow UI suite coverage,
  source-text guards that cannot see a string-built call, the empty save-migration
  table and the placeholder renderer. The stale `builds/qa/rev_before/` content
  snapshot is a QA artifact, not content.
- **Evidence gaps.** No rendered review or human playthrough; the rogue's sneak
  attack has rules coverage but no ordinary-play instance until this batch lands;
  grapple evidence remains seeded-probe only; the two validation gaps above are
  read from code, not from a failing validator run.
- **Carried forward unchanged.** Turn Undead (no product defect found), helpless
  attacks of opportunity, the paralyzed-ally firing penalty and the ranged probe
  stay closed as recorded. The keyboard targeting and both combat-information
  batches stay closed on `da95ed4`/`fbbbbeb` with their acceptance limits. The
  opposed-check helper is unchanged.

## 8. What this note did not do

No executable, test, probe, content, schema or save file was changed; no content,
schematic or validator edit was made. No test, probe, validator, build or export
was run. The checks performed were documentation-integrity ones: git status and
hashes, file reads, greps for cited lines, JSON reads of the authored content, and
one SRD lookup for the printed rule text. Those are not game checks.

## 9. Implementation record (batch A, 2026-11-24)

**Content.** `content/shared/monsters.json` gains one `store_looter` entry (+66 lines):
Warrior 1, CR 1/2, 8 hp, AC 15 from a chain shirt and Dex 12, Str 13 for 1d8+1 with a
longsword at +2, proficiencies simple/martial/light armor, `tags: ["human"]`, no
immunities, `destroyed_at_zero: false`, and `equipment` holding only the armor. The
weapon is the single `attacks` entry, as §3.1 and §3.2 require, and no item or loot is
authored. `content/campaigns/ravenloft_demo/encounters.json` swaps `monsters[1]` to
`store_looter` and rewrites the intro and victory narration so the room explains a
living scavenger: he came down to rob the dead. `monster_cells`, `party_cells`, `rows`
and `xp: 300` are untouched.

**Tests, written and run first.** `tests/test_reachable_opposition.gd` covers the stat
block's shape, `monsters`/`monster_cells` parity and the trigger, sneak damage on the
living flat-footed looter, sneak refusal on the flat-footed zombie, the nonlethal
knockout and its victory, and the unchanged encounter XP and award inventory.
`builds/qa/reachable_opposition_red/` holds the red run: 2/6 tests, 37/42 asserts, the
four content-dependent tests failing on the missing monster, the swapped roster and the
absent living enemy. An earlier attempt that failed to parse was discarded and is not
part of that evidence. The green run is 6/6, 82 asserts, exit 0. The full suite is
**1017/1017 tests, 10,142 asserts, 78 scripts, exit 0**, against 1011/10,057/77 before.

**Validators.** `--validate-campaigns` PASS; `--validate-diagnostics` PASS with the same
eight accepted authored class-progression inconsistencies, and the recorded inventory is
unchanged: `authored=4500 ordinary=4350 qa=150 encounters=1500 effects=3000 start=3000
threshold=6000`.

**Probes and layout, from source.** `--keyboard-probe` 31, `--grapple-probe` 160,
`--level-up-probe` 349 at 1.00 and 1.60, `--advancement-probe` 228, `--combat-info-probe`
62 checks, all PASS; combat layout 32 controls and 0 failures at 1280x720 at 100 % and
160 %.

**Candidate.** `2026-11-24_living_opponent_batch_a`, source
`7547797f85271cdcb5aa4bac72964a6da7ec5695`, 110,905,384 bytes, SHA-256
`8a7925de98d805f5862bc78859987624581ed3a3eb1480adfd8d5f28ee092a8c`, equal to `BUILD.txt`;
`worktree_entries=1` (README only), worktree diff SHA-256
`0e8ff3e146d889b0e942158f588ca92122c4eec62eaaa1bde349a91dc9d95e1c`,
`untracked_files=0`. From that executable: both validators PASS, keyboard 31, grapple
160, level-up 349, advancement 228 and combat-info 62 checks PASS, layout 32/0 at both
scales, and the executable's hash was identical before and after.

**Not done, and not claimed.** No ordinary-play playthrough, no balance testing, no
rendered review of the room or the new narration, and no human playtest. The evidence is
automated content and rules behaviour plus the probes listed above.

**Closure.** Batch A is closed on that evidence. The closure itself ran nothing: no test,
probe, validator, build or export was repeated, and the candidate was neither rebuilt nor
re-hashed. Its records use one identifier set throughout (`storeroom_dead`,
`storeroom_ambush`, `storeroom_cleared`, `store_looter`), checked across the repository.
