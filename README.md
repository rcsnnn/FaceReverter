<center>
<img src="https://camo.githubusercontent.com/8ec0d23e965e6dbf4bd4129af84a6a4ff6ffb0b5b1c5e588651c1715eb6b2177/68747470733a2f2f7374617469632e77696b69612e6e6f636f6f6b69652e6e65742f726f626c6f782f696d616765732f392f39662f417765736f6d654661636544796e616d69632e77656270" height=""></img>
<h1>FaceReverter</h1>
</center>

To install you can use faceReverterModule.lua and make a module. Or get the model on [roblox](https://create.roblox.com/store/asset/84351471308087).

## Setup
Drop the module in `ReplicatedStorage`, then call it from both the server and client:

```lua
-- server (ServerScriptService)
local FaceReverter = require(game.ReplicatedStorage.faceReverterModule)
FaceReverter.startServer()

-- client (StarterCharacterScripts)
local FaceReverter = require(game.ReplicatedStorage.faceReverterModule)
FaceReverter.startClient()
```

You need both running or it won't work. Enable `HttpService` if you're using `facesJsonUrl`.

----------

## Config

All the configs are at the top of the module. :)

**Settings**

-   `remoteName`
-- Name of the `RemoteEvent` in `ReplicatedStorage`. Must match on both sides. Defaults to `faceReverterEvent`
-   `facesJsonUrl`
-- URL to the `faces.json` file in this repo that maps face names to decal IDs. Set to `""` to use the local fallback list instead.
-   `respawnDelay`
-- Seconds to wait after a character loads before touching the rig. Defaults to `1`
-   `defaultFaceId`
-- Placeholder face used while things are loading, and the final fallback for NPCs and rigs.
-   `faceYOffset`
-- Tweaks the vertical position of the face on the new part. Adjust if it looks off.
-   `fallbackFaceIds`
-- Local table of face names to decal IDs, used if `faces.json` fails or is turned off.

**Flags**

-   `convertDynamicNpcs`
-- Convert NPCs that have `FaceControls`. Defaults to `true`
-   `convertAllRigs`
-- Convert any rig with a `Humanoid` + `Head`, not just dynamic ones. Defaults to `true`
-   `convertRigChanges`
-- Re-apply faces if a player's rig changes mid-game. Defaults to `true`
-   `matchDynamicFace`
-- Looks up the player's dynamic face in the json and swaps it for the classic 2D version. Defaults to `true`
-   `scanWorkspace`
-- Scans all of Workspace for NPC rigs on startup. Defaults to `true`
-   `pollFaceChanges`
-- Watches the local player's avatar and updates the server if their equipped assets change. Defaults to `true`
-   `pollInterval`
-- How often the poll runs, in seconds. Defaults to `5`
-   `acceptModelPaths`
-- Extra folders/models to always scan for NPCs.
-   `excludeModelPaths`
-- Models here get skipped entirely.
-   `robloxHeadsOnly`
-- Only convert dynamic heads made by Roblox. UGC heads are left alone. Doesn't affect NPCs and rigs. Defaults to `false`
-   `dynamicFaceRollback`
-- If a face name has no match in the json, keep the dynamic head as-is instead of falling back to the default face. Retried every respawn, so updating the json happens next time the player spawns. If both this and `robloxHeadsOnly` are on, UGC heads are always untouched. This only applies to Roblox-made faces with no match. Defaults to `false`

----------

## Functions

-   `startServer()`
-- Run on the server. Sets everything up.
-   `startClient()`
-- Run on the client. Connects to the remote and sends the player face info to the server.
-   `convertRig(rig, faceId?)`
-- Manually convert a rig. Leave out `faceId` to use whatever face is already on the head.
-   `convertCustomRig(rig, faceId?)`
-- Same as above but forces the custom-rig path. Use for `MeshPart` heads or rigs with `FaceControls`.
-   `getPlayerFaceId(userId)`
-- Returns the cached face decal ID for a player, or `nil` if not resolved yet.
-   `getPlayerCreatorStatus(userId)`
-- Returns whether a player's dynamic face is made by Roblox (`true`), UGC (`false`), or classic/unknown (`nil`).
