# ─────────────────────────────────────────
# Finish
# ─────────────────────────────────────────

finish() {
    local n=1

    # -- Header

    echo ""
    printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
    printf "  ${BOLD_GREEN}✓${RESET}  ${BOLD_WHITE}Setup complete! A few manual steps remain:${RESET}\n"
    printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
    echo ""

    # -- Todo List

    # -- Personal machine steps
    if [ "$PERSONAL_MACHINE" = "y" ]; then
        printf "  ${BOLD_WHITE}[ %s ]${RESET}  ${BOLD}Add your SSH public key to GitHub${RESET}\n" "${n}"
        echo ""
        note "github.com → Settings → SSH and GPG Keys → New SSH key"
        note "Paste the public key printed above."
        echo ""
        n=$((n + 1))

        printf "  ${BOLD_WHITE}[ %s ]${RESET}  ${BOLD}Add your GPG public key to GitHub${RESET}\n" "${n}"
        echo ""
        note "github.com → Settings → SSH and GPG Keys → New GPG key"
        note "Paste the public key printed above."
        echo ""
        n=$((n + 1))
    fi

    printf "  ${BOLD_WHITE}[ %s ]${RESET}  ${BOLD}Install the MesloLGS NF fonts (required for Powerlevel10k)${RESET}\n" "${n}"
    echo ""
    note "Download all four fonts from the dotfiles repo (click each link to download):"
    note "https://github.com/DevTruce/dotfiles/tree/main/fonts"
    echo ""
    case "$OS" in
        macos)
            note "Double-click each .ttf file to install, then open your terminal"
            note "preferences and set the font to \"MesloLGS NF Regular\"."
            ;;
        *)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                note "On WSL, fonts must be installed on the Windows side:"
                note "  1. Double-click each .ttf file → Install for all users"
                note "  2. Open Windows Terminal → Settings → your profile"
                note "     → Appearance → Font face → MesloLGS NF"
            else
                note "Install the fonts with your system font manager, then run:"
                note "  fc-cache -fv"
                note "Then set MesloLGS NF in your terminal emulator preferences."
            fi
            ;;
    esac
    echo ""
    n=$((n + 1))

    printf "  ${BOLD_WHITE}[ %s ]${RESET}  ${BOLD}Open a new terminal for all changes to take effect.${RESET}\n" "${n}"
    echo ""
    printf "  ${BOLD_CYAN}════════════════════════════════════════════════════${RESET}\n"
    echo ""
}
