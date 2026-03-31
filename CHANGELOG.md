# Changelog

## 0.1.0
- Modernize CLI into modular command architecture matching rbxstudio-cli pattern
- Add completion, version generation, and build scripts
- Standardize CI workflows across all commandline-luau CLI repos
- Add per-repo Terraform config for branch protection
- Bump commandline-luau to 0.0.15 and lune to 0.10.4-horse.14.2
- Fix test file headers to include .spec sub-extension

## 0.0.7
- Added file header with name and auto-generated notice to WriteLuauModule output
- Updated file header names to use full sub-extension (e.g., `MyTest.spec`)
- Updated luau-lsp to 1.63.0-horse.1.2
- Switched rojo to horsenuggets fork 7.7.0-rc.1-horse.0.1
- Fixed trailing newline when writing cache file

## 0.0.6
- Changed image uploads to use Image asset type instead of Decal for universal compatibility

## 0.0.5
- Changed init creator prompt to a select menu (User ID vs Group ID)
- Changed default assets directory from "assets" to "Assets"
- Added flags for all init prompts for non-interactive use

## 0.0.4
- Added per-mapping `apiKeyEnvName` field for custom API key environment variables
- Replaced `stdio.style` and `stdio.color` with Chalk for terminal styling

## 0.0.3
- Removed CLI api-key management in favor of .env file with ROBLOX_API_KEY
- Added retry logic with exponential backoff for network failures and rate limits
- Updated Dotenv dependency to 0.1.3 for compiled binary compatibility
- Fixed version display showing 0.0.0 when run outside repo directory

## 0.0.2
- Fixed release artifacts to use zip archives for Rokit compatibility
- Fixed release checks to use forked luau-lsp with --platform lune
- Updated luau-cicd submodule with forked luau-lsp support

## 0.0.1
- Added sync and watch commands for uploading assets via Roblox Open Cloud API
- Added init command for scaffolding assetfile.json configuration
- Added api-key management with binary storage at ~/.assetfile/
- Added parallel asset uploading with per-job result collection
- Added file watcher with mtime-based change detection
- Added cross-platform build script for 6 targets
- Added CI/CD workflows for formatting, testing, static analysis, and multi-platform releases
