## 2026-01-26 - Destructive Action Confirmation
**Learning:** The app lacked confirmation for destructive actions (deleting events), leading to potential data loss.
**Action:** Always wrap delete actions in a confirmation dialog using `showDialog` and `AlertDialog`.
