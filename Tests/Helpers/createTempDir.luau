--[[

createTempDir

Creates a unique temporary directory for test isolation. Each call
returns a new directory path under `.test-{baseName}/`, enabling
parallel test execution without filesystem conflicts.

--]]

const fs = require("@lune/fs")

local counter = 0

const function createTempDir(baseName: string): string
    counter += 1
    const baseDir = `.test-{baseName}`
    const id = `{counter}-{math.random(100000, 999999)}`
    const dir = `{baseDir}/{id}`

    if not fs.isDir(baseDir) then
        pcall(fs.writeDir, baseDir)
    end
    fs.writeDir(dir)

    return dir
end

return createTempDir
