--[[

Sync

Core sync engine that compares local asset files against the cached
asset map, uploads new or changed assets, and removes stale entries.

--]]

local fs = require("@lune/fs")

local Chalk = require("@packages/Chalk")
local t = require("@packages/t")

local AssetMap = require("@assetfile/AssetMap")
local Config = require("@assetfile/Config")
local FileUtils = require("@assetfile/FileUtils")
local RobloxApi = require("@assetfile/RobloxApi")

local MAX_CONCURRENT_UPLOADS = 5

export type SyncResult = {
    Uploaded: number,
    Updated: number,
    Removed: number,
    Failed: number,
    Errors: { string },
}

local Sync = {}

function Sync.run(mapping: Config.AssetMapping, apiKey: string): SyncResult
    assert(t.string(apiKey))

    local assetsDir = mapping.Assets
    local outputPath = mapping.Output

    assert(fs.isDir(assetsDir), `Assets directory "{assetsDir}" does not exist.`)

    local api = RobloxApi.new(apiKey)
    local assetMap = AssetMap.new(assetsDir)

    local result: SyncResult = {
        Uploaded = 0,
        Updated = 0,
        Removed = 0,
        Failed = 0,
        Errors = {},
    }

    -- Scan the directory for all supported asset files
    local currentFiles = FileUtils.scanDirectory(assetsDir)
    local currentFileSet: { [string]: boolean } = {}
    for _, relativePath in currentFiles do
        currentFileSet[relativePath] = true
    end

    -- Remove stale entries (files that no longer exist)
    local existingEntries = assetMap:GetAll()
    for relativePath in existingEntries do
        if not currentFileSet[relativePath] then
            assetMap:Remove(relativePath)
            result.Removed += 1
            print(`{Chalk.yellow("Removed")} "{relativePath}"`)
        end
    end

    -- Collect files that need uploading
    type UploadJob = {
        RelativePath: string,
        FullPath: string,
        Hash: string,
        IsUpdate: boolean,
    }

    local jobs: { UploadJob } = {}
    for _, relativePath in currentFiles do
        local fullPath = `{assetsDir}/{relativePath}`
        local hash = FileUtils.hashFile(fullPath)
        local existing = assetMap:Get(relativePath)

        if existing and existing.Hash == hash then
            continue
        end

        table.insert(jobs, {
            RelativePath = relativePath,
            FullPath = fullPath,
            Hash = hash,
            IsUpdate = existing ~= nil,
        })
    end

    -- Upload all changed files in parallel, collecting results per-job
    type JobResult = {
        ok: boolean,
        RelativePath: string,
        Hash: string,
        IsUpdate: boolean,
        AssetId: string?,
        ErrorMessage: string?,
    }

    local jobResults: { JobResult? } = table.create(#jobs)
    local remaining = #jobs

    if remaining > 0 then
        local done = false
        local activeCount = 0

        for i, job in jobs do
            -- Wait until a slot is available
            while activeCount >= MAX_CONCURRENT_UPLOADS do
                task.wait(0.05)
            end

            activeCount += 1
            task.spawn(function()
                local displayName = job.RelativePath:match("([^/]+)%..+$") or job.RelativePath
                local fileContent = fs.readFile(job.FullPath)
                local assetType = RobloxApi.getAssetType(job.RelativePath)
                assert(assetType, `Could not determine asset type for "{job.RelativePath}".`)

                local ok, uploadResult = pcall(function()
                    return api:Upload({
                        AssetType = assetType,
                        DisplayName = displayName,
                        Description = "Uploaded by Assetfile.",
                        Creator = mapping.Creator,
                        FileContent = fileContent,
                        Filename = job.RelativePath,
                    })
                end)

                if ok then
                    jobResults[i] = {
                        ok = true,
                        RelativePath = job.RelativePath,
                        Hash = job.Hash,
                        IsUpdate = job.IsUpdate,
                        AssetId = uploadResult.AssetId,
                    }
                else
                    jobResults[i] = {
                        ok = false,
                        RelativePath = job.RelativePath,
                        Hash = job.Hash,
                        IsUpdate = job.IsUpdate,
                        ErrorMessage = tostring(uploadResult),
                    }
                end

                activeCount -= 1
                remaining -= 1
                if remaining == 0 then
                    done = true
                end
            end)
        end

        while not done do
            task.wait(0.05)
        end
    end

    -- Process results on the main thread
    for _, jobResult in jobResults do
        if jobResult.ok then
            assetMap:Set(jobResult.RelativePath, jobResult.AssetId :: string, jobResult.Hash)
            if jobResult.IsUpdate then
                result.Updated += 1
                print(`{Chalk.blue("Updated")} "{jobResult.RelativePath}" (asset {jobResult.AssetId})`)
            else
                result.Uploaded += 1
                print(`{Chalk.green("Uploaded")} "{jobResult.RelativePath}" (asset {jobResult.AssetId})`)
            end
        else
            result.Failed += 1
            local errorMsg = `Failed to sync "{jobResult.RelativePath}": {jobResult.ErrorMessage}`
            table.insert(result.Errors, errorMsg)
            print(`{Chalk.red("Failed")} "{jobResult.RelativePath}": {jobResult.ErrorMessage}`)
        end
    end

    -- Save the cache and generate the output module
    assetMap:Save()
    assetMap:WriteLuauModule(outputPath)

    return result
end

return Sync
