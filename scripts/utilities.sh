# ─────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────

# -- tree

setup_tree() {
    section "Utilities — tree"

    if command -v tree >/dev/null 2>&1; then
        skip "tree is already installed."
    else
        step "Installing tree..."
        case "$OS" in
            macos) brew install tree ;;
            *)     sudo apt install tree -y ;;
        esac
        ok "tree installed."
    fi
}

# -- fzf

setup_fzf() {
    section "Utilities — fzf"

    if command -v fzf >/dev/null 2>&1; then
        skip "fzf is already installed."
    else
        step "Installing fzf..."
        case "$OS" in
            macos)
                brew install fzf
                ;;
            *)
                # apt ships fzf 0.29–0.44 which predates `fzf --zsh`; pull latest from GitHub
                local _arch _version
                case "$(uname -m)" in
                    aarch64) _arch="arm64" ;;
                    *)       _arch="amd64" ;;
                esac
                _version="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest \
                    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
                curl -fLo /tmp/fzf.tar.gz \
                    "https://github.com/junegunn/fzf/releases/download/v${_version}/fzf-${_version}-linux_${_arch}.tar.gz"
                tar -xzf /tmp/fzf.tar.gz -C "${HOME}/.local/bin/" fzf
                rm -f /tmp/fzf.tar.gz
                ;;
        esac
        ok "fzf installed."
    fi
}
