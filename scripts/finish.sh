finish() {
    local os_dir
    case "$OS" in
        macos) os_dir="MacOS" ;;
        *)     os_dir="Linux" ;;
    esac

    local step=1

    echo ""
    echo "  ════════════════════════════════════════════════════"
    echo "  All tools are installed! A few manual steps remain:"
    echo "  ════════════════════════════════════════════════════"
    echo ""

    echo "  [ ${step} ]  Copy your dotfiles to your home directory"
    echo ""
    echo "         cp \"${DOTFILES_DIR}/${os_dir}/.zshrc\"                    ~/.zshrc"
    echo "         cp \"${DOTFILES_DIR}/Common/.gitconfig\"                   ~/.gitconfig"
    echo "         cp \"${DOTFILES_DIR}/Common/.p10k.zsh\"                    ~/.p10k.zsh"
    echo "         mkdir -p ~/.claude"
    echo "         cp \"${DOTFILES_DIR}/Common/claude/settings.json\"         ~/.claude/settings.json"
    echo ""
    step=$((step + 1))

    echo "  [ ${step} ]  Set your GPG signing key in ~/.gitconfig"
    echo ""
    echo "         Open ~/.gitconfig and replace 'gpg_sec_key' under [user]"
    echo "         with the key ID printed above, then save the file."
    echo ""
    step=$((step + 1))

    echo "  [ ${step} ]  Add your SSH public key to GitHub"
    echo ""
    echo "         github.com → Settings → SSH and GPG Keys → New SSH key"
    echo "         Paste the public key printed above."
    echo ""
    step=$((step + 1))

    echo "  [ ${step} ]  Add your GPG public key to GitHub"
    echo ""
    echo "         Run:  gpg --armor --export <KEY_ID>"
    echo "         github.com → Settings → SSH and GPG Keys → New GPG key"
    echo "         Paste the output."
    echo ""
    step=$((step + 1))

    if ! command -v code >/dev/null 2>&1; then
        echo "  [ ${step} ]  Install the VS Code CLI"
        echo ""
        echo "         macOS — Open VS Code → Command Palette → Shell Command: Install 'code' in PATH"
        echo "         WSL   — Open this folder in VS Code via the Remote extension, then restart."
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
