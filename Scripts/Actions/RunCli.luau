#!/usr/bin/env -S lune run

require("../Helpers/AssertCwdIsRoot")()

local process = require("@lune/process")

local function runCli()
    process.exec("lune", {
        "run",
        "./Source/Commandline/AssetfileCli.luau",
    }, {
        stdio = "forward",
    })
end

runCli()
