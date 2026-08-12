class Gtcaca < Formula
  desc "TUI widget toolkit built on libcaca"
  homepage "https://github.com/stricaud/gtcaca"
  url "https://github.com/stricaud/gtcaca/archive/refs/tags/v0.1.28.tar.gz"
  sha256 "45a8bb8bfb71a05983f1a936b4bb008bad1c5a601b2dfc7ad8035c8557ee556b"
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
