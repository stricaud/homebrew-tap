class Gtcaca < Formula
  desc "TUI widget toolkit built on libcaca"
  homepage "https://github.com/stricaud/gtcaca"
  url "https://github.com/stricaud/gtcaca/archive/refs/tags/v0.2.5.tar.gz"
  sha256 "ee5e79f4ccf21eae79ba8213ed92de1d80f3c72d4308f1ab24297bdc07268848"
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
