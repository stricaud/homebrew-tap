class Libpcapng < Formula
  desc "pcapng read/write, reassembly, dissection and posa decoders"
  homepage "https://github.com/stricaud/libpcapng"
  url "https://github.com/stricaud/libpcapng/archive/refs/tags/v0.15.tar.gz"
  sha256 "e131455bfc5226877372ee301ae27ba5eece6168840ce151d3064a9e084948a0"
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

