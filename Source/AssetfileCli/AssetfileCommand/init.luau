--[[

AssetfileCommand

The root command for the assetfile CLI. Registers all subcommands for
managing local asset files synced with Roblox.

--]]

local Commandline = require("@packages/Commandline")

local InitCommand = require("@self/InitCommand")
local SyncCommand = require("@self/SyncCommand")
local WatchCommand = require("@self/WatchCommand")
local __VERSION__ = require("@self/__VERSION__")

return Commandline.Command.new({
    Name = "assetfile",
    Description = "Finally, a way to work with Roblox assets local to your computer.",
    Version = __VERSION__,
    Subcommands = {
        InitCommand,
        SyncCommand,
        WatchCommand,
    },
})
