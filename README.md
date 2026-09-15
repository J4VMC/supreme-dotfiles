# Dotfiles Configuration

This repository contains a modular and organized collection of configuration files (dotfiles) for a macOS-based development environment. It is designed to be managed using **GNU Stow** and features a heavy focus on **Emacs**, the **Fish shell**, and modern CLI tools.

## 🚀 Quick Start

### Prerequisites

Before setting up this environment, you must have **Homebrew** installed. If you do not have it, install it using the following command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

```

### Installation

The order below matters: `stow` links the configuration **before** `brew bundle` runs, so the Brewfile is read from its stowed location (`~/.Brewfile`, the same file `maintain` dumps to) and the `emacs-plus` build finds `~/.config/emacs-plus/build.yml` (the formula reads it at build time; without it the custom icon is skipped).

1. **Clone the repository:**

```bash
git clone --recurse-submodules <repository-url> ~/dotfiles
cd ~/dotfiles

```

> **Note:** `emacs` and `fish` are git submodules, referenced by their SSH URLs (`git@github.com:J4VMC/...`) so pushes from this machine use its SSH key. On a machine without a GitHub SSH key, rewrite them to HTTPS before initialising: `git config --global url."https://github.com/".insteadOf git@github.com:`. If you cloned without `--recurse-submodules`, run `git submodule update --init` **before** stowing — stow walks whatever is in the package directory, and an uninitialised submodule is an empty directory, so `stow fish` links nothing and reports no error.

2. **Install GNU Stow and link the configuration:**

```bash
brew install stow

```

```bash
stow stow

```

```bash
stow emacs emacs-plus fish git ghostty starship fastfetch homebrew npm bin

```

```bash
stow --no-folding herdr

```

> **Note:** stow `stow` first, **for real** (not with `-n`). It links `~/.stow-global-ignore`, which is the only ignore file GNU Stow reads for a whole stow directory (a `.stow-local-ignore` is only honoured inside the individual package it sits in), and Stow only consults it once that link exists. Until then every package is filtered by Stow's built-in list, which knows nothing about `.DS_Store`, `lefthook.yml` or `.gitattributes` — so a dry run of the package command (`stow -n emacs ...`), a `stow */` that does everything in one go, or running the package command before `stow stow` all fail with conflicts (`emacs` and `fish` both carry a `lefthook.yml`; Finder drops `.DS_Store` files that collide with `~/.DS_Store`) or link those files into `~`. If that already happened, `stow -D <package>` removes the stray links.

> **Note:** stow `fish` **before** opening a fish shell on a new machine. Fish's first start creates a real `~/.config/fish/` (with a stub `config.fish` and empty `conf.d/`, `functions/`, `completions/`). Stow cannot fold a symlink over an existing directory, so it silently falls back to linking file by file, and `--adopt` would then overwrite the tracked `config.fish` with the stub. If that already happened: move `~/.config/fish/fish_variables` and `~/.config/fish/plugins/` aside, `stow -D fish`, delete the now-empty `~/.config/fish`, `stow fish`, and move the two items back (they are gitignored in the package).

> **Note:** `herdr` must be stowed with `--no-folding` — herdr writes runtime state (logs, `session.json`, `sessions/`, its API socket) next to its config, and a folded `~/.config/herdr` symlink would land all of that inside this repository. `--no-folding` keeps the directory real and links only `config.toml`. Run `herdr integration install claude` once per machine so herdr receives real agent state from Claude Code (the hook installs into `~/.claude`, outside this repo).

> **Note:** `homebrew` and `npm` are not optional — the `maintain` command dumps both package lists (`brew bundle dump --global` and `npm-globals dump`) to `~/.Brewfile` and `~/.npm-globals`; only the stow symlinks make those land in this repository. `emacs-plus` provides the build configuration (`~/.config/emacs-plus/build.yml`) used when compiling Emacs.

> **Note:** stowing `npm` also links `~/.npmrc`. If a real file is already there, stow refuses the whole package — check that the existing one holds no credentials, then either delete it or run `stow --adopt npm` and `git diff` to see what it pulled in.

> **Note:** do **not** run `lefthook install` here (or in any repo). `git/.gitconfig` sets a global `core.hooksPath` (`~/.config/git/hooks`), which makes git ignore per-repo `.git/hooks` entirely, and lefthook refuses to install under a custom hooks path (`--force` would overwrite the global hooks for every repository). Instead the global hooks themselves hand off to `lefthook run <hook>` whenever the repository has a `lefthook.yml`, so this repository's hooks (and every project's) are active as soon as `git` is stowed and `lefthook` is installed.

3. **Create `~/.gitconfig.local` with your identity:**

```bash
printf '[user]\n    name = Your Name\n    email = you@example.com\n' > ~/.gitconfig.local

