#!/usr/bin/env -S lune run

--[[

GenerateVersion.exec

Reads the VERSION file and generates a __VERSION__.luau module that returns
the version string. This is used to embed the version at build time since
compiled executables cannot read files.

--]]

const Chalk = require("@packages/Chalk")
const fs = require("@lune/fs")
const process = require("@lune/process")

const PROJECT_ROOT = tostring(script.Parent.Parent)
const VERSION_FILE = `{PROJECT_ROOT}/VERSION`
const VERSION_MODULE = `{PROJECT_ROOT}/Source/AssetfileCli/AssetfileCommand/__VERSION__.luau`

const GenerateVersion = {}

function GenerateVersion.exec()
    if not fs.isFile(VERSION_FILE) then
        print("VERSION file not found.")
        process.exit(1)
    end

    const version = fs.readFile(VERSION_FILE):gsub("%s+", "")

    const versionModule = `return "{version}"\n`
    fs.writeFile(VERSION_MODULE, versionModule)

    print(`Generated version module with version {Chalk.bold(Chalk.blueBright(version))}.`)
end

GenerateVersion.exec()
