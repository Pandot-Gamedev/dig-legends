# Dig Up a Legendary!

Called Dig Legends until 2026-10-30, when it was renamed to stand out in Roblox search (no other game uses the new name). The repo, file and code names keep the old name.

A relaxed Roblox treasure-digging collection game: dig up fossils, gems and relics, sell them,
buy better shovels, unlock new zones and fill your Collection. Built on the Reel Legends code base.

The ready-to-open game file is [build/DigLegends.rbxlx](build/DigLegends.rbxlx).

## Status

Public on Roblox since 2026-10-28 (shown as Ages 16+ until ID verification works):
[Dig Legends](https://www.roblox.com/games/83829887315860/Dig-Legends) (experience 10773541582).
Steps 1 to 4 are done and play-tested in Roblox Studio with no script errors, including Treasure
Rush and dig buddies with 2 test players. The store art for step 5 is in `store/`.
The 4 game passes and 10 cosmetic products were made on 2026-10-28 with
`tools/create_shop_items.luau`; their ids are in `src/shared/Shop.luau` and the shop is live.
Icon, thumbnails and the content questionnaire are done (step 6).

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
To fill a zone's Collection page: `game.ServerStorage.DigLegendsTest:Invoke("book", "desert")`
To start a Treasure Rush right away: `game.ServerStorage.DigLegendsTest:Invoke("rush")`

To try multiplayer, use Studio's **Test > Clients and Servers** with 2 players. In Studio every
player counts as a friend, so the dig buddy bonus shows up there too.

## What's in the game so far

- **5 zones**, opened in order with a digger level and coins: Backyard, Desert Dig (Lv 5), Crystal Caves (Lv 12),
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
- **Treasure Rush:** every 15 minutes a glowing dig site pops up in Dig Town for 4 minutes. Good
  digs there fill it up (more players in the server means more digs needed). When it is dug out,
  every helper gets a guaranteed Rare or better find from their best zone, or Epic or better when
  3 or more players helped. A button at the top of the screen takes you there.
- **Dig buddies:** digging within 20 studs of a Roblox friend gives you both +10% coins per find.
- **Announcements:** Legendary and Shiny finds (with a pillar of light) and completed Collection
  pages are announced to the whole server.

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
  Shop.luau              game pass and product ids
src/server/              ServerScriptService.Server
  DigService.luau        dig spots, digging down, rolling finds, checking results
  MapBuilder.luau        builds Dig Town and one island per zone if there is no Map folder
  RushService.luau       the Treasure Rush dig site and its loot
  BuddyService.luau      dig buddies (friends digging close together)
src/client/              StarterPlayerScripts.Client
  Digging.luau           digging controls and the minigame on screen
tools/build_place.py     rebuilds build/DigLegends.rbxlx from src/
tools/make_store_art.py  draws the icon, thumbnails and pass/product icons into store/
```
