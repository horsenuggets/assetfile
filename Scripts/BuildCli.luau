#!/usr/bin/env -S lune run

--[[

BuildCli

Compiles the Assetfile CLI to a standalone executable. Accepts an
optional target argument for cross-compilation (e.g., linux-x86_64,
macos-aarch64, windows-x86_64).

[Usage] lune run ./Scripts/BuildCli.luau [target]

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local PROJECT_ROOT = tostring(script.Parent.Parent)
local BUILD_DIR = `{PROJECT_ROOT}/Build`
local ENTRY_POINT = `{PROJECT_ROOT}/Source/Commandline/AssetfileCli.luau`
local OUTPUT_NAME = "assetfile"

local ALIAS_DIRS = {
    { alias = "@assetfile", dir = "Source/Assetfile" },
    { alias = "@packages", dir = "Packages" },
    { alias = "@tests", dir = "Tests" },
}

local function getParentDir(path: string): string
    return path:match("^(.*)/[^/]+$") or ""
end

local function resolveAlias(projectRelPath: string): (string?, string?)
    for _, entry in ALIAS_DIRS do
        local prefix = entry.dir .. "/"
        if projectRelPath:sub(1, #prefix) == prefix then
            local rest = projectRelPath:sub(#prefix + 1)
            return entry.alias, rest
        end
    end
    return nil
end

type FileBackup = { path: string, content: string }

-- Compiled Lune executables on Windows resolve relative paths
-- ("./", "../", "@self/") against the drive root instead of the
-- virtual filesystem. This function rewrites all relative requires
-- to use alias paths which work correctly on all platforms.
local function patchRelativeRequires(): { FileBackup }
    local backups: { FileBackup } = {}
    local patched = 0

    local function processFile(filePath: string, projectRelPath: string)
        local content = fs.readFile(filePath)
        local originalContent = content
        local modified = false
        local fileName = filePath:match("([^/]+)$") or ""
        local fileDir = getParentDir(projectRelPath)

        -- Replace @self requires (used in init.luau files)
        if content:find("@self/", 1, true) then
            local selfDir = fileDir
            content = content:gsub('require%("@self/([^"]+)"', function(target)
                local fullPath = if selfDir == "" then target else `{selfDir}/{target}`
                local alias, rest = resolveAlias(fullPath)
                if alias then
                    modified = true
                    return `require("{alias}/{rest}"`
                end
                return nil
            end)
        end

        -- Replace "./" relative requires
        if content:find('require("./', 1, true) then
            content = content:gsub('require%("(%./[^"]+)"', function(relTarget)
                local target = relTarget:sub(3)
                local fullPath = if fileDir == "" then target else `{fileDir}/{target}`
                local alias, rest = resolveAlias(fullPath)
                if alias then
                    modified = true
                    return `require("{alias}/{rest}"`
                end
                return nil
            end)
        end

        -- Replace "../" relative requires
        if content:find('require("../', 1, true) then
            content = content:gsub('require%("(%.%./[^"]+)"', function(relTarget)
                local target = relTarget:sub(4)
                local parentDir = getParentDir(fileDir)
                local fullPath = if parentDir == "" then target else `{parentDir}/{target}`
                local alias, rest = resolveAlias(fullPath)
                if alias then
                    modified = true
                    return `require("{alias}/{rest}"`
                end
                return nil
            end)
        end

        if modified then
            table.insert(backups, { path = filePath, content = originalContent })
            fs.writeFile(filePath, content)
            patched += 1
        end
    end

    local function processDir(dirPath: string, projectRelPrefix: string)
        for _, entry in fs.readDir(dirPath) do
            local fullPath = `{dirPath}/{entry}`
            local relPath = if projectRelPrefix == "" then entry else `{projectRelPrefix}/{entry}`

            if fs.isDir(fullPath) then
                processDir(fullPath, relPath)
            elseif entry:match("%.luau$") then
                processFile(fullPath, relPath)
            end
        end
    end

    -- Delete sub-package .luaurc files so @packages falls
    -- through to the project root definition
    local function deleteSubLuaurcs(dirPath: string)
        for _, entry in fs.readDir(dirPath) do
            local fullPath = `{dirPath}/{entry}`
            if fs.isDir(fullPath) then
                deleteSubLuaurcs(fullPath)
            elseif entry == ".luaurc" then
                table.insert(backups, {
                    path = fullPath,
                    content = fs.readFile(fullPath),
                })
                fs.removeFile(fullPath)
            end
        end
    end

    local packagesIndexDir = `{PROJECT_ROOT}/Packages/_Index`
    if fs.isDir(packagesIndexDir) then
        deleteSubLuaurcs(packagesIndexDir)
    end

    for _, entry in ALIAS_DIRS do
        local dirPath = `{PROJECT_ROOT}/{entry.dir}`
        if fs.isDir(dirPath) then
            processDir(dirPath, entry.dir)
        end
    end

    if patched > 0 then
        print(
            `Patched {patched}` .. ` {if patched == 1 then "file" else "files"}` .. " for cross-platform compatibility."
        )
    end

    return backups
end

local function restoreFiles(backups: { FileBackup })
    for _, backup in backups do
        fs.writeFile(backup.path, backup.content)
    end
end

local function buildCli()
    local target = process.args[1]

    print()
    print("Building assetfile executable...")

    if not fs.isFile(ENTRY_POINT) then
        print(`Entry point "{ENTRY_POINT}" not found.`)
        process.exit(1)
    end

    local backups = patchRelativeRequires()

    if not fs.isDir(BUILD_DIR) then
        fs.writeDir(BUILD_DIR)
    end

    -- Remove existing binary to avoid corruption
    local outputPath = `{BUILD_DIR}/{OUTPUT_NAME}`
    if fs.isFile(outputPath) then
        fs.removeFile(outputPath)
    end
    if fs.isFile(`{outputPath}.exe`) then
        fs.removeFile(`{outputPath}.exe`)
    end

    -- Strip shebang for building (lune build doesn't support
    -- shebangs). Temp file goes in same directory so relative
    -- requires resolve correctly.
    local entryContent = fs.readFile(ENTRY_POINT)
    local entryDir = ENTRY_POINT:match("(.*/)")
    local tempEntryPoint = `{entryDir}_build_entry.luau`
    local strippedContent = entryContent:gsub("^#![^\n]*\n", "")
    fs.writeFile(tempEntryPoint, strippedContent)

    local args = { "build", tempEntryPoint, "--output", outputPath }

    if target then
        table.insert(args, "--target")
        table.insert(args, target)
        print(`Target is {target}.`)
    else
        print(`Target is {process.os}-{process.arch}.`)
    end

    print(`Entry point is {ENTRY_POINT}.`)

    local result = process.exec("lune", args, { cwd = PROJECT_ROOT })

    -- Clean up temporary entry point and restore patched files
    if fs.isFile(tempEntryPoint) then
        fs.removeFile(tempEntryPoint)
    end
    restoreFiles(backups)

    if result.ok then
        local outputFile = outputPath
        if target and target:find("windows") then
            outputFile = `{outputPath}.exe`
        elseif not target and process.os == "windows" then
            outputFile = `{outputPath}.exe`
        end

        if fs.isFile(outputFile) then
            print(`Output file is {outputFile}.`)
        end

        print()
        print("Build completed successfully!")
    else
        print("Build failed.")
        print(result.stderr)
        process.exit(1)
    end
end

buildCli()
