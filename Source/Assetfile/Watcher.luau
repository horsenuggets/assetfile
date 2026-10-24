--[[

Watcher

Watches asset directories for changes by polling at a regular interval.
When changes are detected, triggers a sync to upload modified assets.
Uses file modification times for cheap change detection rather than
hashing file contents on every poll.

--]]

const fs = require("@lune/fs")

const Chalk = require("@packages/Chalk")
const t = require("@packages/t")

const Config = require("@assetfile/Config")
const FileUtils = require("@assetfile/FileUtils")
const Sync = require("@assetfile/Sync")

const DEFAULT_POLL_INTERVAL = 2

type FileSnapshot = { [string]: number }

const Watcher = {}

const function takeSnapshot(assetsDir: string): FileSnapshot
    const snapshot: FileSnapshot = {}
    const files = FileUtils.scanDirectory(assetsDir)
    for _, relativePath in files do
        const fullPath = `{assetsDir}/{relativePath}`
        const metadata = fs.metadata(fullPath)
        snapshot[relativePath] = metadata.modifiedAt.unixTimestampMillis
    end
    return snapshot
end

const function hasChanges(previous: FileSnapshot, current: FileSnapshot): boolean
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

function Watcher.watch(mappings: { Config.AssetMapping }, apiKeys: { [number]: string }, pollInterval: number?): ()
    assert(t.table(mappings))
    assert(t.table(apiKeys))

    const interval = pollInterval or DEFAULT_POLL_INTERVAL

    -- Build initial snapshot of file mtimes for each mapping
    const snapshots: { [number]: FileSnapshot } = {}
    for i, mapping in mappings do
        snapshots[i] = takeSnapshot(mapping.Assets)
    end

    -- Run initial sync
    print(Chalk.bold("Running initial sync..."))
    for i, mapping in mappings do
        Sync.run(mapping, apiKeys[i])
    end

    print(
        `\n{Chalk.bold(
            `Watching for changes (polling every {interval} {if interval == 1 then "second" else "seconds"})...`
        )}\n`
    )

    -- Poll for changes using modification times
    while task.wait(interval) do
        for i, mapping in mappings do
            const currentSnapshot = takeSnapshot(mapping.Assets)

            if hasChanges(snapshots[i], currentSnapshot) then
                print(Chalk.dim(`Changes detected in "{mapping.Assets}", syncing...`))
                Sync.run(mapping, apiKeys[i])
                snapshots[i] = currentSnapshot
            end
        end
    end
end

return Watcher
