#!/usr/bin/env -S lune run

--[[

GenerateVersion.exec

Reads the VERSION file and generates a __VERSION__.luau module that returns
the version string. This is used to embed the version at build time since
compiled executables cannot read files.

[Usage] ./Scripts/GenerateVersion.exec.luau

--]]

const Commandline = require("@packages/Commandline")

const PROJECT_ROOT = tostring(script.Parent.Parent)
const VERSION_FILE = `{PROJECT_ROOT}/VERSION`
const VERSION_MODULE = `{PROJECT_ROOT}/Source/AssetfileCli/AssetfileCommand/__VERSION__.luau`

const GenerateVersion = {}

function GenerateVersion.exec()
    Commandline.Toolkit.generateVersion({
        OutputPath = VERSION_MODULE,
        VersionFile = VERSION_FILE,
    })
end

GenerateVersion.exec()
