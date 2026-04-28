# Qoob Handoff

Generated: 2026-04-27 23:31:59 CDT  
Repository: `ApexTechConsulting/qoob`  
Local project path: `/Users/danielray/Documents/New project`  
Current local branch: `main`  
Current commit at handoff: `d68c7512cfbe6c8288066244ea28d42b022dfc26`  
Latest GitHub release at handoff: `v0.1.2`

## 1. Executive Summary

Qoob is a small original Godot 4 macOS desktop game. It is a first-person, step-based atmospheric puzzle game centered on an enormous hovering alien cube called the Qoob.

The current build is a playable MVP with:

- A title screen.
- A short loading screen.
- A single gameplay level.
- First-person camera presentation.
- No mouse-look and no continuous free-roam movement.
- Discrete step movement: forward, backward, strafe left, strafe right.
- A deterministic sequence-graph maze with exactly four valid solution paths.
- Visible ground route traces for playtesting.
- Wrong-move punish/reset behavior.
- Game Over after three wrong moves.
- Success feedback on reaching the Qoob.
- Original procedural art/audio.
- macOS export preset.
- Exported local app at `dist/Qoob.app`.
- GitHub releases containing zipped macOS builds.

The current art direction is an original procedural emulation of the lighting and material language visible in Lunaran's Quake 3 map page for `lun3dm5`: sky-lit grey concrete, blocky floating cuboid architecture, soft fog, dirty concrete seams, and broad blue-grey outdoor lighting. No Lunaran textures, Quake assets, or map geometry are copied into this repository.

## 2. Current State At Handoff

### GitHub

- Repository URL: <https://github.com/ApexTechConsulting/qoob>
- Owner/name: `ApexTechConsulting/qoob`
- Visibility: public
- Default branch: `main`
- Primary language: GDScript
- License: MIT
- Created: `2026-04-28T03:34:52Z`
- Latest release: `Qoob v0.1.2`
- Latest release URL: <https://github.com/ApexTechConsulting/qoob/releases/tag/v0.1.2>
- Open/closed GitHub issues at handoff: none returned by `gh issue list --state all`
- Open/closed GitHub pull requests at handoff: none returned by `gh pr list --state all`

### Local Workspace

- Root: `/Users/danielray/Documents/New project`
- Git status at handoff before this document: clean against `origin/main`
- Godot executable: `/Applications/Godot.app/Contents/MacOS/Godot`
- Godot version verified: `4.6.2.stable.official.71f334935`
- Export templates: `~/Library/Application Support/Godot/export_templates/4.6.2.stable`
- Current exported app: `/Users/danielray/Documents/New project/dist/Qoob.app`
- Current zipped app artifact: `/Users/danielray/Documents/New project/dist/Qoob-mac.zip`
- `dist/` is intentionally ignored by git and is not part of the repository tree.

### Dock State

The macOS Dock has a persistent app entry pointing to:

```text
file:///Users/danielray/Documents/New%20project/dist/Qoob.app/
```

The pinned Dock label is `Qoob`. Re-exporting to the same `dist/Qoob.app` path updates what the Dock launches.

### Latest Local Artifact Sizes

- `dist/Qoob.app`: approximately `177M`
- `dist/Qoob-mac.zip`: approximately `59M`

These artifacts are ignored and should be regenerated from source as needed.

## 3. Release History

### `v0.1.0`

- Tag points to commit: `4395ec8428f04075d9ab416fc3c145fba1eef5ee`
- Release URL: <https://github.com/ApexTechConsulting/qoob/releases/tag/v0.1.0>
- Published: `2026-04-28T03:53:53Z`
- Asset: `Qoob-mac.zip`
- Asset size: `61926695` bytes
- Asset SHA-256 digest: `7d3955abd1c133f2ec092406c2d815ead21648d9ff42e16a27dcbf0ec1974652`
- Release note summary: first playable Godot 4 macOS MVP with title/loading/gameplay flow, maze, procedural art/audio, docs, tests, and unsigned local macOS app build.

### `v0.1.1`

- Tag points to commit: `344e449009dc72ee5f172774866293a54fb230e6`
- Release URL: <https://github.com/ApexTechConsulting/qoob/releases/tag/v0.1.1>
- Published: `2026-04-28T04:15:50Z`
- Asset: `Qoob-mac.zip`
- Asset size: `62006722` bytes
- Asset SHA-256 digest: `eadf8d16a9dd48907c2b6a61b62a10966e613c87d195d697f8c534da77824d16`
- Release note summary: spectral black-space visual pass, prismatic Qoob VFX, visible glowing ground maze, louder continuous procedural Qoob hum.