```

> **Note:** this is required, not optional. The stowed `~/.gitconfig` sets `user.useConfigOnly`, so git refuses to guess an identity from the login name and hostname, and **every commit fails** until this file defines `user.name` and `user.email` (the `cog verify` commit hook needs `user.name` as well). The file is the last `[include]` in `~/.gitconfig`, so anything in it — per-client `includeIf` routing, a different signing key or credential helper — overrides the committed defaults. Commits are SSH-signed with `~/.ssh/id_ed25519.pub`; to *verify* signatures locally (`git log --show-signature`) also create `~/.ssh/allowed_signers` with one `<email> <public key>` line per identity.

4. **Install dependencies via Homebrew:**

```bash
brew bundle --global

```

> **Note:** `~/.Brewfile` is the stowed `homebrew/.Brewfile`. Every formula from a third-party tap carries `trusted: true`: Homebrew 7 refuses to load anything from an untrusted tap (`Refusing to load formula ... from untrusted tap ...`), and that option pre-registers each one in `~/.homebrew/trust.json` before tapping. Installing one of those by hand instead needs `brew trust <tap>` (or `brew trust --formula <tap>/<name>`) first.

> **Note:** the Brewfile deliberately carries **no** `npm "..."` entries even though `brew bundle dump` emits them: `config.fish` sets `HOMEBREW_BUNDLE_DUMP_NO_NPM` so `maintain` keeps them out. npm globals belong to nvm's Node and are installed from `~/.npm-globals` in step 6; `brew bundle` would install them into Homebrew's `node` (pulled in as a dependency of `agent-browser`), which is never used. The `go "..."` entries are fine: they land in `~/go/bin`, which `config.fish` puts on `PATH`.

> **Note:** if Emacs was built *before* `emacs-plus` was stowed, re-apply the icon from `build.yml` with `brew postinstall d12frosted/emacs-plus/emacs-plus@31` — no rebuild needed.

> **Note:** the `emacs-plus` **formula** leaves `Emacs.app` and `Emacs Client.app` in `/opt/homebrew/opt/emacs-plus@31/` — nothing appears in `/Applications` until you copy them there yourself (the `emacs-plus-app` cask would, but it cannot coexist with the formula). Copy *after* the icon has been applied, and again after any `brew upgrade` that rebuilds Emacs, or the copies silently fall behind the `emacs` on `PATH`:

```bash
cp -R /opt/homebrew/opt/emacs-plus@31/Emacs.app "/opt/homebrew/opt/emacs-plus@31/Emacs Client.app" /Applications/

```

5. **Make fish the login shell:**

```bash
echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells && chsh -s "$(brew --prefix)/bin/fish"

```

> **Note:** Ghostty launches fish explicitly (its `command` probes both Homebrew prefixes), so it works without this — but Terminal.app, `exec-path-from-shell` in Emacs and anything else that consults `$SHELL` keeps starting zsh until the login shell is changed. `chsh` needs the path in `/etc/shells` first. Steps 1–5 run from the zsh a fresh Mac gives you; everything from here on is fish syntax, so open a new terminal (or run `fish`) first.

6. **Install Node and its global packages:**

```bash
nvm install lts; and set -U nvm_default_version (node --version); and npm-globals install

