require("../Helpers/AssertCwdIsRoot")()

local fs = require("@lune/fs")

local function syncVersion()
    -- Get project version and trim whitespace
    local projectVersion = (fs.readFile("./VERSION"):gsub("%s+", ""))

    -- Read wally.toml
    local wallyConfig = fs.readFile("./wally.toml")

    -- Replace version = "..." with version = "<projectVersion>"
    local newConfig = wallyConfig:gsub(`version%s*=%s*"(.-)"`, `version = "{projectVersion}"`)

    -- Only write if changed
    if newConfig ~= wallyConfig then
        fs.writeFile("./wally.toml", newConfig)
        print(`Updated wally.toml version to "{projectVersion}"!`)
    else
        print(`Version already up to date.`)
    end
end

syncVersion()
