# The Last Guest

A co-op haunted-hotel horror game for Roblox. Up to 4+ friends vote on a difficulty, get dropped in a dark hotel corridor, find brass keys hidden in rooms, unlock the exit and escape a ghost that hunts them. Every escape drops collectible **relics** that you can show off and (soon) trade.

This folder holds the scripts. **The scripts build the lobby, the hotel, the ghost and all the UI themselves**, so you only create 6 scripts in Roblox Studio and paste code into them.

---

## Part 1: Set up Roblox Studio (about 10 minutes)

1. Go to <https://create.roblox.com> and sign in. Click **Download Studio** and install it.
2. Open Studio, click **New**, and choose the **Baseplate** template.
3. Turn on the two panels you'll use all the time: open the **View** tab and click **Explorer** and **Properties** (also **Output**, which shows errors).

## Part 2 (easiest): import the scripts, no copy-paste

Copying 8 scripts by hand is easy to get wrong (a script with the wrong code in it gives confusing errors). Use the import files instead. They put every script in the right place, with the right name and type.

1. **Start clean.** In Studio's Explorer, delete every old game script: `GameConfig`, `GhostModel` (in `ReplicatedStorage`), `GameManager`, `Ghost`, `HotelBuilder`, `PlayerData` (in `ServerScriptService`), and `HUD`, `Cutscene` (in `StarterPlayer > StarterPlayerScripts`). Click one, hold **Ctrl** and click the rest, then press **Delete**. Leave the other things in Explorer alone.
2. **Download the three files** in the `studio-import` folder on GitHub (open each one and click the **download** arrow at the top right of the file). Save them somewhere you can find, like your Desktop.
3. **Import each one into its own place.** Right-click the place in Explorer, choose **Insert from File...**, and pick the file:

| Right-click this in Explorer | Insert this file |
|---|---|
| `ReplicatedStorage` | `1-ReplicatedStorage.rbxmx` |
| `ServerScriptService` | `2-ServerScriptService.rbxmx` |
| `StarterPlayer` > `StarterPlayerScripts` | `3-StarterPlayerScripts.rbxmx` |

4. Check Explorer now shows exactly this, and nothing twice:
```
ReplicatedStorage:        GameConfig, GhostModel
ServerScriptService:      GameManager, Ghost, HotelBuilder, PlayerData
StarterPlayerScripts:     HUD, Cutscene
```
5. Press **Play**.

When I update the game I will also update these files, so you only repeat steps 1 to 3.

If you prefer to copy and paste by hand, use Part 2 below instead.

## Part 2 (by hand): create the scripts

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

**Added later (so there are now 8 scripts):**

| # | Create this... | Inside... | Name it exactly | Paste the code from |
|---|---|---|---|---|
| 7 | **ModuleScript** | `ReplicatedStorage` | `GhostModel` | `src/ReplicatedStorage/GhostModel.luau` |
| 8 | **LocalScript** | `StarterPlayer` > `StarterPlayerScripts` | `Cutscene` | `src/StarterPlayer/StarterPlayerScripts/Cutscene.client.luau` |

> Tip: the scripts must be the *right type* (ModuleScript vs Script vs LocalScript). If you pick the wrong one the game won't start.

## Part 3: Play-test it

1. Click the **Home** tab, then the green **Play** button (or press **F5**). Studio starts a game with you in it.
2. You spawn in a lobby (floating high above the hotel). Walk onto one of the three coloured **difficulty pads** to vote.
3. After the countdown you're dropped into the hotel. Press **F** for the flashlight.
4. Walk into rooms and find the **old brass keys** lying on tables and beds (hold **E** to pick up). Once you have them all the exit door at the end of the corridor opens (green light). Run through it to escape.
5. The ghost wakes after ~12 seconds. It wanders slowly, then chases if it sees or hears you. Break line of sight and get away to lose it.
5b. **Hide:** every room has a **cupboard** on the back wall. Walk up and hold **E** to climb in. The doors close, you can peek out through the slit, and the ghost can't see or hear you. Hold **E** again to get out.
   - If the ghost **sees you climb in** (it was chasing you right then), it will come and open that cupboard. Break line of sight *first*, then hide.
   - If you hide well, it can still wander past and **check** cupboards. It's a gamble, and it's riskier on harder difficulties (`HideCheckChance` in `GameConfig`).
   - Only one person fits in each cupboard.
5c. **Battery:** your flashlight drains while it's on (watch the bar above the Flashlight button). Hunt for **batteries** on tables and beds (hold **E**); each restores half a battery. At 20% the beam flickers, at 0 it dies. Turning it off saves power, and the ghost can only see you from about 60% as far away when you're in the dark, but you won't see it coming either.
6. Press **R** to see your relic collection.
7. **Win a round** (anyone escapes, on any difficulty) and a short cutscene plays. If you escaped, it plays straight away and says YOU ESCAPED. If you were caught but a teammate made it out, it plays when the night ends and says YOUR TEAM ESCAPED. It shows: you drive off in a fast car, and through the rear window the ghost waves goodbye from its window. Then **YOU ESCAPED** appears.