```

> **Note:** Node comes **only** from `nvm.fish`. Homebrew may still install a `node` formula as a dependency of something else (currently `agent-browser`); that copy is never used directly, `config.fish` puts nvm's default version ahead of it on `PATH` in every shell. `nvm_default_version` must be the concrete version (`v24.21.0`), not `lts`, which is why the command above reads it back from `node --version`. Without a default, new shells have no Node at all.

> **Note:** `docker compose` is a CLI plugin. Homebrew's `docker-compose` formula installs it under `$(brew --prefix)/lib/docker/cli-plugins`, where the `docker` CLI does not look by default. Add that directory to `cliPluginsExtraDirs` in `~/.docker/config.json` once per machine (the file also holds registry logins, so it is not stowed):

```bash
jq --arg d "$(brew --prefix)/lib/docker/cli-plugins" '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$d] | unique)' ~/.docker/config.json > ~/.docker/config.json.new; and mv ~/.docker/config.json.new ~/.docker/config.json

```

---

## 🛠 Component Overview

### 📦 Homebrew (`.Brewfile`)

The environment is powered by a curated list of CLI tools and applications:

- **Editor**: `emacs-plus@31` (via the `d12frosted/emacs-plus` tap), built with xwidgets, dbus, and mailutils.
- **Languages & Runtimes**: PHP, Go, OpenJDK, and Python tooling via `pipx` (with `pyenv` managing interpreters — see the Emacs README for the full per-language setup).
- **Modern CLI**: `bat` (cat replacement), `eza` (ls replacement), `fd`, `ripgrep`, `fzf`, and `zoxide`.
- **Utilities**: `docker` + `docker-compose` (with `colima` as the runtime), `cmake`, `imagemagick`, `pandoc`, and `stow`.
- **AI CLIs**: `claude-code` is installed as a Homebrew **cask** (`brew install --cask claude-code`), never through npm, so it updates with `brew upgrade` like everything else.
- **Go tools**: `gopls`, `dlv`, `goimports`, `golangci-lint` and `sqls` are `go "..."` entries, which `brew bundle` installs with `go install` into `~/go/bin` (on `PATH` via `config.fish`; Emacs adds it to `exec-path` itself).

### 📦 Global npm packages (`.npm-globals`)

Node itself is managed by `nvm.fish`; the globally-installed npm packages are pinned in a plain manifest, the npm counterpart of the Brewfile. It is the **only** place they are listed: `brew bundle dump` would also emit them as `npm "..."` lines, but `config.fish` exports `HOMEBREW_BUNDLE_DUMP_NO_NPM` so `maintain` never writes them into the Brewfile (see step 4 of the installation for why).

- **Manifest**: `~/.npm-globals` — one package per line, `#` comments allowed, `@version` suffix to pin.
- **Contents**: language servers (`typescript-language-server`, `bash-language-server`, `svelte`, `vue`, `intelephense`, `vscode-langservers-extracted`), formatters (`prettier`), `corepack` (no longer bundled with Node since Node 25), and AI CLIs (`@google/gemini-cli`, `@google/jules`). Claude Code is deliberately **not** here; it is the `claude-code` Homebrew cask.
- **Caveat**: nvm installs globals _per Node version_. After `nvm install <version>`, re-run `npm-globals install` to repopulate that version.

### 🐟 Fish Shell

The Fish configuration is split between `config.fish` and modular functions.

- **Prompt**: Powered by **Starship** with transient prompt support.
- **Plugin Management**: Uses `fisher` with `bass`, `nvm.fish`, `fzf.fish` (which owns `Ctrl-R` history search), `sponge`, `puffer-fish` (expands `!!`, `$$`, `...`), and `fish-abbreviation-tips`. The full list is `fish_plugins`.
- **Completions**: `generate-completions <cmd> ...` snapshots a CLI's fish completions into `completions/` for tools that do not ship them through Homebrew (`jules`, `ngrok`, `symfony`). Homebrew formulae that ship their own (`gh`, `docker`) are picked up from `vendor_completions.d` and are deliberately not duplicated here.
- **Key Features**:
- **Init Snapshots**: `starship`, `zoxide`, and `direnv` inits are committed as static `conf.d/` snapshots instead of being re-generated on every shell start — much faster startups. `regen-shell-inits` refreshes them after upgrades (`maintain` does this automatically).
- **Auto-Updates**: Automatically runs a background Homebrew update check (`brew_daily_update`) once per day.
- **Theme**: Customized with a **Gruvbox** color palette.
- **Aliases**: Includes `ls` (eza), `cat` (bat), and `maintain` for full system maintenance.

