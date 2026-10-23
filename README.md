# Dotfiles

A modular macOS development environment, managed with **GNU Stow** and centred on **Emacs 31**, the **Fish shell**, **Ghostty** and a curated Homebrew manifest. The repository is public; everything machine- or client-specific stays out of it on purpose (see [What is deliberately not tracked](#what-is-deliberately-not-tracked)).

The Emacs and Fish configurations are separate repositories, pulled in as git submodules:

| Package | Repository | Linked to |
| ------- | ---------- | --------- |
| `emacs` | [J4VMC/supreme-emacs](https://github.com/J4VMC/supreme-emacs) — has its own [README](emacs/.config/emacs/README.md) | `~/.config/emacs` |
| `fish`  | [J4VMC/supreme-fish](https://github.com/J4VMC/supreme-fish) — has its own [README](fish/README.md) | `~/.config/fish` |

## 🚀 Quick Start

### Prerequisites

- macOS on Apple silicon or Intel (every path is derived from the Homebrew prefix, so both work).
- **Homebrew**. If you do not have it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Installation

The order below matters: `stow` links the configuration **before** `brew bundle` runs, so the Brewfile is read from its stowed location (`~/.Brewfile`, the same file `maintain` dumps to) and the `emacs-plus` build finds `~/.config/emacs-plus/build.yml` (the formula reads it at build time; without it the custom icon is skipped).

#### 1. Clone the repository

```bash
git clone --recurse-submodules git@github.com:J4VMC/supreme-dotfiles.git ~/dotfiles
cd ~/dotfiles
```

> **Note:** `emacs` and `fish` are git submodules, referenced by their SSH URLs (`git@github.com:J4VMC/...`) so pushes from a machine with write access use its SSH key. On a machine without a GitHub SSH key, rewrite them to HTTPS before initialising: `git config --global url."https://github.com/".insteadOf git@github.com:`. If you cloned without `--recurse-submodules`, run `git submodule update --init` **before** stowing — stow walks whatever is in the package directory, and an uninitialised submodule is an empty directory, so `stow fish` links nothing and reports no error.

#### 2. Install GNU Stow and link the configuration

```bash
brew install stow
stow stow
stow emacs emacs-plus fish git ghostty starship fastfetch homebrew npm bin zsh
stow --no-folding herdr
```

> **Note:** stow `stow` first, **for real** (not with `-n`). It links `~/.stow-global-ignore`, which is the only ignore file GNU Stow reads for a whole stow directory (a `.stow-local-ignore` is only honoured inside the individual package it sits in), and Stow only consults it once that link exists. Until then every package is filtered by Stow's built-in list, which knows nothing about `.DS_Store`, `lefthook.yml` or `.gitattributes` — so a dry run of the package command (`stow -n emacs ...`), a `stow */` that does everything in one go, or running the package command before `stow stow` all fail with conflicts (`emacs` and `fish` both carry a `lefthook.yml`; Finder drops `.DS_Store` files that collide with `~/.DS_Store`) or link those files into `~`. If that already happened, `stow -D <package>` removes the stray links.

> **Note:** stow `fish` **before** opening a fish shell on a new machine. Fish's first start creates a real `~/.config/fish/` (with a stub `config.fish` and empty `conf.d/`, `functions/`, `completions/`). Stow cannot fold a symlink over an existing directory, so it silently falls back to linking file by file, and `--adopt` would then overwrite the tracked `config.fish` with the stub. If that already happened: move `~/.config/fish/fish_variables` and `~/.config/fish/plugins/` aside, `stow -D fish`, delete the now-empty `~/.config/fish`, `stow fish`, and move the two items back (both are gitignored inside the submodule).

> **Note:** `herdr` must be stowed with `--no-folding` — herdr writes runtime state (logs, `session.json`, `sessions/`, its API socket) next to its config, and a folded `~/.config/herdr` symlink would land all of that inside this repository. `--no-folding` keeps the directory real and links only `config.toml`. Run `herdr integration install claude` once per machine so herdr receives real agent state from Claude Code (the hook installs into `~/.claude`, outside this repo).

> **Note:** `homebrew` and `npm` are not optional — the `maintain` command dumps both package lists (`brew bundle dump --global` and `npm-globals dump`) to `~/.Brewfile` and `~/.npm-globals`; only the stow symlinks make those land in this repository. `emacs-plus` provides the build configuration (`~/.config/emacs-plus/build.yml`) used when compiling Emacs.

> **Note:** stowing `npm` also links `~/.npmrc`. If a real file is already there, stow refuses the whole package — check that the existing one holds no credentials, then either delete it or run `stow --adopt npm` and `git diff` to see what it pulled in.

> **Note:** do **not** run `lefthook install` here (or in any repo). `git/.gitconfig` sets a global `core.hooksPath` (`~/.config/git/hooks`), which makes git ignore per-repo `.git/hooks` entirely, and lefthook refuses to install under a custom hooks path (`--force` would overwrite the global hooks for every repository). Instead the global hooks themselves hand off to `lefthook run <hook>` whenever the repository has a `lefthook.yml`, so this repository's hooks (and every project's) are active as soon as `git` is stowed and `lefthook` is installed.

#### 3. Create `~/.gitconfig.local` with your identity

```bash
printf '[user]\n    name = Your Name\n    email = you@example.com\n' > ~/.gitconfig.local
```

> **Note:** this is required, not optional. The stowed `~/.gitconfig` sets `user.useConfigOnly`, so git refuses to guess an identity from the login name and hostname, and **every commit fails** until this file defines `user.name` and `user.email` (the `cog verify` commit hook needs `user.name` as well). The file is the last `[include]` in `~/.gitconfig`, so anything in it — per-client `includeIf` routing, a different signing key or credential helper — overrides the committed defaults. Commits are SSH-signed with `~/.ssh/id_ed25519.pub`; on a machine whose key has another name, set `user.signingkey` in this file too. To *verify* signatures locally (`git log --show-signature`) also create `~/.ssh/allowed_signers` with one `<email> <public key>` line per identity.

#### 4. Install dependencies via Homebrew

```bash
brew bundle --global
```

> **Note:** `~/.Brewfile` is the stowed `homebrew/.Brewfile`. Homebrew 7 refuses to load anything from an untrusted tap (`Refusing to load formula ... from untrusted tap ...`), so every third-party formula is pre-registered in `~/.homebrew/trust.json` before tapping: formulae that are installed carry `trusted: true` on their own line, and the `gromgit/fuse` tap line carries `trusted: { formulae: [...] }` for `rclone-mac` and `sshfs-mac`, which are trusted but only installed on demand (`s3mount` needs `rclone-mac`). Installing one of those by hand instead needs `brew trust <tap>` (or `brew trust --formula <tap>/<name>`) first.

> **Note:** the Brewfile deliberately carries **no** `npm "..."` entries even though `brew bundle dump` emits them: `config.fish` sets `HOMEBREW_BUNDLE_DUMP_NO_NPM` so `maintain` keeps them out. npm globals belong to nvm's Node and are installed from `~/.npm-globals` in step 6; `brew bundle` would install them into Homebrew's `node` (pulled in as a dependency of `agent-browser`), which is never used. The `go "..."` entries are fine: they land in `~/go/bin`, which `config.fish` puts on `PATH`.

> **Note:** if Emacs was built *before* `emacs-plus` was stowed, re-apply the icon from `build.yml` with `brew postinstall d12frosted/emacs-plus/emacs-plus@31` — no rebuild needed.

> **Note:** the `emacs-plus` **formula** leaves `Emacs.app` and `Emacs Client.app` in `/opt/homebrew/opt/emacs-plus@31/` — nothing appears in `/Applications` until you copy them there yourself (the `emacs-plus-app` cask would, but it cannot coexist with the formula). Copy *after* the icon has been applied, and again after any `brew upgrade` that rebuilds Emacs, or the copies silently fall behind the `emacs` on `PATH`:

```bash
cp -R /opt/homebrew/opt/emacs-plus@31/Emacs.app "/opt/homebrew/opt/emacs-plus@31/Emacs Client.app" /Applications/
```

#### 5. Make fish the login shell

```bash
echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells && chsh -s "$(brew --prefix)/bin/fish"
```

> **Note:** Ghostty launches fish explicitly (its `command` probes both Homebrew prefixes), so it works without this — but Terminal.app, `exec-path-from-shell` in Emacs and anything else that consults `$SHELL` keeps starting zsh until the login shell is changed. `chsh` needs the path in `/etc/shells` first. Steps 1–5 run from the zsh a fresh Mac gives you; everything from here on is fish syntax, so open a new terminal (or run `fish`) first.

#### 6. Install Node and its global packages

```fish
nvm install lts; and set -U nvm_default_version (node --version); and npm-globals install
```

> **Note:** Node comes **only** from `nvm.fish`. Homebrew may still install a `node` formula as a dependency of something else (currently `agent-browser`); that copy is never used directly, `config.fish` puts nvm's default version ahead of it on `PATH` in every shell. `nvm_default_version` must be the concrete version (`v24.21.0`), not `lts`, which is why the command above reads it back from `node --version`. Without a default, new shells have no Node at all.

> **Note:** `docker compose` is a CLI plugin. Homebrew's `docker-compose` formula installs it under `$(brew --prefix)/lib/docker/cli-plugins`, where the `docker` CLI does not look by default. Add that directory to `cliPluginsExtraDirs` in `~/.docker/config.json` once per machine (the file also holds registry logins, so it is not stowed):

```fish
jq --arg d "$(brew --prefix)/lib/docker/cli-plugins" '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$d] | unique)' ~/.docker/config.json > ~/.docker/config.json.new; and mv ~/.docker/config.json.new ~/.docker/config.json
```

#### 7. Install Karabiner-Elements

The keyboard layout this environment assumes is **Caps Lock → Escape when tapped, Control when held**. Emacs, the terminal and the `C-`-heavy bindings everywhere in this setup are built around that key, and it comes from [Karabiner-Elements](https://karabiner-elements.pqrs.org/), not from macOS.

```fish
brew install --cask karabiner-elements
```

Then, in **System Settings → Privacy & Security**, allow the Karabiner driver extension (*Driver Extensions*) and grant **Input Monitoring** to `karabiner_grabber` and `karabiner_observer` when macOS asks; the app does not remap anything until both are granted. Finally add the rule: in Karabiner-Elements → *Complex Modifications* → *Add predefined rule*, enable *"Change caps_lock to control if pressed with other keys, to escape if pressed alone"* (the same rule, locally titled *"Tap Caps Lock for ESC or Hold for Control"*, is the only one in use).

> **Note:** Karabiner is **not** in the Brewfile and its configuration is **not** stowed, both on purpose. The cask refuses to install over an `Karabiner-Elements.app` that was downloaded from the website (which is how the current machine got it), so a `brew bundle` that listed it would fail there, and `~/.config/karabiner/karabiner.json` is rewritten by the app itself (it also keeps `automatic_backups/` next to it), which makes a stowed copy churn constantly. The rule above is the whole configuration, so recreating it by hand is quicker than tracking the file.

---

## 🛠 Component Overview

### 📦 Homebrew (`homebrew/.Brewfile`)

Stowed to `~/.Brewfile`, installed with `brew bundle --global`, and kept in sync by `maintain` (`brew bundle dump --global --force`). It currently carries 7 taps, 74 formulae, 12 casks, 13 VS Code extensions and 5 Go tools:

- **Editor**: `emacs-plus@31` (via the `d12frosted/emacs-plus` tap), built with `--with-compress-install --with-dbus --with-debug --with-mailutils --with-xwidgets`; the icon comes from `emacs-plus/.config/emacs-plus/build.yml`.
- **Languages & runtimes**: `php` + `composer`, `go`, `openjdk` + `maven` + `gradle` + `sbt` + `coursier`, `ruby`, `bun`, Python tooling via `pyenv`, `pipx` and `uv`, `postgresql@18`, `sqlite`. Node is **not** here (see npm below). Rust is not here either: `rustup` is installed from rustup.rs, and `fish/conf.d/rustup.fish` sources `~/.cargo/env.fish` when it exists.
- **Language tooling the Emacs config expects**: `libgccjit` (native compilation), `tree-sitter`, `enchant` + `pkgconf` (spell checking), `coreutils`, `shellcheck` + `shfmt`, `hadolint`, `taplo`, `google-java-format`, `pandoc`, `imagemagick`, `librsvg`. The per-language details are in the [Emacs README](emacs/.config/emacs/README.md#step-5-install-language-specific-tools).
- **Modern CLI**: `bat`, `eza`, `fd`, `ripgrep`, `fzf`, `zoxide`, `grep` (GNU), `grc`, `yq`, `watch`, `fastfetch`, `starship`, `git-delta`, `git-filter-repo`, `gh`. (`jq`, which `npm-globals dump` and the docker step need, is the copy macOS ships in `/usr/bin`.)
- **Shell & environment**: `fish`, `direnv`, `stow`, `lefthook`, `cocogitto`, `herdr`, `gnupg` + `pinentry-mac`, `texinfo`.
- **Containers, cloud & infra**: `docker` + `docker-compose` with `colima` as the runtime (no Docker Desktop), `kubernetes-cli`, `helm`, `k3d`, `tilt`, `terraform`, `awscli`, `cloudflared`, `cloudflare-wrangler`, `openbao`, `ddev`, `flipt`, `symfony-cli`, `agent-browser`.
- **Go tools**: `gopls`, `dlv`, `goimports`, `golangci-lint` and `sqls` are `go "..."` entries, which `brew bundle` installs with `go install` into `~/go/bin` (on `PATH` via `config.fish`; Emacs adds it to `exec-path` itself).
- **Casks**: `claude-code@latest` (Claude Code comes from Homebrew, never npm, so it updates with everything else), `ghostty`, `visual-studio-code` (plus its `vscode "..."` extensions), `1password-cli`, `postman-cli`, `ngrok`, `macfuse`, `zettlr`, `pearcleaner`, `logi-options+`, and the two fonts the whole setup renders with: `font-fira-code-nerd-font` and `font-symbols-only-nerd-font`.

### 📦 Global npm packages (`npm/.npm-globals`)

Node itself is managed by `nvm.fish`; the globally-installed npm packages are pinned in a plain manifest, the npm counterpart of the Brewfile. It is the **only** place they are listed: `brew bundle dump` would also emit them as `npm "..."` lines, but `config.fish` exports `HOMEBREW_BUNDLE_DUMP_NO_NPM` so `maintain` never writes them into the Brewfile (see step 4 of the installation for why).

- **Manifest**: `~/.npm-globals` — one package per line, `#` comments allowed, `@version` suffix to pin. `npm-globals dump` rewrites the list but keeps the header comments.
- **Contents**: language servers and tooling for the Emacs config (`typescript` + `typescript-language-server`, `vscode-langservers-extracted`, `eslint`, `prettier` + `prettier-plugin-svelte`, `svelte-language-server`, `@vue/language-server`, `@tailwindcss/language-server`, `bash-language-server`, `intelephense`, `ts-node`, `tsx`), `corepack` (no longer bundled with Node since Node 25), `aws-cdk`, and AI CLIs (`@google/gemini-cli`, `@google/jules`, `@aws/agentcore`, `@earendil-works/pi-coding-agent`). Claude Code is deliberately **not** here; it is the `claude-code@latest` Homebrew cask.
- **`npm/.npmrc`**: stowed to `~/.npmrc`. It only carries the `allow-scripts` list npm 12 requires before a package's install scripts may run (`@google/jules` and a few native-build dependencies break without it). **Never put a registry token in it** — `npm login` writes credentials to `~/.npmrc`, this repository is public, and the pre-commit hook in `lefthook.yml` rejects credential-looking lines as a backstop. Reference a token from the environment instead (`${NPM_TOKEN}`).
- **Caveat**: nvm installs globals _per Node version_. After `nvm install <version>`, re-run `npm-globals install` to repopulate that version.

### 🐟 Fish Shell (`fish/`, submodule)

Full details in the [Fish README](fish/README.md). In short:

- **Prompt**: **Starship** with a transient prompt (only the character stays once a command has run).
- **Plugins**: `fisher` with `bass`, `nvm.fish`, `fzf.fish` (which owns `Ctrl-R` history search), `sponge`, `puffer-fish` (expands `!!`, `$$`, `...`) and `fish-abbreviation-tips`. The list is `fish_plugins`; the installed copies live in the gitignored `plugins/` directory and fisher bootstraps itself on the first interactive shell that lacks it.
- **Init snapshots**: the `starship`, `zoxide`, `direnv` and `pyenv` inits are committed as static `conf.d/` snapshots instead of being re-generated on every shell start. `regen-shell-inits` refreshes them after upgrades (`maintain` does this automatically). An empty `conf.d/direnv.fish` shadows the slower hook Homebrew's direnv ships in `vendor_conf.d/`.
- **Homebrew prefix detection**: `conf.d/00-homebrew.fish` sets `HOMEBREW_PREFIX` for Apple silicon or Intel before anything else loads; every other path is derived from it.
- **direnv outside fish**: the snapshotted hook only fires at a fish prompt. `zsh/.zshenv` evaluates the current directory's `.envrc` once at zsh startup instead, which is what the Claude desktop app's tool shell needs: it runs every command as `/bin/zsh -c …`, so without it a session inside a client tree saw none of that tree's `.envrc` (`GH_CONFIG_DIR`, `AWS_PROFILE`, …).
- **Background maintenance**: the first interactive shell of each day launches `brew_daily_update` in the background (update, upgrade, cleanup, logged to `~/.brew-update.log`); `maintain` is the interactive superset.
- **Theme**: Gruvbox colours for syntax highlighting and `puffer-fish`.

### 💜 Emacs (`emacs/`, submodule)

A modular Emacs 31 configuration using **Elpaca 0.12** and `use-package`; the [Emacs README](emacs/.config/emacs/README.md) is the complete guide, including every keybinding.

- **Startup**: `early-init.el` plus a high garbage-collection threshold during boot; a bespoke welcome screen (recent files and projects) replaces the dashboard.
- **Modules**: `modules/` covers completion, LSP, tree-sitter, debugging (dape), projects (Projectile + Perspective + Treemacs), terminal (ghostel), docs, web and per-language modes.
- **AI agents**: Claude Code integrated two ways (quick drawer and IDE-style with ediff review), plus a vendor-neutral ACP lane currently driving Gemini, with per-project credentials via direnv.
- **Environment**: `exec-path-from-shell` makes Emacs inherit `PATH` and friends from the fish login shell; the untracked `local.el` picks the theme per machine (`gruvbox-dark-hard` by default, Catppuccin Mocha opt-in).

### ⚙️ Git (`git/`)

- **Defaults**: `init.defaultBranch = main`, `pull.rebase`, `push.autoSetupRemote`, `fetch.prune`, `submodule.recurse` (so `git pull` here also moves the submodule checkouts), `merge.conflictstyle = diff3`.
- **Global ignore**: `~/.gitignore_global` for system-wide exclusions.
- **Identity**: `user.useConfigOnly` is set and no name/email is committed — `~/.gitconfig.local` (untracked) **must** define them or commits fail. Its `[include]` is the last section of `~/.gitconfig`, so everything in it overrides the committed defaults.
- **Signing**: commits are SSH-signed with `~/.ssh/id_ed25519.pub`; `~/.ssh/allowed_signers` is only needed to verify signatures locally.
- **Credentials**: HTTPS access to github.com goes through `gh auth git-credential`, so `gh auth login` is all a machine needs for HTTPS pushes.
- **Diffs**: paged through `delta` with the `gruvbox-dark` syntax theme; an `elpaca-lock` diff driver puts the package name in hunk headers of the Emacs lock file.
- **Global hooks**: `core.hooksPath` points at `~/.config/git/hooks`. `commit-msg` strips AI-assistant attribution trailers, and every hook then runs `lefthook run <hook> --no-auto-install` through `lefthook-dispatch` if the repository has a lefthook config, so project lefthook setups work without `lefthook install` (which the global hooks path makes impossible). `LEFTHOOK=0` skips the hand-off, as with lefthook's own hooks.

### 🖥 Ghostty, Starship, fastfetch

- **Ghostty** (`ghostty/`): launches Homebrew's fish as a login shell whichever prefix it lives in, FiraCode Nerd Font 14 with ligatures, *Gruvbox Dark Hard*, translucent blurred background, P3 colour space, `macos-option-as-alt` so `M-x` works in terminal Emacs, copy-on-select to the system clipboard, and a global quick terminal on `⌘` + `` ` `` (needs the Accessibility permission).
- **Starship** (`starship/`): the prompt definition shared by every shell.
- **fastfetch** (`fastfetch/`): shown once per boot, on the first real terminal only (`config.fish` gates it on `isatty stdout` and the kernel boot time).

### 🧵 herdr (`herdr/`)

Config for the herdr agent multiplexer: Gruvbox theme, priority-sorted agent panel, system toasts, and `prefix+a` / `prefix+shift+a` to cycle agents. Only `config.toml` is tracked; everything herdr writes next to it is gitignored, and the package is stowed with `--no-folding` for the same reason.

---

## ⌨️ Commands and Aliases

Everything below is defined in the fish submodule.

| Command | What it does |
| ------- | ------------ |
| `maintain [--force]` | Full system sync: `brew update/upgrade/cleanup` (sharing the lock with the background job), weekly `fisher update` (`--force` runs it now), Brewfile dump, `npm update -g` + manifest dump, shell-snapshot regen. Only stamps the daily marker when Homebrew succeeded. |
| `brewup` | Abbreviation for `maintain` (kept for muscle memory) |
| `brewed` | `brew bundle dump --global --force`: dumps current Brew state to `~/.Brewfile`, i.e. the stowed `homebrew/.Brewfile` |
| `npm-globals install` | Installs every package listed in `~/.npm-globals` into the active Node version (`npm-globals` alone does the same) |
| `npm-globals dump` | Rewrites `~/.npm-globals` from the active Node version's globals, keeping the header comments |
| `regen-shell-inits` | Re-snapshots the `starship`, `zoxide`, `direnv` and `pyenv` inits into `conf.d/` with portable paths |
| `generate-completions <cmd> …` | Runs a CLI's completion generator and saves the output to `completions/<cmd>.fish` (for tools Homebrew does not ship completions for) |
| `init-git` / `repo-clone <url>` | `git init` / `git clone` plus a Conventional Commits `lefthook.yml` when the project has no hook manager of its own |
| `s3mount <bucket> [dir]` / `s3unmount` | Mount an S3 bucket with `rclone-mac` under the current `AWS_PROFILE` (needs `gromgit/fuse/rclone-mac` and `macfuse`) |
| `start-n8n` / `stop-n8n` | Run n8n in a detached Docker container on port 5678 |
| `ensure-macfuse-pkgconfig` | Relinks macFUSE's `.pc` files where the `gromgit/fuse` tap expects them (run automatically before every brew upgrade) |
| `python` | Alias for `python3` |
| `ls` / `ll` / `lt` | `eza --icons` / `eza -l --icons` / `eza -T --icons` |
| `cat` | `bat --paging=never` |

---

## 🔁 Working with the submodules

`emacs/` and `fish/` are ordinary clones of their own repositories; this repository only records which commit of each it expects. The git config stowed here sets `submodule.recurse`, so a `git pull` in `~/dotfiles` also moves both checkouts to the recorded commit — and leaves them on a **detached HEAD**.

To change something inside a submodule:

```fish
cd ~/dotfiles/fish
git checkout main            # leave the detached HEAD before committing
# ...edit, commit (Conventional Commits, lefthook runs cog verify)...
git push origin main
cd ~/dotfiles
git add fish
git commit -m "chore(fish): bump pointer to <what changed>"
git push origin main
```

Two rules keep a fresh `git clone --recurse-submodules` working:

1. **Push the submodule first, then the pointer.** The parent must never reference a commit the submodule's remote does not have yet.
2. **Only point at commits reachable from the submodule's `main`.** Pointing at a pull-request branch and then rebasing or squashing that branch before merging leaves the recorded commit orphaned: it still exists on GitHub, but `git submodule update` cannot fetch it and fails on every new machine. (This happened once — fixed by re-pointing `emacs` at the merge commit.)

Pushing to any of the three repositories needs write access to the `J4VMC` organisation; a read-only machine can still clone and update over HTTPS (see step 1).

---

## 🔒 What is deliberately not tracked

This repository is public. The following stay on each machine and are either gitignored or simply never created here:

- `~/.gitconfig.local` — identity, signing key, per-client `includeIf` routing.
- `bin/bin/*` except `chrome-route` — client-specific scripts. `chrome-route` itself is tracked, but its routing rules (`~/.config/chrome-router/<context>.conf`, `host-patterns = Chrome profile name`) are not, because they name clients. On a new machine restore that directory from the old one (or recreate it) and make sure the Chrome profiles it names exist. macOS blocks terminals from Chrome's `Local State` until they are allowed access to other apps' data; the script reports `cannot read … Operation not permitted` in that case, and until it is allowed a rule can name the profile directory directly (`* = Profile 2`, from `chrome://version` in that profile).
- `herdr/.config/herdr/*` except `config.toml` — runtime state.
- Inside the fish submodule: `fish_variables`, `plugins/`, `private.fish`, and any `*_autosync.fish` / `*_daily_sync.fish` helper.
- Inside the emacs submodule: `local.el`, `custom.el`, `elpaca/` and every cache directory.
- `~/.config/karabiner/` — see step 7.
- `~/.docker/config.json` — holds registry logins (the `cliPluginsExtraDirs` step 6 adds is the only setting this setup needs from it).

---

## 📂 Directory Structure

- `stow/`: `~/.stow-global-ignore`, the only ignore list GNU Stow applies to the whole stow directory. Stow it first.
- `bin/`: scripts linked into `~/bin`. Only the client-free `chrome-route` (profile-routing `$BROWSER` launcher) is tracked; everything else in `bin/bin/` is gitignored on purpose.
- `emacs/`: submodule — Emacs configuration (`init.el`, `early-init.el`, `modules/`, `templates`).
- `emacs-plus/`: build configuration for the emacs-plus formula (`build.yml`, currently just the `liquid-glass` icon).
- `fish/`: submodule — Fish shell configuration, functions, completions and the plugin list.
- `zsh/`: `~/.zshenv` only — zsh is not the login shell; this makes non-interactive zsh (the Claude desktop app's tool shell) load the current directory's `.envrc` via direnv, see the Fish section.
- `git/`: global Git configuration, global ignore file and the global hooks directory (`commit-msg`, `lefthook-dispatch`, and one thin wrapper per hook lefthook can run).
- `homebrew/`: system package manifest (stowed to `~/.Brewfile`). Carries taps, formulae, casks, VS Code extensions and Go tools — never `npm` entries.
- `npm/`: global npm package manifest plus `.npmrc` (the `allow-scripts` list only).
- `ghostty/`, `starship/`, `fastfetch/`: terminal emulator, prompt and system-info configuration.
- `herdr/`: config for the herdr agent multiplexer (`config.toml` only; stow with `--no-folding`, see above).
- `lefthook.yml`: commit hooks for this repository itself (Conventional Commits check via Cocogitto, and a pre-commit guard that rejects credentials staged into `npm/.npmrc`), executed by the global git hooks above. Each submodule carries its own copy with the Conventional Commits check.
- `.editorconfig`: 4-space indentation (2 for web/YAML/JSON, tabs for Go and Makefiles), LF, final newline.
- `LICENSE`: GPL-3.0.
