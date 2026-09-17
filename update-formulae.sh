#!/usr/bin/env bash
#
# Update this tap's formulae to the latest upstream tag.
#
# For each formula it finds the newest release tag on GitHub (via `git
# ls-remote`, so no API token and no rate limit), re-downloads whatever that
# formula pins, and rewrites the url / version / revision / sha256 fields in
# place.
#
#   ./update-formulae.sh                 # update everything that is behind
#   ./update-formulae.sh --check         # just report, change nothing
#   ./update-formulae.sh carcal          # only this formula
#   ./update-formulae.sh carscal --version 0.1.2
#   ./update-formulae.sh --commit --push # commit each bump and push
#
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# name|github repo|kind|version file
#   tarball  -- archive/refs/tags/<tag>.tar.gz + one sha256
#   git      -- git url pinned by tag: + revision: (submodules)
#   binaries -- per-platform release assets, one sha256 each
#
# The 4th field is optional: a file in the repo root that upstream treats as
# the source of truth for its version (faup builds both `faup -v` and faup.pc
# from it). Where it is set, this script cross-checks it against the tags --
# see check_version_file. Leave it empty for projects that do not keep one, or
# that keep a stale one (libpcapng's says 0.1 while its tags are at 0.18.x).
FORMULAE=(
  "libpcapng|stricaud/libpcapng|tarball|"
  "gtcaca|stricaud/gtcaca|tarball|"
  "faup|stricaud/faup|tarball|VERSION"
  "carcal|stricaud/carcal|git|"
  "carscal|stricaud/carscal|binaries|"
)

# Platforms carscal ships prebuilt binaries for; asset is <name>-<triple>.tar.xz
TRIPLES=(
  aarch64-apple-darwin
  x86_64-apple-darwin
  aarch64-unknown-linux-gnu
  x86_64-unknown-linux-gnu
)

CHECK_ONLY=0
DO_COMMIT=0
DO_PUSH=0
DO_AUDIT=0
PIN_VERSION=""
SELECTED=()

bold=$'\033[1m'; red=$'\033[31m'; green=$'\033[32m'; yellow=$'\033[33m'; dim=$'\033[2m'; reset=$'\033[0m'
[ -t 1 ] || { bold=""; red=""; green=""; yellow=""; dim=""; reset=""; }

info()  { printf '%s\n' "$*"; }
warn()  { printf '%s%s%s\n' "$yellow" "$*" "$reset" >&2; }
die()   { printf '%s%s%s\n' "$red" "$*" "$reset" >&2; exit 1; }

usage() {
  sed -n '3,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --check           Report what is out of date and exit (no edits)
  --version VER     Force this version (requires exactly one formula)
  --commit          git commit each updated formula
  --push            git push after committing (implies --commit)
  --audit           run `brew audit --strict --online` on updated formulae
  -h, --help        This text
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check)   CHECK_ONLY=1 ;;
    --commit)  DO_COMMIT=1 ;;
    --push)    DO_COMMIT=1; DO_PUSH=1 ;;
    --audit)   DO_AUDIT=1 ;;
    --version) shift; PIN_VERSION="${1:-}"; [ -n "$PIN_VERSION" ] || die "--version needs a value" ;;
    -h|--help) usage; exit 0 ;;
    -*)        die "unknown option: $1" ;;
    *)         SELECTED+=("$1") ;;
  esac
  shift
done

