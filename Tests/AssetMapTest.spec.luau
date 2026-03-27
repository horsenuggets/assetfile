--[[

AssetMapTest

Tests for the AssetMap module that manages file-to-asset-ID mappings.

--]]

local fs = require("@lune/fs")

local AssetMap = require("@assetfile/AssetMap")

local createTempDir = require("./Helpers/createTempDir")
local removeDirectory = require("./Helpers/removeDirectory")

local BASE_NAME = "assetmap"

return function()
    afterAll(function()
        removeDirectory(`.test-{BASE_NAME}`)
    end)

    describe("AssetMap", function()
        describe("new", function()
            it("should create a new empty asset map", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                local entries = map:GetAll()
                local count = 0
                for _ in entries do
                    count += 1
                end
                expect(count).to.equal(0)
            end)

            it("should load existing cache file", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("test.png", "12345", "abc123")
                map:Save()

                local map2 = AssetMap.new(dir)
                local entry = map2:Get("test.png")
                expect(entry).to.be.ok()
                expect(entry.assetId).to.equal("12345")
                expect(entry.hash).to.equal("abc123")
            end)
        end)

        describe("Get and Set", function()
            it("should return nil for non-existent paths", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                expect(map:Get("nonexistent.png")).to.equal(nil)
            end)

            it("should store and retrieve entries", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("image.png", "99999", "hash123")

                local entry = map:Get("image.png")
                expect(entry).to.be.ok()
                expect(entry.assetId).to.equal("99999")
                expect(entry.hash).to.equal("hash123")
            end)

            it("should overwrite existing entries", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("image.png", "11111", "hash1")
                map:Set("image.png", "22222", "hash2")

                local entry = map:Get("image.png")
                expect(entry).to.be.ok()
                expect(entry.assetId).to.equal("22222")
                expect(entry.hash).to.equal("hash2")
            end)
        end)

        describe("Remove", function()
            it("should remove an existing entry", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("image.png", "12345", "hash")
                map:Remove("image.png")
                expect(map:Get("image.png")).to.equal(nil)
            end)

            it("should not error when removing non-existent entry", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                expect(function()
                    map:Remove("nonexistent.png")
                end).to.never.throw()
            end)
        end)

        describe("Save", function()
            it("should persist entries to disk", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("a.png", "111", "aaa")
                map:Set("b.png", "222", "bbb")
                map:Save()

                expect(fs.isFile(`{dir}/.assetfile-cache.json`)).to.equal(true)
            end)
        end)

        describe("WriteLuauModule", function()
            it("should generate a valid Luau module", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("image.png", "12345", "hash1")
                map:Set("sounds/boom.mp3", "67890", "hash2")

                local outputPath = `{dir}/TestAssets.luau`
                map:WriteLuauModule(outputPath)

                expect(fs.isFile(outputPath)).to.equal(true)

                local content = fs.readFile(outputPath)
                expect(content:find("return {")).to.be.ok()
                expect(content:find('"image.png"')).to.be.ok()
                expect(content:find("rbxassetid://12345")).to.be.ok()
                expect(content:find('"sounds/boom.mp3"')).to.be.ok()
                expect(content:find("rbxassetid://67890")).to.be.ok()
            end)

            it("should include a file header derived from the output path", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("icon.png", "11111", "hash")

                local outputPath = `{dir}/Assets.luau`
                map:WriteLuauModule(outputPath)

                local content = fs.readFile(outputPath)
                expect(content:find("--[[", 1, true)).to.be.ok()
                expect(content:find("Assets")).to.be.ok()
                expect(content:find("Auto-generated by Assetfile.", 1, true)).to.be.ok()
                expect(content:find("--]]", 1, true)).to.be.ok()
            end)

            it("should derive header name from the file name", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("icon.png", "11111", "hash")

                local outputPath = `{dir}/MyCustomAssets.luau`
                map:WriteLuauModule(outputPath)

                local content = fs.readFile(outputPath)
                expect(content:find("MyCustomAssets")).to.be.ok()
            end)

            it("should sort keys alphabetically", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                map:Set("zebra.png", "333", "z")
                map:Set("alpha.png", "111", "a")
                map:Set("middle.png", "222", "m")

                local outputPath = `{dir}/Sorted.luau`
                map:WriteLuauModule(outputPath)

                local content = fs.readFile(outputPath)
                local alphaPos = content:find("alpha.png") :: number
                local middlePos = content:find("middle.png") :: number
                local zebraPos = content:find("zebra.png") :: number
                expect(alphaPos < middlePos).to.equal(true)
                expect(middlePos < zebraPos).to.equal(true)
            end)

            it("should produce empty table for no entries", function()
                local dir = createTempDir(BASE_NAME)
                local map = AssetMap.new(dir)
                local outputPath = `{dir}/Empty.luau`
                map:WriteLuauModule(outputPath)

                local content = fs.readFile(outputPath)
                expect(content:find("return {")).to.be.ok()
                expect(content:find("}")).to.be.ok()
            end)
        end)
    end)
end
