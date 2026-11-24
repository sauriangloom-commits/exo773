# Candidate A plan: keyboard combat information access

**Status: both batches closed.** This revision was the batch decision taken while
reviewing `d9dfb39`. Batch 1 (sidebar and pending-decision reveal plus focus stability)
shipped in `bad3a05` and is closed on the `da95ed4` record. Batch 2 (log focus and
scrolling) shipped in `4de76f1` and is accepted on candidate
`2026-11-24_combat_log_focus_batch2`; the evidence for both is in `docs/TEST_REPORT.md`.
The review itself ran no tests, probes, validators, builds or exports. Overrun remains
deferred, and the opposed-check helper is untouched.

## 1. Engine, and the 4.7 versus 4.7.2 wording

The project runs **Godot 4.7.2 stable**. The `4.7` in the project file is the same
engine, not a second version:

- `project.godot:18` holds `config/features=PackedStringArray("4.7", "GL Compatibility")`.
  Godot writes the **major.minor series** into that tag, never the patch release, so a
  4.7.2 editor records `4.7`.
- `README.md:10` names the engine as 4.7.2, and the editor metadata keeps the actual
  executable: `.godot/editor/project_metadata.cfg:7` is
  `Godot_v4.7.2-stable_win64.exe`.
- `docs/TEST_REPORT.md:6` records the runtime as
  `4.7.2.stable.official.ed1daf0bf`.

Restating it once: **Godot 4.7.2**, and every engine statement below is a 4.7.2
statement. Engine behavior was read from the 4.7.2 documentation and the 4.7.2
`rich_text_label.cpp` / `scroll_container.cpp` sources, not executed:

- `RichTextLabel` defaults to `FOCUS_ACCESSIBILITY` (3), which is not a Tab stop. Its
  `focus` StyleBox is drawn when focused.
- Its focused `gui_input` handles and accepts `ui_up`, `ui_down`, `ui_page_up`,
  `ui_page_down`, `ui_home` and `ui_end` when its scrollbar is visible. It does not
  handle Enter, Space, Escape or Tab.
- `ScrollContainer.follow_focus` automatically reveals focused **indirect** children;
  `ensure_control_visible` must run after a newly added child has had a frame to lay
  out.
- `RichTextLabel.scroll_following` is only an enable flag; the current following
  state is internal, so the log must track its own paused state.

## 2. Existing seams

| Area | Seam | Current behavior |
|---|---|---|
| Log widget | `src/ui/combat_screen.gd:110-120` | `RichTextLabel` in a margin, local `log_panel`, `scroll_following = true`, accessibility-only focus |
| Log refresh | `combat_screen.gd:824-829` | rewrites the last 160 lines and always `scroll_to_line(last)` |
| Sidebar | `combat_screen.gd:121-132` | outer `ScrollContainer` stored as `sidebar_panel`; no `follow_focus` |
| Target rows | `combat_screen.gd:303-310`, `631-710` | inner target `ScrollContainer` is local; target buttons rebuilt every refresh; no `follow_focus` |
| Decision | `combat_screen.gd:263-264`, `1015-1019`, `1024-1195` | `decision_box` sits before `button_box` in the sidebar; decision lists use a local scroller; children rebuilt every refresh; no `follow_focus` |
| Refresh | `combat_screen.gd:442`, `606-607` | calls `_rebuild_targets()` and `_rebuild_decision()` every time |
| Grid ownership | `combat_screen.gd:332-435`; `combat_view.gd:14-18, 61-112, 118-161` | grid owns arrows/Enter/Space/Escape only while it has focus; focus exit clears the cursor |
| Focus return | `combat_screen.gd:424-435` | returns to the remembered action button or first enabled action |
| Modal focus | `src/main.gd:227-229`, `10148-10239`, `10533-10548` | viewport focus signal, modal-only traversal, nested-pane reveal; combat is not in that walk |
| Layout count | `src/main.gd:2863-2871` | counts BaseButton, LineEdit, SpinBox, HSlider and TextEdit; `RichTextLabel` is not an action control |
| Probe hooks | `src/main.gd:63-118`, `:368`, `:431` | probe-name list, `--keyboard-probe` dispatch, `--layout-probe` / `--layout-scenario=combat` |

