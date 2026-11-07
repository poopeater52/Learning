# Task for Claude Cowork: install "The Last Guest" into Roblox Studio (Windows)

You are helping a user set up a Roblox horror game on their Windows PC. The game's scripts are already
written. Your job is to put them into Roblox Studio, press Play to test, and report what happens.
Do not write or change any game code yourself. Only move the provided files into place.

## Rules (please follow these)

- Work only in **Roblox Studio** and in the **folder the user gave you access to**. Do not open other apps or websites.
- **Do not publish** the place, change Game Settings, sign in or out, buy anything, or upload anything. If Studio asks you to sign in or shows a popup you did not expect, stop and ask the user.
- The only things you may delete in Studio are the 9 old game scripts named in Step 3.
- If something is not as described below, **stop and tell the user what you see** (and attach a screenshot) instead of guessing.
- Do not copy and paste code by hand. Use the **Insert from File** import described below.

## What you need first

The user must have already:
1. Installed **Roblox Studio** (from create.roblox.com) and signed in.
2. Downloaded this project as a ZIP and extracted it. In GitHub that is **Code > Download ZIP** on the branch `claude/scratch-game-dev-5az2zz` of `poopeater52/Learning`, then right-click the ZIP and choose **Extract All**.
3. Given you access to the extracted folder.

Inside the extracted folder you will find `the-last-guest\studio-import\` containing exactly these three files:

| File | Goes into |
|---|---|
| `1-ReplicatedStorage.rbxmx` | `ReplicatedStorage` |
| `2-ServerScriptService.rbxmx` | `ServerScriptService` |
| `3-StarterPlayerScripts.rbxmx` | `StarterPlayer` > `StarterPlayerScripts` |

If you cannot find them, stop and ask the user where the folder is.

## Step 1: Open a new place

1. Open Roblox Studio.
2. Click **New** on the left, then choose the **Baseplate** template.
3. Make sure the **Explorer** panel is visible (right side). If not: open the **View** tab and click **Explorer**. Also turn on **Output** (View tab > Output); you will need it later.

## Step 2: Expand the services you will use

In **Explorer**, click the small arrow next to each of these to expand it: **ReplicatedStorage**, **ServerScriptService**, **StarterPlayer**, and then **StarterPlayerScripts** (it is inside StarterPlayer).

## Step 3: Remove any old copies (skip this step if there are none)

Look for these 9 scripts. If any exist, delete them (click one, hold **Ctrl** and click the others, press **Delete**):

- in `ReplicatedStorage`: `GameConfig`, `GhostModel`
- in `ServerScriptService`: `GameManager`, `Decor`, `Ghost`, `HotelBuilder`, `PlayerData`
- in `StarterPlayerScripts`: `HUD`, `Cutscene`

Do not delete anything else (leave `Workspace`, `Lighting`, `Baseplate`, etc. alone). A new Baseplate place will not have any of these, which is fine.

## Step 4: Import the three files

For each row, **right-click** the item in Explorer, choose **Insert from File...**, pick the file from `the-last-guest\studio-import\`, and click **Open**:

1. Right-click **ReplicatedStorage** > Insert from File... > `1-ReplicatedStorage.rbxmx`
2. Right-click **ServerScriptService** > Insert from File... > `2-ServerScriptService.rbxmx`
3. Right-click **StarterPlayerScripts** > Insert from File... > `3-StarterPlayerScripts.rbxmx`

## Step 5: Check the result

Expand the three places in Explorer. They must show **exactly** this, with no duplicates and nothing missing:

```
ReplicatedStorage:      GameConfig, GhostModel
ServerScriptService:    GameManager, Decor, Ghost, HotelBuilder, PlayerData
StarterPlayerScripts:   HUD, Cutscene
```

(`ReplicatedStorage` may also show other items Studio adds itself; ignore those.)

Also confirm the icons: `GameManager` is a **Script**, `HUD` and `Cutscene` are **LocalScripts**, and the other six are **ModuleScripts**. If a name appears twice, delete the extra and tell the user.

## Step 6: Test it

1. Click the **Home** tab, then the green **Play** button (or press **F5**).
2. Wait a few seconds. You should spawn in a **lobby** with a dark wooden room, a red "THE LAST GUEST" sign and three coloured pads (green EASY, yellow NORMAL, red NIGHTMARE). You should **not** be standing on the plain grey baseplate.
3. Walk onto the **yellow NORMAL** pad and wait for the countdown (about 25 seconds). You will be moved into a dark hotel corridor.
4. In the **Output** window, look for red text. Copy all red/error lines exactly.
5. Click the red **Stop** button to end the test.

A yellow warning that says `[TheLastGuest] Saving is off until you publish the game` is **expected**. A UIBlox / "FoundationProvider not found" warning is also expected and harmless. Neither is a problem.

## Step 7: Report back to the user

Tell the user, in plain words:

1. Whether Step 5's layout matched exactly (list anything different).
2. Whether the lobby appeared (yes/no) and whether the hotel appeared after voting (yes/no).
3. Any red error text from Output, copied exactly (line numbers and script names included).
4. A screenshot of the lobby and of the hotel corridor if you can take one.

Then stop. Do not try to fix errors by editing scripts. The user will send the error text to Claude Code to be fixed.

## Optional: add the music (only if the user says yes first)

The folder `the-last-guest\audio\` holds three tracks. Uploading them puts audio on the user's Roblox account, so **ask the user for permission before doing this**. If they say yes:

1. In Studio: **View** > **Asset Manager**. Right-click **Audio** > **Import** (or Bulk Import) and choose the three `.mp3` files. Wait for them to finish checking.
2. Right-click each one > **Copy ID to Clipboard** and note which ID belongs to which file.
3. Tell the user the three IDs. (Pasting them into `Config.Music` in `GameConfig` is a code change, so let the user decide whether you should do it.)

If Roblox blocks the upload or asks the user to verify their age or ID, stop and tell them.
