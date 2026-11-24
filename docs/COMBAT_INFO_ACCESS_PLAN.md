# Candidate A plan: keyboard combat information access

**Status: planning only.** No implementation, tests, probes, validators, builds or
exports were run for this note. Overrun remains deferred, and the opposed-check
helper is untouched.

## 1. Scope and engine evidence

This is one bounded Candidate A batch: keyboard access to the combat log, and
revealing off-screen target-row and pending-decision controls through the existing
sidebar scrollers. It does not add a shortcut layer, a general focus framework, a
new modal, or another accessibility redesign.

The project targets **Godot 4.7.2** (`project.godot:18` is `4.7`;
`README.md:10` names 4.7.2; `docs/TEST_REPORT.md:6` records
`4.7.2.stable.official.ed1daf0bf`). Engine behavior below was read from the 4.7
documentation and source, not executed:

- `RichTextLabel` defaults to `FOCUS_ACCESSIBILITY` (3), not a normal Tab stop. Its
  `focus` StyleBox is drawn when focused.
- Its focused `gui_input` handles and accepts `ui_up`, `ui_down`, `ui_page_up`,
  `ui_page_down`, `ui_home` and `ui_end` when its scrollbar is visible. It does not
  handle Enter, Space, Escape or Tab.
- `ScrollContainer.follow_focus` automatically reveals focused **indirect**
  children; `ensure_control_visible` must run after a newly added child has had a
  frame to lay out.
- `RichTextLabel.scroll_following` is the follow-enable flag; current following
  state is internal. The log must track its own paused state.

Sources: Godot 4.7 `RichTextLabel`, `ScrollContainer` and `Control` class docs, and
the 4.7 `rich_text_label.cpp` / `scroll_container.cpp` implementations.

## 2. Existing seams

| Area | Seam | Current behavior |
|---|---|---|
| Log widget | `src/ui/combat_screen.gd:110-120` | `RichTextLabel`, local `log_panel`, `scroll_following = true`, accessibility-only focus |
| Log refresh | `combat_screen.gd:824-829` | rewrites the last 160 lines and always `scroll_to_line(last)` |
| Sidebar | `combat_screen.gd:121-132` | outer `ScrollContainer` stored as `sidebar_panel`; no `follow_focus` |
| Target rows | `combat_screen.gd:303-310`, `631-710` | inner target `ScrollContainer` is local; target buttons are rebuilt on every refresh; no `follow_focus` |
| Decision | `combat_screen.gd:263-264`, `1015-1019`, `1024-1195` | `decision_box`; decision target lists use a local scroller; all children are rebuilt on every refresh; no `follow_focus` |
| Refresh | `combat_screen.gd:442`, `606-607` | calls `_rebuild_targets()` and `_rebuild_decision()` every time |
| Grid ownership | `combat_screen.gd:332-389`; `combat_view.gd:14-18, 61-112, 118-161` | grid owns arrows/Enter/Space/Escape only while it has focus; focus exit clears the cursor |
| Focus return | `combat_screen.gd:424-435` | returns to the remembered action button or first enabled action |
| Modal focus | `src/main.gd:227-229`, `10148-10239`, `10533-10548` | viewport focus signal, modal-only traversal, and nested-pane reveal; combat is not included in that walk |
| Layout count | `src/main.gd:2863-2871` | counts BaseButton, LineEdit, SpinBox, HSlider and TextEdit; `RichTextLabel` is not an action control |

## 3. Log input contract

### Reaching and leaving

- The log becomes **one additional focus stop** in normal combat: Tab/Shift+Tab
  can reach it in tree order before the sidebar. It is not an action control.
- While the grid cursor is active, set the log's focus mode to `FOCUS_NONE`. This
  preserves the accepted grid path exactly: arrows, Enter/Space and Escape keep
  their current ownership, and Tab leaves the grid through the same route as
  before. When the grid releases, restore `FOCUS_ALL`.
- Tab never wraps into a hidden log while a modal is open; the existing modal trap
  remains the only traversal owner. The log gets no `focus_neighbor` overrides.

### Keys

Use `RichTextLabel`'s existing focused key path. While the log has focus and its
scrollbar is visible:

