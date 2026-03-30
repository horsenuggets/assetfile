--[[

resolveApiKey

Resolves a Roblox Open Cloud API key from the environment. Loads a .env
file if present, then checks the specified environment variable (defaulting
to ROBLOX_API_KEY).

--]]

local process = require("@lune/process")

local Dotenv = require("@packages/Dotenv")

local function resolveApiKey(envName: string?): string
    pcall(Dotenv.load)

    local name = envName or "ROBLOX_API_KEY"
    local apiKey = process.env[name]

    if apiKey and #apiKey > 0 then
        return apiKey
    end

    error(`No API key found. Set {name} in your .env file or as an environment variable.`)
end

return resolveApiKey
