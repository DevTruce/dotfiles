# DOTFILES

Personal dotfiles and automated installer for macOS and Linux / WSL2.

---

## Table of Contents

- [Overview](#overview)
- [Supported Systems](#supported-systems)
- [What Gets Installed](#what-gets-installed)
- [Files Deployed to Your System](#files-deployed-to-your-system)
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
| zinit                          | Zsh plugin manager (plugins download on first shell launch)              |
| zsh-syntax-highlighting        | Command syntax highlighting in the shell                                 |
| zsh-autosuggestions            | Fish-style inline command suggestions                                    |
| zsh-completions                | Extended zsh completion definitions                                      |
| docker completion              | Direct `_docker` completion from the official `docker/cli` repo          |
| Powerlevel10k                  | Fast, highly configurable zsh prompt theme                               |
| nvm                            | Node Version Manager                                                     |
| Node.js LTS                    | Latest long-term support release of Node.js                              |
| tree                           | Directory tree display utility                                           |
| fzf                            | Fuzzy finder — CTRL-R history, CTRL-T file picker, ALT-C cd             |
| zoxide                         | Smart `cd` — jump to frecent dirs with `z`, interactive with `zi`       |
| ripgrep (rg)                   | Fast grep replacement with better defaults                               |
| bat                            | `cat` with syntax highlighting and git integration                       |
| lazygit                        | Terminal UI for git                                                      |
| gh (GitHub CLI)                | GitHub operations (PRs, issues, repos) from the terminal                 |
| pnpm                           | Fast, disk-efficient Node.js package manager                             |
| SSH + GPG keys | _(personal)_ SSH key for GitHub auth; GPG key for commit and tag signing |
| pinentry-mac / pinentry-curses | _(personal)_ GPG passphrase prompt (GUI on macOS, terminal on Linux)     |
| gpg-agent                      | _(personal)_ Passphrase caching for GPG and SSH keys (SSH support: Linux only) |
| Claude Code CLI                | _(personal)_ Terminal AI coding assistant                                |

> Items marked _(personal)_ are only installed when you answer **y** to the personal machine prompt.

---

## Files Deployed to Your System

| File                 | Repo Path                     | Destination                                                 |
| -------------------- | ----------------------------- | ----------------------------------------------------------- |
| zshrc                | `.zshrc`                      | `~/.zshrc`                                                  |
| git config           | `.gitconfig`                  | `~/.gitconfig`                                              |
| git local identity   | _(not tracked)_               | `~/.gitconfig.local` (built by installer)                   |
| Powerlevel10k config | `.p10k.zsh`                   | `~/.p10k.zsh`                                               |
| Claude Code settings | `claude/settings.json`        | `~/.claude/settings.json` _(personal)_                      |
| GPG agent config     | _(not tracked)_               | `~/.gnupg/gpg-agent.conf` (built by installer) _(personal)_ |

---

## Installation

### Prerequisites

- **All platforms** - `git` must be available to clone the repo
- **macOS** - Install Xcode Command Line Tools if not already present:
  ```bash
  xcode-select --install
  ```
- **Linux / WSL2** - `curl` must be available (`sudo apt-get install curl` if not present — the installer also installs it as its first step)

### 1. Clone the Repo

```bash
git clone https://github.com/DevTruce/dotfiles.git ~/dotfiles
```

### 2. Run the Installer

```bash
cd ~/dotfiles
bash install.sh
```

The installer detects your OS, symlinks your dotfiles, and prompts whether this is a personal machine. Answering **y** adds SSH/GPG key setup, GPG agent configuration, and Claude Code CLI. Answering **n** skips those and installs only the core tooling. It then prints a todo list of any remaining manual steps when it finishes.

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

MesloLGS NF is required for Powerlevel10k to render correctly. Click each link to download the file directly:

- [MesloLGS NF Regular.ttf](https://github.com/DevTruce/dotfiles/raw/main/fonts/MesloLGS%20NF%20Regular.ttf)
- [MesloLGS NF Bold.ttf](https://github.com/DevTruce/dotfiles/raw/main/fonts/MesloLGS%20NF%20Bold.ttf)
- [MesloLGS NF Italic.ttf](https://github.com/DevTruce/dotfiles/raw/main/fonts/MesloLGS%20NF%20Italic.ttf)
- [MesloLGS NF Bold Italic.ttf](https://github.com/DevTruce/dotfiles/raw/main/fonts/MesloLGS%20NF%20Bold%20Italic.ttf)

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
├── .gitconfig                  # git aliases, LFS config, and default settings (identity in ~/.gitconfig.local)
├── .p10k.zsh                   # Powerlevel10k prompt configuration
├── .zshrc                      # zsh config for all platforms (uses $OSTYPE for platform-specific blocks)
├── claude/
│   └── settings.json           # Claude Code settings
├── fonts/                      # MesloLGS NF font files (install manually — see Manual Steps)
│   ├── MesloLGS NF Regular.ttf
│   ├── MesloLGS NF Bold.ttf
│   ├── MesloLGS NF Italic.ttf
│   └── MesloLGS NF Bold Italic.ttf
├── scripts/                    # modular installer components
│   ├── helpers.sh              # section() output helper and detect_os()
│   ├── package-managers.sh     # setup_homebrew, setup_apt
│   ├── shell.sh                # setup_zsh
│   ├── version-control.sh      # setup_git, setup_git_lfs
│   ├── security.sh             # setup_gpg_tools, setup_ssh_key, setup_gpg_key, setup_gpg_agent_conf
│   ├── dev-environment.sh      # setup_zsh_plugins, setup_nvm, setup_pnpm, setup_claude
│   ├── dotfiles.sh             # setup_dotfiles - symlinks all dotfiles into home directory
│   ├── utilities.sh            # setup_tree, setup_fzf, setup_zoxide, setup_ripgrep, setup_bat, setup_lazygit, setup_gh
│   └── finish.sh               # completion banner and manual todo list
├── install.sh                  # entry point: loads scripts, detects OS, dispatches
└── run.sh                      # run a single setup function without the full install
```

---

## Re-running the Installer

Every function checks whether a tool is already present before doing anything, so re-running is safe and fast - most steps will print "already installed" and skip. Pull the latest changes and re-run to pick up any new tools:

```bash
bash ~/dotfiles/install.sh
```

To run a single setup function without the full install, use `run.sh`. It loads all scripts, detects your OS, and prompts for the personal machine flag automatically:

```bash
bash ~/dotfiles/run.sh setup_gpg_key
```

Replace `setup_gpg_key` with any function name from the `scripts/` directory.
