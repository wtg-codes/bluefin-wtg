# Pull and assemble the agy-box developer environment
setup-workspace:
    @echo "Pulling and creating the agy-box workspace via Distrobox..."
    distrobox assemble create --file /usr/share/bluefin-wtg/distrobox.ini
    @echo "Done! Type 'distrobox enter agy-box' to begin (or use 'agy-box-manager' for isolated per-box homes)."
