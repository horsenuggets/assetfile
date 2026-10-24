#!/usr/bin/env -S lune run

--[[

GenerateCompletions.exec

Generates shell completion scripts for the assetfile CLI.

[Usage] ./Scripts/GenerateCompletions.exec.luau [bash|zsh|fish|powershell]

--]]

const AssetfileCommand = require("@assetfilecli/AssetfileCommand")
const Commandline = require("@packages/Commandline")
const process = require("@lune/process")

const GenerateCompletions = {}

function GenerateCompletions.exec()
    print(Commandline.Completions.generate(AssetfileCommand, process.args[1] or "zsh"))
end

GenerateCompletions.exec()