Stop the test with the red **Stop** button.

To test with friends in Studio: **Test** tab > set **Players: 2+** > **Start**.

## Part 4: Publish and turn on saving

Relics are saved between visits, but only in a published game.

1. **File > Publish to Roblox**. Give it a name and create it.
2. **Home > Game Settings > Security** > turn on **Enable Studio Access to API Services**. Save.
3. Still in **Game Settings > Players**, set **Max players** to what you like (4-8 suits this hotel).
4. Before launch, open `GameConfig` and change `Config.MinPlayers = 1` to `2` (or more) so nights only start with a group.
5. **Game Settings > Maturity** (content questionnaire): answer honestly. Horror with scares will get a higher rating, which is fine for a 13+ audience.

## Part 5: Add the scary music

The game plays three tracks (all created for this project, in the `audio/` folder next to this README):

| File | When it plays |
|---|---|
| `audio/lobby_theme.mp3` | A broken, slightly out-of-tune music box in the lobby and between nights |
| `audio/night_ambience.mp3` | Dissonant drones, scrapes and distant knocks while you're in the hotel |
| `audio/chase_layer.mp3` | A pounding pulse that fades in as the ghost hunts you or gets close |

Roblox can only play audio that is **uploaded to Roblox**, so you have to do this once:

1. Download the three `.mp3` files from GitHub (open each file and click **Download raw file**).
2. In Studio: **View > Asset Manager**, right-click **Audio**, choose **Import** (or **Bulk Import**) and pick the three files. Roblox checks them for a minute or two.
3. When they appear, right-click each one and choose **Copy ID to Clipboard**.
4. Open `GameConfig` and paste each ID into `Config.Music`, with `rbxassetid://` in front:

```lua
Config.Music = {
	Volume = 0.5,
	Lobby = "rbxassetid://1234567890",
	Night = "rbxassetid://2345678901",
	Chase = "rbxassetid://3456789012",
}
```

5. Press **Play**. Leave a track as `""` to turn it off.

**If the upload is blocked:** Roblox may ask you to verify your age/ID before you can upload audio. You can use free music instead: **View > Toolbox > Audio** (set the filter to free / Roblox-made) and search for "horror ambience", "music box" or "chase". Copy the ID of anything you like and paste it into `Config.Music`. Never use music you don't have the rights to.

## Tuning cheat sheet (all in `GameConfig`)

| I want to... | Change |
|---|---|
| Make the ghost scarier or easier | `GhostSpeed`, `GhostSight`, `GhostHear` in each difficulty (players walk at 16) |
| Give players more or less time | `TimeLimit` (seconds) per difficulty |
| More or fewer keys | `Keys` per difficulty (max is 8, one per room) |
| Bigger hotel | `RoomsPerSide` (more rooms) |
| Rarer or more generous relics | `RarityWeights` and `RelicRolls` per difficulty |
| Give players a longer or shorter head start when the ghost spots them | `GhostNoticeTime` (seconds it freezes and reaches out first) |
| Make long chases more frantic | `GhostFrenzyRate` and `GhostFrenzyMax` (how much faster it gets the longer it hunts you) |
| Change how quickly it speeds up and stops | `GhostAcceleration` |
| Change how far its "presence" is felt (lights flickering) | `GhostPresenceRadius` |
| Make the torch last longer or shorter | `BatterySeconds` per difficulty (seconds a full battery lasts) |
| More or fewer batteries in the hotel | `Batteries` per difficulty (keys + batteries must be 16 or fewer) |
| Make each battery worth more | `BatteryPickup` (percent restored) |
| How much darkness hides you from the ghost | `DarkSightScale` (0.6 = it sees you from 60% as far) |
| Make the escape cutscene longer | `CutsceneTime` (seconds, at least 11) |
| Make cupboards safer or deadlier | `HideCheckChance` per difficulty (0 = never checked, 1 = always), `HideCheckRadius` |
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
- Music is included (Part 5) but sound *effects* (footsteps, door creaks, a jump-scare sting) are not in yet. Also not in: **trading**, game passes/cosmetics, a proper thumbnail. See the roadmap.

## Roadmap (what makes it thrive without pay-to-win)

1. **Sound effects**: footsteps, a heartbeat when the ghost is near, door creaks, a stinger on the jump scare. Free assets are in the Studio Toolbox (Audio tab).
2. **More hiding**: under beds, behind curtains; a breath-holding meter while hidden.
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
