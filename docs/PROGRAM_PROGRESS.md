# Feats and Skills Program — Progress

Updated: 2026-11-14

## Ashwick Ferry: The Second Ring (2026-11-14)

Bounded campaign-content expansion in `RL_Edit`, with no shared runtime, UI,
rules or other-campaign change. `campaign.json` is now version 2; the save
format is unchanged and there is no migration. Existing v1 Ashwick saves are
refused with their bytes preserved (focused test).

The boathouse ledger now establishes that the noon crossing was struck through
and that Ivo took an unlawful fare after the bell. The optional strongbox,
reachable only through the existing Open Lock check, adds the toll receipt, the
instruction to ring twice, and Ivo's motive: Maela's draught and a debt he
tried to finish with one more fare. The page deepens the account but does not
make the ledger-only truth retrospective.

The account choice is a mutually exclusive, persistent commitment. Truth starts
only "What Ivo Owed" and tells Maela that Ivo broke the crossing law; she gives
the landing to the village, leaves the bell to the water, and keeps no lie.
Mercy starts only "The Passenger's Story", preserves the landing and the ferry,
and leaves the player carrying the truth. If the page is found after either
commitment, Maela can be shown it (truth) or it can stay folded (mercy); neither
reverses the commitment.

The bell is an NPC with three exclusive answers. Ring once consumes the token in
the socket and leaves one clean note. Ring twice starts `ashwick_bell_answer`;
the token is removed only in the encounter's victory effects, so defeat or
interruption leaves it available and the ending incomplete. Breaking the token
leaves the bell silent. Each successful resolution sets `bell_resolved` and its
outcome flag; repeat interaction cannot start another encounter or ending.

Maela's outcome-specific epilogue is the final main objective (`hear_epilogue`,
flag `maela_epilogue`), so combat victory and the neutral bell message do not
complete the campaign. The epilogue reflects account, bell outcome and optional
page, and after its once-only delivery Maela keeps a repeatable post-ending
conversation. The neutral victory text still directs the player back to her.

Verification: full suite **517/517 tests, 5,963 assertions, 42 scripts, exit 0**.
New `tests/test_ashwick_second_ring.gd` **11/11, 389 assertions** covers both
accounts, all three bell outcomes, optional page present/absent/after
commitment, exclusive and repeat attempts, ring-twice defeat and retry, save/load
after each ending, an ordinary entry-to-epilogue path and v1 refusal with byte
preservation. The adapted Ashwick suite is **7/7, 318 assertions** and the
Journal suite **6/6, 90 assertions**. Both validators pass with no content
problems.

Candidate `builds/qa/candidates/ashwick_second_ring_2026-11-14/RavenloftFoundationEdit.exe`,
110,611,128 bytes, SHA-256
`457e3b887e9105a565a7da25d6a82374e0fe7c9dbd045a87d91cff75034c3253`, is additive;
the foundation candidate is untouched. Its pack was audited at 146 paths with no
test, doc, tool, build, profile or other QA artifact. One ordinary exported-UI
route (OS mouse input, isolated `APPDATA`) reached the truth/single-ring
epilogue; the objective read **Complete** only after that conversation. The other
narrative combinations are automated, not native or human, checks. No human
playtest or balance judgment was made.

### Milestone closure — record and scope reconciliation (post-checkpoint)

The expansion is accepted functionally on the reported evidence. This closure
is documentation only: the executable was not rebuilt, the checks were not
rerun for these edits, and the sealed checkpoint was not regenerated,
replaced or modified.

- **Candidate:**
  `builds/qa/candidates/ashwick_second_ring_2026-11-14/RavenloftFoundationEdit.exe`,
  110,611,128 bytes, SHA-256
  `457e3b887e9105a565a7da25d6a82374e0fe7c9dbd045a87d91cff75034c3253`. Additive;
  the foundation candidate is untouched and it was never published.
- **Sealed checkpoint:** `builds/qa/snapshots/2026-11-14_ashwick_second_ring/` —
  `RL_Edit_source.tar.gz` (3,944,688 bytes, 521 entries, SHA-256
  `0ee9fc2e742510f5399073c9f70b622a1bf81d040bdf802b5209516eeda1f716`),
  `MANIFEST.sha256` over 490 files (file SHA-256
  `ec657214eee59eb814e1ad1e8d5b39f432585d5b8dd4a30dd94bc3b8d0190ad4`, as recorded
  in `CHECKPOINT.md`) and `CHECKPOINT.md` (file SHA-256
  `6103368f70bf32724ab65eb9a0df132cd81cb9b0f084ada51baf68768d7e5685`). The
  manifest verified clean against the working tree before this documentation
  change.
- **Post-checkpoint documentation:** `README.md`'s Tests paragraph was corrected
  to mark the 339/339 figures as historical v1 evidence, state the accepted
  Second Ring counts, link the authoritative records, and remove any implication
  of human or balance validation. This section, `CONTINUATION_BRIEF.md` §0 and
  `TEST_REPORT.md` carry the closure note; `ROADMAP.md` carries the later
  adventure assessment. The working tree therefore differs from the sealed
  snapshot only by post-checkpoint documentation; no new checkpoint was
  created.
- **QA-helper scope exception:** `tools/qa/creator_input.ps1` differs from the
  previous milestone by exactly two lines — it adds
  `[W]::SetForegroundWindow($p.MainWindowHandle)` before capture and shortens
  the pre-capture wait from 900 to 300 ms. Working-tree SHA-256
  `c02b138c675435aa81822d8c7e3f053e373a438ee271b6500ca8f95b6dd13f70` equals the
  sealed manifest entry, and the recorded native route postdates the change and
  used it (helper 21:18, captures 21:33, checkpoint 21:34). Recorded as an
  explicit scope exception for this milestone only; it does not authorize
  further tooling changes.
- **Coverage limits:** one ordinary exported-window route (truth account, ring
  once) reached the specific epilogue. Mercy, ring-twice, silence,
  defeat/interruption, optional-page combinations, post-ending repeats,
  save/load after each ending and v1 refusal remain automated evidence; save
  refusal during combat and the pre-bell save boundary are the supported retry
  path. No human playtest and no balance validation.
- **Deletion disclosure:** the only deletion was the disposable
  isolated-profile test residue folder
  `%APPDATA%\RavenloftFoundationEdit\campaigns\.draft_test_creator_alpha`,
  left by an interrupted creator test in the test harness's own `user://`
  profile. No campaign content, candidate, checkpoint, private reference,
  player save or unrelated project file was deleted.
- **Status:** milestone closed. No further content, rules, UI, tooling or
  verification sweep is authorized without new direction.

### Adventure assessment (post-checkpoint, assessment only)

The Second Ring was assessed as an adventure without changing content, runtime,
rules, UI or tooling; the implementation milestone stays closed. The route,
investigation, account options, bell warnings, epilogues and return journeys are
working; see `ROADMAP.md` for the full assessment. One material issue: the
mandatory drowned-ferrymen encounter is a composition trap for the advertised
1–4 party sizes. The token exists only in its victory effects, and Sera's
piercing short sword does at most 2 damage per hit after DR 5/slashing. A
bounded real-encounter check (seed 11, attack-only tactic) ended in solo Sera
defeat at round 14 and solo Aldric defeat at round 14, while the default four
won at round 38. Recommended next correction: enforce the authored `party.min`
(it is currently validated but ignored) and set Ashwick's min to 3. Evidence
and limits: `builds/qa/runs/2026-11-14_ashwick_assessment/`.

## Combat-start flat-footedness (2026-11-13)

Applied PHB pp. 133-136 instead of keeping it as a documented omission: every
combatant is flat-footed until the start of their first turn, denying a
**positive** Dexterity bonus and any dodge bonus to normal and touch AC, and its
attacks of opportunity; a Dexterity penalty still applies, and a rogue can sneak
attack such a target. The first version of this milestone removed the raw
Dexterity modifier (raising AC for a penalty) and kept dodge bonuses; both were
wrong against p. 136 and were corrected before the next candidate. `Encounter.flat_footed` is seeded in
`begin()`, cleared in `_begin_turn`, and passed to every attack path (party
attacks, opportunity attacks, monster attacks, ranged touch spells, trip touch
attacks). Round 1 logs the state and the enemy inspect panel shows the effective
AC. Runtime change only: no save-schema, content-format or campaign-format
change, and encounter state remains deliberately unsaved.

Verification at the time of that correction: full suite **366/366 tests, 4,753
assertions, 25 scripts, exit 0** (378/378 after the ranged milestone below);
`tests/test_flat_footed.gd` **14 tests, 51 assertions**. Six existing tests were
updated when the state was introduced, and two more (`test_combat.gd`,
`test_rules.gd`) when the dodge denial was corrected, because they had asserted
the earlier wrong behaviour. A windowed probe (`--demo-inspect --inspect-probe`)
opened the real enemy panel in round 1 (`AC 12 (flat-footed)`, positive Dexterity
and Dodge denied), for a zombie with -1 Dexterity (`AC 11 (flat-footed)`, AC
unchanged), at 1.6 text size set through the Settings slider, and again after
the defenders acted (`AC 16`, no marker); the same window's attack line read
`vs AC 12`. Captures under `builds/qa/runs/2026-11-13_151001_inspect_panel/`.
No supported creature has uncanny dodge or Combat Reflexes, which is recorded
in `docs/SUPPORTED_FEATURES.md`; neither is implemented.

Candidate `builds/qa/candidates/flat_footed_corrected_2026-11-13/RavenloftFoundationEdit.exe`,
110,490,504 bytes, SHA-256
`51b00508cdb8167a94918818281074f11f484388982bae29b78ff32c2b256a42`; its own
campaign validation passed, and the `inspect`, `cleave` and `trip/prone` probes
passed in that exact executable. The earlier `flat_footed_2026-11-13` candidate
contains the wrong AC handling, is preserved unchanged and is marked
`SUPERSEDED.txt`. The export preset now excludes `builds/*`: the first build of
the corrected candidate packed this milestone's QA PNGs and was replaced before
acceptance. No human playtest, balance retune or full scenario replay was made.
See `docs/TEST_REPORT.md`.

## Ranged attacks into melee and while threatened (2026-11-13)

Implemented the two printed ranged rules separately, because they answer
different questions: PHB p. 140's -4 for shooting or throwing at a target engaged
in melee with a friendly character, and PHB p. 135's opportunity attack for
making a ranged attack while threatened. `Encounter._into_melee_penalty` owns the
first (engagement by the printed definition, the 10-ft escape to the nearest
friendly character, helpless targets as not engaged, and the Precise Shot
exemption); `Rules.attack` carries the result as `into_melee_penalty` so the
penalty is part of the auditable roll and the formatted line. The provocation
keeps its own message and is never used as a proxy for the penalty or the other
way round.

Precise Shot entered `Feats.CATALOG` with the printed Point Blank Shot
prerequisite and no passive modifier. Complete Arcane pp. 73 and 85 extend the
same rule to attack-roll spells, so Scorching Ray takes the penalty and Magic
Missile does not; one spell still provokes once, because casting and firing a ray
are one action.

Verification: full suite **378/378 tests, 4,794 assertions, 26 scripts, exit 0**;
`tests/test_ranged_melee.gd` **12 tests, 41 assertions**. Candidate
`builds/qa/candidates/ranged_melee_2026-11-13/RavenloftFoundationEdit.exe`,
110,492,248 bytes, SHA-256
`e4cde889f5fe812d4671031552f24da4653f115fb358f2467b8362e50dbe6995`; both validators
and the `inspect`, `cleave` and `trip/prone` probes passed in that exact
executable. That candidate was then superseded by `ranged_windowed_2026-11-13`
(SHA-256 `2aa5c030…`) because the regression probes do not exercise the ranged
rule: a dedicated windowed probe `--demo-ranged --ranged-probe` was added and
passed 49 checks in source and in the exact final candidate, covering the -4 on
an engaged target, its absence on an unengaged one, the Precise Shot exemption,
and the ray's penalty with no repeated reaction. The embedded package was
inspected with `tools/qa/pck_paths.py`: 144 packed paths — the required runtime scripts and `content/`/assets are
included; unintended development files, private references, QA profiles and
generated artifacts are excluded. No human
playtest, no cover or concealment model, and no per-round "actually being
attacked" tracking.

**Completed: Concentration for spellcasting (2026-11-13).** Damage taken while
casting now forces a Concentration check at DC 10 + damage + spell level, one
check per damaging interruption; a failed check loses the spell while still
spending the standard action, the slot and the prepared cast. The spell list
offers casting on the defensive as an explicit per-cast checkbox: no opportunity
attack, DC 15 + spell level, failure loses the spell. Verified by
`tests/test_concentration.gd` (12 tests / 57 assertions asserting roll inputs),
390/390 tests overall, both validators, and a windowed probe in the exact
candidate `builds/qa/candidates/concentration_2026-11-13/` (56 checks PASS,
SHA-256 `8ebb56f2...379331a`). No shipped caster has Concentration ranks, so they
keep their Constitution modifier and were not rebuilt (ADAPTATION_LOG 40).

**Completed: Combat Casting (2026-11-13).** Verified against printed p. 92 and
implemented for its defensive clause only: +4 untyped on Concentration checks made
to cast on the defensive, with the grappling/pinned clause documented as not
modeled. The circumstance travels in the skill-check options, so injury checks
get nothing; duplicate non-repeatable feat text no longer doubles a bonus.
`tests/test_combat_casting.gd` (6 tests), suite 396/396, both validators, and 79
concentration probe checks in candidate `combat_casting_2026-11-13`.

**Integration acceptance (2026-11-13).** The shipped town-square encounter was
played with the unmodified pregens and standard zombies: opening flat-footedness
(panel and log), a melee attack reporting the state it applied, a thrown attack
taking the printed -4 into a melee, and an ordinary cast provoking a reaction
that missed while the spell completed and spent one slot. 49 checks PASS in
candidate `integration_2026-11-13`. No rules defect surfaced; the encounter was
not finished and no difficulty judgment is offered.

**Completed: weapon handling, shields and the unarmed-threat correction
(2026-11-13).** Sheathing and drawing are separate actions (each able to spend the
standard action as a move), a crossbow is loaded before firing and spends the shot,
and a loaded crossbow stays loaded while stowed. Threat now separates three things:
the attack a combatant could attempt, the armed state that threatens squares, and
reaction eligibility. Ordinary empty hands therefore grant no threat, no flanking,
no engagement and no opportunity attack, while natural weapons and Improved Unarmed
Strike do (PHB pp. 137, 139). The shield control straps on a carried shield or
unstraps and drops it. `test_weapon_access.gd` (11), `test_melee_threat.gd` (15),
`test_shield_handling.gd` (9); suite 431/431; candidate `unarmed_threat_2026-11-13`
with 51 weapon, 27 shield, 49 integration, 79 concentration and 49 ranged probe
checks. ADAPTATION_LOG 42 (corrected), 43 (historical), 44, 45 (dated correction).

**Next selected milestone: ordinary unarmed attacks (PHB pp. 139).** The correction
makes the distinction explicit, but the attack itself is still semantically wrong:
an empty-handed attack resolves as ordinary lethal bludgeoning damage, provokes no
reaction from an armed defender, offers no lethal-at--4 option, and undead/construct
immunity to nonlethal damage is unmodelled. That is the next coherent unit.

## Campaign platform (current objective)

The project direction changed after the foundation pass: the product is now a
reusable **campaign platform**, and Ravenloft is one campaign built on it. The
feat/skill queue remains paused; its completed batches are evidence for the
extension contracts, not the completion measure.

## Journal overlay triage (2026-11-08)

The blank Journal reported in the exported Ashwick playthrough was a layout
defect, not missing quest data. The Journal's `RichTextLabel` had
`fit_content = true` but no horizontal expansion inside its `ScrollContainer`,
so it measured 1 px wide and 6,831 px tall and every entry rendered outside the
visible body. `Panels.journal()` now expands the label and disables horizontal
scrolling. Quest definitions, saves and campaign formats are unchanged; the
Journal remains the quest/world-event view it already was.

`tests/test_journal_panel.gd` (6 tests, 85 assertions) covers the empty log,
active Ashwick objectives, a loaded in-progress save, the completed quest after
reload, `hollow_lantern`, and 1.6 text scale at the modal's 720x420 content
size. Full suite **352/352 tests, 4,697 assertions, exit 0**; both validators
PASS. Candidate
`workspace/candidates/journal_fix_2026-11-08/RavenloftFoundation.exe`,
110,481,944 bytes, SHA-256
`78b8c2e9d5d0c6b99c5241d491f048f95dc79a165eee6f358261a143b65e4292`; the original
`ashwick_ferry_2026-11-08` candidate is untouched. The exported check at
1280x720 cleared the modal at 1.0 and 1.6 (1.6 set through the Settings slider);
captures are in `workspace/qa/journal_triage/fixed/`.

Two adjacent corrections came out of the triage. The candidate export now
excludes `workspace/*`, and package inspection of the new executable confirms
it: 121 paths, every campaign and shared file present, no `workspace/`,
`docs/`, `tests/`, `tools/`, PDF, reference, save or settings entry. The 29,864
byte reduction is **not** attributed to the exclusion alone — the runtime change
also affects compiled size — and two older Ashwick candidates that do package QA
probe scripts are marked `LOCAL_ONLY.txt` rather than deleted.
`tools/qa/build_candidate.sh` hashes untracked files null-delimited; a
disposable fixture showed the new pipeline survives a path with spaces and stays
identical across runs, while the previous line aborted the first export attempt.

In the candidate, a fresh profile played the Ashwick opening (spoke to Maela,
set 1.6 in Settings — `settings.cfg` records `text_scale=1.6`), and the Journal
showed the title, wrapped summary, one completed and four open objectives with a
scrollbar, both before and after an explicit UI save to slot1 and a relaunch
that continued it. The process was closed by PID because the intended Quit click
missed its enlarged-layout target; in-game Quit is therefore not verified, and
the miss is not read as an application defect. The save is preserved separately
with hashes. Limitations: the original
pre-bell save had already been overwritten, so that state is covered by a
save/load fixture rather than a new playthrough; earlier "1.6" captures have no
settings record behind them (the `--text-scale` argument does not affect
exported builds), so their scale is marked unverified while their
action/visibility/save-load results stand.

