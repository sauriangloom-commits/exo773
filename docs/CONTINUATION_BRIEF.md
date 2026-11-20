# Continuation Brief

**Written:** 2026-11-05. Supersedes the project-organization brief. This is the
authoritative starting point for the next model instance. Historical documents
(`PROJECT_OVERVIEW.md`, `PROJECT_COMPENDIUM.md`, `PROJECT_CHRONICLE.md`,
`PROJECT_SYNTHESIS.md`) remain references; do not treat their counts as current.

## 0. Latest verified state (2026-11-14): Ashwick Second Ring

Bounded content expansion in `RL_Edit` only. The foundation candidate, its
checkpoint and every earlier artifact are unchanged. **Corrected 2026-11-14:**
`RL_Edit` is now a local Git repository (baseline `a64eead`); the sentence below
described the tree before that. At the time it still had no Git
repository; nothing was committed, pushed, published or rewritten.

**The Ashwick Ferry: The Second Ring** (`content_version` 2) adds a substantive
account decision and three exclusive bell resolutions, then gates main-quest
completion on Maela's final conversation. The ledger establishes that Ivo struck
through the lawful noon crossing and took a fare after the bell, breaking the
crossing law; the optional strongbox page adds a silver toll, a twice-rung bell,
and Ivo's motive, "Maela's draught", without making the earlier account false.
The truth account closes the ferry and leaves Ivo's name honest; the mercy
account preserves the landing and the lie that he died bringing a passenger
home. Ringing once uses the token and leaves one clean note; ringing twice
spends the token only on encounter victory and the far bank answers; breaking
the token leaves the bell silent. The final epilogue varies by account, bell
outcome and whether the page was shared, sets `maela_epilogue`, and is followed
by a calm repeatable conversation rather than replaying the finale.

Verification at this boundary: full suite **517/517 tests, 5,963 assertions, 42
scripts, exit 0**; `test_ashwick_second_ring.gd` **11 tests, 389 assertions**;
`test_ashwick_ferry.gd` **7/7, 318 assertions**; `test_journal_panel.gd` **6/6,
90 assertions**. `--validate-campaigns` PASS and `--validate-diagnostics` PASS,
no content problems. The new candidate is
`builds/qa/candidates/ashwick_second_ring_2026-11-14/RavenloftFoundationEdit.exe`,
110,611,128 bytes, SHA-256
`457e3b887e9105a565a7da25d6a82374e0fe7c9dbd045a87d91cff75034c3253`.
Its pack has **146 paths** and no tests, docs, tools, builds, profiles or other
QA artifacts. One ordinary exported-window route reached the specific
truth/single-ring epilogue and the objective became **Complete** only there.
Other branches, defeat/interruption, repeat attempts, save/load after each
ending and v1 refusal with byte preservation are automated checks, not human
playthroughs. No human playtest or balance pass was performed. Evidence is under
the candidate's `runs/`; the sealed source checkpoint is
`builds/qa/snapshots/2026-11-14_ashwick_second_ring/` (its own hashes are in
`CHECKPOINT.md`).

### Milestone closure (record reconciliation)

Accepted functionally on the reported evidence. These are record changes only:
no rebuild, no suite rerun for these edits, and no regeneration or modification
of the sealed checkpoint. Candidate
`builds/qa/candidates/ashwick_second_ring_2026-11-14/RavenloftFoundationEdit.exe`
(110,611,128 bytes, SHA-256
`457e3b887e9105a565a7da25d6a82374e0fe7c9dbd045a87d91cff75034c3253`). Sealed
checkpoint `builds/qa/snapshots/2026-11-14_ashwick_second_ring/`: tarball
`0ee9fc2e742510f5399073c9f70b622a1bf81d040bdf802b5209516eeda1f716`,
`MANIFEST.sha256` file SHA-256
`ec657214eee59eb814e1ad1e8d5b39f432585d5b8dd4a30dd94bc3b8d0190ad4` over 490
files, `CHECKPOINT.md` file SHA-256
`6103368f70bf32724ab65eb9a0df132cd81cb9b0f084ada51baf68768d7e5685`.

`README.md`'s Tests paragraph and this record were corrected after sealing, so
the working tree intentionally differs from that snapshot; no new checkpoint was
made. `tools/qa/creator_input.ps1` carries a two-line window-focus and
pre-capture-wait change, is included in the sealed manifest
(`c02b138c675435aa81822d8c7e3f053e373a438ee271b6500ca8f95b6dd13f70`) and was
used by the recorded native route — an explicit scope exception for this
milestone, not authorization for further tooling changes. Native evidence covers
one route only (truth account, ring once); all other branches, defeat and
interruption, repeat attempts, save/load and v1 refusal are automated. No human
playtest or balance validation. The only deletion was disposable
isolated-profile test residue (`.draft_test_creator_alpha` under the harness's
own `user://` campaigns folder), not project or player data. Milestone closed;
no further content, rules, UI, tooling or verification sweep is authorized.

## 1. Objective

Build a reusable **single-player campaign platform**: a player or the model can
create, validate, test and play a new small campaign through the same systems,
without repeatedly changing the engine.

The baseline product is that platform. Ravenloft is a campaign built on it, not
the platform itself. The platform is also the campaign-development environment,
developer/debug mode, demo bed, and the base for authored campaigns.

Preserved direction: Godot 4.7 + GUT; single-player party; Wizardry-inspired
first-person grid exploration; turn-based tactical combat; D&D 3.5 fidelity
within the documented scope; lore fidelity for supplied material; integrated
narration, dialogue, exploration, combat, quests and saves. Writing, graphics
and audio remain labelled placeholders.

**The individual feat queue stays paused.** Feats, trip and Cleave are existing
examples of the extension contracts; do not resume the queue without direction.
Feat counts, test counts and document volume are not the completion measure.

## 2. Canonical locations

