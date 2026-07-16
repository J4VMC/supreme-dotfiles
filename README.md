# Dotfiles Configuration

This repository contains a modular and organized collection of configuration files (dotfiles) for a macOS-based development environment. It is designed to be managed using **GNU Stow** and features a heavy focus on **Emacs**, the **Fish shell**, and modern CLI tools.

## 🚀 Quick Start

### Prerequisites

Before setting up this environment, you must have **Homebrew** installed. If you do not have it, install it using the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

```


### Installation

1. **Clone the repository:**
```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles

```


2. **Install dependencies via Homebrew:**
```bash
brew bundle --file=homebrew/.Brewfile

```


3. **Stow the configurations:**
```bash
stow emacs emacs-plus fish git ghostty starship fastfetch homebrew

```

> **Note:** `homebrew` is not optional — the `maintain` command dumps the package list with `brew bundle dump --global`, which writes to `~/.Brewfile`; only the stow symlink makes that land in this repository. `emacs-plus` provides the build configuration (`~/.config/emacs-plus/build.yml`) used when compiling Emacs.



---

## 🛠 Component Overview

### 📦 Homebrew (`.Brewfile`)

The environment is powered by a curated list of CLI tools and applications:

* **Editor**: `emacs-plus@30` (via the `d12frosted/emacs-plus` tap), built with xwidgets, dbus, and mailutils.
* **Languages & Runtimes**: PHP, Go, OpenJDK, and Python tooling via `pipx` (with `pyenv` managing interpreters — see the Emacs README for the full per-language setup).
* **Modern CLI**: `bat` (cat replacement), `eza` (ls replacement), `fd`, `ripgrep`, `fzf`, and `zoxide`.
* **Utilities**: `docker`, `cmake`, `imagemagick`, `pandoc`, and `stow`.

### 🐟 Fish Shell

The Fish configuration is split between `config.fish` and modular functions.

* **Prompt**: Powered by **Starship** with transient prompt support.
* **Plugin Management**: Uses `fisher` with plugins including `bass`, `nvm.fish`, `fzf.fish` (which owns `Ctrl-R` history search), and `sponge`.
* **Key Features**:
* **Init Snapshots**: `starship`, `zoxide`, and `direnv` inits are committed as static `conf.d/` snapshots instead of being re-generated on every shell start — much faster startups. `regen-shell-inits` refreshes them after upgrades (`maintain` does this automatically).
* **Auto-Updates**: Automatically runs a background Homebrew update check (`brew_daily_update`) once per day.
* **Theme**: Customized with a **Gruvbox** color palette.
* **Aliases**: Includes `ls` (eza), `cat` (bat), and `maintain` for full system maintenance.



### 💜 Emacs

A high-performance, modular Emacs configuration using the **Elpaca** package manager and `use-package`.

* **Startup**: Optimized with `early-init.el` and a high garbage collection threshold during boot.
* **Modular Design**: Settings are organized into the `modules/` directory, covering completion, LSP, tree-sitter, and language-specific modes.
* **AI Agents**: Claude Code integrated two ways (quick drawer + IDE-style with ediff review), plus a vendor-neutral ACP lane currently driving Gemini — with per-project credentials via direnv. See the Emacs README for details.
* **Environment**: Uses `exec-path-from-shell` to ensure Emacs inherits environment variables like `$PATH` from your shell.
* **Theme**: `gruvbox-dark-hard`.

### ⚙️ Git

* **Default Branch**: Set to `main`.
* **Global Ignore**: Uses `~/.gitignore_global` for system-wide exclusions.
* **Extensibility**: Includes a `~/.gitconfig.local` for machine-specific overrides.

---

## ⌨️ Useful Custom Aliases

| Alias | Command |
| --- | --- |
| `maintain` | Full system sync: brew update/upgrade/cleanup, fisher update, Brewfile dump, and shell-snapshot regen |
| `brewup` | Abbreviation for `maintain` (kept for muscle memory) |
| `brewed` | Dumps current Brew state to the `homebrew/.Brewfile` |
| `python` | Maps to `python3` |
| `ls` | `eza --icons` |
| `cat` | `bat --paging=never` |

---

## 📂 Directory Structure

* `emacs/`: Emacs configuration (`init.el` and modules).
* `emacs-plus/`: Build configuration for the emacs-plus formula (`build.yml`).
* `fish/`: Fish shell configuration and functions.
* `git/`: Global Git configuration.
* `homebrew/`: System package manifest (stowed so `maintain` can keep it in sync).
* `fastfetch/`: System information display config.
* `ghostty/`: Terminal emulator configuration.
* `starship/`: Cross-shell prompt configuration.
* `lefthook.yml`: Commit hooks for this repository itself (Conventional Commits check via Cocogitto).
