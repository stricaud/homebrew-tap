class Gtcaca < Formula
  desc "libcaca-based TUI widget toolkit"
  homepage "https://github.com/stricaud/gtcaca"
  head "https://github.com/stricaud/gtcaca.git", branch: "main"
  license :public_domain
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

