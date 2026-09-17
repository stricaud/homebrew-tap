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

    # Upstream's faup.pc.cmake was added in Dec 2018, after the v1.5 tag (May
    # 2016), so the released tarball installs no pkg-config file at all and
    # `pkg-config --libs faup` finds nothing. Provide the same fields here,
    # against the opt prefix so the file keeps working across version bumps.
    # Drop this block once a tagged release ships faup.pc itself.
    (lib/"pkgconfig").mkpath
    (lib/"pkgconfig/faup.pc").write <<~PKGCONFIG
      prefix=#{opt_prefix}
      exec_prefix=${prefix}
      libdir=#{opt_lib}
      includedir=#{opt_include}

      Name: faup
      Description: Library parsing URLs
      Version: #{version}
      Libs: -L${libdir} -lfaupl
      Cflags: -I${includedir}
    PKGCONFIG
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

    # The library and headers are meant to be consumed by other programs, so
    # check pkg-config resolves them and that the result actually compiles.
    assert_equal version.to_s, shell_output("pkg-config --modversion faup").strip
    (testpath/"consumer.c").write <<~'C'
      #include <string.h>
      #include <stdio.h>
      #include <faup/faup.h>
      #include <faup/options.h>
      #include <faup/decode.h>
      #include <faup/output.h>
      int main(void) {
        faup_options_t *opts = faup_options_new();
        faup_handler_t *fh = faup_init(opts);
        const char *url = "http://www.example.co.uk/";
        faup_decode(fh, url, strlen(url));
        printf("%.*s\n", (int)faup_get_tld_size(fh), url + faup_get_tld_pos(fh));
        faup_terminate(fh);
        faup_options_free(opts);
        return 0;
      }
    C
    flags = shell_output("pkg-config --cflags --libs faup").chomp.split
    system ENV.cc, "consumer.c", *flags, "-o", "consumer"
    assert_equal "co.uk", shell_output("./consumer").strip
  end
end
