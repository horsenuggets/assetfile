#!/usr/bin/env -S lune run

--[[

InstallCompletions

Installs shell completion scripts for the assetfile CLI.

--]]

local AssetfileCommand = require("@assetfilecli/AssetfileCommand")
local Commandline = require("@packages/Commandline")
local process = require("@lune/process")

Commandline.Toolkit.installCompletions({
    Command = AssetfileCommand,
    Shell = process.args[1] or "zsh",
})
