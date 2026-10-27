# Dig Legends

A relaxed Roblox treasure-digging collection game: dig up fossils, gems and relics, sell them,
buy better shovels, unlock new zones and fill your Collection. Built on the Reel Legends code base.

The ready-to-open game file is [build/DigLegends.rbxlx](build/DigLegends.rbxlx).

## Status

Step 3 of 6: all five zones are in. Step 2 (digging in the **Backyard** and the starter patch) was
play-tested in Roblox Studio on 2026-10-27 with no script errors. **Step 3 is not play-tested in
Studio yet**: the walk through Desert Dig, Crystal Caves, Sunken Ruins and Volcano Core is next.
Still to come: Treasure Rush and dig buddies (step 4) and the shop setup (step 5).
All shop ids are 0, so passes and cosmetics show "Coming soon".

## How to test in Roblox Studio

1. Open `build/DigLegends.rbxlx` in Roblox Studio and press **Play**.
2. Follow Grandpa Gus's guide at the top of the screen: take out the shovel (press 1), walk into
   the fenced Starter Patch and click next to a sparkling dirt spot.
3. When the dig bar appears, click (or tap, or press Space) while the white marker is in the
   green. The gold middle is a perfect hit and makes the find worth more. Three misses break it.
4. Sell at Ruby's Trading Post, buy a shovel from Digby, try a charm from Clover's Charm Cart,
   then walk over the bridge to the Backyard island.
5. Saving only works after the place is published with "Enable Studio Access to API Services" on.

If the shovel is held at a strange angle, change `SHOVEL_TILT` in `src/server/DigService.luau`.

Test helper (Studio only, never in the live game): to get coins for testing the shops, pick the
**Server** view while playing and run this in the command bar:
`game.ServerStorage.DigLegendsTest:Invoke("coins", 5000)`
To reach a zone's level, add digger XP the same way: `game.ServerStorage.DigLegendsTest:Invoke("xp", 10000)`

## What's in the game so far

- **5 zones**, each opened with a digger level and coins: Backyard, Desert Dig (Lv 5), Crystal Caves (Lv 12),
  Sunken Ruins (Lv 20) and Volcano Core (Lv 30). Each island has its own look: pyramid and cacti,
  glowing crystals, marble columns, lava pools and a smoking volcano.
- **60 finds (12 per zone) + 5 weekly legendary finds**, 5 rarities, random weights, rare **Shiny** finds worth 3x.
- **Collection pages:** finishing a zone's page gives a "Master" title and +5% coins on every sale, forever.
- **Dig minigame:** tap in the green to dig deeper, perfect hits add up to +30% value, misses crack the find.
- **Dig spots** sparkle; after you dig one it refills for you in 20 seconds. Other players see your
  shovel move and the dirt fly.
- **6 shovels** bought with coins (luck, digging speed, wider sweet spot). Never sold for Robux.
- **Charms** (bought with coins or made from finds): faster digging, more luck, more shinies or legendaries.
- **Collection** book, **Trading Post** with rotating in-demand finds, **Grandpa Gus's bounties**,
  digger levels, daily login reward, rebirths, weather and a weekly legend, global leaderboard.
- **Dig Town hub** with shopkeepers, a starter patch, a VIP lounge, and bridges to each zone island.

## Monetization (never pay-to-win)

| Item | Type | Effect |
|---|---|---|
| VIP | Game pass | Golden name tag, crown, VIP lounge |
| Auto Sell | Game pass | Backpack sells itself when full |
| Big Backpack | Game pass | 60 finds instead of 20 |
| Zone Teleporter | Game pass | Teleport to unlocked zones |
| Shovel skins, trails, titles | Developer products | Looks only |
| Private servers | Monthly | Play with friends only |

Nothing sold for Robux affects what you dig up, your luck, or your coins per find.

## Project layout (Rojo)

```
default.project.json     Rojo project: maps src/ into the game
src/shared/              ReplicatedStorage.Shared (used by server and players)
  Config.luau            backpack size, dig timings, rebirth cost, daily reward
  Finds.luau             every find and rarity (strikes, sweet spot size, marker speed)
  Zones.luau             the five zones with their level and coin price
  Shovels.luau, Charms.luau
  Dig.luau               the dig minigame rules, shared by server and player
  Shop.luau              game pass and product ids (fill these in)
src/server/              ServerScriptService.Server
  DigService.luau        dig spots, digging down, rolling finds, checking results
  MapBuilder.luau        builds Dig Town and one island per zone if there is no Map folder
src/client/              StarterPlayerScripts.Client
  Digging.luau           digging controls and the minigame on screen
tools/build_place.py     rebuilds build/DigLegends.rbxlx from src/
```
