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

# Print "tag asset..." for the latest releases of the repository $1 holding an
# asset matching the regex $2, newest first, at most $3 of them. Drafts and
# pre-releases are left out.
releases() {
  gh api "repos/$1/releases?per_page=30" |
    jq -r --arg re "$2" --argjson n "$3" '
      [.[] | select((.draft or .prerelease) | not)
           | select(any(.assets[].name; test($re)))][:$n][]
      | "\(.tag_name) \([.assets[].name] | join(" "))"'
}

# Quote $1 as a JSON string, which YAML reads too.
quote() { jq -Rn --arg v "$1" '$v'; }

html_escape() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
