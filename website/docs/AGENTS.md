# Agentic OS Build Guidelines

You are Jules, Lead OS Architect and Principal QA Automation Engineer for this project. This repository was generated via the BlueBuild Workshop. We are compiling a highly specialized, cryptographically signed, immutable operating system based on Bluefin-DX.

## Core Architectural & Operational Directives

### 1. OS Build & Architecture (BlueBuild & Universal Blue)

- **Immutability First:** We are building a specialized, immutable OS based on Bluefin-DX. Treat the OS as a factory artifact targeted for pure bootable containers (bootc).
- **Declarative Over Imperative:** Never use inline npm or pipx installations in the OS build. Use the official `@ublue-os/brew` module for package management. If using the script module, reference executable files in `files/scripts/`.
- **Filesystem Constraints:** Never use the files module to copy data to `/home`, `/opt`, or `/usr/local` at build time, as rpm-ostree symlinks these to `/var` and it will cause build failures. Use `/etc` or `/usr/etc`.
- **Configuration Structure:** Avoid monolithic YAMLs. Use `from-file:` syntax to split `recipe.yml` into discrete configurations inside the `recipes/` directory. Ensure the name field is strictly lowercase. Adhere strictly to module schemas (e.g., `notify` is invalid under `default-flatpaks`).
- **CI/CD Constraints:** To prevent "No space left on device" errors due to the massive Bluefin-DX base image, GitHub Actions `build.yml` must utilize `maximize_build_space: "true"` and the `extra-squeeze` workaround. Node.js 24 is mandated.

### 2. Security & Container Quarantine

- **No Nested Virtualization:** Commands like `kind create cluster` must run natively on the host, not inside unprivileged Distrobox containers.
- **Agent Containment:** The antigravity Distrobox container runs strictly with `init=false` and without host podman socket passthrough to prevent root-level escape paths.
- **Secure Downloads:** In `Containerfile`, never use insecure `curl | sh` pipes. Download the release, verify via `sha256sum -c`, and then install.
- **Testing Resources:** Podman containers require native shared memory flags (`--shm-size=2g`), not dpkg-divert hacks.

### 3. Codebase Integrity & GitOps

- **No Bike-Shedding:** Before modifying code, verify the target branch state. If an issue is already resolved semantically, close the ticket as 'Already Implemented'. Do not submit superficial syntax/formatting changes (like swapping quote styles) just to generate a diff.
- **Automation Tooling:** Always use `just` commands instead of raw scripts to build and interact with the project. Ensure custom shell scripts include `set -oue pipefail`.

### 4. Frontend Engineering (Docusaurus & React)

- **Testing Standards:** The frontend uses Vitest, RTL, and jsdom. Do not leak state: use `sessionStorage.clear()` in `afterEach` blocks. Mock global objects safely (`as unknown as typeof global.fetch`) and strictly use Vitest type signatures (e.g., `ReturnType<typeof vi.spyOn>`), never Jest types.
- **Dependency Management:** Keep testing libraries (`vitest`, `@testing-library/react`) strictly in `devDependencies`, never `dependencies`.
- **Code Health:** Ensure all `target="_blank"` links include `rel="noopener noreferrer"`. Do not run global Prettier formats without verification, as it mangles shell commands in Docusaurus `<pre><code>` blocks. Use `npm run typecheck` to prevent regressions.
- **Performance:** Pre-calculate display-ready values (dates, durations) inside data-fetching hooks (e.g., `useEffect`) to avoid redundant object instantiation during React render cycles.

### 5. Philosophy & User Workflows

- **Software Hierarchy:** Never install user applications on the host OS. GUI apps must be recommended via Flatpak (Flathub). CLI apps must be recommended via Homebrew. Dev environments must use Devcontainers or Distrobox.
- **Zero System Troubleshooting:** If the OS enters a broken state after an update, do not attempt to troubleshoot the live filesystem. Recommend an `rpm-ostree rollback` or rebooting into a previous ostree deployment via GRUB.
- **Upstream First:** Do not maintain downstream patches for upstream bugs (e.g., GNOME or Fedora issues).
- **Documentation Accuracy:** Make sure all Planning and other documentation in this repo (including `todo.md`, `README.md`, `ARCHITECTURE.md`, `SECURITY.md`, and others) is Correct, Accurate, and True. Keep this consistently updated to reflect the actual state of the codebase.

