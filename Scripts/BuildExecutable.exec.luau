#!/usr/bin/env -S lune run

--[[

BuildExecutable.exec

Compiles the assetfile CLI to a standalone executable. Embeds the VERSION
at build time since compiled executables cannot read files at runtime.

--]]

const Chalk = require("@packages/Chalk")
const Commandline = require("@packages/Commandline")
const fs = require("@lune/fs")
const process = require("@lune/process")

const PROJECT_ROOT = tostring(script.Parent.Parent)
const GENERATE_VERSION_SCRIPT = `{PROJECT_ROOT}/Scripts/GenerateVersion.exec.luau`
const OUTPUT_NAME = "assetfile"

const BuildExecutable = {}

function BuildExecutable.exec()
    const target = process.args[1]

    print()
    print(`Building {Chalk.bold(Chalk.blueBright(OUTPUT_NAME))} executable...`)

    -- Generate version module (run from project root so rokit shim
    -- finds manifest)
    const versionResult = process.exec("lune", { "run", GENERATE_VERSION_SCRIPT }, { cwd = PROJECT_ROOT })
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

    const outputPath = `{PROJECT_ROOT}/Build/{OUTPUT_NAME}`
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

BuildExecutable.exec()
