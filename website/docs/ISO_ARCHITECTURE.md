# ISO Architecture: Antigravity ISO Forge

This document outlines the architecture and implementation phases for generating bootable Live ISO images for **bluefin-wtg**.

## Technical Flow

The ISO generation process follows a "Container-to-Installer" (C2I) pattern:

1. **Source:** The cryptographically signed OCI image from GHCR.
2. **Generator:** GitHub Action utilizing `ghcr.io/jasonn3/build-container-installer`.
3. **Output:** A bootable ISO 9660 image with EFI support, configured to pull the specific digest of the image.

## Implementation Phases

### Phase 1: CI ISO Generation

- **Goal:** Automate the creation of an ISO artifact whenever a new OCI image is pushed to `main`.
- **Logic:** A new job `iso-build` will depend on the successful completion of the `bluebuild` job.
- **TDD Verification:**
  - The CI job must fail if the ISO generation tool returns a non-zero exit code.
  - The resulting artifact must be uploaded and verified for a minimum size (e.g., > 1GB).

### Phase 2: Virtual Smoke Test (Headless Boot)

- **Goal:** Ensure the ISO is bootable before physical distribution.
- **Logic:** Use QEMU in the CI runner to boot the ISO.
- **TDD Verification:**
  - A script will monitor the serial output of the QEMU instance.
  - **Success Condition:** Detecting the string `GRUB_LOADING` or `Kernel command line` within a 120-second timeout.

### Phase 3: Payload Integrity Verification

- **Goal:** Confirm the ISO contains the correct configuration for the immutable OS.
- **Logic:** Mount the ISO in the CI runner and inspect the configuration files.
- **TDD Verification (BATS):**
  - `test "ISO is UEFI compatible"`: Check for `/EFI/BOOT/BOOTX64.EFI`.
  - `test "ISO uses signed image digest"`: Grep the installer config to ensure it references the specific SHA256 digest produced by the build job.

### Phase 4: Manual Validation (Physical Hardware)

- **Goal:** Final sign-off on the Framework 13 Laptop (Ryzen AI 9 HX 370).
- **Logic:** Flash the ISO to a USB stick and boot on the target hardware.
- **Checklist:**
  - [ ] **GRUB Rendering:** Menu renders correctly at 2.8K resolution without artifacts.
  - [ ] **Kernel Arguments:** Verify `amd_pstate=active` and `amdgpu.sg_display=0` are present in `/proc/cmdline`.
  - [ ] **Input Devices:** Touchpad (including gestures) and keyboard are functional in the Live environment.
  - [ ] **Connectivity:** Wi-Fi 6E module is recognized and can scan for networks.
  - [ ] **Display Scaling:** GNOME (or target DE) correctly applies 150% fractional scaling by default.
  - [ ] **TDI Compliance:** `tests/os_validation.bats` passes when executed manually on the live system.

## TDD Test Definitions (Pseudo-Code)

### BATS: ISO Metadata Verification (`tests/iso_metadata.bats`)

```bash
@test "ISO file exists and is not empty" {
    [ -f "output/antigravity.iso" ]
    [ $(stat -c%s "output/antigravity.iso") -gt 1000000000 ]
}

@test "ISO contains EFI bootloader" {
    mount -o loop output/antigravity.iso /mnt
    [ -f "/mnt/EFI/BOOT/BOOTX64.EFI" ]
    umount /mnt
}

@test "ISO installer references the correct OCI digest" {
    mount -o loop output/antigravity.iso /mnt
    grep -q "sha256:${EXPECTED_DIGEST}" /mnt/loader/entries/install.conf
    umount /mnt
}
```

### QEMU Smoke Test (`scripts/smoke-test-iso.sh`)

```bash
#!/bin/bash
qemu-system-x86_64 -m 2G -cdrom output/antigravity.iso -nographic -serial stdio > boot_log.txt &
QEMU_PID=$!

timeout 120s bash -c 'until grep -q "Welcome to Bluefin" boot_log.txt; do sleep 1; done'
RESULT=$?

kill $QEMU_PID
exit $RESULT
```

## CI/CD Pipeline Modifications (`.github/workflows/build.yml`)

The following additions are planned for the `build.yml` workflow:

```yaml
jobs:
  # ... existing bluebuild job ...

  iso-build:
    name: Build and Test ISO
    needs: bluebuild
    runs-on: ubuntu-latest
    if: github.event_name != 'pull_request'
    steps:
      - uses: actions/checkout@v4

      - name: Generate ISO
        uses: jasonn3/build-container-installer@main
        with:
          image_name: bluefin-wtg
          image_repo: ghcr.io/${{ github.repository }}
          image_tag: latest
          # Ensure we use the digest from the bluebuild output
          image_digest: ${{ needs.bluebuild.outputs.digest }}

      - name: Run ISO Metadata Tests
        run: bats tests/iso_metadata.bats

      - name: Run QEMU Smoke Test
        run: ./scripts/smoke-test-iso.sh

      - name: Upload ISO Artifact
        uses: actions/upload-artifact@v4
        with:
          name: antigravity-live-iso
          path: output/*.iso
```
