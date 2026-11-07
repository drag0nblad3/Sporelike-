# Sporelike: notes for Claude

An evolution game in Godot 4.5 (GDScript), built for Android first and Windows second. The owner tests only on an Android phone, using the APK from the `playtest` release, so there is no local editor in the loop.

## Code layout rules

- **Keep files small and single-purpose.** One class per file, ideally under about 150 lines. Add a new file rather than growing an existing one into a catch-all, so a change only needs to read the file it touches.
- Build scenes in code. `scenes/main.tscn` is only a root node with `scripts/main.gd`; keep `main.gd` (title screen to `Game`) and `game.gd` (one session) thin wiring layers.
- Folders: `scripts/core` (pure data and rules, like `Genome`, `BodyPlan`), `scripts/creatures` (organisms, colonies and their AI and visuals), `scripts/physics` (`SoftBody` springs, `SoftContact`, `IkChain`), `scripts/world` (arena, food, ecosystem, seaweed), `scripts/ui` (HUD, joystick).
- The multicellular stage runs inside `Game` through `StageTwo` (switch at the stage 1 goal, `ColonyPilot`, `ColonyChoices` for cell picks, feeding style and the final body that ends the stage). Cell effects live in `CellEffects`; bites and regrowth in `ColonyWounds`, `ColonyThreat` (hunters) and `ColonyBites` (rival colonies from `RivalColonies`); abilities in `ColonyAbility`/`ColonyCaster`. Stage 2 surroundings (`ColonyWorld`) follow the colony and change by sea region: `PlantKind` seaweed, `MarineSnow`, `RockField` rocks and vent chimneys, `Carrion` from dead rivals. Colonies swim at three `Depth` layers (floor, open water, surface; `DepthControl` buttons) and only touch, eat or bite things at their own depth; `CombJelly` hunters dive from the surface. At 40 cells (cap 60) `Shallows` puts a coast to the north (`ShoreLine` slope and tide, `ShoreLook`, `TidePools`); the final body is picked there and the colony hauls out (`ColonyPilot.haul_out`), the opening of the land stage 3 (plan: https://claude.ai/artifact/UhXB3wu2ft6y2sfQ97rf1i). Stage 2 generations last 120 s. The title screen's "Test stage 2" starts a throwaway game with a random evolved species (`EvolvedSpecies`) straight at the switch, without saving. `ColonyLab` is a sandbox used by CI and the screenshot tour.
- Give every class a `class_name` and a `##` doc comment saying what it owns.
- Use explicit types where a value comes from a Dictionary or untyped Array; `:=` on a Variant is a compile error.

## Checking changes

- No Godot binary is available in the Claude environment. Run `gdparse` and `gdlint` from `pip install "gdtoolkit==4.*"` for syntax, then rely on CI.
- CI (`.github/workflows/build.yml`) runs the game headless for 15 game-seconds with `-- --smoke` (2-second generations, mutations auto-picked, the save reloaded once at generation 2) and fails on any `SCRIPT ERROR`. Pull requests stop there. Merges build nothing; a manual run of the workflow (workflow_dispatch, e.g. the GitHub MCP `actions_run_trigger` on `main`) also exports the APK and replaces the `playtest` release. Only start one when Tyler asks for a build. No Windows build is made for now.
- Headless runs never draw, so CI also runs `-- --shot` under xvfb with the real renderer (`scripts/screenshot_tour.gd`): gameplay, a zoomed-out map, a far-away spot (chunk loading), pause menu, population screen and title. Artifact downloads are blocked from the Claude environment, so each shot is also printed to the job log as `shotb64 <name> <base64 jpeg chunk>` lines; decode them to look at UI changes.
- Make full-screen controls with `set_anchors_and_offsets_preset`, not `set_anchors_preset` (that left the pause menu zero-sized).
