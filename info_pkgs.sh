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

repofiles=$(find /var/lib/pacman/sync/*.db)

for repofile in ${repofiles[@]}; do
  repo=$(basename $repofile)
  repo=${repo%.db}
  repodir=$(mktemp -d)
  tar xf $repofile -C $repodir
  pkgfiles=$(find $repodir -name desc)
  mkdir -p results/$repo
  for pkgfile in ${pkgfiles[@]}; do
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
    done < <(cat "$pkgfile" $(find $(dirname $pkgfile) -type f ! -name "desc" | xargs))
    pkg_obj=$(echo $pkg_obj | jq ". + {\"REPO\":\"$repo\"}")
    echo "Collecting info for $pkgname"
    echo $pkg_obj | jq -r > results/$repo/$pkgname.json
  done
done

find results -type f -name "*.json" | xargs -I @ cat @ | jq -s '. | [.[] | {NAME,VERSION,REPO}]' > results/_pkgs_brief.json
