# Changelog

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
