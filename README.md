# stricaud/homebrew-tap

A [Homebrew](https://brew.sh) tap for **carcal** — a terminal (TUI) packet
analyzer and its libraries — and **faup**, a URL parser.

| Formula     | Command  | What it is                                                     | License        |
|-------------|----------|----------------------------------------------------------------|----------------|
| `carcal`    | `carcal` | Terminal packet analyzer — a tiny Wireshark for the TUI        | MIT            |
| `gtcaca`    | —        | TUI widget toolkit built on libcaca (used by carcal)          | Public domain  |
| `libpcapng` | —        | Read/write, reassemble and dissect pcapng, with `.posa` decoders | MIT          |
| `faup`      | `faup`   | URL parser — splits a URL into scheme, domain, TLD, query string | WTFPL        |

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

### faup

`faup` is independent of `carcal` — install it on its own:

```sh
brew install stricaud/tap/faup
```

It reads URLs on **stdin** (a URL given as an argument is treated as a file to
read, and silently produces nothing):

```sh
echo "http://www.example.co.uk/path?q=1" | faup
echo "http://www.example.co.uk/path?q=1" | faup -o json
echo "http://www.example.co.uk/path?q=1" | faup -f tld      # co.uk
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
- `faup` is built with Lua so its output modules in
  `$(brew --prefix)/share/faup/modules_available/` work. Its Mozilla public
  suffix list lives in `$(brew --prefix)/share/faup/mozilla.tlds`; `faup -u`
  refreshes it from the network.
- If you previously installed faup from source into `/usr/local`, the old
  `/usr/local/lib/libfaupl.1.dylib` can shadow the Homebrew one when
  `DYLD_LIBRARY_PATH` includes `/usr/local/lib` — the symptom is
  `dyld: Symbol not found` on startup. Remove the old install or drop
  `/usr/local/lib` from `DYLD_LIBRARY_PATH`.
- `libpcapng`'s optional Python bindings are **not** built by this tap
  (`-DLIBPCAPNG_BINDINGS=OFF`), so no Python/pybind11 toolchain is required.
- `carcal --version` reports the tag it was built from, and
  `carcal --list-protocols` lists every dissector it loaded together with the
  `protos/` directory they came from — the quickest way to check an install.

## Troubleshooting

```sh
brew doctor
brew reinstall stricaud/tap/carcal
```

If a `--HEAD` build fails after an upstream change, try
`brew install --HEAD --force stricaud/tap/carcal` to rebuild from a clean checkout.