| Key | Result | Consumption |
|---|---|---|
| Up/Down | one line | consumed by `RichTextLabel` |
| PageUp/PageDown | one page | consumed by `RichTextLabel` |
| Home | oldest retained line | consumed by `RichTextLabel` |
| End | return to newest and resume following | consumed by the local combat input guard before the widget |

End is the one addition: the log may be frozen while reading history, so its
handler must update the text to the current log before moving to the bottom. Enter,
Space, Escape and Tab are not handled by the log. Escape keeps its pause/modal path;
Tab keeps normal traversal; Enter/Space do nothing on this read-only surface.

No global key handler is added. The log receives these keys only when it owns focus;
the grid, action controls and modal handlers cannot lose keys they never had.

### Mouse and follow behavior

Mouse wheel remains `RichTextLabel`'s own wheel scrolling. Do not accept or replace
the wheel event; observe the scrollbar's value only to notice that the player left
the bottom. Mouse targeting and the grid cursor are unchanged.

When the player scrolls away from the newest line, set an explicit `_log_following`
false. While false, **freeze the rendered log text** and count new `log_lines`; a
routine refresh must not rewrite the label or call `scroll_to_line`. This avoids the
current unconditional jump at `combat_screen.gd:829` and avoids shifting a reader's
position when the retained 160-line window advances. The fixed hint reports
`N new` (or equivalent). End clears the frozen state, rewrites the log, scrolls to
the newest line, and resumes following. No automatic jump occurs merely because
messages arrive.

## 4. Presentation

- **Focus indicator: yes.** Use the `RichTextLabel` `focus` StyleBox. The project
  theme currently sets no RichTextLabel focus style, so add one transparent GOLD
  outline in `ThemeBuilder.build()` using the existing button-focus convention.
- **Instruction: yes.** Add one fixed muted line in the existing log panel:
  `Combat log — Tab to focus · PgUp/PgDn · End newest`. Use `ThemeBuilder.body`
  at a small size so it scales with `fs()`; do not add a tooltip-only instruction.
  Keep it present when unfocused to avoid a focus-driven layout shift.
- The log remains a read-only text surface. It gets no new button, toolbar, modal
  or copy/selection behavior.

## 5. Sidebar focus reveal and stability

### What can be off-screen

- Target rows: enemy `Inspect`/`Attack`, party `Inspect`, and ground `Pick up`
  buttons inside `target_scroll`, itself inside `sidebar_panel`.
- Pending decisions: Cleave target buttons inside `choices_scroll` plus its
  `Decline extra attack`; Improved Trip's `OptionButton` and
  `Make the extra attack`/`Decline`; trip `Drop weapon`/`Keep weapon`; bull rush
  `Push 5 ft`/`Follow`; all inside `decision_box` inside `sidebar_panel`.
- Existing sidebar controls (actions, OptionButtons, SpinBoxes, checkboxes) can
  also sit below the outer fold; they use the same outer scroller.

### Reveal

- Store the target scroller as a member (`target_panel`) and set
  `target_scroll.follow_focus = true` at `combat_screen.gd:303-310`.
- Set `sidebar_panel.follow_focus = true` at `:121-132`.
- Set each decision list's `follow_focus = true` in `_decision_scroll`
  (`:1015-1019`).
- Use no per-control `focus_entered` chain and no new `_reveal_focused_control`
  branch. Engine 4.7 reveals focused indirect children through every ancestor
  scroller. This is the existing facility the contract needs.

### Routine refreshes

The current `_rebuild_targets()` and `_rebuild_decision()` free all children on
every `refresh_screen()` (`:606-607`), so a focused row/decision control is
destroyed even when nothing meaningful changed. Keep the fix local:

1. Give each dynamically rebuilt focusable control a stable
   `combat_focus_key` metadata value: target index plus button role, or pending
   decision kind plus action and target index.
2. Compute a small content signature for target rows and decisions. If unchanged,
   do not rebuild that subtree; the selected control and scroll offsets survive.
3. If the signature changes, capture the focused control's key before
   `queue_free`, rebuild, wait one frame for layout, then restore that key. If it
   is gone, use the fallback below. `follow_focus` then reveals the restored
   control; do not call `ensure_control_visible` on every refresh.
