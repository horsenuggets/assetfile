local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local task = require("@lune/task")

local Dotenv = require("@packages/Dotenv")

local function main()
    Dotenv.load()

    local robloxApiKey = process.env.ROBLOX_API_KEY
    local assetsToUpload = {} :: { { Name: string, Path: string } }

    for _, fileName in fs.readDir(process.cwd) do
        -- If the file ends with .png, add it to assetPaths
        if fileName:sub(-4):lower() == ".png" then
            table.insert(assetsToUpload, {
                Name = fileName,
                Path = `{process.cwd}{fileName}`,
            })
        end
    end

    for _, assetData in assetsToUpload do
        print(assetData)

        local jsonRequest = serde.encode("json", {
            assetType = "Decal",
            displayName = assetData.Name,
            description = "Uploaded by Assetfile.",
            creationContext = {
                creator = {
                    userId = "35493303",
                },
            },
        })

        local uploadArgs = {
            "--location",
            "https://apis.roblox.com/assets/v1/assets",
            "--header",
            `x-api-key: {robloxApiKey}`,
            "--form",
            `request={jsonRequest}`,
            "--form",
            `fileContent=@"{assetData.Path}";type=image/png`,
        }

        local uploadResult = process.exec("curl", uploadArgs)
        local operationId = serde.decode("json", uploadResult.stdout).operationId

        local checkArgs = {
            "--location",
            `https://apis.roblox.com/assets/v1/operations/{operationId}`,
            "--header",
            `x-api-key: {robloxApiKey}`,
        }

        local maxAttempts = 5
        local attempt = 0
        local success = false
        local response

        while task.wait(1) do
            attempt += 1
            if attempt > maxAttempts then
                print("Max attempts reached for checking upload status.")
                break
            end

            local checkResult = process.exec("curl", checkArgs)
            response = serde.decode("json", checkResult.stdout)

            if response.done then
                success = true
                break
            end

            print("Waiting for upload to complete... Attempt: " .. attempt)
        end

        if not success then
            print("Failed to upload texture after " .. maxAttempts .. " attempts.")
            break
        end

        local assetId = response.response.assetId

        print("Upload completed successfully. Asset ID: " .. assetId)
    end
end

main()
