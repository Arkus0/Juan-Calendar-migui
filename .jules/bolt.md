## 2024-05-22 - AgendaScreen Virtualization
**Learning:** `ListView(children: ...)` with many items (headers + tasks) causes eager building of all widgets, which is inefficient for large lists.
**Action:** Use `ListView.builder` with a sealed class hierarchy (`AgendaItem` -> `Header`, `Task`) to flatten the list and allow lazy building.
