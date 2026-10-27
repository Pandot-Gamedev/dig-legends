# Dig Legends

A relaxed Roblox treasure-digging collection game: dig up fossils, gems and relics, sell them,
buy better shovels, unlock new zones and fill your Collection. Built on the Reel Legends code base.

The ready-to-open game file is [build/DigLegends.rbxlx](build/DigLegends.rbxlx).

## Status

Step 2 of 6: digging works in the **Backyard** zone and the starter patch in Dig Town.
Play-tested in Roblox Studio on 2026-10-27: the guide, digging, finds, selling, shovels, charms,
bounties and the bridge to the Backyard all work with no script errors.
Still to come: the other four zones (step 3), Treasure Rush and dig buddies (step 4),
and the shop setup (step 5). All shop ids are 0, so passes and cosmetics show "Coming soon".

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

## What's in the game so far

- **12 Backyard finds + 2 weekly legendary finds**, 5 rarities, random weights, rare **Shiny** finds worth 3x.
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
  Shovels.luau, Charms.luau, Zones.luau
  Dig.luau               the dig minigame rules, shared by server and player
  Shop.luau              game pass and product ids (fill these in)
src/server/              ServerScriptService.Server
  DigService.luau        dig spots, digging down, rolling finds, checking results
  MapBuilder.luau        builds Dig Town and one island per zone if there is no Map folder
src/client/              StarterPlayerScripts.Client
  Digging.luau           digging controls and the minigame on screen
tools/build_place.py     rebuilds build/DigLegends.rbxlx from src/
```
