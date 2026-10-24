#!/usr/bin/env -S lune run

--[[

InstallCompletions.exec

Installs shell completion scripts for the assetfile CLI.

[Usage] ./Scripts/InstallCompletions.exec.luau [bash|zsh|fish|powershell]

--]]

const AssetfileCommand = require("@assetfilecli/AssetfileCommand")
const Commandline = require("@packages/Commandline")
const process = require("@lune/process")

const InstallCompletions = {}

function InstallCompletions.exec()
    Commandline.Toolkit.installCompletions({
        Command = AssetfileCommand,
        Shell = process.args[1] or "zsh",
    })
end

InstallCompletions.exec()
