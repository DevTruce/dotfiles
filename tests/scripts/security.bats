#!/usr/bin/env bats
# Unit tests for setup_gpg_agent_conf()'s "is the existing config already complete"
# detection logic in scripts/security.sh. Fake pinentry-curses and gpgconf on PATH
# mean the real GPG agent and real package manager are never touched.

setup() {
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../scripts/helpers.sh"
  # shellcheck disable=SC1091
  source "${BATS_TEST_DIRNAME}/../../scripts/security.sh"

  _FAKE_HOME="$(mktemp -d)"
  HOME="$_FAKE_HOME"
  OS="ubuntu"

  _FAKE_BIN="$(mktemp -d)"
  export PATH="${_FAKE_BIN}:${PATH}"
  cat > "${_FAKE_BIN}/pinentry-curses" <<'EOF'
#!/usr/bin/env bash
EOF
  chmod +x "${_FAKE_BIN}/pinentry-curses"
  # no-op stand-in so the real gpg-agent is never killed/relaunched by this test
  cat > "${_FAKE_BIN}/gpgconf" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "${_FAKE_BIN}/gpgconf"

  _GPG_AGENT_CONF="${_FAKE_HOME}/.gnupg/gpg-agent.conf"
}

teardown() {
  rm -rf "$_FAKE_HOME" "$_FAKE_BIN"
}

@test "writes a fresh config with all required settings when none exists" {
  run setup_gpg_agent_conf
  [ "$status" -eq 0 ]
  [ -f "$_GPG_AGENT_CONF" ]
  grep -q "enable-ssh-support" "$_GPG_AGENT_CONF"
  grep -q "default-cache-ttl-ssh" "$_GPG_AGENT_CONF"
  grep -q "pinentry-program ${_FAKE_BIN}/pinentry-curses" "$_GPG_AGENT_CONF"
}

@test "skips rewriting when the existing config already has every required setting" {
  mkdir -p "${_FAKE_HOME}/.gnupg"
  cat > "$_GPG_AGENT_CONF" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
default-cache-ttl-ssh 28800
max-cache-ttl-ssh 86400
pinentry-program ${_FAKE_BIN}/pinentry-curses
enable-ssh-support
EOF
  local _before
  _before="$(cat "$_GPG_AGENT_CONF")"
  run setup_gpg_agent_conf
  [[ "$output" == *"already configured"* ]]
  [ "$(cat "$_GPG_AGENT_CONF")" = "$_before" ]
}

@test "rewrites when the existing config is missing one required setting" {
  mkdir -p "${_FAKE_HOME}/.gnupg"
  # missing default-cache-ttl-ssh - simulates an older config from before it was added
  cat > "$_GPG_AGENT_CONF" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
pinentry-program ${_FAKE_BIN}/pinentry-curses
enable-ssh-support
EOF
  run setup_gpg_agent_conf
  [[ "$output" != *"already configured"* ]]
  grep -q "default-cache-ttl-ssh" "$_GPG_AGENT_CONF"
}

@test "rewrites when the pinentry path in the existing config doesn't match the current one" {
  mkdir -p "${_FAKE_HOME}/.gnupg"
  cat > "$_GPG_AGENT_CONF" <<EOF
default-cache-ttl 28800
max-cache-ttl 86400
default-cache-ttl-ssh 28800
max-cache-ttl-ssh 86400
pinentry-program /some/stale/path/pinentry-curses
enable-ssh-support
EOF
  run setup_gpg_agent_conf
  [[ "$output" != *"already configured"* ]]
  grep -q "pinentry-program ${_FAKE_BIN}/pinentry-curses" "$_GPG_AGENT_CONF"
}

@test "creates ~/.gnupg with 700 permissions" {
  run setup_gpg_agent_conf
  local _perms
  # can't fall back on exit status here (stat -f 'FMT' file 2>/dev/null || stat -c ...):
  # on Linux, `stat -f` means "filesystem info" not "format" - it still exits 0 with
  # the wrong output instead of failing, so the || fallback never triggers. Branch on
  # uname directly instead.
  if [[ "$(uname -s)" == "Darwin" ]]; then
    _perms="$(stat -f '%Lp' "${_FAKE_HOME}/.gnupg")"
  else
    _perms="$(stat -c '%a' "${_FAKE_HOME}/.gnupg")"
  fi
  [ "$_perms" = "700" ]
}
