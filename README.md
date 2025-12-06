# Forge

A system configuration CLI tool

## Installation

### Prerequisites

**Required:**
- `git`

**Optional (recommended)**:
- `stow` (required if you plan on setting up dotfiles)

```sh
git clone https://github.com/pszponder/forge.git
```

## How to develop forge

Make sure to clone the repo to a different location than the location where forge is installed.
This will be your working copy where you can make changes and test them before deploying to your main forge installation.

```sh
git clone git@github.com:pszponder/forge.git ~/Development/repos/github/pszponder/forge
```

Once your changes are pushed and merged to the main branch, you can update your main forge installation by running:

```sh
forge update --self
```

## Resources / References
- [Typecraft's Crucible](https://github.com/typecraft-dev/crucible)
- [dcli - Declarative package management CLI tool for Arch Linux](https://gitlab.com/theblackdon/dcli)
- [Omarchy](https://github.com/basecamp/omarchy)

## Todos
- [ ] Tool should be modular and have options for:
    - [ ] Asking user for what os is being used
    - [ ] Asking user for what type of system (server or workstation)
    - [x] Installing dotfiles
- [ ] Can we replace Brew with Mise?
- [ ] add a "setup" option for
    - [x] --brew
    - [ ] --flatpak
    - [x] --ssh (to setup ssh keys and config)
    - [ ] --mise ???
    - [x] --dirs (default directory structure for a new system)
    - [x] --nerdfonts (only for linux systems)
- [ ] add an "new" option
    - [x] create a new SSH key
    - [ ] create a new GPG key
- [ ] Try using VSCode plan mode when developing the tool
- [x] `forge setup` should ask what to install if no arguments are given
- [ ] `forge uninstall` should ask what to remove if no arguments are given
- [x] `forge install` should be renamed to `forge setup`
- [ ] `forge uninstall` should be renamed to `forge remove`
- [x] Add `forge add` (or `forge new`) to add new items such as ssh keys, gpg keys, etc.