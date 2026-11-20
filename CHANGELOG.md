# Changelog

All notable changes to `bluefin-wtg` are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- **`bluebuild` Fedora 45 / GNOME Mutter Schema Override (`files/gschema-overrides/zz1-org.gnome.mutter.gschema.override`):** Removed obsolete `[org.gnome.mutter]` `experimental-features=['scale-monitor-framebuffer']` override that broke `glib-compile-schemas --strict` after upstream GNOME Mutter graduated fractional scaling and removed the `experimental-features` key.
- **Cosign v3 Zero-Trust Gate (`.github/workflows/build-weekly-iso.yml`, `.github/workflows/build-live-iso.yml`):** Added `--insecure-ignore-tlog=true` (and `--new-bundle-format=false` fallback for legacy OCI `.sig` artifacts emitted by `blue-build/github-action@v1`) so Cosign v3 verifies `cosign.pub` image signatures cleanly.
- **Dynamic Fedora Major Version Detection (`.github/workflows/build-weekly-iso.yml`, `.github/workflows/build-live-iso.yml`):** Replaced hardcoded `version: 41` with `skopeo inspect` extraction from the built image's `ostree.linux` / `org.opencontainers.image.version` labels (with safe fallback to `45`) for `jasonn3/build-container-installer`.

### Added
- **45-Day Scheduled Workflow Keepalive (`.github/workflows/keepalive.yml`):** Added scheduled keepalive workflow using least-privilege permissions (`contents: read`, job-level `actions: write`) to prevent GitHub's 60-day `disabled_inactivity` freeze on daily OS and weekly/monthly ISO builds.
- **Compliance & Vulnerability Reporting (`TODO.md`, `CHANGELOG.md`, `SECURITY.md`):** Added root `TODO.md` (tracking the pending Framework laptop `rpm-ostree status` check for `wtgos` vs `bluefin-wtg` image naming), `CHANGELOG.md`, and private vulnerability reporting instructions in `SECURITY.md` while preserving the Apache-2.0 `LICENSE`.

### Security
- **GitHub Actions Hardening (`.github/workflows/*.yml`):** Pinned all third-party GitHub Actions to full 40-char commit SHAs, added top-level least-privilege `permissions: { contents: read }`, and enabled `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`.
