# Project folder disk inventory (2026-11-24)

Read-only inventory. **Nothing was deleted, and no test, probe, validator, build or export was
run.** This note is phase 1 only; a deletion list is proposed separately and waits for explicit
approval. Sizes are decimal MB (10^6 bytes) unless marked; the workspace reports about 15.2 GiB
in Windows Explorer because 16.32 GB decimal is 15.2 GiB.

Baseline: `HEAD aceee52`, worktree clean except ` M README.md`. `git show --numstat HEAD` and
`git show --numstat 67377f6` contain only added lines (4/42/119 and 189/2), with no whole-file
line-ending rewrites. The README file hash and diff hash were re-verified before and after this
inventory and are unchanged.

The project folder is the workspace `C:\Users\Noot Goblin\Downloads\Ravenloft`; the Git
repository is `RL_Edit` inside it. 15,958 files and 5,496 directories were walked.

## Size of every top-level folder

### Workspace root

| Entry | Size | Classification |
| --- | --- | --- |
| `RL_Edit/` | 9,868.5 MB | Tracked source, content, tests and the Git repo, plus its QA/build/cache output |
| `workspace/` | 5,817.9 MB | Separate archive of old candidates, releases, references, snapshots and backups |
| `Project Ravenloft/` | 369.3 MB | Legacy project copy (188.5 MB) and the Godot 4.7.2 engine executable (180.9 MB) |
| `GodotEngine.epub` | 206.1 MB | Reference document |
| `RavenloftFoundation.exe` | 110.8 MB | Older exported executable with no `BUILD.txt`; unknown provenance |
| `builds/` | 1.4 MB | Small workspace-level build scratch |
| `edit_copy_audit/` | 0.25 MB | Audit notes |
| `.freebuff/` | under 0.1 MB | Tool metadata |

### `RL_Edit/` (the repository)

| Entry | Size | Classification |
| --- | --- | --- |
| `builds/` | 9,633.7 MB | Exported candidates, QA evidence and regenerable export cache |
| `.godot/` | 187.0 MB | Regenerable import cache |
| `.git/` | 42.0 MB | Git history and loose objects |
| `addons/` | 3.0 MB | Tracked third-party GUT |
| `assets/` | 2.5 MB | Tracked source assets |
| `docs/` | 1.8 MB | Tracked documentation |
| `src/` | 1.6 MB | Tracked source |
| `tests/` | 1.4 MB | Tracked tests |
| `content/` | 0.2 MB | Tracked content |
| `placeholder_art/`, `tools/`, `scenes/` | 0.2 MB combined | Tracked source |
| `RavenloftFoundationEdit/` | 0 bytes | Empty stray directory |

### `workspace/` (outside the repository)

| Entry | Size | Classification |
| --- | --- | --- |
| `candidates/` | 1,995.2 MB | Old exported candidate builds and their evidence |
| `archive/` | 1,621.0 MB | Read-only history; the workspace README says nothing is deleted there |
| `releases/` | 1,113.1 MB | Accepted, previously verified builds declared immutable |
| `references/` | 736.0 MB | 43 private D&D 3.5 PDFs and extractions; never redistributed |
| `snapshots/` | 151.7 MB | Recovery point (Git bundle, patch, untracked archive, player data) |
| `backups/` | 116.6 MB | Backups |
| `qa/` | 66.0 MB | Older QA runs |
| `restore_2026-11-21_ad922ba/` | 15.0 MB | Restore copy |
| `external-tools/` | 5.0 MB | Downloaded third-party packages |

## Largest 40 files and folders at any depth

Nested entries are listed as measured; a parent includes its children.

