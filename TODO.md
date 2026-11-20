# TODO — bluefin-wtg

> **Last updated:** 2026-11-20 · Branch: `fix/wave1-iso-cosign-and-keepalive`

## Wave 1.4 — OS Build, ISO Zero-Trust Gate & Keepalive

### Completed in `fix/wave1-iso-cosign-and-keepalive`
- [x] **Re-enable `disabled_inactivity` scheduled workflows:** Re-enabled `bluebuild`, `Build Weekly Standard ISO`, and `Build Monthly Live ISO` on `wtg-codes/bluefin-wtg`.
- [x] **Fix `bluebuild` Fedora 45 / GNOME Mutter schema failure:** Removed obsolete `experimental-features=['scale-monitor-framebuffer']` under `[org.gnome.mutter]` in `files/gschema-overrides/zz1-org.gnome.mutter.gschema.override` (`org.gnome.mutter` removed the `experimental-features` key upstream after fractional scaling graduated).
- [x] **Fix Cosign v3 signature verification gate in ISO workflows:** Updated `Verify Image Signature (Zero Trust Gate)` in `.github/workflows/build-weekly-iso.yml` and `.github/workflows/build-live-iso.yml` to pass `--insecure-ignore-tlog=true` (with `--new-bundle-format=false` fallback for legacy Cosign v2 OCI `.sig` artifacts from `blue-build/github-action@v1`) while strictly enforcing `cosign.pub` key verification.
- [x] **Replace hardcoded Fedora `version: 41` in ISO workflows:** Added dynamic Fedora major version detection from the built image's `ostree.linux` / `org.opencontainers.image.version` OCI labels via `skopeo inspect` (with safe fallback to `45`).
- [x] **Add 45-day scheduled workflow keepalive (`.github/workflows/keepalive.yml`):** Added least-privilege scheduled keepalive (`contents: read`, job-scoped `actions: write`) to refresh workflow enablement before GitHub's 60-day `disabled_inactivity` freeze.
- [x] **Pin GitHub Actions to 40-char commit SHAs & enforce least-privilege `permissions:`:** Pinned all workflow `uses:` references across `.github/workflows/*.yml` to full 40-char commit SHAs and set `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`.
- [x] **Migrate declarative Distrobox workspace from retired `agv-container` to `agy-box` (`#177`):** Updated `files/usr/share/bluefin-wtg/distrobox.ini` (`[agy-box]`, `image=ghcr.io/wtg-codes/agy-box:latest`, `init=false`, `root=false`), `files/usr/share/ublue-os/just/60-bluefin-wtg.just` (`ujust setup-workspace`), and `tests/os_validation.bats` (replacing obsolete Containerfile stubs with active `agy-box`, `cosign.pub`, `keepalive.yml`, and 40-char SHA workflow-pin assertions).
- [x] **OSS compliance documentation:** Added root `TODO.md`, `CHANGELOG.md`, and private vulnerability reporting guidance in `SECURITY.md` (preserving existing Apache-2.0 `LICENSE`).

### Pending Hardware Check (Before Image-Name Alignment)
- [ ] **Confirm canonical OCI image name (`wtgos` vs `bluefin-wtg`) on Framework Laptop 13:** Run `rpm-ostree status` on the physical Framework 13 laptop to confirm whether it is booted against `ghcr.io/wtg-codes/wtgos:latest` (currently built by `recipes/recipe.yml`, `build.yml`, and both ISO workflows) or `ghcr.io/wtg-codes/bluefin-wtg:latest` (currently referenced in `README.md` and `website/`). Once confirmed, align `recipes/recipe.yml`, `README.md`, `website/`, and `.github/workflows/*.yml` in a dedicated follow-up PR.

## Appliance Architecture Backlog
- See [`website/docs/todo.md`](website/docs/todo.md) for the multi-round Distrobox / TDI appliance roadmap.
