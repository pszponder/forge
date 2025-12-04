# Forge CLI subcommands

The `forge` CLI is a thin wrapper around a small command registry implemented in
`scripts/utils/arg_utils.sh` and wired up in `forge.sh`.

Current built-in commands (defined in `forge.sh`):

- `forge install` – install Forge (full system, TODO: hook up real logic)
- `forge install --dotfiles` – install only dotfiles (TODO: hook up real logic)
- `forge uninstall` – remove the Forge binary and data directory
- `forge help` – show help and list available commands

## How the registry works

The registry is defined in `scripts/utils/arg_utils.sh`:

- `forge_register_cmd <name> <description> <handler-func-name>` – register a
  new subcommand.
- `forge_run_cmd <name> [args...]` – look up the handler for `<name>` and call
  it with the remaining arguments.
- `forge_print_help` – print `Usage:` and a list of all registered commands.

`forge.sh` sources `_utils.sh`, which in turn sources `arg_utils.sh`, so the
registry functions are always available inside `forge.sh`.

## Adding a new subcommand

Subcommands live in `forge.sh`. To add one, you:

1. Define a handler function.
2. Register it with `forge_register_cmd`.

### 1. Define a handler

Handlers are plain bash functions. They receive everything after the
subcommand name as their arguments.

```bash
forge_cmd_example() {
  # "$@" contains any extra arguments after `forge example`
  echo "Running example with args: $*"
}
```

### 2. Register the subcommand

After the handler is defined (still in `forge.sh`), register it:

```bash
forge_register_cmd "example" "Run the example command" forge_cmd_example
```

This tells the registry:

- The subcommand name is `example` (used on the CLI as `forge example`).
- The description is `Run the example command` (shown in `forge help`).
- The handler function to call is `forge_cmd_example`.

### 3. Call it from the CLI

Now you can run:

```sh
forge example foo bar
```

This will invoke:

```bash
forge_cmd_example foo bar
```

Flags work the same way. For example:

```sh
forge example --flag value
```

becomes:

```bash
forge_cmd_example --flag value
```

You are free to parse `"$@"` inside the handler however you like (simple
`case` on `$1`, `getopts`, etc.).

## Example: a `status` command

A concrete example you can copy into `forge.sh`:

```bash
forge_cmd_status() {
  print_status "$BLUE" "Forge data dir: $FORGE_DATA_DIR"
  print_status "$BLUE" "Forge bin path: $FORGE_BIN_PATH"
}

forge_register_cmd "status" "Show Forge paths and basic status" forge_cmd_status
```

Now `forge status` will print a small status summary using the shared
`print_status` helper.

This registry-based approach keeps the CLI small and declarative: each new
subcommand is just a function + a single registration line.