| # | Entry | Size | Classification |
| --- | --- | --- | --- |
| 1 | `RL_Edit/` | 9,868.5 MB | Mixed: tracked source plus generated output |
| 2 | `RL_Edit/builds/` | 9,633.7 MB | Mixed: candidates, QA evidence, cache |
| 3 | `RL_Edit/builds/qa/` | 9,630.9 MB | Mixed |
| 4 | `RL_Edit/builds/qa/candidates/` | 8,886.1 MB | Exported candidate builds |
| 5 | `workspace/` | 5,817.9 MB | Archive, releases, references, backups |
| 6 | `workspace/candidates/` | 1,995.2 MB | Old exported builds |
| 7 | `workspace/archive/` | 1,621.0 MB | Archive (read-only history) |
| 8 | `workspace/releases/` | 1,113.1 MB | Immutable accepted builds |
| 9 | `workspace/archive/2026-11-03_candidates_featskills/` | 991.0 MB | Archive |
| 10 | `workspace/references/` | 736.0 MB | Reference PDFs |
| 11 | `workspace/references/dnd35/` | 735.8 MB | Reference PDFs |
| 12 | `workspace/releases/windows_legacy_2026-11-05/` | 660.7 MB | Old release |
| 13 | `RL_Edit/builds/qa/runs/` | 387.4 MB | Preserved QA evidence (probe logs, layouts, screenshots) |
| 14 | `Project Ravenloft/` | 369.3 MB | Legacy project copy and engine |
| 15 | `workspace/archive/snapshots_2026-11-04/` | 241.5 MB | Archive |
| 16 | `workspace/archive/snapshots_2026-11-04/2026-11-04-closure-pre/` | 231.8 MB | Archive |
| 17 | `workspace/archive/2026-11-03_to_04_legacy/` | 226.1 MB | Archive |
| 18 | `RL_Edit/builds/qa/appdata_export/` | 212.5 MB | Regenerable export-template cache |
| 19 | `RL_Edit/builds/qa/appdata_export/Godot/` | 212.5 MB | Regenerable cache |
| 20 | `RL_Edit/builds/qa/appdata_export/Godot/export_templates/` | 212.4 MB | Regenerable cache |
| 21 | `RL_Edit/builds/qa/appdata_export/Godot/export_templates/4.7.2.stable/` | 212.4 MB | Regenerable cache |
| 22 | `GodotEngine.epub` | 206.1 MB | Reference document |
| 23 | `Project Ravenloft/ravenloft-foundation/` | 188.5 MB | Legacy project copy |
| 24 | `RL_Edit/.godot/` | 187.0 MB | Regenerable import cache |
| 25 | `RL_Edit/.godot/imported/` | 183.0 MB | Regenerable import cache |
| 26 | `Project Ravenloft/Godot_v4.7.2-stable_win64.exe` | 180.9 MB | Engine tool |
| 27 | `workspace/archive/2026-11-04_milestone/` | 159.2 MB | Archive |
| 28 | `workspace/archive/2026-11-04_milestone/ravenloft-milestone-qa/` | 159.2 MB | Archive |
| 29 | `workspace/snapshots/` | 151.7 MB | Recovery snapshot |
| 30 | `Project Ravenloft/ravenloft-foundation/workspace/` | 128.6 MB | Legacy project copy |
| 31 | `Project Ravenloft/ravenloft-foundation/workspace/qa/` | 128.5 MB | Legacy QA evidence |
| 32 | `workspace/candidates/foundation_contracts_candidate/` | 119.0 MB | Old exported build |
| 33 | `workspace/candidates/foundation_contracts_candidate/RavenloftFoundation.exe` | 119.0 MB | Old exported executable |
| 34 | `RL_Edit/builds/qa/candidates/package_diagnostics_2026-11-13/` | 117.7 MB | Candidate build |
| 35 | `RL_Edit/builds/qa/candidates/campaign_discovery_2026-11-13/` | 117.7 MB | Candidate build |
| 36 | `RL_Edit/builds/qa/candidates/encounter_resolution_2026-11-13/` | 117.7 MB | Candidate build |
| 37 | `workspace/releases/cleave_offturn_candidate/RavenloftFoundation.exe` | 117.4 MB | Old release executable |
| 38 | `workspace/releases/cleave_offturn_candidate/` | 117.4 MB | Old release |
| 39 | `Project Ravenloft/ravenloft-foundation/workspace/qa/journal_triage/` | 117.4 MB | Legacy QA evidence |
| 40 | `workspace/backups/2026-11-21_ad922ba/` | 116.6 MB | Backup; never delete |

## Exported candidate builds

`RL_Edit/builds/qa/candidates/` holds **81 directories, 8,886.1 MB**, and 80 executables (one
directory is empty). The current newest candidate is **`2026-11-24_aid_another`**, directory
mtime 2026-11-24 18:41, source `81a76e0bcece967df3106a04b72d34380eb0ebff`, executable
110,934,728 bytes, SHA-256
`90afb671831586c717f32106888c63e3f0da5f37e937e718c156708e524b40ca`. That matches its
`BUILD.txt` and the acceptance record in `b7c5bb9`; it is the only candidate with an
`acceptance/` directory. No open acceptance claim depends on an older candidate.

`BUILD.txt` exists for 79 directories. `ashwick_second_ring_2026-11-14` has none;
`profile_quest_final` is an empty stray directory. Older builds whose `BUILD.txt` predates the
`source_head` field record no source commit. "Named" is the count of exact candidate-name
occurrences across `docs/*.md`; zero means no acceptance record names it.

