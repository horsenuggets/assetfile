#!/usr/bin/env -S lune run

--[[

RunTests

Executes all test suites and exits with appropriate status code.
Optionally pass a test name as an argument to run only that test suite.

[Usage] lune run ./Scripts/RunTests.luau [TestName]

--]]

local Testable = require("@devpackages/Testable")
local process = require("@lune/process")

local TESTS = {
    { Name = "ApiKeyStoreTest", Func = require("../Tests/ApiKeyStoreTest.spec") },
    { Name = "AssetMapTest", Func = require("../Tests/AssetMapTest.spec") },
    { Name = "CliTest", Func = require("../Tests/CliTest.spec") },
    { Name = "ConfigTest", Func = require("../Tests/ConfigTest.spec") },
    { Name = "FileUtilsTest", Func = require("../Tests/FileUtilsTest.spec") },
    { Name = "FormDataTest", Func = require("../Tests/FormDataTest.spec") },
    { Name = "RobloxApiTest", Func = require("../Tests/RobloxApiTest.spec") },
}

local function runTests()
    local filterName = process.args[1]
    local testsToRun = TESTS

    if filterName then
        testsToRun = {}
        for _, test in TESTS do
            if test.Name == filterName then
                table.insert(testsToRun, test)
            end
        end

        if #testsToRun == 0 then
            print(`No test suite found with name "{filterName}".`)
            print("Available test suites:")
            for _, test in TESTS do
                print(`- {test.Name}`)
            end
            process.exit(1)
        end
    end

    local _, passed = Testable.run(testsToRun)
    process.exit(if passed then 0 else 1)
end

runTests()
