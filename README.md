# assetfile

Finally, a way to work with Roblox assets local to your computer.

## Overview

In most game development environments, assets like images, sounds, and 3D models are stored as project files tracked with version control. Roblox instead requires developers to manually upload assets to the platform, then reference them by unique asset IDs. If you want to change an asset, you have to reupload it, get a new ID, and update every reference.

Assetfile automates this. Point it at a local directory of assets, and it uploads them to Roblox via the Open Cloud API, generates a Luau module mapping file paths to asset IDs, and keeps everything in sync as files change.

## Installation

Install assetfile with [Rokit](https://github.com/rojo-rbx/rokit):

```
rokit add horsenuggets/assetfile
```

## Getting Started

### 1. Set Up an API Key

A Roblox Open Cloud API key with the `asset:write` permission is required. Create one at the [Creator Dashboard](https://create.roblox.com/dashboard/credentials).

Assetfile reads the API key from environment variables. Set `ROBLOX_API_KEY` in your shell or in a `.env` file in your project root:

```
ROBLOX_API_KEY=your-api-key-here
```

You can also use a custom environment variable name per mapping (see Configuration below).

### 2. Initialize a Project

Run `assetfile init` in your project directory to create an `assetfile.json` config file:

```
assetfile init
```

This walks you through selecting a creator type (user or group), asset directory, and output file path. For non-interactive use, pass flags directly:

```
assetfile init --user-id 12345 --assets Assets --output Assets.luau
```

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

## Configuration

The `assetfile.json` file defines one or more mappings between local asset directories and output Luau modules:

```json
{
    "Mappings": [
        {
            "Assets": "Assets",
            "Output": "Assets.luau",
            "Creator": {
                "UserId": "12345"
            }
        }
    ]
}
```

| Field           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `Assets`        | Path to the local directory containing asset files                        |
| `Output`        | Path for the generated Luau module                                        |
| `Creator`       | Who owns the uploaded assets: `UserId` for personal, `GroupId` for groups |
| `ApiKeyEnvName` | Environment variable name for the API key (default: `ROBLOX_API_KEY`)     |

This file should be committed to version control.

## Supported File Types

| Type  | Extensions                          |
| ----- | ----------------------------------- |
| Image | bmp, gif, jpeg, jpg, png, tga, webp |
| Audio | flac, mp3, ogg, wav                 |
| Model | fbx, glb, gltf, rbxm, rbxmx         |

## Commands

| Command           | Description                              |
| ----------------- | ---------------------------------------- |
| `assetfile init`  | Create a new assetfile.json config file  |
| `assetfile sync`  | Sync assets to Roblox once and exit      |
| `assetfile watch` | Watch for changes and sync automatically |

### `assetfile init`

| Flag            | Short | Description                               |
| --------------- | ----- | ----------------------------------------- |
| `--assets`      | `-a`  | Assets directory path                     |
| `--output`      | `-o`  | Output Luau file path                     |
| `--user-id`     | `-u`  | Roblox user ID for the creator            |
| `--group-id`    | `-g`  | Roblox group ID for the creator           |
| `--api-key-env` | `-k`  | Environment variable name for the API key |

### `assetfile watch`

| Flag         | Short | Description                           |
| ------------ | ----- | ------------------------------------- |
| `--interval` | `-i`  | Poll interval in seconds (default: 2) |
