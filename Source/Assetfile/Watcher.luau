--[[

Watcher

Watches asset directories for changes by polling at a regular interval.
When changes are detected, triggers a sync to upload modified assets.
Uses file modification times for cheap change detection rather than
hashing file contents on every poll.

--]]

local fs = require("@lune/fs")
local task = require("@lune/task")

local Chalk = require("@packages/Chalk")
local t = require("@packages/t")

local Config = require("@assetfile/Config")
local FileUtils = require("@assetfile/FileUtils")
local Sync = require("@assetfile/Sync")

local DEFAULT_POLL_INTERVAL = 2

type FileSnapshot = { [string]: number }

local Watcher = {}

local function takeSnapshot(assetsDir: string): FileSnapshot
    local snapshot: FileSnapshot = {}
    local files = FileUtils.scanDirectory(assetsDir)
    for _, relativePath in files do
        local fullPath = `{assetsDir}/{relativePath}`
        local metadata = fs.metadata(fullPath)
        snapshot[relativePath] = metadata.modifiedAt.unixTimestampMillis
    end
    return snapshot
end

local function hasChanges(previous: FileSnapshot, current: FileSnapshot): boolean
    for path, mtime in current do
        if not previous[path] or previous[path] ~= mtime then
            return true
        end
    end

    for path in previous do
        if not current[path] then
            return true
        end
    end

    return false
end

function Watcher.watch(mappings: { Config.AssetMapping }, apiKey: string, pollInterval: number?): ()
    assert(t.table(mappings))
    assert(t.string(apiKey))

    local interval = pollInterval or DEFAULT_POLL_INTERVAL

    -- Build initial snapshot of file mtimes for each mapping
    local snapshots: { [number]: FileSnapshot } = {}
    for i, mapping in mappings do
        snapshots[i] = takeSnapshot(mapping.assets)
    end

    -- Run initial sync
    print(Chalk.bold("Running initial sync..."))
    for _, mapping in mappings do
        Sync.run(mapping, apiKey)
    end

    print(
        `\n{Chalk.bold(
            `Watching for changes (polling every {interval} {if interval == 1 then "second" else "seconds"})...`
        )}\n`
    )

    -- Poll for changes using modification times
    while task.wait(interval) do
        for i, mapping in mappings do
            local currentSnapshot = takeSnapshot(mapping.assets)

            if hasChanges(snapshots[i], currentSnapshot) then
                print(Chalk.dim(`Changes detected in "{mapping.assets}", syncing...`))
                Sync.run(mapping, apiKey)
                snapshots[i] = currentSnapshot
            end
        end
    end
end

return Watcher
