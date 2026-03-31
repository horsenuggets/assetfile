--[[

Config

Loads and validates the assetfile.json project configuration file. The
config maps local asset directories to output Luau modules that contain
asset ID mappings.

--]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local t = require("@packages/t")

local CONFIG_FILENAME = "assetfile.json"

export type AssetMapping = {
    ApiKeyEnvName: string?,
    Assets: string,
    Output: string,
    Creator: CreatorConfig,
}

export type CreatorConfig = {
    UserId: string?,
    GroupId: string?,
}

export type Config = {
    Mappings: { AssetMapping },
}

local validateCreator = t.interface({
    UserId = t.optional(t.string),
    GroupId = t.optional(t.string),
})

local validateMapping = t.interface({
    ApiKeyEnvName = t.optional(t.string),
    Assets = t.string,
    Output = t.string,
    Creator = validateCreator,
})

local validateConfig = t.interface({
    Mappings = t.array(validateMapping),
})

local Config = {}

function Config.load(path: string?): Config
    local configPath = path or CONFIG_FILENAME

    assert(fs.isFile(configPath), `Config file "{configPath}" not found.`)

    local content = fs.readFile(configPath)
    local data = serde.decode("json", content)

    local ok, err = validateConfig(data)
    assert(ok, `Invalid config file "{configPath}"\n{err}`)

    -- Validate that each Creator has exactly one of UserId or GroupId
    for i, mapping in data.Mappings do
        local creator = mapping.Creator
        local hasUserId = creator.UserId ~= nil
        local hasGroupId = creator.GroupId ~= nil
        assert(hasUserId or hasGroupId, `Mapping {i} must have either "UserId" or "GroupId" in Creator.`)
        assert(
            not (hasUserId and hasGroupId),
            `Mapping {i} must have only one of "UserId" or "GroupId" in Creator, not both.`
        )
    end

    return data :: Config
end

function Config.exists(path: string?): boolean
    return fs.isFile(path or CONFIG_FILENAME)
end

return Config
