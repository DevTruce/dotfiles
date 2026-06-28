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
