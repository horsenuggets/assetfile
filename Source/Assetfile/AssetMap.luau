--[[

AssetMap

Manages the mapping between local file paths and Roblox asset IDs.
Persists mappings to a JSON cache file and generates Luau modules that
game code can require.

--]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local t = require("@packages/t")

local CACHE_FILENAME = ".assetfile-cache.json"

export type AssetEntry = {
    assetId: string,
    hash: string,
}

export type AssetMap = {
    Get: (self: AssetMap, relativePath: string) -> AssetEntry?,
    Set: (self: AssetMap, relativePath: string, assetId: string, hash: string) -> (),
    Remove: (self: AssetMap, relativePath: string) -> (),
    GetAll: (self: AssetMap) -> { [string]: AssetEntry },
    Save: (self: AssetMap) -> (),
    WriteLuauModule: (self: AssetMap, outputPath: string) -> (),
}

local AssetMap = {}
AssetMap.__index = AssetMap

function AssetMap.new(cacheDir: string): AssetMap
    assert(t.string(cacheDir))

    local cachePath = `{cacheDir}/{CACHE_FILENAME}`
    local entries: { [string]: AssetEntry } = {}

    if fs.isFile(cachePath) then
        local content = fs.readFile(cachePath)
        local ok, data = pcall(serde.decode, "json" :: any, content)
        if ok and type(data) == "table" then
            entries = data
        end
    end

    local self = setmetatable({
        _entries = entries,
        _cachePath = cachePath,
        _cacheDir = cacheDir,
    }, AssetMap)

    return self
end

function AssetMap.Get(self: AssetMap, relativePath: string): AssetEntry?
    assert(t.string(relativePath))
    return (self :: any)._entries[relativePath]
end

function AssetMap.Set(self: AssetMap, relativePath: string, assetId: string, hash: string): ()
    assert(t.string(relativePath))
    assert(t.string(assetId))
    assert(t.string(hash));

    (self :: any)._entries[relativePath] = {
        assetId = assetId,
        hash = hash,
    }
end

function AssetMap.Remove(self: AssetMap, relativePath: string): ()
    assert(t.string(relativePath));
    (self :: any)._entries[relativePath] = nil
end

function AssetMap.GetAll(self: AssetMap): { [string]: AssetEntry }
    return (self :: any)._entries
end

function AssetMap.Save(self: AssetMap): ()
    local cacheDir = (self :: any)._cacheDir
    if not fs.isDir(cacheDir) then
        fs.writeDir(cacheDir)
    end
    fs.writeFile((self :: any)._cachePath, serde.encode("json", (self :: any)._entries) .. "\n")
end

function AssetMap.WriteLuauModule(self: AssetMap, outputPath: string): ()
    assert(t.string(outputPath))

    local entries = (self :: any)._entries :: { [string]: AssetEntry }

    -- Sort keys for deterministic output
    local keys = {}
    for key in entries do
        table.insert(keys, key)
    end
    table.sort(keys)

    local lines = { "return {" }
    for _, key in keys do
        local entry = entries[key]
        table.insert(lines, `\t["{key}"] = "rbxassetid://{entry.assetId}",`)
    end
    table.insert(lines, "}\n")

    fs.writeFile(outputPath, table.concat(lines, "\n"))
end

return AssetMap
