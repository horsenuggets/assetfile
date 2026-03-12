# Assetfile

Finally, a way to work with Roblox assets local to your computer.

## Overview

In many game development environments outside of Roblox, assets such as images, sounds, and
3D models are stored as literal project files tracked with version control. Roblox, in
contrast, requires developers to manually upload assets to the platform, then reference them
by unique asset IDs. If you want to change an asset, you have to reupload it, get a new ID,
and update every reference.

Assetfile automates this. Point it at a local directory of assets, and it uploads them to
Roblox via the Open Cloud API, generates a Luau module mapping file paths to asset IDs, and
keeps everything in sync as files change.

## Installation

Install assetfile with [Rokit](https://github.com/rojo-rbx/rokit):

```
rokit add horsenuggets/assetfile
```

## Getting Started

### 1. Add an API Key

A Roblox Open Cloud API key with the `asset:write` permission is required. Create one at the
[Creator Dashboard](https://create.roblox.com/dashboard/credentials), then store it with
assetfile:

```
assetfile api-key add
```

API keys are stored locally in `~/.assetfile/` and are never written to project files. You
can also set the `ROBLOX_API_KEY` environment variable instead (useful for CI).

### 2. Initialize a Project

Run `assetfile init` in your project directory to create an `assetfile.json` config file:

```
assetfile init
```

This creates an `assetfile.json` that maps a local asset directory to an output Luau module:

```json
{
    "mappings": [
        {
            "assets": "assets",
            "output": "Assets.luau",
            "creator": {
                "userId": "12345"
            }
        }
    ]
}
```

The `creator` field specifies who owns the uploaded assets. Use `userId` for personal
uploads or `groupId` for group-owned assets. This file should be committed to version control.

### 3. Sync Assets

Place your asset files in the configured directory, then run:

```
assetfile sync
```

Or watch for changes continuously:

```
assetfile watch
```

Assetfile uploads new and changed files, removes stale entries, and generates a Luau module:

```luau
return {
    ["BackgroundMusic.mp3"] = "rbxassetid://1234567890",
    ["Models/Rock.fbx"] = "rbxassetid://6789012345",
    ["Models/Tree.fbx"] = "rbxassetid://5678901234",
    ["Skybox.png"] = "rbxassetid://2345678901",
    ["SoundEffects/Hit.wav"] = "rbxassetid://3456789012",
    ["SoundEffects/Jump.wav"] = "rbxassetid://4567890123",
}
```

Use it in your game code:

```luau
local Assets = require(ReplicatedStorage.Assets)

local backgroundMusic = Instance.new("Sound")
backgroundMusic.SoundId = Assets["BackgroundMusic.mp3"]
backgroundMusic.Parent = workspace
backgroundMusic:Play()
```

## Supported File Types

| Type  | Extensions                          |
| ----- | ----------------------------------- |
| Image | bmp, gif, jpeg, jpg, png, tga, webp |
| Audio | flac, mp3, ogg, wav                 |
| Model | fbx, glb, gltf, rbxm, rbxmx        |

## Commands

| Command                    | Description                              |
| -------------------------- | ---------------------------------------- |
| `assetfile init`           | Create a new assetfile.json config file  |
| `assetfile sync`           | Sync assets to Roblox once and exit      |
| `assetfile watch`          | Watch for changes and sync automatically |
| `assetfile api-key add`    | Add a Roblox API key                     |
| `assetfile api-key list`   | List stored API keys                     |
| `assetfile api-key remove` | Remove a stored API key                  |
