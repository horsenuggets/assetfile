--[[

CliTest

Integration tests for the built assetfile CLI binary. Builds the
binary once, then runs it with various arguments to verify correct
behavior.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local createTempDir = require("./Helpers/createTempDir")
local removeDirectory = require("./Helpers/removeDirectory")

local BASE_NAME = "cli"
local BINARY_PATH = `{process.cwd}Build/assetfile`

return function()
    beforeAll(function()
        local result = process.exec(`{process.cwd}Scripts/BuildExecutable.luau`)
        assert(result.ok, `Failed to build CLI binary: {result.stderr}`)
        assert(fs.isFile(BINARY_PATH), "Failed to build CLI binary.")
    end)

    afterAll(function()
        removeDirectory(`.test-{BASE_NAME}`)
    end)

    describe("CLI", function()
        describe("init", function()
            it("should error when no input is provided", function()
                local dir = createTempDir(BASE_NAME)
                local result = process.exec(BINARY_PATH, { "init" }, {
                    cwd = dir,
                })
                -- init requires interactive stdio prompts, so it should
                -- fail in non-interactive mode
                expect(result.ok).to.equal(false)
            end)

            it("should create config with all flags", function()
                local dir = createTempDir(BASE_NAME)
                local result = process.exec(BINARY_PATH, {
                    "init",
                    "--user-id",
                    "12345",
                    "--assets",
                    "images",
                    "--output",
                    "Images.luau",
                    "--api-key-env",
                    "MY_KEY",
                }, {
                    cwd = dir,
                })
                expect(result.ok).to.equal(true)

                local config = serde.decode("json", fs.readFile(`{dir}/assetfile.json`))
                expect(config.mappings[1].assets).to.equal("images")
                expect(config.mappings[1].output).to.equal("Images.luau")
                expect(config.mappings[1].creator.userId).to.equal("12345")
                expect(config.mappings[1].apiKeyEnvName).to.equal("MY_KEY")
            end)

            it("should create config with group-id flag", function()
                local dir = createTempDir(BASE_NAME)
                local result = process.exec(BINARY_PATH, {
                    "init",
                    "--group-id",
                    "67890",
                    "--assets",
                    "sounds",
                    "--output",
                    "Sounds.luau",
                }, {
                    cwd = dir,
                })
                expect(result.ok).to.equal(true)

                local config = serde.decode("json", fs.readFile(`{dir}/assetfile.json`))
                expect(config.mappings[1].creator.groupId).to.equal("67890")
                expect(config.mappings[1].apiKeyEnvName).to.equal(nil)
            end)

            it("should omit apiKeyEnvName when set to ROBLOX_API_KEY", function()
                local dir = createTempDir(BASE_NAME)
                local result = process.exec(BINARY_PATH, {
                    "init",
                    "--user-id",
                    "12345",
                    "--api-key-env",
                    "ROBLOX_API_KEY",
                }, {
                    cwd = dir,
                })
                expect(result.ok).to.equal(true)

                local config = serde.decode("json", fs.readFile(`{dir}/assetfile.json`))
                expect(config.mappings[1].apiKeyEnvName).to.equal(nil)
            end)

            it("should use default values for assets and output", function()
                local dir = createTempDir(BASE_NAME)
                local result = process.exec(BINARY_PATH, {
                    "init",
                    "--user-id",
                    "12345",
                }, {
                    cwd = dir,
                })
                expect(result.ok).to.equal(true)

                local config = serde.decode("json", fs.readFile(`{dir}/assetfile.json`))
                expect(config.mappings[1].assets).to.equal("Assets")
                expect(config.mappings[1].output).to.equal("Assets.luau")
            end)

            it("should detect existing config", function()
                local dir = createTempDir(BASE_NAME)
                fs.writeFile(
                    `{dir}/assetfile.json`,
                    serde.encode("json", {
                        mappings = {},
                    })
                )

                local result = process.exec(BINARY_PATH, { "init" }, {
                    cwd = dir,
                })
                expect(result.ok).to.equal(true)
                expect(result.stdout:find("already exists")).to.be.ok()
            end)
        end)

        describe("sync", function()
            it("should error when no config exists", function()
                local dir = createTempDir(BASE_NAME)
                local result = process.exec(BINARY_PATH, { "sync" }, {
                    cwd = dir,
                })
                expect(result.ok).to.equal(false)
                expect(result.stderr:find("assetfile.json")).to.be.ok()
            end)
        end)

        describe("unknown command", function()
            it("should show an error message for unknown commands", function()
                local result = process.exec(BINARY_PATH, { "nonexistent" })
                expect(result.stdout:find("Unknown subcommand")).to.be.ok()
            end)
        end)

        describe("no arguments", function()
            it("should show help when no command is provided", function()
                local result = process.exec(BINARY_PATH, {})
                expect(result.ok).to.equal(true)
                expect(result.stdout:find("assetfile")).to.be.ok()
            end)
        end)
    end)
end
