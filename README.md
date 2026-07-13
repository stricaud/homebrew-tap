# stricaud/homebrew-tap

A [Homebrew](https://brew.sh) tap for **carcal** — a terminal (TUI) packet
analyzer and its libraries.

| Formula     | Command  | What it is                                                     | License        |
|-------------|----------|----------------------------------------------------------------|----------------|
| `carcal`    | `carcal` | Terminal packet analyzer — a tiny Wireshark for the TUI        | MIT            |
| `gtcaca`    | —        | libcaca-based TUI widget toolkit (used by carcal)              | Public domain  |
| `libpcapng` | —        | pcapng read/write, reassembly, dissection and `.posa` decoders | MIT            |

`carcal` depends on `gtcaca` and `libpcapng`, so installing it pulls in
everything automatically.

## Install

```sh
brew install stricaud/tap/carcal
```

(`brew tap stricaud/tap` first is optional — the fully-qualified name taps
automatically.) That's it — run it with:

```sh
carcal path/to/capture.pcapng
```

### Latest development version

To build the newest code from the `main` branch instead of the released
version:

```sh
brew install --HEAD stricaud/tap/carcal
```

### Just a library

You can install the libraries on their own:

```sh
brew install stricaud/tap/libpcapng
brew install stricaud/tap/gtcaca
```

## Update

```sh
brew update
brew upgrade stricaud/tap/carcal
```

## Uninstall

```sh
brew uninstall stricaud/tap/carcal
brew uninstall stricaud/tap/gtcaca stricaud/tap/libpcapng   # if no longer needed
brew untap stricaud/tap
```

## Requirements

Homebrew installs the runtime dependencies (`libcaca`, `luajit`, `oniguruma`)
automatically. You just need Homebrew itself:

- macOS (Apple Silicon or Intel), or Linux with Homebrew
- Xcode Command Line Tools on macOS: `xcode-select --install`

## Notes

- Bundled protocol decoders (`.posa`) and editor grammars are installed under
  `$(brew --prefix)/share/carcal/`. Override the search path at runtime with
  the `CARCAL_PROTOS_DIR` / `CARCAL_GRAMMARS_DIR` environment variables.
- `libpcapng`'s optional Python bindings are **not** built by this tap
  (`-DLIBPCAPNG_BINDINGS=OFF`), so no Python/pybind11 toolchain is required.

## Troubleshooting

```sh
brew doctor
brew reinstall stricaud/tap/carcal
```

If a `--HEAD` build fails after an upstream change, try
`brew install --HEAD --force stricaud/tap/carcal` to rebuild from a clean checkout.
