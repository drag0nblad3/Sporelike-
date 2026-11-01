# Sporelike: notes for Claude

An evolution game in Godot 4.5 (GDScript), built for Android first and Windows second. The owner tests only on an Android phone, using the APK from the `playtest` release, so there is no local editor in the loop.

## Code layout rules

- **Keep files small and single-purpose.** One class per file, ideally under about 150 lines. Add a new file rather than growing an existing one into a catch-all, so a change only needs to read the file it touches.
- Build scenes in code. `scenes/main.tscn` is only a root node with `scripts/main.gd`; keep `main.gd` a thin wiring layer.
- Folders: `scripts/core` (pure data and rules, like `Genome`), `scripts/creatures` (organisms and their AI and visuals), `scripts/world` (arena, food, ecosystem), `scripts/ui` (HUD, joystick).
- Give every class a `class_name` and a `##` doc comment saying what it owns.
- Use explicit types where a value comes from a Dictionary or untyped Array; `:=` on a Variant is a compile error.

## Checking changes

- No Godot binary is available in the Claude environment. Run `gdparse` and `gdlint` from `pip install "gdtoolkit==4.*"` for syntax, then rely on CI.
- CI (`.github/workflows/build.yml`) runs the game headless for 15 game-seconds with `-- --smoke` (2-second generations, mutations auto-picked) and fails on any `SCRIPT ERROR`, then exports the APK and Windows build. Merges to `main` replace the `playtest` release.
