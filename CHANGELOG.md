# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog.

## [Unreleased] - 2026-08-04

### Changed
- Upgraded provider constraints to target azurerm 5.x compatibility (`~> 5.0`) and pinned null provider to `~> 3.0`.
- Added Terraform and linting guardrails in CI and repository configs (`.tflint.hcl`, `.gitattributes`, `.gitignore`, workflow updates).
- Bumped ESLZ module source reference in `ESLZ/containerGroups.tf` from `v1.1.0` to `v1.1.1`.
- SHA-pinned all GitHub Actions in `terraform-ci.yml`, `documentation.yml`, and `release.yml` (with version comments) per GitHub's supply-chain hardening guidance.
- Hardened `release.yml`'s PR-notes generation to write `PR_BODY`/`PR_TITLE`/`PR_NUMBER` straight from their `env:` values to a file with no intermediate shell variable holding raw content.
- Extracted the hard-coded `null_resource.local-exec-stop` subscription aliases (`G3Mc-CTO-ENT-MRZ`, `GcPc-CTO-ENT-CORE`) into a new overridable `stop_container_probe_subscriptions` variable, defaulting to the same values for backward compatibility.
- Rewrote `tests/upgrade_compat.tftest.hcl`'s `upgrade_plan_no_replacement` run: per provider docs, nearly every `azurerm_container_group` argument is ForceNew, so the previous test's `ip_address_type`/`dns_name_label`/`zones` change would actually force replacement on real infrastructure despite the test's name/intent. The run now changes only `tags` (the one attribute that's mutable in place) and asserts `id` stability across the plan, which genuinely proves no replacement occurs.

### Added
- Added release workflow (`.github/workflows/release.yml`) that tags releases from `ESLZ/containerGroups.tf` module ref after merged PRs.
- Added upgrade compatibility test (`tests/upgrade_compat.tftest.hcl`) and expanded mock test coverage for optional container group arguments/blocks.
- Documented the `lifecycle { ignore_changes = [container] }` behavior in a new README.md "Known Behavior" section, cross-referenced from `ESLZ/containerGroups.tfvars` and inline in `module.tf`.
- Documented (via test comment) that the `stop_containers = true` / `null_resource.local-exec-stop` path cannot be meaningfully covered by `terraform test` since it invokes the real Azure CLI.

### Known blockers
- None.

