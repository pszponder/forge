# Forge

A system configuration CLI tool

## Installation

### Prerequisites

**Required:**
- `git`

**Optional (recommended)**:
- `stow` (required if you plan on setting up dotfiles)

### Install forge

You can either clone and run the installer from a checked-out repository, or use the small remote bootstrapper which clones the repository and delegates to the normal installer.

Recommended (explicit clone + run):

```sh
git clone https://github.com/pszponder/forge.git ~/.local/share/forge
bash ~/.local/share/forge/install.sh
```

Remote bootstrapper (one-line):

```sh
curl -fsSL https://raw.githubusercontent.com/pszponder/forge/main/bootstrap.sh | bash
```

If you prefer to review the script before running it (recommended):

```sh
curl -fsSLo /tmp/forge-bootstrap.sh https://raw.githubusercontent.com/pszponder/forge/main/bootstrap.sh
less /tmp/forge-bootstrap.sh
bash /tmp/forge-bootstrap.sh
```

Note: the bootstrapper will remove and replace any existing installation at
`$FORGE_DATA_DIR` (defaults to `~/.local/share/forge`). If you'd prefer to
preserve an existing installation, set `FORGE_DATA_DIR` to a different path
or manually back up the directory before running the bootstrapper.

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
- [ ] Can we replace Brew with Mise?
- [ ] add a "setup" option for
    - [ ] --flatpak
    - [ ] --mac
    - [ ] --ubuntu
    - [ ] --arch
    - [ ] --fedora
    - [ ] --fedora-atomic
- [ ] add an "new" option
    - [ ] create a new GPG key
- [ ] "forge setup" be reserved for setting up a new system and "forge install" to install smaller parts like fonts, dotfiles, etc.?
- [ ] Should `forge setup --common` include homebrew? Maybe remove --common and instead pass the setup into each specific os setup?
- [ ] Consider installing homebrew for all Linux/Mac workstations by default and use it to install fonts (don't forget to run fc-cache after font installation on Linux)