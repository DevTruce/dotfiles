# ─────────────────────────────────────────
# Package Managers
# ─────────────────────────────────────────

# -- Homebrew (macOS)

setup_homebrew() {
    section "Package Manager — Homebrew"

    if [ "$OS" != "macos" ]; then
        warn "setup_homebrew is only supported on macOS."
        return 1
    fi

    if command -v brew >/dev/null 2>&1; then
        skip "Homebrew is already installed."
    else
        step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        ok "Homebrew installed."
    fi

    step "Fetching latest Homebrew updates..."
    brew update

    step "Upgrading outdated packages..."
    # || true prevents a single failed formula from aborting the installer
    brew upgrade || true
    ok "Packages up to date."
}

# -- apt (Linux)

setup_apt() {
    section "Package Manager — apt"

    if [ "$OS" = "macos" ]; then
        warn "setup_apt is only supported on Linux."
        return 1
    fi

    step "Refreshing package lists..."
    sudo apt-get update

    if ! command -v curl >/dev/null 2>&1; then
        step "Installing curl..."
        sudo apt-get install curl -y
        ok "curl installed."
    fi

    step "Upgrading outdated packages..."
    sudo apt-get upgrade -y
    ok "Packages up to date."
}
