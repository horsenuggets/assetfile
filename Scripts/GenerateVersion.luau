#!/usr/bin/env -S lune run

--[[

GenerateVersion

Reads the VERSION file and generates a __VERSION__.luau module that returns
the version string. This is used to embed the version at build time since
compiled executables cannot read files.

--]]

local Chalk = require("@packages/Chalk")
local fs = require("@lune/fs")
local process = require("@lune/process")

local PROJECT_ROOT = tostring(script.Parent.Parent)
local VERSION_FILE = `{PROJECT_ROOT}/VERSION`
local VERSION_MODULE = `{PROJECT_ROOT}/Source/AssetfileCli/AssetfileCommand/__VERSION__.luau`

local function generateVersion()
    if not fs.isFile(VERSION_FILE) then
        print("VERSION file not found.")
        process.exit(1)
    end

    local version = fs.readFile(VERSION_FILE):gsub("%s+", "")

    local versionModule = `return "{version}"\n`
    fs.writeFile(VERSION_MODULE, versionModule)

    print(`Generated version module with version {Chalk.bold(Chalk.blueBright(version))}.`)
end

generateVersion()
