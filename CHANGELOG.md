# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased] - 2026-08-04

### Changed
- Upgraded provider constraints to target azurerm 5.x compatibility (`~> 5.0`) and pinned null provider to `~> 3.0`.
- Added Terraform and linting guardrails in CI and repository configs (`.tflint.hcl`, `.gitattributes`, `.gitignore`, workflow updates).
- Bumped ESLZ module source reference in `ESLZ/containerGroups.tf` from `v1.1.0` to `v1.1.1`.

### Added
- Added release workflow (`.github/workflows/release.yml`) that tags releases from `ESLZ/containerGroups.tf` module ref after merged PRs.
- Added upgrade compatibility test (`tests/upgrade_compat.tftest.hcl`) and expanded mock test coverage for optional container group arguments/blocks.

### Known blockers
- None.
