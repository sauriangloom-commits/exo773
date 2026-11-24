# Godot 4.7 EPUB audit — documentation note (2026-11-24)

Documentation only. Nothing here was fixed, and no test, probe, validator, build or export
was run while writing it. The checks behind this note were documentation-integrity checks:
Git state, recorded suite logs, file hashes and read-only static counts over the working
tree. They are not game checks and do not stand in for one.

Source: `GodotEngine.epub` (Godot Docs — 4.7 branch, 9,216 navpoints) in the parent folder.
Fifteen chapters relevant to a 2D/UI GDScript project were read: GDScript style guide, static
typing, scene organization, project organization, scenes vs. scripts, logic preferences, data
preferences, autoloads vs. regular nodes, instancing with signals, saving games, runtime file
loading/saving, exporting projects, general optimization and CPU optimization. The extracted
text lives in the gitignored `builds/qa/epub_audit/` and is not part of the repository.

Repository baseline for every count below: `HEAD b7c5bb9` ("Record the Aid Another acceptance
and its candidate"), worktree clean except the uncommitted `README.md` change.

## Repository state, reconciled

The audit's suite figures (1,047 tests, 10,294 asserts, 81 scripts) are current, not stale.
The previously recorded suite was 1,032 tests, 10,228 asserts and 80 scripts.

| Record | Tests | Asserts | Scripts | Evidence |
| --- | --- | --- | --- | --- |
| Previous acceptance | 1,032 | 10,228 | 80 | `docs/TEST_REPORT.md:6876`, `docs/ROADMAP.md:2251`, `builds/qa/sneak_range_green/suite_final.log` (source head `81b00f6`) |
| Current acceptance | 1,047 | 10,294 | 81 | `docs/AID_ANOTHER_PLAN.md:417`, `builds/qa/aid_another_green/suite.log` (source head `81a76e0`) |

The delta is exactly +15 tests, +66 asserts and +1 script, and it is fully explained by the
Aid Another work:

- `6c64ec3` added `docs/AID_ANOTHER_PLAN.md` and closed the documentation audit.
- `6a32172` amended that plan to one acceptance unit and fixed its scope.
- `81a76e0` added the action and `tests/test_aid_another.gd` (475 lines, 15 test functions,
  64 asserts in the focused run) and edited `tests/test_combat_focus_reveal.gd` and
  `tests/test_combat_log_focus.gd`.
- `b7c5bb9` recorded the acceptance and the hash-bound candidate.

So Aid Another exists, is committed, and is accepted; no Aid Another work is pending or
uncommitted in the tree. `git status --short` shows only ` M README.md`. The discrepancy
between the two recorded suites is explained by the repository, not by an unrecorded run.
The current log also reports 1,272 deprecated uses (GUT 9.7.1 `wait_frames`), one orphan
`Control` in `test_combat_keyboard_targeting.gd`, and leaked RID/ObjectDB warnings at exit.

## Verified deviations from the style guide

### Long lines

The style guide asks for lines under 100 characters. Measured over 33 scripts and 38,520
lines (`wc -l`; 38,521 when splitting on newlines): **1,142 lines exceed 100**, 445 exceed
120 and 121 exceed 160. Concentration:

| File | Lines >100 | Worst line |
| --- | --- | --- |
| `src/main.gd` | 503 | 318 chars at `main.gd:3916` |
| `src/core/campaign_store.gd` | 255 | 292 chars at `campaign_store.gd:592`; also 269 at :586 and 276 at :590 |
| `src/ui/campaign_creator.gd` | 106 | 305 chars at `campaign_creator.gd:1025`; also 269 at :2645 |
| `src/core/skills.gd` | 48 | — |
| `src/core/encounter.gd` | 44 | — |
| `src/core/content_db.gd` | 39 | — |

Cost: long data-literal and message lines are harder to review and diff. Risk: low for
runtime, but a bulk reformat would create a large, low-value diff across accepted files.

### Declaration order

The style guide orders declarations signals → enums → constants → exports → public
variables → private variables → `@onready` → virtual methods → methods. **17 flagged
declarations in 5 files** sit after a later section:

- `src/main.gd`: constants at :50, :51, :56, :62, :144, :1890 after the variable block;
  variables at :2222, :2941, :2943, :2944, :2945 after methods.
- `src/game_state.gd:1719`: `var training_mode := false` between `_on_combat_started` and
  `_resolve_encounter`.
- `src/core/encounter.gd:4725`: a variable after methods.
- `src/core/character.gd:72`: a constant after variables.
- `src/ui/dialogue_panel.gd:24` and `:25`: constants after variables.

Cost: a reader scanning the top of a file misses state declared further down. Risk: low;
`training_mode` in particular reads like a local at its current position.

### Blank lines between functions

The guide asks for two. **Two of 1,019 functions have one**: `src/core/encounter.gd:512`
(`func cell_of`) and `src/main.gd:8189` (`func _qa_ranged_character`). Formatting only.

### Figures that differ from the earlier audit pass

Recorded here rather than silently carried forward:

- Declaration order: 17 flagged declarations, not 16 (the earlier pass missed
  `main.gd:2943–2945`).
- Probe flags: **78** `APP_FLAGS` entries plus 13 `APP_VALUE_OPTIONS`, not 77.
- `main.gd` probe harness: 133 probe-named functions and 7,264 lines of the file's 11,397.
- Total source size: 38,520 `wc -l` lines; the 38,521 split count includes a final line
  without a newline.

Everything else re-measured identically: 1,142/445/121 long lines, 20 `get_parent()` calls,
2 blank-line spots, 5 order-affected files.

## Maintenance debt

### Parent walking

20 `get_parent()` calls, all in `src/main.gd`, at :2808, :2890, :2894, :2903, :3374, :3767,
:3769, :5143, :7651, :7656, :7792, :7794, :9223, :9225, :9239, :9255, :9324, :9326, :10536
and :10654. Several climb more than one level (`:3374` chains three). The logic-preferences
chapter prefers ownership or signals over parent traversal. Cost: modal layout changes can
break focus/scroll logic silently; the chain calls are the fragile ones. Risk: medium-low,
because automated layout probes cover the modal paths but only at one viewport.

### The `Game` autoload

`src/game_state.gd` is 2,334 lines and is referenced as `Game.` 984 times across 14 files,
while it exposes 9 signals. The autoloads chapter accepts a singleton of this kind but warns
about global state and coupling. Cost: every rules, save, quest or settings change passes
through one large object, and call sites are hard to audit. Risk: growth, not a current
defect; the suite is the main guard.

### The probe harness inside `main.gd`

`src/main.gd` is 11,397 lines; 133 probe-named functions and 7,264 lines of it are QA code,
dispatched from 78 flags and 13 value options. The exported PCK includes it, guarded only by
command-line activation. Cost: the largest file is mostly test harness, so game-shell
changes are reviewed against a noisy file; the harness text also ships. Risk: maintainability
and shipped surface, not gameplay correctness. Moving it is deferred (see below).

### Test-run warnings

The current suite log reports **1,272 deprecated uses** and **one orphan `Control`** from
`test_combat_keyboard_targeting.gd::test_an_open_modal_deactivates_the_grid_and_escape_still_
closes_it`, plus leaked RID/ObjectDB warnings at exit. Cost: the deprecation flood makes a
new warning invisible, and the orphan points at a real node-lifetime loose end in the test
harness. Risk: low today, but diagnostics get weaker over time. No migration was done here.

## Open owner decisions

None of these were chosen or changed; they are recorded so the owner can decide.

- **License.** There is no root `LICENSE`; only `addons/gut/LICENSE.md` (GUT's own MIT).
  Without one, redistribution terms for the project and its assets are unspecified.
- **Copyright.** `project.godot` has no `config/copyright`; the exporting chapter expects it
  in distributable builds.
- **Version.** `project.godot` has no `config/version`, so an exported build has no version
  string to display or bind acceptance records to.
- **PCK encryption.** `export_presets.cfg` sets `encrypt_pck=false` with
  `script_export_mode=2` and `embed_pck=true`. Scripts in the PCK are readable. Whether that
  matters is a product decision, not a defect.

## Evidence gaps

- **One resolution.** Layout acceptance is 33 controls, 0 failures at 1280×720 at 100 % and
  160 % text scale (`AID_ANOTHER_PLAN.md:417`), and the window settings use a fixed
  1280×720 viewport with `window/stretch/mode="disabled"`. No evidence exists for
  1920×1080, 1024×768 or a user resize. Resize handling is partial: `combat_view.gd:25`,
  `dialogue_panel.gd:42–43, 99–101`, `first_person_view.gd:24`, and viewport reads at
  `main.gd:3235` and `:10320`.
- **Performance is unmeasured.** There is no profiler capture and no frame-time number.
  The static fact that `src/` has zero `_process`/`_physics_process` functions is a design
  observation, not a measurement, and the CPU-optimization chapter's first rule (profile
  before optimizing) is neither satisfied nor violated by it.
- **Static-check limits.** Counts come from read-only regex/heuristic passes: tab width is
  taken as 4, declaration order is inferred from top-level line prefixes, and probe size is
  measured by function name. They are reproducible but not a parser.
- **No rendered or human review** of focus, log, hints or defeat screens, and no keyboard-only
  or playtest session; those gaps carry forward unchanged from the Aid Another record.

## Deferred planning items

- **Extracting the probe harness is deferred and needs a design first.** It is not a
  mechanical move: probes are the exported-executable acceptance model (the candidate was
  accepted by running the exported binary headless and binding its hash), so relocating them
  to `tests/` or `tools/` would change what acceptance runs and how hashes are bound. A
  separate QA build — what ships, which flags it keeps, how headless acceptance invokes it —
  has to be designed and recorded before any extraction work starts.
- Long-line, declaration-order and blank-line cleanups are unscheduled; doing them in bulk
  would touch accepted files for formatting only.
- The GUT `wait_frames` migration and the orphan `Control` cleanup are unscheduled.
- Multi-resolution and resize verification is unscheduled.
- The four owner decisions above stay open until the owner rules on them.
- Overrun stays deferred and the opposed-check helper is untouched, as recorded previously.

## What was checked for this note

Documentation-integrity only: README file hash and diff hash before writing
(`d7cd5f89…b1b57` and `0e8ff3e1…5e1c`), `git status`, `git log`, the recorded suite logs,
`project.godot`, `export_presets.cfg`, and read-only counts over `src/`.

No tests, focused tests, probes, validators, builds or exports were run, and the game was not
launched. Nothing executable, in content, schema, saves or project settings was changed.