## Ashwick Ferry authoring note (2026-11-08)

`content/campaigns/ashwick_ferry/` is an original, non-canonical placeholder
scenario using only the existing runtime: two 9x9 areas, five flag-bound
objectives, Maela's one-attempt Sense Motive DC 15 success/failure branch, a
ledger clue, a locked tack-room door, two standard zombies, Ivo's token and the
bell conclusion. Success grants the tack-room key and a potion; failure withholds
both. The spare key and Sera's Open Lock are alternate door routes; the spare
now awards the same `ashwick_tack_room_key` with `only_if_missing`. Failed ledger
or spare-key Search checks return before removal, so they are retryable. The bell
requires `ivo_token` and `ledger_found` and cannot finish the quest early.

Authoring is file-only. `items.json` declares a campaign-local reward referenced
by an area interaction effect; the Creator loads the package but cannot represent
that local item, so `write_package` safely refuses and leaves every file
byte-identical. This is a documented Creator limitation, not a successful edit
path, and the package remains bundled/read-only. Focused regression is **7/7,
288 assertions**; the three-process ordinary-input route is **205 + 51 + 27
assertions**, all exit 0. The recorded run seed was 206352478; this is not a
seeded-balance claim. Both validation commands pass. No runtime or editor code
was changed.

### Exact-candidate ordinary-play acceptance (2026-11-08)

The shipped candidate is at the Ravenloft workspace root (outside this
project):
`workspace/candidates/ashwick_ferry_2026-11-08/RavenloftFoundation.exe`,
110,511,808 bytes, SHA-256
`8a3f067b142411039afef7324739126c664b8944baa0751d5e527053d31d4f5f`,
was hash-checked before launch and driven as an ordinary window. Isolation was
achieved by starting that process with `APPDATA` set to
`workspace/qa/native_profile`; no existing profile or save was used. The run
used visible mouse controls (movement, Interact, Take 10, Move, Attack, End turn,
Cast spell, Save/Load); it did not use `--script`, a backend probe, copied saves
or direct state writes. The shipped release ignores `--script`, and injected
keyboard events were not accepted, so no keyboard claim is made.

The actual run used seed **4104856171** and party **Brother Aldric, Kaelen Dorn,
Sera Vane and Ysolde**. Maela's Sense Motive succeeded with **d20(8) + 7 = 15
vs DC 15**, granting Tack-Room Key x1 and one potion. The
ledger Search succeeded with **d20(14) + 8 = 22 vs DC 10**. The key opened the
tack-room door. The encounter ran for four rounds: Ysolde's dagger was reduced
to 0 by DR 5/slashing, Kaelen's longsword and Ysolde's Scorching Ray dealt
damage, and Magic Missile destroyed the last zombie. Victory granted Ivo's Bell
Token x1 and 200 XP; Ysolde ended at 10/13 HP. Slot 1 was saved at the boathouse
after combat and before the bell, then the process was closed.

On relaunch, slot 1 loaded through the normal campaign Load slot UI into the
boathouse at (3,2). Inventory showed the key, token and two cure potions. The
tack-room door was open, the ledger was removed, the encounter trigger and
combat flags were spent, and all quest objectives except `ring_bell` were done.
Maela's changed branch offered `I found Ivo's token. We can ring the bell.` The
bell then completed the quest and raised the victory presentation once. After
Continue, save, quit and reload, the objective read **Complete**, no victory
modal appeared, the encounter did not restart and the repeat bell interaction
was ordinary inspection. The slot still held token x1 and all five objectives
true. The Journal overlay opened but rendered no entries at the boathouse after
the pre-bell load, with four objectives complete and `ring_bell` open; capture
`workspace/qa/native_50_journal.png`. It was not used as evidence, and this
observation remains unverified as a content defect rather than being claimed
fixed. The loaded save itself retained its objectives, and the later run
completed the quest.

Alternative-route coverage is focused backend/unit evidence, not a replay of
every branch in the window: `test_maela_success_and_failure_are_distinct_and_do_not_softlock`
covers success/failure and withheld rewards; `test_npc_key_open_lock_and_spare_key_each_open_the_door`
covers key, Open Lock and spare-key door routes; `test_failed_ledger_search_keeps_the_clue_available`
and `test_failed_spare_key_search_keeps_the_fallback_available` cover retry;
`test_actions_before_maela_count_and_full_route_persists` covers pre-Maela actions;
`test_bell_cannot_finish_before_token_and_ledger` covers the early-bell refusal.
The exact-window run independently exercised the Maela-success/key route. No
required alternative lacks coverage.

The candidate's `BUILD.txt` records HEAD
`fc951aca49877d6a4fa6999254831d7ebe6b9349`, worktree diff
`54a63fc4946f1883cfcfb4379e2b0c7c9dc2937cfd7dff2f1af45d98a2b39ec5`,
45 untracked files and untracked-source hash
`4532a913aa9c6ec78ceab4ccd03306a250eb3908cca1b1b119a594091e059b93`.
Those values describe the export-time identity. Runtime and campaign content
were not changed after export; only documentation and QA scripts/logs/images
changed, and the candidate does not include documentation or tests.

## Pending-form protection (2026-11-05)

The diagnostics boundary that allowed unapplied entity-form text to disappear is
closed. The creator compares supported forms with the applied draft and, before
an entity/area switch, validation-result jump, Save, Playtest or Back, offers
**Apply / Discard / Cancel**. Cancel keeps text, selection and focus; Discard is
explicit; Apply validates before changing the draft, and a failed Apply keeps the
text and does not navigate. The pinned header names pending forms. Save and
Playtest refuse until the choice is resolved. Existing selectors and validation
remain authoritative; no new editor section or gameplay system was added.

Guarded Apply is now all-or-nothing: a failure restores the complete live draft,
keeps every entered form value, restores dirty state and selection, keeps the
explanation, and writes no file. Reference selectors show an explicit
**Unresolved reference: <id>** entry instead of substituting the first valid
option; opening or unrelated Apply preserves it, intentional selection repairs
it, and invalid saves are refused without overwrite.

Verification: full suite **339/339 tests, 4,324 assertions**; focused creator
**33 tests, 609 assertions**; `--pending-edit-probe` **37 checks** in source and
the exported candidate; existing diagnostic probe **11/11**; campaign and
diagnostic validation PASS. Windowed 1280×720/1.6 external-input check showed
`Unresolved reference: missing_talk`, opened the guard prompt, and preserved it
through Apply. Candidate
`workspace/candidates/pending_atomic_2026-11-07/RavenloftFoundation.exe`,
110,463,552 bytes, SHA-256
`4d88215acd720de9e1278dd2908a7e9ec3e6202aafa27fab8914bc7f9eba11c1`.
Do not start another milestone without review. See `docs/TEST_REPORT.md`.

## Structured content diagnostics (2026-11-05)

Content errors now share a bounded structured contract across the creator,
command line and developer tools: stable code, severity, campaign/source,
entity type/id, field, area/node/choice context and related references. The
creator shows a pinned results panel; selecting a result opens the owning
section, selects the entity, scrolls the field into view and focuses it while
preserving dirty state. Deleted entities offer revalidation instead of selecting
a neighbour. Advanced/file-only content is labelled instead of pretending to be
editable. Malformed JSON has a dedicated fixture and is refused with its source
file, without overwrite or draft mutation. `--validate-diagnostics` emits JSON
and exits nonzero on errors; legacy text validation is unchanged.

Verification: **332/332 tests, 4,198 assertions, 22 scripts**; diagnostic probe
11/11 checks in source and the exported candidate; valid/broken CLI runs exit
0/1; native OS result click at 1280×720/1.6 reached **Set entry here**. Candidate
`workspace/candidates/content_diagnostics_2026-11-05/RavenloftFoundation.exe`,
SHA-256 `9acd6c35b119c8b872e0137b558cd60de67d2188c70779fc0c521fea6a7b027a`.
Do not start another milestone without review. See `docs/TEST_REPORT.md`.

## Earlier campaign-platform increment

Delivered and verified in this increment:

- Campaign package contract and registry (`docs/CAMPAIGN_PACKAGE.md`).
- Shared rules content (`content/shared/`) separated from campaign story content
  (`content/campaigns/<id>/`).
- Two packages through one pipeline: `ravenloft_demo` (existing content) and
  `hollow_lantern` (neutral example with two areas, a branching dialogue, a
  skill check, an encounter and a persistent quest consequence).
- Campaign selection/validate/continue/load UI, campaign-scoped saves with
  legacy read-only fallback and incompatible-version refusal.
- `--list-campaigns`, `--validate-campaigns`, `--campaign-probe=<id>`,
  `--creator-probe`, `--creator-ui-probe`, `--creator-interaction-probe`,
  `--campaign=<id>` and `--demo-creator`; probes and validation pass in source
  and in the exported candidate.
- Writable user campaigns under `user://campaigns/<id>/`, discovered by
directory scan without editing `Main.gd` or a compiled registry; bundled
campaigns stay read-only and duplicate ids are refused.
- Campaign Editor slices 1–2: create from the neutral template, edit
  title/description, add 9x9 areas, toggle walls/floors, set entry and facing,
  link areas, place a speaker NPC, and author a branching conversation with a
  skill check, flag condition/consequence and narration. The editor validates
  with named errors, saves atomically, playtests through the ordinary loader and
  returns with the draft intact; playtest saves are refused and never touch
  ordinary saves. Editing changes only the draft.
- Campaign-local instance policy: named NPCs, monster variants and unique items
  in campaign-root `characters.json` / `monsters.json` / `items.json` using
  supported schemas; shared ids cannot be replaced; local spells are refused.
- Dialogue editor is deliberately a node list with forms: node id/start,
  speaker name, text, `next`, choices, one skill check (skill/DC/actor and
  success/failure), require/show/set flag and narration. Node effects apply on
  entry; choice effects apply before the check. Renaming rewrites references;
  deleting a live node/dialogue is refused with exact references; loops are
  valid and unreachable nodes are reported separately.
- Visual check at 1280×720, 1.0 and 1.6 text scale fixed the interaction layout
  (stacked NPC/conversation editors and short picker labels) after the first
  captures showed squeezed columns. External OS-input pass saved the demo draft
  and added an area with visible “Unsaved changes”; the full authored lifecycle
  is asserted by `--creator-interaction-probe` (29 checks).
- Candidate `workspace/candidates/creator_slice2_2026-11-05/RavenloftFoundation.exe`,
  110,302,600 bytes, SHA-256
  `a01c364413d829cb312a8bbb538fcf7ca6cd31e6f64128beb001f256c14a7a9c`;
  the exact executable passes validation and all three creator probes. The
  accepted slice-1 candidate is untouched.

Next: creator slice 3 — quests and encounters. Do not start it without review.
See `docs/CONTINUATION_BRIEF.md` §9.

## Current state

- Batch 1 (shared skill resolution + passive, fully resolvable feats) is
  **implemented and verified**.
- Batch 2 (the fourteen no-prerequisite +2/+2 skill feats) is **implemented and
  verified**.
- Batch 3 (armor, shield, simple, martial and exotic proficiency plus the
  non-proficiency penalties) is **implemented and verified at the batch
  boundary**; Tower Shield remains deferred by its named dependency.
- Batch 4 (Extra Turning and Improved Turning) is **implemented and verified**
  against the existing turn-undead action and resource model.
- Batch 5 (Power Attack) is **implemented and verified for the supported single
  attack action**. The initial per-attack interpretation was corrected: the
  committed choice lasts until the character's next turn, applies to relevant
  opportunity attacks, and cannot be changed after the attack roll. Full attacks
  and one-handed weapons wielded in two hands remain unsupported.
- Batch 6 (Combat Expertise) is **implemented and verified for the supported
  single attack action**. The trade is chosen as a pending amount, commits only
  on a qualifying melee attack, and then lasts until the character's next turn.
  Ranged and thrown attacks discard it; fighting defensively and total defense
  remain unimplemented.
- Batch 7 (Trip/prone and Improved Trip) and batch 8 (Cleave) are **supported
  within the documented player-initiated scope**; see the dated sections below.
- Latest checkpoint run: **339/339 tests, 4,324 assertions, 22 scripts, exit 0**;
  focused creator **33/609**. The older 329/4,160 figures in historical sections
  remain historical. The checkpoint includes `<code>src/core/campaign_store.gd</code>`,
  campaign diagnostics and pending-form protection; `tests/test_campaign_creator.gd`
  covers the creator contract, persistence, lossless editing, write boundaries,
  quests/encounters, playtest isolation and the pinned creator action bar.
- The feat-completion queue is **paused**. The current objective is the shared
  foundation; see "Foundation reassessment" below.
- Source revision: checkpoint commit `fc951aca49877d6a4fa6999254831d7ebe6b9349`.
  At checkpoint validation the tree had only untracked `PROJECT_SYNTHESIS.md`;
  this assessment then edited `README.md`, `CONTINUATION_BRIEF.md` and this file
  (unstaged record corrections). `git diff --check` is clean.
- No push or deployment was made. The counts above are the closed checkpoint's
  full-suite evidence, not a run repeated for this readiness review. The 339/4,324
  figure predates the Ashwick suite; the content checkpoint ran only the focused
  Ashwick regression and validations.

## Batch 6 delivered

- `Feats.CATALOG` includes Combat Expertise (PHB p. 92), requiring Intelligence
  13. `Feats.combat_expertise_max` caps the trade at `min(5, base attack bonus)`,
  so a character with the feat but a low base attack cannot choose an illegal
  amount.
- The model separates three states: a pending UI amount in
  `Encounter.combat_expertise_pending` that grants nothing, a committed amount in
  `Encounter.combat_expertise_committed` stored as a temporary `combat_expertise`
  effect on the character, and the cap/prerequisite re-check that suspends the
  effect if either is lost. `set_active_combat_expertise` validates the feat and
  cap, and refuses changes once the amount is committed or the standard action is
  spent.
- `Rules.attack` applies the committed amount as a melee attack penalty, and the
  activating melee attack itself takes it. `Rules.armor_class` and
  `Rules.touch_ac` add it as a dodge bonus, omitted when the defender is
  flat-footed or helpless. Combat Expertise never adds damage.
- Activation is per attack action: the pending amount commits immediately before
  a qualifying melee attack resolves. A ranged or thrown attack discards the
  pending choice and never commits it. Committed amounts apply to later melee
  attacks and opportunity attacks, and expire at the start of that actor's next
  turn; another actor's turn does not erase them. `Encounter.finish()` removes
  the transient effect so combat state cannot leak into exploration or saves.
- Combat Expertise and Power Attack are separate per-actor states. Both penalties
  stack on the same melee attack, Power Attack still adds its damage, and Combat
  Expertise still adds its dodge AC.
- Tests cover the Intelligence prerequisite and its temporary loss, the +5/BAB
  cap, pending-versus-committed timing, a qualifying melee attack, ranged and
  thrown rejection, the attack penalty on the activating attack, normal and touch
  AC, flat-footed loss, stacking with Dodge, the opportunity attack (including a
  regression test that a pending choice never activates there), next-turn
  expiry, per-actor switching, combat-end cleanup, Power Attack combination, the
  actual incoming-attack AC calculation, and save round-trip. The UI test covers
  visibility, the pending/active labels and actor switching.
- The source-native QA window used `--demo-combat-expertise` with visible
  controls: a pending 2 with unchanged AC 17, a committed longsword attack at
  -2/-2 with AC 19, an incoming slam at "vs AC 19 — MISS", an opportunity attack
  keeping both penalties, and a round-2 reset to 0 for both controls. Evidence:
  `docs/screenshots/qa_ce_source_start.png`, `qa_ce_source_pending.png`,
  `qa_ce_source_committed.png`, `qa_ce_source_offturn.png` and
  `qa_ce_source_after_turn.png`. The QA fixture is a temporary Kaelen-derived
  fighter with Int 13, Combat Expertise and Power Attack; shipped pregens and
  content are unchanged.
- Fighting defensively (PHB p. 139), total defense (p. 141), full attacks and
  one-handed weapons wielded in two hands are not implemented, so their Combat
  Expertise interactions are deferred rather than invented. "Until your next
  action" is interpreted as until the start of the character's next turn because
  the engine has no immediate/swift-action subsystem and opportunity attacks are
  reactions.
- Exported candidate `../.ravenloft-candidate-featskills6/RavenloftFoundation.exe`
  (110,132,152 bytes, SHA-256
  `ee786089b2d3be679aaf2008b9f543423a040969f862cd09ce8678b0e4855bf`) was launched
  windowed with `-- --demo-combat-expertise` under an isolated `APPDATA` and the
  feature-specific sequence was repeated in that exact executable: pending 2 with
  AC 17, simultaneous Power Attack 2, a -2/-2 longsword attack for 6 damage with
  AC 19 and locked controls, an opportunity attack at -2/-2 for 11 damage, an
  incoming slam at "vs AC 19 — MISS", and a round-2 reset to 0 with both effects
  logged as ending. Evidence: `docs/screenshots/qa_ce_candidate6_start.png`,
  `qa_ce_candidate6_pending.png`, `qa_ce_candidate6_power_attack_pending.png`,
  `qa_ce_candidate6_committed.png`, `qa_ce_candidate6_offturn.png`,
  `qa_ce_candidate6_after_turn.png`. The accepted Power Attack candidate
  `..ravenloft-candidate-featskills5b` is unchanged.

## Batch 5 delivered

- `Feats.CATALOG` includes Power Attack (PHB p. 98), requiring Strength 13. The
  amount is capped at the character's current base attack bonus, so the trade is
  legal even when the feat is present but the cap is low.
- `Rules.attack` applies the committed amount as a melee attack penalty;
  `Rules.damage_bonus` adds the same amount to damage. Light weapons still take
  the attack penalty but gain no damage; two-handed weapons gain twice the
  amount. Natural/unarmed attacks are not treated as manufactured light weapons.
