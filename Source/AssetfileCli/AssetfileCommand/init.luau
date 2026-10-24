--[[

AssetfileCommand

The root command for the assetfile CLI. Registers all subcommands for
managing local asset files synced with Roblox.

--]]

const Commandline = require("@packages/Commandline")

const InitCommand = require("@self/InitCommand")
const SyncCommand = require("@self/SyncCommand")
const WatchCommand = require("@self/WatchCommand")
const __VERSION__ = require("@self/__VERSION__")

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
