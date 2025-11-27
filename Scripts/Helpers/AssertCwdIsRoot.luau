local fs = require("@lune/fs")
local process = require("@lune/process")

return function()
    if not fs.isDir("./.git/") then
        print("Ensure that this script is running from the root of the repository.")
        process.exit(1)
    end
end
