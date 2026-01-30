## 2026-01-26 - Destructive Action Confirmation
**Learning:** The app lacked confirmation for destructive actions (deleting events), leading to potential data loss.
**Action:** Always wrap delete actions in a confirmation dialog using `showDialog` and `AlertDialog`.

## 2026-05-21 - Icon-Only Button Accessibility
**Learning:** Multiple icon-only buttons (FABs, AppBars) lacked tooltips, making them inaccessible to screen readers and confusing for some users.
**Action:** Always verify that `IconButton` and `FloatingActionButton` have a `tooltip` property defined.
