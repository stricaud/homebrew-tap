class Faup < Formula
  desc "URL parser — splits a URL into scheme, domain, TLD, query string and more"
  homepage "https://github.com/stricaud/faup"
  url "https://github.com/stricaud/faup/archive/refs/tags/v1.5.tar.gz"
  sha256 "eafbde5972629e819770879c1a4fb959c3feb29da0ed7ef361377136a171bc61"
  license "WTFPL"
  head "https://github.com/stricaud/faup.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  # Optional upstream, but faup auto-detects it and the Lua output modules in
  # share/faup/modules_available are useless without it.
  depends_on "lua"

  def install
    system "cmake", "-S", ".", "-B", "build",
           # faup still declares cmake_minimum_required(VERSION 2.8), which
           # CMake 4 refuses outright.
           "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
           # The faup tool links libfaupl by build-tree *path* rather than by
           # CMake target, so CMake never rewrites the executable's
           # `@rpath/libfaupl.1.dylib` at install time. Stamping the library
           # with its final absolute id is what lets that reference resolve
           # inside the keg instead of falling through to a stale
           # /usr/local/lib/libfaupl.1.dylib from an older source install.
           "-DCMAKE_INSTALL_NAME_DIR=#{lib}",
           "-DCMAKE_INSTALL_RPATH=#{lib}",
           *std_cmake_args
    # src/tools and src/tests link libfaupl by file path instead of by CMake
    # target, so make has no dependency edge to it: a parallel build starts the
    # faup tool before the library exists and dies with "No rule to make target
    # src/lib/libfaupl.dylib". Building the library first gives the rest of the
    # tree the file it expects.
    system "cmake", "--build", "build", "--target", "faupl"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/faup -v")

    # faup reads URLs from stdin; a URL passed as an argument is treated as a
    # file to read and silently yields nothing.
    csv = pipe_output(bin/"faup", "http://www.example.co.uk/path?q=1\n")
    assert_equal "http,,www,example.co.uk,example,www.example.co.uk,co.uk,,/path,?q=1,,mozilla_tld",
                 csv.strip

    # The bundled Mozilla public-suffix list is what makes co.uk one TLD rather
    # than two labels -- assert it is found, since a missing data dir degrades
    # silently.
    assert_equal "co.uk", pipe_output("#{bin}/faup -f tld", "http://www.example.co.uk/\n").strip
  end
end
