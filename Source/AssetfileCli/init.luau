#!/usr/bin/env -S lune run

--[[

AssetfileCli

The entry point for the assetfile CLI. Registers all commands and executes
with process arguments.

--]]

const process = require("@lune/process")
const stdio = require("@lune/stdio")

const Commandline = require("@packages/Commandline")

const AssetfileCommand = require("@assetfilecli/AssetfileCommand")

const function assetfileCli()
    Commandline.registerCommand(AssetfileCommand)

    const ok, err = pcall(AssetfileCommand.Execute, AssetfileCommand, process.args)
    if not ok then
        stdio.ewrite(`{err}\n`)
        process.exit(1)
    end
end

assetfileCli()
