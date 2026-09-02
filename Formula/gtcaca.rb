class Gtcaca < Formula
  desc "TUI widget toolkit built on libcaca"
  homepage "https://github.com/stricaud/gtcaca"
  url "https://github.com/stricaud/gtcaca/archive/refs/tags/v0.2.3.tar.gz"
  sha256 "7df697e703699ba90d4063389a267d50062fafec0e0c5e552116de331baa8b54"
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
