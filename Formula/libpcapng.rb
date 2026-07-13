class Libpcapng < Formula
  desc "pcapng read/write, reassembly, dissection and posa decoders"
  homepage "https://github.com/stricaud/libpcapng"
  url "https://github.com/stricaud/libpcapng/archive/refs/tags/v0.6.tar.gz"
  sha256 "99dd09f0871806d4a150f5cf9ed207cdfc3e61ccf653e97e5c3a37f06aee9367"
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

