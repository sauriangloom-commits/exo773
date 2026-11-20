# Setup, Run and Test

## Verified environment

| Item | Verified value |
| --- | --- |
| OS | Windows (local desktop) |
| Godot | `4.7.2.stable.official.ed1daf0bf` |
| Executable | `C:\Users\Noot Goblin\Downloads\Ravenloft\Project Ravenloft\Godot_v4.7.2-stable_win64.exe` |
| Project | `C:\Users\Noot Goblin\Downloads\Ravenloft\RL_Edit` (editable copy) |
| GUT | 9.6.1, vendored at `addons/gut` |
| Test result | 538/538 passing, 6,263 assertions, 44 scripts, exit 0 (2026-11-14) |
| Python (QA only) | Miniconda Python 3.12 with pypdf and Pillow |

The game itself has no Python, .NET, Node or external package dependency.
GUT is the only addon.

## Run the game

From the project directory:

```bash
cd "C:\Users\Noot Goblin\Downloads\Ravenloft\RL_Edit"
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path .
```

Alternatively open `project.godot` in the Godot 4.7.2 editor and press **F5**.
The main scene is `scenes/Main.tscn`. No import step is normally needed; if class
names are unresolved after a fresh checkout, run:

```bash
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --headless --path . --import
```

## Run the tests

```bash
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --headless --path . \
  -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected tail:

```
Scripts              44
Tests               538
Passing Tests       538
Asserts            6263
---- All tests passed! ----
```

GUT's own update notice may mention 9.7.1; the installed and tested version is
**9.6.1**. Tests run headless and do not require a display.

### Test save isolation

Automated runs redirect saves to `user://test_saves` by detecting
`gut_cmdln.gd` in the command line (`SaveSystem._static_init`). They never write
to a player's `user://saves` slots. The test suite still deletes the slots it
creates where practical. If you change the test runner invocation, preserve this
redirect or tests may pollute real saves.

## Save locations

Godot maps `user://` to:

```
C:\Users\Noot Goblin\AppData\Roaming\RavenloftFoundationEdit\
```

This editable copy sets `config/use_custom_user_dir` and
`config/custom_user_dir_name`, so its `user://` data is separate from the
original install's `Ravenloft Foundation` folder.

- Player saves: `saves/auto.json`, `saves/slot1.json`, `saves/slot2.json`,
  `saves/slot3.json`.
- Save version 1 remains current. Old version-1 saves without `area_id`/`areas`
  load the Old Gatehouse; unknown areas and malformed area state are refused
  clearly and never overwrite the existing save.
- Test saves: `test_saves/auto.json` (not shown in the player menu).
- Settings: stored under the same `user://` application folder by the settings
  code; the exact file is an implementation detail and not required to play.

Delete `saves/` to reset progression. Do not delete `test_saves` during a test
run. The menu disables **Continue** and **Load game** when no compatible save is
present.

## Developer/QA launch flags

These are not player features; they exist for reproducible screenshots and smoke
tests. Arguments after `--` are user arguments:

```bash
# Start a new game immediately, skipping the menu (exploration at the start).
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo

# Start in Miruna's dialogue.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-dialogue

# Start in the flooded-stores combat.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-combat

# Start directly in the source-grounded E3 town square.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-town-square

# Isolated Combat Expertise + Power Attack QA encounter (not campaign content).
# A temporary Int 13 fighter derived from Kaelen faces two zombies.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-combat-expertise

# Start in the isolated turn-undead QA encounter (not campaign content).
# Aldric is placed first in initiative; the roll itself is a real seeded roll.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-turn-undead

# QA: spend one daily use, save and load it, then show the spent allowance.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-turn-undead-save

# QA: spend two daily uses, run the shrine recovery path, then show the reset.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-turn-undead-rest

# QA: adjacent 1-HP enemy for a victory/reward smoke check.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-victory-qa

# QA: defeat routing smoke check (party is reduced below -9 HP).
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo-defeat-qa

# Save the actual game viewport to docs/screenshots/<name>.png and quit.
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo --capture=explore
```

Valid capture names used by the committed screenshots: `menu`, `explore`,
`dialogue`, `combat`. The capture waits for layout and rendering, then writes
`res://docs/screenshots/<name>.png` and quits. `docs/.gdignore` keeps those images
out of Godot's import pipeline.

`tools/capture_window.py` is an optional desktop-window capture helper
(`python tools/capture_window.py "Ravenloft Foundation" out.png`). It requires
Pillow and is not used by the game.

## Application options and exit status

Application options are the words after Godot's `--` separator; the engine's own
options (`--headless`, `--path`, `--quit-after`, `-s`, `-gdir`, …) are handled by
Godot before the game ever sees them and are never validated here.

Every supported option is declared in `Main.APP_FLAGS` (no value) and
`Main.APP_VALUE_OPTIONS` (`--name=value`). An option outside those lists is
**refused before any screen opens**: the game prints the offending option, a
"did you mean" line with the closest supported names, and exits. Nothing is
shown and no game state is created.

| Exit status | Meaning |
| ---: | --- |
| 0 | Ran successfully: normal launch, `--list-campaigns`, or a passing probe/validator |
| 1 | Ran, but a validation, probe or export check failed |
| 2 | The invocation itself was wrong: an unknown application option, or a `--name=value` option with an empty value |

