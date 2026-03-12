--[[

FormData

Multipart form-data builder for constructing HTTP requests with file
uploads. Generates RFC 2388 compliant form bodies with proper boundary
delimiters.

--]]

local t = require("@packages/t")

type FormDataEntry = {
    Name: string,
    Value: string,
    Filename: string?,
    ContentType: string,
}

export type FormData = {
    Boundary: string,
    GetBody: (self: FormData) -> string,
    GetContentType: (self: FormData) -> string,
    Append: (self: FormData, name: string, value: string, filename: string?, contentType: string?) -> (),
}

local MIME_TYPES = table.freeze({
    bmp = "image/bmp",
    fbx = "model/fbx",
    flac = "audio/flac",
    gif = "image/gif",
    glb = "model/gltf-binary",
    gltf = "model/gltf+json",
    jpeg = "image/jpeg",
    jpg = "image/jpeg",
    json = "application/json",
    mp3 = "audio/mpeg",
    ogg = "audio/ogg",
    png = "image/png",
    rbxm = "model/x-rbxm",
    rbxmx = "model/x-rbxmx",
    tga = "image/tga",
    wav = "audio/wav",
    webp = "image/webp",
})

local FormData = {}
FormData.__index = FormData

local function generateBoundary(): string
    local chars = {}
    for _ = 1, 32 do
        table.insert(chars, string.format("%x", math.random(0, 15)))
    end
    return "AssetfileBoundary" .. table.concat(chars)
end

function FormData.getMimeType(filename: string): string?
    local extension = filename:match("%.(%w+)$")
    if extension then
        return MIME_TYPES[extension:lower()]
    end
    return nil
end

function FormData.new(): FormData
    local self = setmetatable({
        _entries = {} :: { FormDataEntry },
        Boundary = generateBoundary(),
    }, FormData)
    return self
end

function FormData.Append(self: FormData, name: string, value: string, filename: string?, contentType: string?): ()
    assert(t.string(name))
    assert(t.string(value))

    local resolvedContentType = contentType
    if not resolvedContentType and filename then
        resolvedContentType = FormData.getMimeType(filename)
    end

    table.insert((self :: any)._entries, {
        Name = name,
        Value = value,
        Filename = filename,
        ContentType = resolvedContentType or "application/octet-stream",
    })
end

function FormData.GetBody(self: FormData): string
    local entries = (self :: any)._entries :: { FormDataEntry }
    local parts = {}

    for _, entry in entries do
        local header = `--{self.Boundary}\r\n`
        header ..= `Content-Disposition: form-data; name="{entry.Name}"`
        if entry.Filename then
            header ..= `; filename="{entry.Filename}"`
        end
        header ..= `\r\nContent-Type: {entry.ContentType}\r\n\r\n`

        table.insert(parts, header .. entry.Value .. "\r\n")
    end

    table.insert(parts, `--{self.Boundary}--\r\n`)
    return table.concat(parts)
end

function FormData.GetContentType(self: FormData): string
    return `multipart/form-data; boundary={self.Boundary}`
end

return FormData
