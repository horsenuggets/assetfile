--[[

SyncCommand

Syncs assets to Roblox once and exits. Iterates through all mappings in the
configuration, uploads changes, and reports totals.

--]]

local process = require("@lune/process")

local Chalk = require("@packages/Chalk")
local Commandline = require("@packages/Commandline")

local Config = require("@assetfile/Config")
local Sync = require("@assetfile/Sync")

local resolveApiKey = require("@assetfilecli/Helpers/resolveApiKey")

return Commandline.Command.new({
    Name = "sync",
    Description = "Sync assets to Roblox once and exit.",
    Impl = function(_args: any, _flags: any)
        assert(Config.exists(), "No assetfile.json found in current directory.")
        local config = Config.load()

        local totalFailed = 0
        local totalRemoved = 0
        local totalUpdated = 0
        local totalUploaded = 0

        for _, mapping in config.mappings do
            local apiKey = resolveApiKey(mapping.apiKeyEnvName)
            local result = Sync.run(mapping, apiKey)
            totalFailed += result.Failed
            totalRemoved += result.Removed
            totalUpdated += result.Updated
            totalUploaded += result.Uploaded
        end

        print(
            `\n{Chalk.bold("Sync complete.")}`
                .. ` {totalUploaded} uploaded, {totalUpdated} updated,`
                .. ` {totalRemoved} removed, {totalFailed} failed.`
        )

        if totalFailed > 0 then
            process.exit(1)
        end
    end,
})
