# Ragnarok-like Game — Phase 1 + Phase 2

A playable Godot 4 starting point: walk around, collide with the world,
travel between town and field, and fight monsters in the field.
No XP/levels, skills, inventory, shops, quests, or dungeon yet —
those are later phases.

## How to run it (Windows)

1. Install Godot 4 (any 4.x version; this was written for the 4.x scene format).
2. Open Godot, choose **Import**, and pick this folder's `project.godot`
   (or **Project > Open** if it is already in your project list).
3. Press **F5** (or the Play button, top right).

You should spawn in town as a blue box character.

## Controls

- **WASD** or **arrow keys** — move
- **Left-click a monster** — target it (yellow marker, target HP bar in HUD)
- **Left-click empty ground** — clear the target
- Walk close to a targeted monster and you attack automatically
  (10 damage, every 0.8 seconds, range 80). There is no click-to-move yet.
- Walk into the glowing blue portal at the top of town to go to the field
- Walk into the glowing portal at the bottom of the field to return to town

Collision is real: houses, trees, rocks, and the map edges block you.
The camera follows the player. If a monster kills you, you respawn in
town at full HP (gold kept for now).

## Phase 2: combat

- Monsters are data, not code: `data/slime.tres`, `data/mushroom.tres`,
  and `data/wolf.tres` hold HP, damage, speed, aggro/attack range,
  colour, gold drop, and respawn time. Edit those files to rebalance.
- Monster AI has three states only: idle, chase, attack. A monster
  notices you inside its aggro range, attacks inside its attack range,
  and walks back to its spawn (recovering full HP) if pulled more than
  400 pixels away.
- Damage numbers float up from the target, monsters flash red on hit,
  and each monster has an HP bar above it.
- On death a monster drops a gold pickup (walk over it to collect it)
  and respawns in place after its respawn time: Slime 5s, Mushroom 5s,
  Wolf 8s.
- Field monsters: 2 Slimes (30 HP, 5 damage, slow), 2 Mushrooms
  (20 HP, 4 damage, fast), 1 Wolf (60 HP, 12 damage, aggressive).
  XP is in the data files but not used yet — levels come in Phase 3.

## What is in here

```
project.godot                  Main scene = town, GameManager autoload
scripts/
  game_manager.gd              Autoload: carries the spawn point across scenes
  player.gd                    CharacterBody2D, WASD/arrows, placeholder sprite
  portal.gd                    Area2D doorway: target scene + spawn position
  world.gd                     Shared town/field logic: apply a portal spawn
scripts/
  monster.gd                   Monster AI, damage, death, respawn
  monster_data.gd              MonsterData resource class
  gold_pickup.gd               Gold drop pickup
  damage_number.gd             Floating damage numbers
  hud.gd                       Player HP, gold, target HP
scenes/
  player/player.tscn           Player + camera + collision
  world/town.tscn              Town: 3 houses, trees, rock, north portal
  world/field.tscn             Field: trees, rocks, south portal, 5 monsters
  monsters/monster.tscn        Generic monster (data set per instance)
  items/gold_pickup.tscn       Gold pickup
  ui/hud.tscn                  HUD, ui/damage_number.tscn is the damage label
  npcs/                        Empty for now (Phase 4+)
data/
  slime.tres, mushroom.tres, wolf.tres   Monster stats
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

## Next: Phase 3 (progression)

XP from kills, level-ups, stat points (STR/AGI/VIT/INT/DEX/LUK),
HP/SP regen, potions, and the four skills: Basic Attack, Power Strike,
Heal, and Fire Bolt.
