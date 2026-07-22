class Carscal < Formula
  desc "A terminal packet analyzer — a tiny Wireshark for the TUI, in Rust. Rust replica of carcal."
  homepage "https://github.com/stricaud/carscal"
  version "0.1.1"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/stricaud/carscal/releases/download/v0.1.1/carscal-aarch64-apple-darwin.tar.xz"
      sha256 "309d6662c717daee0bd0611ee71a5846e2474dbb0de12618741d7b42582f9b61"
    end
    if Hardware::CPU.intel?
      url "https://github.com/stricaud/carscal/releases/download/v0.1.1/carscal-x86_64-apple-darwin.tar.xz"
      sha256 "45a2a51e40929e4299cb0da931348d097d90ec91145e3f03c2da6b5cab5da6f2"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/stricaud/carscal/releases/download/v0.1.1/carscal-aarch64-unknown-linux-gnu.tar.xz"
      sha256 "9f1be5a4b4f0997ae1eeb819323970b92280c26d3ea4b951a5726aeb0e85a08a"
    end
    if Hardware::CPU.intel?
      url "https://github.com/stricaud/carscal/releases/download/v0.1.1/carscal-x86_64-unknown-linux-gnu.tar.xz"
      sha256 "192fa4b4f2111abc7e72f4dc72e64930642f467a736826a7e7f2583ca7571bb8"
    end
  end
  license "MIT"

  BINARY_ALIASES = {
    "aarch64-apple-darwin":      {},
    "aarch64-unknown-linux-gnu": {},
    "x86_64-apple-darwin":       {},
    "x86_64-unknown-linux-gnu":  {},
  }.freeze

  def target_triple
    cpu = Hardware::CPU.arm? ? "aarch64" : "x86_64"
    os = OS.mac? ? "apple-darwin" : "unknown-linux-gnu"

    "#{cpu}-#{os}"
  end

  def install_binary_aliases!
    BINARY_ALIASES[target_triple.to_sym].each do |source, dests|
      dests.each do |dest|
        bin.install_symlink bin/source.to_s => dest
      end
    end
  end

  def install
    bin.install "carscal" if OS.mac? && Hardware::CPU.arm?
    bin.install "carscal" if OS.mac? && Hardware::CPU.intel?
    bin.install "carscal" if OS.linux? && Hardware::CPU.arm?
    bin.install "carscal" if OS.linux? && Hardware::CPU.intel?

    install_binary_aliases!

    # Homebrew will automatically install these, so we don't need to do that
    doc_files = Dir["README.*", "readme.*", "LICENSE", "LICENSE.*", "CHANGELOG.*"]
    leftover_contents = Dir["*"] - doc_files

    # Install any leftover files in pkgshare; these are probably config or
    # sample files.
    pkgshare.install(*leftover_contents) unless leftover_contents.empty?
  end
end