### 💜 Emacs

A high-performance, modular Emacs configuration using the **Elpaca** package manager and `use-package`.

- **Startup**: Optimized with `early-init.el` and a high garbage collection threshold during boot.
- **Modular Design**: Settings are organized into the `modules/` directory, covering completion, LSP, tree-sitter, and language-specific modes.
- **AI Agents**: Claude Code integrated two ways (quick drawer + IDE-style with ediff review), plus a vendor-neutral ACP lane currently driving Gemini — with per-project credentials via direnv. See the Emacs README for details.
- **Environment**: Uses `exec-path-from-shell` to ensure Emacs inherits environment variables like `$PATH` from your shell.
- **Theme**: `gruvbox-dark-hard`.

### ⚙️ Git

- **Default Branch**: Set to `main`.
- **Global Ignore**: Uses `~/.gitignore_global` for system-wide exclusions.
- **Identity**: `user.useConfigOnly` is set and no name/email is committed — `~/.gitconfig.local` (untracked) **must** define them or commits fail. Its `[include]` is the last section of `~/.gitconfig`, so everything in it overrides the committed defaults.
- **Signing**: commits are SSH-signed with `~/.ssh/id_ed25519.pub`; `~/.ssh/allowed_signers` is only needed to verify signatures locally.
- **Diffs**: paged through `delta` with the `gruvbox-dark` syntax theme.
- **Global hooks**: `core.hooksPath` points at `~/.config/git/hooks`. `commit-msg` strips AI-assistant attribution trailers, and every hook then runs `lefthook run <hook> --no-auto-install` if the repository has a `lefthook.yml`, so project lefthook configs work without `lefthook install` (which the global hooks path makes impossible).

---

## ⌨️ Useful Custom Aliases

| Alias                 | Command                                                                                                                       |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `maintain`            | Full system sync: brew update/upgrade/cleanup, fisher update, Brewfile dump, npm global update/dump, and shell-snapshot regen |
| `brewup`              | Abbreviation for `maintain` (kept for muscle memory)                                                                          |
| `brewed`              | `brew bundle dump --global --force`: dumps current Brew state to `~/.Brewfile`, i.e. the stowed `homebrew/.Brewfile`          |
| `npm-globals install` | Installs every package listed in `npm/.npm-globals` into the active Node version                                              |
| `npm-globals dump`    | Dumps the current global npm packages to `npm/.npm-globals`                                                                   |
| `python`              | Maps to `python3`                                                                                                             |
| `ls`                  | `eza --icons`                                                                                                                 |
| `cat`                 | `bat --paging=never`                                                                                                          |

---

## 📂 Directory Structure

- `stow/`: `~/.stow-global-ignore`, the only ignore list GNU Stow applies to the whole stow directory. Stow it first.
- `bin/`: scripts linked into `~/bin`. Only the client-free `chrome-route` (profile-routing `$BROWSER` launcher) is tracked; everything else in `bin/bin/` is gitignored on purpose.
- `emacs/`: Emacs configuration (`init.el` and modules).
- `emacs-plus/`: Build configuration for the emacs-plus formula (`build.yml`).
- `fish/`: Fish shell configuration and functions.
- `git/`: Global Git configuration.
- `homebrew/`: System package manifest (stowed to `~/.Brewfile` so `maintain` can keep it in sync; `brew bundle --global` installs from it). Carries taps, formulae, casks, VS Code extensions and Go tools — never `npm` entries.
- `npm/`: Global npm package manifest (stowed so `maintain` can keep it in sync) plus `.npmrc`, which carries the `allow-scripts` list npm requires before a package's install scripts may run. **Never put a registry token in `npm/.npmrc`** — it is stowed to `~/.npmrc`, where `npm login` writes credentials, and this repository is public.
- `fastfetch/`: System information display config.
- `ghostty/`: Terminal emulator configuration.
- `starship/`: Cross-shell prompt configuration.
- `herdr/`: Config for the herdr agent multiplexer (`config.toml` only; stow with `--no-folding`, see above).
- `lefthook.yml`: Commit hooks for this repository itself (Conventional Commits check via Cocogitto, and a pre-commit guard that rejects credentials staged into `npm/.npmrc`), executed by the global git hooks above.
