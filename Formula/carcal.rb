class Carcal < Formula
  desc "Terminal packet analyzer — a tiny Wireshark for the TUI (aka carcal)"
  homepage "https://github.com/stricaud/carcal"
  head "https://github.com/stricaud/carcal.git", branch: "main"
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
           "-DCARCAL_DATA_PROTOS=#{share}/carcal/protos",
           "-DCARCAL_DATA_GRAMMARS=#{share}/carcal/grammars",
           *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_path_exists bin/"carcal"
  end
end

