#!/usr/bin/env bats
# Unit tests for scripts/helpers.sh - the shared plumbing every setup_* function in
# the repo depends on (package-manager wrappers, OS detection, checksum verification,
# the symlink/shell-detection logic shared with doctor.sh). Everything here runs
# against fixtures or fake binaries on PATH - no real installs, no real network,
# never touches the real machine.

setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../scripts/helpers.sh"

  _FAKE_BIN="$(mktemp -d)"
  export PATH="${_FAKE_BIN}:${PATH}"
  _FIXTURES="$(mktemp -d)"
}

teardown() {
  rm -rf "${_FAKE_BIN}" "${_FIXTURES}"
  unset _DETECT_OS_RELEASE_FILE
}

# writes a fake `uname` onto PATH ahead of the real one, so detect_os() sees
# whatever kernel name we want without needing to run this on that real OS
_fake_uname() {
  cat > "${_FAKE_BIN}/uname" <<EOF
#!/usr/bin/env bash
echo "$1"
EOF
  chmod +x "${_FAKE_BIN}/uname"
}

# writes a fake command that just execs its arguments - used to stand in for `sudo`
# so _apt can be tested without ever actually invoking privilege escalation
_fake_exec_passthrough() {
  cat > "${_FAKE_BIN}/$1" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
  chmod +x "${_FAKE_BIN}/$1"
}

# writes a fake command that prints given output and exits with a given status -
# used to stand in for apt-get/brew/npm without touching a real package manager
_fake_cmd() {
  local _name="$1" _exit_code="$2" _output="$3"
  cat > "${_FAKE_BIN}/${_name}" <<EOF
#!/usr/bin/env bash
echo "${_output}"
exit ${_exit_code}
EOF
  chmod +x "${_FAKE_BIN}/${_name}"
}

# -- detect_os() --

@test "detect_os returns macos on a Darwin kernel" {
  _fake_uname "Darwin"
  run detect_os
  [ "$status" -eq 0 ]
  [ "$output" = "macos" ]
}

@test "detect_os returns unknown for an unrecognized kernel" {
  _fake_uname "FreeBSD"
  run detect_os
  [ "$output" = "unknown" ]
}

@test "detect_os falls back to 'linux' when os-release is missing" {
  _fake_uname "Linux"
  _DETECT_OS_RELEASE_FILE="${_FIXTURES}/does-not-exist"
  run detect_os
  [ "$output" = "linux" ]
}

@test "detect_os reads the distro ID out of os-release on Linux" {
  _fake_uname "Linux"
  _DETECT_OS_RELEASE_FILE="${_FIXTURES}/os-release"
  cat > "$_DETECT_OS_RELEASE_FILE" <<'EOF'
ID=ubuntu
NAME="Ubuntu"
VERSION_ID="24.04"
EOF
  run detect_os
  [ "$output" = "ubuntu" ]
}

@test "detect_os falls back to 'linux' when os-release has no ID field" {
  _fake_uname "Linux"
  _DETECT_OS_RELEASE_FILE="${_FIXTURES}/os-release"
  echo 'NAME="Some Distro"' > "$_DETECT_OS_RELEASE_FILE"
  run detect_os
  [ "$output" = "linux" ]
}

# -- _verify_sha256() --
# uses file:// URLs so curl reads local fixtures instead of hitting the network

@test "_verify_sha256 succeeds when the hash matches" {
  local _dl="${_FIXTURES}/asset.tar.gz"
  echo "some file contents" > "$_dl"
  local _hash
  _hash="$(sha256sum "$_dl" | awk '{print $1}')"
  local _checksums="${_FIXTURES}/checksums.txt"
  echo "${_hash}  asset.tar.gz" > "$_checksums"

  run _verify_sha256 "$_dl" "file://${_checksums}" "asset.tar.gz"
  [ "$status" -eq 0 ]
}

@test "_verify_sha256 fails on a checksum mismatch" {
  local _dl="${_FIXTURES}/asset.tar.gz"
  echo "some file contents" > "$_dl"
  local _checksums="${_FIXTURES}/checksums.txt"
  echo "0000000000000000000000000000000000000000000000000000000000000000  asset.tar.gz" > "$_checksums"

  run _verify_sha256 "$_dl" "file://${_checksums}" "asset.tar.gz"
  [ "$status" -eq 1 ]
  [[ "$output" == *"checksum mismatch"* ]]
}

@test "_verify_sha256 fails when the expected filename has no entry" {
  local _dl="${_FIXTURES}/asset.tar.gz"
  echo "some file contents" > "$_dl"
  local _hash
  _hash="$(sha256sum "$_dl" | awk '{print $1}')"
  local _checksums="${_FIXTURES}/checksums.txt"
  echo "${_hash}  some-other-asset.tar.gz" > "$_checksums"

  run _verify_sha256 "$_dl" "file://${_checksums}" "asset.tar.gz"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no checksum entry found"* ]]
}

