#!/usr/bin/env -S lune run

--[[

AssetfileCli

The entry point for the assetfile CLI. Registers all commands and executes
with process arguments.

--]]

local process = require("@lune/process")
local stdio = require("@lune/stdio")

local Commandline = require("@packages/Commandline")

local AssetfileCommand = require("@assetfilecli/AssetfileCommand")

local function assetfileCli()
    Commandline.registerCommand(AssetfileCommand)

    local ok, err = pcall(AssetfileCommand.Execute, AssetfileCommand, process.args)
    if not ok then
        stdio.ewrite(`{err}\n`)
        process.exit(1)
    end
end

assetfileCli()
