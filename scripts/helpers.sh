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

# symlink row: cyan source → dim arrow → default destination
link() {
    printf "  ${CYAN}%-28s${RESET}${DIM} → ${RESET}%s\n" "$1" "$2"
}

# -- Spinner: shows a braille spinner while a background PID is running, then erases itself
# Usage: background your command first, capture $!, then call _spinner $pid

_spinner() {
    local pid=$1
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}%s${RESET}" "${frames:$i:1}"
        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done
    printf "\r\033[K"  # erase spinner line so ok/warn prints in its place
}

# -- Silent package manager wrappers: run in background with spinner, surface output only on failure

_apt() {
    local _log _pid
    _log="$(mktemp)"
    DEBIAN_FRONTEND=noninteractive sudo apt-get "$@" > "$_log" 2>&1 &
    _pid=$!
    _spinner "$_pid"
    if wait "$_pid"; then
        rm -f "$_log"
    else
        cat "$_log"
        rm -f "$_log"
        return 1
    fi
}

_brew() {
    local _log _pid
    _log="$(mktemp)"
    brew "$@" > "$_log" 2>&1 &
    _pid=$!
    _spinner "$_pid"
    if wait "$_pid"; then
        rm -f "$_log"
    else
        cat "$_log"
        rm -f "$_log"
        return 1
    fi
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