- `Encounter` stores the choice per actor in `power_attack_committed`.
  `set_active_power_attack` validates the feat and BAB cap, and locks once the
  standard action is used. The committed amount applies to melee attacks and
  relevant opportunity attacks, is erased at the start of that actor's next
  turn, and is not erased when another actor becomes active. `GameSession`
  forwards the choice; `CombatScreen` shows the committed amount and exposes
  melee/thrown modes for multi-mode weapons.
- Tests cover the Strength prerequisite, BAB cap, committed duration and
  opportunity attack, per-actor separation and UI switching, the locked
  post-attack control, explicit weapon modes, light/two-handed/unarmed/natural
  damage, critical multiplier, ranged/thrown exclusion, actual encounter
  resolution, the visible UI control feeding the real attack, and save/load
  retention. No shipped pregen has Power Attack; the existing JSON `feats` field
  is the authoring hook.
- No shipped two-handed weapon exists, so the two-handed doubling test uses
  synthetic weapon metadata (`two_handed: true`); this is an authoring path, not
  a claim that a shipped item exercises it. Wielding a one-handed weapon in two
  hands is not implemented.
- The same committed-attack, opportunity-attack and reset sequence was run in
  the source-native QA window. Exported corrected candidate
  `../.ravenloft-candidate-featskills5b/RavenloftFoundation.exe`
  (110,123,432 bytes, SHA-256
  `c7c49ef57ec32345faad2ac0cff9a781544f2e957c90bc13c42d27e4e0fe6e55`) was then
  launched windowed with `-- --demo-power-attack` under an isolated `APPDATA`.
  In its visible controls: Power Attack 2 was committed, a dagger melee attack
  dealt 4 damage, the amount remained 2, the turned zombie's flight provoked an
  opportunity attack at -2, and round 2 reset the control to 0. The QA fixture
  is a temporary fighter derived from Kaelen with a dagger and a low-AC/no-DR
  zombie; shipped pregens and content are unchanged. Candidate `featskills5`
  predates this correction and is not the corrected artifact. Candidate 4 is
  retained unchanged.

## Batch 4 delivered

- `Feats.CATALOG` includes Extra Turning (PHB p. 94) and Improved Turning
  (PHB p. 96). Both require the ability to turn or rebuke undead; non-clerics
  fail the prerequisite and content validation reports it.
- Extra Turning is repeatable and each prerequisite-valid copy adds four daily
  uses through `Character.turn_undead_max_uses`. Improved Turning adds one
  effective cleric level in `Encounter.turn_undead`, affecting the Table 8-9
  maximum-HD cap, turning damage and the destruction threshold, with a log line.
- Tests cover one and two Extra Turning copies (4 → 8 → 12 uses), non-turner
  rejection, the difference between a 3rd-level cleric (3-HD cap, ghoul
  unaffected) and Improved Turning (4-HD cap, ghoul turned), exact damage and
  save/load retention. No shipped pregen has these feats; the existing JSON
  `feats` field is the authoring hook.
- Exported candidate `../.ravenloft-candidate-featskills4/RavenloftFoundation.exe`
  (110,113,448 bytes, SHA-256
  `56c1a7d3645b640327e9bc41c8e31fa7db2bd1ba1b79850ad71ef8cf86dd925a`) was
  launched with `--headless --quit-after 90 -- --demo` under an isolated
  `APPDATA`: exit 0, no script, parse or validation errors.

## Batch 3 delivered

- `Feats.CATALOG` now includes Armor Proficiency (light/medium/heavy), Shield
  Proficiency, Simple Weapon Proficiency, Martial Weapon Proficiency and Exotic
  Weapon Proficiency (PHB pp. 89, 94, 97, 100). The armor feats are distinct
  entries with their PHB prerequisite chain; martial and exotic selections are
  repeatable for different weapons.
- `Feats.granted_proficiencies`, `is_weapon_proficient`, `is_armor_proficient`
  and `is_shield_proficient` combine authored categories, exact item names and
  prerequisite-valid feat grants. The parser resolves the printed armor names
  without changing the existing Weapon Focus/Skill Focus parameter rules.
- `Rules.weapon_nonproficiency_penalty` applies -4 to manufactured weapons;
  `Rules.armor_attack_penalty` applies non-proficient armor/shield ACP to
  attacks; `Rules.skill_armor_check_penalty` applies it to every movement skill,
  explicitly including Ride, while preserving normal ACP multipliers for
  proficient wearers.
- Armor items author `armor_category`; shields author `proficiency`; all five
  pregens now include their class armor/shield categories. Ysolde's wizard list
  was corrected to her specific simple weapons; Mira retains the sorcerer
  simple list.
- `proficiency_schema` version 2 preserves exact current lists and migrates
  older saves once from class defaults, so existing characters do not become
  retroactively non-proficient. The round-trip and legacy migration are tested.
- Exotic Weapon Proficiency is **mechanically implemented** and tested with a
  synthetic exotic weapon, including the BAB +1 and Str 13 exceptions, but no
  exotic weapon is authored in shipped content. It is therefore not claimed as
  fully integrated. Tower Shield Proficiency is **deferred**: there is no tower
  shield item or cover/total-cover mechanic.
- Exported candidate `../.ravenloft-candidate-featskills3b/RavenloftFoundation.exe`
  (110,112,472 bytes, SHA-256
  `fcb8edaafa10b639c3b44e7c7598af4709f56e9716fa6ea8d9fcbd2df690104f`) was
  launched with `--headless --quit-after 90 -- --demo` under an isolated
  `APPDATA`: exit 0, no script, parse or validation errors. The earlier
  `...featskills3` candidate (SHA-256 `4a74702e...`) was built before the
  exactness fix and is retained as superseded evidence.

## Batch 2 delivered

- `Feats.CATALOG` now contains Acrobatic, Agile, Animal Affinity, Athletic,
  Deceitful, Deft Hands, Diligent, Investigator, Magical Aptitude, Negotiator,
  Nimble Fingers, Persuasive, Self-Sufficient and Stealthy (PHB pp. 89–101).
- Each feat has no prerequisite, is non-repeatable, and grants exactly +2 as an
  untyped modifier to its two printed skills. No action is added or omitted:
  these are passive bonuses.
- `tests/test_feats_skills.gd` checks every catalog field against the printed
  description, checks all 45 skills for exact-pair targeting (no leakage), checks
  stacking with Skill Focus (+2 and +3 yield +5), and checks content validation
  and active `Feats.describe` rows.
- No shipped character, monster, encounter or campaign balance was changed. The
  new feats are available through the established JSON `feats` authoring field.
- No save-schema change: `feats` was already serialized; saves without the new
  names load unchanged.
- Exported candidate `workspace/releases/windows_legacy_2026-11-05/RavenloftFoundation-featskills2.exe`
  (110,104,120 bytes, SHA-256
  `03ea2068f077cc8e7d46ce686656c67468312dbe819e4c35714e9323cbe7fefc`) was copied
  outside the source tree and launched with an isolated `APPDATA`; exit 0, no
  script/parse/validation errors. No native controls changed in this batch.

## Batch 1 delivered

- `src/core/skills.gd`: all 45 Table 4-2 skills, rank/total separation,
  trained-only, armor multipliers (Swim ×2), Table 4-5 synergies, take 10/20,
  Aid Another, opposed checks, class/cross-class rank caps and breakdowns.
- `src/core/feats.gd`: twelve batch-1 feats with prerequisites, parameterised
  selections, repeatable Toughness, typed modifiers, temporary-prerequisite
  suspension, UI rows and content validation. The  catalog contains thirty-seven
  implemented feats after batch 6 (thirty-six after batch 5; thirty-five after
  batch 4; thirty-three after batch 3; twenty-six after batch 2).
- `Rules.stack_bonuses`: same-type bonuses take the best, same-type penalties
  stack, dodge stacks, circumstance stacks by source, untyped stacks.
- Integration: saves, AC, attack, damage, initiative, skill checks, dialogue
  checks, exploration take 10/20, character sheet breakdowns and content
  validation.
- Content: authored proficiencies for all five pregens; infected zombie base HP
  39 + Toughness = 42; ghoul claws use the computed Multiattack penalty.
- Turn undead: holy symbol is now required, with a clear unavailable reason.

## Corrections made in batch 1

- Armor check penalties were being negated twice in the skill breakdown;
  Kaelen's climb now correctly totals 3 (4 ranks + Str 3 − chain shirt 2 −
  shield 2).
- Weapon Focus no longer uses substring matching; it matches the selected weapon
  exactly and re-checks proficiency and BAB.
- Multiattack is mechanical: the ghoul's claw attack data is 0, and the rules
  apply −2 (or −5 without the feat).
- Toughness is applied once on entry and is not reapplied by save loading.

## Next dependency-ordered batch

1. Spell Focus / Greater Spell Focus remain dependent on a shipped spell that
   actually calls for a saving throw; all six current spells are attack, no-save,
   healing or buff spells. Add such a spell before treating the feats as
   integrated. Spell Penetration still awaits spell resistance.
2. Combat feats only with their underlying action: the remaining special attacks
   (disarm, bull rush, overrun, sunder, grapple). Trip and Improved Trip are
   implemented for the player-initiated path, so Improved Disarm and Improved
   Bull Rush/Overrun/Sunder become candidates once their actions exist.
3. Full-attack family (Rapid Shot, Manyshot, Two-Weapon Fighting, Great Cleave,
   Whirlwind Attack) after iterative/full attacks exist. Cleave itself is
   implemented for one extra attack per round.
4. Item creation and metamagic last; they need downtime, components and
   modified spell levels.

## Open verification items

- Manual UI review of the two new take 10/20 buttons at 1.6× text and at
  1024×600; construction is covered by a headless test, rendering is not.
- Dialogue `take`/`circumstance` options are supported by the runner but no
  shipped dialogue uses them yet.
- Dodge target selection remains a documented general-bonus adaptation.
- Skill rank legality is available (`Skills.ranks_legal`) but pregen budgets
  were not retroactively rewritten; no rank-cap violation exists in shipped
  content.
- Exotic Weapon Proficiency has no shipped exotic weapon; only the synthetic
  selection and penalty path is verified. Tower Shield is deferred rather than
  claimed.
- Power Attack's two-handed multiplier is verified with synthetic `two_handed`
  metadata because no shipped weapon uses it; the light-weapon and normal melee
  paths use shipped items.
- Combat Expertise has no shipped pregen or authored encounter that exercises it;
  the native evidence uses a temporary QA fixture. Fighting defensively, total
  defense, full attacks and one-handed-in-two-hands remain unsupported, so those
  interactions are deferred rather than claimed.
- Cleave has no shipped pregen or authored encounter; the native evidence uses a
  temporary QA fixture plus the visible training entry. Own-turn and off-turn
  (opportunity-attack) triggers are supported; ranged/spell/damage-over-time
  triggers and NPC Cleave are deferred rather than claimed, as is Great Cleave.

## Trip, prone and Improved Trip — supported (documented scope)

Updated: 2026-11-05. Status: **supported within the stated scope**. Trip, Stand
Up and Pick up are playable in the combat interface and verified in a fresh
exported candidate. NPC-initiated Trip remains unimplemented, so the player never
answers a counter-trip prompt as the defender; NPC defenders always counter-trip.

Verified by the full suite: **275/275 tests, 3,585 assertions, 18 scripts, exit
0**; `git diff --check` clean.

### Source basis

- Trip, being tripped and tripping with a weapon: PHB printed pp. 158-159.
- Prone attack modifiers: Table 8-5, printed p. 151 (melee -4; most ranged
  weapons unusable, crossbow or shuriken at no penalty).
- Prone AC modifiers: Table 8-6, printed p. 151 (melee -4, ranged +4).
- Standing up: printed p. 143 (move action, provokes an opportunity attack).
- Opposed-check ties: printed p. 64.

### Tie procedure (corrected this session)

Printed p. 64: "In an opposed check, the higher result succeeds, while the lower
result fails. In case of a tie, the higher skill modifier wins. If these scores
are the same, roll again to break the tie." Trip opposes ability checks, so the
ability modifier stands in for the skill modifier. A tie is **not** awarded to
the defender. `Rules.opposed_ability_check` applies result, then modifier, then
reroll, and reports `tie_broken_by`.

### Implemented

- Size category is authored data (`Character.size_category`); `size_ac` is
  recomputed from it on load and legacy saves with only `size_ac` migrate to the
  matching category. Content validation rejects a category/modifier mismatch.
- Explicit `stability_bonus` and `trip_immune` properties; neither is inferred
  from a name, tag or monster type.
- Prone state (`Character.is_prone`/`set_prone`) with no duration.
- Attack-type-aware AC and attack modifiers in `Rules.armor_class`,
  `Rules.touch_ac` and `Rules.attack_bonus`; prone ranged attacks are rejected
  unless the weapon carries authored `prone_usable` data.
- `Encounter.stand_up_active`: move action; the opportunity attacks resolve while
  the character is still prone; prone clears only if the character can finish.
- `Encounter.trip_active`: standard action, size gate, explicit immunity, reach,
  unarmed attempt provoking from the target, weapon-assisted attempt (no
  provoke, source-listed trip weapons only), melee touch attack, opposed check
  with the per-category size bonus and the defender's stability bonus,
  counter-trip, and weapon release on a lost counter-trip.
- A dropped weapon is a free action (PHB p.144) into an encounter-local ground
  list holding its id, data and cell. It is never also in the backpack.
- Pickup is a move action that provokes (PHB Table 8-2, p.141); it moves the item
  to the inventory unequipped and removes the ground entry. A completed encounter
  recovers leftover ground items to the party, so nothing is lost or duplicated.
- Prone movement is limited to crawling 5 feet as a move action, provoking from
  any attacker who threatens the crawl (PHB p.142); a 5-foot step is refused.
- Trip weapon release is a resumable decision: all rolls are made once, the
  resolution pauses with `pending_trip`, unrelated actions and End Turn are
  refused, and `resolve_trip_decision` applies the choice without rerolling.
- `content/items.json` gains the PHB light flail with `trip: true`; the light
  crossbow gains `prone_usable: true`.

### State after closure

- Combat screen has Trip (with an equipped-trip-weapon checkbox), Stand up,
  Pick up, a Drop/Keep weapon decision panel, prone markers and a ground-item
  list. Disabled controls are presentation only; every rejection also happens at
  the rules/session boundary.
- Pending-decision boundary: while `pending_trip` exists, spellcasting, potions,
  first aid, turn undead, Power Attack, Combat Expertise, equipment and inventory
  use, attacks, movement, Trip, Stand up, Pick up, auto-advance and End Turn all
  refuse. Only the decision itself and harmless inspection/settings proceed.
- `finish` voids a pending decision explicitly and logs it; a changed turn or a
  dead actor voids it in `resolve_trip_decision` without applying effects.
- Ground-item recovery happens only on victory; defeat logs the loss and grants
  nothing. Automatic post-victory recovery is a labelled convenience adaptation:
  the source leaves dropped items on the battlefield.
- `--demo-trip` with `--trip-scenario=<success|touch_fail|counter_drop|
  counter_keep|prone|stand_aoo|pickup|crawl|return|improved_trip|
  improved_trip_decline>` builds an isolated fixture from pregen data. QA-only
  `--trip-probe` clicks the real controls through the viewport input pipeline,
  checks explicit expected state after each step, writes captures to
  `--trip-shots=<dir>`, and exits nonzero if any check fails.
- The original candidate `workspace/releases/trip_candidate/RavenloftFoundation.exe`
  (SHA-256 `6fb26be2c919d749177db8348e023bfd8b8088edb46ac68ca18916f8d034f5f9`,
  110,155,848 bytes, HEAD `9fc8fff` plus diff `064452c3...`) is preserved
  unchanged. A narrow external OS-input pass on it reached Trip, the Drop/Keep
  panel, Drop, Pick up and the next round.
- Deferred: NPC-initiated Trip, so the player-as-defender counter-trip prompt is
  unreachable; NPC defenders always counter-trip. Mounted trip, non-listed trip
  weapons, and pickup beyond the item's own square.

### Improved Trip — added 2026-11-05

Source: PHB printed p. 96. Prerequisites INT 13 and Combat Expertise. A fighter
may take it as a fighter bonus feat, and a 6th-level monk may take it without the
prerequisites; the slice has no monk class and no feat-selection UI, so both stay
authoring facts rather than runtime paths. The feat is inert while a prerequisite
is unmet (`Feats.has_active`).

Implemented effects, as printed:
- An unarmed trip does not provoke an opportunity attack. Weapon trips already
  did not.
- +4 on the attacker's own Strength check to trip. It is not added to the touch
  attack, the defender's opposed check, or the defender's counter-trip check.
- After a successful trip in melee, an immediate melee attack against that same
  opponent "as if you hadn't used your attack for the trip attempt". PHB p. 96
  grants "a melee attack", not the trip method, so the player chooses at the
  decision: the equipped weapon's legal melee mode or an unarmed strike. Ranged
  modes are refused, and nothing is drawn, equipped or re-gripped — a different
  weapon would need the normal equip action, which this decision does not grant.
  The attack inherits committed Power Attack and Combat Expertise, uses the prone
  target's melee AC, and spends no second standard action. It is one ordinary
  attack: no iterative chain, and it cannot generate another trip or follow-up.
- The follow-up is the player's to take or decline. It pauses as
  `pending_trip.type == "improved_trip_attack"` with every trip roll final;
  `resolve_improved_trip_attack` resolves it once or declines. A changed turn, a
  dead actor or encounter termination voids it without effect.

Verification: `tests/test_improved_trip.gd` (15 tests, 90 assertions), all eleven
asserted `--trip-probe` scenarios in source and in the new candidate
`workspace/releases/improved_trip_candidate/RavenloftFoundation.exe` (SHA-256
`17f164e9ed83427a3809f713e8a413cb772ea951ac48303f7e6387c232e94b01`), plus a
narrow external OS-input pass. Full suite at that closure: 258/258 tests,
3,509 assertions, 17 scripts; the current suite is larger after Cleave.

### Cleave — added 2026-11-05