### `v0.1.2`

- Tag points to commit: `d68c7512cfbe6c8288066244ea28d42b022dfc26`
- Release URL: <https://github.com/ApexTechConsulting/qoob/releases/tag/v0.1.2>
- Published: `2026-04-28T04:30:03Z`
- Asset: `Qoob-mac.zip`
- Asset size: `62012153` bytes
- Asset SHA-256 digest: `ab4564b1230d1dca620ab8b58658c0296ebc18fab4a5feda60804ea45018f94c`
- Release note summary: concrete sky-map art pass inspired by Lunaran's `lun3dm5` lighting/material language, procedural matte concrete cuboid architecture, soft blue sky/fog lighting, cloud planes, subdued ground maze paths.

## 4. Commit History

Current main history:

```text
d68c751 (HEAD -> main, origin/main, tag: v0.1.2) Emulate lun3dm5 concrete sky lighting
344e449 (tag: v0.1.1) Rebuild Qoob spectral art and audible hum
4395ec8 (tag: v0.1.0) Finalize macOS export settings
4c0ad7f Add tests docs and macOS export setup
b62b0ea Add playable Qoob game flow
d3535fd Initialize Godot project structure
```

## 5. Gameplay Design

### Core Concept

Qoob is a short first-person atmospheric puzzle game. The player begins facing a giant alien cube hovering slightly above the ground approximately 100 feet ahead. The player must move through a sequence maze to reach the Qoob.

### Level Structure

1. Title screen.
2. Loading screen.
3. One gameplay level.
4. Success/failure/reset loop.
5. Game Over state after three wrong moves.

### Movement

Movement is discrete and step-based. There is no free-roam WASD movement and no mouse-look.

Internal movement labels:

- `F`: forward
- `B`: backward
- `L`: strafe left
- `R`: strafe right

Current movement constants in `scripts/Main.gd`:

- `START_RADIUS := 100.0`
- `PLAYER_HEIGHT := 3.2`
- `QOOB_CENTER := Vector3(0.0, 13.0, 0.0)`
- `QOOB_LOOK_TARGET := Vector3(0.0, 7.6, 0.0)`
- `FORWARD_STEP := 11.0`
- `BACKWARD_STEP := 8.0`
- `STRAFE_STEP := 0.244346`
- `MOVE_TIME := 0.52`

The player position is represented by polar/orbital state around the Qoob:

- `orbit_radius`
- `orbit_angle`

Forward/backward alter radius. Left/right alter angle. Camera always looks back toward the Qoob target.

### Controls

Keyboard:

- `W`: forward
- `A`: strafe left
- `S`: backward
- `D`: strafe right
- `Up Arrow`: forward
- `Left Arrow`: strafe left
- `Down Arrow`: backward
- `Right Arrow`: strafe right

Mouse click regions in `scripts/MoveInput.gd`:

- Bottom region begins at `BOTTOM_REGION_RATIO := 0.72`; clicks at or below 72% of viewport height map to backward.
- Left side uses `LEFT_REGION_RATIO := 0.33`; clicks left of 33% viewport width, excluding bottom region, map to strafe left.
- Right side uses `RIGHT_REGION_RATIO := 0.67`; clicks right of 67% viewport width, excluding bottom region, map to strafe right.
- Remaining upper/center area maps to forward.

### Maze

The deterministic maze lives in `scripts/MazeGraph.gd`.

Start state:

```gdscript
const START_STATE := "start"
```

Solution paths:

```text
1. F, R, F, L, F, F, R
2. R, F, R, B, R, F, F
3. L, F, F, R, F, L, F
4. F, F, L, B, L, F, R, F
```

`MazeGraph.gd` builds a transition graph from `SOLUTION_PATHS` and tracks terminal success states. Invalid moves return a dictionary with `valid: false`, `state: start`, `success: false`.

### Failure Loop

Handled by `scripts/GameSession.gd` and presentation code in `scripts/Main.gd`.

Outcomes:

- `progress`: valid move, path continues.
- `success`: reached a success terminal state; session resets.
- `wrong_reset`: invalid move before third mistake; player position resets to start, mistake count remains.
- `game_over`: third invalid move; Game Over screen.

Wrong move feedback:

- First and second wrong moves:
  - Text: `Qoob hates that`
  - Plays wrong screech.
  - Darkens overlay.
  - Resets player view/start position.
