# ─────────────────────────────────────────
# Package Managers
# ─────────────────────────────────────────

# -- Homebrew (macOS)

setup_homebrew() {
    section "Package Manager - Homebrew"

    # install.sh only ever calls this from setup_macos, where OS is already guaranteed
    # correct - this guard only matters if someone runs `bash run.sh setup_homebrew`
    # directly on Linux
    if [ "$OS" != "macos" ]; then
        warn "setup_homebrew is only supported on macOS."
        return 1
    fi

    if command -v brew >/dev/null 2>&1; then
        skip "Homebrew is already installed."
    else
        step "Installing Homebrew"
        # pinned to a specific reviewed commit rather than HEAD (Homebrew/install has no
        # version tags) so this always runs the same, known-good installer instead of
        # whatever happens to be live upstream; bump deliberately after reviewing the diff:
        # https://github.com/Homebrew/install/compare/db5debe9b6dac00d87e6a2277a5e2b6c2b0fb773...HEAD
        local _brew_install_sha="db5debe9b6dac00d87e6a2277a5e2b6c2b0fb773"
        local _brew_log _brew_pid
        _brew_log="$(mktemp)"
        /bin/bash -c "$(curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/${_brew_install_sha}/install.sh")" > "$_brew_log" 2>&1 &
        _brew_pid=$!
        _spinner "$_brew_pid"
        if wait "$_brew_pid"; then
            rm -f "$_brew_log"
            ok "Homebrew installed."
        else
            fail "${_LAST_STEP} failed."
            echo ""
            cat "$_brew_log"
            rm -f "$_brew_log"
            return 1
        fi

        # on Apple Silicon, Homebrew installs to /opt/homebrew which is not in PATH yet
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi

    step "Fetching latest Homebrew updates"
    _brew update
    ok "Homebrew updated."

    step "Upgrading outdated packages"
    # || true prevents a single failed formula from aborting the installer;
    # _brew already prints fail() on error, so only print ok on success
    if _brew upgrade; then
        ok "Packages up to date."
    fi
}

# -- apt (Linux)

setup_apt() {
    section "Package Manager - apt"

    # install.sh only ever calls this from setup_linux, where OS is already guaranteed
    # correct - this guard only matters if someone runs `bash run.sh setup_apt`
    # directly on macOS
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
    # if-wrapped so a single held-back/broken package doesn't abort the whole installer
    # (matches the _brew upgrade guard above); _apt already prints fail() on error
    if _apt upgrade -y; then
        ok "Packages up to date."
    fi
}
