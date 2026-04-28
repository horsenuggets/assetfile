#!/usr/bin/env -S lune run

--[[

GenerateCompletions

Generates shell completion scripts for the assetfile CLI.

--]]

local AssetfileCommand = require("@assetfilecli/AssetfileCommand")
local Commandline = require("@packages/Commandline")
local process = require("@lune/process")

local shell = process.args[1] or "zsh"
print(Commandline.Completions.generate(AssetfileCommand, shell))
