# OPS.md: Operations Runbook

## Target Hardware Manifest (Zero Compromises)

import Manifest from './shared/manifest.md';

<Manifest />

## Performance Optimizations

### OS-Level Performance

The OS image is tuned for the Framework Laptop 13 (Ryzen AI 9 HX 370) with the following kernel arguments:

- `amd_pstate=active`: Enables the active EPP (Energy Performance Preference) driver for superior power management and performance on Zen 5 architecture.
- `amdgpu.sg_display=0`: Disables scatter-gather display support to resolve flickering issues on certain high-resolution Framework panels.

### Documentation Build Performance

The documentation site (`website/`) uses **Docusaurus 3.10.0** with the **@docusaurus/faster** plugin. This replaces the standard Webpack-based build system with **Rspack**, providing significantly faster cold starts and incremental builds.

## Local Validation

Before pushing changes to the repository, you can run the BATS test suite locally if you have `bats` and `podman` installed.

### Running Tests Locally

If you have already built the image locally:

```bash
podman run --rm localhost/bluefin-wtg:latest bats /tests/os_validation.bats
```

## Disaster Recovery

### Rolling Back

Since the OS is atomic, rolling back to a previous "known-good" version is straightforward:

```bash
rpm-ostree rollback
```

### Resetting bluefin-wtg Workspace

If the AI quarantine environment becomes corrupted, you can delete the workspace and recreate it:

```bash
rm -rf ~/.local/share/wtg-workspace
ujust setup-workspace
```

## Maintenance

### Updating the Image

The image is rebuilt daily via GitHub Actions. To update your local system:

```bash
rpm-ostree upgrade
```

### Updating GitHub Actions & Website Dependencies

`dependabot` will automatically create Pull Requests for GitHub Action and npm package updates. Review and merge these weekly to ensure CI/CD security, stability, and performance.

## CI/CD Pipeline

The pipeline consists of:

1. **YAML Linting:** Ensures syntax correctness for all configuration and workflow files.
2. **BlueBuild:** Compiles the OCI image based on `recipes/recipe.yml`.
3. **BATS Validation:** Runs the `tests/os_validation.bats` suite against the newly built image.
4. **Cosign Signing:** Cryptographically signs the image if tests pass.
5. **Registry Push:** Publishes the signed image to `ghcr.io`.