| Candidate | MB | Source | BUILD.txt | `acceptance/` | Named |
| --- | --- | --- | --- | --- | --- |
| 2026-11-23_batch6a_advancement | 110.8 | 9139136 | yes | no | 7 |
| 2026-11-23_batch7_weapon_specialization | 110.9 | 87da7ea | yes | no | 5 |
| 2026-11-23_batch7b_feat_display | 110.9 | 334da1d | yes | no | 5 |
| 2026-11-23_batch8a_grapple | 110.9 | 7ac30a2 | yes | no | 2 |
| 2026-11-23_batch8a_grapple_b | 110.9 | 6cf3f7f | yes | no | 2 |
| 2026-11-24_aid_another | 111.0 | 81a76e0 | yes | yes | 5 |
| 2026-11-24_aoo_helpless_a | 110.9 | 9265130 | yes | no | 0 |
| 2026-11-24_aoo_helpless_b | 110.9 | d14b7fc | yes | no | 5 |
| 2026-11-24_batch8a_acceptance | 110.9 | 33f2fe6 | yes | no | 6 |
| 2026-11-24_batch8a_acceptance_b | 110.9 | a71b942 | yes | no | 6 |
| 2026-11-24_batch8b1_acceptance_a | 110.9 | f236a4a | yes | no | 0 |
| 2026-11-24_batch8b1_acceptance_b | 110.9 | f236a4a | yes | no | 0 |
| 2026-11-24_batch8b1_acceptance_c | 110.9 | f149d1d | yes | no | 4 |
| 2026-11-24_combat_info_batch1 | 110.9 | bad3a05 | yes | no | 6 |
| 2026-11-24_combat_keyboard_a | 110.9 | 072c15b | yes | no | 6 |
| 2026-11-24_combat_log_focus_batch2 | 110.9 | 4de76f1 | yes | no | 6 |
| 2026-11-24_flanking_attacker_specific | 110.9 | 1e7dc4b | yes | no | 3 |
| 2026-11-24_into_melee_paralyzed | 110.9 | 4c42965 | yes | no | 6 |
| 2026-11-24_living_opponent_batch_a | 110.9 | 7547797 | yes | no | 9 |
| 2026-11-24_ranged_720_probe_a | 110.9 | 1a2a239 | yes | no | 4 |
| 2026-11-24_ranged_sneak_limit | 110.9 | 81b00f6 | yes | no | 4 |
| 2026-11-24_turn_undead_wrapper_a | 110.9 | 2240c88 | yes | no | 0 |
| 2026-11-24_turn_undead_wrapper_b | 110.9 | 5d0f54a | yes | no | 6 |
| account_decision_2026-11-14 | 110.6 | not recorded | yes | no | 7 |
| ashwick_second_ring_2026-11-14 | 113.6 | not recorded | no | no | 8 |
| bull_rush_2026-11-21 | 110.7 | 12ecb76 | yes | no | 11 |
| bull_rush_2026-11-21b | 110.7 | 9b0f046 | yes | no | 7 |
| campaign_discovery_2026-11-13 | 117.7 | not recorded | yes | no | 2 |
| campaign_list_2026-11-13 | 111.7 | not recorded | yes | no | 5 |
| cli_args_2026-11-14 | 110.6 | not recorded | yes | no | 4 |
| combat_casting_2026-11-13 | 110.5 | not recorded | yes | no | 3 |
| concentration_2026-11-13 | 110.5 | not recorded | yes | no | 3 |
| creator_focus_2026-11-21a | 110.7 | 8f625f4 | yes | no | 10 |
| creator_probe_2026-11-20 | 110.7 | 2dc61e1 | yes | no | 9 |
| creature_cover_2026-11-21 | 110.7 | 4e56d1e | yes | no | 7 |
| creature_cover_inspector_2026-11-21 | 110.7 | e64a6c9 | yes | no | 7 |
| defensive_actions_2026-11-21 | 110.7 | a8c8189 | yes | no | 17 |
| defensive_actions_2026-11-21b | 110.7 | e72a18a | yes | no | 4 |
| defensive_actions_2026-11-21c | 110.7 | 58cb1a7 | yes | no | 10 |
| dialogue_focus_2026-11-21 | 110.7 | 883c834 | yes | no | 3 |
| dialogue_focus_2026-11-21b | 110.7 | 01d1cfc | yes | no | 3 |
| dialogue_geometry_2026-11-21 | 110.7 | 01e7016 | yes | no | 5 |
| dialogue_geometry_2026-11-21b | 110.7 | 263e2e0 | yes | no | 4 |
| dialogue_header_2026-11-21 | 110.7 | 7d1729f | yes | no | 5 |
| dialogue_hud_2026-11-21 | 110.7 | 77f266d | yes | no | 3 |
| dialogue_page_2026-11-21 | 110.7 | da12abf | yes | no | 3 |
| edit_2026-11-09 | 110.5 | not recorded | yes | no | 0 |
| encounter_resolution_2026-11-13 | 117.7 | not recorded | yes | no | 2 |
| flat_footed_2026-11-13 | 110.5 | not recorded | yes | no | 3 |
| flat_footed_corrected_2026-11-13 | 110.5 | not recorded | yes | no | 4 |
| integration_2026-11-13 | 110.5 | not recorded | yes | no | 3 |
| interruption_2026-11-20 | 110.7 | dafacd8 | yes | no | 5 |
| intro_modal_2026-11-13 | 112.4 | not recorded | yes | no | 3 |
| journal_2026-11-20 | 110.7 | 3dc28cc | yes | no | 7 |
| level_up_ui_2026-11-22 | 110.8 | 84d8fb7 | yes | no | 9 |
| migration_2026-11-20 | 110.7 | 93e8199 | yes | no | 6 |
| modal_focus_2026-11-20 | 110.7 | 60c1221 | yes | no | 12 |
| modal_held_repeat_2026-11-21 | 110.7 | fa349e4 | yes | no | 4 |
| modal_pane_2026-11-20 | 110.7 | 1d89925 | yes | no | 5 |
| modal_scroll_2026-11-20 | 110.7 | 2b3ba36 | yes | no | 4 |
| nonlethal_2026-11-13 | 110.6 | not recorded | yes | no | 3 |
| package_diagnostics_2026-11-13 | 117.7 | not recorded | yes | no | 3 |
| party_layout_2026-11-13 | 111.9 | not recorded | yes | no | 4 |
| party_min_2026-11-14 | 110.6 | not recorded | yes | no | 2 |
| pattern_2026-11-20 | 110.7 | 437fa40 | yes | no | 7 |
| probe_2026-11-20 | 110.7 | 161ceb2 | yes | no | 12 |
| profile_quest_final | 0.0 | none | no | no | 0 |
| quest_log_idempotence_2026-11-13 | 110.7 | not recorded | yes | no | 4 |
| ranged_melee_2026-11-13 | 110.5 | not recorded | yes | no | 4 |
| ranged_windowed_2026-11-13 | 110.5 | not recorded | yes | no | 5 |
| recovery_2026-11-20 | 110.7 | accbc62 | yes | no | 5 |
| refusals_2026-11-20 | 110.7 | c3ede47 | yes | no | 6 |
| resolution_smoke_2026-11-21a | 110.7 | de79c17 | yes | no | 7 |
| save_compat_2026-11-13 | 110.7 | not recorded | yes | no | 4 |
| story_diagnostics_2026-11-13 | 111.4 | not recorded | yes | no | 4 |
| ui_scaling_2026-11-20 | 110.6 | a64eead | yes | no | 5 |
| ui_scaling_2026-11-20b | 110.6 | a64eead | yes | no | 5 |
| unarmed_2026-11-13 | 110.5 | not recorded | yes | no | 7 |
| unarmed_threat_2026-11-13 | 110.5 | not recorded | yes | no | 6 |
| weapon_state_2026-11-13 | 110.5 | not recorded | yes | no | 2 |
| weapons_2026-11-13 | 110.5 | not recorded | yes | no | 1 |

