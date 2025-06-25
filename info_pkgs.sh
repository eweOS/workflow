#!/bin/bash

LANG=C
DATA_ITEM="{}"
STATE=0

declare -A array_keys=(
  [CHECKDEPENDS]=1
  [CONFLICTS]=1
  [DEPENDS]=1
  [LICENSE]=1
  [MAKEDEPENDS]=1
  [OPTDEPENDS]=1
  [PROVIDES]=1
  [REPLACES]=1
)

mkdir -p results

repofiles=$(find /var/lib/pacman/sync/*.files)

for repofile in ${repofiles[@]}; do
  repo=$(basename $repofile)
  repo=${repo%.files}
  repodir=$(mktemp -d)
  tar xf $repofile -C $repodir
  pkgdirs=$(find $repodir/* -type d)
  mkdir -p results/$repo
  for pkgdir in ${pkgdirs[@]}; do
    pkg_obj="{}"
    while IFS= read -r line; do
      if [[ "$line" == "%"* ]]; then
        key=$(sed 's/%//g' <<< "$line")
	value=""
	read -r valueitem
	if [ "$key" == "NAME" ]; then
          pkgname=$valueitem
	fi
	until [ "$valueitem" == "" ] ; do
	  valueitem=$(echo $valueitem | sed "s/\"/\'/g")
	  if [ "$value" != "" ]; then
            value="$value;$valueitem"
	  else
            value="$valueitem"
	  fi
	  read -r valueitem
	done
        if [ -n "$key" ] && [ -n "$value" ]; then
          if [[ -n "${array_keys[$key]}" ]]; then
            pkg_obj=$(echo $pkg_obj | jq ". + {\"$key\":\"$value\" | split(\";\")}")
	  else
            pkg_obj=$(echo $pkg_obj | jq ". + {\"$key\":\"$value\"}")
          fi
        fi
      fi
    done < <(cat $(find $pkgdir -type f ! -name "files" | xargs))
    pkg_obj=$(echo $pkg_obj | jq ". + {\"REPO\":\"$repo\"}")
    echo "Collecting info for $pkgname"
    echo $pkg_obj | jq -r > results/$repo/$pkgname.json
    if [ -f $pkgdir/files ]; then
      cat $pkgdir/files | grep -v -e "^\." -e "^$" -e "%FILES%" | jq -nR '[inputs]' > results/$repo/$pkgname.files.json
    fi
  done
  find results/$repo/*.json ! -name '*.files.json' -exec cat {} \; | jq '. | select(has("MAKEDEPENDS")) | {(.BASE): .MAKEDEPENDS}' | jq -s add > results/$repo/_MAKEDEPENDS.json
  find results/$repo/*.json ! -name '*.files.json' -exec cat {} \; | jq '. | select(has("CHECKDEPENDS")) | {(.BASE): .CHECKDEPENDS}' | jq -s add > results/$repo/_CHECKDEPENDS.json
  find results/$repo/*.json ! -name '*.files.json' -exec cat {} \; | jq '. | select(has("DEPENDS")) | {(.BASE): .DEPENDS}' | jq -s add > results/$repo/_DEPENDS.json
done

find results -type f -name "*.json" ! -name "*.files.json" | xargs -I @ cat @ | jq -s '. | [.[] | {NAME,VERSION,REPO}]' > results/_pkgs_brief.json
