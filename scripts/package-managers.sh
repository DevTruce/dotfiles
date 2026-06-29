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
        step "Installing Homebrew"
        local _brew_log _brew_pid
        _brew_log="$(mktemp)"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > "$_brew_log" 2>&1 &
        _brew_pid=$!
        _spinner "$_brew_pid"
        if wait "$_brew_pid"; then
            rm -f "$_brew_log"
            ok "Homebrew installed."
        else
            cat "$_brew_log"
            rm -f "$_brew_log"
            warn "Homebrew installation encountered errors — see output above."
            return 1
        fi
    fi

    step "Fetching latest Homebrew updates"
    _brew update
    ok "Homebrew updated."

    step "Upgrading outdated packages"
    # || true prevents a single failed formula from aborting the installer
    _brew upgrade || true
    ok "Packages up to date."
}

# -- apt (Linux)

setup_apt() {
    section "Package Manager — apt"

    if [ "$OS" = "macos" ]; then
        warn "setup_apt is only supported on Linux."
        return 1
    fi

    sudo -v

    step "Refreshing package lists"
    _apt update
    ok "Package lists refreshed."

    if ! command -v curl >/dev/null 2>&1; then
        step "Installing curl"
        _apt install -y curl
        ok "curl installed."
    fi

    step "Upgrading outdated packages"
    _apt upgrade -y
    ok "Packages up to date."
}