## 3. Log input contract

### Reaching and leaving

- The log becomes **one additional focus stop** in normal combat. Today
  `log_label` keeps the default `FOCUS_ACCESSIBILITY`, which is not a Tab stop;
  batch 2 sets `focus_mode = Control.FOCUS_ALL` on it. That setting is the first
  engine assumption the tests pin (§7.2).
- While the grid cursor is active, the log is set to `FOCUS_NONE`, so Tab from the
  grid still lands where it lands today and the accepted grid path is unchanged.
  `CombatView.end_keyboard_cursor()` / `_on_focus_exited()` restore `FOCUS_ALL`.
- **Route from grid targeting.** Because the grid keeps its Tab target, there is no
  direct Tab from grid to log. The short path is Escape — which already cancels
  targeting at no cost and returns the ring through `_focus_action_controls()` —
  followed by Shift+Tab from the first action control, which is the log. Tabbing out
  of the grid still lands on the first sidebar control as today, and Shift+Tab from
  there also reaches the log. A direct grid-to-log Tab would be one key cheaper but
  would change the accepted Tab target of the grid, so this batch does not take it.
- Tab never wraps into the log while a modal is open: the existing modal trap stays
  the only traversal owner, and the log gets no `focus_neighbor` overrides.

### Resulting Tab order

Tree order decides it: `body` adds the left column (grid, message label, log panel)
before `sidebar_scroll`, and `decision_box` is added to the sidebar before
`button_box` (`combat_screen.gd:263`, `:270`). So:

1. `log_label`, when the grid cursor is inactive;
2. the pending decision's controls, when one exists — decision target list, then
   Decline / Make the extra attack / Drop weapon / Keep weapon / Push 5 ft / Follow;
3. the 32 action buttons in `button_box` creation order, starting with `Move`;
4. weapon, shield, attack-mode and unarmed `OptionButton`s, then the Power Attack and
   Combat Expertise `SpinBox`es and the Fight defensively checkbox;
5. target rows — enemy `Inspect`/`Attack`, party `Inspect`, ground `Pick up`.

`initiative_label` and `active_label` stay out: the first keeps accessibility-only
focus and the second is a plain label, because the log is the only `RichTextLabel`
promoted to `FOCUS_ALL`.

### Keys

Use `RichTextLabel`'s existing focused key path. While the log has focus and its
scrollbar is visible:

| Key | Result | Consumption |
|---|---|---|
| Up/Down | one line | consumed by `RichTextLabel` |
| PageUp/PageDown | one page | consumed by `RichTextLabel` |
| Home | oldest retained line | consumed by `RichTextLabel` |
| End | return to newest and resume following | consumed by the local combat input guard before the widget |

End is the one addition: the log may be frozen while reading history, so its handler
must update the text to the current log before moving to the bottom, and must check
the modal guard first. Enter, Space, Escape and Tab are not handled by the log.
Escape keeps its pause/modal path; Tab keeps normal traversal; Enter/Space do nothing
on this read-only surface.

No global key handler is added. The log receives these keys only when it owns focus;
the grid, action controls and modal handlers cannot lose keys they never had.

### Mouse and follow behavior

Mouse wheel remains `RichTextLabel`'s own wheel scrolling. Do not accept or replace
the wheel event; observe the scrollbar's value only to notice that the player left
the bottom. Mouse targeting and the grid cursor are unchanged.

When the player scrolls away from the newest line, set an explicit `_log_following`
false. While false, **freeze the rendered log text** and count new `log_lines`; a
routine refresh must not rewrite the label or call `scroll_to_line`. This removes the
current unconditional jump at `combat_screen.gd:829` and keeps a reader's position
when the retained 160-line window advances. End clears the frozen state, rewrites the
log, scrolls to the newest line and resumes following. No automatic jump occurs
merely because messages arrive.

### Frozen state and the indicator

The hint is one line inside the existing log panel, in both states, so nothing shifts
when it changes. `log_margin` gains a `VBoxContainer` holding the `RichTextLabel` and
a `log_hint` label (`ThemeBuilder.body`, `fs(11)`, muted, one line, not a tooltip):

- following: `Combat log — Tab to focus · PgUp/PgDn · End newest`
- frozen: `Combat log — 3 new · End to resume` (same line, count substituted)

