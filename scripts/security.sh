# ─────────────────────────────────────────
# Security
# ─────────────────────────────────────────

# -- GPG Tools

setup_gpg_tools() {
    section "Security — GPG Tools"

    if command -v gpg >/dev/null 2>&1; then
        skip "gpg is already installed."
    else
        step "Installing gpg"
        case "$OS" in
            macos) _brew install gnupg ;;
            *)     _apt install -y gnupg ;;
        esac
        ok "gpg installed."
    fi
}

# -- SSH Key

setup_ssh_key() {
    section "Security — SSH Key"

    local SSH_KEY="${HOME}/.ssh/id_ed25519"

    if [ -f "${SSH_KEY}.pub" ]; then
        skip "SSH key already exists at ${SSH_KEY}.pub — skipping generation."
    else
        step "Generating a new ed25519 SSH key"
        mkdir -p "${HOME}/.ssh"
        chmod 700 "${HOME}/.ssh"
        local _keygen_log
        _keygen_log="$(mktemp)"
        if ssh-keygen -t ed25519 -f "$SSH_KEY" -C "$(git config --global user.email 2>/dev/null || echo "$(whoami)@$(hostname)")" > "$_keygen_log" 2>&1; then
            rm -f "$_keygen_log"
            ok "SSH key generated."
        else
            cat "$_keygen_log"
            rm -f "$_keygen_log"
            return 1
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
    fi

    if [ "$OS" != "macos" ] && command -v gpgconf >/dev/null 2>&1; then
        local _agent_sock
        _agent_sock="$(gpgconf --list-dirs agent-ssh-socket)"
        export GPG_TTY="$(tty)"
        gpgconf --launch gpg-agent 2>/dev/null
        gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

        local _fingerprint
        _fingerprint="$(ssh-keygen -lf "${SSH_KEY}.pub" 2>/dev/null | awk '{print $2}')"
        if [ -n "$_fingerprint" ] && SSH_AUTH_SOCK="$_agent_sock" ssh-add -l 2>/dev/null | grep -qF "$_fingerprint"; then
            skip "SSH key already registered with gpg-agent."
        else
            step "Registering SSH key with gpg-agent for passphrase caching"
            if SSH_AUTH_SOCK="$_agent_sock" ssh-add "$SSH_KEY"; then
                ok "SSH key registered. Passphrase cached for 8 hours."
            else
                warn "Could not register SSH key with gpg-agent automatically."
                note "Open a new terminal and run: ssh-add ~/.ssh/id_ed25519"
            fi
        fi
    fi
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

        step "Generating a GPG key for ${GIT_NAME} <${GIT_EMAIL}>"
        local _gpg_log
        _gpg_log="$(mktemp)"
        # passphrase is entered interactively via pinentry — never stored in the script,
        # shell history, or the process list
        if gpg --quiet --no-tty --quick-gen-key "${GIT_NAME} <${GIT_EMAIL}>" ed25519 default > "$_gpg_log" 2>&1; then
            rm -f "$_gpg_log"
            ok "GPG key generated."
        else
            cat "$_gpg_log"
            rm -f "$_gpg_log"
            return 1
        fi
    fi

    local key_id
    key_id="$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | awk -F'/' '/^sec/{print $2}' | awk '{print $1}' | head -1)"

    if [ -z "$key_id" ]; then
        warn "Could not extract GPG key ID — skipping signing config."
        return 1
    fi

    local existing_signingkey
    existing_signingkey="$(git config --file "${HOME}/.gitconfig.local" user.signingkey 2>/dev/null || true)"

    if [ "$existing_signingkey" = "$key_id" ]; then
        skip "GPG signing config already set in ~/.gitconfig.local (key: ${key_id})."
    else
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
        gpg --armor --export "${key_id}" 2>/dev/null
        echo ""
    fi
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
                step "Installing pinentry-mac"
                _brew install pinentry-mac
                ok "pinentry-mac installed."
            fi
            PINENTRY_PATH="$(command -v pinentry-mac)"
            ;;
        *)
            if ! command -v pinentry-curses >/dev/null 2>&1; then
                step "Installing pinentry-curses"
                _apt install -y pinentry-curses
                ok "pinentry-curses installed."
            fi
            PINENTRY_PATH="$(command -v pinentry-curses)"
            ;;
    esac

    local _skip_check
    case "$OS" in
        macos)
            _skip_check="$(grep -q "pinentry-program ${PINENTRY_PATH}" "$GPG_AGENT_CONF" 2>/dev/null && echo yes || echo no)"
            ;;
        *)
            _skip_check="$(grep -q "enable-ssh-support" "$GPG_AGENT_CONF" 2>/dev/null && grep -q "pinentry-program ${PINENTRY_PATH}" "$GPG_AGENT_CONF" 2>/dev/null && echo yes || echo no)"
            ;;
    esac

    if [ "$_skip_check" = "yes" ]; then
        skip "gpg-agent.conf is already configured (pinentry: ${PINENTRY_PATH})."
    else
        step "Writing gpg-agent.conf"
        note "Pinentry: ${PINENTRY_PATH}"
        case "$OS" in
            macos)
                cat > "$GPG_AGENT_CONF" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program ${PINENTRY_PATH}
EOF
                ;;
            *)
                cat > "$GPG_AGENT_CONF" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program ${PINENTRY_PATH}
enable-ssh-support
EOF
                ;;
        esac
        step "Restarting gpg-agent to apply new configuration"
        gpgconf --kill gpg-agent 2>/dev/null || true
        gpgconf --launch gpg-agent 2>/dev/null
        ok "gpg-agent configured and restarted."
    fi
}

