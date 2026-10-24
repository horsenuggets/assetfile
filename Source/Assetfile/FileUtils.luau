--[[

FileUtils

Utilities for scanning asset directories, computing file hashes, and
detecting changes between syncs.

--]]

const fs = require("@lune/fs")

const HashLib = require("@packages/HashLib")
const t = require("@packages/t")

const RobloxApi = require("@assetfile/RobloxApi")

const FileUtils = {}

function FileUtils.hashFile(filePath: string): string
    assert(t.string(filePath))

    const content = fs.readFile(filePath)
    return HashLib.sha256(content)
end

function FileUtils.isSupportedAsset(filename: string): boolean
    return RobloxApi.getAssetType(filename) ~= nil
end

function FileUtils.scanDirectory(directory: string): { string }
    assert(t.string(directory))
    assert(fs.isDir(directory), `Directory "{directory}" does not exist.`)

    const results = {}

    const function scan(dir: string, prefix: string)
        for _, name in fs.readDir(dir) do
            const fullPath = `{dir}/{name}`
            const relativePath = if prefix == "" then name else `{prefix}/{name}`

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
