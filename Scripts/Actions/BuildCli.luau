require("../Helpers/AssertCwdIsRoot")()

local fs = require("@lune/fs")
local process = require("@lune/process")

local function buildCli()
    if not fs.isDir("./Build/") then
        fs.makeDir("./Build/")
    end

    process.exec("lune", {
        "build",
        "./Source/Commandline/AssetfileCli.luau",
        "-o",
        "./Build/assetfile",
    }, {
        stdio = "forward",
    })
end

buildCli()
