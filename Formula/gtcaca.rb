class Gtcaca < Formula
  desc "TUI widget toolkit built on libcaca"
  homepage "https://github.com/stricaud/gtcaca"
  url "https://github.com/stricaud/gtcaca/archive/refs/tags/v0.1.20.tar.gz"
  sha256 "25c14d51762dd6c05c0696dbcbb3d852d6fa222e73317d078f1c0dd900d21ae2"
  license :public_domain
  head "https://github.com/stricaud/gtcaca.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libcaca"
  depends_on "oniguruma" # syntax colouring in the posa editor

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end
end
