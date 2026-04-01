#!/usr/bin/env -S lune run

--[[

BuildExecutable

Compiles the assetfile CLI to a standalone executable. Embeds the VERSION
at build time since compiled executables cannot read files at runtime.

--]]

local Chalk = require("@packages/Chalk")
local Commandline = require("@packages/Commandline")
local fs = require("@lune/fs")
local process = require("@lune/process")

local PROJECT_ROOT = tostring(script.Parent.Parent)
local GENERATE_VERSION_SCRIPT = `{PROJECT_ROOT}/Scripts/GenerateVersion.luau`
local OUTPUT_NAME = "assetfile"

local function buildExecutable()
    local target = process.args[1]

    print()
    print(`Building {Chalk.bold(Chalk.blueBright(OUTPUT_NAME))} executable...`)

    -- Generate version module (run from project root so rokit shim
    -- finds manifest)
    local versionResult = process.exec("lune", { "run", GENERATE_VERSION_SCRIPT }, { cwd = PROJECT_ROOT })
    if not versionResult.ok then
        print(Chalk.red("Failed to generate version module."))
        print(versionResult.stderr)
        process.exit(1)
    end

    Commandline.Toolkit.build({
        Name = OUTPUT_NAME,
        EntryPoint = "Source/AssetfileCli",
        Target = target,
    })

    local outputPath = `{PROJECT_ROOT}/Build/{OUTPUT_NAME}`
    local outputFile = outputPath
    if target and target:find("windows") then
        outputFile = `{outputPath}.exe`
    elseif not target and process.os == "windows" then
        outputFile = `{outputPath}.exe`
    end

    if fs.isFile(outputFile) then
        print(`Output file is {Chalk.dim(outputFile)}.`)
    end

    print()
    print(Chalk.bold(Chalk.greenBright("Build completed successfully!")))
end

buildExecutable()
