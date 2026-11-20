# RL_Edit — editable copy

Independent working copy of the Ravenloft Foundation Godot project. It is a
local Git repository (baseline commit `a64eead`, one commit, no remote) and can
be edited freely; the original project was not modified.

**Active development authority (2026-11-14).** This copy is the tree that is
edited and verified. The Git-backed original at commit `1af0253` is preserved
read-only as history and is not the edit target; it lags this copy in source,
content and tests, and `workspace/README.md`'s statement that only the original
is edited is superseded by this paragraph. Do not apply changes back to the
original without explicit authorization.

- **Original:** `C:\Users\Noot Goblin\Downloads\Ravenloft\Project Ravenloft\ravenloft-foundation`
  at commit `1af025310957ec413ce1145ea3e96acaa3d7a291` (dirty: excluded
  `PROJECT_COMPENDIUM.md`, `PROJECT_SYNTHESIS.md`, `workspace/`).
- **This copy:** `C:\Users\Noot Goblin\Downloads\Ravenloft\RL_Edit`
- **Engine (read-only):** `..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe`
  (4.7.2.stable.official.ed1daf0bf). Tools accept `GODOT_EXE` to override.
- **Audit records:** `..\edit_copy_audit\` (source/copy manifests, exclusions,
  rename map, logs, verification).

## Exclusions

Not copied: `.git/`, `.godot/`, `builds/` and exported executables,
`.qa_ce_appdata/`, `.qa_*.png` plus `.import` sidecars, `qa_source*.log`,
`workspace/` (QA evidence), `docs/screenshots/`, player saves/settings
(they live in AppData), `PROJECT_COMPENDIUM.md`, `PROJECT_SYNTHESIS.md`, and
reference PDFs (not present in the project). All originals remain in place.

## Rename map

Only the root moved: `Project Ravenloft\ravenloft-foundation` → `RL_Edit`.
That is 79 → 48 characters for the root, and 145 → 114 for the longest
maintained file path (`content/campaigns/ravenloft_demo/dialogue/ashlyn_town_square.json`,
65 relative characters).

No individual file or directory was renamed. Area JSON names are a schema
contract (`areas/<area_id>.json`, enforced by `ContentDB._load_area_file`), and
other names are 65 characters or less at the new root, so renaming would break
stable IDs for no path-length gain. See `rename_map.txt` in the audit folder.

## Identity, saves and outputs

- `config/name` is `Ravenloft Foundation (Edit Copy)`; window title and export
  product name say "Edit Copy".
- `config/use_custom_user_dir=true` and
  `config/custom_user_dir_name="RavenloftFoundationEdit"` put `user://` at
  `C:\Users\Noot Goblin\AppData\Roaming\RavenloftFoundationEdit`, separate from
  the original's `Godot\app_userdata\Ravenloft Foundation` folder. Saves,
  settings, campaigns, playtests and test saves all go there.
- Export preset writes `builds/windows/RavenloftFoundationEdit.exe` (inside the
  copy). `tools/qa/build_candidate.sh` writes
  `builds/qa/candidates/<id>/`; `tools/qa/run_probe.sh` writes `builds/qa/runs/`.
  No tool writes to the original workspace.

## Verification (2026-11-09)

- Import (`--import`): exit 0; no missing-resource, script, or duplicate-UID
  errors.
- `--list-campaigns`: 3 campaigns; `--validate-campaigns` and
  `--validate-diagnostics` both PASS, exit 0.
- Full GUT suite: **352/352 tests, 4,697 assertions, 24 scripts, exit 0**
  (`All tests passed`); no ObjectDB/resource teardown warning in this run.
- Headless boot of `scenes/Main.tscn`: exit 0, no script errors.
- Export through `build_candidate.sh`: `builds/qa/candidates/edit_2026-11-09/`
  `RavenloftFoundationEdit.exe`, 110,482,120 bytes, SHA-256
  `580be9af65207f2b289629b467533f91da915946f1e6051685d3a2e124696250`;
  headless smoke exit 0. Packed paths include `content/...` and `src/main.gd`;
  none of `workspace/`, `tests/`, `tools/`, `docs/` or `PROJECT_COMPENDIUM.md`.
- GUT and boot both reported the isolated user dir
  `C:/Users/Noot Goblin/AppData/Roaming/RavenloftFoundationEdit`.

## Verification (2026-11-14) — application option guard

- Full GUT suite: **538/538 tests, 6,263 assertions, 44 scripts, exit 0**
  (`tests/test_cli_args.gd` contributes 13 tests / 209 assertions).
- `--list-campaigns` (3 campaigns), `--validate-campaigns` and
  `--validate-diagnostics`: exit 0, PASS.
