--[[

ApiKeyStore

Manages Roblox API keys stored in a binary file. Keys are saved to a
user-level config directory so they persist across projects. Supports
both instance-based usage for test isolation and module-level
convenience functions for CLI usage.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local t = require("@packages/t")

local CONFIG_DIR_NAME = ".assetfile"
local KEYS_FILENAME = "api-keys"

export type StoredKey = {
    name: string,
    key: string,
}

export type ApiKeyStore = {
    Add: (self: ApiKeyStore, name: string, key: string) -> (),
    Get: (self: ApiKeyStore, name: string?) -> StoredKey?,
    List: (self: ApiKeyStore) -> { StoredKey },
    Remove: (self: ApiKeyStore, name: string) -> boolean,
    RemoveAll: (self: ApiKeyStore) -> number,
}

local ApiKeyStore = {}
ApiKeyStore.__index = ApiKeyStore

local function defaultStoreDir(): string
    local home = process.env.HOME or process.env.USERPROFILE
    assert(home, "Could not determine home directory.")
    return `{home}/{CONFIG_DIR_NAME}`
end

function ApiKeyStore.new(storeDir: string?): ApiKeyStore
    local dir = storeDir or defaultStoreDir()

    local self = setmetatable({
        _storeDir = dir,
        _storePath = `{dir}/{KEYS_FILENAME}`,
    }, ApiKeyStore)

    return self
end

function ApiKeyStore._loadKeys(self: ApiKeyStore): { StoredKey }
    local path = (self :: any)._storePath
    if not fs.isFile(path) then
        return {}
    end

    local ok, keys = pcall(function()
        local content = fs.readFile(path)
        local buf = buffer.fromstring(content)

        if buffer.len(buf) < 4 then
            return {}
        end

        local count = buffer.readu32(buf, 0)
        local offset = 4
        local result: { StoredKey } = {}

        for _ = 1, count do
            local nameLen = buffer.readu32(buf, offset)
            offset += 4
            local name = buffer.readstring(buf, offset, nameLen)
            offset += nameLen

            local keyLen = buffer.readu32(buf, offset)
            offset += 4
            local key = buffer.readstring(buf, offset, keyLen)
            offset += keyLen

            table.insert(result, { name = name, key = key })
        end

        return result
    end)

    if ok then
        return keys
    end
    return {}
end

function ApiKeyStore._saveKeys(self: ApiKeyStore, keys: { StoredKey }): ()
    local dir = (self :: any)._storeDir
    if not fs.isDir(dir) then
        fs.writeDir(dir)
    end

    -- Calculate total buffer size
    local size = 4
    for _, stored in keys do
        size += 4 + #stored.name + 4 + #stored.key
    end

    local buf = buffer.create(size)
    buffer.writeu32(buf, 0, #keys)
    local offset = 4

    for _, stored in keys do
        buffer.writeu32(buf, offset, #stored.name)
        offset += 4
        buffer.writestring(buf, offset, stored.name)
        offset += #stored.name

        buffer.writeu32(buf, offset, #stored.key)
        offset += 4
        buffer.writestring(buf, offset, stored.key)
        offset += #stored.key
    end

    fs.writeFile((self :: any)._storePath, buffer.tostring(buf))
end

function ApiKeyStore.Add(self: ApiKeyStore, name: string, key: string): ()
    assert(t.string(name))
    assert(t.string(key))
    assert(#name > 0, "Key name must not be empty.")
    assert(#key > 0, "Key value must not be empty.")

    local keys = self:_loadKeys()

    for _, stored in keys do
        if stored.name == name then
            error(`An API key with the name "{name}" already exists.`)
        end
    end

    table.insert(keys, { name = name, key = key })
    self:_saveKeys(keys)
end

function ApiKeyStore.List(self: ApiKeyStore): { StoredKey }
    return self:_loadKeys()
end

function ApiKeyStore.Get(self: ApiKeyStore, name: string?): StoredKey?
    local keys = self:_loadKeys()
    local targetName = name or "default"

    for _, stored in keys do
        if stored.name == targetName then
            return stored
        end
    end

    -- If no name specified and no "default" key, return the first key
    if name == nil and #keys > 0 then
        return keys[1]
    end

    return nil
end

function ApiKeyStore.Remove(self: ApiKeyStore, name: string): boolean
    assert(t.string(name))

    local keys = self:_loadKeys()
    for i, stored in keys do
        if stored.name == name then
            table.remove(keys, i)
            self:_saveKeys(keys)
            return true
        end
    end

    return false
end

function ApiKeyStore.RemoveAll(self: ApiKeyStore): number
    local keys = self:_loadKeys()
    local count = #keys
    self:_saveKeys({})
    return count
end

-- Module-level convenience functions for CLI usage.
-- These create a default instance using the user's home directory.

function ApiKeyStore.add(name: string, key: string): ()
    ApiKeyStore.new():Add(name, key)
end

function ApiKeyStore.list(): { StoredKey }
    return ApiKeyStore.new():List()
end

function ApiKeyStore.get(name: string?): StoredKey?
    return ApiKeyStore.new():Get(name)
end

function ApiKeyStore.remove(name: string): boolean
    return ApiKeyStore.new():Remove(name)
end

function ApiKeyStore.removeAll(): number
    return ApiKeyStore.new():RemoveAll()
end

return ApiKeyStore
