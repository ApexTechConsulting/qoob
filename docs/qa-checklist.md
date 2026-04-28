# Qoob QA Checklist

## Automated

- Run `Godot --headless --path . --script tests/test_runner.gd`.
- Confirm all tests pass.

## Manual Launch Flow

- Launch the Godot project from the editor.
- Launch the exported app with `open dist/Qoob.app`.
- Confirm the app is named `Qoob` in the macOS app menu and Dock.

## Title And Loading

- Confirm the title screen shows `Qoob`.
- Confirm `Start` begins the game.
- Confirm `Quit` exits from the title screen.
- Confirm the loading screen appears briefly before gameplay.

## Gameplay

- Confirm the player starts facing the giant Qoob.
- Confirm the Qoob is roughly 100 feet ahead, hovering just above the ground.
- Confirm a low phasing Qoob hum is audible on the title screen and louder during gameplay.
- Confirm the ground maze is visible as glowing paths with arrows and movement glyphs.
- Confirm the Qoob remains centered or nearly centered after every movement.
- Confirm there is no mouse-look and no continuous free-roam movement.
- Confirm `W`, `A`, `S`, `D` movement works.
- Confirm arrow-key movement works.
- Confirm mouse click regions work:
  - upper/center moves forward
  - left side strafes left
  - right side strafes right
  - bottom moves backward

## Puzzle Outcomes

- Confirm each documented path in `docs/maze-design.md` reaches the Qoob.
- Confirm a first wrong move shows `Qoob hates that`, plays the screech, darkens the sky, and resets position.
- Confirm a second wrong move repeats the punishment and keeps the mistake counter.
- Confirm a third wrong move triggers lightning, `Qoob says: That was foolish.`, and Game Over.
- Confirm Game Over shows `Restart` and `Quit to Title`.
- Confirm `Restart` resets the mistake count.
- Confirm reaching the Qoob shows a happy face and `Nice!`.
- Confirm success resets the player and mistake count.

## Export

- Confirm `dist/Qoob.app` exists after export.
- Confirm `dist/Qoob-mac.zip` exists after packaging.
- Confirm the exported app opens on macOS.
- Confirm the app can be kept in the Dock using Dock `Options > Keep in Dock`.
