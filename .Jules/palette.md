## 2026-01-26 - Destructive Action Confirmation
**Learning:** The app lacked confirmation for destructive actions (deleting events), leading to potential data loss.
**Action:** Always wrap delete actions in a confirmation dialog using `showDialog` and `AlertDialog`.

## 2026-01-26 - Accessibility for Icon-Only Buttons
**Learning:** Multiple key actions (Settings, Add FABs) were icon-only without text labels, making them inaccessible to screen readers and unclear for some users.
**Action:** Systematically add `tooltip` properties to all `IconButton` and `FloatingActionButton` widgets.
