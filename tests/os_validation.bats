#!/usr/bin/env bats

# bluefin-wtg Validation Suite
# This suite verifies the integrity of the bluefin-wtg image and its student workspace configuration.
# It is designed to run both locally during development/CI and on the LIVE Framework hardware.

setup() {
    # Detect if we are running locally/in CI versus on the live system
    if [ -d "files/usr/share/bluefin-wtg" ]; then
        export IS_LOCAL_CI=true
        export DISTROBOX_INI="files/usr/share/bluefin-wtg/distrobox.ini"
        export RECIPE_FILE="recipes/recipe.yml"
        export FLATPAKS_FILE="recipes/flatpaks.yml"
    else
        export IS_LOCAL_CI=false
        export DISTROBOX_INI="/usr/share/bluefin-wtg/distrobox.ini"
        export RECIPE_FILE="/usr/etc/bluebuild/recipes/recipe.yml"
        export FLATPAKS_FILE="/usr/etc/bluebuild/recipes/flatpaks.yml"
    fi
}

@test "Distrobox configuration file exists" {
    [ -f "$DISTROBOX_INI" ]
}

@test "Distrobox configuration uses the declarative agv-container image" {
    grep -q "image=ghcr.io/wtg-codes/agv-container:latest" "$DISTROBOX_INI"
}





@test "Kernel arguments are actively applied (simulated)" {
    grep -q "amd_pstate=active" "$RECIPE_FILE"
}

@test "Workspace Containerfile logic check" {
    skip "Workspace Containerfile deleted"
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

@test "Workspace Containerfile performs sha256 validation for kubectl" {
    skip "Workspace Containerfile deleted"
}
