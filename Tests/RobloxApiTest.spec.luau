--[[

RobloxApiTest.spec

Tests for the RobloxApi module. Only tests static methods and
construction since actual API calls require a real API key.

--]]

local RobloxApi = require("@assetfile/RobloxApi")

return function()
    describe("RobloxApi", function()
        describe("getAssetType", function()
            it("should return Image for png", function()
                expect(RobloxApi.getAssetType("image.png")).to.equal("Image")
            end)

            it("should return Image for jpg", function()
                expect(RobloxApi.getAssetType("photo.jpg")).to.equal("Image")
            end)

            it("should return Image for bmp", function()
                expect(RobloxApi.getAssetType("image.bmp")).to.equal("Image")
            end)

            it("should return Image for tga", function()
                expect(RobloxApi.getAssetType("texture.tga")).to.equal("Image")
            end)

            it("should return Audio for mp3", function()
                expect(RobloxApi.getAssetType("song.mp3")).to.equal("Audio")
            end)

            it("should return Audio for wav", function()
                expect(RobloxApi.getAssetType("sound.wav")).to.equal("Audio")
            end)

            it("should return Audio for ogg", function()
                expect(RobloxApi.getAssetType("music.ogg")).to.equal("Audio")
            end)

            it("should return Audio for flac", function()
                expect(RobloxApi.getAssetType("music.flac")).to.equal("Audio")
            end)

            it("should return Model for fbx", function()
                expect(RobloxApi.getAssetType("tree.fbx")).to.equal("Model")
            end)

            it("should return Model for glb", function()
                expect(RobloxApi.getAssetType("model.glb")).to.equal("Model")
            end)

            it("should return nil for unsupported types", function()
                expect(RobloxApi.getAssetType("file.txt")).to.equal(nil)
                expect(RobloxApi.getAssetType("script.lua")).to.equal(nil)
            end)
        end)

        describe("new", function()
            it("should create an instance with a valid API key", function()
                local api = RobloxApi.new("test-key-12345")
                expect(api).to.be.ok()
            end)

            it("should error with empty API key", function()
                expect(function()
                    RobloxApi.new("")
                end).to.throw()
            end)
        end)
    end)
end
