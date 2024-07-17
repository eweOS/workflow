#!/bin/bash

pkgloc=${1:-new-packages}

function check_diff(){
        pkgfile=$1
        pkgname=`pacman -Qp $1 | cut -f 1 -d ' '`
        cat <<EOF >> symdiff.report.md
## Package \`$pkgname\`

EOF
        if pacman -Si $pkgname 2>/dev/null > /dev/null ; then
                oldpkg=$(mktemp)
                oldpkgdir=$(mktemp -d)
                newpkgdir=$(mktemp -d)
                pacman -Sy
                wget $(pacman -Sp $pkgname --noconfirm) -O $oldpkg
                tar -C $newpkgdir -xf $1
                tar -C $oldpkgdir -xf $oldpkg

                mkdir -p .$pkgname.sodiff.new .$pkgname.sodiff.old

                for sofile in $(comm -12 <(find $newpkgdir -name "*.so" | sed "s@^$newpkgdir@@") <(find $oldpkgdir -name "*.so" | sed "s@^$oldpkgdir@@")); do
                        soname=`basename $newpkgdir/$sofile`
                        readelf -s $newpkgdir/$sofile | grep -v -e " UND " -e "^$" | tail -n "+3" | tr -s ' ' | cut -f 5- -d ' ' | sort > .$pkgname.sodiff.new/$soname.symlist
                        readelf -s $oldpkgdir/$sofile | grep -v -e " UND " -e "^S" | tail -n "+3" | tr -s ' ' | cut -f 5- -d ' ' | sort > .$pkgname.sodiff.old/$soname.symlist
                        echo "- $soname" >> symdiff.report.md
                done

                diff -rdN .$pkgname.sodiff.old .$pkgname.sodiff.new > .$pkgname.symchanges
                if [ -s .$pkgname.symchanges ]; then
                        cat <<EOF >> symdiff.report.md


<details>
  <summary>view diff (`tail -n+4 .$pkgname.symchanges | grep -e "^+" -e "^-" | wc -l` changes)</summary>

\`\`\`diff
`cat .$pkgname.symchanges`
\`\`\`

</details>


EOF
                else
                        cat <<EOF >> symdiff.report.md
No changes, no symdiff reported.

EOF
                fi
        else
                cat <<EOF >> symdiff.report.md
New package, no symdiff reported.

EOF
        fi

}

export -f check_diff

cat <<EOF > symdiff.report.md
# Package files diff check report

EOF

pacman -Fy --noconfirm
pacman -Sy --noconfirm

find $pkgloc | grep '.pkg.' | xargs -I @ bash -c "check_diff @"