The panel keeps its 90 px `custom_minimum_size` (`:111`) and the hint's height is
reserved in both states, so the grid above does not resize when the log freezes or
the count changes. The focus ring is the `RichTextLabel` `focus` StyleBox, one
transparent GOLD outline added in `ThemeBuilder.build()`; no other chrome.

### While frozen

Freezing is a snapshot of what is on screen, not a lock on a live label.

- A routine `refresh_screen()` while frozen does not write `log_label.text` and does
  not call `scroll_to_line`; it only recomputes the count
  (`log_lines.size() - _log_frozen_total`) for the hint.
- **A pending decision arriving** changes nothing about the log: snapshot, offset and
  focus stay, and the decision is reachable by Tab (it precedes the action buttons).
  The player resolves it, then returns with End, or Shift+Tabs back to the log first.
  No automatic unfreeze and no focus steal.
- **A turn change arriving**, including the enemy turn, also only updates the count.
  Paging and End keep working off-turn because the reading spends nothing; the
  snapshot is not cleared, and `_sync_grid_keyboard()` cannot fire while the log owns
  the ring.
- **A modal** keeps the existing trap. While `main.modal != null` the log cannot take
  focus, and the End interception checks that guard, so a modal keypress never
  refreshes the log behind the panel.
- If the frozen lines have aged out of the 160-line window, the snapshot stays exactly
  as rendered until End; it is never silently re-sliced underneath the reader.

## 4. Presentation

- **Focus indicator: yes.** The `RichTextLabel` `focus` StyleBox, added in
  `ThemeBuilder.build()` with the existing button-focus convention. The project theme
  currently sets no RichTextLabel focus style.
- **Instruction: yes.** The always-present hint line above; it scales with `fs()` and
  does not appear only on focus, so there is no layout shift.
- The log stays a read-only text surface: no new button, toolbar, modal, copy or
  selection behavior.

## 5. Sidebar focus reveal and stability

### What can be off-screen

- Target rows: enemy `Inspect`/`Attack`, party `Inspect` and ground `Pick up` buttons
  inside the target scroller, itself inside `sidebar_panel`.
- Pending decisions: Cleave target buttons inside `choices_scroll` plus its `Decline
  extra attack`; Improved Trip's `OptionButton` and `Make the extra attack` /
  `Decline`; trip `Drop weapon` / `Keep weapon`; bull rush `Push 5 ft` / `Follow`; all
  inside `decision_box` inside `sidebar_panel`.
- Existing sidebar controls (actions, OptionButtons, SpinBoxes, checkboxes) can also
  sit below the outer fold and use the same outer scroller.

### Reveal

- Store the target scroller as a member (`target_panel`) and set
  `follow_focus = true` at `combat_screen.gd:303-310`.
- Set `sidebar_panel.follow_focus = true` at `:121-132`.
- Set each decision list's `follow_focus = true` in `_decision_scroll` (`:1015-1019`).
- No per-control `focus_entered` chain and no new `_reveal_focused_control` branch.
  Godot 4.7.2 reveals focused indirect children through every ancestor scroller; that
  is the existing facility this contract needs.

### Routine refreshes

`_rebuild_targets()` and `_rebuild_decision()` free all children on every
`refresh_screen()` (`:606-607`), so a focused row or decision control is destroyed
even when nothing meaningful changed. Keep the fix local:

1. Give each dynamically rebuilt focusable control a stable `combat_focus_key`
   metadata value: target index plus button role, or pending decision kind plus action
   and target index.
2. Compute a content signature for target rows and decisions. If unchanged, do not
   rebuild that subtree; the selected control and both scroll offsets survive.
3. If the signature changes, capture the focused control's key before `queue_free`,
   rebuild, wait one frame for layout, then restore that key. If it is gone or
   disabled, use the fallback below. `follow_focus` then reveals the restored control;
   do not call `ensure_control_visible` on every refresh.
4. Never move the outer or inner scroller merely because a refresh ran. Manual scroll
   offsets stay until focus moves or the selected control no longer exists.

The signature must be built from the values written into the controls — labels, button
texts, every button's `disabled` flag, option items and selection, ground rows and
their pickability — not from HP and names alone. `_can_standard()` and the pickup gate
turn on turn state and pending decisions, so an HP-only signature would leave a stale
enabled `Attack` or `Pick up` on screen after the action was spent.

