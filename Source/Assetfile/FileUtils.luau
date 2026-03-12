--[[

FileUtils

Utilities for scanning asset directories, computing file hashes, and
detecting changes between syncs.

--]]

local fs = require("@lune/fs")

local HashLib = require("@packages/HashLib")
local t = require("@packages/t")

local RobloxApi = require("@assetfile/RobloxApi")

local FileUtils = {}

function FileUtils.hashFile(filePath: string): string
    assert(t.string(filePath))

    local content = fs.readFile(filePath)
    return HashLib.sha256(content)
end

function FileUtils.isSupportedAsset(filename: string): boolean
    return RobloxApi.getAssetType(filename) ~= nil
end

function FileUtils.scanDirectory(directory: string): { string }
    assert(t.string(directory))
    assert(fs.isDir(directory), `Directory "{directory}" does not exist.`)

    local results = {}

    local function scan(dir: string, prefix: string)
        for _, name in fs.readDir(dir) do
            local fullPath = `{dir}/{name}`
            local relativePath = if prefix == "" then name else `{prefix}/{name}`

            if fs.isDir(fullPath) then
                scan(fullPath, relativePath)
            elseif FileUtils.isSupportedAsset(name) then
                table.insert(results, relativePath)
            end
        end
    end

    scan(directory, "")
    table.sort(results)
    return results
end

return FileUtils
