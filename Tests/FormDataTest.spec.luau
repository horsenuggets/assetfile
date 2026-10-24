--[[

FormDataTest.spec

Tests for the FormData multipart form-data builder.

--]]

const FormData = require("@assetfile/FormData")

return function()
    describe("FormData", function()
        describe("getMimeType", function()
            it("should return correct MIME type for png", function()
                expect(FormData.getMimeType("image.png")).to.equal("image/png")
            end)

            it("should return correct MIME type for jpg", function()
                expect(FormData.getMimeType("photo.jpg")).to.equal("image/jpeg")
            end)

            it("should return correct MIME type for mp3", function()
                expect(FormData.getMimeType("song.mp3")).to.equal("audio/mpeg")
            end)

            it("should return correct MIME type for fbx", function()
                expect(FormData.getMimeType("model.fbx")).to.equal("model/fbx")
            end)

            it("should return correct MIME type for wav", function()
                expect(FormData.getMimeType("sound.wav")).to.equal("audio/wav")
            end)

            it("should return nil for unsupported extensions", function()
                expect(FormData.getMimeType("file.xyz")).to.equal(nil)
            end)

            it("should return nil for files without extensions", function()
                expect(FormData.getMimeType("noextension")).to.equal(nil)
            end)

            it("should be case insensitive", function()
                expect(FormData.getMimeType("image.PNG")).to.equal("image/png")
                expect(FormData.getMimeType("photo.JPG")).to.equal("image/jpeg")
            end)
        end)

        describe("new", function()
            it("should create a FormData instance with a boundary", function()
                const form = FormData.new()
                expect(form.Boundary).to.be.ok()
                expect(type(form.Boundary)).to.equal("string")
                expect(#form.Boundary > 0).to.equal(true)
            end)

            it("should generate unique boundaries", function()
                const form1 = FormData.new()
                const form2 = FormData.new()
                expect(form1.Boundary).to.never.equal(form2.Boundary)
            end)
        end)

        describe("Append", function()
            it("should add entries to the form body", function()
                const form = FormData.new()
                form:Append("field", "value", nil, "text/plain")
                const body = form:GetBody()
                expect(body:find("field")).to.be.ok()
                expect(body:find("value")).to.be.ok()
            end)

            it("should include filename when provided", function()
                const form = FormData.new()
                form:Append("file", "content", "test.png")
                const body = form:GetBody()
                expect(body:find('filename="test.png"')).to.be.ok()
            end)

            it("should auto-detect content type from filename", function()
                const form = FormData.new()
                form:Append("file", "content", "test.png")
                const body = form:GetBody()
                expect(body:find("image/png")).to.be.ok()
            end)

            it("should use provided content type over auto-detection", function()
                const form = FormData.new()
                form:Append("data", "{}", nil, "application/json")
                const body = form:GetBody()
                expect(body:find("application/json")).to.be.ok()
            end)
        end)

        describe("GetBody", function()
            it("should include boundary delimiters", function()
                const form = FormData.new()
                form:Append("field", "value", nil, "text/plain")
                const body = form:GetBody()
                expect(body:find(`--{form.Boundary}`)).to.be.ok()
                expect(body:find(`--{form.Boundary}--`)).to.be.ok()
            end)

            it("should include Content-Disposition headers", function()
                const form = FormData.new()
                form:Append("myfield", "myvalue", nil, "text/plain")
                const body = form:GetBody()
                expect(body:find('Content%-Disposition: form%-data; name="myfield"')).to.be.ok()
            end)

            it("should handle multiple entries", function()
                const form = FormData.new()
                form:Append("field1", "value1", nil, "text/plain")
                form:Append("field2", "value2", nil, "text/plain")
                const body = form:GetBody()
                expect(body:find("field1")).to.be.ok()
                expect(body:find("field2")).to.be.ok()
                expect(body:find("value1")).to.be.ok()
                expect(body:find("value2")).to.be.ok()
            end)
        end)

        describe("GetContentType", function()
            it("should return multipart/form-data with boundary", function()
                const form = FormData.new()
                const contentType = form:GetContentType()
                expect(contentType:find("multipart/form%-data")).to.be.ok()
                expect(contentType:find(form.Boundary)).to.be.ok()
            end)
        end)
    end)
end
