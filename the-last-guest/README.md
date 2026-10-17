# The Last Guest

A co-op haunted-hotel horror game for Roblox. Up to 4+ friends vote on a difficulty, get dropped in a dark hotel corridor, find brass keys hidden in rooms, unlock the exit and escape a ghost that hunts them. Every escape drops collectible **relics** that you can show off and (soon) trade.

This folder holds the scripts. **The scripts build the lobby, the hotel, the ghost and all the UI themselves**, so you only create 6 scripts in Roblox Studio and paste code into them.

---

## Part 1: Set up Roblox Studio (about 10 minutes)

1. Go to <https://create.roblox.com> and sign in. Click **Download Studio** and install it.
2. Open Studio, click **New**, and choose the **Baseplate** template.
3. Turn on the two panels you'll use all the time: open the **View** tab and click **Explorer** and **Properties** (also **Output**, which shows errors).

## Part 2: Create the 6 scripts

In the **Explorer** panel, hover over a folder-like item (for example `ServerScriptService`) and click the small **+** that appears. Pick the script type. Then rename it: click it, press **F2**, type the name, press Enter. **Names are case-sensitive and must match exactly.**

New scripts come with a line like `print("Hello world!")`. **Delete everything in the script first**, then paste the code.

| # | Create this... | Inside... | Name it exactly | Paste the code from |
|---|---|---|---|---|
| 1 | **ModuleScript** | `ReplicatedStorage` | `GameConfig` | `src/ReplicatedStorage/GameConfig.luau` |
| 2 | **ModuleScript** | `ServerScriptService` | `HotelBuilder` | `src/ServerScriptService/HotelBuilder.luau` |
| 3 | **ModuleScript** | `ServerScriptService` | `Ghost` | `src/ServerScriptService/Ghost.luau` |
| 4 | **ModuleScript** | `ServerScriptService` | `PlayerData` | `src/ServerScriptService/PlayerData.luau` |
| 5 | **Script** | `ServerScriptService` | `GameManager` | `src/ServerScriptService/GameManager.server.luau` |
| 6 | **LocalScript** | `StarterPlayer` > `StarterPlayerScripts` | `HUD` | `src/StarterPlayer/StarterPlayerScripts/HUD.client.luau` |

> Tip: the 6 scripts must be the *right type* (ModuleScript vs Script vs LocalScript). If you pick the wrong one the game won't start.

## Part 3: Play-test it

1. Click the **Home** tab, then the green **Play** button (or press **F5**). Studio starts a game with you in it.
2. You spawn in a lobby (floating high above the hotel). Walk onto one of the three coloured **difficulty pads** to vote.
3. After the countdown you're dropped into the hotel. Press **F** for the flashlight.
4. Walk into rooms and find the **brass keys** (they sit on tables, hold **E** to pick up). Once you have them all the exit door at the end of the corridor opens (green light). Run through it to escape.
5. The ghost wakes after ~12 seconds. It wanders slowly, then chases if it sees or hears you. Break line of sight and get away to lose it.
6. Press **R** to see your relic collection.

Stop the test with the red **Stop** button.

To test with friends in Studio: **Test** tab > set **Players: 2+** > **Start**.

## Part 4: Publish and turn on saving

Relics are saved between visits, but only in a published game.

1. **File > Publish to Roblox**. Give it a name and create it.
2. **Home > Game Settings > Security** > turn on **Enable Studio Access to API Services**. Save.
3. Still in **Game Settings > Players**, set **Max players** to what you like (4-8 suits this hotel).
4. Before launch, open `GameConfig` and change `Config.MinPlayers = 1` to `2` (or more) so nights only start with a group.
5. **Game Settings > Maturity** (content questionnaire): answer honestly. Horror with scares will get a higher rating, which is fine for a 13+ audience.

## Tuning cheat sheet (all in `GameConfig`)

| I want to... | Change |
|---|---|
| Make the ghost scarier or easier | `GhostSpeed`, `GhostSight`, `GhostHear` in each difficulty (players walk at 16) |
| Give players more or less time | `TimeLimit` (seconds) per difficulty |
| More or fewer keys | `Keys` per difficulty (max is 8, one per room) |
| Bigger hotel | `RoomsPerSide` (more rooms) |
| Rarer or more generous relics | `RarityWeights` and `RelicRolls` per difficulty |
| Add a relic | Copy a line in `Config.Relics` and give it a unique `Id` (letters/numbers only) |
| Shorter lobby wait | `IntermissionTime` |
| Brighter or darker hotel | `Brightness` of lamps in `HotelBuilder`, `Lighting.Ambient` in `GameManager` |

## If something goes wrong

Open **View > Output**. Red text tells you which script and line has the problem.

| You see | Likely cause |
|---|---|
| `Infinite yield possible on 'ReplicatedStorage:WaitForChild("GameConfig")'` | A script is named wrong or in the wrong place (names are case-sensitive) |
| `attempt to index nil` / `... is not a valid member` | Pasted into the wrong script type, or the paste was cut off. Re-paste the whole file |
| Black screen in the lobby | Normal at night! Lobby lamps should light the pads. Check `GameManager` pasted fully |
| `Could not load data ... 403 / API access` | Turn on **Enable Studio Access to API Services** (Part 4). The game still works without it |
| Nothing happens after voting | `Config.MinPlayers` is higher than the number of players |
| Anything else | Copy the red error text and send it to me |

---

## Honest status

- Written and syntax-checked with the Luau compiler/analyzer, and the relic drop rates were tested. **It has not yet been run inside Roblox Studio**, so expect a few small bugs on first play. Send me the Output errors and what you saw, and I'll fix them.
- Not in yet: sound effects (the biggest scare multiplier), hiding spots, **trading**, game passes/cosmetics, a proper thumbnail. See the roadmap.

## Roadmap (what makes it thrive without pay-to-win)

1. **Sound**: footsteps, a heartbeat when the ghost is near, door creaks, a stinger on the jump scare. Free assets are in the Studio Toolbox (Audio tab).
2. **Hiding spots**: wardrobes you can hide in (ghost checks them occasionally).
3. **Trading** relics between friends (secure two-sided confirm). This is the main "come back" loop.
4. **Daily/weekly challenges** and a limited-time seasonal relic set (Halloween, winter).
5. **Lobby relic shelf** so players can display their rarest finds.
6. **Monetization that never changes who wins**:
   - Private servers (built into Roblox)
   - Extra relic storage / extra loadout display slots
   - VIP lobby lounge
   - Cosmetics only: flashlight skins, beam colours, outfits, lobby decorations
   - **Never** sell: faster running, a slower ghost, more time, revives, or paid random relic boxes (paid loot boxes need odds disclosure on Roblox and feel pay-to-win in a trading game).
7. **Polish for launch**: thumbnail and 3 screenshots, an icon, a short trailer, and a description that says "co-op horror". Run a small playtest with 5-10 friends before publishing widely.