[ -z "$PIN_VERSION" ] || [ ${#SELECTED[@]} -eq 1 ] \
  || die "--version requires exactly one formula name"

command -v perl >/dev/null || die "perl is required"
if command -v shasum >/dev/null; then
  sha256() { shasum -a 256 "$1" | awk '{print $1}'; }
elif command -v sha256sum >/dev/null; then
  sha256() { sha256sum "$1" | awk '{print $1}'; }
else
  die "need shasum or sha256sum"
fi

TMPDIR_RUN="$(mktemp -d "${TMPDIR:-/tmp}/tap-update.XXXXXX")"
trap 'rm -rf "$TMPDIR_RUN"' EXIT

selected_p() {
  [ ${#SELECTED[@]} -eq 0 ] && return 0
  local want
  for want in "${SELECTED[@]}"; do [ "$want" = "$1" ] && return 0; done
  return 1
}

# Newest vX.Y.Z tag on the remote, without the leading v. Pre-releases
# (v1.2.3-rc1 and friends) are skipped on purpose.
latest_version() {
  local repo="$1"
  git ls-remote --tags --refs "https://github.com/$repo.git" 2>/dev/null \
    | awk '{print $2}' \
    | sed 's#^refs/tags/##; s/^v//' \
    | grep -E '^[0-9]+(\.[0-9]+)*$' \
    | sort -V \
    | tail -1
}

# Commit the tag points at (dereferenced, so annotated tags give the commit).
tag_revision() {
  local repo="$1" tag="$2"
  git ls-remote "https://github.com/$repo.git" "refs/tags/$tag^{}" "refs/tags/$tag" \
    | awk 'NR==1{c=$1} $2 ~ /\^\{\}$/ {c=$1} END{print c}'
}

# Read a file from a repo at a given ref, without cloning.
raw_file() {
  local repo="$1" ref="$2" path="$3"
  curl -fsSL "https://raw.githubusercontent.com/$repo/$ref/$path" 2>/dev/null | tr -d '\r\n[:blank:]'
}

# Cross-check upstream's own version file against its tags. Two things go
# wrong in practice, and both are silent:
#   * the file is bumped but never tagged -- there is a release's worth of work
#     that no packaging can reach, because brew keys off tags
#   * a tag ships a version file that disagrees with the tag name -- then the
#     built binary reports a version the tap does not know about
check_version_file() {
  local repo="$1" vfile="$2" latest_tag="$3" head_ver tag_ver

  head_ver="$(raw_file "$repo" HEAD "$vfile")"
  if [ -n "$head_ver" ] && [ "$head_ver" != "$latest_tag" ]; then
    local newest
    newest="$(printf '%s\n%s\n' "$head_ver" "$latest_tag" | sort -V | tail -1)"
    if [ "$newest" = "$head_ver" ]; then
      warn "  note: $vfile on HEAD says $head_ver but the newest tag is v$latest_tag"
      warn "        -- tag it upstream, or the tap cannot ship $head_ver"
    fi
  fi

  tag_ver="$(raw_file "$repo" "v$latest_tag" "$vfile")"
  if [ -n "$tag_ver" ] && [ "$tag_ver" != "$latest_tag" ]; then
    warn "  note: tag v$latest_tag ships $vfile=$tag_ver -- the binary will"
    warn "        report $tag_ver while the formula calls itself $latest_tag"
  fi
}

current_version() {
  local file="$1" kind="$2"
  case "$kind" in
    tarball)  perl -ne 'print "$1\n" and exit if m{archive/refs/tags/v?([^"]+)\.tar\.gz}' "$file" ;;
    git)      perl -ne 'print "$1\n" and exit if m{tag:\s+"v?([^"]+)"}' "$file" ;;
    binaries) perl -ne 'print "$1\n" and exit if m{^\s*version\s+"([^"]+)"}' "$file" ;;
  esac
}

# fetch URL -> local file, echoing the path. Returns non-zero on a failed
# download so a 404 page never silently becomes the sha256 we publish.
fetch() {
  local url="$1" out="$TMPDIR_RUN/$(printf '%s' "$url" | tr -c 'A-Za-z0-9._-' '_')"
  [ -s "$out" ] && { printf '%s\n' "$out"; return 0; }
  if ! curl -fsSL --retry 3 --retry-delay 2 -o "$out" "$url"; then
    rm -f "$out"
    warn "  download failed: $url"
    return 1
  fi
  printf '%s\n' "$out"
}

# Is the release asset actually there? A tag often exists for a while before
# its binaries are uploaded -- that is a skip, not an error.
asset_exists() {
  curl -fsSL -o /dev/null --range 0-0 "$1" 2>/dev/null
}

# Every update_* below edits a scratch copy of the formula; the caller only
# moves it into place once the whole formula updated cleanly, so an upstream
# release that is missing half its assets can never leave a file half-bumped.

update_tarball() {
  local file="$1" repo="$2" ver="$3" url sum path
  url="https://github.com/$repo/archive/refs/tags/v$ver.tar.gz"
  info "  fetching $url"
  path="$(fetch "$url")" || return 1
  sum="$(sha256 "$path")"
  URL="$url" SUM="$sum" perl -0pi -e '
    s{(url\s+")[^"]+(")}{$1$ENV{URL}$2};
    s{(sha256\s+")[0-9a-f]{64}(")}{$1$ENV{SUM}$2};
  ' "$file" || return 1
  info "  sha256 $sum"
}

update_git() {
  local file="$1" repo="$2" ver="$3" rev
  rev="$(tag_revision "$repo" "v$ver")"
  [ -n "$rev" ] || { warn "  no revision for tag v$ver in $repo"; return 1; }
  TAG="v$ver" REV="$rev" perl -0pi -e '
    s{(tag:\s+")[^"]+(")}{$1$ENV{TAG}$2};
    s{(revision:\s+")[0-9a-f]{40}(")}{$1$ENV{REV}$2};
  ' "$file" || return 1
  info "  tag v$ver at $rev"
}

update_binaries() {
  local file="$1" repo="$2" ver="$3" name triple url sum path
  name="$(basename "$repo")"
  local base="https://github.com/$repo/releases/download/v$ver"

  # A tag can exist for days before its binaries are uploaded. Check first so
  # this formula is skipped with a clear message instead of failing the run.
  for triple in "${TRIPLES[@]}"; do
    if ! asset_exists "$base/$name-$triple.tar.xz"; then
      warn "  release v$ver has no $name-$triple.tar.xz yet -- skipping $name"
      return 1
    fi
  done

  VER="$ver" perl -0pi -e 's{(^\s*version\s+")[^"]+(")}{$1$ENV{VER}$2}m' "$file" || return 1

  for triple in "${TRIPLES[@]}"; do
    url="$base/$name-$triple.tar.xz"
    info "  fetching $name-$triple.tar.xz"
    path="$(fetch "$url")" || return 1
    sum="$(sha256 "$path")"
    # Rewrite the url line and the sha256 line that follows it, for this
    # triple only -- the file holds one such pair per platform.
    URL="$url" SUM="$sum" TRIPLE="$triple" NAME="$name" perl -0pi -e '
      my $asset = quotemeta("$ENV{NAME}-$ENV{TRIPLE}.tar.xz");
      s{url\s+"[^"]*$asset"(\s*\n\s*sha256\s+")[0-9a-f]{64}"}
       {url "$ENV{URL}"$1$ENV{SUM}"}s
        or die "no url/sha256 pair for $ENV{TRIPLE}\n";
    ' "$file" || return 1
    info "  $triple $sum"
  done
}

updated=()
behind=0
failed=0

for entry in "${FORMULAE[@]}"; do
  IFS='|' read -r name repo kind vfile <<<"$entry"
  selected_p "$name" || continue

  file="Formula/$name.rb"
  [ -f "$file" ] || die "missing $file"

  cur="$(current_version "$file" "$kind")"
  if [ -n "$PIN_VERSION" ]; then
    new="${PIN_VERSION#v}"
  else
    new="$(latest_version "$repo")"
    [ -n "$new" ] || die "could not list tags for $repo"
  fi

  if [ "$cur" = "$new" ] && [ -z "$PIN_VERSION" ]; then
    info "${dim}$name${reset} ${green}up to date${reset} ($cur)"
    [ -n "$vfile" ] && check_version_file "$repo" "$vfile" "$new"
    continue
  fi

  behind=$((behind + 1))
  info "${bold}$name${reset} $cur ${yellow}->${reset} ${bold}$new${reset}"
  [ -n "$vfile" ] && check_version_file "$repo" "$vfile" "$new"
  [ "$CHECK_ONLY" -eq 1 ] && continue

  # Update a scratch copy and move it over the formula only if the whole thing
  # succeeded -- a half-published release never leaves a half-edited file.
  scratch="$TMPDIR_RUN/$name.rb"
  cp "$file" "$scratch"

  case "$kind" in
    tarball)  updater=update_tarball ;;
    git)      updater=update_git ;;
    binaries) updater=update_binaries ;;
  esac

  # Called from an `if` so a `return 1` inside reports failure instead of
  # tripping `set -e` and killing the whole run.
  ok=0
  if "$updater" "$scratch" "$repo" "$new"; then ok=1; fi

  if [ "$ok" -ne 1 ]; then
    warn "  $name left untouched"
    failed=$((failed + 1))
    continue
  fi

  if cmp -s "$scratch" "$file"; then
    warn "  $file unchanged -- check the formula's format"
    failed=$((failed + 1))
    continue
  fi

  cat "$scratch" > "$file"
  updated+=("$name|$file|$new")

  if [ "$DO_AUDIT" -eq 1 ] && command -v brew >/dev/null; then
    info "  brew audit $name"
    brew audit --strict --online "$file" || warn "  audit reported issues for $name"
  fi
done

if [ "$CHECK_ONLY" -eq 1 ]; then
  [ "$behind" -eq 0 ] && info "${green}everything is up to date${reset}"
  exit 0
fi

if [ ${#updated[@]} -eq 0 ]; then
  if [ "$failed" -gt 0 ]; then
    warn "$failed formula(e) could not be updated -- see the warnings above."
    exit 1
  fi
  info "${green}nothing to do${reset}"
  exit 0
fi

changed_files=()
for u in "${updated[@]}"; do
  IFS='|' read -r _ f _ <<<"$u"
  changed_files+=("$f")
done

info ""
git --no-pager diff --stat -- "${changed_files[@]}"

if [ "$DO_COMMIT" -eq 1 ]; then
  for u in "${updated[@]}"; do
    IFS='|' read -r name file new <<<"$u"
    git add "$file"
    git commit -q -m "$name: update to $new"
    info "${green}committed${reset} $name $new"
  done
  if [ "$DO_PUSH" -eq 1 ]; then
    git push
    info "${green}pushed${reset}"
  fi
else
  info ""
  info "Review with ${bold}git diff${reset}, then commit -- or re-run with --commit."
fi

if [ "$failed" -gt 0 ]; then
  warn ""
  warn "$failed formula(e) could not be updated -- see the warnings above."
  exit 1
fi
