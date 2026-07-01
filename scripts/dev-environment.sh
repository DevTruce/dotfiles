# ─────────────────────────────────────────
# Dev Environment
# ─────────────────────────────────────────

# -- Zsh Plugins (zinit)

setup_zsh_plugins() {
    section "Dev Environment - Zsh Plugins (zinit)"

    local ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"

    # directory existence alone doesn't prove a complete clone - an interrupted install
    # (network drop, Ctrl-C) can leave a partial .git dir that would otherwise be treated
    # as "already installed" forever; verify HEAD actually resolves and clean up if not
    if [ -d "$ZINIT_HOME" ] && ! git -C "$ZINIT_HOME" rev-parse HEAD >/dev/null 2>&1; then
        warn "Found an incomplete zinit install - removing it to retry."
        rm -rf "$ZINIT_HOME"
    fi

    if [ -d "$ZINIT_HOME" ]; then
        skip "zinit is already installed."
    else
        step "Installing zinit plugin manager"
        mkdir -p "$(dirname "$ZINIT_HOME")"
        local _log _pid
        _log="$(mktemp)"
        git clone --depth 1 --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" > "$_log" 2>&1 &
        _pid=$!
        _spinner "$_pid"
        if wait "$_pid"; then rm -f "$_log"
        else fail "${_LAST_STEP} failed."; echo ""; cat "$_log"; rm -f "$_log"; return 1; fi
        ok "zinit installed."
        note "Plugins will be downloaded on first shell launch."
    fi
}

# -- Node.js (nvm)

setup_nvm() {
    section "Dev Environment - Node.js (nvm)"

    NVM_DIR="${HOME}/.nvm"

    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        skip "nvm is already installed."
    else
        note "Skipping shell profile changes - your .zshrc already includes the nvm loader."
        step "Installing nvm (Node Version Manager)"
        # cloned at the latest release tag instead of piping nvm's install.sh through bash -
        # nvm.sh is just a shell function library and never touches shell profiles on its
        # own (only install.sh does that, which we no longer run), so this is both safer
        # (no remote script execution, just a tagged git checkout) and makes PROFILE=/dev/null
        # unnecessary
        local _nvm_log _nvm_pid
        _nvm_log="$(mktemp)"
        (
            _nvm_tag="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest \
                | grep '"tag_name"' | sed 's/.*"\(v[^"]*\)".*/\1/')"
            if [ -z "$_nvm_tag" ]; then
                echo "ERROR: could not determine nvm version (GitHub API rate limit?)" >&2
                exit 1
            fi
            git clone --depth 1 --branch "$_nvm_tag" --quiet https://github.com/nvm-sh/nvm.git "$NVM_DIR"
        ) > "$_nvm_log" 2>&1 &
        _nvm_pid=$!
        _spinner "$_nvm_pid"
        if wait "$_nvm_pid"; then
            rm -f "$_nvm_log"
        else
            fail "${_LAST_STEP} failed."
            echo ""
            cat "$_nvm_log"
            rm -f "$_nvm_log"
            return 1
        fi
        ok "nvm installed."
    fi

    # nvm references unbound variables internally, which trips set -u - every nvm
    # call below is bracketed in set +u/set -u for that reason, not just this source
    set +u
    \. "${NVM_DIR}/nvm.sh"
    set -u

    # nvm ls lists the lts/* alias once Node has actually been installed against it,
    # not just when the alias file exists - this is the real "is LTS present" check
    if nvm ls --no-colors 2>/dev/null | grep -q 'lts/\*'; then
        skip "Node.js LTS is already installed."
    else
        step "Installing the latest Node.js LTS release"
        local _node_log _node_pid
        _node_log="$(mktemp)"
        set +u
        (nvm install --lts) > "$_node_log" 2>&1 &
        _node_pid=$!
        _spinner "$_node_pid"
        if wait "$_node_pid"; then
            rm -f "$_node_log"
        else
            fail "${_LAST_STEP} failed."
            echo ""
            cat "$_node_log"
            rm -f "$_node_log"
            set -u
            return 1
        fi
        # nvm install --lts doesn't switch the active version on its own
        if ! nvm use lts/* >/dev/null 2>&1; then
            fail "Failed to activate Node.js LTS after install."
            set -u
            return 1
        fi
        set -u
        local _node_ver _npm_ver
        _node_ver="$(node --version 2>/dev/null || echo "unknown")"
        _npm_ver="$(npm --version 2>/dev/null || echo "unknown")"
        ok "Node.js LTS installed."
        note "Node ${_node_ver}  ·  npm ${_npm_ver}"

        set +u
        nvm alias default 'lts/*' >/dev/null
        set -u
        ok "Default alias set to lts/*."
    fi
}

# -- pnpm

setup_pnpm() {
    section "Dev Environment - pnpm"

    set +u
    [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && \. "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    set -u

    if command -v pnpm >/dev/null 2>&1; then
        skip "pnpm is already installed."
    else
        step "Installing pnpm"
        _npm install -g pnpm
        ok "pnpm installed."
    fi
}

# -- Claude Code CLI

setup_claude() {
    section "Dev Environment - Claude Code CLI"

    set +u
    [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ] && \. "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    set -u

    if command -v claude >/dev/null 2>&1; then
        skip "Claude Code is already installed."
    else
        step "Installing Claude Code CLI"
        _npm install -g @anthropic-ai/claude-code
        ok "Claude Code installed."
    fi
}

# -- bats (test runner for this repo's own scripts)

setup_bats() {
    section "Dev Environment - bats (test runner)"

    if command -v bats >/dev/null 2>&1; then
        skip "bats is already installed."
    else
        step "Installing bats"
        case "$OS" in
            macos) _brew install bats-core ;;
            *)     _apt install -y bats ;;
        esac
        ok "bats installed."
    fi
}

# -- shellcheck (linter for this repo's own scripts)

setup_shellcheck() {
    section "Dev Environment - shellcheck"

    if command -v shellcheck >/dev/null 2>&1; then
        skip "shellcheck is already installed."
    else
        step "Installing shellcheck"
        case "$OS" in
            macos) _brew install shellcheck ;;
            *)     _apt install -y shellcheck ;;
        esac
        ok "shellcheck installed."
    fi
}