- Third wrong move:
  - Text: `Qoob says: That was foolish.`
  - Plays wrong screech and storm/lightning audio.
  - Spawns procedural lightning UI rectangles.
  - Shows Game Over.

Success feedback:

- Text: `:)` and `Nice!`
- Plays success chime.
- Moves camera closer to Qoob briefly.
- Resets session and player view.

## 6. Current Art Direction

### Current Visual Target

The current version emulates the broad lighting/material feel of Lunaran's `lun3dm5`:

- Open blue sky.
- Grey fog/haze.
- Matte concrete.
- Soft sky/dome illumination.
- Sparse hard sun with muted shadows.
- Massive blocky concrete structures.
- Offset cuboid "cubespew" massing.
- Dirty seams/edge grime through procedural shader.

Reference page used for style study:

```text
https://lunaran.com/maps/quake3/lun3dm5/
```

Important copyright/art note: this project does not include the referenced page's images, map files, textures, or geometry. The look is procedurally rebuilt with original Godot code.

### Current Scene Elements

Everything in the gameplay world is built procedurally at runtime in `scripts/Main.gd`.

Major visual builders:

- `_build_world()`: sets up environment, fog, lights, ground, Qoob, maze, set dressing, motes, and camera.
- `_build_dome_fill_lights()`: adds multiple low-energy directional lights to fake sky-dome fill.
- `_build_cloud_deck()`: creates translucent sky cloud planes.
- `_build_qoob()`: creates cube mesh, Qoob shader, edge filaments, field rings, and Qoob pulse light.
- `_build_qoob_edges()`: builds subtle energized Qoob edge strips and chromatic offsets.
- `_build_visible_maze()`: draws all four valid maze paths on the ground.
- `_build_set_dressing()`: creates procedural concrete architecture.
- `_build_concrete_cluster()`: generates offset concrete tower/cluster blocks.
- `_build_concrete_bridge()`: generates concrete sky bridges.
- `_add_concrete_block()`: creates individual BoxMesh concrete blocks with extra dirty edge lips.
- `_build_motes()`: creates sparse atmospheric sky dust motes.

Dormant legacy visual helpers still exist from the previous spectral pass:

- `_build_prism_shards()`
- `_build_spectral_ribbons()`
- `_build_spectral_beams()`

They are not currently invoked by `_build_world()` or `_build_qoob()` in the `v0.1.2` concrete pass. They can be deleted in a cleanup pass or reintroduced if a hybrid style is desired.

### Current UI Style

The UI uses Godot default Control/Button/Label styling with custom colors and sizes. It is functional and acceptable for MVP, but still listed as a placeholder in the asset inventory.

Screens:

- Title screen with `Qoob`, Start, Quit, and hint text.
- Loading screen with text `The concrete sky is waking...`.
- Gameplay HUD with strike counter, feedback text, and overlay.
- Game Over screen with Restart and Quit to Title.

## 7. Audio

All audio is procedural and generated by `tools/generate_audio.mjs`.

Tracked audio files:

- `assets/audio/qoob_hum.wav`
- `assets/audio/wrong_screech.wav`
- `assets/audio/lightning_storm.wav`
- `assets/audio/success_chime.wav`

Runtime players in `scripts/Main.gd`:

- `hum_player`
- `effect_player`
- `storm_player`
- `success_player`

Hum behavior:

- On title screen: `_play_hum(-13.0)`
- During gameplay: `_play_hum(-2.5)`
- On Game Over: `_play_hum(-7.0)`

This is intentional: the hum should be present quietly from title and much more audible during gameplay.

Known audio limitation:

- Audio is mono WAV generated by script. Future polish could add stereo spatialization, better mixing, and richer layered ambience.

## 8. Project Structure

Top-level directories:

- `assets/`: tracked art/audio assets plus reserved material/placeholder directories.
- `docs/`: supporting documentation.
- `scenes/`: Godot scenes.
- `scripts/`: GDScript gameplay, rendering, input, and session logic.
- `tests/`: Godot headless test runner.
- `tools/`: asset-generation scripts.
- `ui/`: reserved UI directory.
- `dist/`: ignored exported local builds. Not tracked.
- `.godot/`: ignored Godot import/editor cache. Not tracked.

## 9. Godot Project Configuration

Project file: `project.godot`

Important settings:

```ini
config_version=5
config/name="Qoob"
run/main_scene="res://scenes/Main.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://assets/art/icon.svg"
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/mode=2
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
renderer/rendering_method="forward_plus"
textures/vram_compression/import_etc2_astc=true
```

