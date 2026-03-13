#!/usr/bin/env -S lune run

--[[

AssetfileCli

Entry point for the Assetfile CLI. Registers all commands and executes
the command line.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local Chalk = require("@packages/Chalk")
local Commandline = require("@packages/Commandline")
local Dotenv = require("@packages/Dotenv")

local Config = require("@assetfile/Config")
local Sync = require("@assetfile/Sync")
local Watcher = require("@assetfile/Watcher")

local VERSION = "0.0.2"

local function resolveApiKey(envName: string?): string
    pcall(Dotenv.load)

    local name = envName or "ROBLOX_API_KEY"
    local apiKey = process.env[name]

    if apiKey and #apiKey > 0 then
        return apiKey
    end

    error(`No API key found. Set {name} in your .env file or as an environment variable.`)
end

-- sync command

local syncCommand = Commandline.Command.new({
    Name = "sync",
    Description = "Sync assets to Roblox once and exit.",
    Impl = function(_args: any, _flags: any)
        assert(Config.exists(), "No assetfile.json found in current directory.")
        local config = Config.load()

        local totalUploaded = 0
        local totalUpdated = 0
        local totalRemoved = 0
        local totalFailed = 0

        for _, mapping in config.mappings do
            local apiKey = resolveApiKey(mapping.apiKeyEnvName)
            local result = Sync.run(mapping, apiKey)
            totalUploaded += result.Uploaded
            totalUpdated += result.Updated
            totalRemoved += result.Removed
            totalFailed += result.Failed
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

-- watch command

local watchCommand = Commandline.Command.new({
    Name = "watch",
    Description = "Watch asset directories and sync changes automatically.",
    Flags = {
        Commandline.Flag.new({
            Name = "interval",
            Description = "Poll interval in seconds.",
            Type = "number",
            Shorthand = "i",
            Default = 2,
        }),
    },
    Impl = function(_args: any, flags: any)
        assert(Config.exists(), "No assetfile.json found in current directory.")
        local config = Config.load()

        -- Validate all API keys upfront before starting the watcher
        local apiKeys: { [number]: string } = {}
        for i, mapping in config.mappings do
            apiKeys[i] = resolveApiKey(mapping.apiKeyEnvName)
        end

        Watcher.watch(config.mappings, apiKeys, flags.interval.Value)
    end,
})

-- init command

local initCommand = Commandline.Command.new({
    Name = "init",
    Description = "Create a new assetfile.json configuration file.",
    Flags = {
        Commandline.Flag.new({
            Name = "api-key-env",
            Description = "Environment variable name for the API key.",
            Type = "string",
            Shorthand = "k",
        }),
        Commandline.Flag.new({
            Name = "assets",
            Description = "Assets directory path.",
            Type = "string",
            Shorthand = "a",
        }),
        Commandline.Flag.new({
            Name = "group-id",
            Description = "Roblox group ID for the creator.",
            Type = "string",
            Shorthand = "g",
        }),
        Commandline.Flag.new({
            Name = "output",
            Description = "Output Luau file path.",
            Type = "string",
            Shorthand = "o",
        }),
        Commandline.Flag.new({
            Name = "user-id",
            Description = "Roblox user ID for the creator.",
            Type = "string",
            Shorthand = "u",
        }),
    },
    Impl = function(_args: any, flags: any)
        if Config.exists() then
            print("assetfile.json already exists.")
            return
        end

        local userId = flags["user-id"].Value :: string?
        local groupId = flags["group-id"].Value :: string?
        local nonInteractive = userId ~= nil or groupId ~= nil

        if not userId and not groupId then
            userId = stdio.prompt("text", "Roblox user ID (blank to use group ID instead)")
            if #userId == 0 then
                userId = nil
                groupId = stdio.prompt("text", "Roblox group ID")
                assert(#groupId > 0, "Must provide either a user ID or group ID.")
            end
        end

        local assetsDir = flags.assets.Value :: string?
        if not assetsDir then
            if nonInteractive then
                assetsDir = "assets"
            else
                assetsDir = stdio.prompt("text", 'Assets directory ("assets" if blank)')
                if #assetsDir == 0 then
                    assetsDir = "assets"
                end
            end
        end

        local outputPath = flags.output.Value :: string?
        if not outputPath then
            if nonInteractive then
                outputPath = "Assets.luau"
            else
                outputPath = stdio.prompt("text", 'Output Luau file ("Assets.luau" if blank)')
                if #outputPath == 0 then
                    outputPath = "Assets.luau"
                end
            end
        end

        local apiKeyEnvName = flags["api-key-env"].Value :: string?
        if not apiKeyEnvName and not nonInteractive then
            apiKeyEnvName = stdio.prompt("text", 'API key env variable name ("ROBLOX_API_KEY" if blank)')
            if #apiKeyEnvName == 0 then
                apiKeyEnvName = nil
            end
        end

        local creator: { [string]: string } = {}
        if userId then
            creator.userId = userId
        else
            creator.groupId = groupId :: string
        end

        local mapping: { [string]: any } = {
            assets = assetsDir,
            output = outputPath,
            creator = creator,
        }

        if apiKeyEnvName and apiKeyEnvName ~= "ROBLOX_API_KEY" then
            mapping.apiKeyEnvName = apiKeyEnvName
        end

        local config = {
            mappings = { mapping },
        }

        fs.writeFile("assetfile.json", serde.encode("json", config))
        print(`Created assetfile.json with assets directory "{assetsDir}".`)

        if not fs.isDir(assetsDir :: string) then
            fs.writeDir(assetsDir :: string)
            print(`Created directory "{assetsDir}".`)
        end
    end,
})

-- root command

local rootCommand = Commandline.Command.new({
    Name = "assetfile",
    Description = "Finally, a way to work with Roblox assets local to your computer.",
    Version = VERSION,
    Subcommands = {
        initCommand,
        syncCommand,
        watchCommand,
    },
})

local function assetfileCli()
    Commandline.registerCommand(rootCommand)

    local ok, err = pcall(Commandline.execute, "assetfile " .. table.concat(process.args, " "))
    if not ok then
        stdio.ewrite(`{err}\n`)
        process.exit(1)
    end
end

assetfileCli()
