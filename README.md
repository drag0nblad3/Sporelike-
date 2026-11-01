# Sporelike

An evolution game for Android and Windows, built with [Godot 4](https://godotengine.org/). You guide a species from a single cell upward by playing individual organisms and steering the population.

Current state: **evolution loop**. A population of cells eats, reproduces with small mutations and gets hunted by predators. You play one of them.

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
| `scripts/main.gd` | Wires the arena, ecosystem, player, camera and HUD together |
| `scripts/core/genome.gd` | Heritable traits (size, speed, sense, armor) and mutation |
| `scripts/creatures/` | `Organism` base class, its visuals, the player, AI species members, predators |
| `scripts/world/` | Arena, food field, and the ecosystem that runs eating, hunting and births |
| `scripts/ui/` | HUD text and the touch joystick |
| `export_presets.cfg` | Android and Windows export settings |

See `CLAUDE.md` for code conventions.