@test "_verify_sha256 fails when the checksums file can't be fetched" {
  run _verify_sha256 "${_FIXTURES}/asset.tar.gz" "file://${_FIXTURES}/does-not-exist.txt" "asset.tar.gz"
  [ "$status" -eq 1 ]
  [[ "$output" == *"could not download checksums file"* ]]
}

# -- _apt() / _brew() / _npm() --
# shared plumbing every setup_* function depends on - widest blast radius in the
# repo if broken. Faked binaries mean no real package manager is ever touched.

@test "_apt returns success and cleans up when apt-get succeeds" {
  _fake_exec_passthrough sudo
  _fake_cmd apt-get 0 "Reading package lists... Done"
  step "Installing bogus" >/dev/null
  run _apt install -y bogus
  [ "$status" -eq 0 ]
}

@test "_apt reports failure and surfaces apt-get's output when it fails" {
  _fake_exec_passthrough sudo
  _fake_cmd apt-get 1 "E: Unable to locate package bogus"
  step "Installing bogus" >/dev/null
  run _apt install -y bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"failed."* ]]
  [[ "$output" == *"E: Unable to locate package bogus"* ]]
}

@test "_brew returns success when brew succeeds" {
  _fake_cmd brew 0 "Already up-to-date."
  step "Installing bogus-formula" >/dev/null
  run _brew install bogus-formula
  [ "$status" -eq 0 ]
}

@test "_brew reports failure and surfaces brew's output when it fails" {
  _fake_cmd brew 1 "Error: no available formula with the name bogus-formula"
  step "Installing bogus-formula" >/dev/null
  run _brew install bogus-formula
  [ "$status" -eq 1 ]
  [[ "$output" == *"failed."* ]]
  [[ "$output" == *"no available formula"* ]]
}

@test "_npm returns success when npm succeeds" {
  _fake_cmd npm 0 "+ some-package@1.0.0"
  step "Installing some-package" >/dev/null
  run _npm install -g some-package
  [ "$status" -eq 0 ]
}

@test "_npm reports failure and surfaces npm's output when it fails" {
  _fake_cmd npm 1 "npm ERR! 404 Not Found - bogus-package"
  step "Installing bogus-package" >/dev/null
  run _npm install -g bogus-package
  [ "$status" -eq 1 ]
  [[ "$output" == *"failed."* ]]
  [[ "$output" == *"npm ERR!"* ]]
}

# -- _spinner() --

@test "_spinner returns immediately for a process that has already finished" {
  ( exit 0 ) &
  local _pid=$!
  wait "$_pid"
  run _spinner "$_pid"
  [ "$status" -eq 0 ]
}

# -- _symlink_status() --
# shared by doctor.sh's _check_symlink - real temp-dir fixtures, no mocking needed

@test "_symlink_status reports 'linked' for a symlink pointing at the expected target" {
  touch "${_FIXTURES}/target"
  ln -s "${_FIXTURES}/target" "${_FIXTURES}/link"
  run _symlink_status "${_FIXTURES}/link" "${_FIXTURES}/target"
  [ "$output" = "linked" ]
}

@test "_symlink_status reports 'broken' with the actual target when it points elsewhere" {
  ln -s "${_FIXTURES}/wrong-target" "${_FIXTURES}/link"
  run _symlink_status "${_FIXTURES}/link" "${_FIXTURES}/target"
  [[ "$output" == "broken:"*"wrong-target" ]]
}

@test "_symlink_status reports 'regular-file' when the destination exists but isn't a symlink" {
  touch "${_FIXTURES}/link"
  run _symlink_status "${_FIXTURES}/link" "${_FIXTURES}/target"
  [ "$output" = "regular-file" ]
}

@test "_symlink_status reports 'missing' when the destination doesn't exist at all" {
  run _symlink_status "${_FIXTURES}/nonexistent" "${_FIXTURES}/target"
  [ "$output" = "missing" ]
}

# -- _configured_login_shell() --
# shared by doctor.sh and setup_zsh - fake dscl/getent so both OS branches are
# testable from either host OS

@test "_configured_login_shell reads via dscl on macOS" {
  OS="macos"
  USER="testuser"
  cat > "${_FAKE_BIN}/dscl" <<'EOF'
#!/usr/bin/env bash
echo "UserShell: /opt/homebrew/bin/zsh"
EOF
  chmod +x "${_FAKE_BIN}/dscl"
  run _configured_login_shell
  [ "$output" = "/opt/homebrew/bin/zsh" ]
}

@test "_configured_login_shell reads via getent on Linux" {
  OS="ubuntu"
  USER="testuser"
  cat > "${_FAKE_BIN}/getent" <<'EOF'
#!/usr/bin/env bash
echo "testuser:x:1000:1000::/home/testuser:/usr/bin/zsh"
EOF
  chmod +x "${_FAKE_BIN}/getent"
  run _configured_login_shell
  [ "$output" = "/usr/bin/zsh" ]
}
