## 2026-01-26 - Destructive Action Confirmation
**Learning:** The app lacked confirmation for destructive actions (deleting events), leading to potential data loss.
**Action:** Always wrap delete actions in a confirmation dialog using `showDialog` and `AlertDialog`.

## 2026-01-27 - Empty States and Accessibility
**Learning:** Empty lists (Agenda/Calendar) felt broken without feedback, and icon-only buttons lacked accessibility labels.
**Action:** Implement visual "Empty State" widgets (Icon + Text) for empty lists and always add `tooltip` to `FloatingActionButton` and `IconButton`.
