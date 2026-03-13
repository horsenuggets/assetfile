--[[

Assetfile

Core library for syncing local asset files with Roblox. Provides
configuration loading, asset uploading, and file watching.

--]]

local AssetMap = require("@self/AssetMap")
local Config = require("@self/Config")
local FileUtils = require("@self/FileUtils")
local FormData = require("@self/FormData")
local RobloxApi = require("@self/RobloxApi")
local Sync = require("@self/Sync")
local Watcher = require("@self/Watcher")

return {
    AssetMap = AssetMap,
    Config = Config,
    FileUtils = FileUtils,
    FormData = FormData,
    RobloxApi = RobloxApi,
    Sync = Sync,
    Watcher = Watcher,
}