- Unknown application options are now refused before any screen opens: in both
the source run and the candidate, `-- --validate-content` and `-- --bogus-option`
  print the refusal and exit **2**; the validators, `--list-campaigns` and a
  no-argument launch exit **0**; `--quest-log-probe` and `--party-limits-probe`
  still pass.
- Candidate `builds/qa/candidates/cli_args_2026-11-14/RavenloftFoundationEdit.exe`,
  110,637,712 bytes, SHA-256
  `e3650ecbcab429e4f23eec83976c74277b181e2842f26ad93ee361503cc45262`; 186 packed
  paths, none under `tests/`, `tools/`, `docs/`, `builds/`, `workspace/` or
  `addons/`, and no Markdown. All 32 content JSON files are packed.
- Checkpoint: `builds/qa/snapshots/2026-11-14_cli_args/` (source archive,
  manifest, manifest check).
- Earlier candidates and checkpoints were not modified.

## Handover note — the workspace README

`..\workspace\README.md` still says `Project Ravenloft\ravenloft-foundation` is
"Only place source, content, tests and tooling are edited". That is superseded by
the authority paragraph above. The file is outside this copy and was **not**
changed under this authorization. Proposed correction: replace that row's Rule
with "Preserved history; do not edit — development happens in `..\RL_Edit` (see
its `EDIT_COPY.md`)", and add the active-tree line to its Conventions section.

## Known limitations

- `docs/screenshots/` was excluded, so those image links in historical docs do
  not resolve; the README's two embeds were replaced with a note.
- Historical records (`PROJECT_CHRONICLE.md`, `PROJECT_OVERVIEW.md`,
  `docs/CONTINUATION_BRIEF.md`, `docs/TEST_REPORT.md`, verification docs) keep
  the original canonical paths as history; live instructions in `README.md`,
  `docs/SETUP.md` and `docs/CAMPAIGN_PACKAGE.md` point at this copy.
- The engine binary is a read-only dependency on the original install folder.
- **Superseded 2026-11-14: this copy now has a local Git repository.**
  `build_candidate.sh` records the real `source_head` and worktree hashes.
  Earlier `BUILD.txt` files keep their `no-git` fields as history.

## Local Git adoption (2026-11-14) — applied

Status: **applied 2026-11-14 19:14**, after the proposal below was accepted.
`git init -b main`, `core.autocrlf=false` and the local identity
`sauriangloom-commits <sauriangloom@gmail.com>` were used. The baseline commit is
`a64eead86b1f17b8b9937caa0d7a786ecb5f0b11` — "Baseline: RL_Edit working tree,
2026-11-14 (game milestones closed)" — with **535 tracked files**, 568 objects,
4.04 MiB of objects. There is still **no remote, no tag, no push and no
publication**, and the Git-backed original at `1af0253` is untouched. The
`.gitignore` draft below was applied as written, so `builds/` and `.godot/` stay
untracked; QA evidence cited by the docs therefore remains local-only.

The proposal text below is kept as accepted history.

**Baseline target.** One initial commit of the current working tree exactly as it
stands, including the post-checkpoint record edits in `docs/TEST_REPORT.md` and
`docs/PROGRAM_PROGRESS.md`. It is a snapshot of today's tree, **not** a
reproduction of `builds/qa/snapshots/2026-11-14_account_decision/`, which excludes
`builds/` and was sealed before those record edits; no commit history before this
baseline exists or can be invented.

### What the baseline would contain (535 files, 7,581,089 bytes ≈ 7.2 MiB)

| Path | Files | Bytes | Note |
| --- | --- | --- | --- |
| `src/` | 54 | 1,062,751 | all game scripts |
| `content/` | 32 | 104,513 | campaigns, shared data (JSON) |
| `scenes/` | 1 | 279 | `Main.tscn` |
| `assets/` | 30 | 2,471,931 | 14 WAV + art, with `.import` sidecars |
| `placeholder_art/` | 40 | 50,133 | design reference PNGs (cited by `PLACEHOLDER_ART_SIZES.md`, not loaded at runtime) |
| `addons/gut/` | 257 | 2,542,775 | vendored test framework, MIT (`addons/gut/LICENSE.md`) |
| `tests/` | 88 | 563,706 | 44 GUT scripts plus `.uid` files |
| `tools/` | 9 | 17,385 | `ui_probe.gd/.tscn`, `capture_window.py`, `qa/` build + audit scripts |
| `docs/` | 16 | 636,224 | guides, roadmap, reports |
| root files | 8 | 131,392 | `project.godot`, `export_presets.cfg`, `.gitignore`, `README.md`, `EDIT_COPY.md`, `PROJECT_OVERVIEW.md`, `PROJECT_CHRONICLE.md`, `PLACEHOLDER_ART_SIZES.md` |

