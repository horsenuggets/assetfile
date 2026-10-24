#!/usr/bin/env -S lune run

--[[

RunCli.exec

Runs the Assetfile CLI directly from source without building.

[Usage] ./Scripts/RunCli.exec.luau [args...]

--]]

const process = require("@lune/process")

const RunCli = {}

function RunCli.exec()
    const args = { "run", "./Source/AssetfileCli" }
    for _, arg in process.args do
        table.insert(args, arg)
    end

    process.exec("lune", args, {
        stdio = "forward",
    })
end

RunCli.exec()