4. Never move the outer or inner scroller merely because a refresh ran. Manual
   scroll offsets stay until focus moves or the selected control no longer exists.

### New pending decisions and resolution

A newly created pending decision does **not** generally steal focus:

- If focus is on a valid control (log, pause, another still-enabled control), leave
  it. The decision remains reachable by Tab and is revealed by `follow_focus`.
- If the grid is active, or the focused action is disabled by the pending gate,
  there is no valid owner left. Release the grid and focus the first enabled
  decision control, then reveal it. This is a fallback, not automatic focus for
  every decision.
- On resolution, if focus was inside the removed decision subtree, return it to
  the remembered action button or first enabled action through the existing
  `_focus_action_controls()` policy. If focus is on another valid owner, leave it
  alone. Do not return focus to the grid.

## 6. Traversal and the 32-control expectation

`_layout_interactive()` (`main.gd:2863-2871`) excludes `RichTextLabel`, so the
combat layout probe's **32 action controls** remain 32. The log adds one focusable
element, not an action control; do not rewrite the 32 expectation. A separate
focusable-element assertion, if added, must count the log as a distinct stop; it
must not be folded into the action-control count.

## 7. Failing-first tests and probe

Write focused tests before implementation. Each should fail on the current tree:

1. **Log ownership**: Tab reaches the log in resting combat and leaves by Tab;
   while the grid is active the log is skipped. At 1280x720, real key events move
   the log's scrollbar and keep the grid cursor unchanged.
2. **No stolen keys**: with the log focused, Enter/Space/Escape/Tab are not
   consumed by the log; Enter/Space do nothing, Escape retains its existing path,
   Tab moves focus. With the grid focused, Page/Home/End do not scroll the log.
3. **Follow pause**: scroll up with real PageUp/wheel, append log lines, refresh;
   assert the rendered text and scroll offset did not move, the hint counts new
   messages, and End returns to the newest line and following.
4. **Nested reveal**: create enough target rows and decision choices to overflow
   both `target_scroll` and `sidebar_panel`; Tab to a control whose initial global
   rect is outside the sidebar; assert it becomes focused, both scroll offsets
   moved just enough, and its rect is inside the visible sidebar. Press Enter and
   assert the control actually activated (Inspect modal or chosen attack), not
   merely that a helper ran or a scrollbar range changed.
5. **Refresh stability**: focus a target row and a decision button; call
   `refresh_screen()` with unchanged state; assert the same control remains
   focused and scroll offsets do not jump. Change HP so the row rebuilds; assert
   focus is restored by key and revealed once.
6. **Pending/modal/off-turn**: a pending decision appearing from an active grid
   seats its first decision control; one appearing while the log is focused leaves
   the log focused; resolving returns to an action control. Log paging works on an
   enemy turn and is inert while a modal owns the keyboard.

Extend the real-key probe (or add `--combat-info-probe`) with a 1280x720 fixture
large enough to overflow the sidebar. At **1.0 and 1.6 text scale**, drive Tab,
PageUp/PageDown, Home, End, Enter and Space through the viewport. Include one
off-screen target row and one off-screen pending-decision choice that are actually
focused, revealed and activated. Record geometry and focus ownership. This is
automated input/geometry evidence only; it is not rendered-readability, human
keyboard-only or screen-reader evidence. No manual testing is requested.

## 8. Recommended batch and boundaries

One bounded batch is coherent: log focus + frozen-history/End behavior + the
fixed hint/focus style; `follow_focus` on the outer/inner/decision scrollers;
stable focus keys and signatures for dynamic rows/decisions; and the focused tests
plus real-key probe at both scales. Existing modal handling, `CombatView` input,
mouse wheel/targeting and the 32 action controls stay unchanged.

If implementing focus preservation reveals that the dynamic rebuilds need a
general focus framework, stop and report that dependency rather than expanding
this batch.

Out of scope: overrun, the opposed-check helper, flanking/occupancy warnings,
content or schema changes, unrelated warning cleanup, readied/delayed actions,
other screens, and any claim of full keyboard-only play or screen-reader support.
