#!/usr/bin/env -S lune run

--[[

RunCli

Runs the Assetfile CLI directly from source without building.

[Usage] lune run ./Scripts/RunCli.luau

--]]

local process = require("@lune/process")

local function runCli()
    local args = { "run", "./Source/Commandline/AssetfileCli.luau" }
    for _, arg in process.args do
        table.insert(args, arg)
    end

    process.exec("lune", args, {
        stdio = "forward",
    })
end

runCli()
