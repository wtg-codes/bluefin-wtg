#!/usr/bin/env bats

# bluefin-wtg Validation Suite
# This suite verifies the integrity of the bluefin-wtg image and its developer workspace configuration.
# It is designed to run both locally during development/CI and on booted hardware.

setup() {
    # Detect if we are running locally/in CI versus on the live system
    if [ -d "files/usr/share/bluefin-wtg" ]; then
        export IS_LOCAL_CI=true
        export DISTROBOX_INI="files/usr/share/bluefin-wtg/distrobox.ini"
        export JUST_FILE="files/usr/share/ublue-os/just/60-bluefin-wtg.just"
        export RECIPE_FILE="recipes/recipe.yml"
        export FLATPAKS_FILE="recipes/flatpaks.yml"
    else
        export IS_LOCAL_CI=false
        export DISTROBOX_INI="/usr/share/bluefin-wtg/distrobox.ini"
        export JUST_FILE="/usr/share/ublue-os/just/60-bluefin-wtg.just"
        export RECIPE_FILE="/usr/etc/bluebuild/recipes/recipe.yml"
        export FLATPAKS_FILE="/usr/etc/bluebuild/recipes/flatpaks.yml"
    fi
}

@test "Distrobox configuration file exists" {
    [ -f "$DISTROBOX_INI" ]
}

@test "Distrobox configuration uses the declarative agy-box image" {
    grep -q '^\[agy-box\]$' "$DISTROBOX_INI"
    grep -q '^image=ghcr.io/wtg-codes/agy-box:latest$' "$DISTROBOX_INI"
    grep -q '^init=false$' "$DISTROBOX_INI"
    grep -q '^root=false$' "$DISTROBOX_INI"
    ! grep -q 'agv-container' "$DISTROBOX_INI"
}

@test "Kernel arguments are actively applied (simulated)" {
    grep -q "amd_pstate=active" "$RECIPE_FILE"
}

@test "ujust setup-workspace targets the agy-box Distrobox manifest" {
    [ -f "$JUST_FILE" ]
    grep -q '/usr/share/bluefin-wtg/distrobox.ini' "$JUST_FILE"
    grep -q 'distrobox enter agy-box' "$JUST_FILE"
    ! grep -q 'agv-container' "$JUST_FILE"
}

@test "GitHub Actions workflows resolve Node 20 deprecation" {
    # This test only makes sense in a local/CI context where the source repo is present
    if [ "$IS_LOCAL_CI" = "false" ]; then
        skip "Source files not available on live system"
    fi
    # Ensure no core actions are pinned to versions lower than Node 24 baseline
    # We check for @v followed by a single digit 0-3 for actions/checkout
    ! grep -r "actions/checkout@v[0-3]" .github/workflows/
    # Ensure FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 is set
    grep -r "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true" .github/workflows/
}

@test "Recipe contains default-flatpaks module configuration" {
    grep -q "type: default-flatpaks" "$FLATPAKS_FILE"
}

@test "Recipe flatpaks configuration contains expected communication apps" {
    grep -q "com.slack.Slack" "$FLATPAKS_FILE"
    grep -q "com.discordapp.Discord" "$FLATPAKS_FILE"
}

@test "Recipe flatpaks configuration includes developer tools" {
    grep -q "com.visualstudio.code" "$FLATPAKS_FILE"
    grep -q "com.google.Chrome" "$FLATPAKS_FILE"
}

@test "fwupd service is active (Framework hardware updates)" {
    if [ "$IS_LOCAL_CI" = "true" ]; then
        skip "fwupd check is only run on live system"
    fi
    # This must be run on the booted machine
    systemctl is-active fwupd.service || systemctl is-enabled fwupd.service
}

@test "Kernel arguments are actively applied to the system" {
    if [ "$IS_LOCAL_CI" = "true" ]; then
        skip "Live kernel arguments are only checked on live system"
    fi
    # Instead of checking the bootc toml files, we check the actual live kernel arguments
    run cat /proc/cmdline
    [[ "$output" == *"amd_pstate=active"* ]]
    [[ "$output" == *"amdgpu.sg_display=0"* ]]
}

@test "Cosign public key, scheduled keepalive, and 40-char SHA workflow pins are enforced" {
    if [ "$IS_LOCAL_CI" = "false" ]; then
        skip "Source files not available on live system"
    fi
    [ -s "cosign.pub" ]
    [ -f ".github/workflows/keepalive.yml" ]
    grep -Eq '^permissions:' .github/workflows/keepalive.yml
    local unpinned
    unpinned="$(grep -rnE '^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*[^./]' .github/workflows/*.yml | grep -vE '@[0-9a-f]{40}([[:space:]]|$)' || true)"
    [ -z "$unpinned" ]
}
