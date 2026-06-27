# ─────────────────────────────────────────
# Security
# ─────────────────────────────────────────

# -- SSH Key

setup_ssh_key() {
    section "Security — SSH Key"

    SSH_KEY="${HOME}/.ssh/id_ed25519"

    if [ -f "${SSH_KEY}.pub" ]; then
        echo "  SSH key already exists at ${SSH_KEY}.pub — skipping generation."
    else
        echo "  No SSH key found. Generating a new ed25519 key..."
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(hostname)")"
        echo "  SSH key generated."
    fi

    echo ""
    echo "  Fingerprint:"
    ssh-keygen -lf "${SSH_KEY}.pub"
    echo ""
    echo "  Public key (you will need this for GitHub — see the todo list at the end):"
    echo ""
    cat "${SSH_KEY}.pub"
    echo ""
}

# -- GPG Key

setup_gpg_key() {
    section "Security — GPG Key"

    if gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -q '^sec'; then
        echo "  A GPG secret key already exists — skipping generation."
    else
        GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
        GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"

        if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
            echo "  No GPG key found, but git user.name/user.email are not configured yet."
            echo "  Update Common/.gitconfig with your name and email, then re-run this script."
            return
        fi

        echo "  No GPG key found. Generating a key for ${GIT_NAME} <${GIT_EMAIL}>..."
        echo "  You will be prompted to enter a passphrase to protect your private key."
        # passphrase is entered interactively via pinentry — never stored in the script,
        # shell history, or the process list
        gpg --quick-gen-key "${GIT_NAME} <${GIT_EMAIL}>" default default
        echo "  GPG key generated."
    fi

    echo ""
    echo "  GPG secret keys on this machine:"
    gpg --list-secret-keys --keyid-format=long
    echo ""
    echo "  Key ID(s) — you will need these for .gitconfig and GitHub (see the todo list at the end):"
    echo ""
    gpg --list-secret-keys --keyid-format=long | awk -F'/' '/^sec/{print $2}' | awk '{print $1}'
    echo ""
}

# -- GPG Agent

setup_gpg_agent_conf() {
    section "Security — GPG Agent"

    mkdir -p "${HOME}/.gnupg"
    GPG_AGENT_CONF="${HOME}/.gnupg/gpg-agent.conf"

    case "$OS" in
        macos)
            if ! command -v pinentry-mac >/dev/null 2>&1; then
                echo "  Installing pinentry-mac..."
                brew install pinentry-mac
            fi
            PINENTRY_PATH="$(command -v pinentry-mac)"
            ;;
        *)
            if ! command -v pinentry-curses >/dev/null 2>&1; then
                echo "  Installing pinentry-curses..."
                sudo apt install pinentry-curses -y
            fi
            PINENTRY_PATH="$(command -v pinentry-curses)"
            ;;
    esac

    if grep -q "pinentry-program ${PINENTRY_PATH}" "$GPG_AGENT_CONF" 2>/dev/null; then
        echo "  gpg-agent.conf is already configured (pinentry: ${PINENTRY_PATH})."
    else
        echo "  Writing gpg-agent.conf..."
        echo "  Pinentry: ${PINENTRY_PATH}"
        cat > "$GPG_AGENT_CONF" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program ${PINENTRY_PATH}
EOF
        echo "  Restarting gpg-agent to apply new configuration..."
        gpgconf --kill gpg-agent 2>/dev/null || true
        echo "  gpg-agent restarted."
    fi
}

# -- Keychain

setup_keychain() {
    section "Security — Keychain (ssh-agent persistence)"

    echo "  keychain keeps your SSH key loaded across terminal sessions,"
    echo "  so you are not prompted for your passphrase on every new tab."
    echo ""

    if command -v keychain >/dev/null 2>&1; then
        echo "  keychain is already installed."
    else
        echo "  Installing keychain..."
        sudo apt install keychain -y
        echo "  keychain installed."
    fi
}
