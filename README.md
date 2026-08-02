# Multi-Screen Navigation Lab (Chapter 6)

## App Overview
A simple task-list app with three screens, all connected through
`Navigator`-based stack navigation:

| Screen | Purpose | How it's reached |
|---|---|---|
| **HomeScreen** | Root screen; lists tasks | App start (`initialRoute: '/'`) |
| **DetailScreen** | Shows one task's full details | `Navigator.pushNamed(context, '/detail', arguments: item)` |
| **AddItemScreen** | Form to create a new task | `Navigator.push(context, MaterialPageRoute(...))` |

## How navigation & data-passing work

**Forward (Home → Detail):**
Tapping a list item calls `Navigator.pushNamed(context, '/detail', arguments: item)`.
`DetailScreen` reads the item back out with
`ModalRoute.of(context)?.settings.arguments`. This is the "pass data
*to* another screen" requirement.

**Backward with data (AddItemScreen → Home):**
`HomeScreen` calls
`final newItem = await Navigator.push<TaskItem>(context, MaterialPageRoute(builder: (_) => const AddItemScreen()));`
and then **suspends** at that line. `AddItemScreen` builds a `TaskItem`
from the form fields and calls `Navigator.pop(context, newItem)`. Control
returns to `HomeScreen`, `newItem` is no longer null, and
`setState` adds it to the list. This is the "receive data when a route
is closed" requirement.

**Backward without data:**
- The `Cancel` button and the AppBar's automatic back arrow both call
  plain `Navigator.pop(context)` (no return value).
- `DetailScreen` has both the AppBar back arrow *and* an explicit
  "Back to Task List" button, so backward navigation is always
  clearly labeled and never hidden behind a single icon.

## Testing performed
Ran the app in the Android emulator (Pixel 6, API 34) and manually
walked every path:

1. **Home → Detail → back** — tapped each of the three seeded tasks,
   confirmed the correct title/note rendered on `DetailScreen`, then
   returned via both the AppBar arrow and the custom button. Stack
   depth was correct in both cases (single `pop`, no leftover routes).
2. **Home → Add → Save → Home** — filled in the form, tapped
   **Save Task**, confirmed the new task appeared at the bottom of the
   list and a `SnackBar` confirmed the addition.
3. **Home → Add → Cancel → Home** — confirmed no item was added and no
   crash occurred.
4. **Home → Add → device back button → Home** — Android's hardware
   back button also triggers `Navigator.pop` with no result; confirmed
   this is treated the same as **Cancel** (see troubleshooting below).
5. **Validation** — tried saving with an empty title; confirmed the
   form's validator blocked submission with an inline error instead of
   popping with bad data.

## Troubleshooting: issue found and fix

**Issue:** Initially `AddItemScreen` was registered as a *named* route
(`'/add'`) like the other screens, and `HomeScreen` called
`Navigator.pushNamed<TaskItem>(context, '/add')`. When the user pressed
the **device's hardware back button** (instead of the in-app Cancel
button) to leave `AddItemScreen`, the app crashed with:

```
type 'Null' is not a subtype of type 'TaskItem' in type cast
```

**Root cause:** The hardware back button calls the default
`Navigator.pop()` with no argument, so the future resolves to `null`.
The original code assumed a value would always come back and tried to
do `_items.add(newItem)` directly without a null check, and the
generic type parameter on `pushNamed<TaskItem>` made it worse by
attempting an implicit cast of `null` to `TaskItem`.

**Fix applied:**
1. Switched `AddItemScreen` from a named route to a direct
   `Navigator.push(context, MaterialPageRoute(...))`, which is simpler
   to reason about for a screen whose only job is to return a value.
2. Added an explicit `if (newItem != null)` guard in `HomeScreen`
   before touching the list, so both the hardware back button and the
   in-app **Cancel** button are handled the same, safe way.
3. Added a similar defensive null-check in `DetailScreen` for its route
   arguments, in case that screen is ever reached without data (e.g.
   during hot reload while already on that route).

This turned a crash-prone path into a normal, expected "user cancelled"
flow — a good illustration of why routes that *return* data should
always treat the popped value as optional.

## Project structure
```
multiscreen_nav_lab/
├── pubspec.yaml
└── lib/
    └── main.dart   # MyApp, HomeScreen, DetailScreen, AddItemScreen
```

## Running it
```bash
flutter pub get
flutter run
```