The ETC2/ASTC import setting is required for the universal macOS export preset.

## 10. macOS Export Configuration

Export file: `export_presets.cfg`

Preset:

- Name: `macOS`
- Platform: `macOS`
- Runnable: true
- Export path: `dist/Qoob.app`
- Export filter: `all_resources`
- Exclude filter: `dist/**,build/**,docs/**,tools/**`
- Binary architecture: `universal`
- Icon: `res://assets/art/Qoob.icns`
- Bundle identifier: `com.apextechconsulting.qoob`
- Category: `Games`
- Version: `1.0.0`
- Code signing: disabled
- Notarization: disabled

Important note: `docs/` and `tools/` are excluded from export so the game package does not bundle documentation or generation scripts. Tests are currently not excluded and do get packed as compiled scripts because `export_filter="all_resources"` includes them; this is harmless but can be tightened later by adding `tests/**` to `exclude_filter`.

## 11. Build, Test, Export, Launch

### Run Tests

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
```

Expected current output:

```text
All Qoob tests passed.
```

### Run Scene Smoke Test

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/Main.tscn --quit-after 3
```

Current note: this headless forced-quit path may report an ObjectDB/resource cleanup warning on shutdown. The warning has not blocked scene load, tests, export, or normal macOS app launch.

### Regenerate Audio

```sh
node tools/generate_audio.mjs
```

### Regenerate Icon

```sh
tools/generate_iconset.sh
```

This uses:

- Node.js for `tools/generate_icon_png.mjs`
- macOS `sips`
- macOS `iconutil`

### Export macOS App

```sh
mkdir -p dist
rm -rf dist/Qoob.app
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release macOS dist/Qoob.app
ditto -c -k --keepParent dist/Qoob.app dist/Qoob-mac.zip
```

### Launch

```sh
open dist/Qoob.app
```

### Direct Binary Launch For Debugging

```sh
dist/Qoob.app/Contents/MacOS/Qoob --verbose
```

### Gatekeeper/Quarantine Local Workaround

The app is unsigned and unnotarized. If macOS blocks launch:

```sh
xattr -dr com.apple.quarantine dist/Qoob.app
open dist/Qoob.app
```

Do not represent the current build as signed or notarized.

## 12. Automated Tests

Test file: `tests/test_runner.gd`

The test runner extends `SceneTree` and exits with code `1` if any assertions fail.

Coverage:

- Exactly four solution paths are defined.
- Maze graph exposes exactly four success paths.
- All four valid paths succeed.
- Invalid move from start fails.
- First wrong move increments mistakes and resets.
- Second wrong move increments mistakes and resets.
- Third wrong move triggers Game Over.
- Success resets maze state and mistake count.
- WASD mapping.
- Arrow-key mapping.
- Mouse region mapping.

Tests deliberately focus on deterministic logic instead of rendering.

## 13. Source Architecture

### `scenes/Main.tscn`

Minimal Godot scene:

- Root node: `Node`
- Script: `res://scripts/Main.gd`

Most content is generated at runtime by `Main.gd`.

### `scripts/MazeGraph.gd`

Purpose: deterministic sequence graph for the puzzle maze.

Key constants:

- `START_STATE`
- `MOVE_FORWARD`
- `MOVE_BACKWARD`
- `MOVE_LEFT`
- `MOVE_RIGHT`
- `SOLUTION_PATHS`

Key methods:

- `_build_graph()`
- `apply_move(state, move)`
- `get_valid_moves(state)`
- `count_success_paths()`
- `get_solution_paths()`

### `scripts/GameSession.gd`

Purpose: session-level maze state and mistake count.

Key outcomes:

- `OUTCOME_PROGRESS`
- `OUTCOME_SUCCESS`
- `OUTCOME_WRONG_RESET`
- `OUTCOME_GAME_OVER`

Key methods:

- `reset_session()`
- `reset_maze_position()`
- `apply_move(move)`

### `scripts/MoveInput.gd`

Purpose: maps Godot input events into maze move labels.

Key methods:

- `from_event(event, viewport_size)`
- `from_key_event(event)`
- `from_keycode(keycode)`
- `from_mouse_position(position, viewport_size)`

### `scripts/Main.gd`

Purpose: runtime game assembly, rendering, UI, audio, input dispatch, movement animation, success/failure presentation, procedural art.

Key grouped responsibilities:

