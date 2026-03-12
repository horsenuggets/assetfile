--[[

createTempDir

Creates a unique temporary directory for test isolation. Each call
returns a new directory path under `.test-{baseName}/`, enabling
parallel test execution without filesystem conflicts.

--]]

local fs = require("@lune/fs")

local counter = 0

local function createTempDir(baseName: string): string
    counter += 1
    local baseDir = `.test-{baseName}`
    local id = `{counter}-{math.random(100000, 999999)}`
    local dir = `{baseDir}/{id}`

    if not fs.isDir(baseDir) then
        pcall(fs.writeDir, baseDir)
    end
    fs.writeDir(dir)

    return dir
end

return createTempDir
