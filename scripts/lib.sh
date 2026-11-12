# shellcheck shell=bash
# Helpers shared by the hub scripts, which source this file.

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
catalogue=$(yq -p toml -o json "$root/catalogue.toml")

log() { printf '%s\n' "$*" >&2; }

die() {
  log "error: $*"
  exit 1
}

# Print the CLIs shipping to the channel $1, one per line.
clis_for() {
  jq -r --arg c "$1" \
    '.cli | to_entries[] | select(.value.channels | index($c)) | .key' \
    <<<"$catalogue"
}

# Print the field $2 of the CLI $1, an array joined by spaces.
cli_field() {
  jq -r --arg n "$1" --arg f "$2" \
    '.cli[$n][$f] | if type == "array" then join(" ") else . end' \
    <<<"$catalogue"
}

# The jq function keeping the stable releases of a releases list, highest
# version first: published, not pre-releases, tagged X.Y.Z or vX.Y.Z with X of
# 1 or more, so 0.x versions and suffixes like 1.0.0-beta are left out.
stable='def stable:
  [.[] | select((.draft or .prerelease) | not)
       | select(.tag_name | test("^v?[1-9][0-9]*[.][0-9]+[.][0-9]+$"))]
  | sort_by(.tag_name | ltrimstr("v") | split(".") | map(tonumber))
  | reverse;'

# The licence every shipped release declares, and its files at the tag.
license=$(jq -r .license <<<"$catalogue")
# shellcheck disable=SC2034 # used by linux-build
license_files=$(jq -r '."license-files" | join(" ")' <<<"$catalogue")

# Succeed when the Cargo.toml of the repository $1 at the tag $2 declares the
# catalogue's licence, else log the one it declares and fail. A fetch error
# dies: skipping the release would unpublish it.
licensed() {
  local got
  got=$(curl -fsSL --retry 3 \
    "https://raw.githubusercontent.com/$1/$2/Cargo.toml" |
    yq -p toml -o json '.package.license' |
    jq -r '. // "no licence"') ||
    die "$1 $2: cannot read the licence of Cargo.toml"
  if [[ $got == "$license" ]]; then return 0; fi
  log "$1 $2: $got, not $license"
  return 1
}

# Print "tag asset..." for the stable releases of the repository $1 holding an
# asset matching the regex $2 and declaring the catalogue's licence, highest
# version first, at most $3 of them.
releases() {
  local n=$3 all tag assets
  all=$(gh api "repos/$1/releases?per_page=30" |
    jq -r --arg re "$2" "$stable"'
      stable | map(select(any(.assets[].name; test($re))))[]
      | "\(.tag_name) \([.assets[].name] | join(" "))"') ||
    die "$1: cannot list the releases"
  if [[ -z $all ]]; then return 0; fi
  while ((n > 0)) && read -r tag assets; do
    if licensed "$1" "$tag"; then
      echo "$tag $assets"
      n=$((n - 1))
    fi
  done <<<"$all"
}

# Quote $1 as a JSON string, which YAML reads too.
quote() { jq -Rn --arg v "$1" '$v'; }

html_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