| What | Path |
| --- | --- |
| Workspace root | the `Ravenloft` folder containing this project |
| Canonical game source + Git repo | `Project Ravenloft\ravenloft-foundation` |
| Godot executable | `Project Ravenloft\Godot_v4.7.2-stable_win64.exe` |
| Accepted releases | `workspace\releases\<name>\` |
| Candidate builds | `workspace\candidates\<build-id>\` |
| QA runs/evidence | `workspace\qa\runs\<run-id>\` |
| Reproducible QA tooling | `ravenloft-foundation\tools\qa\` |
| Private PDF library (43 files) | `workspace\references\dnd35\` |
| Recovery snapshot | `workspace\snapshots\2026-11-05-pre-handoff\` |

## 3. Environment

- Godot **4.7.2.stable.official.ed1daf0bf**; GUT **9.6.1** vendored at `addons/gut`.
- Python **3.12.7** for docs/maintenance scripts only. Windows, Git Bash.
- No build step or package install.

## 4. Revision and working tree

- Branch `master`, HEAD **`fc951aca49877d6a4fa6999254831d7ebe6b9349`**.
- Closed creator-usability/diagnostics/pending-edit checkpoint:
  **`fc951aca49877d6a4fa6999254831d7ebe6b9349`**, parent
  `2dd907998d8a7f69efe10c3570e4cb04e4346509`.
- Working tree at checkpoint validation: only untracked
  `PROJECT_SYNTHESIS.md`; no staged or modified tracked files. This assessment
  subsequently edits `README.md`, this brief and `docs/PROGRAM_PROGRESS.md`
  (unstaged record corrections only). Nothing pushed or published.
- Recovery snapshots (outside the Git tree, under the workspace root):
  `workspace\snapshots\2026-11-05-pre-handoff\` (pre-workspace pass),
  `workspace\snapshots\2026-11-05_pre-diagnostics\`, and
  `workspace\snapshots\2026-11-07_pre-checkpoint_final\` (post-fix source).

## 5. Latest verified state (2026-11-07, closed checkpoint)

### Combat-start flat-footedness (2026-11-13)

- Working copy `RL_Edit` (no Git). `Encounter` seeds `flat_footed` for every
  combatant in `begin()`, clears it in `_begin_turn`, and passes it to every
  attack path (party attacks, opportunity attacks, monster attacks, ranged touch
  spells, the trip touch attack). `Rules.armor_class`/`touch_ac` deny a positive
  Dexterity bonus and dodge bonuses (never a Dexterity penalty, and never every
  bonus), and `Rules.attack` accepts a `flat_footed` option.
- Full suite **378/378 tests, 4,794 assertions, 26 scripts, exit 0**;
  `tests/test_flat_footed.gd` **14 tests, 51 assertions** and
  `tests/test_ranged_melee.gd` **12 tests, 41 assertions**. Six existing tests
  were updated when the flat-footed state was introduced, two more when the dodge
  denial was corrected, and one stale log-word assertion when the wording moved
  from "no Dexterity modifier" to "no Dexterity bonus".
- Windowed probe `--demo-inspect --inspect-probe`: real enemy panel showed
  `AC 12 (flat-footed)` for a +3 Dexterity/Dodge defender, `AC 11 (flat-footed)`
  for a -1 Dexterity zombie (AC unchanged), the same marker at 1.6 text size set
  by the Settings slider, and `AC 16` with no marker after the defenders acted;
  the attack line in that window read `vs AC 12`. Captures:
  `builds\qa\runs\2026-11-13_151001_inspect_panel\`.
- Boundary recorded, not implemented: no supported creature has uncanny dodge or
  Combat Reflexes, and authoring Combat Reflexes is a content error.
- Docs: `TRACEABILITY.md` row 2a, `ADAPTATION_LOG.md` entry 38,
  `SUPPORTED_FEATURES.md`, `PHASE2_VERIFICATION.md` (dated resolution note),
  `PROGRAM_PROGRESS.md` and `TEST_REPORT.md`.
- Accepted candidate `RL_Edit\builds\qa\candidates\ranged_windowed_2026-11-13\`
  `RavenloftFoundationEdit.exe`, 110,501,736 bytes, SHA-256
  `2aa5c030dc46577f35d6df727e00e5edf34d859bde8ab7e08de6f623220278a2`. In that
  executable: `--ranged-probe` (49 checks, PASS), `--inspect-probe`, `cleave`,
  `trip/prone`, `--validate-campaigns` and `--validate-diagnostics` all passed.
  Package inspected with `tools/qa/pck_paths.py`: 144 packed paths; the required
  runtime scripts, `content/` and assets are included, and unintended
  development files, private references, QA profiles and generated artifacts are
  excluded.
- Preserved superseded builds: `ranged_melee_2026-11-13` (predates the windowed
  ranged probe), `flat_footed_corrected_2026-11-13` and `flat_footed_2026-11-13`
  (wrong AC handling). Each keeps its bytes and now has a `SUPERSEDED.txt`.
  `export_presets.cfg` excludes `builds/*`.
- Checkpoint: `workspace\snapshots\2026-11-13_ranged_closed\` — source tarball
  SHA-256 `cd08724f3b90286532a09d5641ba21ea771d1b939bfb070cdf1794a2f87026be`,
  `MANIFEST.sha256` over 457 files, and `CHECKPOINT.md` with the baseline and
  selected next task.
- Ranged attacks (same day): `Encounter._into_melee_penalty` returns the p. 140
  -4 for ranged/thrown weapons and for ranged touch spells, with engagement,
  the 10-ft escape and Precise Shot (added to `Feats.CATALOG` with its Point
  Blank Shot prerequisite). `Rules.attack` takes an `into_melee_penalty` option
  and `Rules.format_attack` prints it. The p. 135 provocation is unchanged and
  logged as its own rule, so the two conditions are never conflated and a ray
  provokes once. `tests/test_ranged_melee.gd` covers both directions (penalty
  without provocation, provocation without penalty), thrown weapons, the 10-ft
  escape, Precise Shot and its prerequisite, rays, Magic Missile and the
  single-provocation rule.
- Completed: **Concentration and casting on the defensive** (PHB pp. 69, 70, 140,
  170). Damage during a cast forces DC 10 + damage + spell level per interruption;
  a failed check loses the spell and still spends the action, slot and prepared
  cast. The spell list's checkbox casts defensively (DC 15 + spell level, no
  opportunity attack) for that one cast only. No shipped caster has ranks, so they
  use the Constitution modifier and were not rebuilt (ADAPTATION_LOG 40). Evidence:
  `tests/test_concentration.gd` (12 tests), 390/390 suite, both validators, and 56
  passing windowed checks in candidate
  `builds\qa\candidates\concentration_2026-11-13\` (SHA-256
  `8ebb56f2b72461acf6323cf9bb728a084d98995b8617a3e957ee65afa379331a`).
- Completed: **Combat Casting** (PHB p. 92), defensive clause only. +4 untyped on
  defensive-casting Concentration checks; the grappling/pinned clause is
  documented as not modeled. `tests/test_combat_casting.gd` (6 tests); suite
  396/396; candidate `builds\qa\candidates\combat_casting_2026-11-13\`
  (SHA-256 `ec8aa425a30385d20d81261e666710302920881f001c2fa91059a47a10803c82`).
- Completed: **integration acceptance** in the shipped `town_square_zombies`
  encounter with unmodified pregens and standard zombies (49 checks PASS, candidate
  `builds\qa\candidates\integration_2026-11-13\`, SHA-256
  `78b85a8688e17aaf69651626ded7f0e41f9a0f59f46bf00be16eed95821d1931`): flat-footed
  opening, flat-footed melee AC, thrown -4 into a melee, ordinary cast provoking a
  reaction that missed while the spell completed. No rules defect found; completion
  and difficulty were not judged.
- Completed: **weapon handling, shields and the unarmed-threat correction**
  (PHB pp. 137, 138, 139-140, 142). Threat separates attemptable attacks from the
  armed state that threatens squares; ordinary empty hands no longer threaten, flank,
  engage or react, while natural weapons and Improved Unarmed Strike do. Sheathing
  and drawing are separate actions, a crossbow is loaded before firing and spends the
  shot, and shields can be strapped or unstrapped-and-dropped. `test_melee_threat.gd`
  (15 tests), `test_weapon_access.gd` (11), `test_shield_handling.gd` (9), suite
  431/431. Candidate `builds\qa\candidates\unarmed_threat_2026-11-13\` (SHA-256
  `ef7688ed1f4975c4976577c5f14b533763ff0c027b82e7c18ab37019741d5c67`), 51 weapon,
  27 shield, 49 integration, 79 concentration and 49 ranged probe checks.
  Adaptations: ADAPTATION_LOG 42, 43 (historical), 44, 45 (dated correction).
- Next selected milestone: **ordinary unarmed attacks** (PHB p. 139). The attack is
  reachable but semantically wrong: lethal bludgeoning by default, no reaction from
  an armed defender, no lethal-at--4 option, and no undead/construct immunity to
  nonlethal damage.
- Not done: human playtest, balance pass and full scenario replay in the
  candidate; cover, concealment and the p. 140 "actually being attacked" nuance
  remain unmodelled, as does Complete Arcane's spell version of Point Blank Shot.
- Recovery snapshot: `workspace\snapshots\2026-11-13_pre-flat-footed\`
  (`RL_Edit_source.tar.gz`, SHA-256
  `ffcf1fdfd644b1eab601a75fa4810cb9c307e588b8677d055ea6b36846d5d5e5`).


### Journal overlay triage (2026-11-08)

- Starts from HEAD `a1dc84ca3b03aaf75a43ef7b2a5008897420608f`; triage changes are
  unstaged, with nothing committed or pushed.
- The blank Journal in the exported Ashwick run was layout, not data: the Journal
  `RichTextLabel` had `fit_content` without horizontal expansion, so it laid out
  1 px wide and 6,831 px tall inside the scroll area. `Panels.journal()` now sets
  `SIZE_EXPAND_FILL` and disables horizontal scrolling. No quest, save or
  campaign-format change.
- Focused `tests/test_journal_panel.gd`: **6 tests, 85 assertions** covering an
  empty log, active Ashwick objectives, a loaded in-progress save, the completed
  quest after reload, `hollow_lantern`, and 1.6 text scale. Assertions read the
  rendered text and measured layout, not flags alone.
- Full suite **352/352 tests, 4,697 assertions, 24 scripts, exit 0**;
  `--validate-campaigns` and `--validate-diagnostics` PASS (both require `--`
  before the user flag).
- Candidate
  `workspace\candidates\journal_fix_2026-11-08\RavenloftFoundation.exe`,
  110,481,944 bytes, SHA-256
  `78b8c2e9d5d0c6b99c5241d491f048f95dc79a165eee6f358261a143b65e4292`. The
  `ashwick_ferry_2026-11-08` candidate remains unchanged
  (`8a3f067b142411039afef7324739126c664b8944baa0751d5e527053d31d4f5f`).
- Export packaging verified by inspecting the candidate pack: 121 paths, all
  three campaigns plus `content/shared/`, areas, dialogue and runtime assets; no
  `workspace/`, `docs/`, `tests/`, `tools/`, PDF, reference, save or settings
  path. The 29,864 byte reduction is not claimed as workspace exclusion alone
  (the runtime change also affects compiled size). Older candidates
  `ashwick_ferry_2026-11-08` and `..._backend` do package QA probe scripts and are
  marked `LOCAL_ONLY.txt`, unchanged otherwise. `build_candidate.sh` hashes
  untracked paths null-delimited; a disposable fixture confirmed deterministic
  hashing with a space in a filename, where the old line aborted the first
  export attempt. The recorded `worktree_diff_sha256` predates these doc edits,
  so it is not a hash of the current tree.
- Active-quest exported check in the same candidate, fresh profile: spoke to
  Maela, set Text size to 1.6 in Settings (`settings.cfg`: `text_scale=1.6`),
  Journal showed title, wrapped summary, one `[x]` and four `[ ]` objectives with
  vertical scrolling; saved to slot1 through the UI, closed the process by PID
  after the intended Quit click missed, relaunched and continued the save through
  the ordinary Continue entry, and the Journal re-read identically. In-game Quit
  is not claimed verified and the miss is not treated as a defect. The save is
  preserved under
  `workspace/qa/journal_triage/active_quest_save_preserved/` (slot1
  `abf9d953…`, autosave `55141c90…`). No combat, no scenario completion.
- Working tree at this checkpoint: this task changed the three `docs/*.md`,
  `export_presets.cfg`, `src/ui/panels.gd`, `tools/qa/build_candidate.sh`, added
  `tests/test_journal_panel.gd` + `.uid` and `workspace/`.
  `PROJECT_COMPENDIUM.md` was already modified and `PROJECT_SYNTHESIS.md`
  already untracked before this task; the earlier "compendium/.uid
  housekeeping" wording was imprecise — only the test `.uid` was generated here
  and the compendium was not touched.
- Teardown scope now includes the focused Journal suite: it exits 0 and then
  prints **2 ObjectDB instances leaked / 1 resource still in use**, the same
  class as the focused Ashwick process. Cause not established; not claimed fixed.
- Limitations: the pre-bell save no longer exists, so that state uses an
  ordinary save/load fixture; the exported 1.6 check used the Settings slider
  because `--text-scale=1.6` had no effect in the exported build; earlier "1.6"
  captures have no settings record behind them, so their scale is marked
  unverified while their action/visibility/save-load/native-input results stand.

- Entity-form text is now protected by one bounded policy: each supported form is
  compared with the applied draft and, before a lossy transition, the creator
  offers **Apply / Discard / Cancel**. Cancel preserves text, selection and
  focus; Discard is explicit; Apply validates first and a failed Apply preserves
  the text and does not navigate. Save, Playtest, Back, area/entity selection
  and validation-result navigation all go through the same guard. The header
  names the pending form. This is protection only, not a new editor section or a
  state-management framework.
- Confirmed pre-guard loss paths: selectors assigned the new entity/area and
  refreshed the controls, replacing unapplied NPC/dialogue/node/choice/quest/
  objective/encounter/trigger text; `capture_draft` carried only campaign title/
  description/current-area name, so Save and Playtest ignored entity-form text;
  leaving discarded it; and diagnostic navigation used the same selectors.
  Validation could announce the applied draft as valid without mentioning the
  unapplied text. The initial standalone probe failed outside the autoload
  context, so this list is from the pre-guard control flow and project-local
  tests, not a pre-fix exported screenshot.
- Validation agreement: `_validate` now says "Applied draft validates, but
  pending form edits are not included" and Save/Playtest refuse while pending.
  The authoritative result is still `Game.validate_campaign_draft_diagnostics`;
  structured diagnostics supplement the legacy validator. Duplicate status text
  and diagnostic-panel messages remain where a stable deduplication key was not
  introduced in this bounded milestone; unmapped legacy rules remain visible and
  non-navigable.
- Guarded Apply is now atomic for the detected forms: the complete draft, form
  text, dirty state and selection are snapshotted; any failure restores all of
  them, keeps the validation explanation, and writes no campaign file. Success
  applies every pending form before the guarded navigation continues. This is a
  bounded form snapshot/rollback, not a general transaction framework or undo.
- Reference selectors now show **Unresolved reference: <id>** for a stored id
  that is absent, instead of selecting the first valid option. Opening or
  navigating to the entity does not repair it; an unrelated Apply preserves it;
  intentional selection of a valid target repairs it and clears the diagnostic.
  The shared `_fill_options` / `_select_by_meta` path covers NPC dialogue, node
  destination, response destinations/effects, quest start/completion and
  victory quest. Saving an unresolved reference is refused without overwrite.
- Verification: full suite **339/339 tests, 4,324 assertions, exit 0**; focused
  creator **33 tests, 609 assertions**. `--pending-edit-probe` passes **37**
  checks in source and the exact candidate; `--diagnostic-navigation-probe`
  remains **11/11**. `--validate-campaigns` and `--validate-diagnostics` PASS.
- Teardown: the full suite was clean. The focused creator suite exited 0 after
  passing, then printed this unresolved warning:

  ```
  WARNING: 5 ObjectDB instances were leaked at exit (run with `--verbose` for details).
     at: cleanup (core/object/object.cpp:2536)
  ERROR: 2 resources still in use at exit (run with --verbose for details).
     at: clear (core/io/resource.cpp:822)
  ```

  Reproduction scope is the focused creator GUT process; its cause is not
  established, and it is not claimed fixed.
- Candidate:
  `workspace/candidates/pending_atomic_2026-11-07/RavenloftFoundation.exe`,
  110,463,552 bytes, SHA-256
  `4d88215acd720de9e1278dd2908a7e9ec3e6202aafa27fab8914bc7f9eba11c1`.
  The prior `pending_edits_2026-11-05`, `content_diagnostics_2026-11-05` and
  `creator_usability_2026-11-05` candidates are untouched.
- Exported-interface check: windowed at 1280×720 and 1.6 text scale, with real OS
  input. The capture shows **Unresolved reference: missing_talk**; clicking the
  diagnostic opens the guard prompt, and Apply preserves the unresolved id while
  applying the unrelated name edit. Captures:
  `workspace/qa/pending_atomic/unresolved_1p6_scrolled.png`,
  `guard_prompt_1p6.png`, `guard_applied_1p6.png`. The asserted probe proves the
  atomic failure and success paths in the exact executable; the visual check is
  limited to those clicks, not a human-usability study.
- Remaining limits: no undo or per-form history; the picker shows one explicit
  unresolved entry rather than a reference browser; duplicate validation status/
  panel messages remain; save still blocks invalid unresolved references rather
  than repairing them. No push or publish was performed; the authorized local
  checkpoint includes this record.
- Historical pre-atomic pending-form run: **334 tests, 4,279 assertions**,
  focused creator **28 tests, 564 assertions**; superseded by this section.

## 5a. Prior verified state (2026-11-05, structured diagnostics)

- Full suite: **332/332 tests, 4,198 assertions, 22 scripts, exit 0**;
  `tests/test_campaign_creator.gd` contributes **26 tests, 483 assertions**.
- `--diagnostic-navigation-probe` passes all **11 checks** in source and in the
  exported candidate: results panel, correct NPC among similar entities, focused
  field, preserved dirty form state, stale-result revalidation, entry control,
  corrected revalidation, and save. Node/choice diagnostics carry dialogue
  context and objectives carry quest context.
- `--validate-diagnostics` emits JSON and exits 0 for valid packages; a copied
  package with a broken area file produced `package.load`, named the file,
  reported FAIL and exited 1 without rewriting it. `--validate-campaigns` keeps
  its text/exit contract. `ContentDiagnostics` carries code, severity, message,
  campaign/source, entity type/id, field, area/node/choice context, refs and an
  advanced flag.
- Candidate:
  `workspace/candidates/content_diagnostics_2026-11-05/RavenloftFoundation.exe`,
  110,427,456 bytes, SHA-256
  `9acd6c35b119c8b872e0137b558cd60de67d2188c70779fc0c521fea6a7b027a`.
  Earlier candidate `creator_usability_2026-11-05` is untouched.
- Recovery panel behavior: selecting a result opens the section, selects the
  entity, scrolls and focuses the field; unsaved form/draft state is preserved.
  Deleted entities show a revalidation message. Unmapped legacy rules remain
  `advanced` and require file editing. There is no universal picker, auto-repair
  or rename. Malformed syntax is distinct from wrong-shape JSON and neither
  overwrites the original.
- Prior milestone (creator usability and acceptance): clear release export exit
  0; full suite **329/329 tests, 4,160 assertions, 22 scripts**; creator
  usability candidate remains as recorded below. Its long creator exercise is
  **callback-driven workflow/integration verification**, not viewport input,
  external OS input or human usability testing; the later native-input check is
  limited to selecting a diagnostic result and reaching its field.
- `--validate-campaigns`: `ravenloft_demo` and `hollow_lantern` both **VALID**
  on source and in the exported executable. The executable additionally sees the
  local `creator_preview` user campaign created by the demo, which is expected
  and not part of the repository.
- `--creator-probe`, `--creator-ui-probe`, `--creator-interaction-probe` and the
  new `--creator-story-probe` pass on source and in the exported executable; each
  exits nonzero on failure. The story probe covers create → quest/flags → second
  area/passages → encounter → trigger → conversation with quest start and a
  flag-gated changed response → save → unsaved edit → snapshot playtest (travel,
  trigger, victory once, changed response, save refused) → return with the saved
  package byte-identical → ordinary play/save/reload → cross-campaign isolation.
  Its victory/defeat step calls `Encounter.finish()` and is a **forced postcombat
  integration check, not a combat playthrough**.
- Creator acceptance exercise: `--creator-acceptance-probe` drives the visible
  campaign list and creator callbacks through create → two areas/passage → entry
  → NPC → skill-check dialogue with a flag-gated changed line → flag → quest and
  objective → encounter/victory → trigger → validate/save → recovery refusals →
  playtest (talk, check, trigger, forced postcombat, changed line, save refused)
  → reopen from disk → ordinary play/save/load. It is an automated UI script,
  not a human study. It passes in source and in `creator_usability_2026-11-05`.
- Usability fixes: the Save/Validate/Playtest bar and status feedback are now
  pinned above the scrolling content; the action is labelled **Playtest draft**
  with a save/play distinction line. Regression test
  `test_creator_action_bar_stays_visible_when_scrolled` covers it. The authoring
  guide now opens with the full getting-started workflow and a refusal-recovery
  table.
- Real-combat acceptance: `--creator-combat-probe` (seed 90210) wins the authored
  encounter through ten **Attack** button + target-cell clicks after closing to
  5 ft with the **Move** control, without calling `Encounter.finish()`, editing
  HP or setting the flag; it sets `beacon_lit`, completes the quest, awards 50 XP
  once (3000→3050) and saves. `--creator-combat-reload-probe` runs as a separate
  process, loads the save, re-crosses the trigger with no combat or second
  reward, and confirms the changed NPC response. Both PASS in source and in the
  exact candidate.
- Lossless editing: an unrelated creator save preserves doors, objects, effects/
  conditions, unknown author keys, `flag_definitions`, local `items.json` and an
  unmanaged `dungeon.json`; packages with inline content, newer format versions or
  wrong-shape/duplicate files are refused with an actionable message rather than
  being narrowed on save. Write boundaries were checked by comparing files and a
  sentinel outside the cleanup roots.
- The authored-interaction test covers deterministic failure and success seeds,
  the persistent flag consequence, the guarded response hiding and the later
  response appearing, refused playtest saves, normal-play save/load, and
  cross-campaign save/flag isolation.
- Visual: quest/flag and encounter/trigger sections inspected at 1280×720 at
  1.0 and 1.6 scale. One layout defect was found and fixed: encounter row labels
  collapsed into one character per line beside the expanding pickers; they now
  have fixed minimum widths and no wrapping. Captures:
  `workspace\qa\slice3\creator_slice3_{quests,encounters}_{min,large}.png`.
- External OS-input pass on the exact candidate (automated events, not human
  testing): **New quest** produced a selected `quest_01`, **Add monster** changed
  the count from 1 to 2, and, after the section was scrolled into view, the
  measured **New encounter** click created and selected `encounter_02`. The
  button was at y=2821 at scroll 0 and y=125 after the focus scroll; the earlier
  miss used the post-scroll coordinate on the unscrolled layout, so there is no
  application defect. Captures: `ext_new_quest.png`, `ext_new_encounter.png`,
  `ext_new_encounter_verified.png`.
- Candidate from this exact source:
  `workspace\candidates\creator_slice3_2026-11-05e\RavenloftFoundation.exe`,
  110,376,216 bytes, SHA-256
  `57758c82c761362bccaa64f1ec8bc0e0619c5038bd7c0da03c07d8a2aea3565f`;
  `BUILD.txt` records HEAD `9fc8fff`, 79 worktree entries, tracked diff hash
  `efc929ed…747090b`, 266 untracked files and untracked-source hash
  `5f2c6200…cae310af`. Candidate `…c` remains at `7a205aee…ecb7a227`; the
  accepted `creator_slice2_2026-11-05` candidate and earlier exports are
  untouched.
- Probe/validation logs: `workspace\qa\runs\2026-11-05_creator_slice2\` and
  the `/tmp` logs from the same run.
- Earlier accepted builds keep their status:
  `workspace\releases\{trip,improved_trip,cleave,cleave_offturn}_candidate`,
  `workspace\releases\windows_legacy_2026-11-05`,
  `workspace\candidates\campaign_packages_2026-11-05`.

## 6. Architecture

| File | Role |
| --- | --- |
| `src/main.gd` | Application shell, campaign selection, menus, probes (~1,900 lines; known cleanup target) |
| `src/game_state.gd` | Autoload `Game`: active campaign, party, flags, quests, effects, save identity, combat/dialogue bridge, training isolation |
| `src/core/campaign_db.gd` | Registry of bundled + user campaigns; manifest validation; collision rejection; display order/default |
| `src/core/campaign_store.gd` | Writable user packages: template, scan, map/draft helpers, NPC/dialogue draft operations with reference-safe rename/delete, shape/full validation, atomic writes, delete |
| `src/ui/campaign_creator.gd` | Campaign Editor screen: metadata, areas, 9x9 map, entry/facing, passages, speaker NPCs, node-list dialogue/choice/check/flag forms, validate/save/playtest |
| `src/core/content_db.gd` | Loads shared rules + one campaign package; campaign-local instances; vocabulary/reference validation; campaign manifest validation |
| `src/core/content_spec.gd` | Single registry of authored effect/condition vocabulary |
| `src/core/save_system.gd` | Campaign-scoped atomic saves, legacy-save read-only fallback |
| `src/core/character.gd`, `rules.gd`, `feats.gd`, `skills.gd` | Shared rules content and resolution |
| `src/core/encounter.gd` | Tactical combat engine (2,527 lines; per-decision plumbing still feature-specific) |
| `src/core/dungeon.gd`, `battle_map.gd` | Grid exploration and combat maps |
| `src/core/dialogue.gd`, `quests.gd`, `dice.gd` | Narrative runners, quest log, RNG |
| `src/ui/*` | Exploration/combat views, panels, dialogue, theme, SFX |
| `content/shared/` | Rules content shared by every campaign: items, spells, characters, monsters |
| `content/campaigns/_registry.json` | Installed campaign ids and default |
| `content/campaigns/ravenloft_demo/` | Ravenloft demo package (gatehouse + town square excerpt) |
| `content/campaigns/hollow_lantern/` | Neutral example package (two areas, dialogue, encounter, quest) |
| `docs/CAMPAIGN_PACKAGE.md` | Campaign package contract, layout, validation and commands |
| `tests/` | 22 GUT scripts, incl. `test_campaign_packages.gd` and `test_campaign_creator.gd` |
| `tools/qa/` | Build/probe wrappers, external input smoke (`external_input.ps1`, `creator_input.ps1`) |

## 7. Campaign platform: implemented now

- **Package contract:** `campaign.json` (format version, stable id, title,
  description, content version, entry area/position/facing, default party and
  bounds, start/completion quest, required capabilities) plus campaign-local
  areas, dialogue, quests, encounters and narration.
- **Shared vs local identifiers:** rules content is global and lives once in
  `content/shared/`; story ids are local to the loaded package; campaign-local
  instance tables may add named items, monsters and characters but may not
  redefine a shared id; a local `spells.json` is refused; duplicate local ids
  are errors; cross-campaign story references fail because only one package is
  loaded.
- **Validation:** references (dialogue, travel target, monster, quest, item,
  skill, capability), entry-point walkability, party defaults, quest wiring,
  and all existing content checks. Invalid packages cannot be started.
- **Player workflow:** Campaigns screen lists packages with New game, Continue,
  Load slot and Validate; party selection and play are identical across
  campaigns; victory narration is driven by the package's completion quest.
- **Persistence isolation:** saves live in `user://saves/<campaign>/<slot>.json`
  and record campaign id + content version; cross-campaign loading switches
  campaigns explicitly; version mismatch is refused and never overwritten;
  pre-campaign saves are read-only fallbacks for `ravenloft_demo`.
- **Writable user campaigns:** `user://campaigns/<id>/` works in source and
  exported builds; directory scan discovers packages with no registry or engine
  edit; bundled packages stay read-only; duplicate bundled/user ids are refused.
- **Campaign Editor (bounded):** create from the neutral template, reopen with
  Edit, edit title/description, add 9x9 areas, toggle walls/floors, set entry
  and facing, link areas, place speaker NPCs, and author branching conversations
  (nodes, choices, one skill check, require/show/set flag, narration), validate
  with named errors, save atomically, playtest through the ordinary loader,
  travel, and return with the in-memory draft. Editing changes only the draft;
  Playtest is an explicit save-plus-launch action and still refuses all saves.
- **Playtest isolation:** `Game.playtest_mode` refuses every save and autosave;
  playtest state never rewrites authored files or ordinary campaign saves;
  returning calls `Game.abandon_playtest()` and restores the creator.
- **Local campaign content:** named NPC/character, monster-variant and unique
  item instances merge from campaign-root `characters.json`, `monsters.json` and
  `items.json`; shared ids cannot be redefined; local `spells.json` is refused.
- **Developer pipeline:** `--list-campaigns`, `--validate-campaigns`,
  `--campaign-probe=<id>`, `--creator-probe`, `--creator-ui-probe`,
  `--creator-interaction-probe`, `--creator-story-probe`, `--campaign=<id>`,
  `--demo-creator`, `--demo-creator-interaction`, `--creator-focus=`; probes pass
  in source and in the exported executable. No new hard-coded `Main.gd` branch
  per campaign.

## 8. Supported scope and limitations

**Supported (verified):** exploration/travel/dialogue/quests/save-reload loop;
45 skills; 39 feats including Power Attack, Combat Expertise, Cleave (on/off
turn), Improved Trip, turning feats and proficiencies; trip/prone; turn undead;
6 spells; training demonstrations; two installable campaign packages.

**Limitations:** the creator covers metadata, 9x9 areas, entry/facing,
passages, speaker NPCs, a bounded dialogue editor, quests/objectives/flags,
fixed-layout encounters, victory consequences and encounter triggers. Doors,
objects and unique items remain file-only and are labelled in the editor.
Dialogue editing is a node list, not a graph; one skill check per choice; only
the require/show/set flag, quest-start, encounter-start and narration palette;
three encounter templates with four party cells and at most four shared
monsters; no monster-stat editing; at most 12 objectives per quest; no quest
scheduler or failure-state framework; no larger maps; no scripting/mod system;
no new mechanics from local instances. Great Cleave, iterative/full attacks,
ranged/spell/DoT Cleave triggers, NPC Cleave, fighting defensively, cover,
stealth, item creation, metamagic, mounted combat and spells beyond the six
remain unsupported; per-decision combat plumbing is still feature-specific;
encounter state is intentionally unsaved; minimum window 1280×720; Dodge is a
documented general adaptation; no packaged-campaign export/install flow.

## 9. Next increments, in order

1. **Creator slice 2 — complete:** speaker NPC placement and a bounded
   node-list dialogue editor with one skill check, require/show/set flag,
   narration, reference-safe rename/delete, draft-only editing, validation,
   save/reopen, playtest and return. Verified in source and in the exact
   exported candidate.
2. **Creator slice 3 — complete:** quests with flag-bound objectives and start/
   completion selection, declared flags, fixed-layout encounters with shared
   monsters and bounded XP, victory consequences, placed once-only triggers, a
   dialogue quest/encounter palette, and playtest-by-snapshot. Verified in source
   and in the exact exported candidate, including the full authored scenario.
3. **Validation navigation and pending-form protection — complete:** structured
   results, id-based field navigation, stale-result handling, and Apply / Discard
   / Cancel protection for entity forms. Verified in source and in the exact
   `pending_atomic_2026-11-07` candidate, including atomic multi-form Apply and
   explicit unresolved-reference display. The reference picker and broader
   jump-to-field work remain the next authoring UX (do not start without review).
4. **Decision registry:** replace per-decision branches in `Encounter` and
   `CombatScreen` with one typed pending record and resolver table (largest
   remaining engine special-case reduction).
4. **Data-driven passive feats / spell resolution table** (only if authoring or
   campaign content needs them; not an automatic queue).
5. **Save migration hook** before changing save payload shape or campaign
   content versions in published builds.
6. **Extract QA fixtures/probes out of `main.gd`.**

## 10. Current state / exact next action

**2026-11-13:** combat-start flat-footedness is implemented and verified in
`RL_Edit` (see §5). That supersedes the "No new milestone has been started"
line below, which records the 2026-11-08 state.

The creator-usability, diagnostics and pending-edit checkpoint is closed at
**`fc951aca49877d6a4fa6999254831d7ebe6b9349`**. The content-only **Ashwick
Ferry** scenario is now authored in `content/campaigns/ashwick_ferry/` and has
passed ordinary-play acceptance in the exact candidate at the Ravenloft
workspace root (outside this project):
`workspace/candidates/ashwick_ferry_2026-11-08/RavenloftFoundation.exe`
(110,511,808 bytes, SHA-256
`8a3f067b142411039afef7324739126c664b8944baa0751d5e527053d31d4f5f`).
The run used normal UI input and an isolated `APPDATA` profile with Brother
Aldric, Kaelen Dorn, Sera Vane and Ysolde; it covered seed 4104856171, Maela's
success branch, the ledger, key-opened door, four-round combat, token and 200 XP,
pre-bell save, process restart and load, changed Maela branch, bell completion,
and save/reload without repeated victory, token or encounter. The creator still safely refuses to save this package because of the
unmanaged campaign-local item interaction; that refusal is the compatibility
result, not a GUI-editable claim.

No new milestone has been started. The remaining unverified observation is that
the Journal overlay opened without entries at the boathouse after the pre-bell
load (`workspace/qa/native_50_journal.png`); the loaded save retained its
objectives and the run later completed. It was not used as evidence. Alternative
door and failure branches remain covered by the focused regression rather than
by the exported window. Keep the feat
queue, reference browser and teardown-warning investigation paused. Do not push
or publish without separate authorization; stop for review.

## 11. Exact commands

From `Project Ravenloft\ravenloft-foundation`:

```bash
# Full suite (328 tests, exits nonzero on failure)
"../Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Campaign contract tests only
"../Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_campaign_packages.gd -gexit

# Clean import after adding a class_name
"../Godot_v4.7.2-stable_win64.exe" --headless --path . --import

# Campaign pipeline
"../Godot_v4.7.2-stable_win64.exe" --headless --path . -- --list-campaigns
"../Godot_v4.7.2-stable_win64.exe" --headless --path . -- --validate-campaigns
"../Godot_v4.7.2-stable_win64.exe" --headless --path . -- --campaign-probe=hollow_lantern
"../Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-probe
"../Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-ui-probe
"../Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-interaction-probe
"../Godot_v4.7.2-stable_win64.exe" --headless --path . -- --creator-story-probe
"../Godot_v4.7.2-stable_win64.exe" --path . -- --campaign=hollow_lantern
"../Godot_v4.7.2-stable_win64.exe" --path . -- --demo-creator
"../Godot_v4.7.2-stable_win64.exe" --path . -- --demo-party
"../Godot_v4.7.2-stable_win64.exe" --path . -- --demo-party --text-scale=1.6

# Build + identify a candidate
tools/qa/build_candidate.sh <build-id>

# Asserted combat probe
tools/qa/run_probe.sh cleave cleave_offturn
```

## 12. What to inspect before editing

1. `docs/CAMPAIGN_PACKAGE.md` — the contract you must extend, not duplicate.
2. `docs/AUTHORING_GUIDE.md` — extension classes A–D (content-only,
   definition-table, handler, core change).
3. `src/core/campaign_db.gd`, `content_db.gd`, `save_system.gd` before touching
   loading, validation or persistence.
4. `src/game_state.gd` campaign/save boundaries and `main.gd` campaign screen.
5. `src/core/encounter.gd` pending-decision sections and
   `src/ui/combat_screen.gd:_rebuild_decision()` before combat changes.
6. `git status` / `git diff` — the tree is dirty on purpose; do not reset it.

## 13. Status ledger

**Implemented:** two bundled campaign packages, user-package discovery under
`user://campaigns`, campaign-local instance tables, the bounded Campaign Editor
(metadata/areas/entry/passages, speaker NPCs, node-list dialogue/choices/check/
flags, quests and flag-bound objectives, declared flags, fixed-layout encounters
with shared monsters and victory consequences, placed once-only encounter
triggers, dialogue quest/encounter palette, validate/save/playtest-by-snapshot/
return), registry, manifest/content validation, campaign selection,
campaign-scoped saves with legacy fallback and version refusal, creator/campaign
probes and CLI, plus everything previously supported.

**Verified:** 329/329 suite, `--validate-campaigns`, `--campaign-probe`,
`--creator-probe`, `--creator-ui-probe`, `--creator-interaction-probe`,
`--creator-story-probe` (forced postcombat integration only),
`--creator-combat-probe`, `--creator-combat-reload-probe`,
`--creator-encounter-click-probe` and `--creator-acceptance-probe` in source and
in the exported candidate.
`test_campaign_creator.gd` has 19 tests covering placement, links/start/
unreachable nodes, reference-safe rename/delete, the check/effect/condition
palette, quest/flag editing, encounter layout legality, trigger persistence and
the once-only guard, playtest snapshot isolation, deterministic success/failure,
victory versus defeat, no-repeat after reload, save/reopen, normal-play save/load
and cross-campaign isolation. The editor was inspected windowed at 1280×720 at
1.0 and 1.6 scale; an external OS-input pass exercised the new creator controls.

**Planned:** reference picker and jump-to-field validation, remaining authoring
UX limits, decision registry, data-driven feats/spells, save migration hook,
fixture extraction.

**Unknown / not verified:** the exported executable was probed headlessly and
through the UI probe, but not played windowed by a human; user-package
collision and package-refusal feedback was exercised through probes/tests and
one external create flow, not every failure dialog; malformed JSON syntax has no
dedicated fixture (the refusal test uses valid JSON of the wrong shape), though
it takes the same strict-reader branch; whether old player saves
should be migrated or left as read-only legacy remains a product decision; the
previous note that a newer export is ~8 MB smaller than an older candidate is
still unexplained and non-authoritative (probes decide acceptance).

## 2026-11-13 — unarmed correction status

The two-part correction requested on this date is closed. Part one separated
attack option, armed state and reaction eligibility: ordinary empty hands no
longer threaten, flank, engage or react, verified in
`candidates/unarmed_threat_2026-11-13` and snapshot
`snapshots/2026-11-13_unarmed_threat/`. Part two gave the strike its printed
damage semantics (nonlethal, size-based, separate total, armed-target
provocation, undead/construct immunity), verified in
`candidates/unarmed_2026-11-13` and snapshot `snapshots/2026-11-13_unarmed/`
with the new `--demo-unarmed` / `--unarmed-probe` pair (15 checks). Whole suite
438/438, 5,090 assertions, 32 scripts.

Next bounded candidates, in the order the evidence supports: (1) a second look at
ranged threat: a readied ranged weapon still never threatens, which remains a
stated simplification; (2) natural hourly nonlethal recovery, which needs an
elapsed-time model the build does not have; (3) foundation gaps outside combat
(content breadth, save migration, authoring UX), selected on evidence rather than
adjacency. This list was rewritten after the unarmed unit closed (see the
2026-11-13 nonlethal section at the end of this file); the earlier ordering,
which named the lethal-at--4 option and an invented "improved damage die", is
withdrawn.

## 2026-11-13 — nonlethal state integration (closes the unarmed unit)

The unarmed rules are closed. Improved Unarmed Strike is described exactly as
printed (PHB p. 97): armed, no provocation against armed opponents, lethal or
nonlethal at the attacker's option, and no damage die change. Nonlethal damage is
a derived state (staggered at equality, unconscious and helpless above current hit
points), crossed in both directions by damage and healing, with staggered action
limits in the encounter and the combat screen and with independent incapacities
preserved. Magical healing removes nonlethal damage equal to the amount it cures,
including at full hit points; rest replaces the printed hourly natural recovery.

Verification: 458/458 tests, 5,168 assertions, 33 scripts; candidate
`nonlethal_2026-11-13` passes all seven probes, both validators and the
packed-path audit (144 paths, no leaks); snapshot `snapshots/2026-11-13_nonlethal/`
has a verified manifest. The earlier candidate `unarmed_2026-11-13` is preserved
with `SUPERSEDED.txt` and an `ARTIFACT_NOTE.txt` that records an overwritten
intermediate binary.

Reassessment after closing this unit: the combat foundation no longer has an
obvious adjacent unarmed/feat gap. Monk progression and touch-spell delivery are
out of scope, and natural hourly recovery needs elapsed time. The concrete needs
now visible are non-combat: content breadth is thin (three areas, five
encounters), and save migration/authoring gaps remain recorded. The next bounded
task should be chosen from those rather than from the nearest combat feat.

## 2026-11-13 — encounter resolution, verified inventory, package diagnostics

**Correction.** The reported condition "an encounter now ends when no enemy can
act" was implemented as `can_act()` on both teams. That was wrong: ghoul paralysis
(MM p. 119, 1d4+1 rounds) and timed unconsciousness make a creature unable to act
without defeating it, so paralysing every enemy produced a victory (XP, narration,
campaign effects) and a wholly paralysed party produced a defeat. `_check_end` now
uses `_enemy_defeated` (dead/destroyed or nonlethally unconscious, PHB p. 147) and
`_party_defeated` (dead, dying, stable or nonlethally unconscious).
`tests/test_encounter_resolution.gd` (11 tests / 33 assertions) proves the
distinctions, mixed groups, party recovery and XP-once. The historical sentence
above that "encounters end when no enemy can act" is superseded by this entry.

**Verified content inventory** (from the current packages, not older records):
3 campaigns, 7 areas, 7 encounters (5 playable, 2 QA fixtures), 5 dialogues,
4 quests, 5 shared characters, 3 monsters, 6 spells, 18 items; no creator
template packages in `content/`. Quantity alone is not treated as a foundation
defect and no campaign was authored for breadth.

**Selected non-combat task (done):** unreadable user-package diagnosis. A package
whose `campaign.json` was missing, malformed, or id-mismatched disappeared from
every list silently. Discovery now records the reason, the campaign screen shows
it, and `--validate-campaigns` prints `CAMPAIGN PACKAGE ERROR` and fails. The
exported candidate was checked with a real broken package (exit 1, "Expected key
(line 3)") and after repair (exit 0, package valid).
`tests/test_campaign_discovery.gd` has 7 tests covering the failure and the
recovery without a restart.

**State:** 476/476 tests, 5,225 assertions, 35 scripts; both validators PASS;
candidate `package_diagnostics_2026-11-13`, 110,555,832 bytes, SHA-256
`926b121b78ed16d094f1fde5c2335f2190319fb8c1dfba10cc225c8dc94afc39`; seven probes
51/27/15/30/49/79/49 all PASS; 144 packed paths, no leaks; snapshot
`snapshots/2026-11-13_package_diagnostics/`. Intermediates
`encounter_resolution_2026-11-13` and `campaign_discovery_2026-11-13` are marked
superseded and preserved.

**Next selected task:** authoring-time validation of a saved package's *content*
files. The manifest path is now diagnosed, but a package whose area or dialogue
JSON is damaged still fails later (creator open refuses with its own message; the
runtime validator reports generic content errors). The bounded next unit is to
make the package validator name the damaged file and line for story files too,
with a fixture that corrupts one area/dialogue file and proves refusal plus
recovery. Save migration remains unnecessary: one save format (`SAVE_VERSION` 1)
exists, and `Character.from_dict` already tolerates older saves without nonlethal
state.


## 2026-11-13 — story-file diagnostics and recovery (closes the authoring-diagnostic gap)

The package reader now distinguishes malformed area/dialogue JSON (parser message,
1-based line, package-relative file), valid JSON of the wrong shape (explicitly no
line), missing referenced area files, and semantic reference errors (entity/field
text only). This uses the existing `ContentDB` reader and `ContentDiagnostics`;
there is no second parser or parallel validator. `Game.validate_campaign` exposes
the same diagnostics to both CLI validators and the campaign screen, and a broken
package is refused before any live state is replaced.

`tests/test_story_diagnostics.gd` (9 tests / 69 assertions) covers syntax at line
3 for area and dialogue, shape, missing file, byte-preserving refusal, no partial
load, repair, no cross-package leakage and agreement between the two diagnostic
surfaces. Exported candidate `story_diagnostics_2026-11-13` (110,566,424 bytes,
SHA-256 `1a5ce809ba8eda304315f8a53813599f6f3fe0b100cc85ddacd0cf1572eb2421`) passes
`--encounter-end-probe` (11), `--package-diagnostics-probe` (20) and
`--nonlethal-probe` (30), fails both CLI validators on damaged area/dialogue with
file and line, and passes them after repair. Screenshot at the supported minimum
1280x720 and default Settings text scale 1.0: `runs/shots/package_notice.png`.
Whole suite 485/485, 5,294 assertions, 36 scripts; 144 packed paths, no leaks.

Not claimed: the story-damaged card was below the fold in the capture and was
clicked only through the probe's ordinary button press; shape/semantic errors
remain line-less by design.

**Next selected task:** supported package edits versus existing saves. Both the
creator manifest and saves record `content_version`, but the creator keeps it at
1, so structural edits (removed area, moved entry, removed flag or quest) can be
loaded into a save written for different content. Establish whether any supported
edit actually strands progress or starts the party in an invalid cell, then fix
only the demonstrated case with a safe refusal or a real version change. This is
compatibility verification, not a migration system, and no migration will be
added unless the check shows one is required.

## 2026-11-13 — save/content compatibility (closes the prior selected task)

The prior task is closed: supported edits were reproduced against an ordinary
save before any runtime change. Prose edits and entry moves loaded at the saved
cell; removing a flag declaration kept stored flags; a blocked saved cell loaded
into a wall; an out-of-bounds position silently used the area start; removing a
saved quest silently lost its progress. Removing the saved area and changing
`content_version` already refused safely.

`Game.load_game` now validates saved quests/objectives and the restored cell
(in bounds and walkable, after saved door state) before replacing any live state.
The existing `content_version` equality check remains the author's manual
compatibility marker; the creator still keeps it at 1. There is no migration,
automatic version bump, content hash or teleport. Refusals preserve save bytes,
session, campaign, package and other slots and name the cause; the legacy-save
fallback now only runs when the campaign-scoped file is missing, so unsupported
formats keep their own message.

`tests/test_content_compatibility.gd` (11 tests / 108 assertions) covers harmless
edits, each refusal, byte preservation, unchanged live state and recovery. Whole
suite **496/496, 5,402 assertions, 37 scripts, exit 0**; both validators PASS.
Exported candidate `save_compat_2026-11-13`, 110,575,720 bytes, SHA-256
`71a6e0cad5fb2138ef2c23d791f1ac8953104b0521aa7b9fe361586fd2b22c36`:
`--save-compat-probe` 14/14 and `--save-compat-ui-probe` 9/9 in the exact
executable. The UI probe drives the ordinary Load modal through harmless load,
blocked-cell refusal with the message visible, unchanged bytes/session, and
recovery after restoring the area. Capture: `runs/shots/save_compat_refusal.png`
at 1280x720/default scale 1.0. Package audit: 144 paths; required runtime scripts,
`content/` and assets included; development files, private references, QA
profiles and generated artifacts excluded.

Checkpoint: `builds/qa/snapshots/2026-11-13_save_compat/` — source tarball and
`MANIFEST.sha256` over 479 files (verified 479/479), with the exact hashes in
`CHECKPOINT.md`.

Limits kept explicit: the UI demonstration is headless control activation (the
button's ordinary `pressed` signal), not an OS mouse click or human playtest; the
capture is a rendered 1280x720 window at default text scale 1.0. The previous
limits for diagnostics captures (damaged card below the fold) remain unchanged.

**Next selected task:** campaign-list usability at the supported minimum
1280x720 window. Existing evidence shows only the top of the campaign list in the
capture, so additional or damaged campaigns can sit below the fold; the bounded
unit is to make the list scroll and select cleanly at that size, verified with a
rendered capture. This needs no playtesting and does not reopen save migration.

## 2026-11-13 — campaign-list usability (closes the prior selected task)

The prior task is closed. An isolated profile with 10 listed campaigns (three bundled, five valid user
packages, one 77-character title, one damaged area) plus one malformed manifest
notice reproduced two defects at 1280x720: the list was taller
than its viewport but `ScrollContainer.follow_focus` was false, so Tab could
focus an action at y=2135 (1.0) or y=2887 (1.6) while scroll stayed at 0; and at
1.6 the long title widened the list to 1384 px against a 1204 px viewport,
clipping text and forcing horizontal scrolling. Disabled "Continue latest"/"Load
slot" buttons also remained focusable.

The existing campaign screen now sets `follow_focus = true`, disables horizontal
scrolling, word-wraps card titles and removes disabled actions from the focus
order. There is no new browser, filter, selection model or campaign-management
subsystem; actions remain card-local, and the validation modal/party screen name
the campaign they belong to.

`tests/test_campaign_list_layout.gd` (2 tests / 35 assertions) covers wrapping,
no horizontal requirement, focus scrolling an off-screen action into view,
disabled-focus skipping, and a rebuild after a package disappears. Whole suite
**498/498, 5,439 assertions, 38 scripts, exit 0**; both validators PASS.
Exported candidate `campaign_list_2026-11-13`, 110,577,992 bytes, SHA-256
`217a061b1cac4ae1df4024ac285ff59a94b2220d62f5465518aa1aa019819830`:
`--campaign-list-probe` PASS at 1.0 and at 1.6 set through the real Settings
slider (`scale=1.60`), with no horizontal overflow and focus scrolling.

Native OS input in that executable at 1280x720: mouse wheel reached the bottom
cards; Tab moved focus to an enabled action on a lower card and the list
followed; Validate identified `qa_list_damaged`, then `qa_list_long_title` as
valid; New game on the damaged package refused with its id and area file;
closing it and launching the long-titled campaign showed the matching title on
party selection. Validation return preserved scroll. Back from party selection
returns the rebuilt list to the top, recorded as a clean reset rather than a
defect. Package audit: 144 paths; required runtime scripts, `content/` and
assets are included, while unintended development files, private references, QA
profiles and generated artifacts are excluded.

Limits: native input is real wheel/click/Tab, but each check is one automated
1280x720 window and not a human playtest. The 1.6 party-selection launch (outside
this fix) shows the footer covering the last trait line of one card.

Checkpoint: `builds/qa/snapshots/2026-11-13_campaign_list/`, with the source
tarball and manifest hashes recorded in `CHECKPOINT.md`.

**Next selected task:** party selection at the largest text scale. The 1.6
launch capture shows the footer covering a party card's final trait line; make
the party list scroll or compact at 1.6 and verify it with a rendered capture.

## 2026-11-13 — party selection at 1.6 (closes the prior selected task)

The prior task is closed. At 1280x720 with text scale 1.6, the party grid was
already 1204x689 inside a 1224x439 viewport, every trait label was inside its
card, and wheel scrolling reached all five pregens. The visible bottom crop was
the scroll viewport edge, not footer overlap: Sera's card ended at y=645 while
the viewport ended at y=619, and the footer began at y=648.

The defect was that focus did not follow. Five Tabs put focus on Ysolde's
checkbox at y=657-869 while scroll stayed 0, leaving the focused character and
all of its traits off-screen. The party `ScrollContainer` now follows focus and
each checkbox calls `ensure_control_visible(card)` on focus, revealing the whole
card rather than only the checkbox. At 1.6 focus now scrolls to 250 and the card
occupies y=407-619. No text was reduced, no traits truncated, and Begin/Back
remain fixed below the scroll area.

`tests/test_party_layout.gd` (3 tests / 39 assertions) covers card growth,
labels inside cards, full-card focus reveal, footer visibility, selection
minimum/maximum, Begin with the chosen party, and Back/reopen reset with the
same campaign identity. Whole suite **501/501 tests, 5,478 assertions, 39
scripts, exit 0**; both validators PASS. Candidate `party_layout_2026-11-13`
SHA-256 `bb7bc2901831bc53769dcbfd5935485a99101a869ac250b9637cffb89a380666`,
144 packed paths.

Native OS input in that executable: at 1.6 five Tabs revealed Ysolde's full card,
wheel reached the lower cards, clicks reduced the party to three, Begin launched
it, and Back returned to the campaign list; at 1.0 all five cards stayed visible
and Begin launched the campaign.

Limits: native checks are one automated 1280x720 window each, not a human
playtest. At 1.6 the post-Begin intro modal is horizontally clipped by its fixed
width, including the Close control. That is outside the party grid and is the
next selected task.

Checkpoint: `builds/qa/snapshots/2026-11-13_party_layout/`.

**Next selected task:** make modal content fit at the largest text scale,
starting with the post-Begin intro, so titles, prose and Close/Begin controls
stay inside 1280x720.

## 2026-11-13 — intro modal at 1.6 (closes the UI-chain task)

The shared modal, not intro-specific copy, caused the clipping. At 1.6 the
panel's child minimum was 1665x546 because the heading did not wrap: its minimum
width was 1454 px, overriding the 800 px request and putting Close at
x=1486-1637 outside the window. At 1.0 a long title still widened the panel to
1080 px.

`open_modal` now:

- clamps the panel to the viewport minus a 16 px margin;
- word-wraps the heading with a zero minimum width;
- puts builder content in a vertical ScrollContainer with focus-follow;
- keeps Close shrink-centered in the header and focuses it on open;
- releases modal focus when closing, so an Enter used to dismiss cannot activate
  Pause underneath.

Both scales now produce an 800x520 panel inside 1280x720. At 1.6 the title is
589x165, Close is x=861-1012, content viewport 744x282 scrolls 420 px of content,
and Begin is at y=517-566. At 1.0 the content fits with Begin at y=439-471.
`tests/test_modal_layout.gd` adds 3 tests / 46 assertions for bounds, wrapping,
tall/short content, scrolling, focus-follow, Begin/Close/Escape, focus release
and unchanged campaign state.

Full suite **504/504 tests, 5,524 assertions, 40 scripts, exit 0**; both
validators PASS. Candidate `intro_modal_2026-11-13` SHA-256
`0dc6de1b29bc084511e19dd22e525c9a842717782491c8ce7546b15a455098dc`, 144 paths.

Native OS input: campaign list → party → Begin → intro → mouse/keyboard Begin or
mouse Close → exploration with movement. At 1.6 wheel reached the final note and
Begin; long title wrapped; Settings still fit. Escape is verified by InputEvent
test because SendKeys Escape was not delivered reliably by the QA harness.
Earlier party and campaign-list candidates/checkpoints remain untouched.

Checkpoint: `builds/qa/snapshots/2026-11-13_intro_modal/`.

**Next:** the UI start/load/play chain has no demonstrated material blocker.
Return to the RPG foundation (content, rules, progression), not another screen
sweep.

## 2026-11-13 — foundation reassessment after closing the UI chain

The intro-modal candidate and checkpoint are accepted as the close of the UI
milestone. The start/load/play chain has no demonstrated material blocker, so no
further screen sweep is authorized by this record.

The subsequent foundation assessment found one small player-facing progression
bookkeeping defect, not a content-volume gap: `QuestLog.sync_flags()` reported
`Quest complete` again on every synchronization after completion. The guard in
`src/core/quests.gd` makes completion a one-time transition. The focused
regression is `tests/test_quest_log.gd` (2 tests / 15 assertions); the full
suite is **506/506, 5,539 assertions, 41 scripts**, both validators pass, and
candidate `builds/qa/candidates/quest_log_idempotence_2026-11-13/` (SHA-256
`3f85c47ff9355b9e5efb135b4a9d2f784be5c00ec5228a2f83809ae869302b23`) passes the
exported six-check `--quest-log-probe`.

The broader state is unchanged: rules are tested within the documented scope;
Ashwick has a full save/reload arc; the demo has the bounded E3 loop; Hollow
Lantern has separate entry/quest/save coverage but no single full-arc regression.
Deferred mechanics and broader content remain optional, not demonstrated
requirements of this slice. No human playtest was performed.

## 2026-11-13 — accepted foundation boundary; work paused

The quest-completion idempotence milestone and the current RPG foundation are
accepted as complete for the agreed scope, on the recorded evidence. This is not
a published release and not a claim of human testing, exhaustive verification,
full D&D 3.5 completeness, or a complete Ravenloft adaptation.

- Latest verified foundation candidate:
  `builds/qa/candidates/quest_log_idempotence_2026-11-13/` — 110,586,088 bytes,
  SHA-256 `3f85c47ff9355b9e5efb135b4a9d2f784be5c00ec5228a2f83809ae869302b23`.
- Hash-verified source checkpoint:
  `builds/qa/snapshots/2026-11-13_quest_completion_idempotence/` — tarball
  SHA-256 `5f915a94a472d17f08aad50208809015026fe078e1d0a7bfe93a37af05f179d8`,
  manifest SHA-256 `80c16203e2b9070360f2410ab4dfce9ec5429a9613e6de9f289c36a20ceb1298`.
- The agreed scope is complete on that evidence. Known verification limits
  (including the absence of a human playtest) remain limits, not demonstrated
  defects. Deferred features remain optional and unimplemented.
- Work is paused pending an explicitly authorized new objective. Earlier
  candidates, checkpoints, private references, player data and unrelated
  projects remain untouched.

## 2026-11-14 — proposed Ashwick expansion (assessment only)

The foundation remains closed. This is a proposal, not implementation; no
runtime code, campaign content, candidate or checkpoint was changed.

### Current playable arc

New game at the landing → speak with Maela and optionally use Sense Motive for
the tack-room key → read the ferry notice → cross to the boathouse → open the
locked tack-room door with Maela's key, the hidden spare key, or Open Lock →
fight two drowned ferrymen → recover Ivo's token → return → interact with the
bell, which completes the five-objective quest and shows one fixed victory text.
The trust branch changes the key/potion and a post-battle line, but not the
outcome.

### Missing experience

The arc has investigation-shaped steps but no conflicting account, no decision
with a cost, no optional evidence that changes a reading, no consequence for the
"ring twice for the dead" warning already present in the notice, and no specific
epilogue. It ends on a generic checklist completion rather than a resolved
choice. The journal cannot show a chosen path because there is only one quest.

### Recommended bounded scope: “The Ashwick Ferry — The Second Ring”

Keep the two existing maps: the landing and the boathouse. Add depth, not a new
region. The first act remains intact.

1. **Investigation.** The ledger remains required. Add one file-authored
   `boathouse_strongbox` object on a free boathouse cell, available after the
   ledger, with an Open Lock check. It yields the missing last page
   (`last_page_found`) and an optional, more informed account of why Ivo rang
   late. Failure is retryable; it never blocks the main route.
2. **Consequential account.** After the ledger, Maela's conversation offers a
   mutually exclusive choice: tell her what the ledger says (`maela_truth`) or
   leave her the version she can live with (`maela_mercy`). Both set
   `maela_decision`; each starts one visible side quest (`maela_truth` or
   `maela_mercy`) with the chosen first objective and a shared final objective
   tied to `bell_resolved`. The unchosen side quest never starts.
3. **Three bell resolutions** at the existing bell object, enabled only after
   the token, ledger and `maela_decision`:
   - **Ring once for passage** — Ivo is laid to rest; token removed;
     `bell_resolved`, `ferry_bell_rung`, `ivo_rested`; no combat.
   - **Ring twice for the dead** — `bell_called` and an encounter
     (`ashwick_bell_answer`) using the existing ghoul/zombie statistics. Victory
     sets `bell_answer_survived` and `bell_resolved`; defeat leaves the quest
     unresolved. No completion on the dark path until the fight is won.
   - **Break the token and leave the bell silent** — token removed;
     `bell_resolved`, `bell_silenced`; no combat.
4. **Resolved epilogue.** Maela's dialogue gains flag-gated endings for the
   truth/mercy choice and each bell resolution, including the optional last-page
   detail. The generic victory narration becomes neutral enough for all paths;
   the specific outcome is delivered by Maela after the victory modal. The
   chosen side quest and main objective states remain visible in the Journal.

### Systems used without modification

Existing JSON packages; multiple areas and travel; doors and objects; Search,
Open Lock, Sense Motive and other skill checks; dialogue conditions and checks;
flags; `quest_start`, `set_flag`, `remove_item`, `narration` and `start_combat`
effects; object-interaction autosave; trigger/encounter handling; encounter
victory effects; journal and save persistence. No new map, monster, spell, item
or UI is required. The final choices use the existing bell object, not a new
object-triggered dialogue feature.

### Required content change, not an engine addition

The main quest gains a required `resolve_bell` objective and a
`maela_decision` objective. Ashwick's content version must therefore move from
1 to 2. Existing version checking will refuse old v1 saves with the current clear
message; their bytes are preserved, and no migration is proposed. This is a
content-contract decision, not an engine change.

No engine addition is genuinely necessary. Optional enhancements, not part of
this scope, would be conditional victory text, dynamic journal prose, or
object-triggered dialogue. If none is required, do not add one.

### Source and originality boundary

Ashwick, Maela, Ivo, the ferry, the bell, the token, the strongbox and the new
passenger story are **original material**, not published Ravenloft canon. The
current package already labels them original placeholders. The expansion uses
only Ravenloft-compatible tone supported by the project’s reference record:
isolated settlement, mist, fear and pressure from the dead (*Expedition to
Castle Ravenloft*, Ch. 1 printed p. 5; Ch. 2 printed pp. 23–29, especially the
bounded E3 material at pp. 25 and 36–37). It does not claim Barovia geography,
Strahd, the church, Madam Eva, the Sunsword or any other canonical event. No
Ravenloft Campaign Setting source is present, so no setting-wide claim is made.
Investigation skills follow PHB Ch. 4; the optional encounter uses the already
adapted MM ghoul and zombie entries.

### Acceptance criteria

- A new game can reach the first bell only after the existing ledger/token route
  and a recorded truth/mercy decision; unavailable final options show a reason.
- The chosen side quest is visible in the Journal before the ending, survives
  save/load, and the unchosen side quest is absent.
- Ring once, ring twice and silence produce three distinct persistent outcomes;
  ring twice starts the real encounter and cannot complete on defeat.
- The optional strongbox is retryable, changes the Maela reading when found, and
  never blocks completion.
- Each ending removes the token as specified, sets a unique ending flag, shows a
  specific Maela epilogue, and cannot repeat its reward or completion.
- Save/load after the decision, during the pre-final state, and after each
  ending preserves flags, quest states, removed objects and the resolved ending.
- Old Ashwick v1 saves are refused without altering bytes; no silent migration.
- Both validators pass; focused acceptance covers the three endings and one
  full save/reload path. No human playtest is required for this proposal.

### Implementation boundary

If authorized later, change only `content/campaigns/ashwick_ferry/` and focused
tests/docs. Preserve the foundation candidate and sealed checkpoint; do not
modify shared rules, another campaign, UI or core runtime for this expansion.
