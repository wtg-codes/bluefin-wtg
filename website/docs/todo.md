# Project Improvements Checklist

1. [x] Fix invalid `actions/checkout@v4` versioning (pinned to stable `v4`).
2. [x] Implement "Single Source of Truth" for documentation via MDX imports.
3. [x] Migrate Build Dashboard to Docusaurus build pipeline.
4. [x] Remove redundant `glib-compile-schemas` comments from `recipe.yml`.

# 🛠️ Jules Implementation Plan: bluefin-wtg "Sanity-Gravity" Remediation

**Architects:** The Cloud-Native Linux Professor & Jorge Castro
**Objective:** Restore cryptographic SLSA Level 3 provenance, enforce true immutability, and implement cloud-native cattle-driven developer workflows.
**Agent Assignee:** Jules

This document outlines the strict, multi-round Pull Request strategy to remediate the bluefin-wtg repository. Jules is instructed to execute these rounds sequentially. No task or round is considered complete until its Exit Criteria can be mathematically or programmatically proven.

## ⭕ Round 1: Securing the Perimeter (The Podman Socket)

**Goal:** Quarantine the AI agent and prevent root-level escape paths by removing the host podman socket passthrough.

- [ ] **Task 1.1: Locate Distrobox Configuration**
      Open `files/usr/share/bluefin-framework/bluefin-wtg/distrobox.ini` (or the equivalent initialization script used for workspace generation).
  - **Exit Criteria:** File is successfully loaded into the agent's context and parsed without errors.

- [ ] **Task 1.2: Excise Socket Passthrough**
      Find and DELETE the line: `volume=/run/user/1000/podman/podman.sock:/run/podman/podman.sock`.
  - **Exit Criteria:** `grep "/run/user/1000/podman/podman.sock" files/usr/share/bluefin-framework/bluefin-wtg/distrobox.ini` returns exit code 1 (no match found).

- [ ] **Task 1.3: Reroute Kubernetes Testing (If Applicable)**
      If kind (Kubernetes-in-Docker) or DinD is currently used in testing scripts, refactor the test suite to run kind directly on the immutable host, outside the agent's sandbox.
  - **Exit Criteria:** Grepping the test suite for `kind create cluster` confirms no nested virtualization is attempting to execute from within the unprivileged Distrobox container.

- [ ] **Task 1.4: Commit and Validate**
      Commit changes as: `refactor(security): remove host podman socket from distrobox workspace`
  - **Exit Criteria:** The GitHub Actions CI runner successfully builds the OCI image without syntax errors in the Distrobox configuration.

**🏁 Phase 1 Exit Criteria:** Upon spawning the newly built workspace, executing `podman ps` inside the Distrobox container must fail or return empty, mathematically proving the host daemon is isolated from the agent.

## ⭕ Round 2: Eradicating the Monolithic Pet VM

**Goal:** Replace the heavy, stateful UI testing environment with ephemeral, cattle-driven headless containers.

- [ ] **Task 2.1: Purge GUI Bloat**
      Edit the workspace Containerfile (`files/workspace/Containerfile` or relevant build files).
      REMOVE all package installations related to XFCE4, KasmVNC, and desktop-environment dependencies.
  - **Exit Criteria:** `grep -iE "xfce4|kasmvnc" files/workspace/Containerfile` returns exit code 1.

- [ ] **Task 2.2: Implement Playwright Automation**
      Update the UI testing documentation and scripts to utilize the official Microsoft Playwright Docker image instead of a heavy VM.
  - **Exit Criteria:** All VLM UI test scripts explicitly reference the headless Playwright runner rather than executing against a local GUI display server.

- [ ] **Task 2.3: Scaffold the Ephemeral Testing Command**
      Add a justfile recipe (e.g., `ujust test-vlm-ui`) that spins up the Playwright container idly:
      `podman run --rm --ipc=host mcr.microsoft.com/playwright:v1.58.2-noble npx playwright test`
  - **Exit Criteria:** `just --summary` lists `test-vlm-ui` as a valid, executable target.

- [ ] **Task 2.4: Commit and Validate**
      Commit changes as: `refactor(workspace): migrate from XFCE/KasmVNC pet to ephemeral playwright containers`
  - **Exit Criteria:** CI pipeline executes `ujust test-vlm-ui` and receives an exit code of 0 (successful test run in headless mode).