### New pending decisions and resolution

A newly created pending decision does **not** generally steal focus:

- If focus is on a valid control (the log, an enabled option, another still-enabled
  control), leave it. The decision remains reachable by Tab and is revealed by
  `follow_focus`.
- If the grid is active, or the focused action button was disabled by the pending gate
  in `_update_button_states()`, there is no valid owner left. Release the grid and
  focus the first enabled decision control, then reveal it. This is a fallback, not
  automatic focus for every decision.
- On resolution, if focus was inside the removed decision subtree, return it to the
  remembered action button or first enabled action through the existing
  `_focus_action_controls()` policy. If focus is on another valid owner, leave it
  alone. Never return focus to the grid.

## 6. Traversal and the 32-control expectation

`_layout_interactive()` (`main.gd:2863-2871`) excludes `RichTextLabel`, so the combat
layout probe's **32 action controls** stay 32 (`docs/TRACEABILITY.md:149` records that
probe as `--layout-scenario=combat`). The log adds one focusable element, not an action
control; do not rewrite the 32 expectation. A separate focusable-element assertion, if
added, must count the log as a distinct stop and must not be folded into the action
count.

## 7. Failing-first tests, per batch

Each test is written first against the current tree and must fail there. Both batches
use the existing conventions in `tests/test_combat_keyboard_targeting.gd`: GUT, a
`CombatScreen` parented to a 1280x720 control, `wait_frames`, and real key presses
pushed through `get_viewport().push_input` (`_push_key`) rather than helper calls.

### 7.1 Batch 1 - reveal and focus stability

1. **Engine assumption: indirect-child reveal.** Two nested `ScrollContainer`s, each
   with content taller than its viewport; add a button, wait a frame, set
   `follow_focus = true` on both, `grab_focus()`. Assert both scrollbars moved just
   enough, the button's rect is inside the outer visible rect, and no key press was
   needed. Fails today because nothing sets the flag.
2. **Engine assumption: reveal takes no keys.** With a revealed target button focused,
   arrows/Enter behave as today and PageUp does not scroll the sidebar behind the
   player's back.
3. **Nested reveal and activation.** Overflow both `target_panel` and `sidebar_panel`
   with enemy and party rows; Tab to an `Attack` control whose initial rect is outside
   the sidebar; assert it is focused, both offsets moved, its rect is inside the
   visible sidebar; press Enter and assert the standard action was spent or the Inspect
   modal opened, not merely that a scrollbar range changed.
4. **Unchanged refresh.** Focus a target row and a decision button; call
   `refresh_screen()` with identical state; assert the same instances survive, focus is
   unchanged and both offsets do not move.
5. **Changed refresh.** Change a target's HP; refresh; assert the row rebuilt, focus
   restored by `combat_focus_key` to the new instance and revealed once after one
   frame, and that a disabled control is never restored as focus owner (fall through to
   `_focus_action_controls()`).
6. **Signature covers disabled state.** Spend the standard action, refresh with no HP
   change; assert the rebuilt `Attack` rows are disabled. This is the test that fails
   if the signature hashes HP and names only.
7. **Pending arrival, grid active.** Set a pending decision while the grid is active;
   refresh; assert the grid released and the first enabled decision control focused and
   revealed.
8. **Pending arrival, valid owner.** Set a pending decision while a still-enabled
   `weapon_option` has focus (and, after batch 2, while the log has focus); assert
   focus is unchanged and the decision is reachable by Tab.
9. **Resolution.** Focus a decision control, resolve; assert focus returned through
   `_focus_action_controls()` to the remembered or first enabled action, revealed, and
   never to the grid. With focus outside the decision subtree, assert it is left alone.
10. **Layout expectation.** `_layout_report(combat, "combat")` still returns **32
    controls** and 0 failures at 1280x720 for 1.0 and 1.6 text scale; the batch adds no
    action control and no focusable control.

### 7.2 Batch 2 - log focus, scrolling and freeze

