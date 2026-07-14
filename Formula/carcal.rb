class Carcal < Formula
  desc "Terminal packet analyzer — a tiny Wireshark for the TUI (aka carcal)"
  homepage "https://github.com/stricaud/carcal"
  url "https://github.com/stricaud/carcal/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "1868892be725715a5abbaefac6719518c2d0e9b449916c68d02f236931149aa4"
  license "MIT"
  head "https://github.com/stricaud/carcal.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "gtcaca"
  depends_on "libcaca"
  depends_on "libpcapng"
  depends_on "luajit"

  def install
    system "cmake", "-S", ".", "-B", "build",
           "-DPCAPNG_INCLUDE_DIR=#{formula_opt_include("libpcapng")}",
           "-DPCAPNG_LIBRARY=#{formula_opt_lib("libpcapng")}/libpcapng.dylib",
           "-DGTCACA_INCLUDE_DIR=#{formula_opt_include("gtcaca")}",
           "-DGTCACA_LIBRARY=#{formula_opt_lib("gtcaca")}/libgtcaca.dylib",
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