**🏁 Phase 2 Exit Criteria:** The final OCI image size is significantly reduced (verified via `podman images`), and UI tests execute headlessly without requiring a virtual framebuffer (Xvfb) or KasmVNC server.

## ⭕ Round 3: Declarative Dependency Management

**Goal:** Eradicate imperative bootstrapping (runtime installation) and lock dependencies to the image digest at build time.

- [ ] **Task 3.1: Audit .jules/setup.sh**
      Identify all imperative tool installations, specifically looking for `npm install -g @google/gemini-cli` and `pipx upgrade google-adk --ignore-installed`.
  - **Exit Criteria:** The `setup.sh` file is stripped of all global package installation commands.

- [ ] **Task 3.2: Relocate to Build-Time Configuration**
      Move these package installations into `recipes/recipe.yml` (via run modules) or the corresponding BlueBuild Containerfile script module.
  - **Exit Criteria:** The package definitions exist solely in the OCI build manifests.

- [ ] **Task 3.3: Implement Containerfile Additions**
      Ensure the following lines (or BlueBuild equivalents) are executed during the image compile phase:

  ```Dockerfile
  # Install global npm and pipx packages at BUILD time
  RUN npm install -g @google/gemini-cli
  RUN pipx install google-adk
  ```

  - **Exit Criteria:** CI build logs output the successful compilation and installation of both dependencies during the build layer cache step.

- [ ] **Task 3.4: Resolve PyYAML Conflicts**
      Remove any `--break-system-packages` or `--ignore-installed` flags used for Python packages.
      Implement a standard Python virtual environment (via pipx) to handle PyYAML safely.
  - **Exit Criteria:** `grep -E "--break-system-packages|--ignore-installed" .jules/setup.sh` returns exit code 1.

- [ ] **Task 3.5: Commit and Validate**
      Commit changes as: `build(deps): transition agent tooling to declarative build-time execution`
  - **Exit Criteria:** The GitHub Actions workflow completes successfully without pip dependency conflicts.

**🏁 Phase 3 Exit Criteria:** A freshly instantiated container from the new image digest must be able to run `gemini-cli --version` and `google-adk --version` with an exit code of 0 before any setup scripts are run by the user.

## ⭕ Round 4: OCI-Compliant Shared Memory (The dpkg-divert Fallacy)

**Goal:** Remove brittle bash wrappers masking memory exhaustion and utilize mathematically correct OCI runtime flags.

- [ ] **Task 4.1: Strip the dpkg-divert Hack**
      Locate the custom bash wrapper script in `/usr/local/bin` (or Containerfile) intended to force `--disable-dev-shm-usage` on Chromium.
      DELETE this script and revert any dpkg-divert routing.
  - **Exit Criteria:** The wrapper script no longer exists in the repository, and no commands exist that alias the Chromium binary.

- [ ] **Task 4.2: Update Container Execution Parameters**
      Modify the testing scripts (from Round 2) to allocate shared memory natively via Podman.
      Ensure testing containers use the `--shm-size` flag:
      `podman run --rm --shm-size=2g my-vlm-testing-container`
  - **Exit Criteria:** A static text search confirms `--shm-size=2g` (or greater) is present in the justfile executing the test suite.

- [ ] **Task 4.3: Final Commit and Verification**
      Commit changes as: `fix(runtime): replace shm wrappers with native OCI --shm-size allocation`
  - **Exit Criteria:** CI Pipeline successfully builds the image.

**🏁 Phase 4 Exit Criteria:** The agent executes a heavy end-to-end Playwright UI trace test. The test must pass without throwing a SIGBUS memory crash, and running `podman inspect` on the active test container must explicitly output a `ShmSize` configuration of 2147483648 bytes (2GB).

## 🏛️ Final Architect Verification

Upon satisfying the Exit Criteria for all 4 Rounds, the repository will enforce a pristine, mathematically verifiable OCI image. The desktop returns to an appliance state, the agent is quarantined without root access, and dependencies are locked to the SHA256 digest at build time.

- [x] Analyze the security vulnerability regarding insecure Helm download in `files/workspace/Containerfile`
- [x] Implement a checksum verification using `sha256sum` to validate the downloaded `get_helm.sh` script before execution.
- [x] Verify the implementation by running `bats tests/os_validation.bats` and verifying `Containerfile` changes.
- [x] Commit the changes using PR security standards.
- [x] Add Universal Blue / Project Bluefin philosophies to AGENTS.md
