# Qoob

Qoob is a short first-person atmospheric puzzle game built in Godot 4 for macOS.

You begin in a barren ritual space facing the Qoob: a huge hovering alien cube about 100 feet ahead. The cube pulses, hums, watches, and punishes wrong movement. There is one level, one invisible movement-sequence maze, and exactly four valid paths to reach the Qoob.

## Gameplay

Qoob is not a free-look FPS. Movement is deliberate and step-based. Every input is one puzzle move:

- `F` means step forward toward the Qoob.
- `B` means step backward away from the Qoob.
- `L` means strafe left in an orbit around the Qoob.
- `R` means strafe right in an orbit around the Qoob.

The camera always faces the Qoob. Wrong moves reset the player to the start and increase the mistake counter. The first and second wrong moves show `Qoob hates that`. The third wrong move triggers lightning, `Qoob says: That was foolish.`, and Game Over. Reaching the Qoob shows a happy face and `Nice!`, then resets the session.

The four solution paths are documented with spoiler warnings in [docs/maze-design.md](docs/maze-design.md).

## Controls

Keyboard:

- `W` or `Up Arrow`: forward
- `A` or `Left Arrow`: strafe left
- `S` or `Down Arrow`: backward
- `D` or `Right Arrow`: strafe right

Mouse click regions:

- Bottom 28% of the screen: backward
- Left 33% of the screen, excluding the bottom region: strafe left
- Right 33% of the screen, excluding the bottom region: strafe right
- Remaining upper/center area: forward

## Run In Godot

1. Open Godot 4.6 or newer.
2. Import/open this folder as a Godot project.
3. Run `scenes/Main.tscn`, or press Play from the editor.

Command-line scene smoke test:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --scene res://scenes/Main.tscn --quit-after 3
```

## Export For macOS

The macOS export preset is named `macOS` and targets `dist/Qoob.app`.

```sh
mkdir -p dist
rm -rf dist/Qoob.app
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release macOS dist/Qoob.app
ditto -c -k --keepParent dist/Qoob.app dist/Qoob-mac.zip
```

## Launch The App

```sh
open dist/Qoob.app
```

This local build is not notarized. If macOS blocks launch because the app is unsigned or quarantined, see [docs/build-notes.md](docs/build-notes.md).

## Add Qoob To The Dock

1. Launch `dist/Qoob.app`.
2. Right-click the Qoob Dock icon.
3. Choose `Options`.
4. Choose `Keep in Dock`.

You can also drag `dist/Qoob.app` into `/Applications` first, then launch it from there before choosing `Keep in Dock`.

## Repository Structure

- `scenes/`: Godot scenes
- `scripts/`: gameplay, puzzle, input, and UI logic
- `assets/art/`: original icon art and generated app icon files
- `assets/audio/`: original procedural WAV audio
- `assets/materials/`: reserved for authored materials
- `assets/placeholders/`: reserved for future placeholder files
- `tests/`: headless Godot test runner
- `docs/`: design, QA, asset, and build documentation
- `tools/`: deterministic asset generation scripts
- `dist/`: local exported builds, ignored by git

## Testing

Run automated tests:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_runner.gd
```

Manual QA steps live in [docs/qa-checklist.md](docs/qa-checklist.md).

## Asset Policy

All committed art and audio are original, procedural, or MVP placeholders generated locally for this project. No commercial game assets, stock audio, or copyrighted third-party game assets are used. Every asset and placeholder is tracked in [docs/asset-inventory.md](docs/asset-inventory.md).

## Known Limitations

- The app is exported unsigned and unnotarized for local testing.
- The environment art is intentionally compact MVP procedural art.
- There is no mouse-look or free-roam movement by design.
- The current audio is procedural and final enough for MVP, but can be replaced with authored production audio later.
