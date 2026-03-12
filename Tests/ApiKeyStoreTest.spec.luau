--[[

ApiKeyStoreTest

Tests for the ApiKeyStore module that manages stored Roblox API keys.
Each test creates an isolated ApiKeyStore instance with its own
temporary directory.

--]]

local ApiKeyStore = require("@assetfile/ApiKeyStore")

local createTempDir = require("./Helpers/createTempDir")
local removeDirectory = require("./Helpers/removeDirectory")

local BASE_NAME = "apikeystore"

return function()
    afterAll(function()
        removeDirectory(`.test-{BASE_NAME}`)
    end)

    describe("ApiKeyStore", function()
        describe("Add and List", function()
            it("should start with no keys", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                local keys = store:List()
                expect(#keys).to.equal(0)
            end)

            it("should add a key", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("test", "my-api-key-123")
                local keys = store:List()
                expect(#keys).to.equal(1)
                expect(keys[1].name).to.equal("test")
                expect(keys[1].key).to.equal("my-api-key-123")
            end)

            it("should add multiple keys", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("key1", "value1")
                store:Add("key2", "value2")
                local keys = store:List()
                expect(#keys).to.equal(2)
            end)

            it("should error on duplicate names", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("dup", "value1")
                expect(function()
                    store:Add("dup", "value2")
                end).to.throw()
            end)

            it("should error on empty name", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                expect(function()
                    store:Add("", "value")
                end).to.throw()
            end)

            it("should error on empty key", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                expect(function()
                    store:Add("name", "")
                end).to.throw()
            end)
        end)

        describe("Get", function()
            it("should return nil when no keys exist", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                expect(store:Get("default")).to.equal(nil)
            end)

            it("should return key by name", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("mykey", "secret123")
                local result = store:Get("mykey")
                expect(result).to.be.ok()
                expect(result.key).to.equal("secret123")
            end)

            it("should return first key when no name specified", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("first", "value1")
                store:Add("second", "value2")
                local result = store:Get()
                expect(result).to.be.ok()
                expect(result.name).to.equal("first")
            end)

            it("should return nil for non-existent name", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("exists", "value")
                expect(store:Get("nonexistent")).to.equal(nil)
            end)
        end)

        describe("Remove", function()
            it("should remove an existing key", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("target", "value")
                local removed = store:Remove("target")
                expect(removed).to.equal(true)
                expect(#store:List()).to.equal(0)
            end)

            it("should return false for non-existent key", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                local removed = store:Remove("nonexistent")
                expect(removed).to.equal(false)
            end)
        end)

        describe("RemoveAll", function()
            it("should remove all keys", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                store:Add("key1", "value1")
                store:Add("key2", "value2")
                store:Add("key3", "value3")
                local count = store:RemoveAll()
                expect(count).to.equal(3)
                expect(#store:List()).to.equal(0)
            end)

            it("should return 0 when no keys exist", function()
                local store = ApiKeyStore.new(createTempDir(BASE_NAME))
                local count = store:RemoveAll()
                expect(count).to.equal(0)
            end)
        end)
    end)
end
