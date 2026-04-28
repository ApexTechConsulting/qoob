# Qoob Maze Design

Spoiler warning: this document reveals the four valid solution paths.

## Model

The maze is a deterministic sequence graph implemented in `scripts/MazeGraph.gd`. The player starts at `start`. Each valid movement advances to a new graph state. Any invalid movement returns the player to the start state and increments the current session mistake count.

For the current playtest build, all four valid routes are also laid out visibly on the ground by `scripts/Main.gd`. These glowing traces are a readability aid and intentionally reveal the maze structure.

Movement labels:

- `F`: forward
- `B`: backward
- `L`: strafe left
- `R`: strafe right

## Solution Paths

There are exactly four success paths:

1. `F, R, F, L, F, F, R`
2. `R, F, R, B, R, F, F`
3. `L, F, F, R, F, L, F`
4. `F, F, L, B, L, F, R, F`

## Maintainability Notes

`MazeGraph.gd` stores the solution paths as data in `SOLUTION_PATHS`, then builds a transition graph from those arrays. Tests verify that the graph exposes exactly four success paths and that every listed path succeeds.