Some candidate directories also hold QA material — `SUPERSEDED.txt`, `godot.log`, `IDENTITY.txt`,
validation logs, campaign fixtures, run screenshots and `.import` sidecars. Those are evidence,
not just builds, so any executable-only deletion must leave every non-executable file in place.
There are 451 non-executable/non-text files in these directories.

## Preserved QA evidence (never delete)

- `RL_Edit/builds/qa/runs/` — 387.4 MB of probe logs, layout dumps and screenshots, one directory
  per run.
- `RL_Edit/builds/qa/snapshots/` — 65 MB of dated state snapshots.
- `RL_Edit/builds/qa/aid_another_red/` — the failing-first run, including 13/15 and 16-check
  superseded attempts.
- `RL_Edit/builds/qa/aid_another_green/` — focused, suite, probe, validator and layout logs.
- `RL_Edit/builds/qa/qa/` — 5.1 MB of older QA runs.
- `RL_Edit/builds/qa/repro/` — 7.0 MB of reproduction logs and profiles.
- Every red/green log and failing-first directory elsewhere under `builds/qa/`.

## Regenerable caches

- `RL_Edit/.godot/` — 187.0 MB, including `imported/` at 183.0 MB. Godot recreates it; the cost is
  a full asset reimport (project assets are 2.5 MB, but import is thousands of files) and loss of
  editor layout/state.
