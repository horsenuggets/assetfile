--[[

ConfigTest.spec

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
                local path = writeConfig(dir, { Mappings = {} })
                expect(Config.exists(path)).to.equal(true)
            end)
        end)

        describe("load", function()
            it("should load a valid config with UserId creator", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    Mappings = {
                        {
                            Assets = "assets",
                            Output = "Assets.luau",
                            Creator = { UserId = "12345" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(#config.Mappings).to.equal(1)
                expect(config.Mappings[1].Assets).to.equal("assets")
                expect(config.Mappings[1].Output).to.equal("Assets.luau")
                expect(config.Mappings[1].Creator.UserId).to.equal("12345")
            end)

            it("should load a valid config with GroupId creator", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    Mappings = {
                        {
                            Assets = "assets",
                            Output = "Assets.luau",
                            Creator = { GroupId = "67890" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(config.Mappings[1].Creator.GroupId).to.equal("67890")
            end)

            it("should load a config with optional ApiKeyEnvName", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    Mappings = {
                        {
                            ApiKeyEnvName = "MY_CUSTOM_KEY",
                            Assets = "assets",
                            Output = "Assets.luau",
                            Creator = { UserId = "12345" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(config.Mappings[1].ApiKeyEnvName).to.equal("MY_CUSTOM_KEY")
            end)

            it("should support multiple mappings", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    Mappings = {
                        {
                            Assets = "images",
                            Output = "Images.luau",
                            Creator = { UserId = "12345" },
                        },
                        {
                            Assets = "sounds",
                            Output = "Sounds.luau",
                            Creator = { GroupId = "67890" },
                        },
                    },
                })

                local config = Config.load(path)
                expect(#config.Mappings).to.equal(2)
            end)

            it("should error when config file does not exist", function()
                local dir = createTempDir(BASE_NAME)
                expect(function()
                    Config.load(`{dir}/nonexistent.json`)
                end).to.throw()
            end)

            it("should error when creator has both UserId and GroupId", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    Mappings = {
                        {
                            Assets = "assets",
                            Output = "Assets.luau",
                            Creator = { UserId = "12345", GroupId = "67890" },
                        },
                    },
                })

                expect(function()
                    Config.load(path)
                end).to.throw()
            end)

            it("should error when creator has neither UserId nor GroupId", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {
                    Mappings = {
                        {
                            Assets = "assets",
                            Output = "Assets.luau",
                            Creator = {},
                        },
                    },
                })

                expect(function()
                    Config.load(path)
                end).to.throw()
            end)

            it("should error when Mappings is missing", function()
                local dir = createTempDir(BASE_NAME)
                local path = writeConfig(dir, {})

                expect(function()
                    Config.load(path)
                end).to.throw()
            end)
        end)
    end)
end
