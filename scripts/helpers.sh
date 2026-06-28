# ─────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────

# -- Colors

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BOLD_CYAN=$'\033[1;36m'
BOLD_GREEN=$'\033[1;32m'
BOLD_WHITE=$'\033[1;37m'

# -- Output

section() {
    echo ""
    printf "  ${BOLD_CYAN}▸ %s${RESET}\n" "$1"
    printf "  ${DIM}──────────────────────────────────────────────────────${RESET}\n"
}

# actively happening right now
step() {
    printf "  ${CYAN}→${RESET}  %s\n" "$1"
}

# just completed successfully
ok() {
    printf "  ${BOLD_GREEN}✓${RESET}  %s\n" "$1"
}

# already done — nothing to do
skip() {
    printf "  ${DIM}✓  %s${RESET}\n" "$1"
}

# warning
warn() {
    printf "  ${YELLOW}⚠${RESET}  %s\n" "$1"
}

# secondary info / sub-detail
note() {
    printf "       ${DIM}%s${RESET}\n" "$1"
}

# symlink row: cyan source → dim destination
link() {
    printf "  ${CYAN}%-28s${RESET}${DIM} → ${RESET}%s\n" "$1" "$2"
}

# -- OS Detection

detect_os() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                echo "${ID:-linux}"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}
