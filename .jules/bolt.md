## 2024-05-21 - Optimization of AgendaScreen List Rendering
**Learning:** Flutter's `ListView(children: ...)` instantiates all children immediately, causing performance issues in long lists. Refactoring to `ListView.builder` requires flattening data structures if the list contains headers and items.
**Action:** Always check `ListView` usage in `build` methods. If using sections/groups, create a sealed class or union for items and flatten the list before passing to `ListView.builder`.