1. **Engine assumption: focus mode and key ownership.** Assert `log_label` starts at
   `FOCUS_ACCESSIBILITY` (so it is not a Tab stop today) and that with `FOCUS_ALL` a
   real Tab lands on it. With a visible scrollbar, assert real Up/Down/PageUp/PageDown/
   Home presses move the log's own scrollbar, and that `ui_accept`, `ui_cancel` and
   `ui_focus_next` are **not** consumed by the label: Escape still pauses, Enter/Space
   do nothing, Tab moves on. For End, assert one scroll result, not two.
2. **Grid coexistence.** With the cursor active, `log_label.focus_mode == FOCUS_NONE`
   and Tab from the grid still lands on the first sidebar control. After release the
   log is `FOCUS_ALL` again, and Shift+Tab from the first action control reaches it.
3. **Frozen snapshot.** PageUp (or a wheel event) away from the bottom, append three
   lines, refresh; assert `text` is byte-identical, the scroll offset is unchanged and
   the hint reads `3 new`.
4. **End resumes.** Press End; assert the text matches the current `log_lines` slice,
   the scrollbar is at the bottom, the hint loses the count, and the next appended line
   follows without another key.
5. **Pending decision while frozen.** From a frozen log, set a pending decision and
   refresh; assert snapshot, offset and focus unchanged, the hint counts the new line,
   and Tab from the log reaches the first enabled decision control.
6. **Turn change while frozen.** Force the enemy turn; refresh; assert the snapshot
   survives, End still works and focus did not move.
7. **Modal.** With `main.modal` set, Tab stays inside the modal, the log takes no focus
   and an End press does not rewrite or unfreeze the log.
8. **Hint and ring at both scales.** Both hint states and the focus outline (present
   only while focused) are asserted at 1.0 and 1.6, and the grid's rect above the panel
   is unchanged from before the hint line.
9. **Layout expectation.** Still **32 controls** / 0 failures at 1280x720 at both
   scales; the log is asserted as one separate focus stop, never inside the action
   count.

**Implemented in `4de76f1`.** Items 1-7 and 9 are pinned by
`tests/test_combat_log_focus.gd`. Item 8's hint states are asserted; its
"grid rect above the panel is unchanged" is covered by the layout run (32 controls,
0 failures) rather than by a dedicated rect comparison, and neither state was reviewed
rendered. Two adjustments, neither of which changes a rule or the contract:

- **End is handled in `CombatScreen._input` before the widget.** The rendered text is a
  frozen snapshot, so End has to rewrite it before the jump; leaving the key to the
  widget would scroll within stale text. With `main.modal` set the key is swallowed
  instead of unfreezing the log behind the panel.
- **The grid route is asserted forward.** A five-enemy fixture puts its target rows
  between the first action control and the log, and those rows form their own backwards
  focus ring, so H2's "Shift+Tab from the first action control" is replaced by a bounded
  forward Tab walk from the control the grid leaves the player on. The two-enemy focused
  test still starts at that control.

### 7.3 Real-key probe for both batches

Add `--combat-info-probe` beside `--keyboard-probe` / `--layout-probe` in the probe
list (`main.gd:63-118`) and its dispatch (`:368`), reusing `probe_size` (1280x720) and
`--probe-text-scale`. Fixture: enough enemies and ground items to overflow the sidebar,
plus a pending decision with enough targets to overflow its list. Drive Tab, Shift+Tab,
arrows, PageUp/PageDown, Home, End, Enter and Space through the viewport, and record:

- one off-screen target row focused, revealed and **activated** (standard spent or
  Inspect modal opened), and one off-screen pending-decision choice likewise;
- the log scrollbar across Page keys, Home and End, frozen and unfrozen, with the
  hint's text;
- `_layout_report` 32 controls / 0 failures.

Run at 1.0 and 1.6. This is automated input and geometry evidence only. Rendered
readability, a human keyboard-only playthrough and screen-reader use remain unverified
and are not claimed by either batch. No manual testing is requested.

## 8. Batch decision

Two independently acceptable batches, not one. **Batch 1 (sidebar and pending-decision
reveal plus focus stability) comes first; Batch 2 (log focus and scrolling) follows.**
The numbering records that decision; it is not the note's section order.

