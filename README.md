# Ragnarok-like Game — Phase 1 + Phase 2 + Phase 3 + Phase 4

A playable Godot 4 starting point: walk around, collide with the world,
travel between town and field, fight monsters, gain XP and levels,
spend stat points, cast skills, collect loot, equip gear, and spend
gold at the shop. No quests or dungeon yet — those are later phases.

## How to run it (Windows)

1. Install Godot 4 (any 4.x version; this was written for the 4.x scene format).
2. Open Godot, choose **Import**, and pick this folder's `project.godot`
   (or **Project > Open** if it is already in your project list).
3. Press **F5** (or the Play button, top right).

You should spawn in town as a blue box character.

## Controls

- **WASD** or **arrow keys** — move (WASD cancels click movement)
- **Left-click a monster** — target it (yellow marker, target HP bar
  in HUD), walk to it, and attack automatically once in range
- **Left-click ground** — walk to that point (and drop any monster target)
- If a clicked path is blocked by a wall, tree, or house for 0.5s,
  click movement stops instead of pushing against it forever.
- **1 Power Strike** (5 SP, 3s cooldown, x1.8 damage, needs a target in range)
- **2 Heal** (10 SP, 5s cooldown, restores HP)
- **3 Fire Bolt** (8 SP, 4s cooldown, 300 range, tracking projectile)
- **4 HP Potion** — uses the best HP potion in your inventory
  (you start with 3 HP Potions; buy more at the shop)
- **C** — character panel: spend stat points with the + buttons
- **I** — inventory: equip gear with Equip, use potions with Use,
  unequip from the Equipped list
- **Esc** — closes only the frontmost open panel, one per press
  (front to back: storage, shop, inventory, character, matching the
  order the panels are drawn in). Every panel also has a Close button
  at its top right, which closes that panel directly.
- **E near the purple Shopkeeper in town** — shop: buy stock (click Buy
  twice to confirm), sell your items for half price, or Esc/Close to leave
- **E near the cyan Storage Keeper in town** — storage: Deposit items
  from your inventory, Withdraw them back, or Esc/Close to leave
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
  XP is now used: killing a monster awards its XP (see Phase 3).

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

## Phase 3: progression

- XP from kills. XP to next level = 25 x level (25 to reach level 2).
  On level-up you get 5 stat points and a "Level Up!" message.
- Base stats all start at 5. Press C and use the + buttons to spend points.
- Formulas (all in `player.gd`, in `recalculate_derived()`):
  - max HP = 100 + VIT x 10 + (level-1) x 10
  - max SP = 50 + INT x 8 + (level-1) x 5
  - attack damage = 10 + STR x 2, attack range = 80 + DEX x 2
  - auto-attack cooldown = max(0.4, 0.8 - AGI x 0.02) seconds
  - crit chance = 5% + LUK x 1% (basic attacks only, damage x2)
  - HP regen = 2 + VIT x 0.5 per second, SP regen = 1.5 + INT x 0.4
  - Heal = 20 + INT x 3, Fire Bolt = 15 + INT x 3
- Regen is x3 in town, so standing in town is the safe way to recover.
  If a monster kills you, you respawn in town at full HP/SP.
- HUD now shows HP, SP, and XP bars, level (with unspent points),
  gold, skill cooldowns, and potion count.
- Potions are not restocked yet — shops and inventory come in Phase 4.

## Phase 4: items and economy

- Inventory lives in `GameManager` (autoload, so it survives scene
  changes), with stackable consumables. Press I to open it.
- Equipment slots: weapon, armor, headgear, accessory. Equipping applies
  its bonuses immediately (attack, defence, max HP/SP) and shows in the
  character panel. You start with a Wooden Sword and Leather Armor equipped.
- Defence reduces monster damage, minimum 1 per hit, and the damage
  number shown is the damage after defence.
- Shop and storage NPCs stand in town (purple Shopkeeper, cyan Storage
  Keeper). Walk up and press E; a "Press E" hint appears when in range.
  Shop stock: 2 swords, 2 armors, 2 headgears, 2 rings, 3 potions.
  Selling pays half the item's price. Storage is a separate stash,
  one item per Deposit/Withdraw click.
- Loot tables: monsters can drop an item on death, in addition to gold.
  Slime drops a Small HP Potion (25%), Mushroom an SP Potion (20%),
  Wolf a Wooden Ring (15%). Walk over a coloured pickup to collect it.
  Item data lives in `data/items/*.tres`, edited the same way as monsters.
- Key 4 now uses potions from your inventory instead of a separate count,
  and the HUD potion count is the HP potions you actually carry.

## Next: Phase 5 (quests and dungeon)

Quests and dialogue, the dungeon with a boss, and quest rewards — reusing
the inventory, shop, and combat systems already in the game.
