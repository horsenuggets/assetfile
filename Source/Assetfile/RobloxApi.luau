--[[

RobloxApi

Client for the Roblox Open Cloud Assets API. Handles uploading assets
and polling for operation completion.

--]]

local net = require("@lune/net")
local serde = require("@lune/serde")
local task = require("@lune/task")

local t = require("@packages/t")

local FormData = require("@assetfile/FormData")

local API_BASE = "https://apis.roblox.com/assets/v1"
local MAX_POLL_ATTEMPTS = 10
local INITIAL_POLL_DELAY = 1

export type AssetType = "Audio" | "Decal" | "Model"

export type CreatorInfo = {
    userId: string?,
    groupId: string?,
}

export type UploadRequest = {
    AssetType: AssetType,
    DisplayName: string,
    Description: string,
    Creator: CreatorInfo,
    FileContent: string,
    Filename: string,
}

export type UploadResult = {
    AssetId: string,
    DisplayName: string,
    ModerationState: string,
}

export type RobloxApi = {
    Upload: (self: RobloxApi, request: UploadRequest) -> UploadResult,
}

local ASSET_TYPE_MAP: { [string]: AssetType } = {
    bmp = "Decal",
    fbx = "Model",
    flac = "Audio",
    gif = "Decal",
    glb = "Model",
    gltf = "Model",
    jpeg = "Decal",
    jpg = "Decal",
    mp3 = "Audio",
    ogg = "Audio",
    png = "Decal",
    rbxm = "Model",
    rbxmx = "Model",
    tga = "Decal",
    wav = "Audio",
    webp = "Decal",
}

local RobloxApi = {}
RobloxApi.__index = RobloxApi

function RobloxApi.getAssetType(filename: string): AssetType?
    local extension = filename:match("%.(%w+)$")
    if extension then
        return ASSET_TYPE_MAP[extension:lower()]
    end
    return nil
end

function RobloxApi.new(apiKey: string): RobloxApi
    assert(t.string(apiKey))
    assert(#apiKey > 0, "API key must not be empty.")

    local self = setmetatable({
        _apiKey = apiKey,
    }, RobloxApi)

    return self
end

function RobloxApi._pollOperation(self: RobloxApi, operationId: string): UploadResult
    local delay = INITIAL_POLL_DELAY

    for attempt = 1, MAX_POLL_ATTEMPTS do
        task.wait(delay)

        local response = net.request({
            url = `{API_BASE}/operations/{operationId}`,
            method = "GET",
            headers = {
                ["x-api-key"] = (self :: any)._apiKey,
            },
        })

        if not response.ok then
            error(`Failed to poll operation "{operationId}" (HTTP {response.statusCode}).`)
        end

        local body = serde.decode("json", response.body)

        if body.done then
            return {
                AssetId = body.response.assetId,
                DisplayName = body.response.displayName,
                ModerationState = body.response.moderationResult and body.response.moderationResult.moderationState
                    or "UNKNOWN",
            }
        end

        if attempt < MAX_POLL_ATTEMPTS then
            delay *= 2
        end
    end

    error(`Operation "{operationId}" did not complete after` .. ` {MAX_POLL_ATTEMPTS} attempts.`)
end

function RobloxApi.Upload(self: RobloxApi, request: UploadRequest): UploadResult
    assert(t.string(request.DisplayName))
    assert(t.string(request.FileContent))
    assert(t.string(request.Filename))

    local creatorContext: { [string]: any } = { creator = {} }
    if request.Creator.userId then
        creatorContext.creator.userId = request.Creator.userId
    else
        creatorContext.creator.groupId = request.Creator.groupId
    end

    local metadata = serde.encode("json", {
        assetType = request.AssetType,
        displayName = request.DisplayName,
        description = request.Description,
        creationContext = creatorContext,
    })

    local form = FormData.new()
    form:Append("request", metadata, nil, "application/json")
    form:Append("fileContent", request.FileContent, request.Filename, FormData.getMimeType(request.Filename))

    local response = net.request({
        url = `{API_BASE}/assets`,
        method = "POST",
        headers = {
            ["x-api-key"] = (self :: any)._apiKey,
            ["Content-Type"] = form:GetContentType(),
        },
        body = form:GetBody(),
    })

    if not response.ok then
        error(`Failed to upload asset "{request.DisplayName}"` .. ` (HTTP {response.statusCode}): {response.body}`)
    end

    local body = serde.decode("json", response.body)
    local operationId = body.path and body.path:match("operations/(.+)") or body.operationId

    if not operationId then
        error(`Upload response did not contain an operation ID.`)
    end

    return self:_pollOperation(operationId)
end

return RobloxApi
