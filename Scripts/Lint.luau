#!/usr/bin/env -S lune run

--[[

Lint

Runs luau-lsp analyze to report type errors and deprecation warnings.

[Usage] ./Scripts/Lint.luau

--]]

local Lint = require("../Submodules/luau-cicd/Scripts/Helpers/Lint")

Lint.run()
