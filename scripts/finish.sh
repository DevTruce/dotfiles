# ─────────────────────────────────────────
# Finish
# ─────────────────────────────────────────

finish() {
    local step=1

    # -- Header

    echo ""
    echo "  ════════════════════════════════════════════════════"
    echo "  All tools are installed! A few manual steps remain:"
    echo "  ════════════════════════════════════════════════════"
    echo ""

    # -- Todo List

    # -- Personal machine steps
    if [ "$PERSONAL_MACHINE" = "y" ]; then
        echo "  [ ${step} ]  Add your SSH public key to GitHub"
        echo ""
        echo "         github.com → Settings → SSH and GPG Keys → New SSH key"
        echo "         Paste the public key printed above."
        echo ""
        step=$((step + 1))

        echo "  [ ${step} ]  Add your GPG public key to GitHub"
        echo ""
        echo "         github.com → Settings → SSH and GPG Keys → New GPG key"
        echo "         Paste the public key printed above."
        echo ""
        step=$((step + 1))
    fi

    echo "  [ ${step} ]  Install the MesloLGS NF fonts (required for Powerlevel10k)"
    echo ""
    echo "         Download all four fonts from:"
    echo "         https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k"
    echo ""
    case "$OS" in
        macos)
            echo "         Double-click each .ttf file to install, then open your terminal"
            echo "         preferences and set the font to \"MesloLGS NF Regular\"."
            ;;
        *)
            echo "         On WSL, fonts must be installed on the Windows side:"
            echo "           1. Double-click each .ttf file → Install for all users"
            echo "           2. Open Windows Terminal → Settings → your profile"
            echo "              → Appearance → Font face → MesloLGS NF"
            ;;
    esac
    echo ""
    step=$((step + 1))

    echo "  [ ${step} ]  Open a new terminal for all changes to take effect."
    echo ""
    echo "  ════════════════════════════════════════════════════"
    echo ""
}