**Both batches are closed, 2026-11-24.** Batch 1 shipped in `bad3a05` and is accepted
on the `da95ed4` record with candidate `2026-11-24_combat_info_batch1`. Batch 2 shipped
in `4de76f1` and is accepted on the `fbbbbeb` record with candidate
`2026-11-24_combat_log_focus_batch2`. The evidence is in `docs/TEST_REPORT.md`; the
closure and the next-task review are in `docs/ROADMAP.md`. No checks were run for the
closure or the review.

### Why batch 1 comes first

- **Player benefit.** Batch 1 removes a hard stop. A focusable control can sit outside
  the sidebar viewport, so Enter activates something the player cannot see, and every
  `refresh_screen()` frees the focused row, leaving no focus owner at all. A pending
  decision the player cannot see or reach blocks the fight from finishing. Batch 2
  removes a comprehension gap — the log is readable but not scrollable — which costs
  information, not the ability to act.
- **Complete on its own.** After batch 1 every focusable combat control is visible when
  focused, survives a refresh, and a decision can always be resolved. Nothing is left
  half-wired.
- **Regression surface.** Batch 1 touches the busiest path (`refresh_screen`, both
  rebuilds, focus policy) but only adds flags, signatures and key-based restore; rules,
  the click path and the 32 controls are untouched. Batch 2 is narrower but sits on the
  same input layer as the grid and the pause key, so it is easier to reason about once
  focus ownership has a tested policy.
- **Dependency direction.** Batch 2's interesting cases — "a decision arrives while the
  log is focused", "resolution leaves the log alone" — are assertions about batch 1's
  ownership rule. Landing batch 2 first would skip them or force a second pass over the
  same tests.

### Batch 1 contract

- **`follow_focus`.** `sidebar_panel.follow_focus = true` (`:121-132`); keep the inner
  target scroller as `target_panel` with `follow_focus = true` (`:303-310`); set it in
  `_decision_scroll` (`:1015-1019`). No `focus_entered` chains, no
  `_reveal_focused_control` branch, no `ensure_control_visible` on every refresh.
- **What is focused after a refresh.** The control that had focus keeps it. If it lived
  in a rebuilt subtree, restore it by `combat_focus_key` one frame later; if the key is
  missing or its control disabled or invalid, fall through to
  `_focus_action_controls()` (`:424-435`). A refresh never grabs focus for a control
  that did not have it, and an unfocused screen stays unfocused.
- **When a rebuild is avoided.** When the subtree signature is unchanged, with the
  signature built from the values written into the controls (labels, button texts,
  `disabled` flags, option items and selection, ground rows and pickability), so a
  spent action or a turn change still rebuilds.
- **New pending decisions.** Seat the first enabled decision control only when the
  previous owner is invalid: the grid was active, or the focused action button was
  disabled by the pending gate. If the log, an enabled option or another valid control
  owns the ring, leave it and let Tab find the decision.
- **Resolution.** Focus inside the removed decision subtree returns through
  `_focus_action_controls()`; focus outside it is left alone; focus never returns to
  the grid.
- **Boundary.** Stop and report if focus restoration turns out to need a general focus
  framework; do not grow this batch into one.

### Batch 2 contract

- **Focus and keys.** `log_label.focus_mode = FOCUS_ALL` except while
  `view.keyboard_cursor_active`, when it is `FOCUS_NONE`; `_leave_grid_keyboard()` and
  `CombatView._on_focus_exited()` restore it. Scroll keys use the built-in 4.7.2 path;
  End is intercepted in `CombatScreen._input` — the handler that already owns Escape
  for the grid — only while the log has focus and no modal is open, so it unfreezes,
  rewrites, follows and jumps once.
- **Frozen text and hint.** One hint label in the existing panel with the two states in
  §3; while frozen `_refresh_log()` writes nothing and does not scroll, and only
  updates the count.
- **Edge cases.** Pending decision, turn change and modal while frozen are as in §3.
  Mouse wheel stays the widget's own and is only observed, never accepted.
- **Boundary.** No new global shortcut, no copy/selection behavior, no log persistence,
  no change to `CombatView` input, `_on_cell_clicked`, rules, content or the 32 action
  controls.

## 9. Out of scope

Overrun, the opposed-check helper, flanking/occupancy warnings, content or schema
changes, unrelated warning cleanup, readied/delayed actions, other screens, and any
claim of full keyboard-only play or screen-reader support.
