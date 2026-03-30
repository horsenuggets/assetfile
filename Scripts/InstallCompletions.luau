#!/usr/bin/env -S lune run

--[[

InstallCompletions

Installs shell completion scripts for the assetfile CLI.

--]]

local Commandline = require("@packages/Commandline")
local process = require("@lune/process")

-- Build the command tree for completion generation
local rootCommand = Commandline.Command.new({
    Name = "assetfile",
    Description = "Finally, a way to work with Roblox assets local to your computer.",
    Subcommands = {
        Commandline.Command.new({
            Name = "init",
            Description = "Create a new assetfile.json configuration file.",
            Flags = {
                Commandline.Flag.new({
                    Name = "api-key-env",
                    Shorthand = "k",
                    Description = "Environment variable name for the API key.",
                    Type = "string",
                }),
                Commandline.Flag.new({
                    Name = "assets",
                    Shorthand = "a",
                    Description = "Assets directory path.",
                    Type = "string",
                }),
                Commandline.Flag.new({
                    Name = "group-id",
                    Shorthand = "g",
                    Description = "Roblox group ID for the creator.",
                    Type = "string",
                }),
                Commandline.Flag.new({
                    Name = "output",
                    Shorthand = "o",
                    Description = "Output Luau file path.",
                    Type = "string",
                }),
                Commandline.Flag.new({
                    Name = "user-id",
                    Shorthand = "u",
                    Description = "Roblox user ID for the creator.",
                    Type = "string",
                }),
            },
        }),
        Commandline.Command.new({
            Name = "sync",
            Description = "Sync assets to Roblox once and exit.",
        }),
        Commandline.Command.new({
            Name = "watch",
            Description = "Watch asset directories and sync changes automatically.",
            Flags = {
                Commandline.Flag.new({
                    Name = "interval",
                    Shorthand = "i",
                    Description = "Poll interval in seconds.",
                    Type = "number",
                }),
            },
        }),
    },
})

Commandline.Toolkit.installCompletions({
    Command = rootCommand,
    Shell = process.args[1] or "zsh",
})
