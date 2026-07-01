# ─────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────

# -- Colors

RESET=$'\033[0m'
# shellcheck disable=SC2034 # used by scripts that source this file (finish.sh)
BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
YELLOW=$'\033[33m'
BOLD_CYAN=$'\033[1;36m'
BOLD_GREEN=$'\033[1;32m'
# shellcheck disable=SC2034 # used by scripts that source this file (install.sh, doctor.sh, run.sh, finish.sh)
BOLD_WHITE=$'\033[1;37m'
BOLD_RED=$'\033[1;31m'

# -- Output

section() {
    echo ""
    printf "  ${BOLD_CYAN}▸ %s${RESET}\n" "$1"
    printf "  ${DIM}──────────────────────────────────────────────────────${RESET}\n"
}

# actively happening right now - also stores message for _spinner to animate inline
_LAST_STEP=""
step() {
    _LAST_STEP="$1"
    printf "  ${CYAN}→${RESET}  %s\n" "$1"
}

# just completed successfully
ok() {
    printf "  ${BOLD_GREEN}✓${RESET}  %s\n" "$1"
}

# already done - nothing to do
skip() {
    printf "  ${DIM}✓  %s${RESET}\n" "$1"
}

# warning
warn() {
    printf "  ${YELLOW}⚠${RESET}  %s\n" "$1"
}

fail() {
    printf "  ${BOLD_RED}✗${RESET}  %s\n" "$1"
}

# secondary info / sub-detail
note() {
    printf "       ${DIM}%s${RESET}\n" "$1"
}

# something the user needs to copy (SSH key, GPG key, etc.)
copy() {
    printf "  ${CYAN}📋${RESET}  %s\n" "$1"
}

# symlink row: cyan source → dim arrow → default destination
link() {
    printf "  ${CYAN}%-28s${RESET}${DIM} → ${RESET}%s\n" "$1" "$2"
}

# -- Spinner: goes up to the step line and animates the spinner inline after the message.
# Erases that line when done so ok/fail/warn prints in its place.
# Usage: call step() first, then background your command, then call _spinner $pid

_spinner() {
    local pid=$1
    local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    # if the process already finished before we got here, skip the animation
    kill -0 "$pid" 2>/dev/null || return 0
    printf "\033[1A"  # cursor up to the step line
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}→${RESET}  %s ${CYAN}%s${RESET}" "$_LAST_STEP" "${frames:$i:1}"
        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done
    printf "\r\033[K"  # erase the step+spinner line so ok/warn prints in its place
}

# -- Silent package manager wrappers: run in background with spinner, surface output only on failure

_apt() {
    local _log _pid
    _log="$(mktemp)"
    # the redirect below is opened by this (non-root) shell against its own tempfile
    # before sudo's exec, not by the elevated apt-get process, so it's not the
    # sudo-doesn't-affect-redirects pitfall shellcheck is warning about here
    # shellcheck disable=SC2024
    DEBIAN_FRONTEND=noninteractive sudo apt-get "$@" > "$_log" 2>&1 &
    _pid=$!
    _spinner "$_pid"
    if wait "$_pid"; then
        rm -f "$_log"
    else
        fail "${_LAST_STEP} failed."
        echo ""
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
        fail "${_LAST_STEP} failed."
        echo ""
        cat "$_log"
        rm -f "$_log"
        return 1
    fi
}

_npm() {
    local _log _pid
    _log="$(mktemp)"
    npm "$@" > "$_log" 2>&1 &
    _pid=$!
    _spinner "$_pid"
    if wait "$_pid"; then
        rm -f "$_log"
    else
        fail "${_LAST_STEP} failed."
        echo ""
        cat "$_log"
        rm -f "$_log"
        return 1
    fi
}

# -- Checksum verification

# Verifies a downloaded file's sha256 against a project-published checksums file.
# Usage: _verify_sha256 <downloaded_file> <checksums_url> <expected_filename_in_checksums>
_verify_sha256() {
    local _file="$1" _checksums_url="$2" _expected_name="$3"
    local _checksums _expected_hash _actual_hash

    _checksums="$(curl -fsSL "$_checksums_url")" || { echo "ERROR: could not download checksums file (${_checksums_url})" >&2; return 1; }
    _expected_hash="$(echo "$_checksums" | grep "  ${_expected_name}\$" | awk '{print $1}')"
    if [ -z "$_expected_hash" ]; then
        echo "ERROR: no checksum entry found for ${_expected_name} in ${_checksums_url}" >&2
        return 1
    fi
    _actual_hash="$(sha256sum "$_file" | awk '{print $1}')"
    if [ "$_actual_hash" != "$_expected_hash" ]; then
        echo "ERROR: checksum mismatch for ${_expected_name} (expected ${_expected_hash}, got ${_actual_hash})" >&2
        return 1
    fi
}

# -- OS Detection

detect_os() {
    # overridable only so tests can point this at a fixture file instead of the real
    # /etc/os-release - every real call site leaves this unset and gets the real path
    local _os_release="${_DETECT_OS_RELEASE_FILE:-/etc/os-release}"
    case "$(uname -s)" in
        Linux*)
            if [ -f "$_os_release" ]; then
                # shellcheck disable=SC1090
                . "$_os_release"
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
