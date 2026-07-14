class Libpcapng < Formula
  desc "pcapng read/write, reassembly, dissection and posa decoders"
  homepage "https://github.com/stricaud/libpcapng"
  url "https://github.com/stricaud/libpcapng/archive/refs/tags/v0.14.tar.gz"
  sha256 "794e6e913f098e779fc5a71d303aafd8f4c1bd2768416c7f74c78b0b422f2cc7"
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

