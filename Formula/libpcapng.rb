class Libpcapng < Formula
  desc "Library to read, write, reassemble and dissect pcapng, with posa decoders"
  homepage "https://github.com/stricaud/libpcapng"
  url "https://github.com/stricaud/libpcapng/archive/refs/tags/v0.18.6.tar.gz"
  sha256 "1fc665d346a4835b2a42be0457a44cb2063a7e451d1720cd5e82a63dbfac7d2e"
  license "MIT"
  head "https://github.com/stricaud/libpcapng.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DLIBPCAPNG_BINDINGS=OFF", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"pcapsh", "--help"
  end
end
