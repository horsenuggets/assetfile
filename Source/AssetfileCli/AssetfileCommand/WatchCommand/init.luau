--[[

WatchCommand

Watches asset directories and syncs changes automatically. Validates all
API keys upfront before starting the file watcher.

--]]

local Commandline = require("@packages/Commandline")

local Config = require("@assetfile/Config")
local Watcher = require("@assetfile/Watcher")

local resolveApiKey = require("@assetfilecli/Helpers/resolveApiKey")

return Commandline.Command.new({
    Name = "watch",
    Description = "Watch asset directories and sync changes automatically.",
    Flags = {
        Commandline.Flag.new({
            Name = "interval",
            Description = "Poll interval in seconds.",
            Shorthand = "i",
            Type = "number",
            Default = 2,
        }),
    },
    Impl = function(_args: any, flags: any)
        assert(Config.exists(), "No assetfile.json found in current directory.")
        local config = Config.load()

        -- Validate all API keys upfront before starting the watcher
        local apiKeys: { [number]: string } = {}
        for i, mapping in config.Mappings do
            apiKeys[i] = resolveApiKey(mapping.ApiKeyEnvName)
        end

        Watcher.watch(config.Mappings, apiKeys, flags.interval.Value)
    end,
})
