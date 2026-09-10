#!/usr/bin/env bash
# Deterministic checks on the App Store listing, every localization included.
#
#   .github/scripts/listing-check.sh <slug>
#
# Apple indexes the metadata of ten localizations on the US storefront (tools/aso/locales.json),
# so the factory writes all ten and this checks all ten: each one present, each field inside
# Apple's limit, keywords that do not waste characters. Limits are counted in characters, not
# bytes — a Chinese or Arabic keyword field is three bytes per character and `wc -c` would
# reject a legal one. Runs anywhere with node; no credentials.
set -uo pipefail

slug=${1:?usage: listing-check.sh <slug>}
meta="apps/$slug/store/metadata"
fails=0
warns=0
fail() { echo "::error::$*"; fails=$((fails + 1)); }
warn() { echo "::warning::$*"; warns=$((warns + 1)); }
pass() { echo "  ok   $*"; }

chars() { node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8").replace(/\r?\n$/,"");console.log([...s].length)' "$1"; }
words() { tr '[:upper:]' '[:lower:]' < "$1" | tr -cs '[:alnum:]' '\n' | sort -u; }

locales=$(node -p 'require("./tools/aso/locales.json").locales.map(l=>l.code).join(" ")')
[ -d "$meta/en-US" ] || { fail "no $meta/en-US; the build agent writes it (new-app skill, step 10)"; exit 1; }

all_keywords=""
for loc in $locales; do
  d="$meta/$loc"
  if [ ! -d "$d" ]; then
    fail "missing localization $loc. Apple indexes it on the US storefront; run app-aso for $slug."
    continue
  fi
  echo "::group::$loc"
  for spec in name.txt:30 subtitle.txt:30 keywords.txt:100 promotional_text.txt:170 description.txt:4000; do
    f=${spec%%:*}; lim=${spec##*:}
    if [ ! -f "$d/$f" ]; then fail "$loc: missing $f"; continue; fi
    n=$(chars "$d/$f")
    if [ "$n" -gt "$lim" ]; then fail "$loc: $f is $n characters, limit $lim"; else pass "$loc/$f $n/$lim"; fi
  done
  for f in privacy_url.txt support_url.txt; do
    [ -s "$d/$f" ] || fail "$loc: $f is missing or empty; App Store Connect wants it per localization"
  done
  if [ -f "$d/keywords.txt" ]; then
    kw=$(cat "$d/keywords.txt")
    case "$kw" in *", "*) fail "$loc: keywords.txt has a space after a comma; that space is a wasted character" ;; esac
    case "$kw" in *,,*|,*|*,) fail "$loc: keywords.txt has an empty entry" ;; esac
    dupes=$(tr ',' '\n' < "$d/keywords.txt" | tr '[:upper:]' '[:lower:]' | sort | uniq -d)
    [ -z "$dupes" ] || fail "$loc: duplicate keyword(s): $(echo "$dupes" | tr '\n' ' ')"
    # A word already in this localization's name or subtitle is indexed from there; repeating
    # it in the keyword field spends the characters twice.
    if [ -f "$d/name.txt" ] && [ -f "$d/subtitle.txt" ]; then
      title_words=$(cat "$d/name.txt" "$d/subtitle.txt" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | sort -u)
      while IFS= read -r k; do
        k=$(echo "$k" | tr '[:upper:]' '[:lower:]' | xargs)
        [ -n "$k" ] || continue
        echo "$title_words" | grep -qx "$k" && warn "$loc: keyword \"$k\" already appears in the name or subtitle"
      done < <(tr ',' '\n' < "$d/keywords.txt")
    fi
    all_keywords="$all_keywords$(tr ',' '\n' < "$d/keywords.txt" | tr '[:upper:]' '[:lower:]' | sed "s/^/$loc\t/")"$'\n'
  fi
  echo "::endgroup::"
done

# Every localization's keyword field is indexed on the same storefront, so the same term in
# two of them buys nothing the second time.
cross=$(printf '%s' "$all_keywords" | awk -F'\t' 'NF==2 && $2!="" {c[$2]++; l[$2]=l[$2]" "$1} END {for (k in c) if (c[k]>1) print k" ("l[k]" )"}')
if [ -n "$cross" ]; then
  while IFS= read -r line; do [ -n "$line" ] && warn "keyword repeated across localizations: $line"; done <<< "$cross"
fi

echo
if [ "$fails" -gt 0 ]; then
  echo "::error::listing: $fails failure(s), $warns warning(s)"
  exit 1
fi
echo "listing: clean ($warns warning(s))"
