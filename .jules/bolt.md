## 2024-05-24 - Testing StateNotifiers with Side Effects
**Learning:** StateNotifiers that trigger async data loading in their constructor (like `_loadData()`) are difficult to test because the side effect happens immediately upon instantiation, often before mocks are fully configured or requiring complex setup.
**Action:** Add an optional `loadOnInit` parameter (default: true) to the constructor of such Notifiers. In tests, set this to `false` to prevent automatic loading, allowing you to manually set the state or verify initial behavior without side effects.
