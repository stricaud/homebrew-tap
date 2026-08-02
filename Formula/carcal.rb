class Carcal < Formula
  desc "Terminal packet analyzer — a tiny Wireshark for the TUI (aka carcal)"
  homepage "https://github.com/stricaud/carcal"
  # Cloned, not fetched as a release tarball: protos/ is the network.protos.posa
  # submodule, and GitHub's archive/refs/tags/*.tar.gz ships that path as an
  # *empty* directory — carcal would build fine and then decode nothing beyond
  # its built-in C dissectors. Homebrew's git strategy runs
  # `submodule update --init --recursive` whenever the checkout has a
  # .gitmodules, so this gets exactly the protos revision the tag pins.
  url "https://github.com/stricaud/carcal.git",
      tag:      "v0.2.1",
      revision: "5e31efed1e10d8f596a1743a48ed4528ac15e4d1"
  license "MIT"
  head "https://github.com/stricaud/carcal.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "gtcaca"
  depends_on "libcaca"
  depends_on "libpcapng"
  depends_on "luajit"

  def install
    system "cmake", "-S", ".", "-B", "build",
           "-DPCAPNG_INCLUDE_DIR=#{formula_opt_include("libpcapng")}",
           "-DPCAPNG_LIBRARY=#{formula_opt_lib("libpcapng")}/#{shared_library("libpcapng")}",
           "-DGTCACA_INCLUDE_DIR=#{formula_opt_include("gtcaca")}",
           "-DGTCACA_LIBRARY=#{formula_opt_lib("gtcaca")}/#{shared_library("libgtcaca")}",
           "-DCARCAL_DATA_PROTOS=#{share}/carcal/protos",
           "-DCARCAL_DATA_GRAMMARS=#{share}/carcal/grammars",
           # `carcal --version` is stamped at configure time from `git describe`,
           # which brew's staged checkout cannot be relied on to answer — hand it
           # the tag so a bottle never reports itself as 0.0.0.
           "-DCARCAL_VERSION=#{version}",
           *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/carcal --version")

    # A carcal with no .posa decoders installs and runs perfectly well — it just
    # silently stops understanding most protocols. Assert the count so a lost
    # submodule fails here instead of shipping.
    out = shell_output("#{bin}/carcal --list-protocols")
    assert_match "#{share}/carcal/protos", out
    loaded = out[/# \.posa decoders — .* \((\d+)\)/, 1].to_i
    assert_operator loaded, :>, 0
  end
end
