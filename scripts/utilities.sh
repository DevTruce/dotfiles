# ─────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────

# -- tree

setup_tree() {
    section "Utilities — tree"

    if command -v tree >/dev/null 2>&1; then
        echo "  tree is already installed."
    else
        echo "  Installing tree..."
        case "$OS" in
            macos) brew install tree ;;
            *)     sudo apt install tree -y ;;
        esac
        echo "  tree installed."
    fi
}
