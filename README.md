# Fireworks 50

A standalone Godot 4.6 demo of 50 procedural firework types — 40 real-world entries from backyard sparklers up through professional aerial shells, plus 10 speculative future-tech bursts.

No assets. Every visual is procedurally drawn via a custom particle engine using `Node2D._draw()` with additive blending.

## Run

Open `project.godot` in Godot 4.6+ and press F5.

## Controls

- `Space` — launch current firework / advance to next
- `B` — previous firework
- `R` — replay current firework
- `A` — toggle auto-advance

## Categories

| Range | Category |
|------:|----------|
| 1-10  | Real — Backyard / consumer |
| 11-20 | Real — Mid-tier cake / 200g |
| 21-40 | Real — Professional aerial |
| 41-50 | Futuristic / speculative |

## Architecture

- `scripts/world.gd` — sequencer, camera, input
- `scripts/firework_field.gd` — particle engine (integration, drawing, mortar physics)
- `scripts/firework_bursts.gd` — 50 burst function definitions + catalog
- `scripts/sky_background.gd` — procedural starfield + city silhouette
- `scripts/hud.gd` — centered banner

Mortars launch from the ground, follow ballistic physics with reduced gravity, get a brief hang at apex, then trigger their burst function. Each particle is a Dictionary with position, velocity, color, life, gravity, drag, optional trail, and optional on-death sub-burst.
