--[[

removeDirectory

Recursively removes a directory and all its contents.

--]]

local process = require("@lune/process")

local function removeDirectory(path: string)
    process.exec("rm", { "-rf", path })
end

return removeDirectory
