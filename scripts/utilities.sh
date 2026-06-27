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

check_vscode_cli() {
    section "Utilities — VS Code CLI"

    if command -v code >/dev/null 2>&1; then
        echo "  VS Code CLI (code) is available."
    else
        echo "  WARNING: The 'code' command was not found on PATH."
        echo ""
        echo "  Your .gitconfig sets 'core.editor = code --wait', so git will try to"
        echo "  open VS Code for commit messages. Without the CLI this will hang."
        echo ""
        echo "  This will be included in the todo list at the end."
    fi
}