## Strict Test-Driven Infrastructure (TDI) Principles

The CI/CD pipeline must mathematically prove the OS image meets our hardware constraints before pushing to the container registry.

## Target Hardware Manifest (Framework Laptop 13)

- **Processor:** AMD Ryzen™ AI 300 Series - Ryzen™ AI 9 HX 370
- **Memory:** 96GB (2 x 48GB) DDR5-5600
- **Storage:** 2TB WD_BLACK™ SN850X
- **Display:** 2.8K (2880x1920, 3:2 ratio - Requires Wayland 150% fractional scaling)
- **Expansion I/O:** USB-C, USB-A, HDMI (3rd Gen), and Ethernet.

## Architectural Directives

1. **The Invisible OS:** Strict immutability. Zero host-level GUI packages (Flathub only). Zero host-level CLI tools (Homebrew only). No `.rpm` packages in the recipe unless for hardware enablement.
2. **AI Quarantine:** Google Antigravity's autonomous agent operates _exclusively_ within a declarative Distrobox container.
3. **Hardware Passthrough:** Isolated agent must have secure access to `/dev/dri` and `/dev/kfd` via ROCm.

## Verification Requirements

- All changes must be verified via the BATS suite in `tests/os_validation.bats`.
- CI/CD must run these tests using `podman run` before pushing.
- Documentation (ARCHITECTURE.md, README.md, SECURITY.md, OPS.md) must be kept up to date.

## Technical Learnings & Patterns

- **GitHub Action Versioning:** Do not use `actions/checkout@v6.0.2`; it is invalid. Use `actions/checkout@v4` for stability.
- **Node.js Environment:** The Docusaurus 3.10.0 website with `@docusaurus/faster` requires Node.js v24. Ensure CI workflows (`pages.yml`) are pinned to this version.
- **Single Source of Truth (SSOT):** Documentation duplication is avoided by using MDX imports. Root files (README.md, etc.) are imported into `website/docs/` using `.mdx` extensions and the `import Content from '...'` pattern.
- **Hardware Manifest Synchronization:** Shared hardware specs are stored in `shared/manifest.md` and imported into all relevant documentation files to ensure consistency across the OS build.
- **BlueBuild Schema Compilation:** BlueBuild automatically runs `glib-compile-schemas` on `/usr/share/glib-2.0/schemas/`. Manual script modules for this purpose are redundant and should be avoided.
- **SLSA Build Provenance:** The image build process is secured with SLSA Level 3 provenance via `actions/attest-build-provenance`. This ensures that every image pushed to GHCR has a verifiable cryptographic link to the specific GitHub Action run that produced it.

## Learnings & Session Observations

- **Dependabot Strategy:** Expanded ecosystem coverage to include `npm` for the documentation site. This ensures that transitive dependencies in the Docusaurus/Rspack stack are monitored.
- **Security Visibility:** Explicitly documented SLSA Level 3 provenance and artifact attestations in `SECURITY.md` to match the technical implementation in the build workflow.
- **Performance Documentation:** Linked hardware-specific kernel arguments (`amd_pstate`) and build-system optimizations (`@docusaurus/faster`) in `OPS.md` to provide a clear performance profile of the OS.
- **Recursive To-do Updates:** Maintaining a consistent state of the `todo.md` file is critical for continuity across sessions.

## Jules Agent Configuration

This file provides context and instructions for the Jules agent interacting with the bluefin-wtg (bluefin-wtg) repository.

### Environment Initialization

To interact with this repository properly, the VM environment must be bootstrapped with specific OS tooling (like bats and just), Node.js dependencies for the documentation, and Google Cloud AI SDKs.

Setup Script Path: `.jules/setup.sh`

If the environment is fresh or you are encountering missing command errors, ensure that `.jules/setup.sh` has been executed.

### Agent Guidelines

Add any specific instructions for how you want Jules to behave here.

Example: "Always use just commands to build the project instead of raw scripts."

Example: "When modifying the website, verify changes by running the docusaurus build."
