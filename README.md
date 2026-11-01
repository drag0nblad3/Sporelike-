# Sporelike

An evolution game for Android and Windows, built with [Godot 4](https://godotengine.org/). You guide a species from a single cell upward by playing individual organisms and steering the population.

Current state: **generations**. A population of cells eats, reproduces with small mutations and gets hunted. You play one of them; between 90-second generations you see how the species changed, pick a mutation to encourage, and are reborn as one of your descendants.

## Playtest on Android

1. Open the [Latest playtest build](../../releases/tag/playtest) release on your phone (sign in to GitHub if asked).
2. Download `sporelike.apk` and open it. Allow installs from your browser if Android asks.
3. New builds install over the old one, so you don't need to uninstall first.

Controls: touch and drag anywhere on the left side of the screen to swim. On Windows, use WASD, the arrow keys, or click and drag.

## How builds work

Every push and pull request runs `.github/workflows/build.yml`, which:

1. Installs Godot and its export templates.
2. Runs the game headless for a few seconds and fails if any script errors appear.
3. Exports an Android APK and a Windows `.exe`, attached to the run as artifacts.
4. On `main`, replaces the **Latest playtest build** release with the new files.

The `ci/debug.keystore` file is a debug-only signing key with the standard public password `android`. It keeps every test build signed the same way so updates install cleanly. Never use it for a store release.

## Project layout

| Path | What it is |
| --- | --- |
| `scripts/main.gd` | Entry point: title screen, then starts or continues a `Game` |
| `scripts/game.gd` | One play session: wires the world together and runs the generation loop |
| `scripts/player_director.gd` | The player's current body: spawn, steering, camera, death |
| `scripts/core/` | `Genome` (eight heritable traits and mutation), `FoodKind` (the four food types and their patches), `SaveGame` (the save file) |
| `scripts/creatures/` | `Organism` base class, its visuals, the player, AI species members, predators |
| `scripts/world/` | Endless chunked sea floor (`ChunkStreamer`, `ChunkGenerator`, `WorldChunk`), blob-shaped food patches, food items, field and grid, the ecosystem that runs eating, hunting and births, and `GameSaver` |
| `scripts/ui/` | HUD, touch joystick, title screen, pause menu and glossary, population screen |
| `export_presets.cfg` | Android and Windows export settings |

See `CLAUDE.md` for code conventions.
