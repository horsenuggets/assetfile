# Assetfile

Finally, a way to work with Roblox assets local to your computer.

## Overview

In many game development environments outside of Roblox, assets such as images, sounds, and 3D models are stored as literal project files tracked with version control. Roblox, in contrast, works such that developers manually upload assets to the platform, which are then referenced by their unique asset IDs. If you want to change an asset, you have to reupload it, get a new asset ID, and update the references.

Assetfile allows you to sync a local directory of assets with Roblox, automating the upload process and managing asset IDs. This way, you can keep your assets in version control, make changes locally, and have those changes reflected in your Roblox projects seamlessly.

## Installation

There are 2 parts to Assetfile: the CLI tool, and the Roblox Studio plugin. The CLI tool tracks your local directory and sends information to the Roblox Studio plugin, which stores filepath to asset ID mappings in a Luau module that your game can require.

### CLI Tool

You can install the CLI tool either by [downloading the binary directly](), or by running one of the following commands in a terminal window based on your platform:

#### Unix (Linux / macOS)

```
<unix-install-command>
```

#### Windows

```
<windows-install-command>
```

### Roblox Studio Plugin

You can install the Roblox Studio plugin by downloading the `*.rbxm` directly from the [releases page]() and moving it to your Roblox Studio plugins folder, or by [adding it through the Creator Hub]().

## Usage

### Adding a Roblox API Key

A Roblox Open Cloud API key with the `asset:write` permission is needed in order to sync assets. An API key can be created [here](https://create.roblox.com/dashboard/credentials).

Then, add the API key to Assetfile:

```
> assetfile api-key add
What would you like to name this API key ("default" if unspecified)? my-api-key
What are the contents of your API key? *****
API key "my-api-key" added successfully.
```

### Syncing Assets

Let's say you have a directory of assets you want to use:

```
/path/to/your/assets
├─ BackgroundMusic.mp3
├─ Skybox.png
├─ SoundEffects/
│  ├─ Hit.wav
│  └─ Jump.wav
└─ Models/
   ├─ Tree.fbx
   └─ Rock.fbx
```

You can run the following command to start watching the directory and syncing assets:

```
> assetfile watch /path/to/your/assets --out Assets.luau
Watching directory "/path/to/your/assets"...
```

After running the command, Assetfile will upload the assets to Roblox and generate an `Assets.luau` file that looks like this:

```lua
-- Assets.luau
return {
    ["BackgroundMusic.mp3"] = "rbxassetid://1234567890",
    ["Skybox.png"] = "rbxassetid://2345678901",
    ["SoundEffects/Hit.wav"] = "rbxassetid://3456789012",
    ["SoundEffects/Jump.wav"] = "rbxassetid://4567890123",
    ["Models/Tree.fbx"] = "rbxassetid://5678901234",
    ["Models/Rock.fbx"] = "rbxassetid://6789012345",
}
```

If the contents of any asset change, Assetfile will automatically reupload the asset and update the asset ID in the `Assets.luau` file.

Using the Roblox Studio plugin, you can also sync local asset directories with ModuleScripts.

Here is an example of how to use the generated `Assets.luau` module in your game code!

```lua
-- Load the Assets module
local Assets = require(ReplicatedStorage.Assets)

-- Use the BackgroundMusic.mp3 asset
local backgroundMusic = Instance.new("Sound")
backgroundMusic.SoundId = Assets["BackgroundMusic.mp3"]
backgroundMusic.Parent = workspace
backgroundMusic:Play()
```
