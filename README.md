# Dev Environment Setup

My personal dev environment, automated end-to-end - shell, version control, security
(SSH/GPG), dev tooling, and dotfiles - via a single idempotent installer for macOS and
Ubuntu / Debian (including WSL2). Shared publicly in case it's useful, but it reflects my
own setup and preferences rather than a general-purpose, everyone's-preferences tool.

---

## Table of Contents

- [Overview](#overview)
- [Supported Systems](#supported-systems)
- [What Gets Installed](#what-gets-installed)
- [Symlinked Dotfiles](#symlinked-dotfiles)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [1. Clone the Repo](#1-clone-the-repo)
  - [2. Run the Installer](#2-run-the-installer)
- [Manual Steps](#manual-steps)
  - [1. Add Your SSH Key to GitHub](#1-add-your-ssh-key-to-github)
  - [2. Add Your GPG Key to GitHub](#2-add-your-gpg-key-to-github)
  - [3. Install MesloLGS NF Fonts](#3-install-meslolgs-nf-fonts)
  - [4. Open a New Terminal and Verify](#4-open-a-new-terminal-and-verify)
- [File Structure](#file-structure)
- [Re-running the Installer](#re-running-the-installer)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This repo takes a fresh macOS or Ubuntu / Debian (including WSL2) machine to a fully
configured dev environment in one run: package manager, shell, version control, SSH/GPG
security, Node.js tooling, a handful of CLI utilities, and your dotfiles - all installed and
symlinked by one modular, OS-aware installer.

The installer is fully **idempotent**: every step checks whether a tool or config is already
in place before doing anything, so it is safe to re-run at any time.

---

## Supported Systems

| Platform                         | Package Manager |
| -------------------------------- | --------------- |
| macOS                            | Homebrew        |
| Ubuntu / Debian (including WSL2) | apt             |

Only these are validated end-to-end: `install.sh` refuses to run on anything else. `run.sh`
and `doctor.sh` will still run against other Linux distros, falling back to apt-based logic
with a warning, since picking a function directly is its own consent - but they aren't a
supported target.

---

## What Gets Installed

| Tool                           | Description                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| Homebrew / apt                 | Package manager for the platform                                         |
| zsh                            | Shell - set as the default login shell                                   |
| git                            | Version control                                                          |
| git-lfs                        | Git extension for large file storage                                     |
| zinit                          | Zsh plugin manager (plugins download on first shell launch)              |
| zsh-syntax-highlighting        | Command syntax highlighting in the shell                                 |
| zsh-autosuggestions            | Fish-style inline command suggestions                                    |
| zsh-completions                | Extended zsh completion definitions                                      |
| docker completion              | Direct `_docker` completion from the official `docker/cli` repo          |
| Powerlevel10k                  | Fast, highly configurable zsh prompt theme                               |
| nvm                            | Node Version Manager                                                     |
| Node.js LTS                    | Latest long-term support release of Node.js                              |
| pnpm                           | Fast, disk-efficient Node.js package manager                             |
| tree                           | Directory tree display utility                                           |
| fzf                            | Fuzzy finder - CTRL-R history, CTRL-T file picker, ALT-C cd              |
| zoxide                         | Smart `cd` - jump to frecent dirs with `z`, interactive with `zi`        |
| ripgrep (rg)                   | Fast grep replacement with better defaults                               |
| bat                            | `cat` with syntax highlighting and git integration                       |
| lazygit                        | Terminal UI for git                                                      |
| gh (GitHub CLI)                | GitHub operations (PRs, issues, repos) from the terminal                 |
| SSH + GPG keys (ed25519 / GPG) | _(personal)_ SSH key for GitHub auth; GPG key for commit and tag signing |
| pinentry-mac / pinentry-curses | _(personal)_ GPG passphrase prompt (GUI on macOS, terminal on Linux)     |
| gpg-agent                      | _(personal)_ Passphrase caching for GPG and SSH keys                     |
| Claude Code CLI                | _(personal)_ Terminal AI coding assistant                                |

> Items marked _(personal)_ are only installed when you answer **y** to the personal machine prompt.

**On Linux, four tools are pulled from GitHub releases instead of apt**, since Ubuntu's
repos ship versions too old (fzf, lazygit) or don't package them at all (zoxide, gh): fzf,
zoxide, lazygit, and gh. Downloads are checksum-verified against the project's published
checksums where available (fzf, lazygit, gh); zoxide doesn't publish one upstream, so its
download gets an archive-validity check instead.

**A few install steps are pinned rather than always pulling the newest code**, to keep
re-runs deterministic and reviewable instead of trusting whatever's live upstream at install
time: the Homebrew installer is pinned to a specific reviewed commit (Homebrew/install has no
version tags), and nvm is installed via a `git clone` at its latest release tag rather than
piping its install script through `bash`.

---

## Symlinked Dotfiles

The first five are symlinked directly from this repo. The rest are generated by the
installer at install time - not tracked, since they hold machine-specific or sensitive
values (identity, keys, local paths).

| File                 | Repo Path              | Destination                            |
| -------------------- | ---------------------- | -------------------------------------- |
| zshenv               | `.zshenv`              | `~/.zshenv`                            |
| zshrc                | `.zshrc`               | `~/.zshrc`                             |
| git config           | `.gitconfig`           | `~/.gitconfig`                         |
| Powerlevel10k config | `.p10k.zsh`            | `~/.p10k.zsh`                          |
| Claude Code settings | `claude/settings.json` | `~/.claude/settings.json` _(personal)_ |
| local git config     | _(generated)_          | `~/.gitconfig.local`                   |
| git-lfs hook script  | _(generated)_          | `~/.config/git/hooks/pre-push`         |
| GPG agent config     | _(generated)_          | `~/.gnupg/gpg-agent.conf` _(personal)_ |

---

## Installation

### Prerequisites

- **All platforms** - `git` must be available to clone the repo, and `sudo` access is
  required (the installer installs system packages, registers the shell in `/etc/shells`,
  and sets your default shell)
- **macOS** - Install Xcode Command Line Tools if not already present:
  ```bash
  xcode-select --install
  ```
- **Ubuntu / Debian / WSL2** - no additional prerequisites beyond `sudo`

### 1. Clone the Repo

```bash
git clone https://github.com/DevTruce/dev-bootstrap.git ~/dev-bootstrap
```

### 2. Run the Installer

```bash
cd ~/dev-bootstrap
./install.sh
```

The installer detects your OS, symlinks your dotfiles, and prompts whether this is a personal machine. Answering **y** adds SSH/GPG key setup, GPG agent configuration, and Claude Code CLI. Answering **n** skips those and installs only the core tooling. It then prints a todo list of any remaining manual steps when it finishes.

---

## Manual Steps

The installer handles everything it can automatically, including symlinking all dotfiles into your home directory. On personal machines it also generates SSH/GPG keys and prints them ready to paste. The steps below require manual action and are also printed at the end of every install run as a reminder.

> Steps 1-2 apply to personal machine installs only.

### 1. Add Your SSH Key to GitHub

The installer prints your public key during setup. To view it again:

```bash
cat ~/.ssh/id_ed25519.pub
```

Then add it to GitHub:

1. Go to **[github.com/settings/keys](https://github.com/settings/keys)**
2. Click **New SSH key**
3. Paste the public key

### 2. Add Your GPG Key to GitHub

The installer prints your full armored public key during setup - copy it directly from the terminal output. To export it again at any time:

```bash
gpg --armor --export YOUR_KEY_ID_HERE
```

Then add it to GitHub:

1. Copy the full output including the `-----BEGIN PGP PUBLIC KEY BLOCK-----` headers
2. Go to **[github.com/settings/keys](https://github.com/settings/keys)**
3. Click **New GPG key**
4. Paste the output

### 3. Install MesloLGS NF Fonts

MesloLGS NF is required for Powerlevel10k to render correctly. Click each link to download the file directly:

- [MesloLGS NF Regular.ttf](https://github.com/DevTruce/dev-bootstrap/raw/main/fonts/MesloLGS%20NF%20Regular.ttf)
- [MesloLGS NF Bold.ttf](https://github.com/DevTruce/dev-bootstrap/raw/main/fonts/MesloLGS%20NF%20Bold.ttf)
- [MesloLGS NF Italic.ttf](https://github.com/DevTruce/dev-bootstrap/raw/main/fonts/MesloLGS%20NF%20Italic.ttf)
- [MesloLGS NF Bold Italic.ttf](https://github.com/DevTruce/dev-bootstrap/raw/main/fonts/MesloLGS%20NF%20Bold%20Italic.ttf)

**macOS**

1. Double-click each `.ttf` file to install via Font Book
2. Open your terminal preferences and set the font to `MesloLGS NF Regular`

**WSL2**

Fonts must be installed on the Windows side for Windows Terminal to use them:

1. Double-click each `.ttf` file → **Install for all users**
2. Open **Windows Terminal** → **Settings** → select your profile → **Appearance**
3. Set **Font face** to `MesloLGS NF`

**Ubuntu / Debian**

1. Install the fonts with your system font manager
2. Run `fc-cache -fv` to rebuild the font cache
3. Set `MesloLGS NF` in your terminal emulator preferences

### 4. Open a New Terminal and Verify

Open a fresh terminal session for all changes (default shell, plugins, PATH) to take effect.
Then run the doctor to confirm everything is wired up correctly:

```bash
~/dev-bootstrap/doctor.sh
```

All items should show a green checkmark. Zinit plugins and shell init caches that haven't
downloaded yet will show a dim checkmark - they are guaranteed to materialize the moment you
opened the new terminal. `doctor.sh` also reports an approximate interactive shell startup
time, purely informational (there's no fixed pass/fail threshold across different machines).

---

## File Structure

```
dev-bootstrap/
├── .github/
│   └── workflows/               # lint.yml (shellcheck + zsh -n) and test.yml (./test.sh) - see Contributing
├── .gitconfig                   # git aliases, LFS config, and default settings (identity in ~/.gitconfig.local)
├── .gitignore                   # ignores keys, .gitconfig.local, OS junk, and zinit plugin cache
├── .p10k.zsh                    # Powerlevel10k prompt configuration
├── .shellcheckrc                # shellcheck config - see Contributing
├── .zshenv                      # disables macOS Terminal.app's session save/restore (SHELL_SESSIONS_DISABLE)
├── .zshrc                       # zsh config for all platforms (uses $OSTYPE for platform-specific blocks)
├── claude/
│   └── settings.json            # Claude Code settings
├── fonts/                       # MesloLGS NF font files (install manually - see Manual Steps)
│   ├── MesloLGS NF Regular.ttf
│   ├── MesloLGS NF Bold.ttf
│   ├── MesloLGS NF Italic.ttf
│   └── MesloLGS NF Bold Italic.ttf
├── scripts/                     # modular installer components
│   ├── helpers.sh               # output helpers (section, step, ok, skip, warn, fail, note, copy, link, _spinner), _run_with_spinner(), _apt(), _brew(), _npm(), _latest_github_version(), _verify_sha256(), detect_os(), _is_supported_os(), _uname_arch(), _symlink_status(), _configured_login_shell(), _bat_binary_name()
│   ├── package-managers.sh      # setup_homebrew, setup_apt
│   ├── shell.sh                 # setup_zsh
│   ├── version-control.sh       # setup_git, setup_git_lfs
│   ├── security.sh              # setup_gpg_tools, setup_ssh_key, setup_gpg_key, setup_gpg_agent_conf
│   ├── dev-environment.sh       # setup_zsh_plugins, setup_nvm, setup_pnpm, setup_claude, setup_bats, setup_shellcheck
│   ├── dotfiles.sh              # setup_dotfiles - symlinks all dotfiles into home directory
│   ├── utilities.sh             # setup_tree, setup_fzf, setup_zoxide, setup_ripgrep, setup_bat, setup_lazygit, setup_gh
│   └── finish.sh                # completion banner and manual todo list
├── tests/                       # bats unit tests for the installer's own logic, mirroring scripts/ - see Contributing
│   ├── scripts/
│   │   ├── helpers.bats          # detect_os(), _is_supported_os(), _uname_arch(), _latest_github_version(), _verify_sha256(), _run_with_spinner(), _apt/_brew/_npm, _spinner, _symlink_status(), _configured_login_shell(), _bat_binary_name()
│   │   ├── dotfiles.bats          # setup_dotfiles()
│   │   ├── version_control.bats   # setup_git()'s identity prompt and editor selection, setup_git_lfs()'s hook registration
│   │   └── security.bats          # setup_gpg_agent_conf()'s config detection
│   └── run.bats                  # _run_selection(), menu OS-filtering, direct dispatch, _warn_if_unsupported_os()
├── install.sh                   # entry point: loads scripts, detects OS, dispatches
├── doctor.sh                    # post-install verification: checks all tools, symlinks, PATH, git identity, and security
├── run.sh                       # run a single setup function without the full install
├── test.sh                      # runs tests/**/*.bats, printed through this repo's ok/fail/warn convention
├── ci.sh                        # runs test.sh + shellcheck + zsh -n in one pass - what CI runs, locally
└── LICENSE                      # MIT
```

---

## Re-running the Installer

Every function checks whether a tool is already present before doing anything, so re-running is safe and fast - most steps will print "already installed" and skip. Pull the latest changes and re-run to pick up any new tools:

```bash
~/dev-bootstrap/install.sh
```

To run a single setup function without the full install, use `run.sh`. Run it with no
arguments for an interactive, grouped menu of every available function (OS-inapplicable
entries like `setup_homebrew` on Linux are hidden automatically):

```bash
~/dev-bootstrap/run.sh
```

Pick one or more steps at the `Select:` prompt - a single number (`3`), a comma/space-separated
list (`1,4,7`), or a range (`1-6`) all work, run in sequence, then loop back to the menu. `c`
runs `doctor.sh` to verify your setup without leaving the menu, and `q` quits.

Or invoke a function directly if you already know its name:

```bash
~/dev-bootstrap/run.sh setup_gpg_key
```

---

## Contributing

This section is for editing dev-bootstrap's own scripts - not for using it to set up a
machine, which is what the rest of this README covers. `bats` and `shellcheck` (used below)
are dev-only tools and are never installed automatically by `install.sh` - install them
yourself first:

```bash
~/dev-bootstrap/run.sh setup_bats
~/dev-bootstrap/run.sh setup_shellcheck
```

**Run everything CI runs, in one pass:**

```bash
./ci.sh
```

Runs the test suite, shellcheck, and the zsh syntax-check below in sequence and prints one
pass/fail summary - the same three checks `.github/workflows/` runs on every push and pull
request. None touch a real machine or run as part of `install.sh`. Run them individually
below if you only need one.

**Run the test suite:**

```bash
./test.sh
```

- Runs every `*.bats` file under `tests/` via the `bats` test runner (installed above).
- `tests/` follows a naming convention mirroring `scripts/` and the root-level `.sh` files
  where a test exists - e.g. `tests/scripts/helpers.bats` tests `scripts/helpers.sh`,
  `tests/run.bats` tests `run.sh`. Coverage isn't exhaustive - not every script has a
  `.bats` file yet. **These `.bats` files are test files, not runners** - `tests/run.bats` doesn't run
  anything, it just contains unit tests for `run.sh`'s functions. `./test.sh` is always the
  command that runs the suite.
- Tests cover the installer's own logic - menu parsing, symlinking and idempotency, identity
  prompts, config detection - against fixtures and fake binaries, never the real machine or a
  real package manager.
- Results print through this repo's own `ok`/`fail`/`warn` output (green ✓ / red ✗ / yellow
  ⚠, matching `doctor.sh`) instead of bats' default TAP output. Want raw TAP instead?
  `bats tests/ -r`.

**Lint every script:**

```bash
shellcheck --severity=warning *.sh scripts/*.sh
```

- `.shellcheckrc` disables two checks that are false positives for this repo's conventions -
  see the comments in that file for why.

**Syntax-check the zsh dotfiles:**

```bash
zsh -n .zshrc && zsh -n .zshenv && zsh -n .p10k.zsh
```

- Catches a broken `.zshrc` (parse errors only, not semantic bugs, since `-n` never runs the
  file).
- shellcheck doesn't cover these three since they're zsh, not POSIX sh.

---

## License

[MIT](LICENSE)