- Lifecycle: `_ready`, `_process`, `_unhandled_input`
- Gameplay input and movement: `process_move`, `_animate_step`, `_animate_to_qoob`, `reset_player_view`, `_update_player_camera`
- World generation: `_build_world`, `_build_dome_fill_lights`, `_build_cloud_deck`, `_build_qoob`, `_build_visible_maze`, `_build_set_dressing`, `_build_motes`
- Procedural concrete architecture: `_build_concrete_cluster`, `_build_concrete_bridge`, `_add_concrete_block`
- Qoob VFX: `_build_qoob_edges`, `_update_qoob`, `_make_qoob_shader_material`
- UI: `_build_ui`, `_build_title_screen`, `_build_loading_screen`, `_build_hud`, `_build_game_over_screen`, `_show_only`
- Audio: `_build_audio`, `_load_audio`, `_play_hum`, `_stop_hum`
- Feedback: `_show_wrong_move_sequence`, `_show_final_failure_sequence`, `_show_success_sequence`, `_spawn_lightning_burst`
- Materials/mesh helpers: `_make_concrete_material`, `_make_emissive_material`, `_make_additive_material`, `_add_box_line`, `_make_triangle_mesh`

### `tools/generate_audio.mjs`

Purpose: generate original procedural WAV audio.

Outputs:

- `qoob_hum.wav`
- `wrong_screech.wav`
- `lightning_storm.wav`
- `success_chime.wav`

Uses a deterministic pseudo-random generator and raw PCM WAV writing.

### `tools/generate_icon_png.mjs`

Purpose: generate original 1024x1024 PNG art for the app icon without third-party dependencies.

It implements:

- Pixel buffer generation.
- Polygon fills.
- Circle/line/arc drawing.
- PNG chunk writing.
- CRC32.
- DEFLATE compression through Node's built-in `zlib`.

Output:

- `assets/art/Qoob_icon_1024.png`

### `tools/generate_iconset.sh`

Purpose: convert the generated PNG into a macOS `.iconset` and `.icns`.

Uses:

- `sips`
- `iconutil`

Outputs:

- `assets/art/Qoob.iconset/`
- `assets/art/Qoob.icns`

## 14. Asset Policy

All tracked assets are original, procedural, generated locally, or default Godot UI/font usage.

Explicitly not used:

- No World of Warcraft assets.
- No Blizzard assets.
- No Quake 3 assets.
- No Lunaran map files.
- No Lunaran textures.
- No copied commercial game audio.
- No stock audio.

Reference material has been used only for broad art-direction and lighting vocabulary.

## 15. Known Limitations And Risks

- App is unsigned and unnotarized.
- UI is still default Godot-style and listed as placeholder.
- `tests/` is currently packed into export because export filter is `all_resources` and only `dist/**,build/**,docs/**,tools/**` are excluded.
- The visual level is runtime-generated in a single large `scripts/Main.gd` file. This is fast for MVP but should eventually be split into systems/resources.
- Some dormant spectral-pass helper functions remain in `Main.gd`; remove or rewire later.
- The visible ground maze intentionally reveals the solution paths for playtesting. A final version may hide the paths or reveal only partial clues.
- Audio is mono procedural WAV. Future production pass could add stereo, reverb, dynamic filtering, and spatial 3D audio.
- No code signing/notarization pipeline exists yet.
- No CI workflow exists yet.
- No GitHub Actions are configured.
- There are currently no PR templates, issue templates, or contribution docs.

## 16. Suggested Next Work

Highest-value next steps:

1. Split `scripts/Main.gd` into smaller scripts:
   - `WorldBuilder.gd`
   - `QoobVisuals.gd`
   - `VisibleMazeRenderer.gd`
   - `GameUI.gd`
   - `AudioController.gd`
2. Add `tests/**` to export exclusion unless runtime tests are wanted in app packages.
3. Decide whether visible maze should remain permanent or become a tutorial/debug option.
4. Add a settings/debug toggle for:
   - show/hide maze route overlay
   - hum volume
   - fullscreen/windowed
5. Replace default UI theme with a custom concrete/Qoob UI theme.
6. Add visual screenshot QA automation for exported app.
7. Add GitHub Actions for:
   - headless Godot tests
   - macOS export
   - release artifact upload
8. Configure Developer ID signing and notarization.
9. Add changelog.
10. Make `docs/asset-inventory.md` update mandatory when asset-generation scripts change.

## 17. Complete Repository File Listing

There were 67 tracked files immediately before this handoff file was created. After committing this document, the repository contains those 67 files plus `Qoob_Handoff.md`.

### Exact Git Tree Entries

