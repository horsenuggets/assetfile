--[[

Sync

Core sync engine that compares local asset files against the cached
asset map, uploads new or changed assets, and removes stale entries.

--]]

const fs = require("@lune/fs")

const Chalk = require("@packages/Chalk")
const t = require("@packages/t")

const AssetMap = require("@assetfile/AssetMap")
const Config = require("@assetfile/Config")
const FileUtils = require("@assetfile/FileUtils")
const RobloxApi = require("@assetfile/RobloxApi")

const MAX_CONCURRENT_UPLOADS = 5

export type SyncResult = {
    Uploaded: number,
    Updated: number,
    Removed: number,
    Failed: number,
    Errors: { string },
}

const Sync = {}

function Sync.run(mapping: Config.AssetMapping, apiKey: string): SyncResult
    assert(t.string(apiKey))

    const assetsDir = mapping.Assets
    const outputPath = mapping.Output

    assert(fs.isDir(assetsDir), `Assets directory "{assetsDir}" does not exist.`)

    const api = RobloxApi.new(apiKey)
    const assetMap = AssetMap.new(assetsDir)

    const result: SyncResult = {
        Uploaded = 0,
        Updated = 0,
        Removed = 0,
        Failed = 0,
        Errors = {},
    }

    -- Scan the directory for all supported asset files
    const currentFiles = FileUtils.scanDirectory(assetsDir)
    const currentFileSet: { [string]: boolean } = {}
    for _, relativePath in currentFiles do
        currentFileSet[relativePath] = true
    end

    -- Remove stale entries (files that no longer exist)
    const existingEntries = assetMap:GetAll()
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

    const jobs: { UploadJob } = {}
    for _, relativePath in currentFiles do
        const fullPath = `{assetsDir}/{relativePath}`
        const hash = FileUtils.hashFile(fullPath)
        const existing = assetMap:Get(relativePath)

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

    const jobResults: { JobResult? } = table.create(#jobs)
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
                const displayName = job.RelativePath:match("([^/]+)%..+$") or job.RelativePath
                const fileContent = fs.readFile(job.FullPath)
                const assetType = RobloxApi.getAssetType(job.RelativePath)
                assert(assetType, `Could not determine asset type for "{job.RelativePath}".`)

                const ok, uploadResult = pcall(function()
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
            const errorMsg = `Failed to sync "{jobResult.RelativePath}": {jobResult.ErrorMessage}`
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
