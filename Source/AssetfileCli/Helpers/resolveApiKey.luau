--[[

resolveApiKey

Resolves a Roblox Open Cloud API key from the environment. Loads a .env
file if present, then checks the specified environment variable (defaulting
to ROBLOX_API_KEY).

--]]

const process = require("@lune/process")

const Dotenv = require("@packages/Dotenv")

const function resolveApiKey(envName: string?): string
    pcall(Dotenv.load)

    const name = envName or "ROBLOX_API_KEY"
    const apiKey = process.env[name]

    if apiKey and #apiKey > 0 then
        return apiKey
    end

    error(`No API key found. Set {name} in your .env file or as an environment variable.`)
end

return resolveApiKey
