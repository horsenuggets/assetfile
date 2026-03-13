--[[

Sync

Core sync engine that compares local asset files against the cached
asset map, uploads new or changed assets, and removes stale entries.

--]]

local fs = require("@lune/fs")
local task = require("@lune/task")

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

    local assetsDir = mapping.assets
    local outputPath = mapping.output

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
        relativePath: string,
        fullPath: string,
        hash: string,
        isUpdate: boolean,
    }

    local jobs: { UploadJob } = {}
    for _, relativePath in currentFiles do
        local fullPath = `{assetsDir}/{relativePath}`
        local hash = FileUtils.hashFile(fullPath)
        local existing = assetMap:Get(relativePath)

        if existing and existing.hash == hash then
            continue
        end

        table.insert(jobs, {
            relativePath = relativePath,
            fullPath = fullPath,
            hash = hash,
            isUpdate = existing ~= nil,
        })
    end

    -- Upload all changed files in parallel, collecting results per-job
    type JobResult = {
        ok: boolean,
        relativePath: string,
        hash: string,
        isUpdate: boolean,
        assetId: string?,
        errorMessage: string?,
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
                local displayName = job.relativePath:match("([^/]+)%..+$") or job.relativePath
                local fileContent = fs.readFile(job.fullPath)
                local assetType = RobloxApi.getAssetType(job.relativePath)
                assert(assetType, `Could not determine asset type for "{job.relativePath}".`)

                local ok, uploadResult = pcall(function()
                    return api:Upload({
                        AssetType = assetType,
                        DisplayName = displayName,
                        Description = "Uploaded by Assetfile.",
                        Creator = mapping.creator,
                        FileContent = fileContent,
                        Filename = job.relativePath,
                    })
                end)

                if ok then
                    jobResults[i] = {
                        ok = true,
                        relativePath = job.relativePath,
                        hash = job.hash,
                        isUpdate = job.isUpdate,
                        assetId = uploadResult.AssetId,
                    }
                else
                    jobResults[i] = {
                        ok = false,
                        relativePath = job.relativePath,
                        hash = job.hash,
                        isUpdate = job.isUpdate,
                        errorMessage = tostring(uploadResult),
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
            assetMap:Set(jobResult.relativePath, jobResult.assetId :: string, jobResult.hash)
            if jobResult.isUpdate then
                result.Updated += 1
                print(`{Chalk.blue("Updated")} "{jobResult.relativePath}" (asset {jobResult.assetId})`)
            else
                result.Uploaded += 1
                print(`{Chalk.green("Uploaded")} "{jobResult.relativePath}" (asset {jobResult.assetId})`)
            end
        else
            result.Failed += 1
            local errorMsg = `Failed to sync "{jobResult.relativePath}": {jobResult.errorMessage}`
            table.insert(result.Errors, errorMsg)
            print(`{Chalk.red("Failed")} "{jobResult.relativePath}": {jobResult.errorMessage}`)
        end
    end

    -- Save the cache and generate the output module
    assetMap:Save()
    assetMap:WriteLuauModule(outputPath)

    return result
end

return Sync
