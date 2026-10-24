--[[

WatchCommand

Watches asset directories and syncs changes automatically. Validates all
API keys upfront before starting the file watcher.

--]]

const Commandline = require("@packages/Commandline")

const Config = require("@assetfile/Config")
const Watcher = require("@assetfile/Watcher")

const resolveApiKey = require("@assetfilecli/Helpers/resolveApiKey")

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
        const config = Config.load()

        -- Validate all API keys upfront before starting the watcher
        const apiKeys: { [number]: string } = {}
        for i, mapping in config.Mappings do
            apiKeys[i] = resolveApiKey(mapping.ApiKeyEnvName)
        end

        Watcher.watch(config.Mappings, apiKeys, flags.interval.Value)
    end,
})
