# DOTFILES

Personal dotfiles and automated installer for macOS and Linux / WSL2.

---

## Table of Contents

- [Overview](#overview)
- [Supported Systems](#supported-systems)
- [What Gets Installed](#what-gets-installed)
- [What's Included](#whats-included)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [1. Clone the Repo](#1-clone-the-repo)
  - [2. Run the Installer](#2-run-the-installer)
- [Manual Steps](#manual-steps)
  - [1. Add Your SSH Key to GitHub](#1-add-your-ssh-key-to-github)
  - [2. Add Your GPG Key to GitHub](#2-add-your-gpg-key-to-github)
  - [3. Install MesloLGS NF Fonts](#3-install-meslogls-nf-fonts)
  - [4. Open a New Terminal](#4-open-a-new-terminal)
- [File Structure](#file-structure)
- [Re-running the Installer](#re-running-the-installer)

---

## Overview

This repo contains dotfiles and a modular installer that sets up a consistent development environment from scratch. It handles package manager setup, shell configuration, version control, SSH/GPG security, and the Node.js dev environment - with OS-specific logic for macOS and Linux/WSL2 handled transparently.

The installer is fully **idempotent**: every step checks whether a tool or config is already in place before doing anything, so it is safe to re-run at any time.

---

## Supported Systems

| Platform                         | Package Manager |
| -------------------------------- | --------------- |
| macOS                            | Homebrew        |
| Ubuntu / Debian (including WSL2) | apt             |

---

## What Gets Installed

| Tool                           | Description                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| Homebrew / apt                 | Package manager for the platform                                         |
| zsh                            | Shell - set as the default login shell                                   |
| git                            | Version control                                                          |
| git-lfs                        | Git extension for large file storage                                     |
| zinit                          | Zsh plugin manager                                                       |
| zsh-syntax-highlighting        | Command syntax highlighting in the shell                                 |
| zsh-autosuggestions            | Fish-style inline command suggestions                                    |
| zsh-completions                | Extended zsh completion definitions                                      |
| OMZ docker / docker-compose    | Oh My Zsh Docker and Docker Compose plugins                              |
| Powerlevel10k                  | Fast, highly configurable zsh prompt theme                               |
| nvm                            | Node Version Manager                                                     |
| Node.js LTS                    | Latest long-term support release of Node.js                              |
| tree                           | Directory tree display utility                                           |
| SSH key (ed25519)              | _(personal)_ Generated and printed for adding to GitHub                  |
| GPG key + gpg-agent            | _(personal)_ Commit signing key, agent configured for passphrase caching |
| pinentry-mac / pinentry-curses | _(personal)_ GPG passphrase prompt (GUI on macOS, terminal on Linux)     |
| keychain                       | _(personal)_ SSH agent persistence across terminal sessions (Linux only) |

> Items marked _(personal)_ are only installed when you answer **y** to the personal machine prompt.

---

## What's Included

| File                 | Repo Path                     | Destination                                      |
| -------------------- | ----------------------------- | ------------------------------------------------ |
| zshrc (Linux / WSL2) | `Linux/.zshrc`                | `~/.zshrc`                                       |
| zshrc (macOS)        | `MacOS/.zshrc`                | `~/.zshrc`                                       |
| git config           | `Common/.gitconfig`           | `~/.gitconfig`                                   |
| Powerlevel10k config | `Common/.p10k.zsh`            | `~/.p10k.zsh`                                    |
| Claude Code settings | `Common/claude/settings.json` | `~/.claude/settings.json`                        |
| GPG agent config     | `Common/gnupg/gpg-agent.conf` | `~/.gnupg/gpg-agent.conf` (written by installer) |
| git local identity   | *(not tracked)*               | `~/.gitconfig.local` (created by installer)       |

---

## Installation

### Prerequisites

- **All platforms** - `git` must be available to clone the repo
- **macOS** - Install Xcode Command Line Tools if not already present:
  ```bash
  xcode-select --install
  ```
- **Linux / WSL2** - No extra prerequisites

### 1. Clone the Repo

```bash
git clone git@github.com:DevTruce/dotfiles.git ~/dev/dotfiles
```

### 2. Run the Installer

```bash
cd ~/dev/dotfiles
bash install.sh
```

The installer detects your OS, symlinks your dotfiles, and prompts whether this is a personal machine. Answering **y** adds SSH/GPG key setup, keychain, and GPG agent configuration. Answering **n** skips those and installs only the core tooling. It then prints a todo list of any remaining manual steps when it finishes.

---

## Manual Steps

The installer handles everything it can automatically, including symlinking all dotfiles into your home directory. On personal machines it also generates SSH/GPG keys and prints them ready to paste. The steps below require manual action and are also printed at the end of every install run as a reminder.

> Steps 1–2 apply to personal machine installs only.

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

The installer prints your full armored public key during setup — copy it directly from the terminal output. To export it again at any time:

```bash
gpg --armor --export YOUR_KEY_ID_HERE
```

Then add it to GitHub:

1. Copy the full output including the `-----BEGIN PGP PUBLIC KEY BLOCK-----` headers
2. Go to **[github.com/settings/keys](https://github.com/settings/keys)**
3. Click **New GPG key**
4. Paste the output

### 3. Install MesloLGS NF Fonts

MesloLGS NF is required for Powerlevel10k to render correctly. Download all four font variants:

**[romkatv/powerlevel10k - MesloLGS NF download](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k)**

**macOS**

1. Double-click each `.ttf` file to install via Font Book
2. Open your terminal preferences and set the font to `MesloLGS NF Regular`

**Linux / WSL2**

Fonts must be installed on the Windows side for Windows Terminal to use them:

1. Double-click each `.ttf` file → **Install for all users**
2. Open **Windows Terminal** → **Settings** → select your profile → **Appearance**
3. Set **Font face** to `MesloLGS NF`

### 4. Open a New Terminal

Open a fresh terminal session for all changes (default shell, plugins, PATH) to take effect.

---

## File Structure

```
dotfiles/
├── Common/                     # dotfiles shared across all platforms
│   ├── .gitconfig              # git identity, aliases, signing, and LFS config
│   ├── .p10k.zsh               # Powerlevel10k prompt configuration
│   ├── claude/
│   │   └── settings.json       # Claude Code settings
│   └── gnupg/
│       └── gpg-agent.conf      # GPG agent cache TTL and pinentry reference
├── Linux/
│   └── .zshrc                  # zsh config for Linux / WSL2
├── MacOS/
│   └── .zshrc                  # zsh config for macOS
├── scripts/                    # modular installer components
│   ├── helpers.sh              # section() output helper and detect_os()
│   ├── package-managers.sh     # setup_homebrew, setup_apt
│   ├── shell.sh                # setup_zsh
│   ├── version-control.sh      # setup_git, setup_git_lfs
│   ├── security.sh             # setup_ssh_key, setup_gpg_key, setup_gpg_agent_conf, setup_keychain
│   ├── dev-environment.sh      # setup_zsh_plugins, setup_nvm
│   ├── dotfiles.sh             # setup_dotfiles - symlinks all dotfiles into home directory
│   ├── utilities.sh            # setup_tree, check_vscode_cli
│   └── finish.sh               # completion banner and manual todo list
└── install.sh                  # entry point: loads scripts, detects OS, dispatches
```

---

## Re-running the Installer

Every function checks whether a tool is already present before doing anything, so re-running is safe and fast - most steps will print "already installed" and skip. Pull the latest changes and re-run to pick up any new tools:

```bash
bash ~/dev/dotfiles/install.sh
```

To run a single component without the full install, source the relevant script after loading helpers and set `OS` - many functions branch on it:

```bash
source ~/dev/dotfiles/scripts/helpers.sh
source ~/dev/dotfiles/scripts/security.sh
OS="$(detect_os)"
PERSONAL_MACHINE="y"
setup_gpg_key
```
