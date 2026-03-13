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
        local result = process.exec("lune", {
            "run",
            `{process.cwd}Scripts/BuildCli.luau`,
        })
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
