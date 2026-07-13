class Gtcaca < Formula
  desc "libcaca-based TUI widget toolkit"
  homepage "https://github.com/stricaud/gtcaca"
  url "https://github.com/stricaud/gtcaca/archive/refs/tags/v0.0.5.tar.gz"
  sha256 "1c96fdb3b6faffcc6871861149d3ab0c6325c75cbe29f1509d1bd8e184665f50"
  license :public_domain
  head "https://github.com/stricaud/gtcaca.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libcaca"
  depends_on "oniguruma"   # syntax colouring in the posa editor

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end
end

