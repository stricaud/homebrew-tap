class Libpcapng < Formula
  desc "pcapng read/write, reassembly, dissection and posa decoders"
  homepage "https://github.com/stricaud/libpcapng"
  url "https://github.com/stricaud/libpcapng/archive/refs/tags/v0.7.tar.gz"
  sha256 "ba5f721bda797f2260ec88d743108086ed3bb82da051a559a8f5eb6b50523555"
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

