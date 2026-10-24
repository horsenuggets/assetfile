--[[

Assetfile

Core library for syncing local asset files with Roblox. Provides
configuration loading, asset uploading, and file watching.

--]]

const AssetMap = require("@self/AssetMap")
const Config = require("@self/Config")
const FileUtils = require("@self/FileUtils")
const FormData = require("@self/FormData")
const RobloxApi = require("@self/RobloxApi")
const Sync = require("@self/Sync")
const Watcher = require("@self/Watcher")

return {
    AssetMap = AssetMap,
    Config = Config,
    FileUtils = FileUtils,
    FormData = FormData,
    RobloxApi = RobloxApi,
    Sync = Sync,
    Watcher = Watcher,
}
