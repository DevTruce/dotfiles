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

# -- Run-with-spinner: shared by every long-running install step in this repo (package
# manager wrappers below, git clones, GitHub-release downloads). Backgrounds its argv,
# animates the spinner via _spinner while it runs, and surfaces the captured output only
# on failure - callers just get a normal exit status back.
# Usage: call step() first (its message is what the spinner animates and what "failed."
# refers to), then _run_with_spinner <cmd> [args...]. For a multi-step sequence, wrap it
# in a small named function first and pass that function's name.
_run_with_spinner() {
    local _log _pid
    _log="$(mktemp)"
    # the redirect below is opened by this shell against its own tempfile before any
    # sudo exec inside "$@", not by the elevated process, so it's not the
    # sudo-doesn't-affect-redirects pitfall shellcheck would otherwise warn about
    # shellcheck disable=SC2024
    "$@" > "$_log" 2>&1 &
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

# -- Silent package manager wrappers: run in background with spinner, surface output only on failure

_apt() {
    _run_with_spinner env DEBIAN_FRONTEND=noninteractive sudo apt-get "$@"
}

_brew() {
    _run_with_spinner brew "$@"
}

_npm() {
    _run_with_spinner npm "$@"
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

# Whether $OS is one install.sh actually knows how to fully set up end-to-end.
# Every other Linux distro's case "$OS" in macos) ...; *) ... in scripts/*.sh still
# takes the apt/Debian branch (harmless if the distro is apt-based, like most
# WSL2 setups; a loud failure otherwise once apt-get itself isn't found) - this
# is the single place that distinction is decided, so install.sh can hard-block
# on it while run.sh/doctor.sh can just warn.
_is_supported_os() {
    case "$OS" in
        macos|ubuntu|debian) return 0 ;;
        *)                   return 1 ;;
    esac
}

# -- Architecture Detection

# Collapses the aarch64/arm64-vs-everything-else uname -m branch that repeats
# across every GitHub-release binary installer in scripts/utilities.sh - each
# tool just supplies its own pair of release-asset arch literals.
# Usage: _uname_arch <value-if-aarch64-or-arm64> <value-otherwise>
_uname_arch() {
    case "$(uname -m)" in
        aarch64|arm64) echo "$1" ;;
        *)             echo "$2" ;;
    esac
}

# -- Symlink Status (shared by doctor.sh's _check_symlink and its own tests)

# Prints one of: linked | broken:<current-target> | regular-file | missing.
# Pure filesystem check, no output side effects, so it's testable directly
# against real temp-dir fixtures without mocking anything.
_symlink_status() {
    local dest="$1" expected_src="$2"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$expected_src" ]; then
        echo "linked"
    elif [ -L "$dest" ]; then
        echo "broken:$(readlink "$dest")"
    elif [ -e "$dest" ]; then
        echo "regular-file"
    else
        echo "missing"
    fi
}

# -- Configured Login Shell (shared by doctor.sh and setup_zsh)

# Prints the OS-level configured login shell for the current user - not $SHELL,
# which only reflects whatever shell the current session happens to be running,
# not what's actually configured. doctor.sh does a realpath-based equivalence
# check on top of this (reporting); setup_zsh does an exact-match check on top
# (decides whether to run chsh) - only this lookup itself is shared, since the
# two comparisons built on it genuinely differ in purpose.
_configured_login_shell() {
    case "$OS" in
        macos) dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}' ;;
        *)     getent passwd "$USER" 2>/dev/null | cut -d: -f7 ;;
    esac
}

# -- bat Binary Name (shared by setup_bat and doctor.sh's check)

# Debian/Ubuntu's bat package installs the binary as `batcat` to avoid a name
# collision with another package that already owns `bat`; Homebrew's doesn't.
_bat_binary_name() {
    case "$OS" in
        macos) echo "bat" ;;
        *)     echo "batcat" ;;
    esac
}
