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
    assets: string,
    output: string,
    creator: CreatorConfig,
}

export type CreatorConfig = {
    userId: string?,
    groupId: string?,
}

export type Config = {
    mappings: { AssetMapping },
}

local validateCreator = t.interface({
    userId = t.optional(t.string),
    groupId = t.optional(t.string),
})

local validateMapping = t.interface({
    assets = t.string,
    output = t.string,
    creator = validateCreator,
})

local validateConfig = t.interface({
    mappings = t.array(validateMapping),
})

local Config = {}

function Config.load(path: string?): Config
    local configPath = path or CONFIG_FILENAME

    assert(fs.isFile(configPath), `Config file "{configPath}" not found.`)

    local content = fs.readFile(configPath)
    local data = serde.decode("json", content)

    local ok, err = validateConfig(data)
    assert(ok, `Invalid config file "{configPath}"\n{err}`)

    -- Validate that each creator has exactly one of userId or groupId
    for i, mapping in data.mappings do
        local creator = mapping.creator
        local hasUserId = creator.userId ~= nil
        local hasGroupId = creator.groupId ~= nil
        assert(hasUserId or hasGroupId, `Mapping {i} must have either "userId" or "groupId" in creator.`)
        assert(
            not (hasUserId and hasGroupId),
            `Mapping {i} must have only one of "userId" or "groupId" in creator, not both.`
        )
    end

    return data :: Config
end

function Config.exists(path: string?): boolean
    return fs.isFile(path or CONFIG_FILENAME)
end

return Config
