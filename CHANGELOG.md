# Changelog

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
