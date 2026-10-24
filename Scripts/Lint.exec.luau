#!/usr/bin/env -S lune run

--[[

Lint.exec

Runs luau-lsp analyze to report type errors and deprecation warnings.

[Usage] ./Scripts/Lint.exec.luau

--]]

const Lint = {}

function Lint.exec()
    require("@submodules/luau-cicd/Scripts/Helpers/Lint").run()
end

Lint.exec()
