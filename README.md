# stricaud/homebrew-tap

A [Homebrew](https://brew.sh) tap for **caracal** — a terminal (TUI) packet
analyzer — and its libraries.

| Formula     | What it is                                                        | License        |
|-------------|-------------------------------------------------------------------|----------------|
| `caracal`   | Terminal packet analyzer — a tiny Wireshark for the TUI           | MIT            |
| `gtcaca`    | libcaca-based TUI widget toolkit (used by caracal)                | Public domain  |
| `libpcapng` | pcapng read/write, reassembly, dissection and `.posa` decoders    | MIT            |

`caracal` depends on `gtcaca` and `libpcapng`, so installing it pulls in
everything automatically.

## Install

```sh
brew tap stricaud/tap
brew install caracal
```

That's it — run it with:

```sh
caracal path/to/capture.pcapng
```

### Latest development version

To build the newest code from the `main` branch instead of the released
version:

```sh
brew install --HEAD caracal
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
brew upgrade caracal
```

## Uninstall

```sh
brew uninstall caracal
brew uninstall gtcaca libpcapng   # if you no longer need the libraries
brew untap stricaud/tap
```

## Requirements

Homebrew installs the runtime dependencies (`libcaca`, `luajit`, `oniguruma`)
automatically. You just need Homebrew itself:

- macOS (Apple Silicon or Intel), or Linux with Homebrew
- Xcode Command Line Tools on macOS: `xcode-select --install`

## Notes

- Bundled protocol decoders (`.posa`) and editor grammars are installed under
  `$(brew --prefix)/share/caracal/`. Override the search path at runtime with
  the `CARACAL_PROTOS_DIR` / `CARACAL_GRAMMARS_DIR` environment variables.
- `libpcapng`'s optional Python bindings are **not** built by this tap
  (`-DLIBPCAPNG_BINDINGS=OFF`), so no Python/pybind11 toolchain is required.

## Troubleshooting

```sh
brew doctor
brew reinstall caracal
```

If a `--HEAD` build fails after an upstream change, try
`brew install --HEAD --force caracal` to rebuild from a clean checkout.
