class Caracal < Formula
  desc "Terminal packet analyzer — a tiny Wireshark for the TUI"
  homepage "https://github.com/stricaud/caracal"
  head "https://github.com/stricaud/caracal.git", branch: "main"
  license "MIT"
  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libcaca"
  depends_on "luajit"
  depends_on "gtcaca"
  depends_on "libpcapng"

  def install
    system "cmake", "-S", ".", "-B", "build",
           "-DPCAPNG_INCLUDE_DIR=#{Formula["libpcapng"].opt_include}",
           "-DPCAPNG_LIBRARY=#{Formula["libpcapng"].opt_lib}/libpcapng.dylib",
           "-DGTCACA_INCLUDE_DIR=#{Formula["gtcaca"].opt_include}",
           "-DGTCACA_LIBRARY=#{Formula["gtcaca"].opt_lib}/libgtcaca.dylib",
           "-DCARACAL_DATA_PROTOS=#{share}/caracal/protos",
           "-DCARACAL_DATA_GRAMMARS=#{share}/caracal/grammars",
           *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_path_exists bin/"caracal"
  end
end