- `RL_Edit/builds/qa/appdata_export/` — 212.5 MB, a private `APPDATA` containing the Godot 4.7.2
  export templates. Recreated by downloading the templates again; only needed to export.

## Disposable worktrees and scratch

- `RL_Edit/builds/qa/rev_before/` — 9.5 MB stale revision-comparison copy, recorded in
  `PROGRAM_PROGRESS.md:2357` as not the current tree.
- `RL_Edit/builds/qa/tmp/` — 2.6 MB scratch logs and `appdata_*` fixtures.
- `RL_Edit/builds/builds/` — 1.0 MB accidental nested duplicate of QA scratch.
- `RL_Edit/RavenloftFoundationEdit/` — empty stray directory.

`RL_Edit/builds/qa/repro/` looks like scratch but is retained under QA evidence because its logs
document a reproduction; it is not proposed for deletion.

## Backups, archives and unknowns (never delete)

- `workspace/backups/` (116.6 MB), `workspace/restore_2026-11-21_ad922ba/` (15.0 MB),
  `workspace/snapshots/` (151.7 MB) and `workspace/archive/` (1,621.0 MB) are backups or
  read-only history. The workspace README says `archive/` is never deleted and `releases/` is
  immutable.
- `workspace/releases/` (1,113.1 MB) and `workspace/candidates/` (1,995.2 MB) are old exported
  builds in the separate archive; they are preserved rather than treated as this repository's
  candidates.
- `workspace/references/` (736.0 MB) holds private reference PDFs.
- `Project Ravenloft/` (369.3 MB) is a legacy copy and the engine executable; provenance is not
  fully documented, so it is unknown and preserved.
- Root `RavenloftFoundation.exe` (110.8 MB) has no `BUILD.txt`; unknown and preserved.

## Git object report

- `.git` is 42.0 MB.
- `git count-objects -vH`: **1,975 loose objects, 36.23 MiB; 0 packs, 0 packed size**.
- `git fsck --unreachable --no-reflogs` reports **85 unreachable entries**, including one commit,
  blobs and trees.
- `git gc` would pack the loose objects and, subject to normal expiry, drop unreachable ones. It
  would reclaim a modest amount — the whole loose store is 36 MiB and the repository is 42 MB —
  so it is not material to a 15.2 GiB folder. It was not run. Any approved gc should keep
  reachable history and not prune aggressively.

## Gitignored large files

`builds/` (line 5 of `.gitignore`) covers all candidates, QA runs and the export-template cache;
`.godot/` (line 2) covers the import cache. The ignore rules also cover `*.exe`, `*.pck`, `*.log`,
`*.pdf` and `*.zip` anywhere in the repository. The workspace-level
`RavenloftFoundation.exe`, `workspace/` and `Project Ravenloft/` are outside the repository and
are not tracked at all.

## Classification summary

- **Tracked source and content:** `RL_Edit/src`, `content`, `tests`, `docs`, `assets`,
  `addons`, `scenes`, `tools`, project files (about 10 MB).
- **Regenerable cache:** `.godot/` (187.0 MB) and `builds/qa/appdata_export/` (212.5 MB).
- **Exported candidate builds:** 81 directories, 8,886.1 MB; 80 executables totalling 8,856.2 MB,
  of which 79 older executables total 8,745.3 MB.
- **Preserved QA evidence:** `builds/qa/runs`, `snapshots`, `aid_another_red`,
  `aid_another_green`, `qa`, `repro` and the evidence files inside candidate directories.
- **Disposable worktrees/scratch:** `builds/qa/rev_before` (9.5 MB), `builds/qa/tmp` (2.6 MB),
  `builds/builds` (1.0 MB), empty `RavenloftFoundationEdit`.
- **Backups:** `workspace/backups`, `restore_2026-11-21_ad922ba`, `snapshots`, `archive`, and the
  immutable `workspace/releases`.
- **Unknown:** `Project Ravenloft/`, root `RavenloftFoundation.exe`, `workspace/references`
  (private reference material), and the legacy QA inside `Project Ravenloft`.

## Deletion status

No file or directory was deleted in phase 1. The proposed deletion list and its risks are given
separately and require explicit approval before any path is touched. No tests, probes,
validators, builds or exports were run for this inventory.
