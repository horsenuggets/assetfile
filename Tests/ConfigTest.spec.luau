--[[

ConfigTest

Tests for the Config module that loads and validates assetfile.json.

--]]

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Config = require("@assetfile/Config")

local createTempDir = require("./Helpers/createTempDir")
local removeDirectory = require("./Helpers/removeDirectory")

local BASE_NAME = "config"

local function writeConfig(dir: string, data: any): string
    local path = `{dir}/assetfile.json`
    fs.writeFile(path, serde.encode("json", data))
    return path
end

return function()
    afterAll(function()
        removeDirectory(`.test-{BASE_NAME}`)
    end)

    describe("Config", function()
        describe("exists", function()
            it("should return false when config does not exist", function()
                local dir = createTempDir(BASE_NAME)
                expect(Config.exists(`{dir}/assetfile.json`)).to.equal(false)
            end)

            it("should return true when config exists", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, { mappings = {} })
                expect(Config.exists(path)).to.equal(true)
            end)
        end)

        describe("load", function()
            it("should load a valid config with userId creator", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    mappings = {
                        {
                            assets = "assets",
                            output = "Assets.luau",
                            creator = { userId = "12345" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(#config.mappings).to.equal(1)
                expect(config.mappings[1].assets).to.equal("assets")
                expect(config.mappings[1].output).to.equal("Assets.luau")
                expect(config.mappings[1].creator.userId).to.equal("12345")
            end)

            it("should load a valid config with groupId creator", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    mappings = {
                        {
                            assets = "assets",
                            output = "Assets.luau",
                            creator = { groupId = "67890" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(config.mappings[1].creator.groupId).to.equal("67890")
            end)

            it("should load a config with optional apiKey", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    apiKey = "test-key-123",
                    mappings = {
                        {
                            assets = "assets",
                            output = "Assets.luau",
                            creator = { userId = "12345" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(config.apiKey).to.equal("test-key-123")
            end)

            it("should support multiple mappings", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    mappings = {
                        {
                            assets = "images",
                            output = "Images.luau",
                            creator = { userId = "12345" },
                        },
                        {
                            assets = "sounds",
                            output = "Sounds.luau",
                            creator = { groupId = "67890" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(#config.mappings).to.equal(2)
            end)

            it("should error when config file does not exist", function()
                local dir = createTempDir(BASE_NAME)
                expect(function()
                    Config.load(`{dir}/nonexistent.json`)
                end).to.throw()
            end)

            it("should error when creator has both userId and groupId", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    mappings = {
                        {
                            assets = "assets",
                            output = "Assets.luau",
                            creator = { userId = "12345", groupId = "67890" },
                        },
                    },
                })

                expect(function()
                    Config.load(path)
                end).to.throw()
            end)

            it("should error when creator has neither userId nor groupId", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    mappings = {
                        {
                            assets = "assets",
                            output = "Assets.luau",
                            creator = {},
                        },
                    },
                })

                expect(function()
                    Config.load(path)
                end).to.throw()
            end)

            it("should error when mappings is missing", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {})

                expect(function()
                    Config.load(path)
                end).to.throw()
            end)
        end)
    end)
end