Source: PHB printed p. 92. "If you deal a creature enough damage to make it drop
(typically by dropping it to below 0 hit points or killing it), you get an
immediate, extra melee attack against another creature in the immediate vicinity.
You cannot take a 5-foot step before making this extra attack. The extra attack
is with the same weapon and at the same bonus as the attack that dropped the
previous creature. You can use this ability once per round." Prerequisites:
Strength 13 and Power Attack. Great Cleave (printed p. 94) is out of scope.

Implemented:
- Eligibility is re-checked on use (`Feats.cleave_available`): the feat, both
  prerequisites and a live attacker. A drop is detected from resolved combat
  state (`hp < 0` or dead), not from interface text or an array removal. A hit
  that does not drop the target offers nothing.
- Only the actor's own resolved melee attack triggers it; opportunity attacks and
  the trip action itself do not. Improved Trip's granted follow-up is an ordinary
  melee attack and does trigger it.
- A separate `pending_cleave` state pauses resolution with a take/decline panel.
  `has_pending_decision()` covers both Trip and Cleave, so the guard message is
  the neutral "Resolve the pending combat decision first." rather than a
  Trip-specific one.
- `resolve_cleave_attack` validates the chosen target against the same
  `cleave_targets` list the panel was built from, then takes the stored weapon,
  mode, label and attack bonus and forces that bonus through `Rules.attack`'s
  `force_attack_bonus`, so the extra attack cannot pick up a different weapon or
  a recomputed bonus.
- `cleave_used` is keyed by combatant, set before the extra attack rolls and
  cleared at the start of each round, so the drop caused by the extra attack
  cannot chain and no other pathway can take a second Cleave. Declining does not
  set it. A changed turn, a dead or invalidated actor, or encounter termination
  voids the decision without effects.
- No movement or 5-foot step is allowed while the decision is pending.

Verification: `tests/test_cleave.gd` (14 tests, 64 assertions), the four asserted
`--cleave-probe` scenarios in source and in
`workspace/releases/cleave_candidate/RavenloftFoundation.exe`, and a narrow external
OS-input pass. Full suite: 275/275 tests, 3,585 assertions, 18 scripts.

### Cleave off-turn trigger and training entry — added 2026-11-05

Source: PHB p. 92 (Cleave) read together with the opportunity-attack rule
(printed p. 137): an opportunity attack is a real melee attack, so the feat's
"extra melee attack" is not restricted to the attacker's own turn. Ranged
attacks, spells and damage-over-time effects are not melee attacks and never
trigger it.

Implemented:
- `Encounter._resolve_attack` offers Cleave from any party member's resolved
  melee attack, on or off turn; the decision stores the triggering attacker,
  weapon and attack context rather than assuming the active combatant. NPC
  attackers, ranged attacks, spells and damage over time stay unsupported.
- Opportunity attacks now resolve through `_resolve_attack(..., reaction: true)`,
  so they spend no action from the attacker's own turn, and the monster and flee
  loops stop with `pending_cleave["off_turn"] = true` when a provoked attack
  drops a creature.
- Interruption is preserved explicitly: the fleeing monster's remaining route,
  target chain and attack-after flag are stored in a bounded `off_turn_resume`
  record (no closures). `resume_interrupted()` re-validates the actor, target
  legality and encounter state and then continues the interrupted action;
  otherwise the interrupted turn ends. Turn ownership never changes.
- "Same bonus" interpretation: `Rules.attack` keeps only the triggering attack's
  own base (`force_attack_base`, reported as `bonus_base`) and re-adds
  target-specific modifiers for the new target (helpless +4, cowering +2, plus
  flanking/prone/reach evaluation), so a bonus that no longer applies is not
  copied from a previous total.
- Frequency is unchanged in intent and now tested in both directions: a use on
  the character's own turn blocks an off-turn opportunity in the same round and
  vice versa, declining records nothing, duplicates are refused, and multiple
  drops in a round still yield one use; the track clears at round start.
- Window minimum is enforced at 1280x720 (`Window.min_size`); the combat sidebar
  scrolls, so the Cleave panel's target list and decline control stay reachable
  at the 1.6x text scale. 1024x600 is not a supported target.
- The main menu now exposes "Combat Training / Rules Demonstrations" with a
  Cleave demonstration beside the existing Trip demonstrations. It reuses the QA
  fixtures, sets `Game.training_mode` (no victory effects, XP or autosave) and
  returns to the menu, leaving campaign saves, geography and pregen feats alone.

Verification: `tests/test_cleave_offturn.gd` (11 tests) plus the updated
`tests/test_cleave.gd` (14 tests); the six `--cleave-probe` scenarios in source
at 1280x720 and at 1.6x text (`cleave`, `cleave_decline`, `cleave_from_trip`),
the `--training-probe` menu path, and the same probes in
`workspace/releases/cleave_offturn_candidate/RavenloftFoundation.exe`. Full suite:
**286/286 tests, 3,631 assertions, 19 scripts, exit 0**.

## Foundation reassessment — 2026-11-05

Direction change: stop implementing the PHB one feat at a time. The implemented
feats, trip, Cleave and turning stay as verified examples; the work now is the
shared groundwork they plug into.

What was consolidated in this pass:
- `src/core/content_spec.gd` is the single authored vocabulary for effects and
  conditions (fields, field kinds, id lookups). Content validation and the
  runtime guards both read it, so a new effect is one row, one handler, one
  test. Dialogue conditions previously used a second hand-maintained list in
  `ContentDB`; that duplicate is gone.
- Missing-field, wrong-kind, unknown-skill and missing item/quest/encounter/area
  references now report named errors from the same registry.
- `Main._start_demo` marks demonstration runs as training, so a command-line
  demo cannot autosave over a player's slots or award campaign XP.
- `tests/test_extensibility.gd` is the contract regression: vocabulary, error
  text, required identifiers, lookups, and a data-only positive control.

Deliberately not done: no new feat, special attack or area, no universal
scripting/event framework, no rewrite of the encounter or UI layers. The
remaining gaps ranked by value:

1. **Decision registry.** `Encounter` carries `pending_trip` and
   `pending_cleave` separately, and `has_pending_decision()`,
   `CombatScreen._rebuild_decision()` and the resume path each need a branch per
   decision. One typed pending record plus a resolver table would let a new
   reaction touch one encounter file and one UI builder.
2. **Content manifest + `--validate-content` CLI** so content errors fail a
   build without launching GUT. *(2026-11-14: the CLI half is met by
   `--validate-campaigns` and `--validate-diagnostics`. A `--validate-content`
   option was never implemented and is now refused as unknown. The manifest is
   still open.)*
3. **Data-driven passive feats.** `Feats.CATALOG` is code; moving the rows to
   JSON with the same schema would make class/template feat lists authorable
   without touching GDScript.
4. **Spell resolution table.** `Encounter.cast_active_spell` matches a `resolve`
   string with per-spell methods; a handler table is the same pattern the
   effect registry now uses.
5. **Save schema migration hook** before the first public content update.

Full suite after this pass: **296/296 tests, 3,654 assertions, 20 scripts, exit
0**; `git diff --check` clean.

## Campaign creator slice 3 — quests, encounters and playtest semantics (2026-11-05)

- Scope: finish the player-authored loop without hand-editing JSON — define a
  quest and its consequences, place an encounter trigger, validate, playtest,
  save, then play normally and save progress. No feats, combat rules or new
  monsters were added.
- Playtest semantics changed deliberately: **Save draft** is the only action that
  writes `user://campaigns/<id>/`. **Playtest** now validates and stages the
  in-memory draft under `user://playtest/<id>/`, loads it through the ordinary
  loader with `Game.playtest_mode`, refuses saves, and deletes the staged copy on
  return. The last deliberately saved package is never overwritten; the draft
  keeps its dirty flag; returning restores the same editor state.
- Quest editor: campaign-local create/select/rename/delete (delete refused while
  referenced), title/description, up to 12 objectives with explicit flags,
  campaign start and optional completion quest, and a reference list. Objective
  flags set before the quest starts are not credited until it becomes active
  (existing `QuestLog.sync_flags()` semantics), so no early flag silently
  completes a quest.
- Flags: declarations are stored in the manifest as `flag_definitions`; the
  editor lists defined flags and used-but-undeclared flags separately. Removing
  a declaration is refused while referenced.
- Encounters: campaign-local create/rename/delete, three fixed layouts (7x5 room,
  9x5 hall, 9x7 crypt) with four party cells, up to four shared monsters
  (`zombie`, `infected_zombie`, `ghoul`), bounded XP, intro text, victory flag,
  narration and optional quest start. Validation checks walkability, uniqueness
  and bounds; no stat editing, spells or AI.
- Triggers: placed on a legal floor cell of the current area, one encounter each,
  optional guard flag. Placement defaults the guard to the encounter's victory
  flag so a cleared encounter is not repeatable after reload. The engine's
  per-trigger spent flag covers re-entry in the same run.
- Dialogue palette extended minimally: a response can start a selected quest and
  start a selected encounter, alongside the existing set-flag/guard/check
  palette. Options come from the campaign's own definitions.
- Full suite at this milestone's close: **329/329 tests, 4,160 assertions, 22
  scripts, exit 0** (baseline 320/3,965). `test_campaign_creator.gd` is now 23
  tests/445 asserts, including the lossless round trip, load-refusal guards,
  write-boundary file comparisons and the pinned action bar.
- Probes in source and in the exact candidate: `--creator-probe`,
  `--creator-ui-probe`, `--creator-interaction-probe`,
  `--creator-story-probe`, `--creator-combat-probe`,
  `--creator-combat-reload-probe` and `--creator-encounter-click-probe` all exit
  0. The story probe asserts the complete authored loop, playtest isolation,
  ordinary save/reload, no repeat, and cross-campaign isolation; it uses the
  forced `Encounter.finish()` path and is labelled postcombat integration only.
- Real-combat closure: `--creator-combat-probe` (seed 90210) wins the authored
  encounter with ten **Attack**-button + target-cell clicks after moving into
  reach with the **Move** control; it does not call `Encounter.finish()`, edit HP
  or set the flag directly. Victory sets `beacon_lit`, completes the quest and
  awards 50 XP once (3000→3050), saves, and quits. A second process
  (`--creator-combat-reload-probe`) loads the slot, re-crosses the trigger with
  no combat or second reward, and sees the changed NPC response.
- Lossless editing and refusal policy: unrelated saves preserve doors, object
  interactions/effects, hand-authored node/choice effects and conditions,
  unknown author keys, `flag_definitions`, campaign-local `items.json` and an
  unmanaged `dungeon.json`; packages with inline content, newer format versions
  or wrong-shape/duplicate content files are refused rather than narrowed.
- Windowed captures at 1280x720, 1.0 and 1.6 scale:
  `workspace/qa/slice3/creator_slice3_{quests,encounters}_{min,large}.png`.
- Layout correction after windowed inspection: encounter row labels collapsed
  next to the expanding pickers; they now have fixed minimum widths and no
  wrapping, and were re-captured at 1.0 and 1.6 scale.
- Candidate: `workspace/candidates/creator_slice3_2026-11-05e/` (110,376,216
  bytes, SHA-256 `57758c82…aea3565f`); `BUILD.txt` now records untracked-file
  count and hash as part of source identity. Candidate `…c` remains at
  `7a205aee…ecb7a227`; the accepted slice-2 candidate and earlier exports are
  untouched.
- New-encounter click resolved: the button sits at y=2821 with the creator at
  scroll 0 and at y=125 after the focus scroll; it is enabled and visible, and
  an OS click at its measured centre created and selected `encounter_02`. The
  earlier miss was a stale pre-scroll coordinate, not a defect.
- Not verified: a human windowed playtest; the combat acceptance is automated
  control input, not a person playing. Everything else above was re-run on the
  final source and the exact candidate.

## Campaign-creator usability and acceptance (2026-11-05)

- Exercise: `--creator-acceptance-probe` starts at the campaign list, uses the
  visible **Create campaign** dialog and the creator's own controls for two areas
  and linked passages, entry, a speaker, a Search-check conversation with a
  flag-gated changed response, a declared flag, a quest/objective, an encounter
  with victory wiring, and a once-only trigger; then validate/save, the recovery
  refusals, playtest (talk, check, trigger, forced postcombat, changed response,
  refused save), reopen from disk, and ordinary play/save/load. It is an
  automated UI script, not a human study. All steps PASS in source and in
  `creator_usability_2026-11-05`; no external file editing was needed.
- Confirmed friction fixed: the Save/Validate/Playtest bar and status message
  scrolled out of view at the quest/encounter sections (about 2,700 px down)
  and validation text was written below the last section. The action bar, the
  save/play distinction line and the status label are now pinned above the
  scrolling content; Playtest is labelled **Playtest draft**. Measured evidence:
  **New encounter** sits at y=2821 at scroll 0 and y=125 after the focus scroll;
  the new assertion checks Save, Playtest and status stay enclosed by the
  viewport at that position. Regression test:
  `test_creator_action_bar_stays_visible_when_scrolled`.
- Recovery outcomes: wall entry, occupied trigger cell, referenced quest delete
  and duplicate campaign id are refused with a reason while the dialog/draft is
  preserved; unsaved **Back** offers Save/Discard/Keep editing; playtest saves
  are refused; the saved package is byte-identical after playtest.
- Guide: `AUTHORING_GUIDE.md` now opens with a ten-step getting-started workflow,
  the draft/save/playtest/playthrough state model, a concrete
  flag→objective→victory→guarded-response example, and a refusal-recovery table.
- Verification: **329/329 tests, 4,160 assertions, 22 scripts, exit 0**;
  `test_campaign_creator.gd` 23 tests/445 asserts; `--validate-campaigns` PASS in
  source and the exported executable; windowed 1280×720 at 1.6 text scale with an
  OS click on **Validate draft** left the pinned bar and green validation message
  visible (`workspace/qa/usability/creator_encounters_1p6_validate.png`).
- Candidate: `workspace/candidates/creator_usability_2026-11-05/`,
  110,384,600 bytes, SHA-256
  `1a53fa04e5cb6683083ffebde8186b8d4f4ce3e14291691adc4c66613c54d39c`.
  The accepted slice-3 candidate is untouched.
- Remaining: validation does not jump to the offending section; malformed JSON
  syntax still has no dedicated fixture; doors/objects/unique items remain
  file-authored; no human usability study or windowed playthrough was performed.

## 2026-11-13 — ordinary unarmed attacks

- The unarmed strike now has printed semantics: nonlethal, size-based damage in
  its own persisted total (PHB p. 139), provocation from an armed target only,
  and undead/construct immunity via the existing type traits. The threat split
  from the previous unit is unchanged: empty hands still threaten nothing.
- Verification: **438/438 tests, 5,090 assertions, 32 scripts, exit 0**;
  candidate `unarmed_2026-11-13` (110,545,480 bytes, SHA-256
  `c9d9f970a637d4f792651f6f5c05280fd8f0c1db61e8ada1f4cb66a2a48c0108`) passes
  all six probes (51/27/15/49/79/49 checks), both validators, and the packed-path
  audit (144 paths, no leaks). Candidate `unarmed_threat_2026-11-13` is preserved
  with `SUPERSEDED.txt` naming only the unarmed-attack semantics it lacked.
  Snapshot `snapshots/2026-11-13_unarmed/` (469 files, verified manifest), and the
  previously missing checkpoint for `snapshots/2026-11-13_unarmed_threat/` is
  now written.
- Remaining in this area: monk/touch-spell armed states, natural hourly
  nonlethal recovery, and a dedicated nonlethal-recovery action beyond magical
  healing.

## 2026-11-13 — nonlethal state integration and feat record correction

- Improved Unarmed Strike is recorded correctly: armed status, no provocation,
  and lethal-or-nonlethal choice (PHB p. 97); it adds no damage die. The invented
  "improved damage die" limitation is withdrawn. The lethal choice is implemented
  through the ordinary attack control, with the printed −4 for characters without
  the feat (PHB p. 147).
- Nonlethal thresholds are derived state: equal to current hit points →
  staggered with the one-action-per-round restriction; greater → unconscious and
  helpless; lethal damage and healing cross the thresholds; zero never creates a
  state; clearing nonlethal never removes another incapacity; encounters end when
  no enemy can act.
- Magical healing removes nonlethal damage equal to the amount cured (cure spell,
  potions, authored healing), including at full hit points. Natural hourly
  recovery is recorded as replaced by rest clearing the total.
- Verification: **458/458 tests, 5,168 assertions, 33 scripts, exit 0**;
  candidate `nonlethal_2026-11-13` (110,554,296 bytes, SHA-256
  `0e551045a24e82c53ce1c78abeac0959ff958248f7ec9654c2a599def6ef8acb`) passes all
  seven probes (51/27/15/30/49/79/49 checks), both validators and the packed-path
  audit (144 paths, no leaks). Snapshot `snapshots/2026-11-13_nonlethal/` with a
  verified manifest.
- Artifact identity: `unarmed_2026-11-13` carries an `ARTIFACT_NOTE.txt` stating
  that an intermediate export there was overwritten and is not preserved; future
  evidence exports use new directories or attempt suffixes.

## 2026-11-13 — encounter resolution and package discovery diagnostics

- **Corrected:** `_check_end` no longer equates "cannot act" with defeat. Enemies
  count as defeated only when dead/destroyed or nonlethally unconscious; the
  party is defeated only when every member is dead, dying, stable or nonlethally
  unconscious. Paralysis (1d4+1 rounds) and timed unconsciousness keep the fight
  running with skipped turns. New `tests/test_encounter_resolution.gd` (11 tests)
  proves victory, non-victory, mixed groups, party-side recovery and XP-once.
- **Added:** user-package discovery diagnostics. An unreadable `campaign.json`
  used to make a package vanish silently. `CampaignStore.scan_errors` now records
  the reason (JSON error with line, id/folder mismatch, missing manifest, invalid
  folder id); `CampaignDB.errors`, the campaign screen and
  `--validate-campaigns` report it, and the validator exits nonzero.
  `tests/test_campaign_discovery.gd` (7 tests) covers failure and repair.