Distinguishing 1 from 2 lets a CI step tell "the content is broken" from "the
command is wrong". Bare text without a leading `-` is ignored, as before.

Layout check (windowed; asserts that no control or label is unreachable at a
given client size and text scale, and exits nonzero if one is):

```bash
# exploration at the minimum client and maximum text
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --path . -- --demo --layout-probe --layout-scenario=screen --probe-size=1280x720 --text-scale=1.6
# Settings, the inspect modal, dialogue, the journal, a blocked move and
# fullscreen: --layout-scenario=settings|inspect|dialogue|journal|refusal|fullscreen
# add --capture-dir=<abs dir> to write the measured frame as a PNG
```

Native input check (windowed; drives the exported build with OS-level keys, wheel
and clicks, and writes a client-area PNG after each step):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/native_input.ps1 `
  -Exe "C:\path\RavenloftFoundationEdit.exe" `
  -GameArgs "-- --demo --text-scale=1.0" `
  -Out "C:\path\captures" `
  -Script "wait:800;click:8:8;key:w:8;shot:01_walk;key:j:1;shot:02_journal"
```

Steps: `wait:ms`, `click:x:y`, `key:name:count`, `wheel:x:y:delta`, `shot:name`,
`fg`. The window is raised to topmost and focused with a real click because
Windows refuses a foreground change from a background process; action keys are
sent with scan codes, which Godot needs to map them to physical keys.

Content checks:

```bash
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --headless --path . -- --list-campaigns
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --headless --path . -- --validate-campaigns
"..\Project Ravenloft\Godot_v4.7.2-stable_win64.exe" --headless --path . -- --validate-diagnostics
```

`--validate-content` does **not** exist. It is named in older planning notes and
was never implemented; it is now rejected with exit 2 like any other unknown
option. Use the two validators above.

## Layout and resolution

- Reference viewport: **1280×720**; the window opens at that size and cannot be
  made smaller (`get_window().min_size`).
- **The client area is the layout surface** (`display/window/stretch/mode="disabled"`,
  corrected 2026-11-20). A larger window or fullscreen gives the UI more logical
  room instead of scaling a fixed 1280×720 canvas, so fonts stay crisp and panels
  are not magnified past a 1080-high display. Verified by `--layout-probe` at
  1280×720, 1600×900, 1920×1017 maximized and 1920×1080 fullscreen at 100 % and
  160 % text. 1024×600 is not a supported size.
- The first-person and combat views set `clip_contents = true`; walls projected
  above the view rect must not paint over the header.
- Text is sized through `ThemeBuilder.fs()`; changing the base scale there is the
  intended global adjustment.

## Controls and settings

Default bindings are in `project.godot` and listed in the README.**Settings** in the main menu and pause menu exposes master/music/SFX/ambience volume, text size and per-action rebinding. Rebinding writes to `InputMap` at runtime; settings are restored on the
next launch by the settings loader.

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `Identifier ... not declared` / class not found after fresh checkout | Run `--import` once so Godot registers `class_name` scripts |
| Game starts at menu instead of a demo screen | Pass user args after `--`: `-- --demo` |
| `--demo` arguments ignored | A single `-` is consumed by Godot; the separator `--` is required |
| No sound in headless mode | Expected; use a windowed run to hear audio |
| Continue/Load disabled | No compatible save exists; start a new game or check `user://saves` |
| Save refused during combat | By design; finish the fight or load an earlier save |
| Tests write into real saves | The GUT command line was changed; keep `gut_cmdln.gd` detectable or set `SaveSystem.save_dir` explicitly |
| Game does not start and prints "Unknown application option" | The option is not supported. The message names it and suggests the closest supported alternatives; see **Application options and exit status** above |
| Screenshot capture fails | Capture requires a windowed (not `--headless`) run and a writable `docs/screenshots/` |
| PDF tools fail on the reference folder | `pdftotext` path handling failed in this environment; use pypdf as documented in the reference index |
| GUT reports a newer release | Informational only; 9.6.1 is installed and verified |

## Export/build status

`export_presets.cfg` is present (`Windows Desktop`, product name "Ravenloft
Foundation (Edit Copy)") and exports run against installed Godot 4.7.2 templates.
Candidates are written to `builds/qa/candidates/<id>/RavenloftFoundationEdit.exe`
with a `BUILD.txt` recording build time, project path, `no-git` revision fields,
exe size and SHA-256. `tools/qa/build_candidate.sh [build-id]` is the supported
way to produce one, and it never writes into the original project.

The export preset excludes `docs/`, `tests/`, `tools/`, `addons/gut/`,
`builds/`, `*.md`, `*.pdf` and QA captures, so a player build ships content,
scripts and assets only. Verify that on each new candidate by checking the packed
path list against the exclusions.

The latest verified candidate, its hash and its probe results are recorded in
[TEST_REPORT.md](TEST_REPORT.md). Candidates are automated-window evidence, not a
human playtest: do not treat a passing probe as proof that the game was played.
Before shipping a build to anyone, replay the loop on that exact executable.
