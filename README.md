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