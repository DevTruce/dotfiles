# ─────────────────────────────────────────
# Security
# ─────────────────────────────────────────

# -- SSH Key

setup_ssh_key() {
    section "Security — SSH Key"

    local SSH_KEY="${HOME}/.ssh/id_ed25519"

    if [ -f "${SSH_KEY}.pub" ]; then
        skip "SSH key already exists at ${SSH_KEY}.pub — skipping generation."
    else
        step "Generating a new ed25519 SSH key..."
        note "You will be prompted to set a passphrase to protect your private key."
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        ssh-keygen -t ed25519 -f "$SSH_KEY" -C "$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(hostname)")"
        echo ""
        ok "SSH key generated."
    fi

    echo ""
    note "Fingerprint (for your records):"
    echo ""
    ssh-keygen -lf "${SSH_KEY}.pub"
    echo ""
    note "Public key (copy this to GitHub → Settings → SSH and GPG Keys → New SSH key):"
    echo ""
    cat "${SSH_KEY}.pub"
    echo ""
}

# -- GPG Key

setup_gpg_key() {
    section "Security — GPG Key"

    if gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -q '^sec'; then
        skip "A GPG secret key already exists — skipping generation."
    else
        local GIT_NAME GIT_EMAIL
        GIT_NAME="$(git config --file "${HOME}/.gitconfig.local" user.name 2>/dev/null || true)"
        GIT_EMAIL="$(git config --file "${HOME}/.gitconfig.local" user.email 2>/dev/null || true)"

        if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
            warn "git user.name/user.email are not configured yet."
            note "Re-run the installer so setup_git can prompt for your identity first."
            return
        fi

        step "Generating a GPG key for ${GIT_NAME} <${GIT_EMAIL}>..."
        note "You will be prompted to enter a passphrase to protect your private key."
        echo ""
        # passphrase is entered interactively via pinentry — never stored in the script,
        # shell history, or the process list
        gpg --quick-gen-key "${GIT_NAME} <${GIT_EMAIL}>" default default
        ok "GPG key generated."
    fi

    local key_id
    key_id="$(gpg --list-secret-keys --keyid-format=long | awk -F'/' '/^sec/{print $2}' | awk '{print $1}' | head -1)"

    git config --file "${HOME}/.gitconfig.local" user.signingkey "${key_id}"
    git config --file "${HOME}/.gitconfig.local" commit.gpgsign true
    git config --file "${HOME}/.gitconfig.local" tag.gpgsign true

    echo ""
    note "Key ID (written to ~/.gitconfig.local):"
    echo ""
    echo "  ${key_id}"
    echo ""
    note "Public key (copy this to GitHub → Settings → SSH and GPG Keys → New GPG key):"
    echo ""
    gpg --armor --export "${key_id}"
    echo ""
}

# -- GPG Agent

setup_gpg_agent_conf() {
    section "Security — GPG Agent"

    mkdir -p "${HOME}/.gnupg"
    chmod 700 "${HOME}/.gnupg"
    local GPG_AGENT_CONF="${HOME}/.gnupg/gpg-agent.conf"
    local PINENTRY_PATH

    case "$OS" in
        macos)
            if ! command -v pinentry-mac >/dev/null 2>&1; then
                step "Installing pinentry-mac..."
                brew install pinentry-mac
                ok "pinentry-mac installed."
            fi
            PINENTRY_PATH="$(command -v pinentry-mac)"
            ;;
        *)
            if ! command -v pinentry-curses >/dev/null 2>&1; then
                step "Installing pinentry-curses..."
                sudo apt install pinentry-curses -y
                ok "pinentry-curses installed."
            fi
            PINENTRY_PATH="$(command -v pinentry-curses)"
            ;;
    esac

    if grep -q "pinentry-program ${PINENTRY_PATH}" "$GPG_AGENT_CONF" 2>/dev/null; then
        skip "gpg-agent.conf is already configured (pinentry: ${PINENTRY_PATH})."
    else
        step "Writing gpg-agent.conf..."
        note "Pinentry: ${PINENTRY_PATH}"
        cat > "$GPG_AGENT_CONF" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program ${PINENTRY_PATH}
EOF
        step "Restarting gpg-agent to apply new configuration..."
        gpgconf --kill gpg-agent 2>/dev/null || true
        ok "gpg-agent configured and restarted."
    fi
}

# -- Keychain

setup_keychain() {
    section "Security — Keychain (ssh-agent persistence)"

    note "keychain keeps your SSH key loaded across terminal sessions,"
    note "so you are not prompted for your passphrase on every new tab."
    echo ""

    if command -v keychain >/dev/null 2>&1; then
        skip "keychain is already installed."
    else
        step "Installing keychain..."
        sudo apt install keychain -y
        ok "keychain installed."
    fi
}