This is the exact `git ls-files -s | sort` output at handoff before adding `Qoob_Handoff.md`. The handoff file itself is listed in the human-readable inventory below; embedding its final blob hash inside itself would change the hash.

```text
100644 02e293e366a152f6d3015dc58e254eee40a2d360 0	assets/art/Qoob.iconset/icon_512x512@2x.png.import
100644 035d4469f2d20423edff7d38ac4389a7abf1802c 0	tests/test_runner.gd
100644 0707e9a06b83092acdaf5e99a318c117311151ce 0	tools/generate_icon_png.mjs
100644 0e72b2b81efc7e0fd974a05ba96e91d9dce0895e 0	scripts/MazeGraph.gd.uid
100644 10cc6b3d7a1810955d4c66a622ae918080feca9a 0	assets/art/Qoob.iconset/icon_256x256@2x.png
100644 10cc6b3d7a1810955d4c66a622ae918080feca9a 0	assets/art/Qoob.iconset/icon_512x512.png
100644 13bcff51d12cf7fb2c6e580dd881ebe4e5362d6a 0	assets/audio/success_chime.wav
100644 1d4ff8040785a69cb68bd9bf596d2a547e210de4 0	tests/test_runner.gd.uid
100644 24b7034a345354c996f92af386f234dac2970556 0	assets/art/Qoob.iconset/icon_32x32@2x.png.import
100644 28fc678af4e75536217998623e298f86a6036778 0	assets/art/Qoob.iconset/icon_256x256.png.import
100644 3a6b6ff992604e3dcf6006a93b04a2d99f8805cd 0	docs/asset-inventory.md
100644 3fd10d4ccabc6e704005623f1f6647b75f364cf7 0	scripts/MoveInput.gd
100644 44a42b106d023066e6f193ddfb6280f403ae7086 0	assets/art/Qoob.iconset/icon_32x32.png.import
100644 464a3e07f4cd727157088ab349a95062aa996325 0	assets/art/Qoob.iconset/icon_32x32@2x.png
100644 525f8be8f8df13cdda234dd9b14116162d220842 0	docs/maze-design.md
100644 5294250d9edcb16b310d6d54d832545c983ebe27 0	assets/art/Qoob.icns
100644 5a5b6f4a56f608b4e3c3071087f2f30f0660ee06 0	README.md
100644 5f5d5ecbc51b49d3cfde8988ee4472665d373563 0	assets/art/icon.svg
100644 61e99fccc655f75461b5a9d43af705d1c6090e24 0	assets/art/Qoob.iconset/icon_128x128@2x.png.import
100644 6432a9ad54b1f0c20dc67ef2e428444a439ca09a 0	assets/art/Qoob.iconset/icon_16x16@2x.png
100644 6432a9ad54b1f0c20dc67ef2e428444a439ca09a 0	assets/art/Qoob.iconset/icon_32x32.png
100644 6830ad986c60a7b174f498b45a48a510a535edc3 0	assets/art/Qoob.iconset/icon_128x128.png.import
100644 727903b82376a8a12154ea98672ef28a9db6ce43 0	assets/audio/wrong_screech.wav
100644 7cd82fdecd8dbf6f914ecf642a52932b9d788839 0	scripts/GameSession.gd
100644 7e45609aec6b619bc06a66e3e444a5850f2586ed 0	assets/art/Qoob.iconset/icon_16x16.png.import
100644 7eb51521ec4ac405a4ea1af01926131db55d2b9e 0	assets/art/icon.svg.import
100644 82a0b699234eaf7cd1827a7c79cd20d0e520a97f 0	assets/audio/qoob_hum.wav
100644 867ea3073ff589adffd240280a4eef956a65a9df 0	docs/build-notes.md
100644 8af499ffdb5db6004317c5aff6b14fe08ea2441d 0	scenes/Main.tscn
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	assets/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	assets/art/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	assets/audio/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	assets/materials/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	assets/placeholders/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	docs/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	scenes/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	scripts/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	tests/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	tools/.gitkeep
100644 8b137891791fe96927ad78e64b0aad7bded08bdc 0	ui/.gitkeep
100644 935053dc39325715d818ae48af35bcf52481aa5c 0	assets/art/Qoob.iconset/icon_512x512.png.import
100644 936871aff09f245e52da021d0e308b3fa5d71a74 0	assets/art/Qoob.iconset/icon_256x256@2x.png.import
100644 944fdbf2264ad00a16cb049fc68cc53b1bd83f8c 0	assets/audio/qoob_hum.wav.import
100644 a3312161ec830a379d2f4b97ac0d48b5ea9b1950 0	project.godot
100644 a89cf1471a08fc09a75a2d786592d8e9d8a630fb 0	assets/art/Qoob.iconset/icon_16x16@2x.png.import
100644 adef2efbb4d8446bb2e7b4424b2c65e6b3a0ce6e 0	assets/art/Qoob.iconset/icon_16x16.png
100644 b0d348d7704b090d8893d08ad2b4acd7af7bfe55 0	assets/art/Qoob.iconset/icon_128x128@2x.png
100644 b0d348d7704b090d8893d08ad2b4acd7af7bfe55 0	assets/art/Qoob.iconset/icon_256x256.png
100644 c501777c6e72cfe1d0265dd1fe266e8abe4cdfb8 0	assets/art/Qoob.iconset/icon_128x128.png
100644 c5b9376fd420d65c0fc50c4e750b48792912860d 0	scripts/MoveInput.gd.uid
100644 ca6199ef2c4df6d94cc8b857248ac17231d3d37c 0	scripts/MazeGraph.gd
100644 caa86fe615a46267bfdc9cf0d4c58923b56e33ed 0	scripts/Main.gd
100644 ce07e719064e7e1805f6f6bd62e18fd69f3c533e 0	assets/audio/lightning_storm.wav.import
100644 ce4fb5ecb424dbdfe91efebf19a3e9ff52c23691 0	LICENSE
100644 cf30d9b690c7934b34ce2f606a74840a9b1a5540 0	assets/audio/success_chime.wav.import
100644 da4e55dec3ba34d8b2732cd952686f6a2fb9208d 0	assets/art/Qoob.iconset/icon_512x512@2x.png
100644 da4e55dec3ba34d8b2732cd952686f6a2fb9208d 0	assets/art/Qoob_icon_1024.png
100644 dbcb9f9b9323acf93b0c77fe0cda323e083a37f5 0	scripts/Main.gd.uid
100644 df3088de4a34236a709c054bf59899aa42e02986 0	scripts/GameSession.gd.uid
100644 e68e70d2e7100e331bf4c9b7721ad54e2cc4928a 0	.gitignore
100644 e7b1a93b21f7dcaee0f31f52b2db79a15ffab5d3 0	tools/generate_audio.mjs
100644 e81c1e8ea28536ca0c62845a51a5457bd9f653ec 0	docs/qa-checklist.md
100644 ef8b37bec704a10ddc432f95954b5d2dc26982cd 0	assets/audio/wrong_screech.wav.import
100644 faf0280a9aea2f71436f51aa0d8ebba050323aff 0	assets/art/Qoob_icon_1024.png.import
100644 fd22cb7eb527500397ab727c578864da961fcc32 0	assets/audio/lightning_storm.wav
100644 fe3c4efac51a53aaef954ab2f5d89544f77dbd3a 0	export_presets.cfg
100755 5da86a4b7452356b88e18a72ead4f78b54b050ec 0	tools/generate_iconset.sh
```

