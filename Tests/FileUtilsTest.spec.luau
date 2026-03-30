--[[

FileUtilsTest.spec

Tests for the FileUtils module that handles file scanning and hashing.

--]]

local fs = require("@lune/fs")

local FileUtils = require("@assetfile/FileUtils")

local createTempDir = require("./Helpers/createTempDir")
local removeDirectory = require("./Helpers/removeDirectory")

local BASE_NAME = "fileutils"

local function createTestFile(dir: string, path: string, content: string?)
    -- Create nested directories if needed
    local parts = path:split("/")
    if #parts > 1 then
        local dirPath = dir
        for i = 1, #parts - 1 do
            dirPath = `{dirPath}/{parts[i]}`
            if not fs.isDir(dirPath) then
                fs.writeDir(dirPath)
            end
        end
    end
    fs.writeFile(`{dir}/{path}`, content or "test content")
end

return function()
    afterAll(function()
        removeDirectory(`.test-{BASE_NAME}`)
    end)

    describe("FileUtils", function()
        describe("isSupportedAsset", function()
            it("should return true for png files", function()
                expect(FileUtils.isSupportedAsset("image.png")).to.equal(true)
            end)

            it("should return true for jpg files", function()
                expect(FileUtils.isSupportedAsset("photo.jpg")).to.equal(true)
            end)

            it("should return true for mp3 files", function()
                expect(FileUtils.isSupportedAsset("song.mp3")).to.equal(true)
            end)

            it("should return true for fbx files", function()
                expect(FileUtils.isSupportedAsset("model.fbx")).to.equal(true)
            end)

            it("should return false for txt files", function()
                expect(FileUtils.isSupportedAsset("readme.txt")).to.equal(false)
            end)

            it("should return false for lua files", function()
                expect(FileUtils.isSupportedAsset("script.lua")).to.equal(false)
            end)

            it("should return false for json files", function()
                expect(FileUtils.isSupportedAsset("config.json")).to.equal(false)
            end)
        end)

        describe("hashFile", function()
            it("should return a hash string", function()
                local dir = createTempDir(BASE_NAME)
                createTestFile(dir, "hashtest.png")
                local hash = FileUtils.hashFile(`{dir}/hashtest.png`)
                expect(type(hash)).to.equal("string")
                expect(#hash > 0).to.equal(true)
            end)

            it("should return the same hash for identical content", function()
                local dir = createTempDir(BASE_NAME)
                createTestFile(dir, "file1.png", "identical content")
                createTestFile(dir, "file2.png", "identical content")
                local hash1 = FileUtils.hashFile(`{dir}/file1.png`)
                local hash2 = FileUtils.hashFile(`{dir}/file2.png`)
                expect(hash1).to.equal(hash2)
            end)

            it("should return different hashes for different content", function()
                local dir = createTempDir(BASE_NAME)
                createTestFile(dir, "file1.png", "content A")
                createTestFile(dir, "file2.png", "content B")
                local hash1 = FileUtils.hashFile(`{dir}/file1.png`)
                local hash2 = FileUtils.hashFile(`{dir}/file2.png`)
                expect(hash1).to.never.equal(hash2)
            end)
        end)

        describe("scanDirectory", function()
            it("should find supported asset files", function()
                local dir = createTempDir(BASE_NAME)
                createTestFile(dir, "image.png")
                createTestFile(dir, "photo.jpg")
                createTestFile(dir, "readme.txt")

                local files = FileUtils.scanDirectory(dir)
                expect(#files).to.equal(2)
            end)

            it("should return sorted paths", function()
                local dir = createTempDir(BASE_NAME)
                createTestFile(dir, "zebra.png")
                createTestFile(dir, "alpha.png")
                createTestFile(dir, "middle.png")

                local files = FileUtils.scanDirectory(dir)
                expect(files[1]).to.equal("alpha.png")
                expect(files[2]).to.equal("middle.png")
                expect(files[3]).to.equal("zebra.png")
            end)

            it("should scan subdirectories recursively", function()
                local dir = createTempDir(BASE_NAME)
                createTestFile(dir, "top.png")
                createTestFile(dir, "sub/nested.png")

                local files = FileUtils.scanDirectory(dir)
                expect(#files).to.equal(2)

                local hasTop = false
                local hasNested = false
                for _, file in files do
                    if file == "top.png" then
                        hasTop = true
                    end
                    if file == "sub/nested.png" then
                        hasNested = true
                    end
                end
                expect(hasTop).to.equal(true)
                expect(hasNested).to.equal(true)
            end)

            it("should return empty table for empty directory", function()
                local dir = createTempDir(BASE_NAME)
                local files = FileUtils.scanDirectory(dir)
                expect(#files).to.equal(0)
            end)

            it("should ignore unsupported files", function()
                local dir = createTempDir(BASE_NAME)
                createTestFile(dir, "script.luau", "-- code")
                createTestFile(dir, "config.json", "{}")
                createTestFile(dir, "notes.txt", "hello")

                local files = FileUtils.scanDirectory(dir)
                expect(#files).to.equal(0)
            end)

            it("should error for non-existent directory", function()
                expect(function()
                    FileUtils.scanDirectory(".nonexistent-dir-12345")
                end).to.throw()
            end)
        end)
    end)
end
