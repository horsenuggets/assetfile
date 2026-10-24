--[[

SyncCommand

Syncs assets to Roblox once and exits. Iterates through all mappings in the
configuration, uploads changes, and reports totals.

--]]

const process = require("@lune/process")

const Chalk = require("@packages/Chalk")
const Commandline = require("@packages/Commandline")

const Config = require("@assetfile/Config")
const Sync = require("@assetfile/Sync")

const resolveApiKey = require("@assetfilecli/Helpers/resolveApiKey")

return Commandline.Command.new({
    Name = "sync",
    Description = "Sync assets to Roblox once and exit.",
    Impl = function(_args: any, _flags: any)
        assert(Config.exists(), "No assetfile.json found in current directory.")
        const config = Config.load()

        local totalFailed = 0
        local totalRemoved = 0
        local totalUpdated = 0
        local totalUploaded = 0

        for _, mapping in config.Mappings do
            const apiKey = resolveApiKey(mapping.ApiKeyEnvName)
            const result = Sync.run(mapping, apiKey)
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