### Human-Readable Repository Inventory

Root:

- `.gitignore`: ignores Godot cache, exported builds, macOS `.DS_Store`, logs, temporary files.
- `LICENSE`: MIT License.
- `Qoob_Handoff.md`: this comprehensive handoff document.
- `README.md`: primary project overview, controls, build/export instructions, known limitations.
- `export_presets.cfg`: Godot macOS export preset.
- `project.godot`: Godot project configuration.

Assets:

- `assets/.gitkeep`: placeholder to preserve directory.
- `assets/art/.gitkeep`: placeholder.
- `assets/art/icon.svg`: original vector icon source.
- `assets/art/icon.svg.import`: Godot import metadata.
- `assets/art/Qoob_icon_1024.png`: generated source PNG for app icon.
- `assets/art/Qoob_icon_1024.png.import`: Godot import metadata.
- `assets/art/Qoob.icns`: generated macOS app icon.
- `assets/art/Qoob.iconset/icon_16x16.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_16x16.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_16x16@2x.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_16x16@2x.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_32x32.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_32x32.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_32x32@2x.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_32x32@2x.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_128x128.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_128x128.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_128x128@2x.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_128x128@2x.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_256x256.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_256x256.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_256x256@2x.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_256x256@2x.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_512x512.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_512x512.png.import`: Godot import metadata.
- `assets/art/Qoob.iconset/icon_512x512@2x.png`: generated iconset PNG.
- `assets/art/Qoob.iconset/icon_512x512@2x.png.import`: Godot import metadata.
- `assets/audio/.gitkeep`: placeholder.
- `assets/audio/qoob_hum.wav`: generated looping Qoob hum.
- `assets/audio/qoob_hum.wav.import`: Godot import metadata.
- `assets/audio/wrong_screech.wav`: generated wrong-move screech.
- `assets/audio/wrong_screech.wav.import`: Godot import metadata.
- `assets/audio/lightning_storm.wav`: generated third-failure storm cue.
- `assets/audio/lightning_storm.wav.import`: Godot import metadata.
- `assets/audio/success_chime.wav`: generated success cue.
- `assets/audio/success_chime.wav.import`: Godot import metadata.
- `assets/materials/.gitkeep`: reserved directory placeholder.
- `assets/placeholders/.gitkeep`: reserved directory placeholder.

