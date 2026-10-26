# Ragnarok-like Game — Phase 1 + Phase 2 + Phase 3 + Phase 4 + Phase 5

A playable Godot 4 starting point: walk around, collide with the world,
travel between town and field, fight monsters, gain XP and levels,
spend stat points, cast skills, collect loot, equip gear, spend
gold at the shop, take quests from the Elder, and clear the dungeon
boss. Save/load, title screen, and pause menu are Phase 6.

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
- **E near the gold Elder in town** — dialogue: accept the next quest
  in the chain, or read your progress on the current one
- **Q** — quest log: every quest in the chain, with its state and
  progress (for example, "Slimes: 3/5")
- Walk into the purple portal on the right side of the field to enter
  the dungeon; walk into the purple portal at the bottom of the dungeon
  to return to the field
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

## Pixel-art sprites

Placeholder boxes are gone for characters and world objects. Sprites
are generated at runtime from pixel grids in `scripts/sprite_data.gd`
— deliberately no image files, so the whole project stays plain text
and pushable (the GitHub snapshot tool rejects binary PNGs). Grids
are upscaled with nearest-neighbour so pixels stay crisp, and `.`
in a grid is transparent:
- Player (32x48), shopkeeper, storage keeper, and Elder (32x48)
- Monsters (32x32): slime, mushroom, wolf, skeleton, bat, goblin,
  Dungeon Guardian — wired through `MonsterData.sprite_name`, with
  the old coloured-box fallback if a sprite name is missing
- Houses (220x160), trees (64x64), rocks (48x48) in town and field,
  via `scripts/sprite_node.gd` (a Sprite2D that draws by name)
- Still flat colour by design: ground, walls, dungeon pillars, and
  the glowing portals (a portal is a glow, not an object)

To change a sprite, edit its grid in `scripts/sprite_data.gd` —
nothing else needs to change. Collision shapes are unchanged, so
movement, targeting, and combat work exactly as before.

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
- Progression lives in `GameManager`, not on the Player node: the
  Player is recreated in every map, so storing level/XP/stats only
  on it reset them on every map change. `GameManager` captures them
  before every portal travel and the new Player loads them on spawn.
  HP/SP carry over too, except on death, where the town respawn is
  at full HP/SP with level/XP/stats kept.
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

## Phase 5: quests and dungeon

- Quests are a chain, given by the Elder in town, one at a time:
  1. Meet the Elder (talk) — 20 XP, 20 gold
  2. Slime Hunt (kill 5 slimes) — 50 XP, 30 gold
  3. Herb Gathering (collect 3 herbs; mushrooms drop herbs 50% of
     the time, on top of their potion drop) — 60 XP, 40 gold
  4. Wolf Hunt (kill 5 wolves) — 100 XP, 60 gold
  5. Clear the Dungeon (defeat the Dungeon Guardian) — 200 XP,
     150 gold, and an Iron Sword
- Quest progress is tracked as it happens (kills on monster death,
  pickups on item collection, not inventory totals), and completing a
  quest shows a "Quest complete" message, grants its rewards at once,
  and unlocks the next quest. Quest data lives in `data/quests/*.tres`.
- The deliver example from the plan is not a separate quest: herb
  gathering already ends with returning to the Elder for the next quest.
- Dungeon (dark room, 1200x700, pillars, exit portal at the bottom):
  2 Skeletons (80 HP, 15 damage), 2 Bats (35 HP, fast), 1 Goblin
  (120 HP, 20 damage), and the Dungeon Guardian boss at the far end
  (300 HP, 25 damage, 200 XP, 100 gold, 50% Silver Ring drop).
  Boss special: every 5 seconds, a "Roar!" hits the player for 15
  damage (before defence) if they are within 150 pixels — step back
  to avoid it. The boss respawns after 30 seconds, like other monsters.

## Next: Phase 6 (polish and save)

Title screen, pause menu, save/load, sound placeholders, and a
balance pass — reusing everything built so far.