- **Content inventory verified from current packages:** 3 campaigns
  (`ravenloft_demo`, `hollow_lantern`, `ashwick_ferry`), 7 areas, 7 encounters
  (5 playable, 2 QA fixtures), 5 dialogues, 4 quests, 5 shared characters,
  3 monsters, 6 spells, 18 items. No creator template packages exist in
  `content/` (only GUT's own `addons/gut/double_templates`).
- **Verification:** 476/476 tests, 5,225 assertions, 35 scripts, exit 0; both
  validators PASS; candidate `package_diagnostics_2026-11-13`
  (110,555,832 bytes, SHA-256
  `926b121b78ed16d094f1fde5c2335f2190319fb8c1dfba10cc225c8dc94afc39`) passes all
  seven probes (51/27/15/30/49/79/49 checks) and reports the broken-package
  failure (exit 1, line-numbered reason) and repair (exit 0) end-to-end; packed
  paths 144, no leaks.
- **Next selected task:** authoring-time content validation inside a package is
  the remaining non-combat gap worth taking next (see the continuation brief);
  save migration is still not required: `SAVE_VERSION` is 1, only one save
  format exists, and a missing `nonlethal` field is already tolerated.


## 2026-11-13 — story-file diagnostics and recovery

- **Extended, not replaced:** the existing content loader now keeps parser
  message/line and records structured diagnostics (`code`, `campaign`,
  package-relative `source`, `entity_type`, `entity_id`, `line`) beside the human
  messages. Area and dialogue syntax, wrong-shape JSON, missing referenced area
  files and manifest problems have distinct codes. Shape and semantic problems
  never invent a line. Parser lines are normalized to 1-based.
- **One validity answer:** `Game.validate_campaign` returns the same structured
  diagnostics used by `--validate-campaigns`, `--validate-diagnostics` and the
  campaign screen's **Validate**; `Game.diagnose_campaign` validates first and
  keeps the file/line entries. A broken package still cannot replace the active
  campaign: the loader builds a fresh `ContentDB` and only swaps on success.
- **Recovery:** repairing a damaged area or dialogue file clears the diagnostic on
  the next load; other packages keep validating. No file is rewritten and no
  default story data is substituted.
- **Tests:** `tests/test_story_diagnostics.gd` (9 tests / 69 assertions); whole
  suite **485/485, 5,294 assertions, 36 scripts, exit 0**; both validators PASS.
- **Exported candidate `story_diagnostics_2026-11-13`** (110,566,424 bytes,
  SHA-256 `1a5ce809ba8eda304315f8a53813599f6f3fe0b100cc85ddacd0cf1572eb2421`):
  `--encounter-end-probe` 11/11 (paralysis is not defeat; recovery does not
  resolve; real defeat once), `--package-diagnostics-probe` 20/20 (real campaign
  screen: readable manifest reason, safe refusal with file/line, Validate surface,
  repair and reopen), `--nonlethal-probe` 30/30, exported CLI exits 1 on damaged
  area/dialogue and 0 after repair, 144 packed paths with no leaks.
- **Window check:** supported minimum 1280x720 at the real default Settings text
  scale (1.0); the discovery notice is legible above the cards
  (`runs/shots/package_notice.png` in the candidate).
- **Next selected task:** audit supported package edits against existing saves.
  `content_version` is fixed at 1 and editing a package does not change it, so a
  structural edit can reuse a save made for different content. Establish whether
  any supported edit actually strands or misplaces progress (removed area, moved
  entry, removed flag/quest) and fix only that demonstrated case with a safe
  refusal or version change — not a migration system.

## 2026-11-13 — save/content compatibility

- **Contract:** `SAVE_VERSION` remains 1; a save stores `campaign_id`,
  `content_version`, area, cell/facing, party/items, dungeon/area state, quests,
  flags, gold, RNG and log. Save-format compatibility is separate from
  campaign-content compatibility.
- **Reproduced before changing code**, using an ordinary `CampaignStore.create`,
  a second area, `Game.new_game`, a side quest and `Game.save_game("slot2")`:
  prose edits and entry moves loaded at the saved cell; a blocked saved cell
  loaded into a wall; an out-of-bounds position silently fell back to the area
  start; removing a saved quest dropped its progress; removing a flag
  declaration was harmless; removing the saved area and changing
  `content_version` already refused safely.
- **Fixed only the demonstrated unsafe cases** in `Game.load_game`, before any
  live assignment: saved quests/objectives must still be defined; the saved cell
  must be in bounds and walkable after saved state is applied. The existing
  content-version contract is unchanged and still enforced. There is no silent
  teleport, no progress discard, no migration, no content hash and no automatic
  version bump.
- **Diagnostic fix:** the legacy-save fallback now runs only when the
  campaign-scoped file is missing, so an unsupported save format keeps its own
  message instead of being masked by "No save in slot2."
- **Refusal is atomic:** refused loads preserve save bytes, live session,
  campaign, package and other slots. Messages distinguish missing area,
  blocked/outside location, missing quest/objective, content-version mismatch,
  unsupported format and uninstalled campaign.
- **Tests:** `tests/test_content_compatibility.gd` — 11 tests / 108 assertions
  covering harmless edits, each refusal, unchanged bytes, unchanged live state,
  unsupported format and missing campaign. Whole suite **496/496, 5,402
  assertions, 37 scripts, exit 0**; both validators PASS.
- **Candidate `save_compat_2026-11-13`** (110,575,720 bytes, SHA-256
  `71a6e0cad5fb2138ef2c23d791f1ac8953104b0521aa7b9fe361586fd2b22c36`): exported
  `--save-compat-probe` 14/14 and `--save-compat-ui-probe` 9/9. The latter opens
  the ordinary Load modal: harmless save loads, blocked content is refused with
  the message visible, bytes/session/campaign are unchanged, restoring the area
  recovers the save.
- **Capture:** `runs/shots/save_compat_refusal.png`, 1280x720 at default text
  scale 1.0; the Load modal stays open with the blocked-cell message.
- **Package:** 144 packed paths; required runtime scripts, `content/` and assets
  included; no development files, private references, QA profiles or generated
  artifacts.
- **Next selected task:** campaign-list usability at the supported 1280x720
  minimum. The existing capture still shows only the top of the list, so extra or
  damaged campaigns sit below the fold; make the list scroll/select cleanly at
  the minimum size and verify with a rendered capture. No playtesting required.

## 2026-11-13 — campaign-list usability at the supported minimum

- **Reproduced, not assumed.** An isolated profile held three bundled campaigns,
  five valid user campaigns, one 77-character title, one package with a damaged
  area file and one malformed manifest (11 listed cards, 10 with actions). At
  1280x720/1.0 the list was 2058 px tall in a 495 px viewport; at 1.6 it was
  2860 px in 431 px. `ScrollContainer.follow_focus` was false: focusing the last
  "New game" left `scroll_vertical` at 0 with the action at y=2135 (1.0) and
  y=2887 (1.6). At 1.6 the long title widened the list to 1384 px against a
  1204 px viewport, clipping card text and requiring horizontal scrolling.
- **Small correction in the existing layout:** the same `ScrollContainer` now
  has `follow_focus = true` and horizontal scrolling disabled; campaign-card
  titles wrap with word-smart autowrap; disabled "Continue latest"/"Load slot"
  buttons are removed from the focus order. No browser, filtering or selection
  subsystem was added.
- **Tests:** `tests/test_campaign_list_layout.gd` — 2 tests / 35 assertions:
  maximum title wraps, no horizontal bar, focus on an off-screen action scrolls
  it fully into view, disabled actions are skipped, and rebuilding after a
  package disappears neither activates a card nor changes the active campaign.
  Whole suite **498/498, 5,439 assertions, 38 scripts, exit 0**; both validators
  PASS.
- **Exported candidate `campaign_list_2026-11-13`** (110,577,992 bytes, SHA-256
  `217a061b1cac4ae1df4024ac285ff59a94b2220d62f5465518aa1aa019819830`):
  `--campaign-list-probe` PASS at 1.0 and at 1.6 set through the real Settings
  slider (`scale=1.60`), each reporting `follow=true`, no horizontal overflow,
  and a focused off-screen action scrolled inside the viewport.
- **Native OS input** in the exported window at 1280x720 (mouse wheel, clicks,
  Tab/Esc; no in-process button calls): wheel reached the bottom cards; Tab
  focused an enabled action on a lower card and the list scrolled to it; Validate
  named `qa_list_damaged` and showed the area line, then named
  `qa_list_long_title` as valid; New game on the damaged package refused with its
  id and file, closing it and launching the long-titled valid campaign showed the
  matching campaign title on party selection. Validation return preserved the
  scroll position. Back from party selection resets the rebuilt list to the top;
  that was recorded as a clean reset, not a defect.
- **Limits:** native input is real OS wheel/click/Tab in one 1280x720 window per
  check, not a human playtest; screenshots are in
  `runs/shots/native_*`. At 1.6 the party-selection footer overlaps the last
  trait line of one card (observed during launch, outside this list fix).
- **Package:** 144 packed paths; required runtime scripts, `content/` and assets
  included; development files, private references, QA profiles and generated
  artifacts excluded.
- **Next selected task:** party selection at the largest text scale. The 1.6
  launch capture shows the footer covering the final trait line of a party card;
  make the party list scroll or compact at 1.6 and verify with a rendered capture.

## 2026-11-13 — party selection at 1.6

Reproduced in exported `campaign_list_2026-11-13` at 1280x720 with the Settings
slider at 1.6. The party grid already sized every card to its wrapped traits:
grid 1204x689 in a 1224x439 viewport, all five labels inside their cards, scroll
max 689. The visible crop was the scroll viewport edge (Sera's card ended at
y=645, viewport at y=619), not footer overlap; the footer started at y=648.

The real defect was keyboard reach. Five Tabs focused Ysolde's checkbox at
y=657-869 while the viewport was y=180-619 and `scroll_vertical` stayed 0, so
the focused character and all of its traits were off-screen. The party
`ScrollContainer` now follows focus, and each checkbox calls
`ensure_control_visible(card)` so the whole card is revealed. At 1.6 the same
focus moves scroll to 250 and puts the card at y=407-619 inside the viewport.
No card-height override, text reduction, truncation or new party model was
added; Begin/Back remain outside the scroll.

`tests/test_party_layout.gd`: 3 tests / 39 assertions for card growth, wrapped
labels, focus revealing the full card, visible footer controls, empty/minimum/
maximum selection rules, Begin using the chosen party, and Back/reopen resetting
defaults without changing campaign identity. Whole suite **501/501 tests, 5,478
assertions, 39 scripts, exit 0**; both validators PASS. Exported candidate
`party_layout_2026-11-13`, SHA-256
`bb7bc2901831bc53769dcbfd5935485a99101a869ac250b9637cffb89a380666`, 144 packed
paths and no development/profile output.

Native OS input in that executable: at 1.6 five Tabs revealed Ysolde's full
card, wheel reached the lower cards, clicks changed the party to three, Begin
launched it and Back returned to the campaign list; at 1.0 all five cards stayed
visible and Begin launched the campaign. Captures under the candidate's
`runs/shots/`.

Observed next gap: after Begin at 1.6 the intro modal is horizontally clipped
by its fixed width, including the Close control and title. That is outside this
party-grid change and is the next selected task.

## 2026-11-13 — intro modal at 1.6 through the shared builder

Reproduced in `party_layout_2026-11-13` at 1280x720, Settings scale 1.6. The
shared modal panel was **1665x546** and began at x=0; the heading's unwrapped
minimum width was **1454 px**, so the 800 px request was overridden and Close sat
at x=1486-1637, outside the window. At 1.0 the same panel grew to 1080 px for the
77-character title even though it fit. Cause: the shared heading had no wrapping
and the shared panel accepted an unbounded child minimum.

`open_modal` now clamps the panel to the viewport minus a 16 px margin, wraps the
header with word-smart autowrap, places builder content in a vertical
ScrollContainer with focus-follow, keeps Close centered in the header, focuses
Close on open, and releases modal focus on close. At both scales the panel is
now **800x520** inside 1280x720. At 1.6 the title wraps to 589x165, Close stays
at x=861-1012, the content viewport is 744x282 with 420 px of content, and
Begin is reachable at y=517-566 after scrolling.

`tests/test_modal_layout.gd`: 3 tests / 46 assertions for long-title wrapping,
viewport bounds, tall content scrolling, focus-follow to Continue, short-content
bounds, full intro narration, Begin/Close dismissal, Escape, focus release and
unchanged campaign/exploration state. Whole suite **504/504 tests, 5,524
assertions, 40 scripts, exit 0**; both validators PASS. Exported candidate
`intro_modal_2026-11-13`, SHA-256
`0dc6de1b29bc084511e19dd22e525c9a842717782491c8ce7546b15a455098dc`, 144 packed
paths.

Native OS input in that executable: campaign list → party → Begin → readable
intro → mouse Close or mouse/keyboard Begin → exploration with movement input;
1.6 wheel exposed the final text and Begin; long titles wrapped; Settings still
opens with its Close and controls reachable. The QA harness's SendKeys Escape was
not delivered reliably, so Escape is covered by an automated InputEvent test and
native keyboard dismissal used Tab+Enter on Close.

No further start/load/play blocker was demonstrated. The UI chain is at a
coherent boundary; do not start another screen sweep. Return to foundation work
rather than cosmetic layout.

## 2026-11-13 — foundation reassessment and quest-completion idempotence

The intro-modal milestone is closed on its recorded evidence. The UI start/load/
play chain remains at a coherent boundary; no further screen sweep was run.

**Assessment of the existing foundation.**

- **Implemented and tested:** the core rules exercised by the shipped pregens and
  content (combat-start flat-footedness, attacks, ranged/melee modifiers,
  concentration and defensive casting, weapon access, shields, unarmed and
  nonlethal states, trip/prone, Cleave, turning, skills, feats in the supported
  list), the Ashwick Ferry full route with save/load and a changed post-quest
  conversation, the demo gatehouse-to-E3 loop, and the Hollow Lantern entry,
  quest, consequence and save contract. The setting material is the bounded,
  clearly labelled E3 excerpt; the gatehouse, Ashwick and Hollow Lantern are
  explicitly original/example content.
- **Implemented but not exhaustively verified:** no human playtest and no
  complete windowed replay of every campaign; Hollow Lantern has no single
  full-arc regression (its entry, quest, save and consequence are covered
  separately). These are verification limits, not demonstrated defects.
- **Missing and required by the agreed foundation scope:** none demonstrated.
  Full attacks, cover/concealment, other special attacks, advancement, save
  migration and broader authoring UX remain deferred/optional for this slice;
  treating them as mandatory would silently expand the documented scope.
- **Optional expansion:** more authored areas and encounters, full-attack and
  special-attack families, cover/concealment, advancement, and richer setting
  material.

**Selected bounded defect.** `QuestLog.sync_flags()` treated a completed quest
as complete again on every later flag synchronization and returned a second
`Quest complete: ...` message. `GameSession._sync_quests()` logs every such
message, so a resolved quest could be described as newly complete after a later
interaction or effect. This is a player-facing progress-reporting error, not a
reward, save or campaign-state change. The authoritative project contract is in
`TRACEABILITY.md` row 38 (quest persistence is an Adapted original-design rule)
and the campaign-creator help text: objectives complete only after their quest
starts, and a completed quest ends the campaign only when it is the selected
completion quest. No printed D&D rule is being reinterpreted here.

**Reproduction and correction.** The focused regression in
`tests/test_quest_log.gd` failed before the change with
`ARRAY(["Quest complete: The Watch"]) != ARRAY([])` on the second sync. The
smallest correction is an explicit completed-state guard in `sync_flags`; the
transition is now reported once and later syncs return no changes. No quest
content, flags, rewards, victory conditions, saves or setting prose changed.

**Verification.** Focused regression **2 tests / 15 assertions**, PASS after the
guard. Full suite **506/506 tests, 5,539 assertions, 41 scripts, exit 0**;
`--validate-campaigns` PASS and `--validate-diagnostics` PASS. Candidate
`builds/qa/candidates/quest_log_idempotence_2026-11-13/` (110,586,088 bytes,
SHA-256 `3f85c47ff9355b9e5efb135b4a9d2f784be5c00ec5228a2f83809ae869302b23`)
passes exported `--quest-log-probe` 6/6, including the live `ravenloft_demo`
completion count remaining at one after a second sync. Package: 144 paths, zero
development/test/doc/build/profile paths.

**Limits.** The probe is an automated state/log check against the real session
path, not a human playtest. It does not replay the campaign UI. No further
material foundation defect was demonstrated in this assessment.

## Bounded correction — party contract and Ashwick minimum (2026-11-14)

**Scope.** The Ashwick assessment is accepted with one qualification: its
tested defeats show composition risk under the recorded conditions, not
mathematical impossibility or complete balance validation. This batch applies
the smallest fix the assessment recommended and nothing else.

**Defect.** `party.min` was validated on load but ignored at runtime:
`GameSession.new_game()` checked only `max`, and party selection hard-coded
"non-empty and ≤ 4". Ashwick declared `min: 1`, so one or two characters could
begin a campaign whose only `ivo_token` comes from the mandatory
drowned-ferrymen victory effects.

**Correction.** `GameSession.party_limits()`, `party_size_error()` and
`party_range_text()` are now the single interpretation of a campaign's declared
range (authored fallback 1–4, the values validation accepts). Party selection
shows that range, disables Begin with the reason when the selection is out of
range, and refuses in the same words; `new_game()` checks the requested party
against the requested campaign before it commits a campaign switch or any session
state, so a refused request leaves the live campaign, party, quests, position,
seed, RNG and save files untouched. Ashwick now declares `min: 3` and its
description states the designed party size.

**Why three.** All ten three-character subsets of the five pregens were driven
through the real mandatory encounter with ordinary weapons, spells, turning,
healing and one carried potion each: 10/10 victories at seed 11 (2–11 rounds) and
10/10 at seed 4242 (2–6 rounds). The weakest row (sera+aldric+ysolde) needs 11
rounds and two potions at seed 11. This supports three as a reasonable authored
minimum; it is bounded evidence, not a win guarantee, and no monster, rule or
other content was touched.

**Compatibility.** `version` stays 2. `party.min` is a new-game restriction: it
does not itself invalidate an otherwise compatible existing save. Loading still
applies the documented save-format and content-safety refusal checks (save
version, campaign identity, `content_version`, area/position/quest references),
which are unchanged. A version-2 Ashwick save holding two characters still loads
(focused regression). New-game eligibility and save-load compatibility are
deliberately separate; no migration or load-policy change was made.

**Verification.** `tests/test_party_limits.gd`: 8 tests / 91 assertions, PASS.
Full suite **525/525 tests, 6,054 assertions, 43 scripts, exit 0**;
`--validate-campaigns` PASS and `--validate-diagnostics` PASS. Additive candidate
`builds/qa/candidates/party_min_2026-11-14/` (110,634,608 bytes, SHA-256
`87f94b96653402b161aaa1d7fe0fecff27f9292f536a0dfa5384975c7a0f84a4`) passes the new
`--party-limits-probe` 22/22 in that exact executable at 1280×720 and 1.6× text.
That is an automated party-screen probe; ordinary native-input verification of
this change was not performed. Package: 186 paths, no tests, tools, docs, builds, addons or profile output.
Evidence: `builds/qa/runs/2026-11-14_party_min_check/`.

**Limits.** Two seeds, one scripted policy, no human playtest, no full native
adventure replay and no balance validation. Turning, kiting and readied actions
were not optimized, so the composition result is a lower bound on capable play.

**Post-checkpoint wording.** The sealed checkpoint
`builds/qa/snapshots/2026-11-14_party_contract/` is preserved unmodified; its own
CHECKPOINT.md predates the two clarifications above and is superseded by this
paragraph where they differ.

## Bounded correction — application option guard (2026-11-14)

**Scope.** One reproduced CLI defect plus the documentation reconciliation it
required. No rules, content, save format, campaign or UI behaviour changed.

**Defect.** Unknown application options had no rejection path: the dispatch in
`Main._ready()` matched nothing and the interactive game started, so a typo
looked like a hang. `--validate-content` — named in `ROADMAP.md` but never
implemented — reproduced it.

**Correction.** `Main.APP_FLAGS` / `Main.APP_VALUE_OPTIONS` declare the supported
vocabulary and `Main.application_arg_error()` produces an actionable message with
the closest alternatives; `_ready()` prints it and exits **2** before any screen
is shown. Valid commands, exported probes, value options and Godot's own engine
arguments are untouched. Exit status is now 0 (ran), 1 (ran, check failed),
2 (bad invocation).

**Documentation reconciled.** Feat counts corrected to the actual 41 entries
(`SUPPORTED_FEATURES.md`, `ROADMAP.md`); the `--validate-content` instruction
replaced with the working validators; completed roadmap items marked **Done**
with their numbers kept as history; `SETUP.md` test and export claims brought to
the current boundary; `EDIT_COPY.md` records which tree is the development
authority. `workspace/README.md` still names the original as the only edit
target; it is outside this copy and was not changed — see the handover note in
`EDIT_COPY.md`.

**Verification.** `tests/test_cli_args.gd` 13 tests / 209 assertions, PASS. Full
suite **538/538 tests, 6,263 assertions, 44 scripts, exit 0**; both validators
PASS. Candidate `builds/qa/candidates/cli_args_2026-11-14/` (110,637,712 bytes,
SHA-256 `e3650ecbcab429e4f23eec83976c74277b181e2842f26ad93ee361503cc45262`) was
checked headless: unknown options exit 2 with the refusal, valid validators exit
0, a no-argument launch exits 0, and `--quest-log-probe` / `--party-limits-probe`
still pass in that executable. Checkpoint:
`builds/qa/snapshots/2026-11-14_cli_args/`.

**Limits.** No window was opened and no gameplay was replayed. Git adoption and
independent backup storage remain open operational decisions; nothing was
committed, staged, moved, deleted or published.

## Player-view assessment - Ashwick Ferry (post-checkpoint, assessment only)

An informed evaluator pass ran against the accepted candidate
(`cli_args_2026-11-14`, SHA-256 `e3650e...`), windowed at 1280x720 with text scale
at 160 %, a disposable profile, the party Kaelen / Aldric / Ysolde, and ordinary
external mouse input. Run 1 reached the boathouse ledger, the tack-room key, the
mandatory encounter and the bell token, then stopped on the truth account at Maela.
Run 2, restarted for the mercy account, was defeated in that encounter; run 3,
loaded from the only autosave, stopped mid-encounter. The mercy account in a
playable state, the bell, the specific epilogue, the completed Journal and the
repeatable post-ending conversation were **not** reached and remain unverified.
**Update, same day:** all five were subsequently reached through ordinary windowed
play on the accepted `account_decision_2026-11-14` candidate; see *Silent-bell
route completed through ordinary play* at the end of this file.

Recorded findings: at 160 % Maela's decision list shows the truth rows but hides the
mercy statement below the fold, while either row commits a terminal choice that
cannot be revisited; the Journal prints raw flags (`maela trust`, `ledger found`)
instead of events and does not separate known facts from open questions; the
optional page needs Open Lock and the only lockpicker, Sera, was dropped by
this party (a three-character party may include her); refusals scroll out of the
two-line exploration log;
the party card still claims turn undead is not implemented while combat offers it;
long area titles clip the right-hand control column. The defeat screen and the
combat reach / damage-reduction messages are clear. Two corrections are judged
worth making (mercy-row visibility, cleric copy); none were applied. Details and
evidence shots: `docs/TEST_REPORT.md`,
`builds/qa/runs/2026-11-14_ashwick_player_view/`.

## Correction batch — inspection triage and account decision (post-checkpoint)

The reported combat turn loss did not reproduce: a party token opens the
character sheet and the encounter is untouched; the lost turn in the assessment
came from the clicks after it. That is now pinned by eight checks added to the
existing `--demo-inspect --inspect-probe` (they pass in source and candidate; the
probe keeps five pre-existing layout failures that also fail without the new
(recorded here at the time as seven; corrected against the saved baseline log on
2026-11-20)
block).

Maela's account became a deliberate decision, in content only: one named entry,
a dedicated page that states the account is what she will keep, the truthful
account, the evidence-aware variant when the page is found, the fabricated
passenger account, and a noncommitting way back. Only the explicit choice commits,
and it stays mutually exclusive and once-only; consequence nodes and epilogues are
unchanged. The cleric's note no longer claims turn undead is unimplemented
(orisons genuinely are). Both commitment paths were verified natively at 1280x720
with text at 160 %, from two separate pre-decision saves.

Boundary: **541/541 tests, 6,364 assertions, 44 scripts, exit 0**; both validators
PASS; candidate `account_decision_2026-11-14` (110,642,032 bytes, SHA-256
`022817be…565e3980`) with a 186-path package; checkpoint
`builds/qa/snapshots/2026-11-14_account_decision/`. Content version stays 2 — no
flag, quest, node or area id changed, and a pre-fix v2 save loads and plays — so
an old save keeps the old note text, which was checked rather than assumed.

Still open, untouched: Journal flags, exploration feedback, header clipping,
optional-page party dependency, and the silent-bell ending which remains
unverified through ordinary play.

## Silent-bell route completed through ordinary play (post-checkpoint)

Documentation only, on the accepted `account_decision_2026-11-14` candidate
(SHA-256 `022817be...`), at 1280x720 with text at 160 %, ordinary mouse input.
Continued from a disposable copy of an ordinary-play save (landing, three
adventurers, tack room cleared, token held, no account decided), selected mercy
through the normal UI, then played the remaining route: the bell, *Break the token
and leave the bell silent.*, the narration sending the player back to Maela, the
silence epilogue (reached by scrolling to *Tell me what the silence means for the
ferry.* and then *Let her keep the story she has.*), the objective panel going
**Complete**, the completion modal, a Journal listing *Completed: The Ashwick
Ferry, The Passenger's Story* with its recorded events, and a repeat conversation
that offers a short post-ending line instead of replaying the finale.

Judged: the silence choice is understandable before commitment (each row names
action and outcome), mercy and silence are acknowledged together in the epilogue,
direction back to Maela is explicit, completion is unmistakable, and the finale
does not replay. Two clarity gaps were observed and left unfixed, recorded as
assessment findings rather than approved content changes: nothing warns that
breaking the token spends it for good, and the silent-route epilogue row sits
below the fold at 160 %, which is a discoverability refinement rather than a
blocker. The retained Journal raw-flag exposure is visible again in the completed
Journal.

The player-view assessment is therefore **closed** for its stated gap (mercy, the
silent-bell resolution and its ending, all now observed through ordinary play),
with these limits: one outcome on one party; ring-twice, defeat, page-after-mercy
and post-ending save/load still rest on the focused automated suite; ring-once was
not exercised in this pass but has earlier native evidence on a different
executable (`ashwick_second_ring_2026-11-14`, SHA-256 `457e3b88...`), which was
not rerun; no human playtest or balance judgement. No suite, validator, package audit
or checkpoint was produced for this pass — the 541/541 and eight-inspection
results belong to the earlier implementation boundary, and the windowed probe's
five known layout failures (recorded as seven at the time; see the 2026-11-20
reconciliation) are unchanged and reported, not fixed.

Accepted and closed. No further implementation or verification work is authorized
for this assessment; the epilogue placement and the bell-page wording stay
recorded as a discoverability refinement and as assessment findings.

## Bounded correction — UI scaling (2026-11-20)

**Scope.** Layout and scaling only: `project.godot` display settings, the window
floor, page minimums, modal/dialogue sizing, one readout width, and the layout
tests that pin them. No content, rules, save format, quest/journal text or other
behaviour changed. Earlier milestones, sealed checkpoints and accepted candidates
are untouched.

**Defect (reproduced, assessment only, 2026-11-15).** The UI was always composed in
a fixed 1280x720 logical canvas and then magnified (`stretch/mode="canvas_items"`,
`aspect="expand"`), while the Settings text scale only enlarged fonts. At 160 %
text, at 1280x720 and at every larger 16:9 size: the exploration location label
overlapped the 3D view and the newest log line was cut; the combat right column
(Pause, actions, Inspect/Attack) was pushed past the client edge; the dialogue
panel ran past both client edges; Settings showed about a third of its content in
a fixed 760x540 box and the "Cannot save now" dialog clipped its own sentence; the
text-size readout wrapped to "160" / "%"; and fullscreen reported a 1920x1082
client on a 1920x1080 display. A taller logical viewport (1280x980) fixed the
vertical clipping and a wider one (1600x720) the horizontal, which identified the
fixed base canvas rather than one bad offset.

**Correction.**

1. `display/window/stretch/mode="disabled"`: the client area *is* the layout
   surface, so a larger window or fullscreen adds logical room instead of scaling
   a fixed canvas. `get_window().min_size` stays 1280x720, so 1280x720 is the
   supported minimum and fullscreen is exactly the display size (no 1.5028 scale).
2. Page minimums that could not shrink: exploration view 360->140 and log
   140->80 (the log scrolls inside its panel), the exploration title now wraps
   instead of competing with Gold/Seed/Pause, combat view 420->140, log 150->90,
   initiative panel 150->90 and target list 120->96.
3. The dialogue panel's minimum is capped to the client and re-clamped on resize
   instead of being computed once at build time.
4. `open_modal` scales its requested size by the text scale and then caps it to the
   client; `refresh_modal` re-uses the size the caller asked for instead of
   resetting every modal to 760x540.
5. The text-size readout is sized by its own text (no fixed 52 px column); the
   Settings list clears the scrollbar; the character sheet's tab page has a top
   margin so the tab strip cannot sit on its first line.
6. Headless CI pins its dummy window to 1280x720, since the client is now the
   layout surface; without it the layout tests measured a 64x64 dummy.

**Verification.** Full suite **550/550 tests, 6,403 assertions, 45 scripts, exit
0**, including the new `tests/test_layout_scaling.gd` (9 tests) which lays pages
out at 1280x720 and asserts that nothing escapes the client and that the dialogue
panel and modal requests stay capped. Both validators PASS.

New `--layout-probe` (with `--layout-scenario=screen|settings|inspect|dialogue|
fullscreen`, `--probe-size`, `--text-scale`) asserts every visible interactive
control is inside the client or reachable through a ScrollContainer, and that no
wrapping-off label is allocated less width than its text. It passed **32/32** runs
across 1280x720, 1600x900 and 1920x1017 at 100 % and 160 % for exploration, combat,
dialogue, Settings and the inspect modal, plus fullscreen at 1920x1080 for both
scales (a 1920x1082 client would now fail).

`--demo-inspect --inspect-probe` now **PASSES**: its five failing checks of 49
(44 pass, 5 fail) were the combat sidebar's controls being laid out outside the
1280x720 client. The passing run executes 53 checks, not 49: four `close modal`
assertions only run once a sheet opens, and the duelist's sheet never opened
before the fix. No check was relaxed or removed. The earlier "seven" in this file
and in `TEST_REPORT.md` is unsourced by the saved logs; the reconciliation is in
`TEST_REPORT.md` (2026-11-20). `--party-layout-probe`, `--intro-layout-probe`,
`--campaign-list-probe` and
`--party-limits-probe` also PASS (the first three need their QA fixture
profile, as before).

Candidate `builds/qa/candidates/ui_scaling_2026-11-20b/RavenloftFoundationEdit.exe`,
110,647,296 bytes, SHA-256
`6d38c18d8f533a245343ae4df9731e7ae41ad27e2d7b7477c4b2c5a17435dbd7`, built from
worktree `a64eead` + the changes above. Its own `--list-campaigns`,
`--validate-campaigns`, `--validate-diagnostics`, `--inspect-probe` and the layout
matrix were run windowed with an isolated `APPDATA`; results are in
`builds/qa/runs/2026-11-20_ui_fix/acceptance.log` with captures in
`.../accept/shots/`.

**Limits.** No human playtest and no subjective judgement of the new proportions.
Keyboard-driven flows still cannot be injected through the headless/Windows
harness, so keyboard-only reachability rests on the construction tests. Windows
display scaling other than 100 % was not exercised (it needs a system-wide change)
— if a player's failure comes from OS DPI rather than the text slider, it remains
unverified. Journal raw-flag rendering, exploration log length and the
"Recorded world events" heading overlap seen once at 100 % are outside this
correction and unchanged; no checkpoint was created for it. The notes and the
heading were addressed later on 2026-11-20 (see "Journal notes" below).
## Journal notes: authored facts and open questions (2026-11-20)

**Scope.** Player-facing Journal notes only: an optional `journal.json` per
campaign, its loader and validator, the Journal's rendering, one layout-probe
scenario and the tests that pin them. Quests, flags, rules, dialogue, encounters
and the save format are untouched — `SAVE_VERSION` stays 1, `Game.serialize()`
is unchanged, and the Journal only *reads* `Game.flags`.

**Defect.** "Recorded world events" printed every truthy flag as an internal id
(`ledger found`, `maela decision`, `last page shared`), alphabetically, with no
prose and no separation between settled events and open questions. Two further
flaws were found while assessing it: `if keys.is_empty()` tested for keys rather
than true values, so a save holding only false flags produced an empty heading,
and the heading's apparent overlap was synthetic bold — `[b]` in a RichTextLabel
whose font has no bold face is drawn as an offset embolden pass, which reads as a
doubled line at heading sizes. Both were reproduced in isolation
(`builds/qa/bold_probe.png`) before being fixed.

**Correction.**

1. `content/campaigns/<id>/journal.json`: authored `facts` (`flag`, `text`,
   optional `conflicts_with`), `questions` (`text`, optional `revealed_by` and
   `resolved_by`) and `internal` bookkeeping flags, with `format_version: 1`.
2. `ContentDB` loads the file when present, exposes `authored_flags()` (every
   flag the campaign's dialogue, areas, encounters and doors can set) and
   validates entry types, format version, flag references, duplicates, a flag
   that is both fact and internal, self-conflicts, and a question revealed and
   resolved by the same flag.
3. `Panels.journal_notes()` is the pure selection step: facts appear once their
   flag is true, in authored order; `conflicts_with` is resolved by authored
   order (first fact claims the pair, later partners are suppressed), so a
   corrupted save holding both halves renders one deterministic line. Questions
   appear while `revealed_by` is true (or absent) and `resolved_by` is false.
4. The Journal renders "What you know" and "Still open", hides a section with no
   lines, says "Nothing recorded yet." when notes exist but nothing is earned,
   and adds nothing at all when the campaign has no notes file.
5. Headings use `[font_size]` and gold instead of `[b]`, removing the synthetic
   bold that caused the doubled heading.
6. `--layout-scenario=journal` seeds one fact and one revealed question, then
   checks both section headings, every expected fact line, the absence of raw
   flag ids, and that the body's ScrollContainer is inside the client.

**Wording decisions.**

- Notes are past tense and second person ("You rang the bell once..."), matching
  the exploration log; no numbers, rules terms or destinations appear in them.
- No "(ORIGINAL PLACEHOLDER)" prefix in notes: the campaign title and its
  narration already carry that banner, and prefixing every Journal line would
  read as shouting. Notes restate details the content already establishes
  (the ledger, the receipt, the notice) instead of inventing new lore.
- One fact per flag, so a save cannot show the same event twice. Where two
  outcomes are exclusive (`maela_truth`/`maela_mercy`, `maela_trust`/
  `maela_refused`, `ferry_bell_rung`/`bell_silenced`, `bell_called`/
  `bell_silenced`, `warden_pact`/`warden_destroyed`) both sides declare
  `conflicts_with`.
- The mercy fact says what the player did ("...and let her keep that"), not that
  it is true; the truth fact names the debt. Neither implies the other happened.
- `bell_resolved` is set on both endings, so its line says "the crossing has its
  answer" rather than naming which one.
- Bookkeeping flags are `internal`: `maela_decision` (the chosen account is
  already a fact), `maela_spoken_once`, `ivo_rested` (covered by the ring), and
  the door flags (`tack_room_door_open`, `crypt_door_open`, `store_door_open`).
- Questions are phrased in-world and never name a flag or a destination. Their
  `revealed_by` flag is the moment the question becomes askable (reading the
  notice, hearing about the ledger, committing to an account); their
  `resolved_by` flag is the moment it is answered.
- One question for Hollow Lantern: the campaign sets four flags and has one real
  mystery, so a second question would have had nothing to resolve it.
- The demo's "what became of Thendrick and Mathilda" was left out: no flag in
  that campaign answers it, and a question that can never close is worse than no
  question.

**Verification.** Full suite **562/562 tests, 6,523 assertions, 46 scripts, exit
0**, including 12 new tests (coverage of every authored flag, authored order,
raw-id absence, reveal gating, resolution, conflicts in both directions, empty
states, a missing notes file, malformed-note validation, and a save round trip
that asserts `save_version` stays 1 and no journal key is written). Both
validators PASS. `--layout-scenario=journal` passes **6/6** runs across
1280x720, 1600x900 and 1920x1017 at 100 % and 160 % (18 controls, 0 failures),
with captures in `builds/qa/runs/2026-11-20_journal/shots/`. `--inspect-probe`
still PASSES (53 checks), and the exploration screen still passes at
1280x720/160 %.

**Limits.** No human playtest; the wording was reviewed as text against the
content it restates, not by a player. Journal length is bounded by content: a
save with every flag set shows every authored fact, and at 160 % that needs
scrolling (the scroll container is bounded and counted by the probe). Campaigns
written in the creator without a notes file show the quest log alone — the
creator does not author notes yet. The coverage rule that every settable flag
must be a fact or internal is enforced by the test over shipped campaigns, not
by the runtime validator, so a creator package may leave flags unexplained
without failing to load.
## Candidate journal_2026-11-20 and an exploration-feedback assessment (2026-11-20)

**Candidate.** `builds/qa/candidates/journal_2026-11-20/RavenloftFoundationEdit.exe`,
110,662,552 bytes, SHA-256
`d3070eae4878c85884d374b83561865cf9f3f14fda2fc1d2a2174dfd4816ca79`, exported
from `3dc28cc` with a clean worktree. Exported acceptance (isolated `APPDATA`,
real windows): list, both validators, `--inspect-probe` (53 checks), the journal
layout scenario at 1280x720 on 100 % and 160 % (18 controls, 0 failures each),
`--save-compat-ui-probe`, and two fixture campaigns for the empty states —
**7/7 runs, 0 failures**; details in `TEST_REPORT.md` (2026-11-20) and
`builds/qa/runs/2026-11-20_journal_accept/acceptance.log`.

**Assessment, not implemented: exploration refusal and skill feedback.**

- Refusals that only set `Game.last_ui_message` and never call `_log()`:
  moving into a wall, a closed door or an NPC (`game_state.gd:813`, `:817`,
  `:821`), "There is nothing within reach." (`:858`), "No one can pick the lock."
  (`:892`), "There is nothing left here." (`:936`), "You find nothing you can
  use." (`:954`), "No conscious adventurer can attempt that." (`:964`).
- `last_ui_message` has no reader outside `game_state.gd`, so those strings
  reach no label, log or tooltip. `ExplorationScreen._do()` discards the result
  dictionary it is handed (`exploration_screen.gd:180`), and the keyboard
  interact path discards it before that (`:331`).
- Measured in a headless run: a blocked move returns "Cold stone blocks the way."
  with `log_lines` unchanged (6 -> 6); interacting with the same wall logs
  (6 -> 7). So an invisible refusal sits next to a visible one.
- Skill results are not lost: lock-picking and object checks log their line
  (`game_state.gd:911`, `:990`) into the exploration log, and dialogue checks
  render inside the dialogue panel (`dialogue_panel.gd:112`).
- Smallest fix proposed for a later unit: a `_refuse(text)` helper that sets
  `last_ui_message`, appends to the log only when the line would not repeat the
  previous entry, and returns the failure dictionary; the eight silent sites
  above call it. No rules, content, save or layout change. Not implemented.
## Exploration refusals are visible now (2026-11-20)

The silent-refusal assessment became a small unit: `GameState._refuse(text)`
sets `last_ui_message`, logs once (suppressing a consecutive identical line) and
returns the same `{"ok": false, "message": text}` dictionary. The eight sites
identified earlier route through it; the wall description and skill-check
results still log as before. No rules, content, layout or save change.

Tests: `tests/test_refusals.gd`, 12 cases (every family, dedupe, the result
shape, both input paths). Suite **574/574, 6,591 assertions, 47 scripts, exit 0**.

The new `--layout-scenario=refusal` probe makes the difference between *logged*
and *on screen* checkable: presence in `Game.log_lines`, presence in the log
widget's text, the widget inside the client, no modal over it, and at least one
visible line. It also captures the frame, so the 100 % and 160 % runs can be
looked at rather than inferred.
## Native interaction verification and two defects (2026-11-20)

The refusal candidate was driven with OS-level input instead of function calls
(`tools/native_input.ps1`: topmost window, real click for focus, `keybd_event`
with scan codes, `mouse_event` wheel and clicks, client-area captures). At
1280x720 on 100 % and 160 %: movement, interaction, the blocked-move line, log
wheel scrolling, Tab traversal, Enter activation and the Journal's Close button
(mouse and Enter) all pass; the Journal body's wheel scroll could not be checked
because the demo notes fit the modal — manual steps are in the test report.

Two pre-existing defects are recorded rather than fixed: an open modal does not
trap Tab (two Tabs reach "Turn left (Q)" behind it, and Enter turns the party
while the Journal is open, at both scales), and closing a modal leaves no
control with visible focus. Neither is caused by the refusal logging.

The `.uid` question is settled: `tests/*` is excluded from the preset and the
candidate contains no test script names, so the untracked sidecar did not touch
the build. It is committed now (`b203a1d`).

## Modals own their focus now (2026-11-20)

The two focus defects recorded yesterday are fixed: Tab and Shift+Tab cycle only
the active modal's controls and wrap, background activation is swallowed, and
closing returns focus to the opener (or the screen's first usable control),
including across a refresh or a modal opened from another modal. The rebind
capture keeps priority.

`tests/test_modal_focus.gd` adds 12 cases and two layout assertions were
retargeted from "focus released" to "focus restored". Suite **586/586, 6,640
assertions, 48 scripts**; exported candidate `modal_focus_2026-11-20` passes
9/9 acceptance runs (validators, Inspect, journal and refusal layouts at both
text scales, save-compat UI).

Native input confirms the reported Tab-twice/Enter sequence now closes the
Journal and leaves the party where it stood, at 100 % and 160 %. Journal wheel
scrolling, previously unverified because the demo notes fit the modal, is proven
with a 70-question user fixture at both scales. Shift+Tab is verified natively at
both scales; the earlier harness limitation was the action-matching bug fixed in
`b5dfd9b`, not the injection path, so that manual step is withdrawn.

## Keyboard modal scrolling assessed; Shift+Tab verified (2026-11-20)

Keyboard scrolling of modal text is missing: the body `ScrollContainer` is
`FOCUS_NONE`, Tab never reaches it, and PageUp/PageDown or arrows leave an
overflowing Journal exactly where it was at 160 % (verified with the 70-question
fixture). Arrows also drop the visible focus ring, though Enter there stayed
inert and the world was unchanged.

The smallest fix is proposed here and was implemented the same day (last section): reference the modal body,
handle PageUp/PageDown as a page and Up/Down as two lines in `_input`, mark them
handled, and leave focus, activation, rebind capture and Escape untouched. The
tests this fix needs are defined in the report.

Shift+Tab is verified natively at 100 % and 160 % on the current candidate; the
earlier harness limitation was the action-matching bug, now fixed, so the manual
step is withdrawn.

## Keyboard scrolling of modal text (2026-11-20)

The proposed fix is implemented. `open_modal` keeps `modal_scroll`, `_input`
handles PageDown/PageUp as 90 % of the visible page and Up/Down as two
text-scale-aware lines before the Tab branch, and any control that needs those
keys (a caret, a number field, a slider, a list, a tree) keeps them. Focus never
moves, a fitting body does not move, and the key is consumed either way so an
arrow cannot fall through to traversal and take the ring off the modal.

Measuring the real Journal corrected the proposal: `Panels.journal()` wraps its
text in its own `ScrollContainer`, so the shared body fits exactly (travel 0) and
the first implementation scrolled nothing - six native frames, byte-identical.
`_modal_body_target()` now prefers the shared body when it travels and otherwise
the first visible inner one that does (the Journal's inner body travels 2961 px).

Tests: 13 new cases in `tests/test_modal_focus.gd`; suite **599/599, 6,690
assertions, 48 scripts, exit 0**. Validators and the Inspect probe pass. Exported
candidate `modal_scroll_2026-11-20` (`0c2f982e`, 110,667,352 bytes) scrolls the
70-question Journal natively at 100 % and 160 % with PageUp/PageDown and the
arrows, keeps the ring on Close, returns to a byte-identical top frame, and closes
on Escape; export acceptance 9/9.

Limits: no key repeat while holding; gamepad page keys are not handled; the
arrow-owning control list is maintained by hand (`OptionButton` is not on it);
only one inner scrolling body is chosen; focus retention is asserted in unit
tests and inferred natively from the ring, because the harness cannot read the
focus owner.

## Modal pane selection and slider arrows fixed (2026-11-20)

Both gaps from the scrolling assessment are closed. `_modal_body_target()` now
picks the visible pane with the greatest vertical travel and keeps the shared body
on ties, so Settings at 100 % scrolls its 463 px list instead of a 27 px wrapper
(reach 27 -> 463 px, unreachable 436 -> 0); and `HSlider` and `TabBar` left the
arrow exemption, so Up/Down scroll from them while Left/Right still adjust the
slider and switch tabs. `VSlider`, `SpinBox`, `LineEdit`, `TextEdit`, `ItemList`
and `Tree` keep the keys. Before the change a Down from a volume slider moved the
ring to the Fullscreen check box (100 %) or the "D" rebind button (160 %); now the
ring stays and the list moves.

Five tests were added to `tests/test_modal_focus.gd`: wrapper-and-list shape,
long body with a short inner list, focused horizontal slider, focused tab bar, and
a vertical slider keeping the arrows. Suite **604/604, 6,720 assertions, 48
scripts, exit 0**; both validators and the Inspect probe pass; export acceptance
11/11. Candidate `modal_pane_2026-11-20` (110,667,640 bytes, `6217fe39`) was
verified natively at 100 % and 160 %: PageDown x4 reveals the last rebind row and
"Restore Default Controls", further PageDowns are byte-identical at the end, the
music slider steps 55 -> 70 % on Right with Down scrolling two lines per press and
Up returning to the identical frame, and the party tab strip switches on Right
and scrolls on Down.

Recorded limits: Settings still clips its last ~27 px through the wrapper's own
minimum-size overflow (the list is at its end, the wrapper never moves); inner
panel lists do not follow focus, so Tab can land on a row below the fold (Enter
still activates it); one pane is chosen per scroll; `SpinBox` remains exempt
although Godot 4.7 ignores Up/Down for it; gamepad page keys and key repeat remain
out of scope.

## Settings clipping and off-screen focus fixed (2026-11-20)

Both limits from the pane-selection unit are closed. `Panels.settings()` no longer
gives its content root a 720x480 minimum - at 100 % text that overflowed the 453 px
body by 27 px, and because the keys and the wheel both moved the list inside, the
strip never scrolled and cut the bottom of "Restore Default Controls". The root now
sets only a width, so the body fits (travel 27 -> 0) and the list gets the whole
height (463 -> 490 px at 100 %, 679 at 160 %).

Focus now reveals itself through nested panes. `_reveal_modal_focus()` walks from
the focus owner up to the modal and adjusts every `ScrollContainer` on the way,
asking each wrapper to show the pane inside it rather than the deep control, with
an 8 px pad and clamping at each pane's own travel; it stops at a popup `Window`, so
a confirmation dialog keeps its own geometry. It is driven by the viewport's
`gui_focus_changed`, so Tab, Shift+Tab, a click and a control grabbing focus itself
all reveal the row. On the real Settings at 100 %, Tab x18 put "Restore Default
Controls" at y = 1043 outside a 163-616 body before; it now scrolls the list to its
end and the row sits at y = 580, fully visible, while Enter still opens the
confirmation over an unmoved list.

Four tests were added (body fits and the list reaches its last row; Tab reaches that
row visibly at both scales with Shift+Tab walking back; a nested-list button is
revealed and un-revealed while the wrapper and focus containment hold; a popup
leaves the list at its offset). Suite **608/608, 6,767 assertions, 48 scripts, exit
0**; validators and the Inspect probe pass; export acceptance 11/11. Candidate
`modal_focus_2026-11-20` (110,668,280 bytes, `42b003c9`) was verified natively at
100 % and 160 %: the whole Restore button is visible at the end of the list, Tab x18
puts the ring on it with the list scrolled, Shift+Tab moves the ring to the row
above with the list one step up, Tab returns to a byte-identical frame, and the
confirmation opens and closes without moving the list.

Remaining limits: the reveal runs only while a modal is open (the campaign creator
keeps its own scrolling); a control taller than its pane is aligned to the pane's
top and can still be clipped; one pane follows the focus per key press; the shared
body keeps `follow_focus` alongside the new walk; no key repeat, and no reveal if a
pane is re-laid out while the focus owner is unchanged.

## Candidate audit, migration readiness and status split (2026-11-20)

**No candidate replaced another.** Three distinct builds sit under
`builds/qa/candidates/` and every on-disk hash matches its `BUILD.txt`:
`modal_scroll_2026-11-20` (built 17:46:48, head `2b3ba36`, 2 dirty entries,
110,667,352 bytes, `0c2f982e`), `modal_pane_2026-11-20` (18:03:47, head
`1d89925`, 2 dirty entries, 110,667,640 bytes, `6217fe39`) and
`modal_focus_2026-11-20` (18:18:04, head `60c1221`, 3 dirty entries, 110,668,280
bytes, `42b003c9`). The three worktree diff hashes (`d5ace748`, `3842d180`,
`cdd57a78`) differ, so each is its own source state; `modal_focus` is the newest,
not a relabel of `modal_pane`. Nothing was overwritten or deleted.

Each result is now tied to a build: the 9/9 acceptance and Journal frames to
`modal_scroll`; the 11/11 acceptance, the 27 px reproduction frames (`settings10`)
and the pane/slider/party frames to `modal_pane`; the 11/11 acceptance and the
`focus1.0`/`focus1.6` frames to `modal_focus`. GUT suite logs and probe output are
source-tree runs and support no binary. Attribution rests on BUILD.txt timestamps,
each run's `EXE=` path and frame mtimes, because frames do not embed the exe hash.

**Missing artifacts, recorded not repaired.** None of the three runs wrote an
`acceptance.log` - the scripts print their summary and keep per-check logs only -
so the three earlier citations were corrected. The focus candidate also carries a
stale `export.log` (16:48, before its 18:18 build) with no build id, and the pane
and focus native frames sit one run directory behind their acceptance runs
(`scrollfix/native` and `panefix/native` respectively).

**Status split.** Closed UI defects, each with the build that proves it: the
unreachable Settings list and the HSlider/TabBar traversal (`60c1221`, verified on
`modal_pane`), and the clipped last 27 px and the off-screen focused row
(`01ced3a`, verified on `modal_focus`). Remaining limits are unchanged: reveal only
inside modals, controls taller than their pane align to its top, one pane follows
focus per key press, `follow_focus` stays beside the reveal walk, no key repeat or
gamepad page keys, and no consolidated acceptance log for these runs.

**Migration readiness (assessment only, nothing implemented).** Saves are
version-refused rather than migrated: `SaveSystem` requires `save_version == 1`
before validating, `load_game` refuses a `content_version` mismatch, the payload
is validated against content ids and shapes before any live state changes, writes
are atomic with a `.bak` that is never read back, and settings are an unversioned
`ConfigFile` that is rewritten from a fresh object (so unknown keys are dropped)
and whose `text_scale` is not clamped on load. The smallest design - a read-only
migration table with a version floor, content version kept as a refusal, a settings
`meta` section that merges instead of rewriting, and one fixture per step - is
written out under ROADMAP P0 item 4, marked proposed and not implemented.

## Provenance resolution and migration foundation (2026-11-20)

**Provenance.** The earlier `modal_focus_2026-11-20` build (`fe7511b3...`,
110,665,048 bytes, source `b5dfd9b`) is **missing**: re-hashing every `.exe` under
`builds/` finds no match, and `runs/2026-11-20_modal/export/` holds logs only. The
candidate directory name was **reused** by the 18:18 export (`42b003c9`), which
overwrote it; the stale `export.log` (16:48) is the surviving trace. Earlier
results stay documented but cannot be re-verified. Nothing was deleted or
renamed.

**Save migration foundation, no version bump.** `src/core/save_migrations.gd`
adds the read-only table (`steps` empty in production, `SUPPORTED_MIN_VERSION = 1`,
test-only target override) and `SaveSystem.read_save` now upgrades in memory or
refuses with the unchanged message, never writing on load. `SAVE_VERSION` stays 1
and no production step ships; tests drive everything with synthetic steps
(1 -> 2 -> 3 chains, unknown fields, missing/refusing steps, below-floor and newer
versions, byte- and live-state preservation).

**Settings versioning.** `settings.cfg` records `[meta] version = 1`; loads clamp
volumes to 0-1 and `text_scale` to 0.8-1.6 and parse flags explicitly; writes merge
into the loaded file so unknown sections, keys and bindings survive; a file from a
newer build is read but never rewritten (`settings_newer`), which is the policy for
newer settings now defined before any write. Unknown keybind actions are kept but
not applied.

**Verified.** 15 new tests; suite **623/623, 6,842 assertions, 50 scripts, exit
0**; `--validate-campaigns`, `--validate-diagnostics`, the Inspect probe and
`--save-compat-ui-probe` all PASS in source.

**Export.** `migration_2026-11-20` was built at 18:43:43 from commit `93e8199`
with `worktree_entries=0` and no untracked files - 110,670,872 bytes, SHA-256
`00136308f9a3237504daa89da37db782105b75b3289b2baea08dd0378dbada71` - and its
11/11 acceptance log records that hash at both ends
(`builds/qa/runs/2026-11-20_migration/acceptance.log`).

**Read-only Settings notice and conservative save recovery.** The Settings modal
now opens with a line above its scrolling body when `settings_newer` is set:
changes still apply for this session and nothing is written back. The line lives
outside the scroll (`modal_notice` on `Main`), so it cannot scroll away, and it
survives the panel refreshes the setters trigger.

Saves recover from an interrupted write without touching a byte. `SaveSystem`
exposes the slot's three artifacts (`artifact_paths`, `has_artifacts`,
`read_payload` with `missing`/`corrupt`/`unsupported_version`), and `GameSession`
splits the old `load_game` into `_choose_save_source` + `_prepare_save` (the
validation that always ran) + `_apply_prepared_save`. A readable primary always
wins and its refusals stand - a newer version or a content-version mismatch is
still the same refusal, never a silent downgrade to older bytes. Only a missing or
unreadable primary lets the backup and then the temp file stand in; each is
validated by the same checks and must belong to the loaded campaign, and a
recovered load names its source in the status line and keeps the panel open
because the restored game is already live behind it. `list_saves`/`_save_info`
now show a slot whose primary is gone instead of "empty", tagged
"(from backup)" / "(unfinished save)". Pre-campaign legacy saves still stand in,
but only when the campaign slot holds no artifact at all.

The write path stopped deleting files it did not create: when a crashed write's
`.bak` or `.tmp` occupies the working name, the new save takes a free working name
(numbered after the interruption audit below), removes only its own files, and
leaves crash artifacts intact on success and on failure. `save_game` also refuses to overwrite a crashed slot
whose readable leftover belongs to another campaign.

**Verified.** 18 new tests (`tests/test_save_recovery.gd`,
`tests/test_persistence_notices.gd`) plus the extended `--save-compat-ui-probe`
(backup recovery, newer-primary refusal, temp recovery) and a new
`--settings-notice-probe`; suite **641/641, 6,931 assertions, 52 scripts, exit 0**.
In source, `--validate-campaigns`, `--validate-diagnostics`, the Inspect probe,
the settings/journal/refusal layouts and the notice probe at 100 % and 160 % all
PASS.
**Acceptance.** `recovery_2026-11-20` was built at 19:08:08 from commit `accbc62`
with `worktree_entries=0` and no untracked files - 110,678,072 bytes, SHA-256
`a0e305021ac295cc958d0c97421af2652a1468c21841ceecaa44f66ed4f0b7f8` - and its 13/13
acceptance log records that hash at both ends
(`builds/qa/runs/2026-11-20_recovery/acceptance.log`). Limits are listed at the
end of [TEST_REPORT.md](TEST_REPORT.md).
**Save write interruption audit.** Every interruption point of the write sequence
was listed with the files it leaves behind; the loader now discovers every accepted name of the
slot (canonical, numbered working copies 2-100, plus the
older `.bak.w`/`.tmp.w` spelling), so a slot is no longer called empty while a
valid copy parses. Working names are reserved rather than reused, so a repeated
interrupted write can no longer truncate an earlier crash copy; within the backup
and temp tiers the greatest `saved_unix` wins (ties by name), the primary stays unconditional,
and its incompatible-version refusal, the campaign guards, read-only selection
and the preservation of surviving recovery files are unchanged. 17 new
interruption-state tests; suite **658/658, 7,113 assertions, 53 scripts**. The
state table and the remaining durability limits are in
[TEST_REPORT.md](TEST_REPORT.md).
**Acceptance.** `interruption_2026-11-20` was built at 19:21:11 from commit
`dafacd8` with `worktree_entries=0` and no untracked files - 110,679,352 bytes,
SHA-256 `4c0d699dc3a48cdac42a82b666e736302e312382f1422028a0476fc863cf488a` - and
its 13/13 acceptance log records that hash at both ends
(`builds/qa/runs/2026-11-20_interruption/acceptance.log`).
**Slot-file pattern and refusal accuracy.** `SaveSystem.parse_slot_file` is now
the single definition of what belongs to a slot: `<slot>.json`, `.bak`, `.tmp`,
numbered working copies 2-100, and the previous release's `.w` names, matched
case-insensitively but kept as distinct directory entries. Discovery, the load
list, the save panel and deletion all use it, so a stray `slot2.json.2026-11-20`
archive is not recovery, is not listed, does not block the legacy fallback and is
not deleted with the slot. Recovery rejections are classified (incompatible
version, other campaign, other content, invalid state, unparseable bytes) and the
most actionable one is reported; "No save in slot" now only means no accepted
files at all, and existing primary refusal strings are unchanged. Within a tier
the greatest `saved_unix` wins and a tie resolves canonical name first, then
lexicographic name - deterministic, but not proof of newest. 16 new tests; suite
**674/674, 7,227 assertions, 54 scripts**. Details and the exact pattern are in
[TEST_REPORT.md](TEST_REPORT.md).
**Acceptance.** `pattern_2026-11-20` was built at 19:55:49 from commit `437fa40`
with `worktree_entries=0` and no untracked files - 110,683,464 bytes, SHA-256
`dc2d1b5e97d3400917f60acbc7381b9ffacf28c12d14b140add4848521f10963` - and its 13/13
acceptance log records that hash at both ends
(`builds/qa/runs/2026-11-20_pattern/acceptance.log`). Platform limits are listed
at the end of [TEST_REPORT.md](TEST_REPORT.md).
**Cleanup helper honesty.** `SaveSystem.delete_save` is now
`delete_save_everywhere`, with a comment that states its real scope (the legacy
directory plus every campaign directory, all recovery copies, accepted names
only) and its QA/test-only purpose: the game has no in-game delete and no UI file
calls it. It returns `{"ok", "removed", "failed"}` with one
`{"path", "error"}` per file that is still present afterwards, so a locked or
permission-denied copy is reported instead of the call claiming success, while
the rest are still removed. 6 new tests cover the report, a real locked-file
failure and its retry, unrelated-file preservation, the no-op case, and source
guards that no `src/ui` file and no non-probe `main.gd` function reaches it.
Suite **680/680, 7,284 assertions, 55 scripts**; six affected probes pass and
`--creator-acceptance-probe` is a pre-existing failure (it fails at `87e64bf`
too). Details in [TEST_REPORT.md](TEST_REPORT.md).
**Creator acceptance probe repaired.** The probe failed at "Validate draft
accepts the authored campaign" and then hung because `_choice_form_pending()`
compared the DC of a plain choice against the DC the form still carried from an
earlier check, so the draft looked permanently unsaved; validation warned, save
and playtest refused, playtest never started, `Game.encounter.finish` ran on a
null encounter, and the aborted coroutine never reached `quit()`. The comparison
now applies only to check choices, every early return exits through a helper that
quits 0/1, a missing encounter is an explicit check, and a 60 s watchdog turns a
runtime error into exit 1 instead of a hang. Reproduced identically at `87e64bf`
and `4e1188b` with fresh profiles; forced-failure and forced-crash runs exit 1 in
6 s and 8 s; a creator regression test fails on the old comparison and passes
now. Suite **681/681, 7,297 assertions, 55 scripts**; all six creator probes and
the combat-reload probe pass. Details in [TEST_REPORT.md](TEST_REPORT.md).
**Acceptance.** `creator_probe_2026-11-20` was exported from clean tree `2dc61e1`
(110,684,280 bytes, SHA-256
`4196d9781955b641210b64fcccc34a7922f9e9b438fd47a123212950f0a7c7cf`) and passed 9/9
- both validators and seven creator probes, the acceptance probe in 4.0 s - with
the hash recorded at both ends of
`builds/qa/runs/2026-11-20_creator_probe/acceptance.log`.
## Batch closure: audit refresh (2026-11-20; documentation only)

The audit's seven items are now reconciled with the committed fixes; no code,
build or check was repeated for this record.

| Item | Status | Evidence |
| --- | --- | --- |
| UI scaling | Closed (`15329d3`) | `ui_scaling_2026-11-20b` `6d38c18d`, 18/18; layouts at 1.0/1.6 on `pattern` `dc2d1b5e` |
| Journal output | Closed (`3dc28cc`) | `journal_2026-11-20` `d3070eae`, 7/7; native close at both scales |
| Refusal logging | Closed (`c3ede47`) | `refusals_2026-11-20` `06883c82`; refusal layout 1.0/1.6; native W/F input |
| Migration foundation | **Foundation only; no production step** (`93e8199`) | `migration_2026-11-20` `00136308`, 11/11; `SAVE_VERSION` 1, `steps` empty |
| Recovery | Closed with limits (`accbc62`, `dafacd8`, `437fa40`) | `a0e30502` 13/13, `4c0d699d` 13/13, `dc2d1b5e` 13/13 |
| Cleanup hardening | Closed, QA-only (`4e1188b`) | suite 680/680, six probes, helper present in `4196d978` |
| Creator acceptance | Closed (`161ceb2`) | `creator_probe_2026-11-20` `4196d978`, 9/9 hash-bound; probe exit 0 in 4.0 s |

Remaining defects are unchanged: reveal only inside modals, a control taller than
its pane clips, one pane follows focus per key press, `follow_focus` is
redundant beside the reveal walk, and there is no key repeat, gamepad page keys or
reveal after a silent relayout. Verification gaps and deferred features are split
out in [TEST_REPORT.md](TEST_REPORT.md): the Journal wheel is verified with a
70-question overflow fixture, no
OS-level crash injection was run, case-sensitive filesystems are unproven,
latest layout evidence is 1280x720 only, several older acceptance logs do not
bind their exe, and the earlier `modal_focus` `fe7511b3` binary is missing. The
only deferred item in this batch is a save migration production step - the
foundation ships with no step and no version bump.

Latest hash-bound candidates: `pattern_2026-11-20` `dc2d1b5e` (13/13) and
`creator_probe_2026-11-20` `4196d978` (9/9); `probe_2026-11-20` is the same bytes
from a dirty tree and carries no acceptance.

The two bell-page content warnings are applied as label-only clauses: the token
cost on *Ring once* and *Break the token*, and combat on *Ring twice for the
dead.* Conditions, effects, flags and rewards are untouched, and a focused test
pins the exact wording plus the unchanged ring-once outcome.

Dialogue choice focus is fixed and hash-bound: the body follows focus, and Tab
and Shift+Tab cycle the available choices in content order while a conversation
is open. Candidate `dialogue_focus_2026-11-21b` (source `01d1cfc`, SHA-256
`cd00d389`) shows the silence epilogue row revealed at 100 % and 160 % on a
1280x720 client, with Enter opening the epilogue. Suite 686/686, both validators
and the dialogue layout probes PASS.

Dialogue PageUp/PageDown now scroll the conversation body one 90 % page with
clamps, leaving focus, Tab order and activation alone; reverse Tab walks back and
wraps. Candidate `dialogue_page_2026-11-21` (source `da12abf`, SHA-256
`29298fe2`) passes the 10-test dialogue file, 692/692 suite, both validators and
the dialogue layout probes at 100 %/160 %. The trace found the dialogue dim is
0x0 (HUD stays mouse-live) and arrow focus can land on unavailable rows; both were
fixed in `01e7016` and `263e2e0` the same day (see the audit refresh below).

Dialogue geometry and focus are closed in `263e2e0`: the root and dim fill the
viewport, both ignore the mouse pick (read-only HUD and Pause stay usable), arrows
cycle available choices, and Tab, paging, activation, modal priority and rebind
capture are unchanged. Candidate `dialogue_geometry_2026-11-21b` (source
`263e2e0`, SHA-256 `94af082e`) passes 12 dialogue tests, 694/694 suite, both
validators and the dialogue probes at 100 %/160 %. Oversized-control clipping
remains a conditional limit - no shipped modal reproduces it.

Dialogue header clearance and dialogue-aware focus return landed in `7d1729f`:
the panel starts below the measured HUD header (following it when long readouts
wrap the title), keeps 860x600 at 1280x720 with normal readouts, and a HUD panel
closed during a conversation returns the ring to the dialogue control that had it
(first available choice, then Leave, as fallbacks). Candidate
`dialogue_header_2026-11-21` (source `7d1729f`, SHA-256 `1796fb2a`) passes 17
dialogue tests, 699/699 suite, both validators and the dialogue probes at
100 %/160 %. Keyboard access to the HUD panels during dialogue remains deferred:
C/I/J are blocked, Tab is reserved for choices, Esc ends the conversation, and
Save has no binding.
## Audit refresh: UI batch closure (2026-11-21; documentation only)

The 2026-11-20 table above is the historical modal/UI snapshot. The dialogue
work after it is closed as follows; no code, build or check was repeated for this
record.

| Item | Status | Evidence |
| --- | --- | --- |
| Dialogue choice focus | Closed (`01d1cfc`) | `dialogue_focus_2026-11-21b` `cd00d389`, 10/10; epilogue revealed at 1.0/1.6 |
| Dialogue paging | Closed (`da12abf`) | `dialogue_page_2026-11-21` `29298fe2`, 10/10; clamps, Enter, reverse Tab, wheel |
| Dialogue geometry and arrows | Closed with limits (`263e2e0`) | `dialogue_geometry_2026-11-21b` `94af082e`, 12/12; full-screen dim, HUD/Pause live, arrows on choices |
| Header clearance and focus return | Closed with limits (`7d1729f`) | `dialogue_header_2026-11-21` `1796fb2a`, 17/17; panel below measured header, ring returns to the choice |

Remaining limits after the refresh:

- **Keyboard access to HUD panels during dialogue is deferred.** C/I/J remain
  blocked by the explore-mode guard, Tab is reserved for choice focus, Esc ends
  the conversation, and Save has no binding. No shortcut was added.
- At 160 % with ten-digit gold/seed readouts the header grows and the panel
  shrinks to 589 px (one less visible row; scroll/paging still reaches all 13
  choices). Covered by tests only, not by a native capture.
- The 100 % exported captures do not show a distinct focus ring:
  `shots100/open.png` equals `after_enter.png`, and `choice.png` equals
  `party_closed.png` by SHA-256. Focus return at 100 % is inferred; it is visible
  at 160 %.
- Oversized-control clipping remains conditional; reveal-only-inside-modals, the
  focus walk, `follow_focus` redundancy, no key repeat and no gamepad page keys
  are unchanged.
- Verification gaps unchanged: 1280x720 only; no OS-level crash injection;
  case-sensitive filesystems unproven; older acceptance logs do not bind their
  exe; the `modal_focus` `fe7511b3` binary is missing. The final candidate was
  not rerun for this closure (evidence reused).


## Backup risk and bounded plan (2026-11-21; assessment only)

No artifact was copied, deleted, uploaded or overwritten for this assessment.

The editable source is a local Git repository (`a64eead`..`3af98a0`, 43 commits)
with **no remote**, on the same disk as the working tree. `builds/` is gitignored,
so the candidate executable and all QA runs exist only there.

| Artifact | Separate recoverable copy? | Detail |
| --- | --- | --- |
| Source (`RL_Edit`, HEAD `3af98a0`) | **No current copy** | Only local `.git` (14 MB) and the working tree. The original checkout `Project Ravenloft/ravenloft-foundation` (`1af0253`, separate history) lags the source. |
| Source snapshots | Partial, stale | `workspace/snapshots/2026-11-13_*` hold `RL_Edit_source.tar.gz` (four entries, two with manifests). Latest is 2026-11-13, before the 2026-11-20/21 batches. |
| `builds/qa/rev_before` | Partial, stale | 11 MB revision-comparison copy, not the current tree. |
| Candidate `dialogue_header_2026-11-21` | **No copy** | One directory (exe + `BUILD.txt`), gitignored; no file of that size elsewhere in the workspace; not in any snapshot. |
| Evidence `runs/2026-11-21_dialogue_header` | **No copy** | 12 files (report + 5 shots at 100 %, 6 at 160 %), 1.5 MB, gitignored; earlier runs are likewise single copies. |
| Docs | In Git only | Committed (`3af98a0`), recoverable from `.git` history, but on the same disk with no off-machine copy. |
| `edit_copy_audit` | Reference only | Source hash manifests and logs from 2026-11-09; no content. |

Risk: one disk loss removes the current source history, the accepted candidate and
all evidence; snapshots stop two milestone days earlier. `builds/qa` holds 4.7 GB
of candidates and 317 MB of runs, so backing it up wholesale is neither bounded
nor useful.

**Bounded plan (one accepted batch, about 126 MB).**

1. Snapshot set: `git bundle create ravenloft-3af98a0.bundle --all`; the final
   candidate directory; the final evidence run directory; a `SHA256SUMS` file for
   every file; and a text record of bundle HEAD, candidate hash/size and counts.
2. Destinations: two independent user-controlled media (for example an external
   drive and a cloud folder). Nothing was copied.
3. Integrity before storage: `git bundle verify`; `git fsck --full`; recorded
   HEAD matches `git rev-parse HEAD`; `sha256sum -c SHA256SUMS`; candidate hash
   and bytes match `BUILD.txt`; screenshot hashes match the manifest.
4. Restore test (about 10 minutes): in a new empty temporary directory,
   `git clone` the bundle; confirm HEAD `3af98a0`, `git fsck --full` and a clean
   status; run `tests/test_dialogue_focus.gd` (17/17) with the shared Godot
   binary; verify the restored candidate hash and launch it at 1280x720/160 %
   with `--campaign=ashwick_ferry --demo-silence`, comparing its open capture
   with the archived `shots160/open.png` (fall back to visible header/panel checks
   if timing makes pixels differ).
5. Retention: newest bundle, candidate and evidence per accepted batch, last
   three batches; exclude the rest of `builds/qa` and Godot caches.
6. Untested until performed: the restore test, off-disk copies, and external
   media integrity. The snapshot directories are on the same `Downloads` disk,
   so they do not mitigate disk loss.