Docs:

- `docs/.gitkeep`: placeholder.
- `docs/asset-inventory.md`: asset inventory and placeholder status.
- `docs/build-notes.md`: build/export/signing notes.
- `docs/maze-design.md`: spoiler maze solution paths and implementation notes.
- `docs/qa-checklist.md`: manual and automated QA checklist.

Scenes:

- `scenes/.gitkeep`: placeholder.
- `scenes/Main.tscn`: minimal main scene with root `Node` and `scripts/Main.gd`.

Scripts:

- `scripts/.gitkeep`: placeholder.
- `scripts/Main.gd`: main runtime, procedural world, UI, audio, movement, and feedback.
- `scripts/Main.gd.uid`: Godot UID metadata.
- `scripts/MazeGraph.gd`: deterministic maze graph data/model.
- `scripts/MazeGraph.gd.uid`: Godot UID metadata.
- `scripts/GameSession.gd`: session state, mistakes, outcome handling.
- `scripts/GameSession.gd.uid`: Godot UID metadata.
- `scripts/MoveInput.gd`: keyboard/mouse to movement-label mapping.
- `scripts/MoveInput.gd.uid`: Godot UID metadata.

Tests:

- `tests/.gitkeep`: placeholder.
- `tests/test_runner.gd`: headless automated tests.
- `tests/test_runner.gd.uid`: Godot UID metadata.

Tools:

- `tools/.gitkeep`: placeholder.
- `tools/generate_audio.mjs`: procedural audio generator.
- `tools/generate_icon_png.mjs`: dependency-free PNG icon generator.
- `tools/generate_iconset.sh`: macOS iconset/ICNS generation wrapper.

UI:

- `ui/.gitkeep`: reserved directory placeholder.

## 18. Ignored/Untracked Runtime Outputs

The following important local paths are intentionally not in git:

- `.godot/`: Godot editor/import/cache directory.
- `dist/`: exported app and zip.
- `build/`: reserved ignored build output path.
- `.DS_Store`: macOS metadata.
- `*.log`, `*.tmp`: temporary files.

Current useful ignored artifacts:

- `dist/Qoob.app`
- `dist/Qoob-mac.zip`

## 19. Operational Checklist For Next Developer

1. Clone repo:

   ```sh
   git clone https://github.com/ApexTechConsulting/qoob.git
   cd qoob
   ```

2. Open in Godot 4.6 or newer.

3. Run tests:

   ```sh
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
   ```

4. Run or inspect scene:

   ```sh
   /Applications/Godot.app/Contents/MacOS/Godot --path .
   ```

5. Export:

   ```sh
   mkdir -p dist
   rm -rf dist/Qoob.app
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release macOS dist/Qoob.app
   ditto -c -k --keepParent dist/Qoob.app dist/Qoob-mac.zip
   ```

6. Launch:

   ```sh
   open dist/Qoob.app
   ```

7. If publishing a new release:

   ```sh
   gh release create vX.Y.Z dist/Qoob-mac.zip --title "Qoob vX.Y.Z" --notes "..."
   ```

8. If the app is meant for wider distribution, implement signing and notarization first.

## 20. Final Handoff Notes

Qoob is playable and version-controlled. The strongest current implementation qualities are deterministic puzzle logic, procedural asset provenance, macOS exportability, and a cohesive concrete sky-map art pass. The biggest technical debt is that `scripts/Main.gd` now owns too many responsibilities. The cleanest next engineering step is to split that file into focused components while preserving the deterministic maze/test suite.

The project is intentionally compact, so a new developer should be able to understand the full game in one sitting: read `README.md`, then `scripts/MazeGraph.gd`, `scripts/GameSession.gd`, `scripts/MoveInput.gd`, and finally `scripts/Main.gd`.
