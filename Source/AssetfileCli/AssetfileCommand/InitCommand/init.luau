--[[

InitCommand

Creates a new assetfile.json configuration file. Supports both interactive
prompts and non-interactive mode via flags.

--]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local Commandline = require("@packages/Commandline")

local Config = require("@assetfile/Config")

return Commandline.Command.new({
    Name = "init",
    Description = "Create a new assetfile.json configuration file.",
    Flags = {
        Commandline.Flag.new({
            Name = "api-key-env",
            Description = "Environment variable name for the API key.",
            Shorthand = "k",
            Type = "string",
        }),
        Commandline.Flag.new({
            Name = "assets",
            Description = "Assets directory path.",
            Shorthand = "a",
            Type = "string",
        }),
        Commandline.Flag.new({
            Name = "group-id",
            Description = "Roblox group ID for the creator.",
            Shorthand = "g",
            Type = "string",
        }),
        Commandline.Flag.new({
            Name = "output",
            Description = "Output Luau file path.",
            Shorthand = "o",
            Type = "string",
        }),
        Commandline.Flag.new({
            Name = "user-id",
            Description = "Roblox user ID for the creator.",
            Shorthand = "u",
            Type = "string",
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
            local creatorType = stdio.prompt("select", "Creator type", { "User ID", "Group ID" })
            if creatorType == 1 then
                userId = stdio.prompt("text", "Roblox user ID")
                assert(#userId > 0, "Must provide a user ID.")
            else
                groupId = stdio.prompt("text", "Roblox group ID")
                assert(#groupId > 0, "Must provide a group ID.")
            end
        end

        local assetsDir = flags.assets.Value :: string?
        if not assetsDir then
            if nonInteractive then
                assetsDir = "Assets"
            else
                assetsDir = stdio.prompt("text", 'Assets directory ("Assets" if blank)')
                if #assetsDir == 0 then
                    assetsDir = "Assets"
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
            creator.UserId = userId
        else
            creator.GroupId = groupId :: string
        end

        local mapping: { [string]: any } = {
            Assets = assetsDir,
            Creator = creator,
            Output = outputPath,
        }

        if apiKeyEnvName and apiKeyEnvName ~= "ROBLOX_API_KEY" then
            mapping.ApiKeyEnvName = apiKeyEnvName
        end

        local config = {
            Mappings = { mapping },
        }

        fs.writeFile("assetfile.json", serde.encode("json", config))
        print(`Created assetfile.json with assets directory "{assetsDir}".`)

        if not fs.isDir(assetsDir :: string) then
            fs.writeDir(assetsDir :: string)
            print(`Created directory "{assetsDir}".`)
        end
    end,
})
