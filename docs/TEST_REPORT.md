# Test Report

Date of latest verification: **2026-11-14**
Project: `C:\Users\Noot Goblin\Downloads\Ravenloft\RL_Edit` (editable copy, no
Git repository). The original tree is untouched.
Godot: `4.7.2.stable.official.ed1daf0bf`
GUT: **9.6.1** (vendored). GUT prints a notice that 9.7.1 is available; that
version was not installed or tested.

## Ashwick Second Ring content milestone — 2026-11-14

Bounded Ashwick content expansion; no shared runtime, UI, rules or other
campaign changed. Content version 1 → 2, with no save-format change or
migration. The final main objective is Maela's `maela_epilogue` conversation.

- Full suite: **517/517 tests, 5,963 assertions, 42 scripts, exit 0**.
- New `tests/test_ashwick_second_ring.gd`: **11 tests, 389 assertions**, exit 0.
  Covers both persistent account choices and their exclusive side quests; all
  three bell outcomes (one ring, two rings plus victory, token broken/silent);
  optional page present, absent, and found after commitment; attempts to repeat
  or contradict a committed choice; ring-twice defeat leaving the token and
  ending incomplete, with a supported retry; save/load after the account
  decision and after each ending; one ordinary entry-to-epilogue path; and a v1
  save refused with its bytes unchanged. Values are read back from the real
  session/save data, not flags alone.
- Adapted `tests/test_ashwick_ferry.gd`: **7 tests, 318 assertions**;
  `tests/test_journal_panel.gd`: **6 tests, 90 assertions**. Existing assertions
  were updated for the new five-objective main quest and content version rather
  than weakened.
- `--validate-campaigns`: **PASS** for `ravenloft_demo`, `hollow_lantern` and
  `ashwick_ferry`. `--validate-diagnostics`: **PASS**, no content problems.
- Candidate `builds/qa/candidates/ashwick_second_ring_2026-11-14/RavenloftFoundationEdit.exe`:
  110,611,128 bytes, SHA-256
  `457e3b887e9105a565a7da25d6a82374e0fe7c9dbd045a87d91cff75034c3253`.
  Additive; the foundation candidate is preserved unchanged.
- Package audit with `tools/qa/pck_paths.py`: **146 packed paths**. Runtime,
  shared content and all Ashwick areas/dialogue/encounters/quests are present;
  no `tests/`, `docs/`, `tools/`, `addons/`, `builds/`, `workspace/`, Markdown,
  PDF, ZIP, QA-profile or `qa_gui.log` path is packed.
- Ordinary exported-window route: fresh isolated `APPDATA`, OS mouse input with
  `--campaign=ashwick_ferry`. Reached the truth account, rang once, returned to
  Maela, scrolled the ordinary dialogue list, chose "Tell me how the crossing
  ended at the bell.", then "What will you tell the village?". The specific
  epilogue appeared and the objective panel changed to **Complete**. Captures
  and the pre-epilogue autosave are in the candidate's `runs/`; see
  `runs/native_route.md`.
- Not verified natively: the mercy account, the ring-twice and silence endings,
  defeat/interruption, optional-page combinations, post-ending repeat dialogue
  and v1 refusal. Those are focused automated checks. No human playtest,
  balance judgment or full permutation replay was performed.

### Closure record (documentation-only)

Accepted functionally on the reported evidence. No executable rebuild, no suite
rerun for these edits, and no regeneration or modification of the sealed
checkpoint. Candidate
`builds/qa/candidates/ashwick_second_ring_2026-11-14/RavenloftFoundationEdit.exe`,
110,611,128 bytes, SHA-256
`457e3b887e9105a565a7da25d6a82374e0fe7c9dbd045a87d91cff75034c3253`. Sealed
checkpoint `builds/qa/snapshots/2026-11-14_ashwick_second_ring/`: tarball
`0ee9fc2e742510f5399073c9f70b622a1bf81d040bdf802b5209516eeda1f716`;
`MANIFEST.sha256` file SHA-256
`ec657214eee59eb814e1ad1e8d5b39f432585d5b8dd4a30dd94bc3b8d0190ad4` (490 files,
verified clean before this documentation change); `CHECKPOINT.md` file SHA-256
`6103368f70bf32724ab65eb9a0df132cd81cb9b0f084ada51baf68768d7e5685`.

The README Tests paragraph and this record were corrected post-checkpoint, so
the working tree intentionally differs from that snapshot. `tools/qa/creator_input.ps1`
carries the two-line window-focus and pre-capture-wait change; it matches the
sealed manifest entry (`c02b138c675435aa81822d8c7e3f053e373a438ee271b6500ca8f95b6dd13f70`)
and was used by the recorded native route. That is an explicit scope exception
for this milestone only. Native evidence covers one truth/single-ring route;
every other branch is automated. No human playtest or balance validation. The
only deletion was disposable isolated-profile test residue; see
`PROGRAM_PROGRESS.md` for the full reconciliation.

## Flat-footed milestone — 2026-11-13

Runtime change: combat-start flat-footedness (PHB p. 133) is now applied instead
of documented as an omission. See `docs/TRACEABILITY.md` row 2a and
`docs/ADAPTATION_LOG.md` entry 38.

- Full suite: **360/360 tests, 4,732 assertions, 25 scripts, exit 0**
  (`All tests passed`). The previous checkpoint was 352/352, 4,697 assertions;
  that result is retained above and below as history.
- New focused file `tests/test_flat_footed.gd`: **8 tests, 30 assertions**, exit
  0. It covers the initial state for every combatant, the Dexterity modifier
  removed from normal and touch AC, the end of the state at the start of the
  first turn, no opportunity attack from a flat-footed reactor, the reaction
  returning once the creature has acted, monster attacks resolved against a
  flat-footed party AC, rogue sneak attack against a flat-footed living target
  and its absence afterwards, and no state after the encounter ends.
- Six existing tests legitimately changed and were updated to assert the new
  rule rather than weakened: `test_moving_out_of_threatened_square_provokes_
  attack_of_opportunity` and `test_moving_out_of_two_threats_provokes_from_both`
  now let the reacting creatures take their first turn first;
  `test_standing_up_provokes_an_opportunity_attack_while_still_prone`,
  `test_unarmed_trip_provokes_the_target_before_the_touch_attack` and
  `test_pick_up_costs_a_move_action_and_provokes` do the same through a
  `target_has_acted` fixture flag; and the Cleave/Improved Trip AC assertions now
  compute the expected AC with the defender's actual flat-footed state.
- Exported candidate **superseded** (it contains the wrong AC handling):
  `builds/qa/candidates/flat_footed_2026-11-13/` `RavenloftFoundationEdit.exe`,
  110,483,112 bytes, SHA-256
  `ac959c5b42b68c42d7c686df6f8f5387b35557627ee16867bec5ba7ddf538b7c`. It is
  preserved unchanged and marked by a `SUPERSEDED.txt` note added beside it; the
  exe and `BUILD.txt` were not modified. `source_head=no-git` (this copy has no
  Git repository).
- Exact-candidate combat probes (automated viewport input on QA fixtures, not a
  human playthrough): `cleave` **PROBE RESULT PASS**
  (`builds/qa/qa/runs/2026-11-13_145911_cleave_cleave/probe.log`) and `prone`
  **PROBE RESULT PASS** (`.../2026-11-13_145922_trip_prone/probe.log`). The Cleave
  log contains the live rule line `QA Cleave Second is flat-footed: no Dexterity
  modifier to AC (PHB p.133).`, so the state is active in the exported build, not
  only in the test harness.
- Not verified: the enemy inspect panel's "(flat-footed)" label was not opened in
  the candidate; no full scenario was replayed in the candidate; no human
  playtest was performed; balance was not retuned and the opening encounters were
  not replayed for difficulty. The panel change is a presentation-only reuse of
  the tested effective AC.

### Correction: only a Dexterity bonus is denied (2026-11-13)

The first version of this milestone removed the raw Dexterity modifier and kept
dodge bonuses, and the documentation said so. The supplied PHB says otherwise on
printed p. 136 (PDF 137):

> "Sometimes you can't use your Dexterity bonus (if you have one). If you can't
> react to a blow, you can't use your Dexterity bonus to AC. (If you don't have a
> Dexterity bonus, nothing happens.) … Any situation that denies you your
> Dexterity bonus also denies you dodge bonuses."

`Rules.armor_class` and `Rules.touch_ac` now subtract `max(0, Dexterity
modifier)`, and `Rules._feat_ac_bonus` drops only dodge-typed feat AC while
Dexterity is denied, so a non-dodge bonus (exercised with `ac_misc`) is
untouched. Helpless targets already used Dexterity 0 and now also lose dodge
bonuses, which corrected `test_helpless_target_has_dexterity_zero` (8 → 7) and
the Dodge clause of the Combat Expertise test.

- Full suite after the correction: **366/366 tests, 4,753 assertions, 25
  scripts, exit 0**. The 360/360, 4,732 result above is the pre-correction run,
  retained as history.
- `tests/test_flat_footed.gd`: **14 tests, 51 assertions** — positive, zero and
  negative Dexterity, armor-limited Dexterity, dodge denial with a retained
  non-dodge bonus, normal and touch AC, clearing at the first turn, and
  panel/roll parity through `CombatScreen.effective_ac`.
- Windowed evidence in a real window with ordinary controls (isolated `APPDATA`
  `builds/qa/profile_inspect`): `--demo-inspect --inspect-probe` **PASS**. Round 1
  showed `QA Inspect Duelist` (+3 Dexterity, Dodge) as "HP 60/60 • AC 12
  (flat-footed)" and the zombie (-1 Dexterity) as "AC 11 (flat-footed)" with a
  standing AC of 11 too. At 1.6 — set by clicking the real Text size slider in
  Settings and asserted back at 1.6 — the marker was still shown and the panel
  text stayed inside the panel. After End turn the same panel read "AC 16" with
  no marker, and the attack line in that window read `vs AC 12`, matching the
  panel. Captures: `builds/qa/runs/2026-11-13_151001_inspect_panel/shots/`.
- Method limit: the probe is an automated viewport-input script driven through
  the real control tree, not a human usability study. The captures were read by
  the model; no human reviewed them.
- Corrected candidate:
  `builds/qa/candidates/flat_footed_corrected_2026-11-13/`
  `RavenloftFoundationEdit.exe`, **110,490,504 bytes**, SHA-256
  `51b00508cdb8167a94918818281074f11f484388982bae29b78ff32c2b256a42`
  (`source_head=no-git`). Its own `--validate-campaigns` passed all three
  packages, and the asserted probes passed in that exact executable:
  `--demo-inspect --inspect-probe` **PROBE RESULT PASS** (same checks and same
  panel text as in source; captures under
  `builds/qa/runs/2026-11-13_151253_inspect_panel_candidate/shots/`), `cleave`
  **PASS**, and `trip/prone` **PASS**.
- Packaging defect found and fixed by this milestone's probe: QA evidence written
  under `builds/` was packed into the exported executable (the first corrected
  build was 112,284,872 bytes and contained the run's PNGs). `export_presets.cfg`
  now excludes `builds/*`; the rebuilt executable packs no probe image
  (`trip_inspect_01_panel_flat` absent) and is 1.79 MB smaller. That first package
  was deleted before acceptance rather than kept, because it was never a
  candidate for play; no earlier milestone's candidate was touched.

## Ranged-melee milestone — 2026-11-13

Two printed rules that are easy to confuse, implemented and tested separately.

> **PHB p. 140 (PDF 141).** "If you shoot or throw a ranged weapon at a target
> engaged in melee with a friendly character, you take a -4 penalty on your
> attack roll because you have to aim carefully to avoid hitting your friend.
> Two characters are engaged in melee if they are enemies of each other and
> either threatens the other. (An unconscious or otherwise immobilized character
> is not considered engaged unless he is actually being attacked.) If your
> target ... is at least 10 feet away from the nearest friendly character, you
> can avoid the -4 penalty, even if the creature you're aiming at is engaged in
> melee with a friendly character. Precise Shot: If you have the Precise Shot
> feat (page 98), you don't take this penalty."

> **PHB p. 135 (PDF 136).** "Making a ranged attack provokes attacks of
> opportunity from opponents that threaten you."

(A) is about the target's neighbours and changes the attack roll; (B) is about
 the attacker's neighbours and produces a reaction. Neither is used as a proxy
for the other, and the log names whichever applied.

- `Encounter._into_melee_penalty` evaluates (A): engagement by the printed test
  (enemies of each other, and either threatens the other), the 10-ft escape, a
  helpless target counting as not engaged, and Precise Shot. `Rules.attack`
  accepts the result as `into_melee_penalty`, so the -4 is inside the auditable
  roll, and `Rules.format_attack` prints `shooting into melee -4`.
- `Feats.CATALOG` gains `precise_shot` (p. 98) with no passive modifier and the
  printed prerequisite `point_blank_shot`; `Feats.has_active` therefore honours
  the requirement, and a character with Precise Shot alone gets no exemption.
- Ranged spells: Complete Arcane p. 85 makes any attack-roll spell a weapon and
  p. 73 gives Precise Shot the same exemption for ranged spells, so Scorching
  Ray takes the penalty and Magic Missile (no attack roll) does not. Casting
  still provokes once; firing the ray adds no second opportunity attack.
- The p. 135 provocation message no longer says "fires into melee": it states
  that the attacker is threatened, and it is emitted independently of (A).
- Full suite: **378/378 tests, 4,794 assertions, 26 scripts, exit 0**.
  `tests/test_ranged_melee.gd`: **12 tests, 41 assertions** — penalty and its
  exact -4 against an identical-seed control shot, 10-ft escape with a reach
  ally, thrown weapons, melee unaffected, Precise Shot on and off (and without
  its prerequisite), provocation without penalty, penalty without provocation,
  ray penalty, ray without engagement, one provocation per cast, Magic Missile
  excluded.
- Candidate: `builds/qa/candidates/ranged_melee_2026-11-13/`
  `RavenloftFoundationEdit.exe`, **110,492,248 bytes**, SHA-256
  `e4cde889f5fe812d4671031552f24da4653f115fb358f2467b8362e50dbe6995`. In that
  exact executable `--validate-campaigns` and `--validate-diagnostics` both
  passed, and the `inspect`, `cleave` and `trip/prone` probes all reported
  `PROBE RESULT PASS`. The `flat_footed_corrected_2026-11-13` build is preserved
  and marked `SUPERSEDED.txt` because this runtime change postdates it.
- Limits: no windowed probe covers the ranged penalty (the rule is verified by
  the unit tests above and by the exact-candidate regression probes only);
  cover, concealment, cover-provoked misses and per-round "actually being
  attacked" tracking remain unmodelled; no human playtest.

### Windowed ranged verification and milestone closure (2026-11-13)

The earlier `inspect`, `cleave` and `trip` probes are regressions: none of them
touches the into-melee penalty or the provocation, so citing them proved nothing
about the ranged rule. A dedicated windowed probe now covers it.

- Fixture `--demo-ranged` (`_qa_ranged_demo`): QA clones only, no shipped
  character edited — a crossbow shooter, a shooter with Point Blank Shot and
  Precise Shot, a third shooter aimed at an unengaged target, the prepared wizard,
  and a fighter who is the friendly character in the melee. Two enemies: "QA
  Ranged Target" and a rooted "QA Clear Target" (the zombie AI would otherwise
  close in and make the control case engaged — the fixture clone has `speed_ft`
  0, no shipped monster changed). Cells are assigned by character after `begin()`
  and the geometry preconditions are asserted before any attack.
- Probe `--ranged-probe` drives only ordinary controls: `Attack` + target, the
  enemy row's `Attack`, `Cast spell` → `Scorching Ray` → target, and `End turn`
  until the wanted actor is active. It reads the rendered combat log; the
  "must not appear" checks use the exact lines that action added, because the
  label scrolls.
- Result: **49 checks, `PROBE RESULT PASS`** in source and again in the exact
  accepted candidate. Evidence:
  `builds/qa/runs/2026-11-13_153702_ranged_probe_candidate/` (`probe.log`,
  `shots/00_start`, `01_engaged_penalty`, `02_precise_shot_exempt`,
  `03_unengaged_control`, `04_ray_into_melee`). The rendered breakdown reads, for
  example, "QA Ranged Shooter attacks QA Ranged Target with Light Crossbow:
  d20(4)+1 = 5 vs AC 11 | shooting into melee -4 | MISS" followed by "shooting
  into melee -4: QA Ranged Target is engaged with QA Clear Shooter (PHB p.140)."
- Scope of that evidence: it shows the -4 when the target is engaged with an ally
  at 5 ft., its absence for an unengaged target, its absence for a Precise Shot
  attacker against the same engaged target, and the ray taking the -4 with one
  provocation line and no creature reacting twice. It does not exercise the
  10-ft escape (unit test only) or the unmodelled cover/concealment and
  "actually being attacked" cases.
- Accepted candidate: `builds/qa/candidates/ranged_windowed_2026-11-13/`
  `RavenloftFoundationEdit.exe`, 110,501,736 bytes, SHA-256
  `2aa5c030dc46577f35d6df727e00e5edf34d859bde8ab7e08de6f623220278a2`.
  `--validate-campaigns`, `--validate-diagnostics`, `--ranged-probe`,
  `--inspect-probe`, `cleave` and `trip/prone` all passed in that executable.
  `ranged_melee_2026-11-13` is preserved with `SUPERSEDED.txt`: it predates the
  probe, so it could not demonstrate the rule in a window.
- Package hygiene, from the embedded path list (`tools/qa/pck_paths.py`, 144
  entries): no `builds/`, `workspace/`, `snapshots`, `tests/`, `tools/`, `docs/`,
  `.py`, `SUPERSEDED`, `BUILD.txt`, `trip_*` or `profile_` path is packed; 58
  `res://src/*`, 31 `content/*` (characters, monsters, demo encounters), 32
  assets, `res://project.godot` and `res://src/main.gd` are present. Exported
  content paths are stored without the `res://` prefix in this export; the
  executable loads and validates them, so it is recorded rather than "fixed".
- Source snapshot and manifest: `workspace/snapshots/2026-11-13_ranged_closed/`
  (`RL_Edit_source.tar.gz` and `MANIFEST.sha256` over 457 files; the exact
  hashes are recorded in that folder's `CHECKPOINT.md`, so they cannot drift out
  of date against later documentation edits).

## Automated tests — retained history (2026-11-07)

**2026-11-07 run: 339 tests, 4,324 assertions, exit 0; creator file
33 tests, 609 assertions; pending-edit probe 37 checks.** The detailed block
below is the retained Cleave-era run kept as history.

Current teardown observation: the full suite was clean. The focused creator
suite passed 33/33 tests and 609 assertions, exited 0, and then printed this
exact unresolved teardown warning:

```
WARNING: 5 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
ERROR: 2 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
```

This is retained as an **unresolved teardown warning**, not claimed fixed. Its
cause has not been established. Reproduction scope: the focused
`tests/test_campaign_creator.gd` GUT process only; the 2026-11-07 full-suite log
had no ObjectDB/resource shutdown warning. No cleanup investigation was opened
merely to silence it. Scope was widened by the 2026-11-08 Journal triage below
to include that focused suite and the focused Ashwick process (2 ObjectDB
instances / 1 resource in use); neither is assumed to share this warning's cause.

### Journal overlay triage (2026-11-08)

A blank Journal overlay was reported during the exported Ashwick playthrough.
The exported candidate was preserved unchanged (SHA-256
`8a3f067b142411039afef7324739126c664b8944baa0751d5e527053d31d4f5f`) and the
observation reproduced from a copy of the completed Ashwick `slot1` save at
1280x720 and the default 1.0 text scale: the modal showed only its "Journal"
header and an empty body with a tiny scrollbar, and closing/reopening produced
an identical capture. The pre-bell save itself no longer exists — both retained
slots were overwritten by the completed landing save — so that state is
reconstructed with an ordinary save/load fixture, not claimed as a fresh
playthrough.

Cause (measured, not inferred): `Panels.journal()` put a `RichTextLabel` with
`fit_content = true` inside a `ScrollContainer` without horizontal expansion, so
the label laid out **1 px wide** and **6,831 px tall** and all content fell
outside the visible body. Quest data was present throughout; the view could not
show it. Source probe: `text_size=(1.0, 6831.0)`, `scroll_size=(720.0, 420.0)`,
`content_h=6831`.

Fix (layout only; no quest, save or campaign-data change): the Journal label now
uses `SIZE_EXPAND_FILL` horizontally and its scroll container disables
horizontal scrolling, so text wraps at panel width.

`tests/test_journal_panel.gd` replaces the temporary layout probe and covers the
established cause plus every reachable state: an empty quest log, the active
Ashwick quest (all five objectives), a save/load round trip with two objectives
done, the completed quest after reload, a second campaign (`hollow_lantern`),
and 1.6 text scale at the 720x420 content size the 1280x720 modal provides. Its
assertions read rendered text and measured layout (parsed text, label width
against the scroll area, wrapped line count, content height, visible overlap),
not quest flags alone.

- Focused: **6/6 tests, 85 assertions, exit 0**.
- Full suite: **352/352 tests, 4,697 assertions, 24 scripts, exit 0**.
- `--validate-campaigns` and `--validate-diagnostics`: **PASS**, exit 0. Both
  need the `--` user-argument separator (`... --path . -- --validate-campaigns`);
  without it Godot ignores the flag and starts the GUI.
- Candidate: `workspace/candidates/journal_fix_2026-11-08/RavenloftFoundation.exe`,
  110,481,944 bytes, SHA-256
  `78b8c2e9d5d0c6b99c5241d491f048f95dc79a165eee6f358261a143b65e4292`. The original
  `ashwick_ferry_2026-11-08` candidate is untouched.
- Exported check with ordinary OS input at 1280x720: Continue from the copied
  completed save, then open Journal at 1.0 — full-width body showing "Completed:
  The Ashwick Ferry" and the recorded events; close and reopen gives a
  byte-identical capture. With Text size set to 1.6 through the Settings slider,
  the Journal wraps at panel width and scrolls vertically with no blank body.
  Captures: `workspace/qa/journal_triage/fixed/{menu_1p0,journal_1p0,
  journal_1p0_reopen,menu_1p6,explore_1p6,journal_1p6}.png`.
- Method limit: passing `--text-scale=1.6` to the exported executable (with or
  without the `--` separator) did not change the scale, so the native 1.6 check
  used the in-game Settings slider instead.
- Active-quest check in the same candidate, from a fresh isolated profile
  (`workspace/qa/journal_triage/active_profile/`, separate from the preserved
  evidence profiles): Choose a campaign → Ashwick New game → Begin the campaign,
  walked to Maela and spoke to her with ordinary OS clicks ("Objective complete:
  Speak with Maela Vey at the landing."), then set Text size to 1.6 with the
  Settings slider. The readout capture (`settings_1p6_readout.png`) and the
  resulting `settings.cfg` (`text_scale=1.6`, copied as `settings_at_1p6.cfg`)
  are the actual settings record; no command-line argument is involved. The
  Journal then showed the quest title, the wrapped summary,
  `[x] Speak with Maela Vey at the landing.`, four incomplete `[ ]` objectives
  and a vertical scrollbar (`active_journal_1p6.png`).
- Save/relaunch: saved to slot1 through the Save game panel (read back as
  "2026-11-08 19:29:15 — The Ashwick Ferry — Landing …"), preserved separately as
  `workspace/qa/journal_triage/active_quest_save_preserved/slot1.json`
  (`abf9d953d66937ccc0a4cac4e5f74b334748b8841553b62608effbf7e61e635e`) with the
  autosave
  (`55141c909c67b80fea1e373a2d757f8ec6e244bf90b25804f53dc2e8868b74b4`); the JSON
  records quest `active` with `speak_maela: true` and the other four objectives
  false. The process was then closed by PID — the intended pause-menu Quit click
  missed its button in the enlarged layout, so an in-game Quit is **not**
  verified here, and that miss is not treated as an application defect. The same
  executable and profile were relaunched and the save opened through the ordinary
  Continue entry: Journal showed the identical title, summary, one `[x]` and four
  `[ ]` objectives, wrapping and scrolling (`journal_after_reload_1p6.png`). No
  combat and no further scenario steps were played.
- Packaging: `pck_list.py` read the embedded pack of this candidate — 121 paths,
  all three campaigns (`content/campaigns/*`), `content/shared/*`, areas,
  dialogue and the runtime `src/`/`scenes/`/engine assets present; no
  `workspace/`, `docs/`, `tests/`, `tools/`, PDF, reference, save or settings
  path. The 29,864 byte reduction versus `ashwick_ferry_2026-11-08` is therefore
  **not** claimed as workspace exclusion alone: the filter is proven by
  inspection, but the runtime change also alters compiled size. Two older
  Ashwick candidates do package QA probe scripts (10 and 6 `workspace/qa`
  paths); they are retained unchanged and marked `LOCAL_ONLY.txt` (local
  evidence, not for distribution).
- Build identity: the untracked-file hash now uses null-delimited paths
  (`git ls-files -z --others --exclude-standard | sort -z | xargs -0 -r
  sha256sum`). In a disposable repository outside the project, the new pipeline
  hashed three files including `with space.txt` identically twice and changed
  when a file was removed; the previous line split that name into `with` and
  `space.txt` and aborted the first export attempt (exit 123, no `BUILD.txt`),
  so the successful `journal_fix_2026-11-08` identity record was written by the
  fixed tool. `worktree_diff_sha256` no longer matches the working tree because
  these docs were edited after the export; that does not retroactively change
  what the build ran with, and the package itself proves the edited filter was
  in effect.

Historical scale claims, reviewed rather than re-run: no retained profile or
record contains `text_scale=1.6` (every preserved `settings.cfg` holds 1.0), and
`--text-scale=1.6` has no observed effect on an exported executable. Earlier
reports' "1.6 text scale" labels therefore rest on captures whose UI is visibly
enlarged, not on a settings record, and are now marked *scale unverified* where
that is the only evidence. Those passes' other results stand as reported: the
exercised action worked, the control was visible, the save/load route passed and
native OS input reached the target. This review does not invalidate every
earlier scale check — only the claim that 1.6 was applied.

Teardown: this focused Journal suite exits 0 and then prints the same warning
class as the focused Ashwick process — **2 ObjectDB instances leaked and 1
resource still in use at exit**. Its cause is not established, it is not assumed
to match the creator-suite warning, and it is not claimed fixed. The full suite
in this run was clean.

Command:

```bash
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Result (exit status 0):

```
Scripts              20
Tests               296
Passing Tests       296
Asserts             3654
Time               4.084s
---- All tests passed! ----
```

No failing, pending or risky tests were reported. This is the final run after the
Cleave off-turn increment: the earlier batches (shared skill resolution, the feat catalog
with the committed Power Attack and Combat Expertise trades, the +2/+2 skill
feats, the proficiency feats, Extra Turning and Improved Turning, the
non-proficiency penalties, take 10/20, the holy-symbol requirement and corrected
Multiattack/Toughness data), the turn-undead baseline, Trip/prone, Improved Trip
and Cleave.

Historical teardown note (earlier runs): normal runs printed 2–3 `ObjectDB
instances were leaked at exit` plus `1 resources still in use at exit`, while two
normal runs and one `--verbose` run were clean. The verbose run named no project
object. Every run still exited 0 and passed all tests. This is recorded as
intermittent test-process teardown noise, not claimed fixed and not reported as
a gameplay failure. The current 2026-11-07 focused-run warning is recorded
separately above.

### Test scripts

| Script | Focus |
| --- | --- |
| `tests/test_rules.gd` | Ability modifiers, AC, attack bonuses, saves, skills, critical confirmation, range increments |
| `tests/test_feats_skills.gd` | 45-skill catalog, trained-only, armor breakdown, Skill Focus/Alertness, the fourteen +2/+2 skill feats and their stacking, proficiency grants and non-proficiency penalties, synergies, typed stacking, take 10/20, Aid Another, opposed ties, rank caps, Dodge, Weapon Focus, Weapon Finesse, Point Blank Shot, Improved Initiative, Toughness persistence, Multiattack, unknown feats, shipped-content validation, holy symbol, take controls, crate take 20 |
| `tests/test_character.gd` | HP/damage, dying/stable/dead, conditions and expiry, equipment effects, inventory, serialization |
| `tests/test_combat.gd` | Initiative order, action economy, movement, 5-ft step, AoOs, targeting, spells, DR, monster behavior, victory/defeat, Power Attack committed duration, expiry, per-actor state, weapon modes and damage cases, and Combat Expertise's prerequisite, cap, pending/committed timing, dodge AC states, opportunity attack, expiry, Power Attack combination and combat-end cleanup |
| `tests/test_exploration.gd` | Start state, grid movement/turning, walls, doors/lockpick, search loot, shrine rest, encounter triggers, bell objective, look text |
| `tests/test_narrative_and_save.gd` | Content validation, missing dialogue, quest effects, conditional choices, skill-check actor, Corvin combat start, save/load round trip, combat save refusal, invalid content, missing audio, party validation |
| `tests/test_integration.gd` | Full demonstration loop: talk → accept quest → fight zombies → loot clapper → open crypt → parley/fight Corvin → ring bell → victory → save/reload |
| `tests/test_smoke.gd` | Entry-scene/engine smoke checks |
| `tests/test_ui.gd` | Instantiates Main, ExplorationScreen, CombatScreen, DialoguePanel, character sheet, inventory, journal, settings and saves panels; checks the 1.6× four-member sidebar; verifies the committed Power Attack and Combat Expertise controls, their post-attack locks, actor switching and the dagger mode selector, plus a binding button entering capture mode |
| `tests/test_travel.gd` | Demo-route travel, staging state, save/load and dialogue refusal |
| `tests/test_phase3_town_square.gd` | Area registry, E3 entry effect and featured tracker, encounter and infected-zombie stats, Ashlyn dialogue, one-time barricade repair, repair autosave through the interaction path, repair through the real Save Game panel, failed-autosave honesty, full save/quit/load/return loop and legacy saves |
| `tests/test_cleave.gd` | Cleave: prerequisites, a drop by the actor's own melee attack, eligible targets and reach, same weapon and base bonus, no movement, once per round, no chaining, decline, duplicate submission, invalidated target, Power Attack/Combat Expertise, Improved Trip's granted attack |
| `tests/test_cleave_offturn.gd` | Off-turn Cleave: an opportunity attack that drops a creature offers Cleave to the attacker (not the active combatant), no turn ownership transfer, the opportunity attack spends no action, decline, resolve-then-resume of the interrupted route, duplicate submission, once per round in both own-turn/off-turn directions, target modifiers re-evaluated (cowering, helpless, prone, reach), encounter-end invalidation |
| `tests/test_extensibility.gd` | Foundation contracts: shipped content validates against the effect/condition registry, stable vocabulary, unknown effect and condition errors, required identifier fields, missing item/quest/encounter/area/skill references, registry/lookup consistency, and a data-only positive control (registered shapes with real ids need no new code) |
| `tests/test_improved_trip.gd` | Improved Trip: prerequisites, +4 only on the attacker's check, no unarmed provocation, the granted follow-up (take/decline), follow-up attack selection (equipped melee mode or unarmed, ranged refused, no equip change), turn/encounter invalidation |
| `tests/test_turn_undead.gd` | Turn undead: eligibility and 3 + Cha uses, standard-action and use consumption, Table 8-9 thresholds, 2d6 + level + Cha damage, 60-ft range, closest-first ordering and capacity exhaustion, Knowledge (religion) +2, explicit Hit Dice, ghoul +2 turn resistance gating eligibility/capacity/destruction, turn versus destruction, 10-round duration, path-aware fleeing within one move action, cornered cowering and its expiry, the four 10-ft approach distinctions, skipping turned undead, exhausted uses, Extra Turning stacking and non-turner rejection, Improved Turning effective level/cap/damage, save round-trip, legacy and current save payloads, rest recovery, no-softlock, one-time XP, defeat routing |

### Combat Expertise batch verification (2026-11-04)

- Full suite: **206/206 tests, 2,224 assertions, 13 scripts**, exit 0, after the
  final assertion repair. Focused runs: `tests/test_combat.gd` **36/36 tests, 235
  assertions** and `tests/test_ui.gd` **14/14 tests, 77 assertions**, both exit 0.
- Source rule (PHB p. 92): Intelligence 13; trade up to 5 points of melee attack
  bonus for an equal dodge bonus to AC, never more than the base attack bonus.
  Dodge bonuses are lost when the defender is denied Dexterity (p. 135).
- Three distinct states are tested independently: the pending UI amount grants
  nothing (AC unchanged, no effect on the character), the committed amount on a
  qualifying melee attack (the activating attack takes the penalty and the dodge
  bonus applies from then on), and expiry at the start of the actor's next turn.
  The amount cannot be changed after commitment; the message states that it must
  be chosen before the attack roll.
- Nonqualifying actions: a ranged crossbow attack and a thrown attack resolve
  normally, receive no Combat Expertise penalty, and discard the pending choice
  without committing it. A dedicated regression test proves that an opportunity
  attack cannot activate a pending choice — PHB p. 92 makes the choice when you
  use the attack action or full attack action in melee — while an already
  committed amount does apply to that opportunity attack.
- AC paths: normal AC, touch AC, flat-footed AC (bonus omitted), helpless (bonus
  omitted) and stacking with Dodge (+1 general adaptation) were checked. The
  incoming zoo-level attack test asserts the defender's AC used by the enemy
  attack equals the committed dodge value.
- Power Attack interaction: both are separate per-actor states, their penalties
  combine (-4 at 2/2), Power Attack still adds damage, Combat Expertise adds no
  damage and the committed dodge AC, and both survive an opportunity attack and
  expire together at the next turn. Switching active characters preserves the
  other actor's commitment.
- Temporary loss: reducing Intelligence to 12 after commitment suspends the dodge
  bonus and the AC returns to baseline; restoring 13 resumes it without a new
  choice. `Encounter.finish()` removes the transient effect so it cannot leak
  into exploration or saves; the feat itself survives a save round trip.
- Source-native QA used the `--demo-combat-expertise` window and visible controls:
  AC 17 with the control visible, a pending 2 with AC still 17, a committed
  longsword attack at -2/-2 with AC 19, an incoming slam at "vs AC 19 — MISS", an
  opportunity attack showing both penalties, and round 2 with both controls reset
  to 0 and both expiries logged. Evidence:
  `docs/screenshots/qa_ce_source_start.png`, `qa_ce_source_pending.png`,
  `qa_ce_source_committed.png`, `qa_ce_source_offturn.png`,
  `qa_ce_source_after_turn.png`. The fixture is a temporary Kaelen-derived fighter
  with Int 13, Combat Expertise and Power Attack, a longsword, one turned zombie
  and one incoming zombie; shipped pregens and content are unchanged.
- Deferred rather than invented: fighting defensively (PHB p. 139), total defense
  (p. 141), full attacks and one-handed weapons wielded in two hands. "Until your
  next action" is read as until the start of the character's next turn because
  the engine has no immediate/swift-action subsystem and opportunity attacks are
  reactions.
- Exported candidate `../.ravenloft-candidate-featskills6/RavenloftFoundation.exe`
  (110,132,152 bytes, SHA-256
  `ee786089b2d3be679aaf2008b9f543423a040969f862cd09ce8678b0e4855bf`), built from
  HEAD `06f4abd` plus the uncommitted changes, then launched windowed with
  `-- --demo-combat-expertise` under an isolated `APPDATA`. In its visible
  controls: AC 17 with both controls at 0; Combat Expertise 2 and Power Attack 2
  selectable together with AC still 17 and the pending label; the longsword
  attack resolved at -2/-2 for 6 damage, raised AC to 19 and locked both
  controls; ending the turn produced the turned zombie's flight and an attack of
  opportunity at -2/-2 for 11 damage; the incoming zombie's slam was logged as
  `d20(9)+2 = 11 vs AC 19 | MISS`; the next turn reset both controls to 0,
  returned AC to 17 and logged both effects ending at the start of the turn.
  Evidence: `docs/screenshots/qa_ce_candidate6_start.png`,
  `qa_ce_candidate6_pending.png`, `qa_ce_candidate6_power_attack_pending.png`,
  `qa_ce_candidate6_committed.png`, `qa_ce_candidate6_offturn.png` and
  `qa_ce_candidate6_after_turn.png`. A first launch attempt used the wrong
  working directory and never opened a window; that invocation was rejected
  rather than counted as evidence. No full E3 replay was performed.

### Power Attack correction and verification (2026-11-04)

- Full suite: **194/194 tests, 2,092 assertions, 13 scripts**, exit 0 (superseded
  by the batch-6 run above). Focused
  runs also passed: `tests/test_combat.gd` **27/27 tests, 138 assertions** and
  `tests/test_ui.gd` **12/12 tests, 51 assertions**. The prior 185-test batch-5
  result described a per-attack reset; that interpretation was incorrect and is
  superseded by this section.
- Source rule (PHB p. 98): one amount, capped by base attack bonus, is committed
  for the character's melee attacks and relevant attacks of opportunity until
  the start of the character's next turn. `Encounter.power_attack_committed` is
  keyed per combatant, is erased in `_begin_turn`, and cannot be replaced after
  the standard action is used. Switching the active UI actor preserves another
  actor's commitment.
- Weapon modes are explicit: `attack_modes` supports melee, thrown and ranged;
  legacy `range_increment`-only data remains ranged, and ordinary weapons default
  to melee. A dagger's melee attack is melee; its thrown attack is explicit and
  gets Strength but no Power Attack. Crossbows are projectile/ranged. Opportunity
  attacks use the committed amount and melee mode.
- Damage cases exercised: ordinary one-handed, light (including dagger), synthetic
  two-handed, unarmed, natural, critical multiplier, ranged during an active
  choice, thrown, and opportunity attack. One-handed weapons wielded in two hands
  and full-attack sequences are not implemented; no shipped two-handed weapon
  exists.
- Source-native QA used the `--demo-power-attack` window and visible controls:
  Power Attack 2, a 4-damage dagger melee attack, the amount still 2 afterward,
  a turned zombie's flight provoking an opportunity attack at -2, and a round-2
  reset to 0. The QA fixture derives a temporary fighter from Kaelen with a
  dagger and a low-AC/no-DR zombie; shipped pregens and content are unchanged.
  Evidence: `docs/screenshots/qa_power_source_final_committed.png`,
  `qa_power_source_final_attacked.png`, `qa_power_source_final_reset.png`.
- Exported corrected candidate
  `../.ravenloft-candidate-featskills5b/RavenloftFoundation.exe` (110,123,432
  bytes, SHA-256
  `c7c49ef57ec32345faad2ac0cff9a781544f2e957c90bc13c42d27e4e0fe6e55`) was
  launched windowed with `-- --demo-power-attack` under isolated `APPDATA`; the
  same feature-specific checks passed in that exact executable. Its evidence is
  `docs/screenshots/qa_power_candidate5b_native_committed.png`,
  `qa_power_candidate5b_native_attacked.png`, and
  `qa_power_candidate5b_native_reset.png`. A first launch omitted the `--`
  separator and remained on the main menu; that invocation was rejected rather
  than counted as feature evidence. A headless candidate smoke check also exited
  0 and reached `QA POWER ATTACK READY`. No full E3 replay was performed.
- No shipped pregen has Power Attack; the existing JSON `feats` field is the
  authoring hook. Candidate `featskills5` predates this correction and is not the
  corrected artifact.

### Turning-feat batch verification (2026-11-04)

- Focused run `tests/test_turn_undead.gd`: **36/36 tests, 173 assertions**, exit 0.
- Feats/skills run: **36/36 tests, 1,025 assertions**, exit 0.
- Full suite at the batch-4 boundary: **180/180 tests, 1,981 assertions, 13 scripts**, exit 0 (superseded by batch 5 above).
- Source-grounded checks: Extra Turning (PHB p. 94) is repeatable and adds four
  uses per taking; the test covers 4 → 8 → 12. A Fighter with the feat is still
  rejected by the turn-undead prerequisite. Improved Turning (p. 96) adds one
  effective cleric level; the same d20 check leaves a 4-HD ghoul unaffected at
  level 3 but turns it at effective level 4, with the expected 2d6+5 damage.
  Save/load retains both feats and recomputes the allowance from `turn_undead_used`.
- No shipped pregen has either feat; they are available through the existing JSON
  `feats` field. No new native controls were added.
- Exported candidate `../.ravenloft-candidate-featskills4/RavenloftFoundation.exe`
  (110,113,448 bytes, SHA-256
  `56c1a7d3645b640327e9bc41c8e31fa7db2bd1ba1b79850ad71ef8cf86dd925a`), built
  from HEAD `06f4abd` plus the uncommitted changes. Copied outside the source
  tree and launched with `--headless --quit-after 90 -- --demo` under an isolated
  `APPDATA`: exit 0, no `SCRIPT ERROR`, `Parse Error` or validation failure.

### Proficiency batch verification (2026-11-04)

- Focused run `tests/test_feats_skills.gd`: **36/36 tests, 1,025 assertions**,
  exit 0.
- Full suite: **177/177 tests, 1,960 assertions, 13 scripts**, exit 0.
- Source-grounded checks: Armor Proficiency (PHB p. 89), Exotic Weapon
  Proficiency (p. 94), Martial Weapon Proficiency (p. 97), Shield and Simple
  Weapon Proficiency (p. 100). The tests cover positive proficiency, the -4
  negative path, exact-selection isolation, armor/shield ACP on attacks and
  movement skills including Ride, armor+shield attack-penalty stacking, armor
  prerequisite chains, the Exotic BAB +1/Str 13 exceptions, and shipped-pregens
  remaining proficient.
- Save behavior: current lists round-trip under `proficiency_schema` 2; a legacy
  Fighter payload without the schema receives one-time class armor/shield
  defaults and does not become retroactively non-proficient.
- Regression caught before export: proficiency matching was narrowed from
  arbitrary substrings to exact names plus the known masterwork prefix. A
  short-sword proficiency no longer satisfies `Weapon Focus (sword)`.
- Exotic Weapon Proficiency is tested with a synthetic exotic weapon because no
  exotic weapon is authored in shipped content; it is not claimed as fully
  integrated. Tower Shield Proficiency remains deferred (no tower shield item or
  cover mechanic).
- Exported candidate `../.ravenloft-candidate-featskills3b/RavenloftFoundation.exe`
  (110,112,472 bytes, SHA-256
  `fcb8edaafa10b639c3b44e7c7598af4709f56e9716fa6ea8d9fcbd2df690104f`), built
  from HEAD `06f4abd` plus the uncommitted changes. It was copied outside the
  source tree and launched with `--headless --quit-after 90 -- --demo` under an
  isolated `APPDATA`: exit 0, no `SCRIPT ERROR`, `Parse Error` or validation
  failure. No new native controls were added; proficiency feats use the existing
  JSON `feats` authoring field and equipment metadata. The earlier `...featskills3`
  candidate (SHA-256 `4a74702e...`) is retained as superseded evidence.

### Skill-feat batch verification (2026-11-04)

- Focused run `tests/test_feats_skills.gd`: **30/30 tests, 978 assertions**, exit 0.
- Full suite: **171/171 tests, 1913 assertions, 13 scripts**, exit 0.
- Source-grounded checks: Acrobatic, Agile, Animal Affinity and Athletic
  (PHB p. 89); Deceitful, Deft Hands and Diligent (p. 93); Investigator and
  Magical Aptitude (p. 97); Negotiator, Nimble Fingers and Persuasive (p. 98);
  Self-Sufficient (p. 100); Stealthy (p. 101). Each is non-repeatable, has no
  prerequisite and grants +2 to exactly its two printed skills.
- Exact-pair coverage checks all 45 skills for leakage; Skill Focus +3 and the
  feat's +2 stack to +5 because both are untyped. No shipped content changed and
  the save schema is unchanged.
- Exported candidate `workspace/releases/windows_legacy_2026-11-05/RavenloftFoundation-featskills2.exe`
  (110,104,120 bytes, SHA-256
  `03ea2068f077cc8e7d46ce686656c67468312dbe819e4c35714e9323cbe7fefc`), built
  from HEAD `06f4abd` plus the uncommitted batch-1/2 changes. It was copied
  outside the source tree and launched with `--headless --quit-after 90 -- --demo`
  under an isolated `APPDATA`: exit 0, no `SCRIPT ERROR`, `Parse Error` or
  validation failure. The pack includes `src/core/feats.gdc`. No new native
  controls were added in this batch, so no additional click-through was required.

### Batch 1 feats and skills verification (2026-11-04)

- At that boundary `tests/test_feats_skills.gd` was **25/25 tests**; the file now
  contains 30 tests after batch 2.
- Full suite at that boundary: **166/166 tests, 1093 assertions, 13 scripts**, exit 0.
- Source-grounded checks: Table 4-2 (45 skills), Table 4-5 synergies, take 10/20
  (PHB p. 65), Aid Another, opposed-check ties (PHB p. 64), rank caps (p. 62),
  Dodge (p. 92), Improved Initiative (p. 95), Alertness (p. 89), Skill Focus
  (p. 100), Weapon Focus/Finesse (p. 102), Point Blank Shot (p. 98), Toughness
  (p. 101), Multiattack (MM p. 304), turn-undead holy symbol (PHB p. 159).
- Corrections caught by the suite: armor check penalties were negated twice in
  the breakdown (Kaelen climb 11 → 3); Weapon Focus substring matching replaced
  with exact parameter matching; ghoul claw data corrected from -2 to 0 and the
  Multiattack penalty computed by the rules; infected zombie base HP corrected
  from 42 to 39 so Toughness yields the printed 42 once.
- Save compatibility: `proficiencies` is optional and defaults to empty; Toughness
  is not reapplied on load; no save-version bump is required.
- Not covered: manual click-through of the two new take buttons at every text
  scale; their construction and the gameplay path are automated, rendering is not.

### Turn undead milestone verification (2026-11-04)

- Focused suite `tests/test_turn_undead.gd`: **33/33 tests, 152 assertions**, exit 0.
- Full suite: **141/141 tests, 935 assertions**, exit 0.
- Save compatibility: the three new fields (`hit_dice`, `turn_resistance`,
  `turn_undead_used`) are optional in the payload and default to 0, so saves from
  before this milestone load unchanged — no version bump, migration or refusal is
  needed. A pre-milestone payload is covered by a dedicated test.
- Ghoul correction: MM p.119 gives the standard ghoul **+2 turn resistance**, so
  Corvin is 2 HD and treated as 4 HD for turning. The drowned dead (MM zombie
  template) and the ECR infected Strahd zombie (HD 6, `SQ hard to kill, plodding,
  undead traits`) have none. Effective Hit Dice drive eligibility, capacity spent
  and destruction; applying resistance to the destruction clause is recorded as
  an interpretation.
- Exact exported executable `.ravenloft-candidate-turnundead2\RavenloftFoundation.exe`
  (110,070,048 bytes, SHA-256
  `9fa7ac64104570f98e82892e96889af885fa4f6d0001677b470fc176d27b4ccd`), built from
  `06f4abd455b16213289503113e0646e605b54bb8` plus the uncommitted changes:
  - `--demo-turn-undead`: check d20(14)+1 = 15 (4 HD cap), damage 2d6(3,3)+4 = 10;
    the ghoul was turned **as 4 HD**, the drowned dead as 2 HD, the 6-HD infected
    zombie was listed unaffected, and uses fell to 3/4 with the action then
    disabled and the reason shown. The drowned dead then cowered (already at the
    map's maximum distance).
  - `--demo-turn-undead-save`: one use spent, real save + load, combat shows
    **3 of 4** remaining — spent attempts survive the save round trip.
  - `--demo-turn-undead-rest`: two uses spent, shrine recovery path run, combat
    shows **4 of 4**.
  - `--demo-victory-qa`: one attack destroyed the last enemy; the screen showed
    VICTORY, `Each adventurer gains 150 XP` once, and `Autosaved`.
  - `--demo-defeat-qa`: party reduced below −9 HP routed to the defeat screen with
    its load/menu recovery buttons.
- Not repeated in the export this pass: the full E3 acceptance sequence and the
  dialogue/travel loop. Combat remains intentionally unsaveable, so a turned
  duration is never persisted; daily uses are.

The UI tests are **construction smoke tests**: they catch missing nodes, bad
types, null state and layout-time script errors. They do not simulate every mouse
click. Two of them now cover the reported manual-save problem specifically: the
quick-action grid must precede the scrolling party list, and `_open_save_modal()`
must produce a modal listing named slots.

### Save isolation check

After the full suite:

- `user://saves/` contained **no** files (player slots untouched).
- `user://test_saves/auto.json` existed.

This confirms GUT runs are redirected to the test directory. Earlier runs did
pollute `user://saves`; that file was removed and the redirect was added.

## Runtime and import checks

Commands run:

```bash
# Register class_name scripts and import generated audio.
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . --import

# Main menu shell.
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . --quit-after 30

# Demo launch paths.
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . --quit-after 90 -- --demo
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . --quit-after 90 -- --demo-dialogue
"..\Godot_v4.7.2-stable_win64.exe" --headless --path . --quit-after 90 -- --demo-combat
```

Observed:

- Import exit 0; no `SCRIPT ERROR` / `Parse Error`.
- Main menu, exploration demo, dialogue demo and combat demo exit 0; no project
  script errors.
- Windowed in-game viewport captures succeeded for menu, exploration, dialogue and
  combat, writing 1280×720 PNGs to `docs/screenshots/`.
- Godot may print shutdown-only diagnostics such as `BUG: Unreferenced static
  string` when a windowed process exits; these are engine teardown messages, not
  project script errors. They do not appear during gameplay.

## Manual visual verification

Screenshots in `docs/screenshots/` were captured from the running game viewport
(not the desktop) and inspected. Only a representative subset of QA captures is
tracked; the complete historical run sets were moved without deletion to
`workspace/qa/archive/2026-11-05_creator_acceptance_prep/`, and the slice-3 and
combat captures remain under `workspace/qa/`. Phase 2 also captured 1366×768, 1920×1080,
1024×600 and 1.6× text layouts; those are summarized in
[PHASE2_VERIFICATION.md](PHASE2_VERIFICATION.md).

- **Menu:** Continue and Load are disabled when no saves exist; layout is centered
  and readable.
- **Exploration:** header (location, gold, seed, pause), first-person corridor,
  Miruna sprite, all four party HP/AC rows, quest tracker, action grid and log.
- **Dialogue:** speaker badge/name, wrapped prose, five choices including a named
  Sense Motive actor, leave button, modal dimming.
- **Combat:** encounter title, initiative order with all six combatants, action
  buttons, enemies-first combatant list, tactical grid with tokens and HP,
  reachable squares, legend and combat log.

Issues found and fixed during visual verification:

1. Gold/Seed header labels collapsed to one-character-wide columns and pushed the
   header to ~200 px tall. Fixed with non-wrapping header labels.
2. The first-person raycaster drew close walls outside its rect and covered the
   screen title. Fixed with `clip_contents`.
3. The party sidebar cut off half the party; compact HP/AC rows now show all four
   members.
4. The combat initiative panel clipped the last entry; smaller type and a taller
   panel show the full order.
5. Dialogue skill-check labels duplicated the DC and did not name the actor; they
   now append the acting adventurer once.
6. Load game was enabled with no saves; it now matches Continue's disabled state.
7. Test runs created an `auto` save visible in the player menu; tests are now
   redirected to `test_saves`.

## What was not verified

- **Audible audio.** Headless runs use a dummy audio driver; windowed files were
  imported and hooks called, but the 14 placeholders were not subjectively
  auditioned.
- **Full UI interaction.** Save/load modals, settings sliders, rebinding and every
  combat button were built and inspected, but not exhaustively clicked in an
  automated test.
- **Mouse combat end-to-end.** `CombatView.cell_clicked` is wired and construction-
  tested; an automated click-through of move/attack/target selection is not present.
- **Full campaign loop in the batch-2 executable.** The candidate was exported,
  launched outside the source tree with an isolated profile, and produced no
  script or validation errors. The full E3 loop was verified in source, not
  repeated end to end in this candidate; no shipped content or native controls
  changed in batch 2, so the focused and full suites carry the mechanical proof.
  The earlier baseline executable at `workspace/releases/windows_legacy_2026-11-05/RavenloftFoundation.exe`
  remains unchanged.
- **E3 victory/return** was completed through normal graphical controls on the
  previous build: encounter won, Ashlyn spoke, barricade repaired, travelled out
  and back without repeating the trigger or rewards, autosave reloaded with
  position, quest and XP. The repaired-barricade flag did not survive that
  autosave; that gap is now diagnosed and fixed. The repair interaction never
  requested a save — autosave existed only at dialogue end and combat victory — so
  `_run_interaction()` now writes the autosave after effects and removal, and
  three regression tests cover the repair flag, the removed object, the manual-save
  route and a failed write. The fix has **not** yet been re-verified end to end in
  the baseline executable or the batch-2 candidate; batch 2 changed no campaign
  content, so that remains a separately tracked acceptance item.
- **Baseline executable.** `workspace/releases/windows_legacy_2026-11-05/RavenloftFoundation.exe`, 110,056,320
  bytes, SHA-256
  `b70cc9276d5ba5a88af202ec26e3df3b38294baa97601ce4244c40cb122d1065`, built after
  the fixes from HEAD `d52168d74da0c0c955395f0c130b21fd7ab21e9e` with a dirty tree
  and run outside the source tree under an isolated `APPDATA` (the real player
  profile was untouched). Verified in it: menu, New game, party selection with
  full character data, a four-member session, E3 scenario start, and combat
  started/moved/attacked through the normal controls. Not yet verified in it:
  E3 victory, Ashlyn dialogue, barricade repair autosave, travel return, manual
  save/quit/relaunch/load, defeat and both recovery paths, and
  rebinding/restart/Restore Default Controls.
- **Packaged contents.** The export excludes docs, tests, tools, GUT, markdown,
  PDFs, zips and `.qa*` screenshots. A parsed pack table plus a binary scan of the
  built executable confirm 14 `content/*.json` files are packaged and no
  `docs/`, `tests/`, `tools/`, `addons/gut/`, `.pdf`, `.md` or screenshot entries
  are. Reference PDFs and extracted text live outside the project.
- **Long-session stability.** No soak test beyond the short demo runs.
- **Other resolutions/DPI.** 1280×720, 1366×768, 1920×1080, 1024×600 and 1.6× text were visually inspected; mouse-wheel scrolling and high-DPI beyond those captures were not automated.
- **PDF page-level completeness.** Key sections and samples were verified; not
  every page of every PDF was read. Extraction gaps are listed in the reference
  index.
- **Canonical Ravenloft accuracy.** The Old Gatehouse and staging map are
  invented; only the E3 town square is a bounded source-adapted excerpt. The
  encounter is reduced to two infected zombies, and much of the village/church
  material is deferred.

## Reproduce this report

1. Run the import command.
2. Run the GUT command and confirm 206/206, 2,224 assertions.
3. Run the three demo commands; grep for `SCRIPT ERROR`.
4. Run windowed with `-- --demo --capture=explore` (and menu/dialogue/combat) and
   inspect the images.
5. Confirm `user://saves` is untouched after the test run.

This report reflects only the commands and checks above. No test result was
fabricated or inferred from a partial run. See
[PHASE2_VERIFICATION.md](PHASE2_VERIFICATION.md) for the Phase 2 audit.

## Trip and prone — 2026-11-05

- `tests/test_prone_and_size.gd`: 13 tests, 1,023 assertions — size progression
  and save migration, content consistency, prone AC signs by attack type, prone
  melee penalty, prone ranged restriction, opposed-check tie procedure, save
  round trip.
- `tests/test_trip.gd`: 18 tests, 100 assertions — stand-up cost and timing
  (including that the opportunity attack uses the prone AC), refusal cases, Trip
  size gate, immunity, reach, unarmed provoke order, prone application,
  trip-weapon requirement, weapon drop, counter-trip, the paused weapon-release
  decision (no reroll, no double spend, duplicate submission refused), pickup
  cost and provoke, interrupt, ground-item duplication/recovery and crawling.
- `tests/test_trip_pending_guards.gd`: 9 tests, 84 assertions — spells, potions,
  first aid, turn undead, Power Attack, Combat Expertise, equipment/inventory
  use and auto-advance all refuse while a decision is pending, with no resource
  spent; duplicate resolution applies once; encounter end and a dead actor void
  the decision without effects; a turn change discards it; a dropped weapon is
  ground-only; victory recovers leftovers and defeat grants nothing.
- Baseline reproduced at the start of this increment: 237/237 tests, 3,347
  assertions, 15 scripts, exit 0.
- Full suite after the guards and fixture: **246/246 tests, 3,431 assertions,
  16 scripts, exit 0**.
- Native interface verification: performed in the source build and repeated in
  the exported candidate, windowed at 1280x720. The QA probe clicks real
  controls and every scenario ended in the expected state: successful Trip,
  missed touch attack (standard still spent), counter-trip pause with Drop and
  Keep, prone attack and stand-up opportunity attack, pickup, crawl (5-ft step
  disabled), and return to exploration. Captures are in
  `docs/screenshots/qa_trip/` (source) and `docs/screenshots/qa_trip_export/`
  (exported candidate).
- Export candidate: `workspace/releases/trip_candidate/RavenloftFoundation.exe`, SHA-256
  `6fb26be2c919d749177db8348e023bfd8b8088edb46ac68ca18916f8d034f5f9`, built
  from HEAD `9fc8fff` plus working-tree diff `064452c3...`.
- Headless startup and headless probe runs are smoke evidence only; the
  interface claims above rest on the windowed runs.
- Not verified: NPC-initiated Trip (unimplemented), and manual play outside the
  fixture scenarios.

## Improved Trip and probe closure — 2026-11-05

- `tests/test_improved_trip.gd`: 12 tests, 78 assertions — prerequisites (INT 13
  and Combat Expertise, and suspension when unmet), +4 applied only to the
  attacker's trip check (the defender's check and the counter-trip resist are
  unchanged), no opportunity attack for an unarmed trip, a qualifying success
  pausing with the granted attack, no pause without the feat or after a miss or
  lost trip, one follow-up attack that spends no second standard action and deals
  damage on a hit, duplicate submission refused, declining restoring ordinary
  movement, a changed turn or finished encounter voiding the grant, committed
  Power Attack and Combat Expertise carrying into the follow-up, and the prone
  target's melee AC.
- The QA probe is now an acceptance probe, not an observational transcript: each
  scenario checks explicit expected actor, target, modal, condition and action
  state, including that every clicked control exists, is enabled and lies inside
  the window; it captures its steps, is bounded by a 90-second watchdog and exits
  nonzero on any failed check. Setup stays in `_qa_trip_demo`; the checks only
  read state that the real control tree produced.
- The new assertions immediately found a real UI defect: the added decision label
  sat in a horizontal box, giving the sidebar an enormous minimum width, which
  squeezed the log to one character per line and pushed the decision buttons
  below the 1280x720 window. The panel is now a label above a button row, and the
  probe's on-screen check covers the regression.
- All eleven scenarios (`success`, `touch_fail`, `counter_drop`, `counter_keep`,
  `prone`, `stand_aoo`, `pickup`, `crawl`, `return`, `improved_trip`,
  `improved_trip_decline`) pass with exit 0 in the source build and in the new
  export. Captures are in `docs/screenshots/qa_trip_improved/` and
  `docs/screenshots/qa_trip_improved_export/`.
- External-input pass (narrow, not a replay): a PowerShell harness starts each
  exported candidate and drives it with OS-level mouse events (`SetCursorPos` +
  `mouse_event`) at the client coordinates the probe reports. In both the
  preserved `trip_candidate` and the new candidate it opened Trip, ticked the trip
  weapon, targeted the enemy, answered Drop weapon, picked the flail up and
  returned to the next round (round 2, HP 21, "Picked up Light Flail."). Captures:
  `workspace/qa/runs/2026-11-04_05_feats-cleaves/external/old_candidate_counter_drop.png` and
  `workspace/qa/runs/2026-11-04_05_feats-cleaves/external/new_candidate_counter_drop.png`. This is scripted external
  input, not a human hand on the mouse.
- Full suite: **258/258 tests, 3,509 assertions, 17 scripts, exit 0**;
  `git diff --check` clean.
- New export: `workspace/releases/improved_trip_candidate/RavenloftFoundation.exe`,
  111,382,672 bytes, SHA-256
  `17f164e9ed83427a3809f713e8a413cb772ea951ac48303f7e6387c232e94b01`, built from
  HEAD `9fc8fff` plus working-tree diff `095ad523...`. The earlier candidate and
  its evidence are untouched.
- Limitation: layout-dependent clicks need a real window. A headless probe lays
  controls out for a larger default viewport, so decision buttons can sit outside
  the 1280x720 click area; headless remains smoke only.

## Improved Trip follow-up selection and Cleave — 2026-11-05

- Improved Trip attack-selection conclusion (PHB p. 96: "you can immediately make
  a melee attack against that opponent as if you hadn't used your attack for the
  trip attempt"): the follow-up is *a melee attack*, not the trip method. The
  earlier report wording ("the trip weapon or unarmed strike") overstated a
  restriction the source does not impose. The code now records the actual choice:
  at the decision the player picks the equipped weapon's legal melee mode or an
  unarmed strike. Ranged modes are refused, and no draw, equip or grip change
  occurs, so a different weapon still needs its normal equip action.
- `tests/test_improved_trip.gd`: **15 tests, 90 assertions** — the 12 earlier
  tests plus follow-up selection (an unarmed trip still offers the equipped
  longsword), refusal of a ranged mode, and the follow-up resolving with the
  chosen attack.
- `tests/test_cleave.gd`: **14 tests, 64 assertions** — prerequisites (STR 13,
  Power Attack, and suspension when unmet), a drop by the actor's own melee
  attack offering the decision, a hit that does not drop offering nothing, the
  same weapon and attack bonus preserved, only living enemies within reach
  offered, no 5-ft step or movement before the extra attack, once-per-round use
  cleared at round start, no chaining from the Cleave attack itself, decline
  restoring play, duplicate submission refused, a dead or invalidated pending
  target, Power Attack and Combat Expertise carried into the extra attack,
  Improved Trip's follow-up granting Cleave while the trip itself does not, and
  opportunity attacks not granting Cleave.
- QA: `--demo-cleave --cleave-scenario=<cleave|cleave_decline|
  cleave_no_target|cleave_from_trip>` with the asserted `--cleave-probe` (bounded
  by the 90-second watchdog, an on-screen check for every clicked control, and a
  nonzero exit on any failed check). All four scenarios pass with exit 0 in the
  source build and in the exported candidate. Captures:
  `docs/screenshots/qa_cleave/` and `docs/screenshots/qa_cleave_export/`.
- External OS-input pass on the new decision panel:
  `tools/qa/external_input.ps1` gained `-Demo cleave`; two runs drove the export
  with OS mouse events at the coordinates the probe reports. The first stopped on
  the Cleave panel (the second enemy offered, decline offered, the dropped
  creature dead); the third click in the second run resolved the extra attack,
  destroyed the second enemy, ended the encounter and returned to exploration.
  Captures: `docs/screenshots/qa_cleave_external/cleave_panel.png` and
  `cleave_follow.png`.
- Export candidate: `workspace/releases/cleave_candidate/RavenloftFoundation.exe`,
  113,419,112 bytes, SHA-256
  `0a6088757d49dd9b2c55a4a1a6a3fc666196297c9336f407028465501f9578c5`, built from
  HEAD `9fc8fff` plus the tracked source/content working tree (source diff
  `6c5f86d20911ec8a328bbd3d06a5abfcb31cb8f8bbc6642231e8118d46e1e7e9`; the untracked `tests/test_cleave.gd` is part of the same state).
  The `trip_candidate` and `improved_trip_candidate` builds and their evidence are
  untouched.
- Full suite after this increment: **275/275 tests, 3,585 assertions, 18 scripts,
  exit 0**; `git diff --check` clean.
- Limitations: Great Cleave is not implemented; Cleave does not trigger from
  opportunity attacks or other out-of-turn damage, and NPC attackers do not take
  it. No shipped content carries the feat, so the native evidence is the QA
  fixture.

## Off-turn Cleave, compact layout and training entry — 2026-11-05

- Trigger scope: the feat is offered from any party member's resolved melee
  attack, own turn or off turn. Opportunity attacks are melee attacks, so a
  provoked attack that drops a creature now offers Cleave; the decision stores
  that attacker, weapon and context instead of the active combatant. Ranged
  attacks, spells and damage-over-time effects remain non-triggering, and NPC
  attackers still do not take the feat.
- Interruption: the interrupted monster or flee route keeps its remaining path,
  target chain and attack-after flag in a bounded `off_turn_resume` record;
  `resume_interrupted()` re-validates and continues or ends that action. The
  active combatant and turn are unchanged while the decision is open, and the
  opportunity-attack budget is debited before the decision.
- Same bonus: `Rules.attack` preserves the triggering attack's own base and
  committed Power Attack/Combat Expertise context and re-evaluates
  target-specific circumstances (helpless +4, cowering +2, flanking, prone,
  reach) for the new target; the previous final total is never copied.
- New tests: `tests/test_cleave_offturn.gd` (11 tests) covering the trigger,
  turn ownership, use of the opportunity attack, decline, resolve-then-resume,
  duplicate submission, same-round frequency in both directions, modifier
  re-evaluation and encounter-end invalidation. `tests/test_cleave.gd` updated
  for the base-bonus model.
- Layout: window minimum enforced at 1280x720; the combat sidebar scrolls. The
  stated 1024x600 target is **not supported**; Godot clamps the window to
  1280x720 and the docs now say so. At 1280x720 with the 1.6x text scale, the
  `cleave`, `cleave_decline` and `cleave_from_trip` probes pass, with every
  clicked control on screen and the target list scrollable.
- QA: `--probe-size=WxH`, `--probe-text-scale=<float>`, the two new
  `cleave_offturn*` fixtures and `--training-probe` were added. All six Cleave
  scenarios and the training probe pass in source and in the exported build.
  External OS-input runs on the exported build drove the decision panel: one
  resolved the extra attack and destroyed the second enemy (victory), one
  declined. Captures: `workspace/qa/runs/2026-11-04_05_feats-cleaves/external/cleave_offturn_accept2.png`,
  `cleave_offturn_decline.png`.
- Export candidate: `workspace/releases/cleave_offturn_candidate/RavenloftFoundation.exe`,
  117,406,824 bytes, SHA-256
  `1bb6a194bf4a6c7b17a69d3862c53ba4df84cc91e6fa4b13fbd96ec8dc80c6aa`, built from
  HEAD `9fc8fff` plus the working tree (`git diff --check` clean). The
  `trip_candidate`, `improved_trip_candidate` and `cleave_candidate` builds and
  their evidence are untouched.
- Full suite after this closure: **286/286 tests, 3,631 assertions, 19 scripts,
  exit 0**.
- Remaining limitations: Great Cleave, ranged/spell/DoT triggers, NPC Cleave and
  full-attack/iterative interactions stay unimplemented; the training entry
  reuses QA fixtures rather than authored campaign content; 1024x600 is
  unsupported by design.

## Foundation reassessment — 2026-11-05

- Scope: the individual feat queue is paused. This pass audited the shared
  groundwork and made one bounded consolidation instead of another named feat.
- `src/core/content_spec.gd` (new) is the single registry for authored effect
  and condition types: required fields, field kinds and the content table each
  id must exist in. `ContentDB` validates every effect list and every dialogue
  choice condition through it (conditions previously had a second,
  hand-maintained list), and `GameSession.apply_effects`/`check_conditions`
  consult the same registry before running their handlers.
- `Main._start_demo` now sets `Game.training_mode`, so command-line
  demonstrations cannot autosave over player slots or grant campaign XP;
  explicit QA slots (`qa_turn`) are unchanged, and campaign play is untouched.
- New `tests/test_extensibility.gd` (10 tests) pins the contract: shipped
  content validates cleanly, the vocabulary is stable, unknown effect/condition
  types and missing identifiers/references produce named errors, registry
  lookups are declared fields, and a data-only addition using existing shapes
  needs no new code.
- Full suite: **296/296 tests, 3,654 assertions, 20 scripts, exit 0**; content
  validation runs inside the suite (no separate validator has been added yet).
- Native check: new candidate `workspace/candidates/foundation_contracts_candidate/RavenloftFoundation.exe`
  (118,961,152 bytes, SHA-256
  `31b452002ad274a0fa9b6f7c272328a2621638add4a5aaf41458312b7111cc1d`) passes
  `--training-probe` and the `cleave_offturn` probe.
- Not changed: no feat, special attack or campaign area was added; the earlier
  candidate builds and their evidence are untouched; no commit, push or
  publish was made.

## Campaign creator (slice 1) — 2026-11-05

- Scope: a visible **Create campaign** flow and **Campaign Editor** for metadata,
  9x9 areas, wall/floor cells, entry position/facing and two-area passages,
  with validation, atomic save and an ordinary-loader playtest that can be
  paused and returned to the creator. NPC/dialogue/encounter/quest editing is
  explicitly out of this slice.
- New code: `src/core/campaign_store.gd` (safe ids, template, directory scan,
  draft helpers, shape/full validation through a temporary package, atomic
  writes, delete) and `src/ui/campaign_creator.gd` (the editor screen).
  `CampaignDB` merges user packages and rejects bundled-id collisions;
  `ContentDB` merges campaign-local instance tables and refuses local spells;
  `Game` gained `playtest_mode`, save/autosave refusal, `refresh_campaigns`,
  `validate_campaign_draft` and `abandon_playtest`.
- Local-content policy: campaign-root `items.json`, `monsters.json` and
  `characters.json` may define instances using shared schemas; a shared id may
  not be redefined; a local `spells.json` is a named error. Named characters
  default to non-playable only when authored `"playable": false`; party
  selection uses `ContentDB.playable_character_ids()`.
- Test coverage: `tests/test_campaign_creator.gd` (9 tests) covers create and
  discovery, invalid ids/path traversal, duplicate user ids with no overwrite,
  bundled read-only protection, map/entry/transition validation, local-instance
  merging and shared-id refusal, playtest save refusal with the ordinary save
  untouched, authored files unchanged by playtest, and existing bundled
  campaign save/load. `test_campaign_packages.gd` was updated for the new local
  table policy (local spells rejected, empty local instance tables allowed).
- Full suite: **315/315 tests, 3,783 assertions, 22 scripts, exit 0**. Content
  validation: `ravenloft_demo` and `hollow_lantern` VALID.
- Probes: `--creator-probe` (create → second area → passage → entry → validate
  → save → playtest → travel → save refusal → no save file → relaunch
  discovery → cleanup) and `--creator-ui-probe` (area list, 81-cell map,
  add-area, set-entry, passage, validate, save, playtest, pause/return with
  draft, Edit of the existing package). Both exit nonzero on failure and pass
  in source and in the exported executable, alongside both
  `--campaign-probe` runs and `--validate-campaigns`.
- Windowed inspection at 1280×720, 1.0 and 1.6 text scale, found and fixed:
  metadata labels rendering vertically (grid label column collapsed under
  autowrap) and the first build blanking the template area name; the campaign
  list footer still said the creator was a future milestone. The description
  field now wraps instead of scrolling horizontally. Party selection was checked
  for both campaigns (it names the selected campaign) and at 1.6 scale (it
  scrolls, with Back/Begin visible); the Validate dialog was checked. A
  `--demo-party` QA flag makes that screen directly launchable. Continue/Load
  enabled state was not visually exercised because no campaign save existed;
  their behavior remains covered by the save tests. Captures:
  `workspace/qa/runs/2026-11-05_campaign_creator/`.
- External OS-input pass on the source executable: Create campaign dialog →
  typed title/id → created `external_campaign` → added area 2 → set entry →
  linked a passage → saved; then `--demo-creator` → Playtest → Pause → Return
  to campaign creator. Captures `ext_01_dialog.png` … `ext_05_returned.png`.
  The created test campaigns were removed afterwards.
- Export candidate: `workspace/candidates/creator_2026-11-05b/RavenloftFoundation.exe`,
  110,252,488 bytes, SHA-256
  `e73c2076a4d9503fc6efe7476f207fba14315b29fcfee939deefd264d1d8bdd4`,
  built from HEAD `9fc8fff` plus 80 worktree entries (diff hash
  `e1e6b0d3…ed0dbee`). The earlier `creator_2026-11-05` build predates the
  `--demo-party` QA flag and is superseded. Logs:
  `workspace/qa/runs/2026-11-05_campaign_creator/exe_b_*.log`.
- Remaining limitations: creator covers one 9x9 area at a time; larger maps,
  doors/triggers/objects, NPCs, dialogue, encounters and quests remain
  file-authored; no scripting or new mechanics from local instances; the
  exported executable was probed headlessly, not played windowed by a human.

## Campaign creator slice 2 — speaker NPCs and dialogue (2026-11-05)

- Scope: place a campaign-local speaker NPC and author a branching conversation
  in the existing Campaign Editor, without external JSON. The NPC is a speaker
  record (`id`, name, position, look, dialogue, sprite); no combat stat block is
  required. Encounters, quests, doors, triggers and objects remain file-only.
- Dialogue authoring: dialogue id and start node; node id, speaker name, text
  and `next`; choices with a plain destination or one skill check (skill, DC
  1–60, actor `best` or a default party member, success/failure destinations);
  preview. Node effects apply on entry; choice effects apply before the check.
  The bounded palette is require flag (`not_flag`), show only when set (`flag`),
  set flag, and narration. Effects outside this palette are preserved when a
  form is applied rather than silently stripped.
- Reference safety: renaming a node rewrites start, `next`, choice and check
  destinations; renaming a dialogue rewrites NPC references. Deleting a
  referenced node or dialogue is refused with the exact references. Removing an
  NPC keeps its conversation. Loops are valid; unreachable nodes are reported
  separately from cycles.
- Draft isolation: editing changes only the in-memory draft. Save writes
  atomically. Playtest saved the current draft first in slice 2 (superseded in
  slice 3 by staged-snapshot playtest), then
  launches the ordinary loader with `Game.playtest_mode`; saves are refused,
  ordinary slots are untouched, and Return restores the draft.
- `tests/test_campaign_creator.gd` is now **14 tests, 250 assertions**
  (was 9 tests), adding NPC placement/move/remove validity, dialogue links and
  unreachable-node reporting, rename/delete refusal with live references, the
  check/effect/condition palette, and an end-to-end authored interaction. The
  last test uses deterministic success and failure seeds, asserts the failure
  branch does not set the flag and the success branch does, asserts the guarded
  response hides and the later response appears, asserts playtest save refusal,
  then plays the same package normally, saves, starts a new game, loads and
  confirms the flag. It also asserts a second campaign's save and flags do not
  leak into the first campaign and vice versa.
- Full suite: **320/320 tests, 3,965 assertions, 22 scripts, exit 0** (baseline
  315/3,783). `--validate-campaigns` PASS.
- Probes: `--creator-probe` 21 checks, `--creator-ui-probe` 21 checks and the new
  `--creator-interaction-probe` 29 checks all exit 0 in source and in the exact
  exported candidate. The interaction probe covers place → author identity →
  add nodes/responses → validate → save → dirty flag cleared → reopen → playtest
  → talk from the entry cell → skill-check response offered → return with the
  draft → ordinary play reloads the package and writes a save → main-menu
  Continue/Load enabled → the authored campaign card's Continue latest/Load slot
  enabled. The full authoring path before the card checks is asserted; failures
  exit nonzero.
- Windowed inspection at 1280×720, 1.0 and 1.6 text scale. Captures:
  `workspace/qa/runs/2026-11-05_creator_slice2/`. The first captures showed the
  NPC and conversation columns clipping horizontally; they are now stacked.
  Long `OptionButton` labels then squeezed row labels into vertical text; picker
  labels are now stable ids (node text stays visible in the fields/preview) and
  row labels have fixed minimum widths. Placement, node, response, check and
  flag controls were re-captured at both scales.
- External OS-input pass on the source executable: **Save draft** produced the
  visible “Saved” state; **Add area** produced “Area 2 (area_02)” and “Unsaved
  changes.” The full edit → save → reopen → playtest → return path is asserted by
  the interaction probe, not by the OS-input screenshots. Captures `ext_save.png`
  and `ext_add_area.png` in the same run directory.
- Export candidate:
  `workspace/candidates/creator_slice2_2026-11-05/RavenloftFoundation.exe`,
  110,302,600 bytes, SHA-256
  `a01c364413d829cb312a8bbb538fcf7ca6cd31e6f64128beb001f256c14a7a9c`.
  `BUILD.txt` records HEAD `9fc8fff`, 80 worktree entries and diff hash
  `a821d511…e29488`. The accepted slice-1 candidate
  `creator_2026-11-05b` is untouched.
- Limitations: this is a node-list editor, not a graph; one skill check per
  choice; only the stated flag/narration palette; one 9x9 area at a time;
  encounter/quest/door/trigger/object editing is still file-authored. The
  exported executable was probed headlessly; visual checks used the source
  executable and were not repeated in the export. No human windowed playtest
  was performed.

[read_files: showing lines 1-777 of 777.]

## Campaign creator slice 3 — quests, encounters, playtest semantics (2026-11-05)

- Scope: author a quest with flag-bound objectives, declare flags, create a
  fixed-layout encounter with shared monsters and bounded XP, connect victory to
  an objective flag, and place a once-only encounter trigger — then validate,
  playtest, save, play normally and reload. No feat, combat-rule or monster
  additions.
- Draft/playtest separation: **Save draft** writes atomically. **Playtest**
  validates the in-memory draft, stages `user://playtest/<id>/`, loads it through
  the ordinary loader with `Game.playtest_mode`, refuses saves, and deletes the
  staged copy on return. Tests assert the saved `quests.json` is byte-identical
  after staging, while the playtest sees an unsaved in-memory title; validation
  failure and start failure leave both draft and package untouched.
- Quest/flag semantics: objectives complete only after the quest is active;
  start and completion quests are explicit, so a completed quest does not end
  every campaign. Quest/encounter rename rewrites references; delete is refused
  while referenced. A used-but-undeclared flag is listed separately from a
  declared flag; removing a declaration is refused while used.
- Encounter/trigger semantics: three legal templates; monsters capped by the
  layout and four; walkability/uniqueness/bounds validation; triggers refuse
  walls, the entry cell, occupied cells and missing encounters. Re-entering a
  cleared trigger does not restart combat or grant XP, and the guard flag keeps
  it spent after reload.
- Defeat versus victory: `Encounter.finish("defeat")` leaves the victory flag
  unset, the objective incomplete, the quest incomplete and XP unchanged;
  victory sets the flag, completes the objective/quest and grants the authored
  XP exactly once.
- Real-combat acceptance (2026-11-05, closure): `--creator-combat-probe` creates
  the campaign through `CampaignStore` (the creator backend), talks the authored
  NPC into starting the quest, travels by the authored passage, walks onto the
  trigger through ordinary exploration and wins with one shared zombie using the
  shipped controls: the **Attack** button plus a click on the enemy's map cell,
  moving into 5-ft reach through the **Move** control first and ending turns when
  the standard action was spent. It never calls `Encounter.finish()`, never edits
  hit points and never sets the victory flag itself. Disclosed deterministic
  seed **90210**; 10 attack clicks; victory sets `beacon_lit`, completes the
  quest, and awards the authored 50 XP once (3000 → 3050). It then saves and
  exits.
- Relaunch acceptance: a **separate process** (`--creator-combat-reload-probe`)
  discovers the campaign, loads `slot1`, and confirms the flag, spent trigger,
  completed quest and saved XP. Walking off and back over the trigger cell starts
  no combat and grants no second reward; the return passage and the changed NPC
  response still work. Both phases PASS in source and in candidate `…e`.
- Lossless editing: the creator rewrites the package as a whole, so supported
  content outside its forms survives an unrelated edit. A fixture with doors, an
  object interaction (`once`, guard, effects), hand-authored node/choice effects
  and conditions, unknown author keys on the manifest/quest/encounter/area/node/
  choice, `flag_definitions`, a campaign-local `items.json` and an unmanaged
  `dungeon.json` was opened, had unrelated fields changed, saved and reopened;
  all of it survived and the local/unmanaged files were byte-identical. Loading
  now refuses, with an actionable message, packages that store `areas`, `quests`,
  `encounters`, `narration` or `dialogues` inline, a newer `format_version`, a
  non-object content file (valid JSON of the wrong shape), or duplicate
  area/dialogue ids, instead of
  silently emptying and overwriting them.
- Write boundaries (file comparisons): the saved package is byte-identical after
  staging, loading and abandoning a playtest; a normal `slot1` save is unchanged
  by playtest; unsaved draft edits and dirty state survive; only **Save draft**
  changes `quests.json`; `cleanup_playtest("..")`, `cleanup_playtest("bad/../id")`
  and `delete_user_campaign("..")` leave a sentinel file outside the designated
  root untouched while removing files inside it.
- Full suite at this milestone's close: **329/329 tests, 4,160 assertions, 22
  scripts, exit 0** (baseline 320/3,965, 22). `test_campaign_creator.gd`: 23
  tests, 445 assertions, adding the lossless round trip, refusal guards,
  write-boundary comparisons and the pinned creator action bar.
- New-encounter click resolution: geometry from the real control tree shows the
  **New encounter** button at `(939, 2821)` with `scroll=0` — outside the
  1280×720 viewport — and at `(939, 125)` after `focus_encounter_section()`
  (`scroll=2696`). The control is enabled and visible in both states. The earlier
  missed OS click used a post-scroll coordinate against the unscrolled layout;
  no application defect was found. Clicking the measured centre `(1009, 142)` in
  the exact candidate created and selected `encounter_02` and reported “Created
  encounter 'encounter_02'.” Capture:
  `workspace/qa/slice3/ext_new_encounter_verified.png`.
- Probes, source and exact candidate: `--creator-probe`, `--creator-ui-probe`,
  `--creator-interaction-probe` and `--creator-story-probe` all exit 0. The story
  probe covers create → quest/flags → second area/passages → encounter →
  trigger → conversation with quest start and a flag-gated changed response →
  save → unsaved edit → playtest (travel, trigger, victory, no repeat, changed
  response, save refused) → return with the package unchanged → ordinary play →
  save → reload → cross-campaign isolation. Its victory/defeat resolution calls
  the engine's own `Encounter.finish()` path so assertions are deterministic;
  that probe verifies **forced postcombat integration only** and is not a combat
  playthrough. The attack-driven acceptance is `--creator-combat-probe` above.
  `--creator-encounter-click-probe` asserts the measured click geometry and that
  the button creates/selects the new encounter.
- Windowed/exported evidence: the exact candidate was run windowed for the story
  probe and for captures at 1280x720 at 1.0 and 1.6 text scale:
  `workspace/qa/slice3/creator_slice3_quests_min.png`,
  `..._quests_large.png`, `..._encounters_min.png`,
  `..._encounters_large.png`. Both sections stack vertically and remain readable
  at 1.6; no horizontal clipping was observed.
- Layout correction found by the captures: the encounter row labels ("Battle
  map", "Monster", "Victory flag") collapsed into one character per line beside
  the expanding pickers. They now have fixed minimum widths and no wrapping;
  re-captured at 1.0 and 1.6, both sections stack vertically and stay readable.
- External input (automated OS events, not human testing; SetCursorPos +
  mouse_event on the real window): **New quest** produced a selected `quest_01`
  with its placeholder objective; **Add monster** changed the count from 1 to 2
  and reported "Added monster 'ghoul'." After scrolling the encounter section
  into view, the measured **New encounter** click created and selected
  `encounter_02` and displayed “Created encounter 'encounter_02'.” Captures:
  `ext_new_quest.png`, `ext_new_encounter.png`,
  `ext_new_encounter_verified.png`.
- Candidate: `workspace/candidates/creator_slice3_2026-11-05e/RavenloftFoundation.exe`,
  110,376,216 bytes, SHA-256
  `57758c82c761362bccaa64f1ec8bc0e0619c5038bd7c0da03c07d8a2aea3565f`.
  `BUILD.txt` records HEAD `9fc8fff`, **79** worktree entries, tracked diff hash
  `efc929ed…747090b`, 266 untracked files and untracked-source hash
  `5f2c6200…cae310af` (build identity now covers untracked source/content, not
  just tracked diffs). Candidate `…c` remains at
  `7a205aee…ecb7a227`; `creator_slice3_2026-11-05d` keeps the pre-preset-fix
  build; the accepted `creator_slice2_2026-11-05` and earlier exports were not
  overwritten.
- Windowed/exported checks on this exact candidate: `--creator-combat-probe`,
  `--creator-combat-reload-probe`, `--creator-encounter-click-probe`,
  `--creator-probe`, `--creator-ui-probe`, `--creator-interaction-probe`,
  `--creator-story-probe`, `--validate-campaigns` and
  `--campaign-probe=ravenloft_demo` all exit 0. The external OS click above ran
  against this candidate. The full suite ran on the final source (export preset
  path is not compiled into the executable).
- Limitations: fixed battle-map templates; four monsters, four party cells and
  twelve objectives; no monster/stat/spell/AI editing; no quest scheduler,
  scripting language or failure-state framework; objective flags only; trigger
  once-only relies on the per-trigger spent flag plus the optional guard; no
  human windowed playtest was performed, and the combat acceptance is automated
  control input rather than a person playing. The malformed-JSON-syntax case is
  a known test gap: the refusal fixture replaces the area file with valid JSON of
  the wrong shape (`[]`); a syntactically invalid file takes the same strict
  reader branch and message but has no dedicated fixture.

## Campaign-creator usability and acceptance (2026-11-05)

- Scope: prove a creator can build a small campaign through the application and
  the authoring guide, then fix only the highest-impact confirmed friction. No
  new editor section, subsystem, undo/redo, node graph or map resizing was added.
- Exercise: `--creator-acceptance-probe` starts at the campaign list and uses the
  visible **Create campaign** dialog and the creator's own controls for every
  step: two 9x9 areas with entry and linked passages, a speaker, a conversation
  with a Search check and a flag-gated changed response, a declared flag, a quest
  with a flag-bound objective, a fixed-layout encounter with victory wiring, and
  a once-only trigger. It validates, saves, exercises refusals, playtests (talk,
  check, trigger, forced postcombat victory, changed response, refused save),
  returns with the package byte-identical, reopens from disk, and plays/saves/
  loads ordinarily. This is a **model-driven UI script, not a human usability
  study**; it drives screen callbacks rather than native OS input for the long
  workflow.
- Result: every authoring and recovery check PASS in source and in
  `creator_usability_2026-11-05` (exit 0). No step required external file editing.
- Confirmed friction and fixes, highest impact first:
  1. **Actions and feedback scrolled out of reach (fixed).** The header sat
     inside the scrolling page, so at the quest/encounter sections (about 2,700
     px down) Save/Validate/Playtest were off-screen, and validation text was
     written below the last section. The action bar, save/play distinction line
     and status label are now pinned above the scroll area. Measured proof:
     `--creator-encounter-click-probe` places **New encounter** at y=2821 at
     scroll 0 and y=125 after the focus scroll; the new assertion checks Save,
     Playtest and status remain enclosed by the viewport at that scroll position.
  2. **Playtest vs save was ambiguous (fixed).** The button is now **Playtest
     draft**, with “Save draft writes the package. Playtest draft runs these
     unsaved changes with all saves disabled.” Tests and probes still call the
     callback, not the label.
  3. **The guide lacked an end-to-end order and state model (fixed).**
     `AUTHORING_GUIDE.md` now opens with a ten-step getting-started workflow, the
     draft/save/playtest/playthrough distinction, a concrete flag→objective→
     victory→guarded-response example, and a refusal-recovery table.
  4. **Validation recovery was not discoverable (mitigated).** The pinned status
     line keeps the full listed error visible while editing, and the guide maps
     common refusals to the next action. Validation still does not jump to the
     offending field; that remains a deliberately deferred UX change.
  5. **Generated ids and rename actions were easy to misread (documented).** The
     guide now explains the campaign-id slug, that quest/encounter ids are
     stable and renamed through their explicit **Rename** action, and that
     **Apply** commits form fields to the draft.
- Error-recovery checks (draft preserved, package unchanged): wall entry refused;
  trigger on the entry/occupied cell refused; deleting a referenced quest
  refused and names the reference; leaving with unsaved changes offers Save /
  Discard / Keep editing; duplicate campaign id keeps the create dialog open; a
  playtest save is refused; a failed check or an invalid draft does not write.
- Verification: full suite **329/329 tests, 4,160 assertions, 22 scripts, exit
  0**; `test_campaign_creator.gd` **23 tests, 445 assertions**, including the
  pinned-action regression. `--validate-campaigns` PASS in source and in the
  exported candidate. Windowed at 1280×720 and 1.6 text scale, an automated OS
  click on **Validate draft** at the encounter section left the pinned bar and
  the green “Draft validates…” message visible:
  `workspace/qa/usability/creator_encounters_1p6_validate.png`.
- Candidate (runtime changed):
  `workspace/candidates/creator_usability_2026-11-05/RavenloftFoundation.exe`,
  110,384,600 bytes, SHA-256
  `1a53fa04e5cb6683083ffebde8186b8d4f4ce3e14291691adc4c66613c54d39c`.
  The accepted `creator_slice3_2026-11-05e` candidate is untouched.
- Limitations: this is not a human study; the long workflow is in-process UI
  automation, and only the changed pinned control was exercised with native OS
  input. No external file editing was needed for the exercised capabilities, but
  doors/objects/unique items remain file-authored. Malformed JSON syntax still
  has no dedicated fixture. Validation does not focus the offending section.
  Fixed maps, four monsters, flag-only objectives and the absence of undo/redo
  remain supported-scope limits.

## Structured content diagnostics (2026-11-05)

- **Contract.** `src/core/content_diagnostics.gd` defines one dictionary per
  result: stable `code`, `severity` (`error`/`warning`), human `message`,
  `campaign`, `source`, `entity_type`, stable `entity_id`, `field`, `area_id`,
  `node_id`, `choice_index`, `section`, `refs`, and `advanced`. Producers attach
  these directly; consumers never parse message wording. Legacy validators
  remain authoritative for save/playtest, and unmapped legacy messages are
  wrapped as `content.rule` advanced diagnostics.
- **Migrated coverage.** `CampaignStore.diagnose_draft` covers campaign id/title/
  areas; area rows, duplicate ids and start cells; entry area/position/facing and
  entry overlap; missing or non-walkable passage destinations; NPC ids, duplicate
  ids, names, placement and dialogue references; dialogue speaker/start/nodes,
  destinations, choices, skill/DC/actor/branches and unreachable nodes; quests,
  objectives and flags; encounter maps/cells/monsters/XP; trigger ids, cells,
  encounter references and guards. Declared-but-unused flags and undeclared
  trigger guards are warnings, not errors; legitimate dialogue loops are not
  errors. Doors, non-travel objects and file-only instance arrays produce
  advanced warnings that name the package source.
- **Creator navigation.** Selecting a result opens the owning section, selects
  the area/entity (including the right one among similar NPCs), scrolls the field
  into view, and focuses it. Node/choice results carry their dialogue first and
  objectives carry their quest first. Navigation uses ids and existing selectors,
  not fixed coordinates. Dirty form text and draft state are preserved; nothing
  is applied, saved or discarded. A deleted/renamed entity shows “no longer
  exists … Validate draft again” instead of selecting a neighbour. The results
  panel stays pinned and keeps the full status list readable.
- **Advanced-only.** Unmapped legacy rules (`content.rule`) and file-only content
  remain non-navigable. Their source and the need to edit package JSON are shown;
  there is no universal reference browser or automatic repair.
- **Malformed content.** A dedicated area fixture writes syntactically invalid
  JSON (`{ this is not json`). Loading reports the file and parser message, exits
  without crashing, does not replace the live campaign, does not overwrite the
  invalid original, and does not mutate a valid open draft. Valid JSON with the
  wrong shape (`[]`) produces a separate message. Parser output is handled by
  `JSON.new().parse()` rather than dependent on the test runner tolerating an
  engine error.
- **CLI.** `--validate-diagnostics` prints one JSON array plus a summary and exits
  nonzero on any error; `--validate-campaigns` keeps its existing text and exit
  behavior. A copied user package with a broken area file produced
  `package.load` naming `barovia_east_gate.json`, summary FAIL, exit 1. Bundled
  campaigns now report no false load error.
- **Verification.** Full suite **332/332 tests, 4,198 assertions, 22 scripts,
  exit 0**; `test_campaign_creator.gd` **26 tests, 483 assertions**. The focused
  source and exported `--diagnostic-navigation-probe` passed all 11 checks
  (right NPC, focused field, dirty state, stale revalidation, entry field,
  corrected revalidation, save). `--validate-campaigns` and
  `--validate-diagnostics` PASS in the candidate. At 1280×720 and 1.6 text scale,
  a native OS mouse click on the pinned result scrolled to **Set entry here** with
  the button focused: `workspace/qa/diagnostics/creator_diag_1p6_after_click.png`
  (before-click capture alongside it).
- **Candidate.**
  `workspace/candidates/content_diagnostics_2026-11-05/RavenloftFoundation.exe`,
  110,427,456 bytes, SHA-256
  `9acd6c35b119c8b872e0137b558cd60de67d2188c70779fc0c521fea6a7b027a`.
  The earlier `creator_usability_2026-11-05` candidate is untouched.
- **Dirty-state boundary.** Navigation preserves campaign-level form text, the
  draft and its dirty flag, and never saves. Entity-specific fields still use the
  existing **Apply** contract; unapplied entity-field text is not in the draft
  and is not silently committed by navigation. The focused regression asserts
  the campaign title and dirty flag; entity-form Apply behavior is unchanged.
- **Method and limits.** The long creator exercise remains callback-driven
  workflow/integration verification, not viewport input or human usability
  testing; it was not rerun merely to relabel it. The single result-selection
  check used native OS input on the source debug window. The exported candidate
  check is the headless asserted probe. Not every legacy rule has rich metadata;
  those are explicitly advanced. Rich diagnostics may coexist with the same
  legacy message in the text list. Fixed maps, four monsters, flag-only
  objectives and no undo/redo remain supported-scope limits.

## Pending-form protection (2026-11-05)

- **Confirmed lossy paths.** Before this change, `_select_area`, `_select_npc`,
  `_select_dialogue`, `_select_node`, `_select_choice`, `_select_quest`,
  `_select_objective`, `_select_encounter` and `_select_trigger` assigned the new
  selection and refreshed the controls, replacing unapplied form text.
  `capture_draft` carried campaign title/description/current-area name only, so
  Save and Playtest ignored entity-form text; Back discarded it; and diagnostic
  navigation used the same selectors. Validation could say the applied draft was
  valid without mentioning the pending text. This is a pre-guard control-flow
  reproduction; the initial standalone probe failed outside the autoload context
  and produced no pre-fix captured baseline. The current tests assert the
  protected behavior instead.
- **Policy.** One shared guard compares each supported form with the applied
  draft. Before a lossy transition it opens **Apply changes and continue**,
  **Discard these form edits** or **Cancel**. Cancel keeps text, selection and
  focus; Discard is explicit; Apply validates before changing the draft. Failed
  Apply keeps the text and the explanation and performs no navigation. Save,
  Playtest, Back, every selector and diagnostic navigation call the same guard.
  The header shows `Pending form edits: ...` and Save/Playtest refuse until the
  choice is resolved. No silent commit, no new editor section, no undo system.
- **Validation agreement.** `_validate` distinguishes the applied draft from
  pending form text and says so; Save/Playtest consume the same pending guard and
  the existing authoritative validator. Structured diagnostics continue to
  supplement the legacy checks. Duplicate status/panel messages remain where no
  stable deduplication key was introduced; unmapped legacy errors stay visible
  and non-navigable. Message strings are not parsed for locations.
- **Focused regression coverage.** Dirty NPC → diagnostic navigation; dirty
  dialogue/node/choice/quest/objective/encounter → selection change; dirty NPC →
  area change; Apply success; failed Apply preserving text and draft; explicit
  Discard; Cancel preserving text, selection and focus; Save and Playtest with
  pending text; failed validation preserving form and draft; and validation/
  save agreement. Tests assert the live control text separately from the applied
  draft, not only a dirty flag. Focused `tests/test_campaign_creator.gd`:
  **33 tests, 609 assertions**. Full suite: **339 tests, 4,324 assertions, exit
  0**. Historical pre-atomic pending-form run: **334 tests, 4,279 assertions**
  (creator **28/564**), retained as history and superseded by the current run.
- **Atomic Apply regression.** The failing pre-fix reproduction had a valid NPC
  name pending and `"   "` in the speaker field, with a valid stored speaker.
  The first application changed the NPC, refreshed the screen, and the later
  invalid speaker either disappeared or was overwritten; the operation returned
  success and the complete draft changed. The fix snapshots the complete draft,
  all detected form values, dirty state and selection. Any failure restores all
  of them, keeps the explanation, and writes no file. Success applies all forms
  before guarded navigation. The test compares the complete related draft before
  and after failure, not just `dirty`.
- **Unresolved-reference regression.** `_fill_options` and `_select_by_meta` now
  insert **Unresolved reference: <id>** for a non-empty stored id that is absent,
  instead of selecting the first valid option. Opening `guide_b` leaves
  `missing_talk` selected and not pending; an unrelated name Apply preserves it;
  choosing `guide_talk` repairs it and clears the diagnostic; opening or applying
  does not write a package. `CampaignStore.update_npc` permits preserving an
  already-stored missing dialogue while editing unrelated fields, but still
  refuses a newly invented missing id. The package writer refuses the invalid
  draft, so no file is overwritten.
- **Executable evidence.** Final candidate
  `workspace/candidates/pending_atomic_2026-11-07/RavenloftFoundation.exe`,
  110,463,552 bytes, SHA-256
  `4d88215acd720de9e1278dd2908a7e9ec3e6202aafa27fab8914bc7f9eba11c1`.
  `--pending-edit-probe` passed **37** checks in the candidate, including atomic
  failure, unresolved display/preservation and both validation commands;
  `--diagnostic-navigation-probe` passed **11/11**; `--validate-campaigns` and
  `--validate-diagnostics` passed. The prior pending, diagnostics and usability
  candidates were not overwritten.
- **Windowed interface check.** At 1280×720 and 1.6 text scale, the exported
  candidate showed `Unresolved reference: missing_talk` and the pending NPC name
  (`workspace/qa/pending_atomic/unresolved_1p6_scrolled.png`). A real OS click on
  the `guide_b` result opened the prompt (`guard_prompt_1p6.png`); Apply preserved
  the unresolved stored id while applying the unrelated name edit
  (`guard_applied_1p6.png`). The asserted probes cover the atomic failure path;
  this is a short external-input check, not a human-usability study.
- **Teardown warning.** The focused creator suite is the reproduction scope for
  the unresolved exact `5 ObjectDB instances were leaked at exit` plus
  `2 resources still in use at exit` warning recorded at the top of this report;
  the full suite was clean. It remains teardown noise without an established
  cause, not a passing assertion or a gameplay failure.
- **Limitations.** No undo or per-form history; the picker uses one explicit
  unresolved entry rather than a browser; duplicate validation status/panel
  messages remain; invalid unresolved saves are blocked rather than repaired.
  The prompt is modal and generic. Full validation-system unification remains
  out of scope. The pre-fix baseline is control-flow evidence, not an exported
  before/after run.

## Ashwick Ferry exact-candidate acceptance (2026-11-08)

- **Executable.** At the Ravenloft workspace root (outside this project):
  `workspace/candidates/ashwick_ferry_2026-11-08/RavenloftFoundation.exe`,
  110,511,808 bytes, SHA-256
  `8a3f067b142411039afef7324739126c664b8944baa0751d5e527053d31d4f5f`.
  Hash and size were checked before launch. The earlier
  `ashwick_ferry_2026-11-08_backend` build remains preserved.
- **Isolation and input.** The process used `APPDATA` =
  `workspace/qa/native_profile`, so its `slot1` and `auto` saves could not touch
  an existing profile. The run used visible mouse controls; the release ignores
  `--script`, and injected keyboard events were not accepted. No copied save,
  backend probe or direct state mutation was used.
- **Primary route.** Seed 4104856171; party Brother Aldric, Kaelen Dorn, Sera
  Vane and Ysolde. Maela Sense Motive **d20(8)+7 = 15 vs DC 15** succeeded and
  granted key/potion. Ledger Search **d20(14)+8 = 22 vs DC 10** succeeded. The
  key opened the door. Four rounds of combat ended with token x1 and 200 XP;
  Ysolde was at 10/13 HP. Slot 1 was saved before the bell, then the process
  closed.
- **Cross-process continuity.** Relaunch, normal Load slot, and the loaded state
  showed the key/token/potions, open door, removed ledger, spent encounter,
  four completed objectives and Maela's changed token branch. The bell raised
  victory once. Save, quit, reload showed **Complete**, no victory modal, no
  restarted encounter and token x1; repeat bell use was inspection only.
- **Alternative coverage.** Focused tests cover Maela success/failure, key,
  Open Lock, spare-key fallback, failed-ledger retry, failed-spare retry,
  pre-Maela actions and early-bell refusal. The exact window independently
  covered the Maela-success/key route; the other alternatives were not replayed
  there.
- **Limitations.** The Journal overlay rendered blank at the boathouse after the
  pre-bell load (four objectives complete, `ring_bell` open; capture
  `workspace/qa/native_50_journal.png`). The loaded save retained its objectives
  and the later run completed the quest; the overlay is not claimed working.
  This was an external-input acceptance, not a human usability study. No runtime
  or campaign content changed after export; later edits are documentation and
  QA evidence only. No full-suite run was repeated for this content checkpoint.

## Concentration and defensive casting (2026-11-13)

Scope: damage taken during casting forces a Concentration check (DC 10 + damage +
spell level, one check per damaging interruption); casting on the defensive is an
explicit checkbox in the spell list (DC 15 + spell level, no opportunity attack).
Source text and rulings: ADAPTATION_LOG 40, TRACEABILITY 18a-18b.

- **Source suite.** 390/390 tests, 4,851 assertions, 27 scripts, exit 0.
  `tests/test_concentration.gd` adds 12 tests / 57 assertions and asserts the roll
  inputs (roll, bonus, DC), not only the outcome: unthreatened cast, threatened
  cast whose reaction misses, injury success with the DC arithmetic, injury
  failure with slot/prepared/action spent and no effect, defensive success and
  failure, the level term raising the DC by one, one check per interruption,
  incapacitation by the reaction, invalid target preserving resources, missing
  ranks using Constitution only, and an old save without the skill entry.
  `tests/test_ranged_melee.gd` changed only for the provocation line's new wording
  ("while threatened and provokes").
- **Candidate.** `RL_Edit\builds\qa\candidates\concentration_2026-11-13\`,
  110,510,200 bytes, SHA-256
  `8ebb56f2b72461acf6323cf9bb728a084d98995b8617a3e957ee65afa379331a`.
- **Exact-executable probes.** `--demo-concentration --concentration-probe`: 56
  checks PASS, `PROBE RESULT PASS`. `--demo-ranged --ranged-probe`: 49 checks PASS.
  `--validate-campaigns`: PASS. `--validate-diagnostics`: PASS. Captures:
  `builds/qa/runs/2026-11-13_155123_concentration_probe_candidate/shots/`
  (`trip_concentration_00_start` ... `04_defensive_failure`). The fixture waits for
  round 2 so no reacting creature is still flat-footed, and drives the real Cast
  spell button, the real checkbox and the target cell.
- **Rendered log evidence** (screenshots, not assertions): `01` shows `Injury
  while casting: 9 damage + spell level 1: Concentration DC 10 + 9 + 1 = DC 20.`
  then `Concentration check: d20(1)+21 = 22 vs DC 20 - success` and the resolved
  missiles; `03` shows `casts Magic Missile defensively: no opportunity attack,
  Concentration DC 15 + 1 = DC 16.` with no reaction line; `04` shows `casts
  Scorching Ray defensively ... DC 17`, a failed `d20(13)-5 = 8` check, `The spell
  is disrupted: ... loses Scorching Ray, the prepared cast is expended and the
  action is spent.` and the status line `QA Caster Untrained's spell is
  disrupted.` Backend state (slot counts, target HP) is asserted separately in the
  probe and labelled `state:`.
- **Package.** `tools/qa/pck_paths.py`: 144 packed paths; 58 `res://src/*`, 31
  `content/*`, and no path from `builds/`, `workspace/`, `tests/`, `tools/`,
  `docs/` or any profile directory.
- **Limitations.** No human playtest. Combat Casting's +4, readied/delayed
  actions, counterspells, casting while grappled, weather and ongoing-damage
  interruptions, and spell components are not implemented. The pregens were not
  given Concentration ranks.

## Combat Casting (2026-11-13)

Printed text verified on PHB p. 92 before implementation: the +4 applies only to
Concentration checks made to cast while on the defensive, or while grappling or
pinned. Only the defensive clause is implemented.

- `tests/test_combat_casting.gd`: 6 tests / 28 assertions. Defensive check with
  and without the feat (bonus equals Constitution modifier plus the printed +4),
  the feat named once in the roll breakdown with value 4 and type untyped, an
  injury check receiving nothing even with the feat, duplicate feat text not
  doubling (and content validation still rejecting the duplicate), a failed
  defensive cast still spending the standard action, slot and prepared cast, and
  the catalog/validation/character-sheet contract.
- Whole suite after the change: **396/396 tests, 4,879 assertions, 28 scripts,
  exit 0**.
- Candidate `builds/qa/candidates/combat_casting_2026-11-13/` (110,511,656 bytes,
  SHA-256 `ec8aa425a30385d20d81261e666710302920881f001c2fa91059a47a10803c82`):
  both validators PASS, the concentration probe PASS (79 checks, now including a
  feat-holder whose log line reads
  `Concentration check: d20(1)-1 = 0 vs DC 16 [CON modifier -5, Combat Casting +4] - FAILED`),
  and the ranged probe PASS. 144 packed paths, no generated-output leakage.
- Scope boundary: the grappling/pinned clause is documented as not modeled
  rather than claimed.

## Integration acceptance in the shipped town-square encounter (2026-11-13)

Fixture `--demo-integration` runs content encounter `town_square_zombies` with its
own map, party cells and standard infected zombies, played by the four unmodified
pregens. The only fixture value is a fixed dice seed (20261113); no stat, cell or
modifier was retuned to change outcomes. `--integration-probe`: **49 checks PASS**,
`PROBE RESULT PASS` in both source and candidate
`builds/qa/candidates/integration_2026-11-13/` (110,517,400 bytes, SHA-256
`78b85a8688e17aaf69651626ded7f0e41f9a0f59f46bf00be16eed95821d1931`). Captures:
`builds/qa/runs/2026-11-13_160546_integration_probe_candidate/shots/`
(`00_opening`, `01_flat_footed_panel`, `02_melee_attack`, `03_thrown_into_melee`,
`04_cast_threatened`).

- **Correct rule behavior observed.** The opening logs combat-start flat-footedness
  and the enemy panel's AC line reports the state before anyone acts; Kaelen's
  melee attack reports the flat-footed state the resolver actually applied;
  Ysolde's thrown dagger logs `shooting into melee -4: Infected Zombie is engaged
  with Kaelen Dorn (PHB p.140)`; an ordinary Magic Missile in reach logs the
  provocation, the reaction misses, the cast completes and exactly one slot is
  spent.
- **No defect found** in the rules these mechanics resolve in this encounter.
  Monster AI, cover and the p. 140 "actually being attacked" nuance remain outside
  the model as documented.
- **Authoring limitation, now the next selected milestone.** Sera carries a light
  crossbow in her inventory but her equipped weapon is a short sword and the
  combat screen has no weapon switch, so the party's only usable ranged attack is
  throwing Ysolde's dagger. This is a player-facing gap rather than a rules bug.
- Not attempted here: finishing the encounter, a difficulty or balance judgment,
  and any human playtest. Three rounds were exercised.

## Carried-weapon access and crossbow loading (2026-11-13)

Reproduced first: Sera's authored equipment readies a short sword while her light
crossbow sits in inventory with no way to use it, and the combat screen attacked
only with the readied weapon.

- `tests/test_weapon_access.gd`: 9 tests / 41 assertions. The shipped rogue's
  carried list; drawing costs the move action and readies the weapon; a second draw
  in the same turn is refused with an explanation and no mutation; an unloaded
  crossbow refuses to fire and spends nothing; loading costs a move and firing
  spends the shot (a second shot needs another load); loading provokes when
  threatened; loading without a move action is refused; a two-handed weapon is
  refused while a shield is strapped on; equipment and carried lists do not leak
  between characters; returning to the melee weapon works.
- Whole suite: **405/405 tests, 4,920 assertions, 29 scripts, exit 0**. Existing
  ranged fixtures now mark their crossbows loaded because they measure range,
  engagement and the into-melee penalty; that is stated in the fixtures, and reload
  behaviour is covered only by the new file.
- Candidate `builds/qa/candidates/weapons_2026-11-13/`, 110,528,136 bytes,
  SHA-256 `47672918ef0e6d5ee10c4313dc43c71c82752478f5353082e5290d9ce023ea88`:
  both validators PASS; `--demo-weapons --weapon-probe` **30 checks PASS** (weapons
  control, draw cost, refusal of an unloaded shot, load, fired shot, return to
  melee); integration probe 49 PASS; concentration probe 79 PASS; ranged probe 49
  PASS. 144 packed paths, no generated-output leakage.
- Rendered evidence: `builds/qa/runs/2026-11-13_162413_weapons_candidate_final/shots/`
  (`trip_weapons_00_before`, `01_drawn`, `02_unloaded_refusal`, `03_loaded`,
  `04_fired`, `05_back_to_melee`). The weapon control shows
  `Light Crossbow (readied)`; the log shows
  `Sera Vane draws Light Crossbow (move action; PHB p.142).`,
  `Sera Vane loads Light Crossbow (move action; loading provokes attacks of
  opportunity; PHB p.115).` and
  `Sera Vane attacks QA Target Zombie with Light Crossbow: d20(8)+5 = 13 vs AC 11 |
  3 damage`.
- Adaptations (also in ADAPTATION_LOG 42): one move action both stows and readies;
  the BAB +1 free draw is not granted; loaded state is encounter-scoped; no
  ammunition; shield removal not modelled; threat stays reach-based.


## Weapon-state correction and shield handling (2026-11-13)

The first carried-weapon build exposed two defects, both reproduced before changing
anything: threat came from reach alone, so a crossbow-armed character took melee
opportunity attacks, and one move action both stowed and readied a weapon, which the
log described as the printed cost when it was not.

- `tests/test_melee_threat.gd`: 9 tests / 34 assertions. Sword threatens, crossbow
  does not, an unsupported reaction is refused with a reason and consumes no
  reaction (and works again once the sword is readied), switching to a crossbow and
  back removes and restores threat, a flat-footed creature still threatens but cannot
  react, engagement survives when only the target threatens, two crossbows across the
  way are not engaged, flanking needs two actual threats, and loading still provokes
  from a melee-capable enemy.
- `tests/test_weapon_access.gd`: 11 tests / 76 assertions. Sheathing and drawing are
  separate actions; a swap within one turn spends the move and the standard action
  (PHB p. 138) and the log names the slot; a loaded crossbow stays loaded while
  stowed; a spent shot is never restored; a refused attack leaves the weapon loaded.
- `tests/test_shield_handling.gd`: 9 tests / 50 assertions. The shipped fighter's
  strapped shield, loosing drops it on his square and lowers AC by its bonus, pickup
  and re-strapping restore it with no duplicate copy, a second shield cannot be
  strapped over the first, loosing without one is refused, a two-handed weapon blocks
  strapping one on, loose-then-ready uses the standard action in one turn, save/load
  round trip, and no cross-character leakage.
- Whole suite: **425/425 tests, 5,039 assertions, 31 scripts, exit 0**.
- Candidate `builds/qa/candidates/weapon_state_2026-11-13/`, 110,538,840 bytes,
  SHA-256 `2dd5c83a3926127eff7520f35e4bbe767e52d4b733f7f213ebc015c4fa7edc9a`:
  both validators PASS; `--demo-weapons --weapon-probe` **50 checks**, `--demo-shield
  --shield-probe` **27 checks**, integration 49, concentration 79, ranged 49, all PASS.
  144 packed paths, no generated-output leakage.
- Rendered evidence in `builds/qa/runs/2026-11-13_163904_weapon_state_candidate/shots/`:
  `trip_weapons_00_before` through `07_back_to_melee` (switch refused, sheathed,
  drawn, unloaded refusal, loaded, fired, back to melee) and `trip_shield_00_before`
  through `04_loose_standard`. The shield log reads
  `Kaelen Dorn unstraps and drops Heavy Steel Shield (move action; PHB p.142).` and
  the shield control shows the strapped shield with an explicit loose entry.
- Adaptations: ADAPTATION_LOG 42 (corrected), 43 (threat capability, including the
  recorded divergence on bow-armed unarmed strikes) and 44 (shield ready/loose/drop).
  The earlier claim that a swap was never cheaper than the printed rules is withdrawn.


## Unarmed-threat correction (2026-11-13)

Reported boundary: the shared threat helper still conflated "can attempt a melee
attack" with "is armed and threatens". PHB printed p. 137 ("If you're unarmed, you
don't normally threaten any squares") and p. 139 (armed unarmed attacks) settle it.

- Split into `Encounter.available_melee_attack` (attack option), `threat_capability`
  (armed state driving threat, flanking, engagement and provocation) and the existing
  reaction guards (can act, not flat-footed, one reaction per round). Ordinary empty
  hands no longer threaten; natural weapons and Improved Unarmed Strike do.
- `tests/test_melee_threat.gd`: **15 tests / 55 assertions**, adding ordinary
  empty-hand refusal, Improved Unarmed Strike armed status, natural-weapon threat,
  no false flank from an empty-handed enemy, no engagement when neither side threatens,
  and a load that provokes nothing from an adjacent unarmed enemy. Existing fixtures
  were checked for empty-hand assumptions; none relied on empty hands threatening.
- Whole suite: **431/431 tests, 5,060 assertions, 31 scripts, exit 0**.
- Candidate `builds/qa/candidates/unarmed_threat_2026-11-13/`, 110,539,432 bytes,
  SHA-256 `ef7688ed1f4975c4976577c5f14b533763ff0c027b82e7c18ab37019741d5c67`:
  both validators PASS; weapon probe 51 checks, shield 27, integration 49,
  concentration 79, ranged 49, all PASS; 144 packed paths, no leakage.
- `weapon_state_2026-11-13` is preserved with a `SUPERSEDED.txt` that names the
  empty-hand threat defect specifically. ADAPTATION_LOG 45 records the correction and
  keeps entry 43 as history.

## 2026-11-13 — ordinary unarmed attacks

- `Character.nonlethal` with `apply_nonlethal`, persisted through the save
  record; `Rules.nonlethal_immune` for undead and constructs; the size-based
  `Encounter._unarmed_strike`; the printed provocation in `attack_active`; the
  nonlethal branch in `_apply_damage`; nonlethal flags propagated through
  opportunity attacks and the monster full attack; nonlethal totals shown in the
  combat labels.
- `tests/test_unarmed_attack.gd`: **7 tests / 30 assertions** — size-based
  damage, nonlethal totals without hit-point loss, unconsciousness at the
  printed threshold, undead immunity, armed-target provocation, no provocation
  from an unarmed bystander, and the persisted nonlethal total.
- Whole suite: **438/438 tests, 5,090 assertions, 32 scripts, exit 0**.
- Candidate `builds/qa/candidates/unarmed_2026-11-13/`, 110,545,480 bytes,
  SHA-256 `c9d9f970a637d4f792651f6f5c05280fd8f0c1db61e8ada1f4cb66a2a48c0108`:
  weapons 51 checks, shield 27, **unarmed 15**, integration 49, concentration
  79, ranged 49, all PASS; both validators PASS; 144 packed paths, no leakage.
  The unarmed probe drives the exported executable: an empty-handed punch is
  announced as unarmed, provokes the armed target, deals nonlethal damage
  (hit points untouched), leaves the threat state empty, and the same damage
  path logs immunity and records nothing for an undead target.
- `unarmed_threat_2026-11-13` is preserved with a `SUPERSEDED.txt` naming only
  the missing unarmed-attack semantics; its threat verification still stands.
  Both snapshots now carry a `CHECKPOINT.md`.
- Superseded limitation: the lethal-at-−4 option and the "improved damage die"
  were not real gaps in the printed feat. See the 2026-11-13 nonlethal section
  below. the undead-immunity probe uses the engine damage call rather
  than two extra turns of UI setup.

## 2026-11-13 — nonlethal conditions, healing and the Improved Unarmed Strike record

- **Feat record corrected.** PHB p. 97 gives Improved Unarmed Strike no damage
  die; it grants armed status, the no-provocation clause against armed opponents,
  and the option to deal lethal or nonlethal damage. The earlier "improved damage
  die" limitation was invented and is withdrawn; no damage progression was added.
- **Lethal choice implemented.** `attack_active(target, mode, unarmed_damage)`
  accepts `"lethal"` for an unarmed strike: no penalty with the feat, the printed
  −4 without it (PHB p. 147). The combat screen exposes the choice next to the
  weapon control and resets it per attacker.
- **Nonlethal state machine.** `Character.nonlethal_state` /
  `refresh_nonlethal_state` derive `staggered` (nonlethal equals current hit
  points) and `nonlethal_unconscious` (greater), refreshed after nonlethal gain,
  hit-point damage, healing, rest and load. Equality staggered, greater
  unconscious and helpless, zero never staggers, and independent incapacities are
  preserved by using separate effect ids.
- **Action limit.** `Encounter._staggered_blocks_standard` /
  `_staggered_blocks_move` refuse a standard action after a move and a move after
  a standard action; the combat screen disables the same controls and shows
  "staggered" in the status line.
- **Healing.** `Character.magical_heal` removes nonlethal damage equal to the
  amount cured by the cure spell, a potion (combat or inventory) or the authored
  party-healing effect, including at full hit points. Natural hourly recovery is
  recorded as replaced by rest clearing the total.
- **Encounter completion.** `_check_end` counts only enemies that `can_act()`, so
  a fully nonlethally incapacitated enemy force ends the encounter in victory.
- `tests/test_nonlethal_state.gd`: **20 tests / 78 assertions**. Whole suite:
  **458/458 tests, 5,168 assertions, 33 scripts, exit 0**.
- Candidate `builds/qa/candidates/nonlethal_2026-11-13/RavenloftFoundationEdit.exe`,
  110,554,296 bytes, SHA-256
  `0e551045a24e82c53ce1c78abeac0959ff958248f7ec9654c2a599def6ef8acb`, built
  once in its own directory (`IDENTITY.txt`, `BUILD.txt`). Probes in that
  executable: weapons 51, shield 27, unarmed 15, **nonlethal 30**, integration 49,
  concentration 79, ranged 49, all PASS; both validators PASS; 144 packed paths,
  no leakage.
- The nonlethal probe (`--demo-nonlethal`, `--nonlethal-probe`) drives the UI: a
  staggered rogue shows "nonlethal 20 • staggered", Attack is disabled after a
  move, a potion removes nonlethal damage and clears the state, and a punch takes
  an already-staggered dummy past its hit points to unconscious/helpless, ending
  the encounter in victory with its hit points untouched.
- `unarmed_2026-11-13` is preserved with `SUPERSEDED.txt` and an
  `ARTIFACT_NOTE.txt` recording that an intermediate binary in that directory was
  overwritten and is not preserved.
- Limitation: the immunity half of the unarmed probe remains an engine-call
  demonstration rather than a fully UI-driven one; monk progression and touch
  spells are still out of scope.

## Encounter resolution and package discovery (2026-11-13)

### Encounter resolution correction

`Encounter._check_end` previously used `Character.can_act()` for both sides. That
treated any temporary inability to act as defeat: ghoul paralysis (1d4+1 rounds)
and a timed unconsciousness effect would end the fight, grant victory/XP and
campaign effects, and a wholly paralysed party would be defeated. The encounter
now uses two explicit predicates:

- `_enemy_defeated(ch)`: `dead` or `nonlethal_unconscious`.
- `_party_defeated(ch)`: `dead`, `dying`, `stable` or `nonlethal_unconscious`.

`tests/test_encounter_resolution.gd`: **11 tests / 33 assertions**. Cases:
paralysed enemy does not finish; timed unconsciousness does not finish; nonlethal
incapacitation wins; a dead enemy still wins; a mixed dead+paralysed group does
not finish until the last enemy is nonlethally out; party paralysis is not
defeat; a whole paralysed party keeps running and recovers when the effect
expires; nonlethally knocked-out party is defeated; a dead party is defeated; a
lone dying member is defeat; temporary incapacity grants no victory, XP, mode
change or flag change, and the real victory then awards XP once even after a
second `changed` emission.

### Package discovery diagnostics

`CampaignStore.list_user_campaigns()` previously dropped an unreadable user
package silently, so an author's campaign could disappear from every list with no
reason. Discovery now records `scan_errors` with the cause (missing manifest,
invalid JSON with line number, valid JSON that is not an object, id/folder
mismatch, illegal folder id); `CampaignDB` carries those into its registry
errors; the campaign selection screen shows them above the list; and
`--validate-campaigns` prints `CAMPAIGN PACKAGE ERROR: ...` and exits nonzero.
No file is rewritten and no old data is reinterpreted.

`tests/test_campaign_discovery.gd`: **7 tests / 24 assertions** (invalid JSON is
skipped with a line number; the registry carries the reason; id mismatch;
missing manifest; illegal folder name; repairing the manifest restores the
package and clears the diagnostic; a healthy package lists with no errors).

End-to-end in the exported executable, using a profile containing a broken
`user://campaigns/broken_pack/campaign.json` plus a valid creator-made
`qa_recovery` package:

- broken: exit 1, `CAMPAIGN PACKAGE ERROR: User campaign 'broken_pack':
  campaign.json is not valid JSON: Expected key (line 3)...`,
  `CAMPAIGN VALIDATION FAIL`, while `qa_recovery` and all three bundled campaigns
  are `CAMPAIGN VALID`.
- repaired (valid manifest, matching id): exit 0, `CAMPAIGN VALID broken_pack`,
  `CAMPAIGN VALIDATION PASS`.

Whole suite after both changes: **476/476 tests, 5,225 assertions, 35 scripts,
exit 0**; `--validate-campaigns` and `--validate-diagnostics` PASS in source. The
seven probes pass in the exported candidate: weapons 51, shield 27, unarmed 15,
nonlethal 30, integration 49, concentration 79, ranged 49 checks, no failures.
Packed-path audit: 144 paths, no leaked source/secret/build artifacts.

Candidate: `builds/qa/candidates/package_diagnostics_2026-11-13/RavenloftFoundationEdit.exe`,
110,555,832 bytes, SHA-256
`926b121b78ed16d094f1fde5c2335f2190319fb8c1dfba10cc225c8dc94afc39`, exported once
into its own directory (`BUILD.txt`). Intermediates
`encounter_resolution_2026-11-13` and `campaign_discovery_2026-11-13` are marked
`SUPERSEDED.txt`: they were built before the validator/reporting correction and
before the final documentation state, and are preserved, not overwritten.

Limitations: the campaign-screen notice is exercised by code inspection and by
the exported validator path, not by a windowed click-through; the discovery
diagnostics cover the manifest file, not damage inside area/dialogue files, which
the creator already refuses with its own message and the content validator
reports separately.


## Story-file diagnostics and recovery (2026-11-13)

### Reader and diagnostics

`ContentDB` now records structured diagnostics beside its human strings:
`_parse_json_file` keeps the parser message and line, and `_diag` attaches a
stable code, campaign id, package-relative source, entity type/id and line.
Codes: `content.area.syntax`, `content.dialogue.syntax`, `content.json.syntax`,
`content.area.shape`, `content.dialogue.shape`, `content.area.missing`,
`content.area.id_mismatch`, `content.area.duplicate`, `content.file.missing`,
`content.index.shape`, `content.area_manifest.syntax` / `.shape`.
`ContentDiagnostics` gained the `line` field. Parser lines are 1-based (Godot's
`get_error_line` is 0-based; verified with a direct parse probe). Shape errors
carry `line: 0` and never claim a line. Semantic errors remain descriptor-only and
keep their existing entity/field wording.

`validate_campaign` returns the same structured diagnostics, so
`--validate-campaigns`, `--validate-diagnostics` and the campaign screen agree on
validity. `Game.diagnose_campaign` validates through the content loader first and
returns those entries (file, line, code) instead of re-wrapping them as
location-less rules. `CampaignStore.load_package` now reports the damaged
dialogue file with its parser line and distinguishes syntax from shape; the
creator still refuses rather than rewriting.

### Tests and workflow

`tests/test_story_diagnostics.gd`: **9 tests / 69 assertions** — malformed area
and dialogue JSON with file and line 3; valid-JSON-wrong-shape with `line 0` and
no "invalid JSON" wording; missing file listed by `areas/_manifest.json`; broken
package refused without replacing the active campaign; creator refusal leaving
bytes untouched; repair clearing the diagnostic without leaking into another
package; both diagnostic surfaces agreeing.

Disposable-package CLI run in source (`qa_story_diag` under an isolated profile):

- malformed area: `--validate-campaigns` exit 1,
  `Area file areas/area_01.json is not valid JSON: Expected key (line 3).`;
  `--validate-diagnostics` exit 1 with `"code":"content.area.syntax"`,
  `"source":"areas/area_01.json"`, `"line":3`, `"campaign":"qa_story_diag"`.
  SHA-256 of the damaged file unchanged; `--campaign=qa_story_diag` prints
  `CAMPAIGN LOAD FAILED` with the same reason and does not start.
- malformed dialogue: exit 1 with `Dialogue file dialogue/intro.json is not valid
  JSON: Expected key (line 3).`; JSON code `content.dialogue.syntax`, line 3;
  bytes unchanged.
- after restoring both files: both validators exit 0 (`PASS`).

Exported candidate `story_diagnostics_2026-11-13` (110,566,424 bytes, SHA-256
`1a5ce809ba8eda304315f8a53813599f6f3fe0b100cc85ddacd0cf1572eb2421`):

- `--encounter-end-probe` — 11/11 checks: paralysis does not end combat or pay XP,
  expires through the turn loop, recovery does not resolve it, nonlethal defeat
  resolves once and pays once.
- `--package-diagnostics-probe` — 20/20 checks on the real campaign screen with an
  isolated profile: broken manifest is not listed and its reason is readable;
  the story-damaged package is listed and every campaign stays selectable; its
  **New game** is refused with `Campaign unavailable`, `areas/area_01.json` and
  `line 3`; the active campaign is unchanged; **Validate** reports the same file;
  repairing the area and refreshing/reopening lets it load; repairing the
  manifest clears the notice.
- `--nonlethal-probe` — 30/30 checks still pass.
- Exported CLI on the story-damaged package: `--validate-campaigns` exit 1 with
  the file/line, `--validate-diagnostics` exit 1 with
  `content.area.syntax`/line 3, and exit 0 after repair.
- Window capture at the supported minimum 1280x720 and the actual default
  Settings text scale (1.0, fresh profile): the discovery notice is fully legible
  above the campaign cards; screenshot in
  `builds/qa/candidates/story_diagnostics_2026-11-13/runs/shots/package_notice.png`.

Whole suite: **485/485 tests, 5,294 assertions, 36 scripts, exit 0**; both
validators PASS on the clean profile. Packed-path audit: 144 paths, no leaked
source, secret, profile or build artifact.

### Limitations

- Shape diagnostics intentionally carry no line; semantic reference errors still
  have no source mapping and report entity/field text only.
- Parser lines are normalized to 1-based here (Godot reports 0-based). The earlier discovery record that quoted `line 3` for a token on human line 4 is superseded by this convention; new messages report 4.
- The capture shows the top of the list; the story-damaged card is below the fold
  and was exercised through the probe's ordinary button press, not a human click.
- The probe uses the real screen, buttons and refresh path, but it runs headless;
  the windowed path is represented by the capture plus the source-run screen.

## Save/content compatibility (2026-11-13)

Reproduced through the existing load path against a disposable package and an
ordinary `slot2` save before changing runtime code:

| Edit | Observed before the fix | After the fix |
| --- | --- | --- |
| Prose only | loaded at saved cell | loads at saved cell |
| Entry moved | loaded at saved cell | loads at saved cell |
| Saved cell became a wall | loaded into the wall | refused, `blocked` message |
| Saved position out of bounds | silently used area start | refused, `outside` message |
| Saved side quest removed | progress silently dropped | refused, names the quest |
| Flag declaration removed | flag value intact | loads, flag intact |
| Saved area removed | refused, missing area | refused, missing area |
| `content_version` changed | refused | refused |

Backend tests: `tests/test_content_compatibility.gd`, **11 tests / 108
assertions**. They assert refusal before live replacement (saved cell, quest
status, campaign id and session position unchanged), unchanged save bytes, the
harmless cases, unsupported save format, uninstalled campaign and recovery after
restoring content. Whole suite **496/496 tests, 5,402 assertions, 37 scripts,
exit 0**; `--validate-campaigns` and `--validate-diagnostics` PASS.

Exported candidate `save_compat_2026-11-13` (110,575,720 bytes, SHA-256
`71a6e0cad5fb2138ef2c23d791f1ac8953104b0521aa7b9fe361586fd2b22c36`):

- `--save-compat-probe` — 14/14 checks: prose and entry edits load; blocked cell,
  out-of-bounds position and removed saved quest are refused with specific
  messages; a removed flag declaration still loads the stored flag; removed area
  and changed content version are refused; save bytes unchanged.
- `--save-compat-ui-probe` — 9/9 checks through the ordinary Load modal:
  harmless save loads and closes the modal at the saved cell; blocked content is
  refused with the message visible and the modal stays open; session, campaign
  and save bytes remain unchanged; restoring the area recovers the save.
- Capture: `builds/qa/candidates/save_compat_2026-11-13/runs/shots/save_compat_refusal.png`,
  1280x720 at the actual default Settings text scale (1.0), showing the Load
  modal, the listed slot and the blocked-cell refusal.
- Packed paths: 144; required runtime scripts, `content/` and assets included;
  no development files, private references, profiles or generated artifacts.

### Limitations

- The UI demonstration activates the ordinary button signal headlessly; it is
  not an OS-level mouse click and not a human playtest.
- The rendered capture is one 1280x720 window at default text scale. The earlier
  diagnostics UI limits remain: a story-damaged campaign card can be below the
  fold and was exercised through the probe, not a human click.
- Shape/semantic diagnostic entries still intentionally carry no parser line.

## Campaign-list usability (2026-11-13)

Isolated profile: 10 listed campaigns (three bundled, five valid user packages,
one 77-character title, one damaged area), plus one malformed-manifest notice,
at 1280x720. The probe counted 11 panel children including the notice.

| Check | Before | After |
| --- | --- | --- |
| 1.0 list height / viewport | 2058 / 495 px | 2058 / 495 px |
| 1.6 list height / viewport | 2860 / 431 px | 2860 / 431 px |
| `follow_focus` | false; focus at y=2887 with scroll 0 | true; focused action scrolled into view |
| 1.6 list width / viewport | 1384 / 1204 px, horizontal bar | 1204 / 1204 px, no horizontal bar |
| Disabled Continue/Load | focusable | skipped by Tab |

`tests/test_campaign_list_layout.gd`: **2 tests / 35 assertions**. It builds
four temporary packages through `CampaignStore.create`, instantiates the real
`Main` scene, opens the ordinary campaign screen, and asserts title wrapping, no
horizontal requirement, focus-follow to the last action, disabled-focus skipping,
and that rebuilding after a package disappears neither activates a card nor
changes the active campaign.

Whole suite **498/498 tests, 5,439 assertions, 38 scripts, exit 0**;
`--validate-campaigns` and `--validate-diagnostics` PASS. Exported candidate
`campaign_list_2026-11-13` (110,577,992 bytes, SHA-256
`217a061b1cac4ae1df4024ac285ff59a94b2220d62f5465518aa1aa019819830`):
`--campaign-list-probe` PASS at 1.0 and at 1.6 set through the Settings slider
(`follow=true`, no horizontal overflow, focused action inside the viewport).

Native OS input in that executable at 1280x720: wheel reached bottom cards; Tab
focused an enabled action on a lower card and the list followed; Validate named
`qa_list_damaged` and then `qa_list_long_title`; New game on the damaged package
refused with its id and area line; closing it and launching the long-titled
campaign showed the matching title on party selection; validation return kept the
scroll position. Captures in
`builds/qa/candidates/campaign_list_2026-11-13/runs/shots/native_*`. Packed paths:
144; required runtime scripts, `content/` and assets included, unintended
development files, private references, QA profiles and generated artifacts
excluded.

### Limitations

- Native interaction was one automated 1280x720 window per check, not a human
  playtest; scaled coordinates target the 1280x720 client layout.
- The 1.6 run used the persisted setting changed and confirmed through the real
  Settings slider; the 1.0 run used a fresh profile.
- Back from party selection rebuilds the list at the top; this was recorded as a
  clean reset, not treated as a defect.
- The 1.6 party-selection screen clips one card's last trait line behind the
  footer; that is outside the campaign-list fix and is the next selected task.

## Party selection at 1.6 (2026-11-13)

Isolated campaign, 1280x720, five pregens, default party of four.

| Check | Result |
| --- | --- |
| 1.0 grid / viewport | 449 / 449 px; all five cards visible, no scroll |
| 1.6 grid / viewport | 689 / 439 px; scroll max 689 |
| Labels inside cards at 1.6 | all five cards, no clipping |
| Horizontal scrolling at 1.6 | none required (542 / 542 px) |
| Focus before fix | last checkbox y=657-869, viewport y=180-619, scroll 0 |
| Focus after fix | scroll 250, card y=407-619, fully visible |
| Footer | Begin/Back start at y=648, below the grid viewport (ends 619) |

`tests/test_party_layout.gd`: **3 tests / 39 assertions**. It instantiates the
real `Main` scene at 1.6 and asserts card growth, wrapped labels inside cards,
focus scrolling the last full card into view, visible Begin/Back, empty and
five-member refusal, a one-member minimum, Begin starting exactly the four
chosen characters, and Back/reopen restoring defaults without changing the
campaign.

Whole suite **501/501 tests, 5,478 assertions, 39 scripts, exit 0**;
`--validate-campaigns` PASS and `--validate-diagnostics` PASS on clean profiles.
Exported candidate `party_layout_2026-11-13` (110,580,824 bytes, SHA-256
`bb7bc2901831bc53769dcbfd5935485a99101a869ac250b9637cffb89a380666`):
`--party-layout-probe` PASS at 1.0 and at 1.6 set through the Settings slider.
Packed paths: 144; no tests, tools, documentation, builds or QA profiles.

Native OS input in that executable: five Tabs reveal Ysolde's full card at 1.6;
wheel reaches the bottom cards; clicks reduce the party to three; Begin launches
it; Back returns to the campaign list. At 1.0 all five cards remain visible and
Begin launches the campaign.

### Limitations

- Each native check is one automated 1280x720 window, not a human playtest.
- At 1.0 the entire party fits without scrolling; at 1.6 scrolling is required
  and the top view legitimately ends partway through Sera's card.
- After Begin at 1.6 the intro modal is horizontally clipped by its fixed width,
  including the Close control. This is a separate modal layout defect and is the
  next selected task, not a regression from the party-grid change.

## Intro modal at 1.6 (2026-11-13)

| Check | Before | After |
| --- | --- | --- |
| 1.6 panel | 1665x546 at x=0 | 800x520 at x=240-1040 |
| 1.6 heading min width | 1454 px, no wrap | 1 px min, 589x165 wrapped |
| 1.6 Close | x=1486-1637, off-screen | x=861-1012, inside panel |
| 1.0 long-title panel | 1080 px wide | 800 px wide, wrapped |
| Content height | expanded panel | 744x282 viewport over 420 px content |
| Focus | none | Close on open; released on close |

`tests/test_modal_layout.gd`: **3 tests / 46 assertions**. It checks viewport
bounds with a maximum-length title, heading wrapping, a tall scrolled body,
focus-follow to Continue, a short modal, the real intro, Begin and Close
dismissal, Escape, focus release, and unchanged campaign/exploration state.
The exported `--intro-layout-probe` and `--intro-click` PASS at 1.0 and 1.6.

Whole suite **504/504 tests, 5,524 assertions, 40 scripts, exit 0**;
`--validate-campaigns` PASS and `--validate-diagnostics` PASS on clean profiles.
Candidate `intro_modal_2026-11-13` (110,584,776 bytes, SHA-256
`0dc6de1b29bc084511e19dd22e525c9a842717782491c8ce7546b15a455098dc`). Packed
paths: 144; no tests, tools, docs, builds or QA profiles.

Native OS input at 1280x720: campaign list → party → Begin → readable intro at
1.0 and 1.6; mouse Close and mouse Begin dismiss to exploration; keyboard
Tab+Enter closes without opening Pause; wheel exposes the final text and Begin
at 1.6; movement/turn input works after dismissal. Settings at 1.6 remains
inside the window with Close reachable.

### Limitations

- Each native check is one automated 1280x720 window, not a human playtest.
- SendKeys Escape was not delivered reliably; Escape dismissal is covered by an
  automated InputEvent test, while native keyboard dismissal used Tab+Enter.
- At 1.6 the intro body requires scrolling; the top view intentionally ends
  before the final note and Begin.
- No further start/load/play blocker was demonstrated. Further work should
  return to foundation content/rules rather than another screen sweep.

## Quest-completion idempotence (2026-11-13)

`QuestLog.sync_flags()` reported `Quest complete` again whenever a completed
quest was synchronized with flags. Because `GameSession._sync_quests()` logs the
returned messages, later effects could re-announce an already resolved quest.

- Focused reproduction before the change: `tests/test_quest_log.gd` failed with
  `ARRAY(["Quest complete: The Watch"]) != ARRAY([])` on the second sync.
- Correction: skip quests whose status is already `complete` in
  `sync_flags`; the completion transition is reported once.
- Focused test: **2 tests / 15 assertions**, exit 0.
- Full suite: **506/506 tests, 5,539 assertions, 41 scripts, exit 0**.
- Validators: `--validate-campaigns` PASS; `--validate-diagnostics` PASS.
- Candidate: `builds/qa/candidates/quest_log_idempotence_2026-11-13/`,
  110,586,088 bytes, SHA-256
  `3f85c47ff9355b9e5efb135b4a9d2f784be5c00ec5228a2f83809ae869302b23`.
- Exact candidate `--quest-log-probe`: **6/6 PASS**, including the live
  `ravenloft_demo` completion log count remaining at one after a second flag
  synchronization.
- Package: **144 packed paths**, no tests, tools, docs, builds, private
  references or QA profile output.
- Limits: automated session/log probe, not a human playtest or windowed UI
  replay; no campaign content, reward, save-format or setting change.

## Party contract and Ashwick minimum (2026-11-14)

`party.min` was validated on content load but ignored at runtime, so a campaign
that declared a larger minimum could still be started with fewer characters.
Ashwick declared 1 while its only bell token comes from a mandatory encounter.

- Correction: one shared interpretation of the campaign range
  (`GameSession.party_limits` / `party_size_error` / `party_range_text`),
  enforced at party selection (Begin unavailable with the reason) and in
  `new_game` before any state or campaign switch is committed.
- Content: Ashwick `party.min` 1 → 3, description states "three or four
  adventurers"; `version` stays 2, so compatible v2 saves still load. `party.min`
  is a new-game restriction and does not itself invalidate an otherwise
  compatible existing save; the documented save-format and content-safety
  refusal checks are unchanged. A version-2 save holding two characters loads in
  the focused regression, which separates new-game eligibility from save-load
  compatibility.
- Focused tests: `tests/test_party_limits.gd`, **8 tests / 91 assertions**, PASS,
  covering minimum/maximum in UI and `new_game`, refused requests preserving
  campaign, session, RNG and save bytes, campaign-specific limits, unchanged
  1–4 wording for campaigns that keep their range, and compatible-save loading.
- Full suite: **525/525 tests, 6,054 assertions, 43 scripts, exit 0**.
- Validators: `--validate-campaigns` PASS (3/3); `--validate-diagnostics` PASS.
- Candidate: `builds/qa/candidates/party_min_2026-11-14/`, 110,634,608 bytes,
  SHA-256 `87f94b96653402b161aaa1d7fe0fecff27f9292f536a0dfa5384975c7a0f84a4`.
- Exact candidate, automated party-screen probe only: `--party-limits-probe
  --probe-size=1280x720 --probe-text-scale=1.6` **22/22 PASS** (range shown, two
  characters refused with the reason and Begin unavailable, three characters
  begin, footer buttons inside the window). Ordinary native-input verification
  of this change was not performed.
- Package: **186 packed paths**, no tests, tools, docs, builds, addons,
  workspace, Markdown or QA-profile path.
- Composition evidence (`builds/qa/runs/2026-11-14_party_min_check/`): all ten
  three-character subsets won the mandatory encounter at seeds 11 and 4242 under
  one scripted policy that uses weapons, prepared spells, turning, healing and
  each character's single potion. Bounded evidence for the authored minimum, not
  a win guarantee or a balance validation.

## Application option guard (2026-11-14)

**Defect.** Application options (`OS.get_cmdline_user_args()`, i.e. text after
Godot's `--` separator) were dispatched by a chain of `in args` and
`begins_with` tests with no rejection path. An unrecognised option matched
nothing and the game started normally, so a mistyped CI command looked like a
hang rather than an error. Reproduced during the audit: `-- --validate-content`
(the option named in `ROADMAP.md` but never implemented) started the game
headless and ran until killed.

**Correction.** `Main.APP_FLAGS` (60 bare options) and
`Main.APP_VALUE_OPTIONS` (11 `--name=value` options) declare the supported
vocabulary; `Main.application_arg_error(args)` returns `""` for a usable command
line and otherwise one message naming each offender plus the closest supported
alternatives. `_ready()` prints it and quits **2** before presenting anything. A
`--name=` option with an empty value is refused for the same reason: the dispatch
would otherwise silently use the default. Engine options are unaffected — they
are consumed by Godot before the game sees its arguments. Exit status is now
0 = ran, 1 = ran but a validation/probe check failed, 2 = the invocation was
wrong.

**Tests.** `tests/test_cli_args.gd`: **13 tests / 209 assertions**, PASS —
no-argument acceptance, bare-word tolerance, the reported `--validate-content`
typo, every unknown option listed, the three validator commands, nineteen
representative probes, all eleven value forms, empty-value refusal, a realistic
probe command line, registry uniqueness, and rejection of every registered
option as unknown.

**Boundary.** Full suite **538/538 tests, 6,263 assertions, 44 scripts, exit 0**;
`--validate-campaigns` PASS (3/3); `--validate-diagnostics` PASS (`[]`).

**Candidate.** `builds/qa/candidates/cli_args_2026-11-14/`, 110,637,712 bytes,
SHA-256 `e3650ecbcab429e4f23eec83976c74277b181e2842f26ad93ee361503cc45262`.
Verified in that exact executable: `-- --validate-content` and `-- --bogus-option`
print the refusal and exit **2**; `--list-campaigns`, `--validate-campaigns` and
`--validate-diagnostics` exit **0**; a no-application-argument launch exits 0;
representative existing probes still run (`--quest-log-probe` PASS,
`--party-limits-probe --probe-size=1280x720` PROBE RESULT PASS). Package: 186
packed paths, zero `tests/`, `tools/`, `docs/`, `builds/`, `workspace/` or
`addons/` entries and zero Markdown files; all 32 content JSON files are packed.

**Limits.** Classification is pinned by unit tests; the process exit statuses
above are headless checks against the exported candidate. No window was opened,
no gameplay was replayed, and no human playtest was performed for this correction.

## Player-view assessment - The Ashwick Ferry (informed evaluator pass)

*Post-checkpoint addition, recorded after `builds/qa/snapshots/2026-11-14_cli_args/`.
No new executable and no sealed checkpoint were produced. No code, content, rules
or UI were changed; this is an assessment, not a correction.*

**Candidate.** `builds/qa/candidates/cli_args_2026-11-14/RavenloftFoundationEdit.exe`,
SHA-256 `e3650ecbcab429e4f23eec83976c74277b181e2842f26ad93ee361503cc45262`.

**Setup.** 1280x720 window; text scale **160 %**, the largest offered in Settings and
confirmed in Settings before play. Disposable profile
`builds/qa/runs/2026-11-14_ashwick_player_view/profile`. Two seeds were used
because the run had to be restarted: 2410389571 (run 1) and 1524215524 (runs 2-3).
**Party:** Kaelen Dorn, Brother Aldric, Ysolde - Sera Vane deselected to reach the
supported three. **Input:** ordinary external mouse through the run's `drive.ps1`
(`SetCursorPos` + `mouse_event`). Keyboard injection (SendKeys) does not reach the
game window, so every action was a click on an on-screen control; no key drove the
game. Screenshots: `builds/qa/runs/2026-11-14_ashwick_player_view/shots/` (01-94).

**Route and stopping point.** Campaign list -> New game -> three adventurers ->
intro -> landing -> Maela -> skiff -> boathouse -> ledger -> tack-room key ->
mandatory encounter (won, round 4) -> bell token -> landing -> Maela account.
Run 1 stopped there, on the **truth** account. Run 2, restarted to take the mercy
account, was **defeated** in the mandatory encounter. Run 3, loaded from the only
autosave (the boathouse), re-entered that encounter and stopped in round 7 with
Aldric 8/21, Ysolde 1/13, Kaelen 28/28 and both drowned dead at 16/16, because
clicks aimed at an adjacent square kept landing on a party token and spent turns
opening character sheets.

**Not reached, therefore not assessed:** the mercy account in a playable state,
the bell and *break the token and leave it silent*, the specific epilogue, the
completed Journal, and the repeatable post-ending conversation. Nothing below is
evidence about those.

### Findings

1. **The mercy account sits below the fold of the decision list** (consequential).
   `48_maela_account.png`: at 160 % the visible rows end at *Show her the last page
   and tell her all of it. - unavailable*; *Tell her Ivo died bringing a passenger
   home. Let her keep that.* is only reachable by scrolling. The visible rows still
   commit a terminal account - truth and mercy both set `maela_decision` - and once
   one is taken the rows are gone (`49_account_options.png`: the truth text, then
   only *Let her have the rest.*, which returns to the root). That is what happened
   in run 1: the account was committed from the visible row without the mercy
   statement ever being on screen. An irreversible choice should not be presented
   as a list whose decisive row is hidden. **Correction justified.**

2. **The Journal shows raw internal flags, not events.** `35_journal2.png`:
   *Recorded world events* lists `ledger found`, `maela spoken`, `maela spoken once`,
   `maela trust`. These are identifiers, not player-facing event text, and nothing
   separates known facts from unresolved questions, so the question "does the
   Journal distinguish known facts from open questions" cannot be answered yes.

3. **The optional page is closed to this party composition.** The strongbox needs
   Open Lock, which is trained only; the log says *Open Lock is trained only;
   Ysolde has no ranks in it* (`34_strongbox.png`). The roster's only lockpicker is
   Sera Vane, and this party dropped her to reach three; a three-character party
   may of course include her. Any supported three-character party without Sera
   reaches the ledger but not the optional page, and the reason appears only in the
   log, not on the object.

4. **Required refusals scroll out of the exploration log.** At 160 % the exploration
   log holds about two lines (combat holds about five), so the line explaining *why*
   an interaction failed - lock refusal, trained-only note - is already gone when the
   player looks (`34_strongbox.png`, `36_tack_door.png`). The player sees that
   nothing happened, not why.

5. **The party card contradicts the combat UI.** `08_party_three.png`: *Cleric of
   the Morninglord (EXAMPLE). Turn undead and orisons are not implemented in this
   slice.* Combat offers Aldric a usable *Turn undead: 4 of 4 uses left today*
   (`91_r7.png`). **Correction justified** (copy).

6. **Long area titles clip the control column at 160 %.** `35_journal2.png`,
   `63_ledger_nail.png`: *Pause (E*, *Party (Tal*, *Sheet (C*, *nventory (*,
   *Save gam*. The landing header fits; the boathouse header does not.

7. **Clear where it matters.** The defeat screen is honest and complete
   (`78_critical.png`): it says the party fell, states that combat autosaves on
   victory only, and offers load or begin again. Reach and damage-reduction feedback
   are explicit - *Drowned Dead is 15 ft. away; melee reach is 5 ft. Move closer
   first.*, *damage reduction 5/slashing applies (piercing). Drowned Dead takes 0
   damage (HP 16/16).* No finding.

8. **Control friction, recorded as observation only.** Clicking a party token opens
   the character sheet, and in a single-file column the token covers the square a
   player aims at. It ended run 3; it is not claimed as a defect.

### Correction judgement

Two findings are worth acting on: the pre-commitment visibility of the mercy row (1)
and the cleric copy (5). The rest are presentation debt for a polish pass. None were
changed here, per the assessment-only scope.

### Limits

An informed evaluator pass, not a blind test or a human playtest: the route was known
in advance and was driven by scripted mouse coordinates. The mercy line, the bell, the
epilogue, the completed Journal and the post-ending conversation were never displayed,
so their clarity remains unverified. Every value above is read from a screenshot or
the run's own log; no validator, suite or checkpoint was re-run.

## Correction batch — inspection triage and the account decision (post-checkpoint)

*Added after `builds/qa/snapshots/2026-11-14_account_decision/`. Two bounded
corrections were authorized from the assessment above; the retained findings were
not touched.*

### Reported combat turn loss: not reproducible

Clicking a party token opens that adventurer's sheet and nothing else. The grid
click reaches `CombatScreen._on_cell_clicked`, a party-occupied cell calls
`_inspect_index`, and that only opens the modal; the encounter is never touched
(no action, no movement, no `end turn`, no roll), and the sheet's dim layer blocks
click-through. The turn that appeared lost in the assessment came from the clicks
after it — a move on an empty square and an attack on an enemy.

Evidence, in the existing windowed probe: `--demo-inspect --inspect-probe` now
replays the grid click on the active party token and requires the sheet to open
with round, active combatant, `turn_state`, every combatant's HP and the combat
log length unchanged, then the same after closing. **Eight checks, PASS** in the
source tree and in the candidate. The probe still reports its **five pre-existing**
failures of 49 checks (recorded as seven at the time — see the 2026-11-20
reconciliation below): the first enemy's `Inspect` control is laid out below the
1280x720 client. An A/B run with the new block removed fails identically, so they
are not caused by this work and were left for their own scope.

### Maela's account is a deliberate decision

Content only, in `content/campaigns/ashwick_ferry/dialogue/maela_vey.json`, using
the dialogue runner's existing conditions, effects and `next`. The three
committing rows left the general conversation and one named entry replaced them:
*Tell her what the ledger shows about Ivo's last fare.* A dedicated
`account_decision` node states that whatever is said now is what Maela keeps, and
offers the truthful account, the evidence-aware variant when the last page is
found, the fabricated passenger account, and a noncommitting *Not yet - say
nothing about the ledger.* Each account opens its own statement page with the
account at full width and an explicit *Tell her. This commits the account she
keeps.* / *Not yet - step back.* Only the committing choice carries the original
effects, so `maela_decision` stays mutually exclusive and once-only, and the
consequence nodes and epilogues are unchanged.

At 1280x720 with the Settings slider at its maximum (160 %), verified natively on
two separate pre-decision saves, all four alternatives fit on one screen, the
cancel path commits nothing and re-offers the entry, and both commitments land
with their own objective completion and side quest.

### Stale cleric description

`content/shared/characters.json`: *"Turn undead and orisons are not implemented in
this slice"* → *"Turn undead is implemented; orisons are not in this slice."* Turn
undead is implemented; no level-0 spell exists and no orison is referenced in
`src/` or `content/`, so the orison half stands. No ability was added.

### Corrected claim in the assessment

The assessment said a three-character party necessarily drops Sera and so loses
the optional page. A three-character party may include her; only this party
omitted her. Corrected above; the finding itself stands unchanged.

### Evidence

- Focused: `test_ashwick_ferry.gd` 10/10, `test_ashwick_second_ring.gd` 11/11,
  `test_journal_panel.gd` 6/6.
- Full suite **541/541 tests, 6,364 assertions, 44 scripts, exit 0**;
  `--validate-campaigns` PASS (3/3); `--validate-diagnostics` PASS (`[]`).
- Candidate `builds/qa/candidates/account_decision_2026-11-14/RavenloftFoundationEdit.exe`,
  110,642,032 bytes, SHA-256
  `022817bee0515cef0b76b918565a76d20e1a40c699dd6bf286a4811c565e3980`; both
  validators PASS in it, the new probe checks PASS in it, 186 packed paths with no
  `tests/`, `tools/`, `docs/`, `builds/` or Markdown.
- Checkpoint `builds/qa/snapshots/2026-11-14_account_decision/` (tarball
  `f756dfce…f9a4a`, manifest `07791b56…875f8d5`, 535 files all OK).

### Still not verified

The silent-bell resolution and its ending remain unverified through ordinary
windowed interaction; that part of the assessment stands incomplete. A save made
before the copy fix still shows the old cleric sentence, because a save embeds the
character note (`n18_notes2.png`); the content version was deliberately not bumped,
since that would refuse every existing v2 save for a text-only change.

**Closed later the same day.** The silent-bell resolution and the mercy/silence
ending were then reached through ordinary windowed play - see *Silent-bell route
completed through ordinary play* at the end of this file.

## Silent-bell route completed through ordinary play (post-checkpoint)

*Documentation only: no source, content, test, executable or checkpoint change.
Executable `builds/qa/candidates/account_decision_2026-11-14/RavenloftFoundationEdit.exe`,
110,642,032 bytes, SHA-256
`022817bee0515cef0b76b918565a76d20e1a40c699dd6bf286a4811c565e3980`. Window
1280x720, text size confirmed at the Settings maximum (160 %) before play, ordinary
OS mouse input. This closes the verification gap, not the implementation.*

### State and provenance

The mercy-committed state from the account-decision pass had not been saved (the
profile's `auto.json` was byte-identical to the pre-decision copy; dialogue commits
do not write a save), so the route continued from an ordinary-play disposable save
instead of a prepared one. Profile `silence_run/` is a copy of
`builds/qa/runs/2026-11-14_native_mercy/profile_mercy/`'s autosave (written
`2026-11-14 15:59:18` by mouse-driven play in the earlier native pass): landing
`(4,7)`, three-adventurer party Aldric / Kaelen / Sera, tack room cleared, Ivo's
token held, optional page found, **no account decided** and no bell outcome. The
original profile was not modified, no flag was edited, no item granted, no
teleport, and the mandatory tack-room encounter was not replayed.

Mercy was then selected through the normal UI on that state: the clearly named
entry, the decision page, the passenger statement page, and *Tell her. This commits
the account she keeps.* The decision page showed all four alternatives on one
screen at 1.6, with the evidence-aware row **available** this time (the page had
been found).

### The route as it actually played

1. **Bell.** Walked from the landing to the bell (south-west of the entry). Its
   page offered five rows: *Ring once for passage.*, *Ring twice for the dead.*,
   *Break the token and leave the bell silent.*, *Inspect the waiting bell.*,
   *Step away.* — the header says the notice gives three answers and none of them
   is free.
2. **Silence.** Chose *Break the token and leave the bell silent.* The log read
   *"You set the token against the stone and break it. The socket stays empty. The
   bell has nothing to say. Maela is waiting at the landing; speak with her before
   you call the crossing finished."* and the bell's next page read *"The broken
   token lies in the socket. The silence is a decision, not a peace."*
3. **Return.** Walked back to Maela and re-opened the conversation. The epilogue
   was **not** automatic: the first page after the ending was the ordinary
   conversation with the account rows closed, and the epilogue row — *Tell me what
   the silence means for the ferry.* — sat **below the fold at 160 %**, seven
   unavailable rows down, and had to be scrolled into view.
4. **Epilogue.** That row gave *"The token is broken. The socket stays empty.
   Maela does not ask you to ring. 'Ask me what you need to ask.'"* with *Let her
   keep the story she has.* available; choosing it gave *"Maela believes Ivo died
   trying to bring someone home. She keeps the landing as a memorial, though no
   ferry crosses. The silence is yours to carry."*, the victory narration, and the
   objective panel **Complete**. Leaving the conversation raised the
   *Campaign objective complete* modal.
5. **Journal.** *Completed: The Ashwick Ferry, The Passenger's Story* and
   *Recorded world events*: bell resolved, bell silenced, drowned cleared, ivo
   token found, last page found, ledger found, maela decision.
6. **Repeat conversation.** Re-opening Maela after the ending showed the roots and
   the finale rows as *unavailable*, with *How is the landing now?* available;
   that gave a short post-ending line (*"Maela keeps the rope where it is. The
   landing is quiet, and she has said all she will say about Ivo. The water is
   still."*) and the objective stayed **Complete**. The finale did not replay.

Captures: `builds/qa/runs/2026-11-14_ashwick_player_view/shots/s01`-**s17**
(`s01` text scale, `s03` decision page, `s06` bell, `s07` silence,
`s10`-`s12` epilogue and completion, `s14` Journal, `s15`-`s17` repeat talk).

### Assessment answers

- **Choice understandable before commitment** — largely yes for the silence path:
  each row names the action and the outcome, the header says none of the three
  answers is free, and the narration after the choice confirms the bell stays
  empty. Two gaps: nothing warns that the token is spent for good, and *Ring twice
  for the dead.* starts a fight from a dialogue row with no hint of it.
- **Mercy and silence acknowledged consistently** — yes: the epilogue joins the
  fabricated passenger story to the broken token, the post-ending line holds both,
  and the Journal records both under the mercy side quest.
- **Directed to the required final conversation** — the direction is clear in the
  silence narration and in the bell's own resolved page, but the epilogue is not
  automatic and its row was below the fold at 160 %, so the last step needs a
  scroll. That placement is recorded as a **discoverability refinement**, not a
  blocker; the two bell-page clarity gaps above are assessment findings, not
  approved content changes.
- **Completion unmistakable** — yes: objective panel *Complete*, victory
  narration, and the *Campaign objective complete* modal.
- **Repeat interaction does not replay the finale** — yes: finale rows are gated
  closed and a short post-ending exchange replaces them.

### Limits of this pass

One outcome (mercy + silence) on one party (three adventurers, Sera included).
Ring-once, ring-twice, defeat/interruption, the page-after-mercy branch and
post-ending save/load were **not exercised in this pass**; for those the current
candidate rests on `tests/test_ashwick_second_ring.gd`. Ring-once does have
earlier native evidence, but on a different executable: the *Ordinary
exported-window route* recorded above rang once on the truth account and reached
its epilogue in `ashwick_second_ring_2026-11-14` (SHA-256 `457e3b88...`), not in
`account_decision_2026-11-14` (`022817be...`). That route was not rerun to
reconcile the two. No human playtest or balance judgement.
Per the authorization: no suite rerun, no validators, no package audit, no new
executable and no new checkpoint — so the claims stay separate: the full suite
(541/541, 6,364 assertions) passed at the previous implementation boundary, the
eight new combat-inspection assertions passed, and the broader windowed probe still
carries its five known layout failures and is not a passing probe.

## UI scaling correction — layout and the client area (2026-11-20)

*Implementation and verification record. Supersedes the 1.6x text and 1024x600
claims in `PHASE2_VERIFICATION.md`; it does not rewrite that phase's history.*

### Defect

The UI was composed in a fixed 1280x720 logical canvas and magnified to the window
(`stretch/mode="canvas_items"`, `aspect="expand"`), while the Settings text scale
enlarged only fonts. At 160 % text the exploration header overlapped the 3D view and
the newest log line was clipped, the combat right column sat outside the client at
1280x720, the dialogue panel ran past both edges, the fixed 760x540 modals clipped
their own content, the text-size readout wrapped across two lines, and fullscreen
reported a 1920x1082 client on a 1920x1080 display. Behaviour is summarized with
evidence paths in `PROGRAM_PROGRESS.md` (2026-11-20) and the assessment run in
`builds/qa/runs/2026-11-15_ui_scaling/`.

### What changed

`display/window/stretch/mode="disabled"` (client is the layout surface; 1280x720
window floor unchanged), lower shrinkable page minimums for exploration and combat,
a wrapping location title, a dialogue panel capped to the client and re-clamped on
resize, modal sizes scaled by text scale and then capped, `refresh_modal` keeping
the caller's size, a text-sized slider readout, a top margin on the character-sheet
tab page, a Settings list that clears the scrollbar, and a 1280x720 headless window
pin so CI measures the same surface a player gets.

### Verification actually run

| Check | Result |
| --- | --- |
| Full GUT suite (`--headless -s addons/gut/gut_cmdln.gd -gdir=res://tests`) | **550/550 tests, 6,403 assertions, 45 scripts, exit 0** |
| `tests/test_layout_scaling.gd` (new) | **9/9**, including "nothing escapes a 1280x720 client" for exploration and combat at 160 % |
| `--validate-campaigns` / `--validate-diagnostics` | PASS / PASS, exit 0 |
| `--layout-probe` matrix, source tree | **32/32** runs: 1280x720, 1600x900, 1920x1017 (maximized) x 100 %/160 % x exploration, combat, dialogue, Settings, inspect modal; plus fullscreen 1920x1080 at both scales |
| `--demo-inspect --inspect-probe` | **PASS** (baseline: 44 pass / 5 fail of 49; the pass run carries 53 checks because four conditional `close modal` assertions now execute — no check removed) |
| `--party-layout-probe`, `--intro-layout-probe`, `--campaign-list-probe`, `--party-limits-probe` | PASS (the first three need the `qa_list_*` fixture profile) |
| Exported candidate `ui_scaling_2026-11-20b`, SHA-256 `6d38c18d8f533a245343ae4df9731e7ae41ad27e2d7b7477c4b2c5a17435dbd7` | `--list-campaigns`, both validators, `--inspect-probe` and an 18-run windowed layout matrix (1280x720 at 100 %/160 % for all five screens, 1920x1017 at 160 %, fullscreen 1920x1080 at 100 %/160 %) — **18/18, exit 0** |

Evidence: `builds/qa/runs/2026-11-20_ui_fix/` — `layout/` (source runs, captures in
`shots/`), `accept/` (exported runs, `acceptance.log`, `shots/`), `matrix.log`.
The pre-fix baseline of the same probe is `.../probe_before/inspect.log` (5 failures).

### Limits

No human playtest; no subjective judgement of the new proportions. Keyboard input
still cannot be injected through this harness, so keyboard-only reachability rests
on construction tests. Windows display scaling other than 100 % was not exercised.
Journal raw-flag text, exploration log length and the "Recorded world events"
heading overlap are outside this correction and unchanged. The raw notes and the
heading were addressed later the same day (see "Journal notes").

### Reconciliation — the Inspect probe's failure count (2026-11-20)

Earlier records in this file and in `PROGRAM_PROGRESS.md` said the Inspect probe
kept "seven" pre-existing failures. The saved logs do not support seven; they
support **five**. Evidence, all from the same probe invocation on the pre-fix
baseline (`builds/qa/runs/2026-11-20_ui_fix/probe_before/inspect.log`):

| Figure | Value |
| --- | --- |
| `PROBE CHECK PASS` lines | 44 |
| `PROBE CHECK FAIL` lines | 5 |
| Checks emitted | 49 |
| Summary line | `PROBE RESULT FAIL scenario=inspect ... failures=5` |
| Distinct failing labels | 4 (the duelist check is asserted twice: before and after the turn) |

The five are: `control 'inspect QA Inspect Duelist' is on screen` (twice — once
before and once after the turn), `the marker is still shown at 1.6 text size`,
`the panel text stays inside the panel at 1.6`, and `the panel shows the standing
AC 16 and no marker after that turn (line: )`. Every failure has the same cause:
the duelist's `Inspect` button was laid out below the 1280x720 client, so the
sheet never opened.

The passing run emits **53** checks, all passing. The four extra ones are
`control 'close modal' is on screen` and `control 'close modal' is enabled`, each
asserted once per sheet opening: they live inside the probe's "a sheet is open"
block, which the baseline never reached. A label-level diff of the two logs shows
no other difference, so no check was removed, renamed or weakened — the fix added
executions, not latitude.

No saved artifact anywhere under `builds/` reports seven failures. The printed
count is the only reproducible figure, and the "seven" is best explained as a
double-count of the duplicated duelist label (5 + 2) in a record written from
console output rather than the log; that explanation is plausible but unproven,
so the number is corrected rather than explained away. Nothing in `tests/` was
changed for this reconciliation.
## Journal notes (2026-11-20)

*Implementation and verification record for the Journal's authored notes. The
save format is unchanged: `SAVE_VERSION` is still 1 and `Game.serialize()` was
not touched.*

### Defect

The Journal listed flags, not events: every truthy flag key with underscores
replaced by spaces, alphabetically — `ledger found`, `maela decision`,
`last page shared`, `tack room door open`. It mixed settled events with open
questions, exposed internal state (`maela_refused`, `maela_trust`), showed both
halves of a mutually exclusive pair when a save held both, and its empty-state
check watched the wrong thing (`keys.is_empty()` rather than "no true flag").
The heading looked overlapped because `[b]` on a font without a bold face is
drawn as an offset embolden pass; an isolated render of the same string with and
without `[b]` (`builds/qa/bold_probe.gd`, `builds/qa/bold_probe.png`) showed the
ghost only in the bold run, and not with the Label shadow either.

### What changed

Optional `journal.json` per campaign with `format_version`, `facts`, `questions`
and `internal`; loader and validator in `ContentDB`; `Panels.journal_notes()` as
a pure selector with authored-order conflict resolution; two rendered sections
with hidden-when-empty behaviour; headings sized and coloured instead of bold;
`--layout-scenario=journal`; 12 new tests. Authoring rules are documented in
`docs/AUTHORING_GUIDE.md`, and the package layout in `docs/CAMPAIGN_PACKAGE.md`.

### Verification actually run

| Check | Result |
| --- | --- |
| Full suite (`--headless -s addons/gut/gut_cmdln.gd -gdir=res://tests`) | **562/562 tests, 6,523 assertions, 46 scripts, exit 0** |
| `tests/test_journal_entries.gd` (new) | **12/12**: shipped notes valid, every authored flag covered, authored order, no raw ids, reveal gating, resolution, conflicts both ways, empty states, missing file, malformed notes rejected, save round trip |
| `tests/test_journal_panel.gd` (existing) | all pass; two assertions retargeted from the old flag heading to the empty-notes line, none removed |
| `--validate-campaigns` / `--validate-diagnostics` | PASS / PASS, exit 0 |
| `--layout-probe --layout-scenario=journal` | **6/6**: 1280x720, 1600x900, 1920x1017 x 100 %/160 %, 18 controls, 0 failures (`builds/qa/runs/2026-11-20_journal/matrix.log`) |
| `--demo-inspect --inspect-probe` | PASS, 53 checks, 0 failures |
| `--layout-scenario=screen` spot check, 1280x720 at 160 % | PASS (16 controls) |

Evidence: `builds/qa/runs/2026-11-20_journal/` — `suite.log`, `matrix.log`,
`inspect.log`, `shots/layout_journal_exploration_screen_*.png`.

### Findings during implementation

- The first version of the probe's body check required the RichTextLabel itself
  to fit the client. A `fit_content` label inside a ScrollContainer is meant to
  be taller than its viewport, so 1280x720 at 160 % failed on a correct layout.
  The check now bounds the scroll container and asserts expected text, which is
  what "reachable" means here; it is stricter about content and looser about the
  label's own rectangle.
- Seeding one fact was not enough to cover the second section, so the probe now
  also sets the first question's `revealed_by` flag and asserts "Still open".

### Limits

No human playtest. Notes were not proofread by a writer; they restate content
details and use past-tense second person. At 160 % a fully-earned journal scrolls
(the scroller is bounded and checked). The creator does not author `journal.json`
yet, so creator-made campaigns show the quest log alone, and the
every-flag-covered rule is a shipped-content test rather than a runtime error.
## Journal candidate acceptance — journal_2026-11-20 (2026-11-20)

Build: `builds/qa/candidates/journal_2026-11-20/RavenloftFoundationEdit.exe`,
110,662,552 bytes, SHA-256
`d3070eae4878c85884d374b83561865cf9f3f14fda2fc1d2a2174dfd4816ca79`, exported
from `3dc28ccfcba065e90191253406d1ed54af567206` with a clean worktree
(`worktree_entries=0`, preset "Windows Desktop"). Provenance is in the
candidate's `BUILD.txt`; every run used an isolated `APPDATA` and real windows,
with logs and captures under `builds/qa/runs/2026-11-20_journal_accept/`.

| Check (exported executable) | Result |
| --- | --- |
| `--list-campaigns` | ok |
| `--validate-campaigns` / `--validate-diagnostics` | PASS / PASS |
| `--demo-inspect --inspect-probe` | PASS, 53 checks, 0 failures |
| `--layout-probe --layout-scenario=journal`, 1280x720 at 100 % | PASS, 18 controls, 0 failures |
| `--layout-probe --layout-scenario=journal`, 1280x720 at 160 % | PASS, 18 controls, 0 failures |
| `--save-compat-ui-probe` | PASS: an existing save loads through the Load modal, a blocked load is refused with the area named, and the save recovers after the content is repaired |
| empty notes (fixture with `journal.json`, no earned facts) | PASS; the journal says "Nothing recorded yet." |
| missing notes file (fixture without `journal.json`) | PASS; quest log only, no notes headings |

`acceptance.log` ends with `ACCEPTANCE exe=RavenloftFoundationEdit.exe runs=7
failures=0`; the two empty-state fixture runs are logged separately in
`fixture_qa_journal_empty.log` and `fixture_qa_journal_no_file.log` and captured
in `shots_fixtures/<id>/`.

Limits: the journal was not scrolled by input — nothing in this harness injects
the wheel, so scrolling is evidenced by the scroller bounds the probe measures
and the 160 % capture showing the scrollbar, not by a scroll action. The
empty-state packages are copies of the QA user campaign `qa_list_valid_0` with
the manifest id and area tracker quest retargeted; they are fixtures, not shipped
content. `--save-compat-ui-probe` proves the save loads through the player path
but does not open the Journal afterwards, so "existing save, journal contents"
rests on the GUT round-trip test. Both journal runs are `ravenloft_demo`; Ashwick
and Hollow Lantern are covered by validation and unit tests, not rendered here.
## Exploration refusals reach the log (2026-11-20)

`GameState._refuse(text)` is now the one home for a refusal: it sets
`last_ui_message`, appends the line unless the previous log line is already
identical, and returns `{"ok": false, "message": text}` exactly as each site did
before. Eight sites route through it — a blocked step (`_step`), a closed door
(`_step`), an NPC in the way (`_step`), nothing within reach (`interact`), no
lock-picker (`_try_open_door`), a removed object and an object with nothing
usable (`_interact_object`), and no conscious adventurer (`_run_interaction`).
Return values, callers, rules, content and the save format are unchanged; the
wall description and the skill-check outcomes already logged and still do.

`tests/test_refusals.gd` (12 tests) covers each family, the consecutive
duplicate rule (repeat suppressed; a different line in between logs again), the
two-key result shape, and both input paths: the keyboard handler drops the
result, the action bar hands it to `_do()`, and neither may log a second copy.

`--layout-scenario=refusal` (`src/main.gd`) walks the party into the map edge and
then separates three things: the line in `Game.log_lines` (state), the line in
the log widget's parsed text (rendered), and the widget's rectangle inside the
client with no modal over it (on screen). It exits nonzero if any of the three
fails; the capture written after the check is the visual evidence.

Ran: full suite **574/574, 6,591 assertions, 47 scripts, exit 0**
(`builds/qa/suite_refusal.log`); `--validate-campaigns` PASS;
`--validate-diagnostics` PASS; `--demo-inspect --inspect-probe` PASS. The probe
needs `--demo-inspect`: with plain `--demo` the encounter screen is never built
and its "combat screen with an encounter exists" check fails, which is an
invocation difference, not a regression.
Candidate `refusals_2026-11-20` repeats the checks in the export
(`builds/qa/candidates/refusals_2026-11-20/RavenloftFoundationEdit.exe`,
110,662,808 bytes, SHA-256
`06883c8254ed8cf2411ae7174adb847b4ca0f7818a2b45903a2b6ccd1ef29d7d`, source
`c3ede47`): both validators PASS, `--demo-inspect --inspect-probe` PASS, and
`--layout-scenario=refusal` PASS at 1280x720 on 100 % and 160 % (17 controls, 0
failures each; logs in `builds/qa/runs/2026-11-20_refusals/`). The exported
captures in `shots_export/` show "Cold stone blocks the way." as the newest,
readable line of the narration log at both scales.

Limits of that check: the scenario calls `Game.move_forward()` and refreshes,
which is what the keyboard handler does, but it does not inject a real key
event, so the key binding itself rests on the existing input tests rather than
this capture. "On screen" is established by the widget's rectangle inside the
client, no modal over it, a nonzero visible-line count and the capture; there is
no per-pixel occlusion test. Only the wall refusal is exercised in the export —
the other seven families are covered by the suite. The export needs export
templates in its `APPDATA`; unsetting the variable makes Godot look in
`./Godot` inside the project, so the build used an isolated profile holding a
copy of the templates.
## Native interaction verification (2026-11-20)

**The untracked `.uid` did not affect the candidate.** `tests/test_refusals.gd.uid`
was untracked when `refusals_2026-11-20` was exported, but the preset's
`exclude_filter` lists `tests/*`, the exported executable contains no occurrence
of `test_refusals` or `test_journal_entries`, and a `.gd.uid` is only a `uid://`
alias for a script the game never loads. It was committed afterwards as
`b203a1d`; the candidate's recorded provenance (`BUILD.txt`) already said its
only worktree entry was that file.

**Method.** `tools/native_input.ps1` launches the exported candidate, raises it
to topmost, focuses it with a real click, then sends OS-level input —
`keybd_event` with scan codes and `mouse_event` wheel/clicks — capturing the
client area after each step. This is the same path a player's hardware takes;
the earlier probes called game functions directly.

**Results at 1280x720** (`builds/qa/runs/2026-11-20_native/`):

| Check | 100 % | 160 % |
| --- | --- | --- |
| Move with a real W key | PASS: 5,10 -> 1,10 | PASS: 5,10 -> 1,10 |
| Blocked move explains itself | PASS: one "Cold stone blocks the way." after four blocked steps | PASS: same, one line |
| Interact with a real F key | PASS: interaction lines append | PASS: same |
| Mouse wheel over the narration log | PASS: scrolled to older lines, then back | PASS: dedicated run scrolled to older content and back |
| Mouse wheel over the Journal body | **NOT VERIFIED** | **NOT VERIFIED** |
| Tab traversal | PASS: focus ring walks the action buttons | PASS: same |
| Enter activates the focused control | PASS: Interact ran | PASS: Strafe left ran and logged its refusal |
| Journal Close by mouse | PASS | PASS |
| Journal Close by Enter (default focus) | PASS | PASS |

**Manual step for the one unverified check.** The demo Journal holds one quest
and "Nothing recorded yet.", which fits its modal at both scales, so a wheel
turn has nothing to scroll. To verify: play until the Journal holds more than a
screen of notes (or add entries to a campaign's `journal.json`), run
`RavenloftFoundationEdit.exe -- --demo --text-scale=1.0`, press J, hover the
notes area and turn the wheel; the body should scroll and the scrollbar thumb
move. Repeat with `--text-scale=1.6`.

### Defects found (pre-existing, not caused by refusal logging)

1. **An open modal does not trap Tab.** Open the Journal (J), press Tab twice:
   focus lands on "Turn left (Q)" behind the modal (visible at 100 %; hidden
   under the near-fullscreen modal at 160 %). Enter then turns the party
   (West -> South) while the Journal is still open. Confirm by closing the
   modal: the status line reads "Facing South" and the focus ring sits on
   "Turn left (Q)". Evidence: `t100/focus_modal/02_tab2.png`,
   `t100/focus_modal/04_enter.png`, `t100/trap/02_after.png`,
   `t160/trap/02_after.png`. The modal only calls `close.grab_focus()`
   (`src/main.gd:6641`); no control owns Tab while it is open.
2. **Closing a modal leaves no visible focus.** After Close (by mouse or
   Escape) no control shows a focus ring until Tab is pressed again. Minor;
   evidence `t100/seq/09_close_click.png`, `t160/focus/04_close_click.png`.

## Modal focus containment and restoration (2026-11-20)

**Fixed** (`e9a5086`, then `b5dfd9b` for the Shift+Tab direction):
`open_modal` records the control that had focus, `_input` routes Tab and
Shift+Tab to `_cycle_modal_focus` (modal controls only, wrapping at both ends,
scroll bodies skipped), activation is swallowed when focus is not inside the
modal, and `close_modal` returns focus to the opener or to the screen's first
usable control. A refresh, or a modal opened from another modal, keeps the
original opener. The rebind capture still consumes its key before the trap.

**Tests**: `tests/test_modal_focus.gd` (12) covers opening focus, Tab and
Shift+Tab containment across six stops, both wraps, a Shift+Tab event routed
backwards, the reported Tab-twice/Enter sequence, world keys while a modal is
open, restore to the opener, fallback after the opener is gone, refresh keeping
the opener, Escape, and rebind priority. `tests/test_modal_layout.gd` now
asserts where focus is restored to instead of that it is released.

**Ran**: full suite **586/586 tests, 6,640 assertions, 48 scripts, exit 0**
(`builds/qa/suite_modal3.log`). Exported candidate `modal_focus_2026-11-20`
(110,665,048 bytes, SHA-256
`fe7511b335be0b56c6dee93a56f9225798f23c4b93ac7214b2eab706a986e368`, source
`b5dfd9b`): `--list-campaigns`, both validators, `--demo-inspect --inspect-probe`,
the journal layout scenario at 100 % and 160 %, the refusal scenario at 100 %
and 160 %, and `--save-compat-ui-probe` — **9/9 runs, 0 failures**
(`builds/qa/runs/2026-11-20_modal/export/`).

**Native input at 1280x720** (`tools/native_input.ps1`, OS-level keys, wheel and
clicks against the candidate):

| Check | 100 % | 160 % |
| --- | --- | --- |
| Tab twice with the Journal open | ring stays on Close | same |
| Tab three times in Paused | Close -> Resume -> Save -> Load, all inside | (same at 100 %) |
| Tab twice then Enter (the reported sequence) | Journal closes; the world stays 5,10 facing West | same |
| Close by mouse | modal closes | modal closes |
| Focus after closing | visible ring on Pause | visible ring on Pause |
| Wheel over an overflowing Journal | questions 09-18, then back to the top | questions 06-13, then back |

The overflow is a **user** fixture under the run's isolated `APPDATA`
(`qa_journal_overflow`: 70 questions with no `revealed_by`), built from the
earlier empty-notes fixture with its manifest id and `content_root` retargeted;
shipped content is untouched. Wheel up at the top is a no-op, which is why the
scroll-down turn carries the evidence.

**Shift+Tab is verified natively (corrected 2026-11-20).** This paragraph used
to say the harness could not inject a Shift chord, so the backward cycle rested
on unit tests and a manual step. That was wrong: the failure was the Tab
action-matching bug fixed in `b5dfd9b`, not the injection path. On the fixed
candidate one Shift+Tab on Pause moves the ring Close -> Return to main menu
and the next walks back to Settings, at 100 % and 160 %. The manual step is
withdrawn. Enter activating a focused button is still native-verified only:
headless GUI key activation does not fire in the harness, so no unit test
covers that half.

## Assessment: keyboard access to scrollable modal text (2026-11-20; implemented the same day, below)

**Measured.** The shared modal builds one body `ScrollContainer`
(`content_scroll` in `open_modal`) whose `focus_mode` is `FOCUS_NONE` and whose
vertical bar reached 1616 px against a 293 px page in a 60-line fixture;
`scroll_vertical` is writable and the wheel moves it (fixture runs at 100 % and
160 %). Keyboard cannot: `_modal_focusables()` skips `ScrollContainer`, and the
container is not focusable in the first place.

**Verified at 160 % with the 70-question Journal** (`--campaign=qa_journal_overflow`):
three PageDown presses and six Down presses left the text at questions 01-04 —
identical frames. One Down also removed the focus ring from Close and nothing
else became ringed; Enter then did nothing and the world was unchanged after
Escape (position 4,4 facing North). So arrows neither scroll nor keep focus
visible; in that run they did not reach an actionable background control either.

**Shift+Tab is now verified natively** at 100 % and 160 %: with Pause open, one
Shift+Tab wraps Close -> Return to main menu, the next walks back to Settings.
The earlier "harness cannot inject Shift" note is withdrawn: that failure was
the action-matching bug fixed in `b5dfd9b`, not the injection path. No manual
step is needed for it any more.

### Smallest proposed fix (as proposed; implemented in the section below)

1. Keep a `modal_scroll` reference to the `content_scroll` created in
   `open_modal`, and clear it in `close_modal`.
2. In `_input`, after the rebind branch and before the Tab branch, while a modal
   is open:
   - `ui_page_down` / `ui_page_up` scroll the body by about 90 % of a page;
   - `ui_down` / `ui_up` scroll it by two lines.
   Mark the event handled and return.
3. A helper (`_scroll_modal_body(event)`) adjusts
   `modal_scroll.scroll_vertical`; the container clamps at both ends, so a body
   that fits does not move. Arrow keys stop reaching Godot's focus traversal as
   a side effect, which closes the ring-loss above.

New scrolling keys, then: **PageDown/PageUp = one page, Down/Up = two lines**,
wheel unchanged, Home/End and a Tab stop on the body deliberately left out.

Why it keeps the existing guarantees: focus is never moved (containment and
visible focus untouched, no theme change, no new stop); Enter and Space are not
intercepted (activation unchanged); the rebind branch stays first (capture
unchanged); Escape is handled after it exactly as now.

### Tests defined for the fix (as defined; results in the section below)

- Unit, `tests/test_modal_focus.gd`: a tall modal scrolls about a page per
  PageDown and back with PageUp, two lines per arrow, clamps at top and bottom,
  keeps the same focus owner throughout, still cycles with Tab, still closes
  with Enter on Close, still restores focus on Escape, and still lets a rebind
  capture win; a modal whose content fits stays at 0.
- Native, fixture campaign: at 100 % and 160 %, PageDown reveals later
  questions, PageUp returns, arrows move by lines, the Close ring stays put, and
  Tab/Enter behave as they do today.

### Assumptions to hold the tests to

- `ScrollContainer` clamps `scroll_vertical` at its bounds; that is standard
  container behaviour and was not separately measured (writing a value inside
  the range was).
- The arrow-key focus loss is inferred from a missing ring plus an inert Enter;
  the harness cannot read which control holds focus, and at 160 % the dimmed
  background hides a ring drawn under the modal.

## Keyboard scrolling of modal text (implemented 2026-11-20)

The shared modal now scrolls its own text from the keyboard. `open_modal` keeps
a `modal_scroll` reference to the body it builds and `close_modal` drops it;
`_input` calls `_scroll_modal_body()` after the rebind branch and before the Tab
branch, so a rebind capture still wins and a scroll key never reaches Godot's
focus traversal.

**Keys (documented in the README).** PageDown/PageUp move by 90 % of the visible
page, so a sliver of the previous text stays as context. Up/Down move by two
rendered text lines, with the line height read from the theme's default font;
`ThemeBuilder.fs()` derives that size from the text setting, so the same press
moves 44 px at 100 % text and about 70 px at 160 % instead of crawling. One
press moves once: held-key echo is filtered for every modal key, this one
included. Home/End stay unbound, and the body is still not a Tab stop.

**Keys a focused control needs stay with it.** While focus sits in a `LineEdit`,
`TextEdit`, `SpinBox`, a `VSlider`, `ItemList`, `Tree` - or a child of one -
Up/Down are left alone. `HSlider` and `TabBar` no longer keep them; both act on
Left/Right and their Up/Down did nothing but hand the ring to Godot's traversal,
so they scroll now (see "Pane selection and slider arrows" below).
PageUp/PageDown are only yielded to a `TextEdit`, which pages its own caret. A popup opened from a modal takes focus into its own
window, and then nothing in the body is intercepted. Every other control (a
Button, a CheckBox, a prose body) has no use for those keys, so they scroll.

**Nested bodies are the Journal's real shape.** `Panels.journal()` wraps its text
in a `ScrollContainer` of its own, so the shared body fits exactly and cannot
travel. The first version of this fix therefore did nothing at all in the Journal,
and the frames proved it (six captures, byte-identical). Measured on the real
Journal: the shared body reports `max 420 / page 420` (travel 0) while its inner
body reports `max 3414 / page 453` (travel 2961). `_modal_body_target()`
picks the visible pane with the most vertical travel (the shared body on a tie),
so the keys move the text the player can see; the rule and its limits are
recorded in "Pane selection and slider arrows" below. A body
that fits everywhere still does not move; the key is consumed anyway so an arrow
cannot fall through to focus traversal and take the ring off the modal.

**Tests.** `tests/test_modal_focus.gd` gained 13 cases: a page step of 90 % and
its return, exactly two lines per arrow, the step growing with the text scale,
clamping at both bounds, a fitting body staying at 0, focus containment and the
same focus owner after scrolling, Escape still restoring the opener, the rebind
capture still winning, a focused text field keeping Down but not PageDown, a
focused list keeping Down and moving its own selection, the helper refusing
keys it does not own, no body reference after closing, and the nested-body case
above. Suite **599/599, 6,690 assertions, 48 scripts, exit 0**; the two
validators and the Inspect probe pass in source.

**Native, exported candidate** `modal_scroll_2026-11-20`
(110,667,352 bytes, SHA-256 `0c2f982e`), 70-question Journal fixture, one window
per scale, OS-level keys:

| Step | 100 % | 160 % |
| --- | --- | --- |
| Open Journal | questions 01-04, ring on Close | questions 01-04, ring on Close |
| PageDown | questions 06-15 | questions 04-11 |
| PageDown x2 more | later questions, thumb moves down | later questions |
| PageUp x3 | back to questions 01-04, frame identical to the opening one | same |
| Down x3 (six lines) | text moves by a small step | visible step, smaller than a page |
| Up x3 | frame identical to the opening one again | same |
| Escape | Journal closes, world frame equals the earlier run's | same |

The ring stayed on Close in every frame; no arrow removed it. Captures are in
`builds/qa/runs/2026-11-20_scrollfix/native/t1.0` and `t1.6`.

**Export acceptance:** 9/9 (three validators, the Inspect probe, the journal and
refusal layouts at 100 % and 160 %, and the existing-save load path). The
per-check logs are in `builds/qa/runs/2026-11-20_scrollfix/`; no consolidated
`acceptance.log` was written for this run - see "Candidate audit" below.

**Limits and what is not covered.** The harness cannot read the focus owner, so
focus retention rests on the ring staying on Close plus the unit assertions; the
ring is also the only evidence that a focused field or list kept its keys in the
native runs (the unit tests assert those two). Holding a key does not repeat.
Gamepad page keys are not handled - only keyboard events are. The arrow-owning
list is maintained by hand: `OptionButton` is deliberately not on it (it opens on
Enter/Space), so arrows scroll the body while one has focus. With several
scrollable children the pane with the most travel wins (see below); a modal with
two independently scrolling panes would still scroll only one. The wheel is untouched, and its behaviour is still evidenced by
the earlier fixture run rather than repeated here.

## Pane selection and slider arrows (2026-11-20)

The scrolling unit shipped with two gaps, both reproduced before this change.
Settings at 100 % text scrolled its wrapper (27 px of travel) instead of the list
inside it (463 px), so six PageDowns stopped at 27 px and 94 % of the dialog was
unreachable; and Up/Down on a focused `HSlider` or on the party sheet's tab strip
did not scroll at all - they ran Godot's focus traversal instead, taking the ring
from a volume slider to the Fullscreen check box at 100 % and to the "D" rebind
button at 160 %, which also contradicted the rule that arrows scroll and never
move focus.

**Pane rule (new).** `_modal_body_target()` returns the visible pane with the
greatest vertical travel, and the shared body on a tie. Invisible panes are
skipped because a pane that was never laid out reports `page = 0` and therefore a
huge, meaningless travel (a hidden character-sheet tab reported 21,643 px; an
unfiltered rule picked it). Ties keep the shared body, so a plain dialog still
scrolls itself and a long prose body with a short nested list keeps the body
(measured 527 px versus 0 px). Measured targets after the change: Settings
463 px (100 %) and 679 px (160 %), party sheet 402 px, inventory 744 px, Journal
inner body 2,961 px, Save/Load/Pause/Training 0, Create campaign 14, combat
potions 7, combat inspect 517.

**Arrow rule (changed).** `HSlider` and `TabBar` left the exemption list: both act
on Left/Right (Right moved the music slider 55 % -> 70 %, switched the party tab
0 -> 1), and in Godot 4.7 their Up/Down is unhandled by the control, so holding
them only let traversal take the focus. From either one Up/Down now scroll the
body and the ring stays put. `VSlider` (measured 0.50 -> 0.45 on Down), `SpinBox`,
`LineEdit`, `TextEdit`, `ItemList` and `Tree` keep the keys.

**Tests.** Five cases added to `tests/test_modal_focus.gd`: a wrapper whose list
travels further scrolls that list to its end while the wrapper stays at 0; a long
body with a short inner list keeps the body; a focused horizontal slider scrolls
the body by exactly two lines, keeps focus and still changes value on Right
without scrolling; a focused tab bar scrolls on Down, keeps its tab and still
switches tabs on Right; a focused vertical slider consumes the arrows and the body
does not move. Suite **604/604, 6,720 assertions, 48 scripts, exit 0**; both
validators and the Inspect probe pass in source.

**Headless measurement on the real modal** (`probe_modal_matrix.gd`): Settings at
100 % now reports `outer=27 target=INNER(463)` with six PageDowns reaching 463 and
`unreachable=0` (before: `target=OUTER`, reaching 27); at 160 % `INNER(679)`.
Every volume and text-size slider keeps focus through Down at both scales
(`focus HSlider->HSlider`, value unchanged), and the Settings confirmation dialog
still leaves the body at 0 with focus on Close.

**Native, exported candidate** `modal_pane_2026-11-20` (110,667,640 bytes,
SHA-256 `6217fe39`), 1280x720, Settings opened from Pause (`Esc`, `Tab` x4,
`Enter`), OS-level keys:

| Step | 100 % | 160 % |
| --- | --- | --- |
| PageDown x4 | last rebind row ("Pause - Escape") and "Restore Default Controls" visible | same |
| PageDown x2 more | frame byte-identical (clamped at the end) | same |
| PageUp x6 | frame byte-identical to the opening one | same |
| Focus Music slider, Right x3 | 55 % -> 70 %, ring stays on the slider | same |
| Down x1, then x2 | list steps down two lines, then two more; ring still on the slider | same |
| Up x3 | frame byte-identical to the post-Right frame | same |
| Party sheet tab strip, Right | second tab (Sera Vane), ring on the strip | - |
| Down x2, Up x2 | text scrolls four lines, then returns byte-identically | - |

Captures: `builds/qa/runs/2026-11-20_scrollfix/native/pane1.0` and `pane1.6`
(PageDown reach), `slider2_1.0` and `slider2_1.6` (slider), `party10` (tab strip).

**Export acceptance:** 11/11 - list-campaigns, both validators, the Inspect probe,
the settings, journal and refusal layouts at 100 % and 160 %, and the
existing-save load path; per-check logs in `builds/qa/runs/2026-11-20_panefix/`
(no consolidated `acceptance.log` - see "Candidate audit" below).

### Limits (measured, not fixed here)

- **The wrapper clipped its last 27 px at 100 %** and **inner panel lists did not
  follow focus** - both measured here and **fixed later the same day**; see
  "Settings clipping and focus reveal" at the end of this report.
- **One pane per scroll.** The rule chooses a single pane; a modal with two
  independently scrolling panes would still move only the one with more travel.
- **`SpinBox` stays exempt** as a conservative default even though Godot 4.7
  ignores Up/Down for it (measured: value unchanged, focus lost). No shipped modal
  contains one - it appears only on the creator screen.
- **Popups and `OptionButton`** behave as recorded in the assessment: a
  confirmation dialog keeps the keys with the body at 0, an `OptionButton` opens
  on Enter and ignores Down, and no modal contains one.
- Gamepad page keys are still unhandled, and holding a key still does not repeat.

## Settings clipping and focus reveal (2026-11-20)

The two limits recorded above are fixed. Neither was cosmetic: the first cut the
bottom of the last Settings row, and the second let Tab move the ring onto a
control the player could not see.

**The content minimum.** `Panels.settings()` gave its content root a 720x480
`custom_minimum_size`. The modal body is 453 px tall at 100 % text, so the shared
body overflowed by 27 px - and since both the keys and the wheel moved the 463 px
list inside, that strip never scrolled: the list sat at its end while its bottom
27 px, including most of the "Restore Default Controls" button, stayed clipped.
The minimum is now `Vector2(720, 0)`: the width still keeps the columns apart, the
panel keeps the size the modal asks for, and the body simply fits. Measured after:
shared body travel **0** (was 27) and the list travels **490** px (was 463) at
100 %, **679** at 160 %; PageDown reaches the end with nothing left unreachable.

**Revealing the focused control.** Only the shared body had `follow_focus`, and
that flag can only ever move the body - which, holding a list that clips its own
rows, moved nothing useful. `_reveal_modal_focus()` now walks from the focus owner
up to the modal and adjusts every `ScrollContainer` on the way, innermost first.
Each wrapper is asked to show the *pane inside it* rather than the deep control:
that is what the player can see, and it keeps every step independent of the
others' scroll offsets. A control taller than its pane is aligned to the pane's
top; each step is clamped to that pane's own travel; an 8 px pad keeps a focus
ring off the clip edge. The walk stops at a popup `Window`, so a dialog raised from
the modal keeps its own geometry and the body behind it does not move. The hook is
the viewport's `gui_focus_changed`, so it covers Tab, Shift+Tab, clicks, a refresh
and a control grabbing focus itself - not just the Tab helper.

Measured on the real Settings at 100 %: Tab x18 focuses "Restore Default Controls",
the list scrolls to 490 and the row sits at y = 580 inside the body's 163-616 -
visible, where it used to sit at y = 1043 outside it. `Enter` still opens the
confirmation dialog and leaves the list where it was.

**Tests.** Four cases added to `tests/test_modal_focus.gd`: the real Settings body
no longer overflows and PageDown leaves the Restore button fully inside the list;
Tab reaches that last row at 100 % and 160 % with the row fully visible and
Shift+Tab walking back to a visible row; a synthetic modal whose button sits at the
bottom of a nested list has it revealed by Tab, then the nested list returns to 0
on Shift+Tab with the wrapper untouched and focus still inside the modal; and a
confirmation popup leaves the list at its offset and the modal open. Suite
**608/608, 6,767 assertions, 48 scripts, exit 0**; both validators and the Inspect
probe pass in source.

**Native, exported candidate** `modal_focus_2026-11-20` (110,668,280 bytes,
SHA-256 `42b003c9`), 1280x720, Settings opened from Pause, OS-level keys:

| Step | 100 % | 160 % |
| --- | --- | --- |
| PageDown x4 | last row and the whole Restore button visible, no clipped edge | same |
| PageUp x6 | frame byte-identical to the opening one | same |
| Tab x18 | ring on "Restore Default Controls", list at its end, row whole | same |
| Shift+Tab x1 | ring on the "Pause - Escape" row above it, list one step up | same |
| Tab x1 | frame byte-identical to the Tab x18 frame | same |
| Enter, Escape | confirmation opens over the untouched list; Escape closes only the dialog, frame identical again | same |

Captures: `builds/qa/runs/2026-11-20_focusfix/native/focus1.0` and `focus1.6`.

**Export acceptance:** 11/11 (list-campaigns, both validators, the Inspect probe,
settings/journal/refusal layouts at 100 % and 160 %, save-compat UI); per-check
logs in `builds/qa/runs/2026-11-20_focusfix/` (no consolidated `acceptance.log` -
see "Candidate audit" below).

### Remaining limits

- **Reveal is modal-only.** `_reveal_modal_focus` runs while a modal is open; the
  campaign creator screen and other non-modal screens keep their own scrolling
  (the creator uses `ensure_control_visible` directly).
- **A control taller than its pane is aligned to the top**, so its bottom can
  still be clipped - no shipped control is that tall, but a wrapped paragraph in
  a short pane would be.
- **One pane scrolls per key press.** The greatest-travel rule still moves a
  single pane; with two independently scrolling panes the other one does not
  follow the focus.
- **`follow_focus` stays on the shared body** (a layout test asserts it). Where a
  wrapper can travel, the engine may nudge it in the same frame we set the inner
  list; the measured results are identical, but the wrapper is the redundant half.
- **No key repeat**, gamepad page keys remain unhandled, and the reveal does not
  run again if a pane's content is re-laid out while the focus owner is unchanged.

## Candidate audit and migration readiness (2026-11-20)

**No candidate replaced another.** Three builds coexist under
`builds/qa/candidates/`, each in its own directory with its own `BUILD.txt`;
nothing was overwritten or deleted, and every on-disk hash matches its record.
Re-hashing the three executables reproduces `BUILD.txt` exactly.

| Candidate | built_at | source_head | dirty entries | exe bytes | exe_sha256 (8) | on disk |
| --- | --- | --- | --- | --- | --- | --- |
| modal_scroll_2026-11-20 | 17:46:48 | 2b3ba36 | 2 | 110,667,352 | 0c2f982e | matches |
| modal_pane_2026-11-20 | 18:03:47 | 1d89925 | 2 | 110,667,640 | 6217fe39 | matches |
| modal_focus_2026-11-20 | 18:18:04 | 60c1221 | 3 | 110,668,280 | 42b003c9 | matches |

The three `worktree_diff_sha256` values are different (`d5ace748`, `3842d180`,
`cdd57a78`), so the binaries are three distinct source states, not twins: each was
exported from its unit's uncommitted work, and that work becomes the `source_head`
of the next candidate. `modal_focus_2026-11-20` is therefore the *newest* build,
not a relabelled `modal_pane_2026-11-20`.

**Which result supports which build.**

| Evidence | Build | Location note |
| --- | --- | --- |
| acceptance run, 9/9 | modal_scroll `0c2f982e` | `runs/2026-11-20_scrollfix/`, script names the exe |
| native `t1.0`, `t1.6` (Journal) | modal_scroll `0c2f982e` | `runs/2026-11-20_scrollfix/native/` |
| acceptance run, 11/11 | modal_pane `6217fe39` | `runs/2026-11-20_panefix/`, script names the exe |
| native `settings10` (defect reproduction, 17:57) | modal_scroll `0c2f982e` | captured before the pane export |
| native `pane1.0`, `pane1.6`, `slider1.0`, `slider1.6`, `slider2_1.0`, `slider2_1.6`, `party10`, `reach10` (18:04-18:07) | modal_pane `6217fe39` | stored under `runs/2026-11-20_scrollfix/native/` |
| native `source_t1.0`, `source2_t1.0` | source tree, **no binary** | named for the source run |
| acceptance run, 11/11 | modal_focus `42b003c9` | `runs/2026-11-20_focusfix/`, script names the exe |
| native `focus1.0`, `focus1.6` | modal_focus `42b003c9` | stored under `runs/2026-11-20_panefix/native/` |
| `suite.log` in the run directories | source tree, **no binary** | GUT always runs from source |
| `probe.log`, matrix output | source tree, **no binary** | headless probes |

The harness does not embed the executable hash in a frame, so these attributions
rest on the `BUILD.txt` timestamps above, each run script's `EXE=` path, and the
first-frame mtimes: 17:46/17:47 for modal_scroll, 17:57 for the pre-fix
reproduction, 18:04-18:07 for modal_pane, 18:19-18:20 for modal_focus.
`runs/2026-11-20_scrollfix/native/appdata` is a reused profile, not evidence.

**Missing or misplaced artifacts (recorded, not repaired).**

- **No `acceptance.log` exists for any of the three runs.** The scripts print their
  summary to the terminal and write per-check logs only (`list.log`,
  `validate_campaigns.log`, `validate_diagnostics.log`, `inspect.log`,
  `journal_t1.*.log`, `refusal_t1.*.log`, `settings_t1.*.log`, `save_ui.log`,
  `shots/`). The three sections above cited `acceptance.log`; that citation was
  wrong and is corrected. By contrast,
  `runs/2026-11-20_journal_accept/acceptance.log` and
  `runs/2026-11-20_ui_fix/acceptance.log` exist, so the consolidated log is an
  earlier script's behaviour that this one dropped.
- **`candidates/modal_focus_2026-11-20/export.log` is stale.** Its mtime (16:48)
  predates that candidate's `BUILD.txt` and exe (18:18) and it carries no build id,
  so it cannot be the log of that export. `BUILD.txt` plus the matching on-disk
  hash are the authority. The other two candidate directories contain no export
  log at all.
- **Native frames are one run directory behind.** The pane unit wrote its frames
  under `2026-11-20_scrollfix/native/` and the focus unit under
  `2026-11-20_panefix/native/`, while their acceptance logs sit in `panefix/` and
  `focusfix/`. The frames are internally consistent with the hashes quoted above;
  they are just not colocated with the run that cites them.

**Status: closed UI defects.**

| Defect | Closed by | Evidence on the named build |
| --- | --- | --- |
| Settings list unreachable (27 px wrapper pan) | `60c1221` | modal_pane `6217fe39`: probe `INNER(463)`, native `pane1.0` |
| Up/Down from `HSlider`/`TabBar` ran traversal | `60c1221` | modal_pane: probe focus stays, native `slider2_*`, `party10` |
| Settings' last 27 px clipped at 100 % | `01ced3a` | modal_focus `42b003c9`: native `focus1.0/01_bottom` |
| Focus landing on a row below the fold | `01ced3a` | modal_focus: native `focus1.0/03_restore_focus`, Tab x18 |

**Status: remaining limits** (unchanged by this audit, all recorded earlier).

- Reveal runs only while a modal is open; the campaign creator keeps its own path.
- A control taller than its pane aligns to the pane's top, so its bottom can clip.
- One pane follows the focus per key press; two scrolling panes move only one.
- `follow_focus` remains on the shared body beside the reveal walk (redundant half).
- No key repeat; gamepad page keys unhandled; no reveal after a silent relayout.
- Save and settings have version refusal only, and these three runs have no
  consolidated acceptance log (see below).

**Migration readiness (assessment only; nothing implemented).**

- **Saves.** `SaveSystem` writes `save_version = 1` and `read_save` refuses any
  other value before validating, with a message naming the found version; a
  migrated path does not exist. `GameSession.load_game` additionally refuses a
  `content_version` that differs from the installed campaign, and it validates
  party ids, equipment and inventory items against content, dungeon/quest/flag
  shapes, numeric fields, facing 0-3, and every saved area id before touching live
  state. Writes are atomic (temp file, `.bak` restore on failure), but the `.bak`
  is never read, so a crash between the two renames leaves an unread backup.
- **Settings.** `user://settings.cfg` is a `ConfigFile` with `audio`, `display` and
  `input` sections, no version key, and a tolerant read (missing keys default).
  `save_settings` rebuilds a fresh `ConfigFile`, so unknown sections written by a
  newer build would be dropped, and `load_settings` does not clamp `text_scale`
  (the setter clamps to 0.8-1.6, the file path does not). Keybind entries are only
  applied when `InputMap.has_action` passes, so removed actions linger harmlessly.
- **Roadmap.** P0 item 4 already asks for "a schema migration hook before the first
  public content update; keep the version refusal until then", and the debt list
  records "no save migration beyond version refusal" and "settings persistence
  path/versioning is minimal". The smallest design that satisfies it - a read-only
  migration table, a version floor, a settings `meta` section that merges instead
  of rewriting, and one fixture per step - is written out in ROADMAP.md under that
  item, marked proposed and not implemented. `content_version` stays a refusal:
  a save names ids that only the campaign author can re-map.

## Provenance resolution and migration foundation (2026-11-20)

**The earlier `modal_focus_2026-11-20` binary with hash prefix `fe7511b3` is
missing.** Two records describe it: the modal-focus section above
(110,665,048 bytes, SHA-256
`fe7511b335be0b56c6dee93a56f9225798f23c4b93ac7214b2eab706a986e368`, source
`b5dfd9b`) and `builds/qa/runs/2026-11-20_modal/report.md`. No file in this
workspace hashes to that prefix: every `.exe` under `builds/` was re-hashed (36
files, including the Godot export templates), and
`builds/qa/runs/2026-11-20_modal/export/` holds logs and a profile only. The
candidate directory was **reused**: the 18:18 export wrote `42b003c9` into
`candidates/modal_focus_2026-11-20/`, overwriting that earlier exe, and the
stale `export.log` (16:48) is the surviving trace. Candidate-name reuse is
therefore confirmed rather than suspected, and the earlier artifact is
unrecoverable from this workspace - its results stay documented but cannot be
re-verified. Nothing was deleted or renamed in this audit.

**Save migration foundation (no version bump, no production step).**

- `src/core/save_migrations.gd`: an ordered table of pure `Dictionary ->
  Dictionary` steps keyed by the version they upgrade from, `SUPPORTED_MIN_VERSION
  = 1`, and a copy-on-entry `upgrade(data, from, target)` that returns `null` when
  a step is missing, a step returns null, or the file is newer than the target.
  `steps` is empty in production and `target_override` is 0, so the target is
  `SaveSystem.SAVE_VERSION` (still **1**).
- `SaveSystem.read_save` upgrades a payload in memory or keeps the exact refusal
  message it had before (now with `reason: "unsupported_version"` and a
  `migrated_from` field on success). It never writes: a migrated save is written
  only when the player saves again, so a refusal or an interrupted load cannot
  rewrite player data.
- Tests use synthetic steps only: 1 -> 2 -> 3 chains, unknown fields preserved,
  missing step, null step, caller payload never mutated, a version below the floor
  refused even with a step registered, and a newer version refused.

**Settings versioning and write policy.**

- `settings.cfg` now records `[meta] version = 1`. A file without the section is
  version 1 (everything written before this change). Volumes clamp to 0-1,
  `text_scale` to 0.8-1.6 (the slider's own range), and a flag accepts `true`,
  `yes`, `1`, `on` or a number instead of erroring on `bool("yes")`.
- `save_settings` merges into the file it loaded, so unknown sections and keys
  from another build survive, and it derives only the known keys.
- **Newer-file policy, defined before any write:** if the file's version exceeds
  `SETTINGS_VERSION`, its values are still read and clamped and changes still
  apply in memory, but `save_settings` refuses to write (`settings_newer`), so the
  newer build's file is never damaged. Tests cover the flag, the unread-write and
  the unchanged bytes.
- Unknown keybind actions are kept in settings (so a later build can use them) and
  applied only when `InputMap.has_action` passes. `Game.settings_path` is
  redirectable so tests never touch a player's file.

**Tests.** `tests/test_save_migrations.gd` (9 cases) and
`tests/test_settings_migration.gd` (6 cases) join the suite: **623/623, 6,842
assertions, 50 scripts, exit 0**. Failure paths asserted: unsupported and newer
versions, below-floor versions, a missing step, a refusing step, the caller's
payload unchanged, the save file byte-identical with no `.tmp`/`.bak` left, live
gold/position/area/party untouched after a refused `load_game`, and a synthetic
upgrade reaching live state without rewriting the file. Settings: defaults on a
missing file, clamps, unknown section/key survival, newer-file read-only, legacy
versionless file upgraded on the next write, and unknown binding preservation.

**Checks run in source:** `--validate-campaigns` PASS, `--validate-diagnostics`
PASS, `--demo-inspect --inspect-probe` PASS, `--save-compat-ui-probe` PASS (all
eight compat checks, including "refusal leaves the save bytes untouched").

**Exported candidate from the clean tree.** `migration_2026-11-20` was built at
2026-11-20T18:43:43-05:00 from commit `93e8199` with `worktree_entries=0`,
`untracked_files=0`, and both diff hashes `e3b0c442...` (the SHA-256 of empty
input), so the binary is bound to a committed tree rather than to dirty edits.

| field | value |
| --- | --- |
| build_id | `migration_2026-11-20` |
| built_at | 2026-11-20T18:43:43-05:00 |
| source_head | `93e8199df4e9a2f027ab208481240471b98e6ad2` |
| worktree_entries | 0 |
| untracked_files | 0 |
| exe_bytes | 110,670,872 |
| exe_sha256 | `00136308f9a3237504daa89da37db782105b75b3289b2baea08dd0378dbada71` |

Acceptance against that hash: **11/11** - list-campaigns, both validators, the
Inspect probe, the settings/journal/refusal layouts at 100 % and 160 %, and
`--save-compat-ui-probe`. This run writes the consolidated log the earlier three
did not: `builds/qa/runs/2026-11-20_migration/acceptance.log` records the exe hash
at its start and its end line repeats
`sha256=00136308f9a3237504daa89da37db782105b75b3289b2baea08dd0378dbada71` with
`runs=11 failures=0`; per-check logs are in its `export/`, captures in `shots/`.
Re-hashing the candidate reproduces that value, so the evidence is hash-bound to
the binary that produced it.

## Save recovery and the read-only Settings notice (2026-11-20)

**The gap.** `write_save` staged a `.tmp`, moved the primary to `.bak`, renamed
the temp into place and then deleted `.bak`. A process that died between those
renames left a valid backup or temp that no load ever read: `read_save` only
looked at the primary, `exists`/`list_saves` reported the slot empty, and the next
save deleted the crash's `.bak` before staging its own. A settings file written by
a newer build refused writes silently between one click and the next.

**Recovery design.** `SaveSystem` now names a slot's artifacts
(`artifact_paths`), reports whether any exist (`has_artifacts`), and reads one
file through the same version rules as before (`read_payload`, `reason` =
`missing` / `corrupt` / `unsupported_version`). `load_game` became
`_choose_save_source` + `_prepare_save` (the validation the load always ran,
unchanged apart from returning values instead of assigning them) +
`_apply_prepared_save`, so a candidate is accepted by exactly the checks a normal
load applies. Selection writes nothing and changes no live state; a corrupt
candidate is skipped, not repaired.

Ordering and refusals are deliberately asymmetric. A readable primary always
wins, and its refusal stands: a newer `save_version` (or a content-version
mismatch) is still the same message, because loading an older backup there would
be a silent downgrade. Only a missing or unreadable primary lets the backup, then
the temp file, stand in; each must belong to the loaded campaign (a leftover never
switches campaigns) and passes `_prepare_save` or is skipped. A recovered load
reports `recovered_from` and a message naming the source, which the Load panel
shows in its status line and keeps open, since the restored game is already live
behind it. `list_saves`/`_save_info` now show a slot whose primary is gone (tagged
"(from backup)" / "(unfinished save)") instead of "empty".

The legacy directory is a fallback, never a candidate: it is read only when the
campaign slot holds no artifact at all, so a crash's backup is not replaced by an
older demo save with the same slot name. `save_game` also refuses to overwrite a
crashed slot whose readable leftover belongs to another campaign.

**Write-path preservation.** When a crash's `.bak` or `.tmp` occupies the normal
working name, a new save staged through a free working name (`.bak.w` /
`.tmp.w` in that release; numbered names after the interruption audit below),
removed only the files it created, and left crash artifacts intact - on success
and on failure. The previous unconditional pre-staging `.bak` delete is gone.

**UI.** `Main` gained an optional `modal_notice` strip above a modal's scrolling
body (kept across `refresh_modal`); Settings passes the read-only line only when
`settings_newer` is set, so the notice cannot scroll away, and the controls keep
working - the changes apply for the session and are never written.

**Tests added (18).** `tests/test_save_recovery.gd` (13): missing primary ->
backup; corrupt primary -> backup with the damaged file left byte-identical; temp
used only without a readable backup; incompatible primary stops the search with
the existing refusal and no downgrade; valid primary wins with leftovers
untouched; foreign-campaign leftover refused without a campaign switch; no valid
candidate keeps files and refusal; campaign artifacts block the legacy fallback;
an empty campaign slot still uses it; a later save keeps crash artifacts and
leaves no `.bak.w`/`.tmp.w`; a save over another campaign's leftover is refused;
a failed write leaves the artifacts alone; selection changes no live state before
acceptance. `tests/test_persistence_notices.gd` (5): the notice appears only for a
newer file, sits outside the scroll and inside the panel, does not freeze the
controls; the Load row names the backup; the Save row calls a crashed slot
"interrupted", not "empty"; a recovered load states its source in the status line.

**Source checks.** Suite **641/641, 6,931 assertions, 52 scripts, exit 0**.
`--validate-campaigns` PASS, `--validate-diagnostics` PASS, `--demo-inspect
--inspect-probe` PASS, settings/journal/refusal layouts PASS at 100 % and 160 %,
`--settings-notice-probe` PASS at 100 % and 160 % (notice inside the panel, above
the scroll, surviving a refresh), `--save-compat-ui-probe` PASS with the new
backup/newer-primary/temp cases (`UI COMPAT backup status=Loaded slot2 from its
backup...`, `...incompatible version (99.0)`, `...from its unfinished write...`).

**Exported candidate from the clean tree.** `recovery_2026-11-20` was built at
2026-11-20T19:08:08-05:00 from commit `accbc62` with `worktree_entries=0` and no
untracked files; both diff hashes are `e3b0c442...` (SHA-256 of empty input).

| field | value |
| --- | --- |
| build_id | `recovery_2026-11-20` |
| built_at | 2026-11-20T19:08:08-05:00 |
| source_head | `accbc624d62b0402618527ef75a709e3dbca2a1c` |
| worktree_entries | 0 |
| untracked_files | 0 |
| exe_bytes | 110,678,072 |
| exe_sha256 | `a0e305021ac295cc958d0c97421af2652a1468c21841ceecaa44f66ed4f0b7f8` |

Acceptance against that hash: **13/13** - list-campaigns, both validators, the
Inspect probe, the settings/journal/refusal layouts at 100 % and 160 %, the new
settings-notice probe at 100 % and 160 %, and `--save-compat-ui-probe`.
`builds/qa/runs/2026-11-20_recovery/acceptance.log` records the exe hash at its
start and its end line repeats
`sha256=a0e305021ac295cc958d0c97421af2652a1468c21841ceecaa44f66ed4f0b7f8` with
`runs=13 failures=0`; per-check logs are in its `export/`, captures in `shots/`.

**Limits.** (1) Failure paths are simulated - a directory on the primary path and
damaged bytes - not by killing the process mid-write; no OS-level crash injection
was run. (2) `.bak.w`/`.tmp.w` are working names for one write and are not read by
recovery: a crash that leaves only those (possible only when a crash artifact was
already present) reports an empty slot, and the next save replaces them. (3) A
leftover from another campaign is skipped, not loaded, so such a slot appears in
the list but refuses to load with "No save in". (4) Validation still uses the
installed campaign's content, so a recovery copy written for a different
`content_version` is skipped rather than migrated. (5) Layout and notice evidence
covers 1280x720 only; other sizes rest on the earlier resolution pass. (6) GUT
runs in the source tree; the exported binary was verified by the probes above,
not by the suite.

## Save write interruption audit (2026-11-20)

The recovery release read `.bak`/`.tmp` but the write sequence could still place
the only valid copy under a name nothing looked at, and a repeated interrupted
write could truncate an earlier crash copy. This audit lists every interruption
point, shows which copies survive, and fixes the states that reported an empty
slot while a valid copy remained.

### The write sequence and its interruption points

`SaveSystem.write_save` now runs: (W1) ensure the directory; (W2) reserve the
first free temp name from `.tmp`, `.tmp.2`, `.tmp.3`, ...; (W3) reserve the first
free backup name the same way; (W4) create the temp and write the payload; (W5)
verify it parses (on failure the temp is removed and nothing else changes); (W6)
note whether a primary exists; (W7) rename the primary to the backup name; (W8)
rename the temp to the primary; (W9) remove the backup this write created. Steps
W2/W3 write nothing; a name that already exists is never reused, so a crash copy
can no longer be truncated by a later attempt.

| killed after | files on disk | valid copies | loader discovers | data outcome |
| --- | --- | --- | --- | --- |
| W1-W3 | unchanged | the previous set | the previous set | nothing lost |
| W4/W5 (temp partial) | temp (maybe unparseable) + previous set | previous set | previous copies; the partial temp is skipped | nothing lost |
| W6 (temp verified, before rename) | temp (valid) + previous set | previous set + new temp | primary if readable, else the backup tier | the staged save is not chosen while a committed copy exists |
| W7 (primary renamed away) | backup name holds the previous committed save, temp holds the new one, primary missing | both | backup tier, newest copy = the just-staged previous save | previous committed state, never an empty slot |
| W8 (new primary in place) | primary (new), backup name (previous) | both | primary | new state; the orphan backup copy is preserved |
| W9 | primary (new) + any older crash copies | primary and preserved copies | primary | new state |

### Repeated interrupted writes

Working names are reserved, not reused, so each interruption adds at most one
file and every earlier one stays readable. Within a tier the loader prefers the
copy with the greatest `saved_unix`; a tie keeps the first in canonical order
(the canonical name, then the lexicographically first extra name). That is a
deterministic preference, not proof of newest - see the tie rules below.

| files | loader chooses | note |
| --- | --- | --- |
| `.bak` + `.bak.2` + `.bak.3` | `.bak.3` | greatest `saved_unix` |
| `.tmp` + `.tmp.w` | `.tmp.w` | greatest `saved_unix` (old `.w` names still discovered) |
| `.bak` (damaged) + `.bak.2` (valid) | `.bak.2` | previously "No save in slot" |
| `.tmp.2` only | `.tmp.2` | previously "No save in slot" |
| `.bak` + `.tmp` | `.bak` | tier policy: a committed state beats a staged one |
| `.bak` + `.tmp` with a foreign campaign | skipped copies | refusal "No save in", campaign not switched |
| primary version 99 + `.bak.w` | refused | the incompatible-primary refusal is preserved |
| legacy save + `.bak.2` | `.bak.2` | legacy fallback stays blocked by any artifact |

### What changed

- `SaveSystem.slot_files` discovers every file whose name starts with
  `<slot>.json`, classifying `.bak*` as backup and `.tmp*` as temp, so `.bak.2`,
  `.tmp.2`, `.bak.w` and `.tmp.w` are all visible. `has_artifacts`,
  `list_saves`, `first_readable` (list rows, overwrite guard) and
  `delete_save_everywhere` (QA/test cleanup only)
  use it; `Game.has_save` counts artifacts, so Continue is offered for a crashed
  slot.
- Working names are reserved with `_free_working_name`; at 100 existing copies of
  one family a save refuses with "Too many interrupted saves" instead of
  overwriting one.
- `_choose_save_source` walks the backup tier and then the temp tier over
  `slot_files`, keeping the same validation, campaign and content checks, and
  picking the newest readable copy within a tier. The primary is still
  unconditional and its refusal still stops the search.
- On an interrupted second write, a crash copy is no longer truncated: the old
  code reused `.tmp.w`/`.bak.w` and `FileAccess.WRITE` truncated them.

### Tests and checks

`tests/test_save_interruption.gd` (17 tests) builds each state above and asserts
the chosen source, the recovered state, that every file is byte-identical after
selection, repeated-interruption naming, that a failed write never truncates a
working copy, the campaign guard, listing/Continue for a working-copy-only slot,
and deletion of working copies. Suite **658/658, 7,113 assertions, 53 scripts,
exit 0**. In source: `--validate-campaigns` and `--validate-diagnostics` PASS,
Inspect PASS, settings/journal/refusal layouts PASS at 100 % and 160 %, the
settings-notice probe PASS at 100 % and 160 %, and `--save-compat-ui-probe` PASS
with the added working-copy case (`UI COMPAT working copy status=Loaded slot2
from its backup; the save was interrupted...`).

**Remaining durability limits.** (1) Interruptions are reproduced by building
their file states, not by killing the process at each step; no OS-level crash
injection ran. (2) Tier order beats recency: a crash between W7 and W8 recovers
the committed backup, so one save's worth of new progress is not restored even
though its temp remains on disk (it is never chosen while a backup reads).
(3) Crash copies are never pruned; each interruption adds one file and nothing
collects them (the 100-copy cap turns that into a refused save, not a silent
loss). (4) `write_save` does not fsync, so a power loss may still lose the most
recent file data on some filesystems; rename ordering is assumed. (5) `saved_unix`
has one-second resolution, so copies written in the same second tie and the
canonical name wins - deterministic, but not necessarily the newest. (6) A
recovery copy from another campaign or another `content_version` is skipped, not
migrated, so a slot holding only such copies still reports "No save in".
(7) Layout evidence covers 1280x720 only. (8) GUT runs in the source tree; the
exported binary is verified by the probes.
**Exported candidate from the clean tree.** `interruption_2026-11-20` was built at
2026-11-20T19:21:11-05:00 from commit `dafacd8` with `worktree_entries=0` and no
untracked files; both diff hashes are `e3b0c442...` (SHA-256 of empty input).

| field | value |
| --- | --- |
| build_id | `interruption_2026-11-20` |
| built_at | 2026-11-20T19:21:11-05:00 |
| source_head | `dafacd8fc24e5b8b89ffeb96b377d33df4abcbad` |
| worktree_entries | 0 |
| untracked_files | 0 |
| exe_bytes | 110,679,352 |
| exe_sha256 | `4c0d699dc3a48cdac42a82b666e736302e312382f1422028a0476fc863cf488a` |

Acceptance against that hash: **13/13** - list-campaigns, both validators, the
Inspect probe, the settings/journal/refusal layouts at 100 % and 160 %, the
settings-notice probe at 100 % and 160 %, and `--save-compat-ui-probe`, whose new
working-copy case reports `Loaded slot2 from its backup; the save was
interrupted...` and restores the saved cell.
`builds/qa/runs/2026-11-20_interruption/acceptance.log` records the exe hash at
its start and its end line repeats
`sha256=4c0d699dc3a48cdac42a82b666e736302e312382f1422028a0476fc863cf488a` with
`runs=13 failures=0`; per-check logs are in its `export/`.

## Slot-file pattern, refusal accuracy and timestamp ties (2026-11-20)

The interruption audit left two loose ends: discovery/deletion matched any name
starting with `<slot>.json`, and a slot holding only unusable copies still
answered "No save in slot". Both are now defined by one parser.

### Exact accepted pattern

`SaveSystem.parse_slot_file(name, slot)` is the single definition used by
discovery, classification and deletion. Names match case-insensitively, keep
their own directory spelling, and only these forms are accepted:

| accepted | role | produced by |
| --- | --- | --- |
| `<slot>.json` | primary | every write |
| `<slot>.json.bak` | backup | a write over an existing primary |
| `<slot>.json.bak.<n>`, n = 2..100 | backup | a write beside an earlier crash copy |
| `<slot>.json.bak.w` | backup | the previous release's working name (legacy read only) |
| `<slot>.json.tmp` | temp | every write |
| `<slot>.json.tmp.<n>`, n = 2..100 | temp | a write beside an earlier crash copy |
| `<slot>.json.tmp.w` | temp | the previous release's working name (legacy read only) |

Rejected: `.bakup`, `.bak.1`, `.bak.0`, `.bak.01`, `.bak.+2`, `.bak.-2`,
`.bak.101`, `.bak.w.2`, `.bak.2.old`, `.tmpX`, `.orig`, `.notes`, `~`,
`.json.2026-11-20`, `slot2.jsonx`, and any other suffix. Consequences: a
hand-made archive is never loaded as recovery, never lists the slot, never blocks
the pre-campaign fallback and is not deleted with the slot; only the files the
game wrote are `delete_save_everywhere`'s to remove; that helper is QA/test
cleanup, not a player action (see "Cleanup helper honesty and scope").

Case handling: parsing is case-insensitive because Windows and macOS are, and
`path_for` already resolves a differently cased primary there. Entries keep the
spelling the directory reports, so two names differing only by case stay two
files on a case-sensitive filesystem; the exact spelling is read first and each
entry is deleted by its own name. A primary stored as `SLOT2.JSON` is discovered
and loads.

### Unusable slots are never "empty"

`_choose_save_source` classifies every candidate it rejects and returns the most
actionable message, in this precedence: incompatible version, other campaign,
other content version, invalid state, unreadable bytes. "No save in slot" is
reserved for a slot with no accepted files at all.

| slot holds | message | `reason` |
| --- | --- | --- |
| nothing | `No save in slot2.` | `missing` |
| only unparseable bytes | `Save slot2 is corrupt (invalid JSON).` (existing text) | `corrupt` |
| only a newer version | `Save slot2 was written by an incompatible version (99.0).` (existing text) | `unsupported_version` |
| only another campaign | `Save 'slot2' belongs to campaign 'X', which is not loaded.` | `campaign_mismatch` |
| only another content version | `Save 'slot2' was made for campaign content version 2; the installed campaign is version 1. The save was not modified.` | `content_mismatch` |
| only an invalid payload | the existing validation text, e.g. `Save contains no valid party members.` | `invalid` |
| a mix | the highest-precedence reason above | as named |

The primary path is untouched: a readable primary still wins outright and its
incompatible-version, corrupt and content messages are byte-identical to the
previous release (pinned by `test_primary_refusals_are_unchanged`). The save
panel says "unreadable - incompatible copy" for a slot whose only files are
version-incompatible and "damaged - no readable copy" for unparseable bytes; the
Load list tags such rows `(unreadable)` and no row is reported as `empty`.

### Timestamp ties

Selection order is unchanged: primary (never compared by time), then the backup
tier, then the temp tier; within a tier the greatest `saved_unix` wins. A tie
keeps the first candidate in canonical order, which is: the canonical name
(`.bak` or `.tmp`), then the remaining names sorted as strings. Therefore
`.bak` beats `.bak.2` on a tie, `.bak.10` beats `.bak.2` on a tie, and a copy
without a `saved_unix` (treated as 0) loses to any copy that has one. Two copies
without a timestamp tie on the canonical name. The order is deterministic but
not proof of newest: `saved_unix` has one-second resolution, it is written from
the system clock, and it is a player-editable field.

### Tests and checks

`tests/test_save_files.gd` (16 tests) covers the accepted/rejected name table,
case variants and distinct files, stray files (discovery, listing, legacy
fallback, deletion), a case-variant primary, damaged/incompatible/foreign/
content-mismatch/invalid-only slots and their messages, mixed-precedence
selection, the three tie rules, missing timestamps, unchanged primary refusals,
and the `(unreadable)` row tag. Two interruption tests were updated to expect
the precise refusal instead of "No save in", and one was renamed to state the
`greatest saved_unix` rule. Suite **674/674, 7,227 assertions, 54 scripts,
exit 0**. In source: both validators PASS, Inspect PASS, settings/journal/refusal
layouts PASS at 100 % and 160 %, the settings-notice probe PASS at 100 % and
160 %, and `--save-compat-ui-probe` PASS including the new incompatible-only
case (`UI COMPAT incompatible-only status=Save slot2 was written by an
incompatible version (99.0).`) and the stray-file check.
**Exported candidate from the clean tree.** `pattern_2026-11-20` was built at
2026-11-20T19:55:49-05:00 from commit `437fa40` with `worktree_entries=0` and no
untracked files; both diff hashes are `e3b0c442...` (SHA-256 of empty input).

| field | value |
| --- | --- |
| build_id | `pattern_2026-11-20` |
| built_at | 2026-11-20T19:55:49-05:00 |
| source_head | `437fa407ff246da49bab1ded848893d726dab62e` |
| worktree_entries | 0 |
| untracked_files | 0 |
| exe_bytes | 110,683,464 |
| exe_sha256 | `dc2d1b5e97d3400917f60acbc7381b9ffacf28c12d14b140add4848521f10963` |

Acceptance against that hash: **13/13** - list-campaigns, both validators, the
Inspect probe, the settings/journal/refusal layouts at 100 % and 160 %, the
settings-notice probe at 100 % and 160 %, and `--save-compat-ui-probe`, whose new
cases report `UI COMPAT incompatible-only status=Save slot2 was written by an
incompatible version (99.0).` and reject a hand-made `slot2.json.2026-11-20`
archive. `builds/qa/runs/2026-11-20_pattern/acceptance.log` records the exe hash
at its start and its end line repeats
`sha256=dc2d1b5e97d3400917f60acbc7381b9ffacf28c12d14b140add4848521f10963` with
`runs=13 failures=0`.

**Platform limits.** (1) Only Windows was exercised. Names are matched
case-insensitively because Windows and macOS are; on a case-sensitive filesystem
the distinct-entry behavior is covered by the pure `_classify_names` test, not by
a real macOS/Linux run. (2) A name that matches the accepted pattern is treated
as a slot file regardless of who created it: a hand-made copy named exactly
`slot2.json.bak.3` is recovery, while `slot2.json.2026-11-20` is not. (3) On a
case-insensitive filesystem two names differing only by case cannot coexist, so
the "two distinct files" case is only observable on a case-sensitive volume.
(4) The pattern accepts 2..100 working copies per family; at the cap a save
refuses instead of overwriting. (5) Legacy `.w` names are read only; this build
never produces them. (6) Deleting a slot still removes that slot from every
campaign directory, by design. (7) Timestamps remain second-resolution,
clock-derived and player-editable, so tie order is deterministic but not a
recency proof. (8) No OS-level crash injection; filesystem rename ordering and
the absence of fsync are unchanged. (9) Layout evidence is 1280x720 only; GUT
runs in the source tree and the exported binary is verified by the probes.

## Cleanup helper honesty and scope (2026-11-20)

`SaveSystem.delete_save` is now `delete_save_everywhere`, and it no longer claims
success while a file is still there.

**Scope, stated in the comment.** It deletes one slot from the legacy
pre-campaign directory and from every directory under `user://saves` - all
campaigns, and every recovery copy (`.bak`, `.tmp`, `.bak.N`, `.tmp.N`, `.bak.w`,
`.tmp.w`). Only names accepted by `parse_slot_file` are attempted, so unrelated
files (archives, notes, `other.txt`) are never touched. The comment also says
what the old one got wrong: this is **QA and test cleanup**, there is no in-game
delete, and nothing in `src/ui` calls it. The 12 QA probe call sites and 42 test
call sites were renamed mechanically; no player-facing path exists.

**Per-file failure report.** The return value is
`{"ok": bool, "removed": Array[String], "failed": Array}`, where each failure is
`{"path": String, "error": Error}`. Removal is confirmed by re-checking the file,
so an `OK` error code that leaves the file behind is still a failure, and `ok` is
true only when no accepted file remains. A slot with nothing to remove is a
successful no-op; a partial deletion reports the files that survived and still
removes the rest.

**Tests.** `tests/test_save_cleanup.gd` (6 tests) pins:
- removal from two campaign directories and the legacy directory, with all six
  files reported in `removed`;
- preservation of an archive, a `.notes` file and an unrelated file, unchanged;
- a no-op slot reporting `ok` with empty `removed`/`failed`;
- a locked copy: on this Windows host an open handle makes
  `DirAccess.remove_absolute` fail (`err=1`, file present), so the test asserts
  `ok == false`, exactly one `failed` entry naming that path with a non-`OK`
  error, the other two copies still removed and not listed as removed, and a
  retry after closing the handle succeeding; hosts that allow unlinking an open
  file take a documented success-only branch;
- a source guard that no `res://src/ui/*.gd` mentions `delete_save`, and that
  every `src/main.gd` call sits in a probe function (or the `_compat_ui_fixture`
  those probes share).

`test_delete_removes_working_copies_too` was also repaired: its payload helper
saves and deletes the slot, so building payloads inline wiped the copies written
before them and the test only ever deleted one file. It now builds all four
payloads first and asserts four removals with each name gone.

**Checks.** Suite **680/680, 7,284 assertions, 55 scripts, exit 0**. Both
validators PASS. Affected probes: `--creator-interaction-probe`,
`--creator-story-probe`, `--creator-combat-probe`,
`--creator-combat-reload-probe`, `--save-compat-probe` and
`--save-compat-ui-probe` all exit 0. `--creator-acceptance-probe` (which calls
the helper at its start) fails at "Validate draft accepts the authored campaign"
after 22 passing checks and then hangs until the timeout; the same probe at
`87e64bf` (before this change) also fails and hangs, earlier, at "creating a
campaign opens the creator" (3 passing checks). It is a pre-existing,
environment-dependent probe failure, not a regression from the rename, and it is
not counted as a passing check.

## Creator acceptance probe: cause, exit contract and regression (2026-11-20)

The probe used to fail at "Validate draft accepts the authored campaign" and then
hang. Both are now explained and fixed.

**Reproduction.** Two revisions, two fresh APPDATA profiles, the same binary and
flags (`--creator-acceptance-probe`, 90 s bound): `87e64bf` (before the cleanup
work) and `4e1188b` (current at the time). Both printed the same 22 passes, then
failed that one check, cascaded through nine dependent checks, hit
`SCRIPT ERROR: Invalid call. Nonexistent function 'finish' in base 'Nil'` at
`Game.encounter.finish`, and were killed by the harness at 90 s (exit 124). An
earlier apparent difference - `87e64bf` failing earlier at "creating a campaign
opens the creator" - came from running an un-imported `git archive` checkout:
without a `.godot` cache the first UI frame arrives later. After `--import` both
revisions fail identically, so the difference was test setup, not behavior.

**First failed check, with diagnostics.** With the probe's new failure detail:

```
CREATOR PROBE FAIL Validate draft accepts the authored campaign | status=Applied
draft validates, but pending form edits are not included. Apply or discard them
before saving or playtesting. pending=["choice"] errors=[]
```

The draft itself validated; the creator thought a plain choice was edited.

**Confirmed cause.** `CampaignCreator._choice_form_pending()` compared `"dc"` in
its unconditional field loop, but `dc` only exists for choices with a check. The
probe authors a check at DC 5, then a plain choice; the DC spin still held 5
while a plain choice stores the default 12, so the plain choice looked edited
forever. Every consumer followed: `_validate()` reported the pending-edits
warning instead of `Draft validates:`, `_save()` and `_playtest()` refused
(`_guard_pending`), the draft stayed unsaved, playtest never started,
`Game.encounter` was null, and the unguarded `Game.encounter.finish("victory")`
aborted the probe coroutine before its final print and `quit()`. With no exit
call the window stayed open until the harness timeout - the probe looked slow
instead of failed.

**Hang, second path.** Six early returns in the probe (`create == null`,
`fields.size() < 2`, and so on) skipped the final `quit()` for the same reason.
Both paths now end the run.

**Fixes, no assertion weakened.**
- Production: `_choice_form_pending()` compares the skill, DC and branch fields
  only when the form's check is on, matching `_apply_choice()`, which writes no
  DC for a plain choice.
- Probe: `_creator_probe_check` gained an optional detail that is printed on
  failure (status, pending form keys, diagnostics).
- `_creator_probe_exit(campaign_id)` prints `PASS`/`FAIL` with the failure count,
  cleans the probe campaign and saves, and quits with 0 or 1; every early return
  and the normal end go through it.
- `Game.encounter` is checked before `finish`; a missing encounter is an explicit
  failure instead of a script error.
- `_creator_probe_watchdog(60.0)` exits 1 if a runtime error aborts the coroutine
  anyway, so a broken probe fails within a minute instead of hanging.

**Verification.**
- Probe: `CREATOR ACCEPTANCE PROBE PASS campaign=probe_acceptance failures=0`,
  50 checks, exit 0, 5.8-6.0 s (fresh profile).
- Failure exit: a temporary forced failed check (`_creator_probe_check(false, ...)`,
  not committed) gave exit 1 in 5.9 s with `failures=1`.
- Runtime-error exit: a temporary null dereference mid-probe (not committed) gave
  exit 1 at 8.4 s under a 5 s test watchdog, printing
  `reason=watchdog after 5s`.
- Regression test: `test_a_plain_choice_is_not_pending_after_a_check_at_a_custom_dc`
  drives the real creator (check at DC 5, then a plain choice), asserts the
  choice form is not pending, that `pending_form_keys()` is empty, and that the
  plain choice stores its text and no check. Restoring the old unconditional
  `"dc"` comparison makes it fail with `pending=["choice"]`; with the fix it
  passes.
- Suite: **681/681 tests, 7,297 assertions, 55 scripts, exit 0**. Both validators
  PASS.
- Creator probes: `--creator-probe`, `--creator-ui-probe`,
  `--creator-interaction-probe`, `--creator-story-probe`, `--creator-combat-probe`,
  `--creator-combat-reload-probe` (run against the combat probe's profile, as its
  message requires) and `--creator-acceptance-probe` all exit 0.

**Remaining uncertainty.** (1) The probe still drives real frames; on a heavily
loaded machine a fixed one-frame wait could race, though it did not across the
runs above, and the watchdog now bounds it. (2) The watchdog is specific to the
acceptance probe; the other creator probes have no early returns that skip their
exit (checked), but they have no crash watchdog either, so a new runtime error
there would still hang. (3) The DC fix is verified through the creator UI and the
acceptance probe; no separate end-to-end playtest of a campaign that mixes check
and plain choices was run beyond that.
**Exported candidate from the clean tree.** `creator_probe_2026-11-20` was built
at 2026-11-20T20:49:30-05:00 from commit `2dc61e1` with `worktree_entries=0` and
`untracked_files=0`.

| field | value |
| --- | --- |
| build_id | `creator_probe_2026-11-20` |
| source_head | `2dc61e17f5a4a0832db88bf495c29eb71eeb8d29` |
| worktree_entries | 0 |
| untracked_files | 0 |
| exe_bytes | 110,684,280 |
| exe_sha256 | `4196d9781955b641210b64fcccc34a7922f9e9b438fd47a123212950f0a7c7cf` |

Acceptance against that hash: **9/9** - both validators and all seven creator
probes (`creator-probe`, `creator-ui-probe`, `creator-interaction`,
`creator-story`, `creator-combat`, `creator-combat-reload`, `creator-acceptance`),
each with a fresh APPDATA profile except the reload probe, which reuses the
combat probe's profile as its message requires. The acceptance probe passed in
4.0 s with exit 0. `builds/qa/runs/2026-11-20_creator_probe/acceptance.log`
records the exe hash at its start and end
(`runs=9 failures=0`); `builds/qa/runs/creator_probe_acceptance.sh` is kept
outside its own output directory so the run cannot delete itself.

## Batch closure: audit refresh (2026-11-20; documentation only)

This reconciles the 2026-11-20 audit ("Candidate audit and migration readiness"
and the sections after it) with the fixes that are now committed. No code was
changed, no candidate rebuilt and no check re-run for this section; every status
below is what the recorded logs and `BUILD.txt` files already on disk support,
and the places where that record is weaker than a result are named as gaps.

### Status of the audit's seven items

| Item | Status | Fix | Evidence recorded | Residual |
| --- | --- | --- | --- | --- |
| UI scaling | **Closed** | `15329d3` (client-size layout, 160 % fit) | `ui_scaling_2026-11-20b` `6d38c18d`; 18/18 in `runs/2026-11-20_ui_fix/`; settings/journal/refusal layouts at 100 % and 160 % on `pattern_2026-11-20` `dc2d1b5e` (13/13) | Latest layout evidence is 1280x720 only; the modal limits below remain |
| Journal output | **Closed** | `3dc28cc` (+ `4b63c88` uid) | `journal_2026-11-20` `d3070eae`, 7/7 (list, both validators, Inspect, journal 1.0/1.6, save-compat); native Journal close by mouse and Enter at both scales; native wheel over a 70-question overflow fixture at both scales (`2026-11-20_modal/report.md`) | None for scrolling; the overflow fixture is a user package, not shipped content |
| Refusal logging | **Closed** | `c3ede47` (+ `b203a1d` uid) | `refusals_2026-11-20` `06883c82`: both validators, Inspect, refusal layout at 100 % and 160 %; native real W/F input at both scales | Export exercises the wall family only; the key binding rests on the input tests, not the layout scenario |
| Migration foundation | **Foundation only; no production step** | `93e8199` | `migration_2026-11-20` `00136308`, 11/11 hash-bound; `SAVE_VERSION` still 1, `steps` empty | A production step is deferred; `content_version` stays a refusal by design |
| Recovery | **Closed with limits** | `accbc62`, `dafacd8`, `437fa40` | `recovery_2026-11-20` `a0e30502` 13/13; `interruption_2026-11-20` `4c0d699d` 13/13; `pattern_2026-11-20` `dc2d1b5e` 13/13 | No OS crash injection; 2..100 working-copy cap; case-sensitive-filesystem behavior unproven; tie order is deterministic, not newest |
| Cleanup hardening | **Closed (QA-only)** | `4e1188b`, uid `2dc61e1` | Source suite 680/680 and the six probe runs in `runs/creator_probes/`; the helper is present in `creator_probe_2026-11-20` | No dedicated export check, because the helper has no player-facing path to exercise |
| Creator acceptance | **Closed** | `161ceb2`, uid `2dc61e1` | `creator_probe_2026-11-20` `4196d978`, 9/9 hash-bound (both validators + seven creator probes); acceptance probe 50 checks, exit 0, 4.0 s in the export | Probe still depends on frame timing; the 60 s watchdog bounds a regression |

### Where the original audit is now out of date

- "No `acceptance.log` exists for any of the three runs" was true for the three
  modal builds. Later candidates write one and bind the exe hash at both ends
  (`migration`, `recovery`, `interruption`, `pattern`, `creator_probe`).
  `journal` (7/7), `ui_fix` (18/18) and `refusals` (per-check logs only) still
  lack a consolidated, hash-named log - a gap, not a passing check.
- "The `.bak` is never read, so a crash leaves an unread backup" is superseded by
  `accbc62`/`dafacd8`/`437fa40`: the backup and temp are read, validated, and
  only used when the primary is missing or unreadable.
- "Migration readiness (assessment only; nothing implemented)" is superseded by
  the foundation in `93e8199`. The version-refusal-only state is no longer
  accurate for settings either: `settings.cfg` now carries `[meta] version = 1`,
  merges on write, and refuses to write a newer file.
- The audit's UI status split still stands: the 27 px Settings list, HSlider/TabBar
  traversal, clipped last row and off-screen focus are closed on `modal_pane` and
  `modal_focus`, and the remaining limits are unchanged.
- Both focus defects found by the native pass (Tab escaping a modal, no focus
  after close) are closed by `e9a5086` and `b5dfd9b`.

### Remaining defects, and items that are not defects

Reclassified 2026-11-21. Only a reproduced, reachable failure counts as a
defect. A guard for an unreachable layout, outstanding maintenance and an
unsupported input device are recorded in their own sections; calling them
defects overstated them. The audit's original five items are unchanged in
substance, only in classification.

**Confirmed defects (not fixed)**

1. Reveal runs only while a modal is open; the campaign creator keeps its own
   path. The creator has its own keyboard path, so this is a narrow scope
   limitation, but the result is still an inconsistent reveal and it is recorded
   as a defect rather than as debt.

**Defects found and fixed after the defensive-actions acceptance (2026-11-21)**

2. **[Fixed 2026-11-21] A live defensive stance survived the end of its encounter and was
   written into the victory autosave.** `Encounter.finish` already cleared Combat
   Expertise, but not `fighting_defensively` or `total_defense`, nor the encounter-only
   selection. A fight that ended while a stance was active — a defensive finishing blow, or
   total defense followed by an ally's kill — left the dodge bonus on the character in
   exploration, showed it in the party card and character sheet, and serialized it, because
   `Character.to_dict` writes `effects`. Reproduced before the fix through the real
   resolution and autosave path: fighting defensively AC 19 vs base 17, total defense 21 vs
   17, both present in `auto.json` and after `load_game`. Combat math was unaffected (the
   next fight starts flat-footed, which denies dodge bonuses) and the character's first turn
   removed the effect, so the failure was stale display state plus a polluted save, not a
   wrong to-hit number. Fixed in `Encounter._clear_combat_scope_states` (see the section at
   the end of this file).

**Conditional layouts (not confirmed defects)**

- A control taller than its pane aligns to the pane's top, so its bottom can
  clip. No shipped modal reaches that condition at 100 % or 160 %; it guards
  future layouts and is not a reproduced defect.

**Maintenance debt (not defects)**

- `follow_focus` remains on the shared body beside the reveal walk; one of the
  two is now redundant.
- One pane follows the focus per key press, so with two scrolling panes only one
  moves. That is a designed property of the single-focus walk, not a failure.

**Unsupported features (not defects)**

- Gamepad page keys are not handled. A gamepad is not a shipped input path, so
  this is an unsupported feature rather than a defect.
- No reveal after a silent relayout: silent relayouts are unreproduced.
  `open_modal` fixes the panel's minimum size once (base size times text scale,
  capped to the client at open time), so a window resize re-centres the panel
  without reflowing its body, and a refresh rebuilds and refocuses through
  `gui_focus_changed`. Kept as a guard for a future responsive modal.

Correction (2026-11-21): key repeat is implemented and automated-verified.
Physical held-key acceptance is pending (see the modal held-key entry at the end
of this file) and is an **evidence gap**, not a defect.

### Acceptance log binding (policy from 2026-11-21)

Every future acceptance run must record the exported executable's SHA-256 before
the first check and again after the last check, in the run log itself, and the
two values must match. A run whose hash appears only in `BUILD.txt` is bound by
that file but not by the run, so it stays "no" in the candidate table's bound
column. This applies to probes, validators, suite runs against an export and any
native pass. The two creature-cover candidates remain explicitly unbound: their
logs recorded no start/end hash, although each `BUILD.txt` pins the hash.

### Verification gaps (distinct from defects)

- Enter activation of a focused modal button is native-verified only; headless GUI
  key activation does not fire in the harness, so no unit test covers that half.
  Shift+Tab is not a gap: it was verified natively at 100 % and 160 %
  (`2026-11-20_scrollkeys/assessment.md`), and the earlier "cannot inject Shift"
  note was withdrawn because that failure was the action-matching bug fixed in
  `b5dfd9b`.
- No OS-level crash injection for save writes; interruption states are built
  directly and failure paths simulated.
- Case-sensitive filesystems: two slot names differing only by case are asserted
  through `_classify_names`, not by a real macOS/Linux run.
- Latest layout and notice evidence covers 1280x720 only.
- GUT runs in the source tree; exported binaries are covered by probes, not by
  the suite.
- `journal` 7/7 and `ui_fix` 18/18 do not name the exe they ran; `refusals` has
  no consolidated log; the three modal runs have none (recorded in the audit).
- The cleanup helper's per-file failure path is exercised by an open handle on
  Windows; hosts that allow unlinking an open file take a success-only branch.
- The earlier `modal_focus_2026-11-20` binary (`fe7511b3...`) is missing; its
  results stay documented but cannot be re-verified.

### Deferred features

- Any save migration production step: the table, floor and in-memory upgrade
  exist, `steps` is empty, `SAVE_VERSION` stays 1, and a migrated save is only
  written when the player saves again. **Foundation only; no production step.**
- Content-version migration: deliberately a refusal - a save names ids only the
  campaign author can re-map.
- Key repeat, gamepad page keys and reveal outside modals are limits, not
  scheduled work in this batch.
- Deferred mechanics in `FEATS_SKILLS_COVERAGE.md` remain outside this batch.

### Latest candidates and what each acceptance covered

All under `builds/qa/candidates/`, source heads from `BUILD.txt`; "bound" means
the acceptance log records the exe hash at its start and end.

| Candidate | source_head | exe_sha256 | bytes | Acceptance scope | Bound |
| --- | --- | --- | --- | --- | --- |
| `ui_scaling_2026-11-20b` | `a64eead` | `6d38c18d8f533a245343ae4df9731e7ae41ad27e2d7b7477c4b2c5a17435dbd7` | 110,647,296 | 18/18 in `runs/2026-11-20_ui_fix/` (layouts, notice, save UI) | no |
| `journal_2026-11-20` | `3dc28cc` | `d3070eae4878c85884d374b83561865cf9f3f14fda2fc1d2a2174dfd4816ca79` | 110,662,552 | 7/7 (list, both validators, Inspect, journal 1.0/1.6, save-compat) | no |
| `refusals_2026-11-20` | `c3ede47` | `06883c8254ed8cf2411ae7174adb847b4ca0f7818a2b45903a2b6ccd1ef29d7d` | 110,662,808 | Both validators, Inspect, refusal layout 1.0/1.6 (per-check logs) | no |
| `migration_2026-11-20` | `93e8199` | `00136308f9a3237504daa89da37db782105b75b3289b2baea08dd0378dbada71` | 110,670,872 | 11/11 (list, both validators, Inspect, three layouts at both scales, save UI) | yes |
| `recovery_2026-11-20` | `accbc62` | `a0e305021ac295cc958d0c97421af2652a1468c21841ceecaa44f66ed4f0b7f8` | 110,678,072 | 13/13 (adds the settings-notice probe at both scales) | yes |
| `interruption_2026-11-20` | `dafacd8` | `4c0d699dc3a48cdac42a82b666e736302e312382f1422028a0476fc863cf488a` | 110,679,352 | 13/13, same scope as recovery | yes |
| `pattern_2026-11-20` | `437fa40` | `dc2d1b5e97d3400917f60acbc7381b9ffacf28c12d14b140add4848521f10963` | 110,683,464 | 13/13, including the incompatible-only and stray-file compat cases | yes |
| `probe_2026-11-20` | `161ceb2` | `4196d9781955b641210b64fcccc34a7922f9e9b438fd47a123212950f0a7c7cf` | 110,684,280 | none recorded; exported with one untracked uid | no |
| `creator_probe_2026-11-20` | `2dc61e1` | `4196d9781955b641210b64fcccc34a7922f9e9b438fd47a123212950f0a7c7cf` | 110,684,280 | 9/9 (both validators + seven creator probes) | yes |
| `creature_cover_2026-11-21` | `4e56d1e` | `3045596184a265577d3fef325476c2840ded5219ce5ed728470cea382b974a39` | 110,693,592 | Both validators from the exe, Inspect probe, inspect and dialogue layouts at 100 %/160 %; the panel clause was not rendered yet | no |
| `creature_cover_inspector_2026-11-21` | `e64a6c9` | `b5b1f67403c70472fd290cbb01c08816cc333d9d8a6f105facc8377824c81c89` | 110,698,344 | Both validators from the exe, cover probe and cover layout at 100 %/160 % (23 checks / 23 controls), source suite 731/731 | no |
| `defensive_actions_2026-11-21c` | `58cb1a7` | `f705ceda267440d8d1ecc73d06eaf745f0722ff9edcaced32664040e4faafd0f` | 110,708,200 | Both validators from the exe, defensive probe at 100 %/160 % in the exe (45 checks each, 0 failures), exe hash `f705ceda...4faafd0f` matched before/after; contains the source-tested combat-scope cleanup, which this probe does not exercise | yes |
| `bull_rush_2026-11-21b` | `9b0f046` | `33071751d7ba76773730416f2ab3ad711e09080392123ef6d44a8f9692a60e4c` | 110,732,632 | Both validators from the exe, `--demo-combat --layout-probe --layout-scenario=combat` at 100 %/160 % (29 controls each, 0 failures), exe hash matched before/after, source suite 778/778. Rules behaviour is source-tested only; the probe shows layout, not bull rush outcomes | yes |
| `bull_rush_2026-11-21` | `12ecb76` | `0946289c0240c902b4f1b98875a666862d59ef203035072db4e99c0b382c8c40` | 110,733,240 | **Not accepted.** Its 100 % layout run was measured without `--demo-combat`, and the corrected 160 % run failed six reachability checks because the layout probe only scrolled the innermost `ScrollContainer`. Superseded by `-b`, which carries the probe fix | no |
| `defensive_actions_2026-11-21c` | `58cb1a7` | `e53a62656eadb0765384898de492524e76dbc3f78c323ed5caa5454afd11fb25` | 110,708,296 | Superseded by `-c`. Accepted for the defensive-actions scope, but ships the stance-leak defect: a stance active when the fight ended survived into exploration and the victory autosave | no |
| `defensive_actions_2026-11-21` | `a8c8189` | `f6bb00f21a4765e1014fcdc8f16beba9fc219548678cc68f5bff01f3a2d5de6b` | 110,708,264 | Superseded by `-b`; same scope, before the stance-specific attack refusal | no |

`defensive_actions_2026-11-21c` supersedes `-b`: it is exported from clean source
`58cb1a7` (which contains `7fae8d1`, the combat-scope cleanup) and keeps the same
defensive-probe scope. `-b` is preserved unchanged and its stance-leak defect is
recorded with it; its acceptance stands only for the scope it was run for. The
cleanup itself is verified by the source suite, not by the probe, because the
probe never ends an encounter and never writes a save.

`probe_2026-11-20` is superseded by `creator_probe_2026-11-20`: the same
executable bytes, re-exported from a clean tree, and only the clean one carries
acceptance. Source head `c23f96c` is documentation only and has no binary. The
older `modal_scroll` (`0c2f982e`), `modal_pane` (`6217fe39`) and `modal_focus`
(`42b003c9`) candidates remain as recorded in the audit; nothing was rebuilt.

### Applied bell-page warnings (label-only, 2026-11-21)

Both gaps are closed by appending one clause to three choice labels in
`content/campaigns/ashwick_ferry/dialogue/ferry_bell.json`; the content diff
touches only `"text"` lines, so no condition, effect, destination, flag or reward
changed.

- `Ring once for passage. — The token is spent permanently.`
- `Ring twice for the dead. — This starts combat.`
- `Break the token and leave the bell silent. — The token is spent permanently.`

`test_bell_rows_warn_about_the_permanent_cost_and_combat` asserts the three exact
labels, that the bare ring-once label is gone, that all three rows stay available
before the choice, and that ringing once still spends `ivo_token` and sets
`ferry_bell_rung`/`bell_resolved`. The existing second-ring tests still cover the
ring-twice fight, the break path, the refused/kept account rows and the epilogue
destinations.

Verified on this change: full suite **682/682 tests, 7,334 assertions, 55
scripts, exit 0**; `--validate-campaigns` PASS (ravenloft_demo, hollow_lantern,
ashwick_ferry) and `--validate-diagnostics` PASS (`[]`), both exit 0. The content
diff has three changed lines, every one a `"text"` value.

### Epilogue row reachability at 160 % (checked, no change)

The silence epilogue row - *Tell me what the silence means for the ferry.* -
is still in `maela_vey.json` (`next = epilogue_silent`), gated by
`bell_resolved`, `bell_silenced` and not `maela_epilogue`. It sits in the same
single-column choice list as the account rows, seven unavailable rows down, and
was reached by scrolling at 160 % in the silence playthrough
(`account_decision_2026-11-14`, captures `s10`-`s12`). `15329d3` then capped the
dialogue panel to the client and kept one vertical ScrollContainer (horizontal
disabled), so the row stays reachable by wheel or scrollbar. At the time nothing
was captured after that change at 160 %, and the scroller had no `follow_focus`,
so Tab could focus the row without revealing it. That gap is now closed:
`2026-11-21` adds focus-follow and contained Tab traversal, and the row is shown
above the fold at 100 % and 160 % (see below).

### Dialogue choice focus reveal (closed, 2026-11-21)

The conversation body keeps its ScrollContainer and sets `follow_focus`; while a
conversation is open, Tab and Shift+Tab cycle its available choices in content
order instead of wandering into the HUD, and the body scrolls the new owner into
view. Unavailable rows stay visible and are skipped, and mouse wheel and click
activation are untouched. A QA-only `--demo-silence` entry seeds the broken-token
state so the gated row can be driven with ordinary input.

Verified on candidate `dialogue_focus_2026-11-21b` (source `01d1cfc`, SHA-256
`cd00d38988ab1f721cc19b52c19f669e0c86e4a5f3be666543781de5ea4c5330`, 110,686,136
bytes) with a 1280x720 client at 100 % and 160 %: four Tabs put a visible ring on
*Tell me what the silence means for the ferry.* and scrolled the row above the
fold from below it; one Shift+Tab moved back to an earlier choice with the body
scrolled up; Enter opened `epilogue_silent` ("The token is broken..."); the wheel
still scrolled the body. Captures are in
`builds/qa/runs/2026-11-21_dialogue_focus/`.

Regression: `tests/test_dialogue_focus.gd` (4 tests) pins content order,
availability, the overflow, Tab reaching the row, Shift+Tab walking back visible,
and Enter opening the epilogue. Suite **686/686 tests, 7,395 assertions, 56
scripts, exit 0**; both validators PASS; `--demo-dialogue` and `--demo-silence`
dialogue layout probes PASS at 1280x720 at both scales; `--creator-story-probe`
exit 0. Remaining limits are listed in the run report.

### Dialogue text scrolling and modality trace (2026-11-21)

PageUp/PageDown now scroll the conversation body by 90 % of a visible page,
clamped to `max_value - page`, without moving the focus ring (`da12abf`). The
handler sits in the existing dialogue branch after the modal and rebind returns,
so modal scrolling still wins and a rebind still captures the key. Shift+Tab
walks back through earlier available choices in content order and wraps.

Evidence: `tests/test_dialogue_focus.gd` is now 10 tests (page step, both clamps,
focus preservation, Tab/Enter after paging, manual offset persistence, modal
priority, rebind capture, reverse Tab and the wrap). Suite **692/692 tests,
7,444 assertions, 56 scripts, exit 0**; both validators PASS; `--demo-silence`
and `--demo-dialogue` dialogue layout probes PASS at 1280x720 at 100 % and
160 %; `--creator-story-probe` exit 0. Candidate `dialogue_page_2026-11-21`
(source `da12abf`, SHA-256
`29298fe2292dffe874fda8423e89c17e50be5cd2da8b52dda5838ff5cb020d74`, 110,686,664
bytes, clean tree) showed page down/up, top and bottom clamps, Enter after
paging, reverse Tab and the wrap natively at both scales.

Modality trace (behaviour unchanged): `DialoguePanel` and its dim measure 0x0, so
the dim never draws or blocks, and HUD controls outside the framed panel stay
mouse-live. Arrows can focus disabled choice rows and reach HUD buttons. Party,
Sheet, Inventory, Journal and Save open panels over the conversation; Pause ends
it and autosaves (existing pause handler). Movement and turn buttons fire but
`Game` returns early outside explore mode, so world state is unchanged. The
policy the code implies is full modality for world actions with read-only panels
allowed on top; the 0x0 dim and arrow focus were closed the same day (below).
Limits are in `builds/qa/runs/2026-11-21_dialogue_page/report.md`.

### Dialogue geometry and input policy (closed, 2026-11-21)

The overlay root and its dim now fill the viewport, the dim is visual only, and
the framed panel stays at the left edge so the read-only HUD column is never
covered. The root and dim ignore the mouse pick: Party, Sheet, Inventory,
Journal, Save and Pause stay clickable, while the framed panel keeps its own
clicks and the world action grid stays behind it (and remains mode-guarded).
Arrow keys now cycle available choices only (Left/Up backward, Right/Down
forward, wrapping); Tab/Shift+Tab, PageUp/PageDown, Enter activation, modal
priority and rebind capture are unchanged. Pause keeps its existing meaning:
during a conversation it ends it and autosaves.

Policy while a conversation is open:

- Keyboard: Tab/Shift+Tab and arrows move through available choices;
  PageUp/PageDown scroll the body 90 % of a page; Enter/Space activate the
  focused choice; a rebind capture consumes the key; an open modal wins.
- Mouse: wheel and scrollbar scroll the body; the framed panel consumes its own
  clicks (disabled rows still show their reason); the HUD column and Pause remain
  clickable; world action buttons are covered by the panel and mode-guarded.

Tests: `tests/test_dialogue_focus.gd` is 12 tests, adding viewport geometry (root,
dim, both ignoring the mouse pick, panel clear of the HUD column) and directional
cycling (skip unavailable, stay inside, wrap). Suite **694/694 tests, 7,485
assertions, 56 scripts, exit 0**; both validators PASS; `--demo-silence` and
`--demo-dialogue` dialogue probes PASS at 1280x720 at 100 % and 160 %;
`--creator-story-probe` exit 0.

Candidate `dialogue_geometry_2026-11-21b` (source `263e2e0`, SHA-256
`94af082ed7b6f679c6e5a13270e3d91b81630a4819958b1a55d17f27a69afd55`, 110,687,000
bytes, clean tree): native at 100 % and 160 % shows the full-screen dimmed
backdrop, the panel left of the HUD, Tab reaching the epilogue, arrows skipping
unavailable rows, PageDown/PageUp scrolling without moving the ring, Enter
opening `epilogue_silent`, Party opening over the conversation, and Pause ending
it. The earlier `dialogue_geometry_2026-11-21` build used PASS on the root and is
superseded.

Limits: QA-seeded state; native only at 1280x720, 100 %/160 %; HUD panels are
mouse-only during a conversation (Tab and arrows are confined to choices); the
panel still clips the first glyph of the gold readout; the dim is visual only, so
world-action safety rests on panel coverage plus the explore-mode guards; paging
can leave the focused row off-screen until the next focus move; Home/End are not
bound.

### Dialogue header clearance and focus return (closed, 2026-11-21)

The framed panel now starts below the measured HUD header instead of at 16,16.
At 1280x720 with normal readouts it keeps its 860x600 size and 800x556 body at
both text scales. The header is not fixed-height: ten-digit gold and seed values
at 160 % squeeze the location title onto more lines (header 63 -> 107 px), so the
panel follows the header's resize, moving down and shrinking only as much as the
bottom margin requires (589 px at the stress case). Gold, seed and Pause are
never covered.

Closing a HUD panel opened during a conversation now returns the ring to the
dialogue control that had it before the click, instead of leaving it on the HUD
button. If that control was rebuilt away, focus falls back to the first available
choice, then to "Leave conversation". Exploration keeps returning to its opener,
nested modals keep carrying the original opener, and a freed opener is guarded.

Tests: `tests/test_dialogue_focus.gd` is 17 tests (5 new: header clearance with
long readouts at 1.0 and 1.6, focus return to the choice, fallback after a
dialogue rebuild, exploration opener unchanged, and C/I/J/Tab opening no HUD
panel during dialogue). Suite **699/699 tests, 7,550 assertions, exit 0**; both
validators PASS; `--demo-silence` and `--demo-dialogue` dialogue probes PASS at
1280x720 at 100 % and 160 %.

Candidate `dialogue_header_2026-11-21` (source `7d1729f`, SHA-256
`1796fb2a55387d5b56313a007599174820151797445197d86605ff4ae5e81bb9`, 110,689,192
bytes, clean tree): native at 100 % and 160 % shows the whole header (gold, seed,
Pause) above the panel; Tab focuses a choice, clicking Party opens it, Escape
closes it and returns the ring to that choice, and Pause still ends the
conversation. The native Enter after that choice lands back on the root page
because the authored `crossing` node has `next: root`; that is content behavior,
not a focus failure.

Deferred: keyboard access to the HUD panels during dialogue. C/I/J remain blocked
by the exploration explore-mode guard, Tab stays reserved for dialogue focus,
Esc ends the conversation, and Save has no key binding at all. This batch did not
add or enable shortcuts.

Limits: long readouts at 160 % shrink the panel to 589 px (one choice row less
visible; all 13 remain reachable by scroll/paging); native evidence is 1280x720
at 100 %/160 % only; state is QA-seeded.

### Corrections to this refresh

- **Journal wheel scrolling is verified.** `builds/qa/runs/2026-11-20_modal/report.md`
  records OS-level wheel input over a 70-question `qa_journal_overflow` user
  fixture (shipped content untouched) at 100 % and 160 %: questions 09-18 then
  back at 100 %, 06-13 then back at 160 %. The journal acceptance's "not scrolled
  by input" limit was superseded the same day by that native pass; this refresh
  repeated the older line. The Journal item is now closed without that residual.
- **Oversized-control clipping is conditional**, not a reproduced defect: no
  shipped example exists at either supported scale.
- **The two content warnings are restored** above, with proposed wording; neither
  is implemented.
- The removed Journal gap is replaced by the genuinely open input gap: Enter
  activation of a focused modal button is native-only, with no unit test. This
  refresh had also carried a withdrawn Shift+Tab note; `2026-11-20_scrollkeys/
  assessment.md` records Shift+Tab wrapping Close -> Return to main menu ->
  Settings natively at 100 % and 160 %, so that item is closed too.


### Final candidate acceptance scope (2026-11-21; evidence review)

Candidate `dialogue_header_2026-11-21` was checked against stored evidence, not
rerun. `BUILD.txt` records source `7d1729f`, 0 worktree entries and 0 untracked
files; the executable hashes to
`1796fb2a55387d5b56313a007599174820151797445197d86605ff4ae5e81bb9` and
110,689,192 bytes, matching `BUILD.txt`. That source commit is an ancestor of
HEAD `9b73efe` (docs-only closure); the tree is clean. Reviewed: `report.md` and 11 screenshots in
`builds/qa/runs/2026-11-21_dialogue_header/` (5 at 100 %, 6 at 160 %).

| Check | 100 % | 160 % | Result |
| --- | --- | --- | --- |
| Header (gold, seed, Pause) above the panel | yes | yes | pass |
| Tab moves the ring to a choice | yes | yes | pass |
| Party opens over the conversation | yes | yes | pass |
| Escape returns to the conversation | equals the choice capture | ring visible on the choice | indicated at 100 %, visible at 160 % |
| Pause ends the conversation | not captured | yes | pass at 160 % only |
| Panel keeps its normal size | visual only | visual only | tests measure 860x600 |
| Enter after the focused choice | root page | root page | content loop (`crossing` has `next: root`), not a focus check |

Unverified for this candidate: native long gold/seed readouts (test-only);
native C/I/J/Tab behavior (unit test here, native trace on
`dialogue_geometry_2026-11-21b`); nested-modal native run; Inventory, Journal and
Save panels native; Pause at 100 %; window sizes other than 1280x720; a fresh
rerun or archived driver stdout. At 100 % no focus ring is visible in the
captures (`open.png` equals `after_enter.png`; `choice.png` equals
`party_closed.png`), so focus return there is inferred rather than seen.

Automated evidence for the same source: 17/17 dialogue tests (214 assertions),
699/699 suite (7,550 assertions), both validators PASS, both dialogue probes PASS
at 1280x720 at 100 % and 160 %.
## Dialogue HUD shortcuts — candidate `dialogue_hud_2026-11-21` (2026-11-21)

**Scope.** Sheet (C), Inventory (I) and Journal (J) open during dialogue when no
modal is open. Routing sits after rebind capture and modal priority; dialogue
Page/arrow/Tab handling stays ahead of it; Enter, Escape and Pause are reserved
so a rebound shortcut cannot steal activation or dismissal. Tab continues to
cycle choices. `FOCUS_ACCESSIBILITY` controls are excluded from the modal focus
walk because the new panels exposed controls that cannot be manually focused
without a screen reader.

**Automated.** `tests/test_dialogue_focus.gd`: **23/23, 283 assertions** (six new
cases: each panel opens with focus contained, Escape returns to the prior choice,
Escape with no panel ends the conversation, rebind capture wins, an open modal
keeps priority, and combat/creator do not open HUD panels). Suite **705/705
tests, 7,619 assertions, 56 scripts, exit 0**; both validators PASS; both dialogue
layout probes PASS at 1280x720 at 100 % and 160 % (30 and 22 controls, 0 failures).

**Candidate.** `dialogue_hud_2026-11-21` from clean commit `77f266d`, 0 worktree
entries and 0 untracked files: 110,689,720 bytes, SHA-256
`fa3ff0244a8cfe545b26211c7d1759a7af3dc1f18718167c4084647390f1ac71`. Its own
campaign list and both validators pass.

**Native acceptance.** `acceptance.log`: **19 checks, 0 failures**, hash recorded
at both ends and unchanged. At 1280x720, client text 100 % and 160 %, real OS
input, campaign `ashwick_ferry` with the QA-only silence seed:

| Check | 100 % | 160 % |
| --- | --- | --- |
| C opens Party & Character Sheet | pass | pass |
| I opens Inventory & Equipment | pass | pass |
| J opens Journal | pass | pass |
| Escape closes each; ring returns to the prior choice | pass | pass |
| Tab focuses a choice first | pass | pass |
| Escape after panels ends the conversation | pass | pass |

Every `*_closed.png` is byte-identical to the corresponding `choice.png`; every
panel-open frame differs. Evidence: `builds/qa/runs/2026-11-21_dialogue_hud_shortcuts/`.

**Limits.** Native state is seeded with `--demo-silence`, not a full playthrough;
1280x720 on Windows only; no other window size or OS scaling; one Tab inside each
panel, with only Inventory visibly moving focus; no human playtest. Focus return
is pixel equality plus unit-tested ownership, because the native harness cannot
read the focus owner. Save has no shortcut, and gamepad/controller behavior is
unchanged.

## Modal held-key repeat — candidate `modal_held_repeat_2026-11-21` (2026-11-21)

Status: implemented and automated-verified. Native held-repeat acceptance is
**pending** (procedure at the end of this entry), so the task is **not fully
accepted**. The 32-check result below stands as recorded and is limited to
single presses, hold/release and clamping.

Modal body scroll keys now repeat while held. Eight new synthetic `echo` tests in
`tests/test_modal_focus.gd` (42 tests total) cover PageUp/PageDown and both
arrows repeating, clamping at top and bottom, and never moving the ring; a
focused TextEdit keeping its own page keys; echoes left alone without a modal,
during rebind capture, and when focus is outside the modal; and non-scroll echoes
neither claimed by the body nor turning into repeated activation or dismissal.

| Check | Result |
| --- | --- |
| `tests/test_modal_focus.gd` | 42 tests, 8 new |
| Full suite | **713/713 tests, 7,654 assertions, 56 scripts, exit 0** |
| `--validate-campaigns` | PASS |
| `--validate-diagnostics` | PASS (`[]`) |
| Dialogue layout probes, 1280x720 | PASS at 100 % (30/22 controls) and 160 % (30/22 controls) |

Candidate `builds/qa/candidates/modal_held_repeat_2026-11-21/`: source
`fa349e4`, clean tree, 0 worktree entries, 0 untracked files, 110,689,608 bytes,
SHA-256 `dfc62dc84a2750330bb28af81fe12ca9123f8802bfa17f7eaacd1e5ec92f5878`,
unchanged before and after the native runs.

Native: `builds/qa/runs/2026-11-21_modal_held_key_repeat/acceptance.log` — 32
checks, 0 failures, hash-bound at both ends, Settings (`ravenloft_demo`,
`--demo`) and Journal (`ashwick_ferry`, `--demo-silence`) at 1280x720, 100 % and
160 %, OS-level input. PageDown scrolls; PageUp returns to the exact top frame; a
held Down equals two discrete Downs; nothing moves after a hold or a discrete
press is released (800 ms); PageDown clamps at the end. Frames are compared by
pixel, because two captures of an identical framebuffer can differ in PNG bytes.

**Verification gap.** Windows does not auto-repeat injected `keybd_event` input: a
1.5 s hold produced the frame of exactly one press, and nothing moved afterwards.
Native evidence therefore covers hold, release and single press only; repeated
movement rests on the synthetic echo tests. Focus is visually unchanged (the ring
stays on "Close (Esc)"), but the harness cannot read the focus owner, so ownership
is the tests' claim.

Limits: 1280x720 on Windows only, no other window size or OS display scaling; the
demo journal does not overflow, so the Journal check uses the Ashwick silence
seed; `tests/test_modal_focus.gd` alone is 40/42 with two isolation failures that
also fail at `014f3b8` and pass in suite order; no human playtest; held Tab's
repeated traversal is Godot's existing behavior and was left alone.

### Pending manual held-key acceptance

Implemented and automated-verified is not the same as accepted. The 32 native
checks above show a single press, hold/release and clamping only, because injected
`keybd_event` input does not auto-repeat on Windows; no frame shows several
movements during one hold. Injected repeated presses and synthetic echo events are
**not** accepted in place of that evidence.

Run this against candidate `modal_held_repeat_2026-11-21` only:
`RavenloftFoundationEdit.exe`, SHA-256
`dfc62dc84a2750330bb28af81fe12ca9123f8802bfa17f7eaacd1e5ec92f5878`, built from
source `fa349e4`. Do not rebuild or export it: a new executable invalidates the
hash binding.

Environment: Windows 10 (10.0.19045.6466), 1280x720 client, physical keyboard.

1. Settings: `RavenloftFoundationEdit.exe -- --demo --text-scale=1.0`, then
   Escape and the Settings row (or Tab four times, then Enter). Journal:
   `-- --campaign=ashwick_ferry --demo-silence --text-scale=1.0`, then J. Repeat
   both launches with `--text-scale=1.6` - four runs in total.
2. Click the window header once so it holds the foreground, and confirm the panel
   opens with the ring on "Close (Esc)".
3. Hold PageDown for about two seconds: the list must move several times during
   one hold and stop at the end while the key is still held.
4. Hold PageUp the same way: several movements back, stopping at the top.
5. Hold Down, then Up, about two seconds each: continuous line-by-line movement,
   clamped at both ends.
6. Release each key and wait about two seconds: no further movement.
7. Confirm the focus ring stays on "Close (Esc)" before, during and after each
   hold; a photo of each state is enough.
8. Record the panel, text scale, what moved, where it stopped, and whether
   anything moved after release. One movement per hold means the physical repeat
   path is still unproven.

The status stays pending until a human operator has recorded all four runs; no
operator has run it, and the automated session could not produce physical key
repeats.


### Creature soft cover on ranged attacks (2026-11-21)

A creature standing on the line now gives the target +4 AC against ranged,
thrown and ranged touch attacks. The grid uses the printed method rather than a
centre-to-centre line: each of the attacker's four corners is tried, and cover
exists only when every corner still has a line to a corner of the target's
square that crosses another creature's square (PHB p.151; "Soft Cover", p.152).
The test that the existing LOS code would have suggested is wrong on this grid:
attacker (0,0), target (3,3) and a creature at (2,3) - the centre line visits
(1,1), (2,2), (3,3) and never the creature, while the corner line (1,0)->(3,4)
passes through it. Centre-to-centre both misses cover the rule grants and counts
squares a line only grazes; no attack, log line or panel reads it.

Corrected expectation: Precise Shot removes the -4 into-melee penalty and
nothing else. Its test now asserts `into_melee_penalty == 0` and `cover == 4` in
the same shot. Improved Precise Shot ignores cover but needs BAB +11, so no
supported feat suppresses it.

Tests: **731/731 tests, 7,700 assertions, 57 scripts, exit 0**. The new
`tests/test_cover_geometry.gd` (13 tests) pins every geometry example: a body
between attacker and target, a body off the line, a body beside the attacker, the
corner-versus-centre counterexample above, one clear corner shooting past a body
behind the target, the attacker's and target's own squares, no stacking, a body
at the target's shoulder, and the edge/corner rules of `cells_crossed`.
`tests/test_ranged_melee.gd` gains the crossbow shot, the thrown dagger, the
ranged touch spell, the touch-AC arithmetic in `Rules.attack`, and the inspect
panel's shooter line through `CombatScreen.cover_summary`.

Candidate `creature_cover_2026-11-21` (source `4e56d1e`, clean tree,
110,693,592 bytes, SHA-256
`3045596184a265577d3fef325476c2840ded5219ce5ed728470cea382b974a39`): its own
`--validate-campaigns` and `--validate-diagnostics` PASS; `--demo-inspect
--inspect-probe` PASS (`PROBE RESULT PASS scenario=inspect`); `--layout-probe`
for the inspect modal and the dialogue PASS at 1280x720 at 100 % and 160 %
(27 and 22 controls, 0 failures; captures under
`builds/qa/runs/2026-11-21_creature_cover/`).

Limits: the inspect panel's cover clause is asserted through the panel's own
text function plus the resolver-parity test, not rendered in a windowed probe -
the demo fixtures have no creature in the shooting line, so no capture shows the
clause, and the panel was not viewed. Walls, low walls, reach-melee cover,
big-creature cover and concealment stay unmodelled (ADAPTATION_LOG 19d-19f).
Native input was not exercised because no binding or focus behaviour changed.

Correction (later the same day): the clause is now rendered and asserted by the
`--demo-cover --cover-probe` fixture at 100 % and 160 %, in source and in the
exported candidate. See the cover-clause section at the end of this file.


### Cover clause in the enemy inspector (2026-11-21)

The inspector's cover clause previously had no scenario that displayed it. The
new QA fixture `--demo-cover` places the shooter at (1,2), an ally at (3,2) and
the target at (5,2) on the 9x5 `qa_victory` board, then re-runs the real
initiative path until the shooter acts first; `Encounter.creature_cover` reads 4
(`QA COVER READY: shooter_first=true cover=4`). The new `--cover-probe` opens the
enemy panel through its row button and checks, on the rendered controls: the
clause text; normal AC = `Rules.armor_class` + 4; touch AC = `Rules.touch_ac` +
4; that the two differ (the fixture has natural armor); that the clause label
wraps (`AUTOWRAP_WORD_SMART`), is allocated its full minimum width and height,
and lies inside the panel and the client. It then attacks once and requires the
roll's `target_ac` to equal the panel's number with `cover == 4`; the logged
line read `d20(14)+4 = 18 vs AC 15`, so the +4 is in the roll the panel
described.

Evidence, source `e64a6c9` (731/731 tests, 7,704 assertions, 57 scripts, exit 0;
both validators PASS) and exported candidate
`creature_cover_inspector_2026-11-21` (clean tree, 110,698,344 bytes, SHA-256
`b5b1f67403c70472fd290cbb01c08816cc333d9d8a6f105facc8377824c81c89`):

| Run | 100 % | 160 % |
| --- | --- | --- |
| `--demo-cover --cover-probe`, source | PASS, 23 checks | PASS, 23 checks |
| `--demo-cover --layout-probe --layout-scenario=cover`, source | PASS, 23 controls, 0 failures | PASS, 23 controls, 0 failures |
| `--cover-probe` in the candidate | PASS | PASS |
| `--layout-scenario=cover` in the candidate | PASS, 23 controls, 0 failures | PASS, 23 controls, 0 failures |
| candidate `--validate-campaigns` / `--validate-diagnostics` | PASS | PASS |

Captures: `builds/qa/runs/2026-11-21_cover_probe/` (`layout_100`,
`layout_160`, `cand_layout_100`, `cand_layout_160`, and the probe shots).

Rules code is unchanged in this batch: no test exposed a defect, so only the QA
fixture and probe were added.

Limits: 1280x720 on this Windows desktop at 100 %/160 % only; the fixture is a
QA encounter (ids, display names and cells are QA values, while initiative stays
the real seeded path) and is not campaign content; the probe asserts wrapped-label
geometry and the panel's own text, not where the string breaks lines; the
captures were produced but not read by a human, and no manual testing was
performed or requested; native input was not exercised because no binding or
focus behaviour changed. The earlier candidate `creature_cover_2026-11-21`
(SHA-256 `3045596184a265577d3fef325476c2840ded5219ce5ed728470cea382b974a39`) is
preserved unchanged.


### Acceptance: creature soft cover and its inspector follow-up (2026-11-21)

**Status: accepted within the recorded scope.** Nothing was rebuilt and no check
was repeated for this entry; the evidence is what the two batches recorded.

Accepted behaviour: a creature whose square lies on the line gives the target +4
AC against ranged, thrown and ranged touch attacks, on normal and touch AC, using
the printed corner method (best attacker corner, interior crossings only). The
roll, the combat log and the enemy inspect panel read one value; the panel names
the shooter and states both ACs. Precise Shot removes only the into-melee -4.
`creature_cover_2026-11-21` (source `4e56d1e`, SHA-256 `30455961...`) is the rules
build; `creature_cover_inspector_2026-11-21` (source `e64a6c9`,
`b5b1f674...`) adds the deterministic `--demo-cover` fixture and `--cover-probe`
and supersedes it for judgment.

Not part of the accepted scope and still recorded as unmodelled: concealment,
hard cover from walls, low walls, reach-melee cover (PHB p.151 applies the ranged
method there), big-creature cover (no Large creature ships) and Improved Precise
Shot (BAB +11). Grid adaptations 19d-19f in ADAPTATION_LOG.md define the edge,
wall and reach boundaries.

Carried-forward limits: layout evidence is 1280x720 at 100 %/160 % on this
desktop; the cover clause was checked as wrapped-label geometry plus the panel's
own text, not by reading the PNGs; the QA fixture is not campaign content; native
input was not exercised; no manual test was performed. The two candidates' logs do
not record a start/end exe hash, so they read "no" in the table's bound column
even though each BUILD.txt pins the hash.


## Fighting defensively and total defense — candidate `defensive_actions_2026-11-21` (2026-11-21)

**Status: accepted within the recorded scope.** Source `e72a18a`, candidate
`defensive_actions_2026-11-21b` (clean tree, 110,708,296 bytes, SHA-256
`e53a62656eadb0765384898de492524e76dbc3f78c323ed5caa5454afd11fb25`). That binary
is superseded by `defensive_actions_2026-11-21c` (`58cb1a7`) because it contains
the stance-leak defect described at the end of this file; the behaviour below is
unchanged in `-c`.

Implemented: fighting defensively as a selected-then-committed stance and total
defense as its own standard action (PHB pp. 140, 143). A selection grants no
bonus, spends nothing, can be cleared, and can be replaced by total defense; the
commit point of a legal attack is the only activation path, so a refused or
cancelled attack leaves no bonus and writes no stance line. Once active the
stance applies -4 to every attack roll in the round (opportunity attacks
included) and +2 dodge AC (+3 with 5 Tumble ranks) to normal and touch AC,
cannot be cancelled, and ends at the start of the character's next turn. It
stacks with Combat Expertise (RC p. 54). Total defense grants +4 dodge AC (+6
with 5 Tumble ranks), forbids attacks and opportunity attacks on both the
provocation path and the movement reaction path, and refuses Combat Expertise
and an active fighting-defensively stance. The sidebar shows a checkbox with a
persistent status line plus a `Defend` action button, both gated on the standard
action, the lock and the standard-action cost.

Test evidence (`tests/test_defensive_actions.gd`, 17 tests, 72 assertions inside
the suite):

| Area | Covered by |
| --- | --- |
| Selection vs active, deselection | `test_a_selection_grants_nothing_and_can_be_cancelled`, `test_a_legal_attack_commits_the_stance` |
| Refused / out-of-reach / post-standard attack grants nothing | `test_a_refused_attack_grants_no_bonus`, `test_an_out_of_reach_attack_grants_no_bonus`, `test_a_selection_made_after_the_standard_action_is_refused` |
| Lock after commitment | `test_an_active_stance_cannot_be_cancelled` |
| Total defense: cost, replacement, move still allowed, exclusions | `test_total_defense_replaces_a_selection`, `test_total_defense_allows_a_move_afterwards`, `test_total_defense_refuses_combat_expertise` |
| Opportunity attacks | `test_total_defense_prevents_opportunity_attacks`, `test_an_active_stance_penalises_the_opportunity_attack` |
| Expiry | `test_the_stance_expires_at_the_start_of_the_next_turn` |
| Stacking with Combat Expertise, Tumble 5/4 ranks, dodge denial | `test_fighting_defensively_stacks_with_combat_expertise`, `test_tumble_ranks_replace_the_defensive_bonus`, `test_four_tumble_ranks_keep_the_base_bonus`, `test_the_dodge_bonus_is_denied_while_dexterity_is_denied` |
| Normal/touch/cover parity with the inspector | `test_normal_and_touch_ac_parity_and_cover_stacking` |

Runs at `a8c8189`: source suite 748 tests / 7,780 assertions / 58 scripts, exit
0; `--validate-campaigns` and `--validate-diagnostics` PASS in source and from
the candidate exe. Windowed `--demo-defensive --defensive-probe` at 1280x720 and
100 %/160 %: PASS (45 checks each) in source and in the candidate exe; captures in
`builds/qa/runs/2026-11-21_defensive_b/shots_100` and `shots_160`, plus the
source-run captures in `builds/qa/defensive_shots/`. The exe SHA-256 was
`e53a6265...11fb25` (110,708,296 bytes) immediately before the acceptance runs
and byte-identical afterwards, so this candidate is bound. Candidate
`defensive_actions_2026-11-21` (`a8c8189`, `f6bb00f2...d5de6b`) is preserved
unchanged and superseded: it predates the stance-specific refusal message and
the test that attacks the real target instead of an ally while total defense is
active.

Defect found and fixed inside the batch: the long `Total defense` label widened
the four-column action grid past the sidebar's 340 px minimum; the scroll
container's bars then oscillated and the frame queue stalled (GUT's footer never
advanced and the process eventually segfaulted). The control is labelled `Defend`
with the full name in its tooltip, and the sidebar now reserves its vertical
scrollbar (`SCROLL_MODE_SHOW_ALWAYS`) so a wrapped label cannot restart the loop;
the full suite and both probes pass at both scales afterwards.

Limits: 1280x720 at 100 %/160 % on this Windows desktop only; the fixture is a QA
encounter (ids, display names and cells are QA values while initiative stays the
seeded real path) and is not campaign content; no shipped character has Tumble
ranks, so the +3/+6 replacement is unit-tested with a fixture and unreachable in
content; the captures were produced but not read by a human, and no manual test
was performed or requested; native input was not exercised because no binding or
focus behaviour changed. Backups were not touched and the two cover candidates
are preserved unchanged.

## Combat-scope cleanup — defensive stances at encounter resolution (2026-11-21)

**Status: fixed and verified in source; no candidate was rebuilt.**

Reproduction (before the fix, source `73ed778`): `tests/test_combat_scope_cleanup.gd`
drove a real campaign game, real `Game` wrappers, the real resolution signal, the
real victory autosave and `Game.load_game`. Fighting defensively reported AC 19
against a base of 17 in exploration, total defense 21 against 17; both effects
were in `auto.json` and both came back after reload. The log is preserved at
`builds/qa/runs/2026-11-21_combat_scope/repro_failing_first.log` (4 tests, 77/90
assertions). Combat Expertise already passed: `Encounter.finish` cleared it
before the batch, which is what made the defensive gap a regression rather than
a pre-existing class.

Cause: `Encounter.finish` called `_clear_combat_expertise_states`, which removed
only the Combat Expertise effect and its two dictionaries. `fighting_defensively`
and `total_defense` are `Character` effects that `Character.to_dict` serializes,
and nothing removed them when the fight ended first. `finish` emits `changed`,
`Game._on_encounter_changed` runs `_resolve_encounter`, and the victory branch
autosaves — so the stale effect was written to disk.

Fix: the helper is now `Encounter._clear_combat_scope_states`. It clears
`combat_expertise_pending`, `combat_expertise_committed` and
`fight_defensively_selected`, and removes `combat_expertise`,
`fighting_defensively` and `total_defense` from every combatant. `finish` calls
it before emitting `changed`, so the resolution save cannot see a combat-scope
effect; `begin` calls it too, so a rechallenge starts clean. Unrelated lasting
effects (bless, mage armor, aid, conditions) are untouched.

Tests added:

| File | Test | Covers |
| --- | --- | --- |
| `tests/test_combat_scope_cleanup.gd` | `test_fighting_defensively_does_not_survive_victory_or_the_autosave` | selection → committed attack → ally's kill → base AC, no effect in the saved party entry, bless preserved, reload clean |
| same | `test_total_defense_does_not_survive_victory_or_the_autosave` | total defense active at victory, same four checks |
| same | `test_combat_expertise_still_does_not_survive_victory_or_the_autosave` | regression pin for the cleanup that already existed |
| same | `test_a_stance_is_cleared_on_defeat_and_no_autosave_is_written` | defeat exit: real damage plus the real end-turn `_check_end`, effect cleared, no save file |
| `tests/test_defensive_actions.gd` | `test_total_defense_does_not_remove_flanking_or_engagement` | a total-defending ally still flanks and still creates the shooter's -4 |
| same | `test_total_defense_refuses_a_pending_combat_expertise_choice` | pending choice refused without spending, preserved, then committed by the attack |

Results at the fix: focused 23 tests / 178 assertions pass; full suite **754
tests, 7,886 assertions, 59 scripts, exit 0**; `--validate-campaigns` and
`--validate-diagnostics` both PASS. Logs and the pre-fix reproduction are in
`builds/qa/runs/2026-11-21_combat_scope/`.

Limits: victory and defeat are the only exits the engine produces, and both are
covered; the defeat test applies damage through `Character.take_damage` and then
lets a real end turn reach `_check_end`, rather than waiting for an enemy attack
roll. The suite runs in the source tree under an isolated `APPDATA` profile and
writes only the `auto` slot, which it deletes before and after each test; no
player save directory was touched. No manual testing was performed or requested.

### Exported acceptance of `defensive_actions_2026-11-21c`

Exported from clean source `58cb1a7` (worktree entries 0, untracked 0), preset
`Windows Desktop`, 110,708,200 bytes, SHA-256
`f705ceda267440d8d1ecc73d06eaf745f0722ff9edcaced32664040e4faafd0f`. The same hash
and byte count were read immediately before the first check and again after the
last one, so this candidate is bound. `defensive_actions_2026-11-21b` is preserved
unchanged and marked superseded, with its stance-leak defect recorded in the
candidate table.

Exported-probe results (these are **not** cleanup evidence):

| Run | 100 % | 160 % |
| --- | --- | --- |
| `--validate-campaigns` / `--validate-diagnostics` from the exe | PASS | PASS |
| `--demo-defensive --defensive-probe` from the exe | PASS, 45 checks, 0 failures | PASS, 45 checks, 0 failures |

Captures: `builds/qa/runs/2026-11-21_defensive_c/shots_100` and `shots_160`;
logs sit beside them.

The probe drives the stance controls, the commitment, the lock, the expiry, the
total-defense switch and the AC numbers at both text scales. It never reaches
encounter resolution and never writes a save, so it says nothing about the
combat-scope cleanup. That cleanup remains **source-tested only**: the 754-test
suite above, including the four `test_combat_scope_cleanup.gd` tests that read
`auto.json` and reload it. The new candidate contains the fix because it was
exported from `58cb1a7`, but no exported run has exercised it.

Limits of this export: 1280x720 at 100 %/160 % on this desktop; the probe reads
control state and label text, not the rendered pixels beyond the saved captures;
no new probe was added for the cleanup and no manual test was run or requested;
backups were not touched.

### Closure of the defensive-actions and combat-scope work (2026-11-21)

Both are closed as accepted within their recorded limits. Fighting defensively and
total defense: accepted for the committed-stance scope on source `e72a18a`. The
combat-scope cleanup: accepted on source `58cb1a7` and pinned by the four
`test_combat_scope_cleanup.gd` tests; candidate `defensive_actions_2026-11-21c`
carries it and is bound by its own exported checks, which do not reach encounter
resolution or write a save. Nothing was rebuilt and no check was repeated for this
closure. No confirmed defect remains open in either area; the defect that was found
is fixed and recorded above, `-b` stays superseded, and the deferred features,
maintenance debt and evidence gaps in the ledgers earlier in this file are
unchanged. No manual testing was performed or requested, and backups were not
touched.


### Bull rush — player-initiated (2026-11-21)

Implemented the standard-action bull rush from `BULL_RUSH_PLAN.md` and the SRD
text it quotes (PHB p. 154), using the printed sequence: the entry into the
defender's space provokes from every threatening opponent including the defender,
both sides make opposed Strength checks with ±4 per size step and the defender's
stability bonus, a win pushes 5 ft plus 5 ft per full 5 points of excess while
moving with the defender, and a loss sends the rusher back with a prone fall when
that square is occupied. The user-visible entry points are the `Bull rush` action
button, its enemy-target mode and a Push 5 ft / Follow decision.

Tests were written and run failing first: all 24 failing on the absent
`bull_rush_active` entry point (`builds/qa/runs/2026-11-21_bull_rush/red_failing_first.log`).
The finished `tests/test_bull_rush.gd` holds 24 tests and 90 assertions, including
geometry tests for the push chain (corridor, wall, occupied square, map edge),
seeded-outcome tests for the check, push distance, movement cap and reactions,
failure and prone handling, the follow decision and its void guard, and a
cross-batch guard that a bull rush neither activates a stance nor commits Combat
Expertise. Full suite 778/778 tests, 7,976 assertions, 60 scripts, exit 0; both
validators PASS (`builds/qa/runs/2026-11-21_bull_rush/`).

Adaptations are recorded as 19i (blocked push and the no-space refusal) and 19j
(entry costs movement, atomic placement, grid diagonals). Limits: player-initiated
only, no charge form, no Improved Bull Rush, no 25 % redirect, no mounted or AI use,
no multi-square creatures, no terrain. The rules evidence here is source-tree only;
the exported candidate is checked for layout and validators, not for rules
outcomes, and no manual testing was performed or requested.


### Exported acceptance of `bull_rush_2026-11-21b` (2026-11-21)

Exported from clean source `9b0f046` (worktree entries 0, untracked 0), preset
`Windows Desktop`, 110,732,632 bytes, SHA-256
`33071751d7ba76773730416f2ab3ad711e09080392123ef6d44a8f9692a60e4c`. The same hash
and byte count were read before the first check and after the last one, so this
candidate is bound.

| Check | 100 % | 160 % |
| --- | --- | --- |
| `--validate-campaigns` / `--validate-diagnostics` from the exe | PASS | PASS |
| `--demo-combat --layout-probe --layout-scenario=combat` | PASS, 29 controls, 0 failures | PASS, 29 controls, 0 failures |

Logs: `builds/qa/runs/2026-11-21_bull_rush_export_b/`. This is **layout evidence
only**: the probe walks the combat screen's control tree for reachability and
clipping, and does not invoke a bull rush, a push, a check or a decision. Every
rules result above comes from the source suite.

Two corrections were made while producing this acceptance, and both are recorded
rather than quietly repaired:

- The first layout run of the day omitted `--demo-combat`, so the probe measured
  the menu (6 controls) and its PASS was meaningless for combat. That run is kept
  in `builds/qa/runs/2026-11-21_bull_rush_export/` and is not used as evidence.
- The corrected 160 % run failed six reachability checks in the combatant list.
  The cause was the probe, not the screen: a list row sits inside the list's
  `ScrollContainer` and the sidebar's `ScrollContainer`, and the probe scrolled
  only the innermost one, so it never brought the row into the client. It now
  walks every ancestor scroller (`9b0f046`). The screen itself needed a scroll and
  no layout change; the 100 % run was unaffected.

`bull_rush_2026-11-21` (`12ecb76`, `0946289c...`), the pre-fix export, is not
accepted: its only combat layout evidence was the meaningless 100 % run and the
failing 160 % one. It is preserved and marked superseded. No manual testing was
performed or requested, and backups were not touched.


### Closure of the bull rush batch (2026-11-21)

Closed as accepted within the recorded limits. Candidate `bull_rush_2026-11-21b`
(source `9b0f046`, 110,732,632 bytes, SHA-256 `33071751...92a60e4c`) is bound by
its own before/after hash and carries both exported validators and the combat
layout probe at 100 % and 160 % (29 controls, 0 failures each). The rules results
are the source suite at 778/778 tests, 7,976 assertions, 60 scripts, and
`tests/test_bull_rush.gd` at 24 tests / 90 assertions. The pre-fix export
`bull_rush_2026-11-21` stays preserved and unaccepted. Nothing was rebuilt and no
check was repeated for this closure. No confirmed defect was introduced by the
batch.

### Layout probe scroll coverage — what the fix does and does not change (2026-11-21)

`9b0f046` replaced the single-scroller lookup with a walk over every ancestor
`ScrollContainer`. The reachability rule itself is unchanged: an interactive
control must be inside the client, or inside a scroller that can bring it there.

What it changes: a control nested in two scrollers (a combatant-list row inside
the list's scroller inside the sidebar's) now gets both scrollers moved. Before
the fix only the innermost moved, so such a row was reported unreachable even
though the sidebar could reveal it.

What it cannot change: a PASS. The fix only adds scroll attempts for controls
that were already outside the client; the set of checked controls and the
non-wrapping-label clipping check are untouched. A control that passed before
still passes. In the other direction, an earlier FAIL of this shape may have been
a probe artifact rather than a layout fault.

Consequences for earlier conclusions:

- The 32/32 layout matrix and the per-candidate 100 %/160 % results keep their
  PASS status. Their combat entries, however, were weaker evidence than recorded:
  at 160 % the combatant list sits below the fold and its rows were only
  reachability-checked through the inner scroller, so the matrix did not actually
  prove that those rows could be brought into view. That is an evidence gap in
  those rows, not a defect: the current build passes the corrected probe at both
  scales (29 controls, 0 failures).
- No earlier documented layout failure is currently attributed to this cause. The
  one earlier probe false failure on record (a `fit_content` journal label taller
  than its viewport, `2026-11-20`) had a different cause and was fixed at the time.
- The fix cannot retroactively certify old binaries: none of the archived
  candidates was re-run, and the corrected coverage applies to the current build
  and to future ones.


## Resolution and action smoke - candidate `resolution_smoke_2026-11-21a` (2026-11-21)

One headless application flag, `--resolution-smoke=<profile>`, plays the QA victory
encounter through the real `Game` wrappers and then checks the packaged behaviour
the source suite had been proving alone. It adds no play, no content, no UI and no
save-schema change: the only source edit is the flag, its smoke, and its helpers in
`src/main.gd`.

### What the flag does

1. Refuses to run unless `<profile>` exists, contains Godot's `user://` directory,
   and is not inside the platform's roaming app-data folder. All three checks run
   before the first save read or write, so a mistyped profile cannot reach a
   player's save directory.
2. Starts the demo campaign with `kaelen` and `ysolde`, opens `qa_victory`, and
   places the duel fixture the source tests use: the zombie stationary and
   adjacent at (3,2), the fighter at (2,2), the ally at (6,3), `bless` on the
   fighter. The seed is chosen by trying 7301..7340 until the bull rush check is
   won, because the follow only exists after a won check; the winning run is then
   deterministic (seed 7302 in every recorded run).
3. Takes the fighter's turn and calls `Game.combat_bull_rush(index)` followed
   immediately by `Game.combat_resolve_bull_rush(true)` - the pre-decided follow,
   through the same wrappers the combat screen calls.
4. Passes the turn, takes `Game.combat_total_defense()` on the fighter's next turn,
   and has the ally's `magic_missile` drop the zombie, so the fight is won while a
   combat-scope effect is live.
5. Asserts the stance effects are gone in memory, absent from `auto.json`, and
   absent after `Game.load_game("auto")`; base AC is restored after the fight and
   in the reloaded state; `bless` survives all three; the defender moved exactly
   the printed push distance (5 ft plus 5 ft per full 5 points of excess) and the
   rusher ended in the vacated square, with both cells preserved through
   resolution. 32 checks, exit 0 only if every check passes.

The entry point is `_resolution_smoke_probe` so the existing guard that only
probes may call `SaveSystem.delete_save_everywhere` still holds; that call removes
the `auto` slot of the isolated profile only.

### Source evidence (before the export)

- `--resolution-smoke=<isolated profile>`: **PASS, 32 checks, 0 failures**, seed
  7302, push 10 ft, autosave read and reloaded.
- Missing profile directory: exit **1**, `RESOLUTION SMOKE FAIL isolation`, no
  save written.
- Profile inside the real roaming folder (a throwaway subdirectory under
  `%APPDATA%\Roaming`, created and removed for the check): exit **1**,
  `RESOLUTION SMOKE FAIL isolation`, no save written.
- Full suite: **778/778 tests, 7,979 assertions, 60 scripts**.
- `--validate-campaigns` and `--validate-diagnostics`: **PASS**.

### Exported evidence - `resolution_smoke_2026-11-21a`

Exported from clean source `de79c17` (worktree entries 0), preset `Windows
Desktop`, 110,740,824 bytes, SHA-256
`c1cff4cc4ad18aa3a9b40dfcb7d7c376726bf0909522ca463658c957035d9a75`. The same hash
was read before the first check and after the last one, and the two readings match.

| Check from the exe | Result |
| --- | --- |
| `--validate-campaigns` | PASS |
| `--validate-diagnostics` | PASS |
| `--resolution-smoke=<isolated profile>` | PASS, 32 checks, 0 failures, seed 7302 |
| `--resolution-smoke=<missing directory>` | exit 1, isolation refusal |

Logs: `builds/qa/runs/2026-11-21_resolution_smoke_export/` (exe) and
`builds/qa/runs/2026-11-21_resolution_smoke/` (source).

### Limits

- The smoke does **not** test the Push 5 ft / Follow decision UI. It calls
  `combat_bull_rush` and `combat_resolve_bull_rush(true)` directly, so the buttons,
  their labels and the pending-decision prompt remain covered only by the source
  suite's engine-level tests and the combat layout probe. No click is made.
- It is packaging evidence for resolution-time stance cleanup, base AC restoration,
  bull-rush movement and autosave reload. It is not a rules authority and does not
  replace the suite; it re-proves a narrow slice of it in the binary.
- No layout probe was rerun for this candidate: the flag adds no control and the
  diff touches no screen, so the accepted layout evidence for
  `bull_rush_2026-11-21b` is not affected.
- No manual testing was performed or requested, and backups were not touched.


### Closure of the resolution smoke (2026-11-21)

Closed as accepted within the limits recorded with it. Candidate
`resolution_smoke_2026-11-21a` (source `de79c17`, 110,740,824 bytes, SHA-256
`c1cff4cc4ad18aa3a9b40dfcb7d7c376726bf0909522ca463658c957035d9a75`) is bound by its
before/after hash. From the exe it ran both validators and
`--resolution-smoke` (PASS, 32 checks, seed 7302) and reproduced the
missing-profile refusal; the source tree holds the same 32 checks, the suite at
778/778 tests and 7,979 assertions, and both validators. Nothing was rebuilt and
no check was repeated for this closure.

What it does not cover, unchanged: the Push 5 ft / Follow decision UI (the smoke
calls the wrappers directly), the exported behaviour of any other combat action,
and any rules not asserted by its 32 checks.


## Campaign-creator keyboard reveal - candidate `creator_focus_2026-11-21a` (2026-11-21)

The creator's body scrolls (`ScrollContainer` without `follow_focus`), and the only
focus-changed hook ran the reveal walk for modals: `_reveal_modal_focus()` returned
early when `modal == null`. Tab outside a modal falls through to Godot's own
traversal, so a creator field below the fold took the focus ring while staying
off-screen. The fix routes non-modal focus changes on that screen through the same
walk (`_reveal_focused_control`, `8f625f4`); no second scroller, no traversal or
binding change, no content, save or rules change, and the modal path is the same
code it was.

### The probe, written first (red)

`--creator-focus-probe` builds the real creator from
`_demo_creator_interaction_draft()` at 1280x720 and runs at 100 % and 160 % text in
one invocation. It focuses every focusable control in tree order and asserts the
focused control's rect is enclosed by the viewport, then walks the real Tab order
with key events and its Shift+Tab reverse, then pins a modal opened over the
creator (Settings, whose list has its own scroller inside the shared body), and an
`OptionButton` popup.

Before the fix, `builds/qa/runs/2026-11-21_creator_focus/probe_before_fix.log`,
exit 1:

| Scale | Focusables | Outside the viewport |
| --- | --- | --- |
| 100 % | 182 | 98 |
| 160 % | 182 | 145 |

Sample failures: map cells at y = 698 (bottom 733 > 720), `Toggle wall / floor` at
y = 762, the keeper dropdown at y = 933, and at 160 % eight Tab and eight Shift+Tab
stops at y = 727/778. The pre-fix probe also recorded that Tab stops moving at the
description `TextEdit`, which consumes Tab for indentation: the order pinning
therefore uses a map-cell stretch, and the exhaustive pass covers every control.

### After the fix

- `--creator-focus-probe`: **PASS, failures 0**, 182/182 focusables focused, **0
  outside the viewport** at 100 % and at 160 %; 8 Tab stops, Shift+Tab exact
  reverse; dropdown focused and inside; popup opens with the creator body
  unchanged while open and after closing; Settings over the creator reveals its
  nested row, keeps focus inside, leaves the creator's scroll alone, and returns
  focus to its opener on close.
- Full suite: **778/778 tests, 7,981 assertions, 60 scripts**.
- `--validate-campaigns` and `--validate-diagnostics`: **PASS**.

Logs: `builds/qa/runs/2026-11-21_creator_focus/`.

### Exported evidence - `creator_focus_2026-11-21a`

Exported from clean source `8f625f4` (worktree entries 0), preset `Windows
Desktop`, 110,747,912 bytes, SHA-256
`53ae457ecfc54cfa5e4a57f226908574994d5c9fbbb7b264e79e42d1b0c0017b`. The same hash
was read before the first check and after the last one, and the readings match.

| Check from the exe | Result |
| --- | --- |
| `--validate-campaigns` | PASS |
| `--validate-diagnostics` | PASS |
| `--creator-focus-probe` | PASS, 0 failures, 0 outside at both scales |

Logs: `builds/qa/runs/2026-11-21_creator_focus_export/`.

### Limits

- The probe checks **control rects, not rendered pixels**. It cannot see a glyph
  clipped inside its own rect, two controls overlapping, a focus ring hidden
  behind another pane, or a frame the compositor never draws.
- Its exhaustive pass calls `grab_focus()` on each control - the same focus event a
  Tab press produces - while the order check uses real Tab and Shift+Tab key
  events; it does not prove the pointer path or that every Tab press in a player's
  hands reaches the same stops.
- `TextEdit` keeps Tab for indentation, so the Tab-order pin covers the map-cell
  stretch and the editor stops there. That is existing traversal behaviour,
  untouched here and outside this batch.
- No layout probe was rerun: the change moves scroll offsets only, and the
  creator's layout is unchanged.
- No manual testing was performed or requested, and backups were not touched.


### Closure of the creator focus fix (2026-11-21)

Closed as accepted within the limits recorded with it. Candidate
`creator_focus_2026-11-21a` (source `8f625f4`, 110,747,912 bytes, SHA-256
`53ae457ecfc54cfa5e4a57f226908574994d5c9fbbb7b264e79e42d1b0c0017b`) is bound by its
before/after hash. Its source probe passed with 0 of 182 focused controls outside
the viewport at 100 % and 160 %, the suite stood at 778/778 tests and 7,981
assertions, both validators passed, and the same probe passed from the exe.
Nothing was rebuilt and no check was repeated for this closure.

What it does not cover, unchanged: the probe checks control rects, not rendered
pixels; its exhaustive pass uses programmatic focus; the Tab order is pinned over
the map-cell stretch because the description editor keeps Tab for indentation; no
pointer path is exercised.

### Class progression tables (2026-11-21)

Batch 1 of the level-up plan adds `src/core/class_progression.gd` and
`tests/test_class_progression.gd`. Seventeen new tests cover the printed levels 3
and 4 rows for the five shipped classes, hit dice and skill points, feat slots,
spell slots and sorcerer spells known, the validator's rejection of a missing class
or level row, a backwards row, a wrong base attack or save, a bad hit die or skill
points and illegal spell data, the expected hit points of all five authored
characters, and the exact set of accepted authored inconsistencies (13). Tests were
written first and failed to compile before the class existed; the suite now stands
at 795/795 tests, 8,126 assertions and 61 scripts (baseline 778/778, 7,981, 60).
`--validate-campaigns` passes and `--validate-diagnostics` passes with `CLASS
PROGRESSION PASS | 13 accepted authored inconsistencies`; its JSON line is
unchanged. Nothing player-visible changed, so no candidate was exported, no manual
testing was performed or requested, and no backups were touched. A one-time
`--import` refresh was run so the new `class_name` entered the global class cache;
it changed no source.

### Batch 1 closure and batch 2 plan (2026-11-21)

Batch 1 (`level_tables`) is accepted within its limits without any check being
rebuilt or repeated. The closure uses the run already recorded with the batch:
commit `7391e39`, 795/795 tests, 8,126 assertions, 61 scripts,
`--validate-campaigns` PASS and `--validate-diagnostics` PASS with
`CLASS PROGRESSION PASS | 13 accepted authored inconsistencies`. The table remains
data only; no play path reads it.

The thirteen accepted inconsistencies now each have a recorded decision in
`LEVEL_UP_PLAN.md` 11.2: the four feat counts, the three bonus-slot readings and
Mira's known list are carried forward; the five skill findings (three ranks above
the level-3 cap and two point totals over the class budget) are repaired in one
separate content commit after batch 2, never silently. Level-up does not back-fill
feats or spells, adds exactly one 2nd-level spell to Mira, and never audits an
existing rank above the cap - it enforces the new caps only on points spent during
the step.

Batch 2 is planned in `LEVEL_UP_PLAN.md` 12: a pure `LevelUp` module with
`eligibility` at 6,000 XP, a read-only `preview`, and an atomic `apply` whose
refusals leave the character byte-identical; 35 failing-first tests with the red
evidence taken from the logged failure output, not the exit code, because GUT
9.6.1 exits 0 on an unparseable test file. Nothing was implemented.

### Level-up core (2026-11-21)

Batch 2 of the level-up plan adds `src/core/level_up.gd` and
`tests/test_level_up_core.gd` with 35 tests written before the module existed. The
red run's exit code was 0 even though the new file never compiled, so the recorded
evidence is the log:

    SCRIPT ERROR: Parse Error: Identifier "LevelUp" not declared in the current scope.
       at: GDScript::reload (res://tests/test_level_up_core.gd:32)
    ...
    Scripts              61
    Tests               795
    Passing Tests       795
    Asserts            8126

The file was not collected at all (61 scripts and the old totals unchanged), which
is exactly why the exit status cannot stand in for a failure. After implementation
the suite is 830/830 tests, 8,326 assertions and 62 scripts.
`--validate-campaigns` passes, and `--validate-diagnostics` passes with
`CLASS PROGRESSION PASS | 13 accepted authored inconsistencies` unchanged. A
one-time `--import` refresh was needed so the new `class_name` entered the global
class cache; it changed no source or content. Nothing in play calls `LevelUp` yet.
No candidate was exported because nothing player-visible changed, no manual testing
was performed or requested, and no backups were touched.

### Content repair: the five skill findings (2026-11-21)

The scheduled content commit rebuilt the two skill-point overspends and lowered
the three over-cap cross-class ranks, touching `skill_ranks` on aldric, mira and
ysolde only (8 lines inserted, 10 deleted). Before and after, with the points
charged:

| Character | Before | Spent | Budget | After | Spent |
| --- | --- | ---: | ---: | --- | ---: |
| aldric | heal 6, diplomacy 4, sense motive 4, listen 2, spot 2 | 26 | 12 | diplomacy 2, heal 4, sense motive 3 | 12 |
| mira | search 2, spot 2, listen 2, diplomacy 4 | 20 | 12 | bluff 2, diplomacy 3, search 1, spellcraft 2 | 12 |
| ysolde | search 4, spot 2, listen 2, diplomacy 2 | 20 | 30 | search 3, spot 2, listen 2, diplomacy 2 | 18 |

`test_class_progression.gd` now expects the eight inconsistencies that remain,
and `test_repaired_skill_blocks_fit_the_level_three_budget` recomputes each
block's spend and every rank against its cap. `test_level_up_core.gd` keeps the
"level-up never audits an existing rank" rule by injecting the over-cap rank in
memory, and `test_repaired_content_has_no_over_cap_rank_notice` pins that the
repaired content raises no notice.

Suite 832/832 tests, 8,350 assertions, 62 scripts (batch 2: 830 / 8,326 / 62).
`--validate-campaigns` PASS. `--validate-diagnostics` PASS with
`CLASS PROGRESSION PASS | 8 accepted authored inconsistencies`, down from 13.
Logs are in `builds/qa/runs/2026-11-21_content_repair/`. No engine line changed,
nothing player-visible in the UI moved, so no candidate was exported; no manual
testing was requested and no backups were touched.

### Level-up choices (2026-11-22)

Batch 3 adds `src/core/level_choices.gd` and `tests/test_level_choices.gd` with 18
tests written before the module existed: the 17 planned ones plus one for the empty
spell pool. Before the module existed the log, not the exit code, is the evidence:

    SCRIPT ERROR: Parse Error: Identifier "LevelChoices" not declared in the current scope.
       at: GDScript::reload (res://tests/test_level_choices.gd:57)

The file was never collected (`Scripts 62`, `Tests 832`, `Asserts 8350`, unchanged)
while GUT exited 0. The first green run was 849/850: the shared helper asserted the
character was unchanged after a successful `apply` as well, and now checks that
around `validate` always and around `apply` only for refusals.

Final: 850/850 tests, 8,562 assertions, 63 scripts. `--validate-campaigns` PASS;
`--validate-diagnostics` PASS with
`CLASS PROGRESSION PASS | 8 accepted authored inconsistencies`. `Feats.CATALOG`
gained the verified `fighter_bonus` flag, `LevelUp` gained the public `stage` seam
and `required_choices`, and `LevelUp.apply` is still the only path that changes a
character. Logs are in `builds/qa/runs/2026-11-22_level_choices/`. No candidate was
exported, no manual testing was requested and no backups were touched.
### Level-up screen (batch 4a, 2026-11-22)

21 tests written before the screen: `tests/test_level_up_screen.gd` (19) and
`tests/test_level_up_ui_surface.gd` (2). Red #1, quoted from the log because the exit
code is not the evidence:

    SCRIPT ERROR: Parse Error: Could not find type "LevelUpScreen" in the current scope.
       at: GDScript::reload (res://tests/test_level_up_screen.gd:54)
    [Failed]:  [""] expected to not equal [""]:  the screen file exists

The screen suite was never collected (`Scripts 64`, `Tests 852`, `Asserts 8566/8570`;
batch 3 recorded 63 / 850 / 8,562) and the surface suite ran and failed. The plan
predicted `Identifier "LevelUpScreen" not declared in the current scope`; the
engine's wording for a missing `class_name` is the text above, and that is what is
recorded. Red #2, once the screen existed, collected all 21 and failed four:

    [Failed]:  focus moved to the refused group
    [Failed]:  the focused row is fully inside the body
    [Failed]:  Expected [<null>] to be anything but NULL:  the panel exists
    [Failed]:  the refusal is the engine's

The first was a screen defect - a refusal on Confirm left focus on the footer because
the refused group's rows are on another step - and the modal now moves to that step
(`ADAPTATION_LOG.md` 55). The other three were the tests' own mistakes, corrected in
place: the reveal check included controls outside the scrolling body, the panel
lookup matched a default node name that carries a counter, and the stale-page refusal
is `feat_already_owned` rather than `already_level_4` because
`LevelChoices.validate` stages instead of applying.

Final: 871/871 tests, 9,236 assertions, 65 scripts. `--validate-campaigns` PASS;
`--validate-diagnostics` PASS with
`CLASS PROGRESSION PASS | 8 accepted authored inconsistencies`. Logs are in
`builds/qa/runs/2026-11-22_level_up_ui/`. No candidate was exported, no manual
testing was requested and no backups were touched.

The 160 % layout is not covered by a probe: the suite's control-rectangle tests pass
at 1.6, but no `--level-up-probe` run exists, so the screen has not been seen in a
window at that scale.

### Call-surface contract reconciled (2026-11-22)

`tests/test_level_up_ui_surface.gd` now holds three tests instead of two. The screen's
engine names are a closed list - `LevelChoices.choices`, `LevelChoices.validate`,
`LevelUp.preview`, `LevelUp.apply`, `LevelUp.ABILITIES` - the party sheet's is exactly
`LevelUp.eligibility`, and the staging guard is unchanged. The lists were taken from
the shipped source before they were written down, and they matched, so no wrapper API
was added to keep the plan's old "exactly three things" wording true. Run: 872/872
tests, 9,238 assertions, 65 scripts; `--validate-campaigns` PASS;
`--validate-diagnostics` PASS with
`CLASS PROGRESSION PASS | 8 accepted authored inconsistencies`. Logs are in
`builds/qa/runs/2026-11-22_level_up_contract/`.

### Refusal codes agree between validate and apply (2026-11-22)

Bounded repair of the defect batch 4a recorded as open: `LevelChoices.validate` now
asks `LevelUp.eligibility` first, as `LevelUp.apply` does, and only then stages the
draft. Four regression tests were written first in `tests/test_level_choices.gd`. Red,
22 tests collected with 18 passing and 4 failing:

    [Failed]:  validate refuses a character who is already 4th level
    [Failed]:  ["eligible"] expected to equal ["already_level_4"]:  validate reports the applied-already code
    [Failed]:  ["feat_already_owned"] expected to equal ["already_level_4"]:  both modules agree on the code
    [Failed]:  ["unknown_ability"] expected to equal ["xp_below_threshold"]:  an eligibility refusal outranks the choice checks
    SCRIPT ERROR: Invalid access to property or key 'commoner' on a base object of type 'Dictionary'.

Validation accepted a stale draft that `apply` refuses, and an untabled class crashed
inside `validate` rather than returning `class_not_tabled`; one eligibility test
removes both. Green: 41/41 in the two level-up files, 876/876 tests, 9,318 assertions,
65 scripts; `--validate-campaigns` PASS; `--validate-diagnostics` PASS with
`CLASS PROGRESSION PASS | 8 accepted authored inconsistencies`. Logs are in
`builds/qa/runs/2026-11-22_refusal_codes/`. The stale-screen UI test is unchanged and
still passes.

### Level-up probe (batch 4b-4c, planned 2026-11-22)

No run exists for the probe and none is claimed: `--level-up-probe` is not
implemented, so there is no `LEVEL UP PROBE` receipt line at either scale. Its red
will be that missing line; its green must be `_probe_finish("level_up")` at 1.0 and
at 1.6 with the C1-C9 checks, in the same log.
