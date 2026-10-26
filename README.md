# Ragnarok-like Game — Phase 1 Scaffold

A playable Godot 4 starting point: walk around, collide with the world,
and travel between town and field. No combat, monsters, items, or quests
yet — those are later phases.

## How to run it (Windows)

1. Install Godot 4 (any 4.x version; this was written for the 4.x scene format).
2. Open Godot, choose **Import**, and pick this folder's `project.godot`
   (or **Project > Open** if it is already in your project list).
3. Press **F5** (or the Play button, top right).

You should spawn in town as a blue box character.

## Controls

- **WASD** or **arrow keys** — move
- Walk into the glowing blue portal at the top of town to go to the field
- Walk into the glowing portal at the bottom of the field to return to town

Collision is real: houses, trees, rocks, and the map edges block you.
The camera follows the player.

## What is in here

```
project.godot                  Main scene = town, GameManager autoload
scripts/
  game_manager.gd              Autoload: carries the spawn point across scenes
  player.gd                    CharacterBody2D, WASD/arrows, placeholder sprite
  portal.gd                    Area2D doorway: target scene + spawn position
  world.gd                     Shared town/field logic: apply a portal spawn
scenes/
  player/player.tscn           Player + camera + collision
  world/town.tscn              Town: 3 houses, trees, rock, north portal
  world/field.tscn             Field: trees, rocks, south portal back to town
  monsters/ npcs/ items/ ui/   Empty for now (Phase 2+)
data/                          Empty for now (MonsterData/ItemData in Phase 2+)
```

## How travel works

1. `portal.gd` detects the player entering its area.
2. It calls `GameManager.travel_to(scene_path, spawn_position)`.
3. Godot switches scenes. The new world's `world.gd` reads
   `GameManager.spawn_position` in `_ready()` and moves its Player there,
   then clears the flag. Starting a scene directly from the editor still
   uses that scene's default Player position.

## Placeholder art, on purpose

Everything visual in Phase 1 is coloured boxes: the player sprite is
generated in `player.gd` at runtime, and houses/trees/rocks/portals are
`ColorRect` boxes with matching collision shapes. Replace a box with a
real sprite later without changing the collision or movement code.

## Known Phase 1 simplifications

- No TileMap yet: collision is `StaticBody2D` rectangles, which is
  easier to edit by hand and runs on any Godot 4.x. A TileMap can replace
  the ground/obstacles later without changing the player or portal code.
- Movement reads keys directly instead of an Input Map, so the project
  needs no extra setup. Move these to named actions later if you prefer.
- Godot is not installed in this chat's environment, so this scaffold
  has been checked for file structure and scene/script references, but
  not run inside the Godot editor. If Godot reports an error on import,
  paste the exact error and it can be fixed from there.

## Next: Phase 2 (combat)

Add `scenes/monsters/`, a monster scene with idle/chase/attack states,
click-to-target + basic attack on the player, damage numbers, HP bars,
death, drops, and respawn timers — reusing this player, world, and
portal code unchanged.