Largest included files: `assets/audio/music_explore.wav` (882,044),
`music_menu.wav` (705,644), `ambience_dungeon.wav` (529,244), `src/main.gd`
(281,296), the four GUT `LobsterTwo` fonts (216K–235K), `docs/TEST_REPORT.md`
(171,370). No file exceeds 1 MB; nothing needs Git LFS.

### What stays untracked

- `builds/` — **2,851 files, 3,161,359,169 bytes (≈ 2.95 GiB)**: 27 candidate
  folders with ~110 MB executables (2.77 GiB), sealed snapshots (64.3 MiB) and QA
  run evidence/screenshots/profiles (164.2 MiB).
- `.godot/` — 2,118 files, 99,833,318 bytes (95.2 MiB) import cache.
- The engine binary and the original project: both outside this tree.
- Player saves, settings and QA profiles: none inside the tree; they live in
  `%APPDATA%\RavenloftFoundationEdit` (runs redirect `APPDATA` into `builds/qa/runs/`).
- Private PDFs / ZIP references: none present in this tree (the export preset
  already excludes `*.pdf` and `*.zip` from packages).
- Prior build evidence referenced from docs (screenshots, candidate hashes,
  checkpoints) therefore stays local-only; the repo will cite evidence it does
  not contain.

### `.gitignore` — draft, not applied

Existing rules already cover `.godot/`, `builds/`, `*.exe`, `*.pck`, `.qa_*`,
`qa_*.log`, `*.tmp`, `*.bak`. Proposed additions (append; keep every existing
line):

```gitignore
# Godot user data if APPDATA/XDG_DATA_HOME is ever pointed inside this tree
/profile/

# Private reference material and archives kept out of version control
*.pdf
*.zip

# Local run logs (no log file is part of the source tree today)
*.log

# OS metadata noise
.DS_Store
Thumbs.db
desktop.ini
```

**Do not add:** `*.import` (61 sidecars carry the audio/art import settings),
`*.uid` (158 script UIDs), or `*.cfg` (would drop `export_presets.cfg`).

### Files the exclusions would wrongly drop, if rules drift

- `export_presets.cfg` — required for `tools/qa/build_candidate.sh` and the
  documented export; a later `*.cfg` or `*.local` rule would silently omit it.
- The 61 `.import` sidecars — without them Godot re-imports WAV/PNG with defaults
  (loop and compression settings lost); `addons/gut` media hits this too.
- The 158 `.uid` files — dropping them churns script UIDs across the project.
- `content/**` JSON is required at runtime and by both validators; nothing
  currently ignores it.
- `*.exe` is safe today because no executable belongs in the tree; it would also
  hide a deliberately vendored CLI, so add an exception if that ever happens.

### Private / machine-specific material needing a decision

1. **Absolute paths in tracked documentation.** Eight files contain
   `C:\Users\Noot Goblin\...` or sibling-folder paths: `README.md`,
   `EDIT_COPY.md`, `PROJECT_OVERVIEW.md`, `PROJECT_CHRONICLE.md`,
   `docs/SETUP.md`, `docs/TEST_REPORT.md`, `docs/PHASE2_VERIFICATION.md`,
   `docs/PHASE3_VERIFICATION.md`. Options: (a) track unchanged — recommended for a
   local-only repository of this machine's records; (b) sanitize to relative paths
   before the first commit, which edits historical records and needs its own
   authorization.
2. **Evidence citations** point into untracked `builds/` (screenshots, candidate
   hashes, checkpoint files). Accepted as local-only records unless selected
   evidence is later imported deliberately.
3. **`placeholder_art/`** is reference art, not runtime content. Recommended to
   keep (50 KB, part of the documented art spec); excluding it is possible but
   loses the spec's pictures.
4. **Line endings are mixed** — 32 CRLF files (content JSON, several tests, docs)
   and 441 LF files. The repository must set `core.autocrlf=false` locally, or a
   checkout could rewrite bytes and change hashes; a `.gitattributes` file is a
   later decision, not part of this baseline.

### Operations that would need authorization

```sh
cd "C:\Users\Noot Goblin\Downloads\Ravenloft\RL_Edit"
git init -b main
git config --local core.autocrlf false
git config --local user.name  "<name>"      # only if no global identity is set
git config --local user.email "<email>"
# apply the .gitignore draft above (the only file edit), then:
git add --all
git ls-files | wc -l        # expect 535
git status --short          # expect nothing under builds/ or .godot/
git commit -m "Baseline: RL_Edit working tree, 2026-11-14 (game milestones closed)"
git count-objects -vH      # record the initial object size in this file
```

Local repository only: no remote, no push, no tag, no publication, no history
rewriting, and no operation against the original repository. Independent backup
storage stays a separate unresolved decision — a repository inside this tree is
not a backup.
