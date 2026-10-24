--[[

removeDirectory

Recursively removes a directory and all its contents.

--]]

const process = require("@lune/process")

const function removeDirectory(path: string)
    process.exec("rm", { "-rf", path })
end

return removeDirectory
