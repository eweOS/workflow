#!/bin/bash

pkgloc=${1:-new-packages}

function check_diff(){
	pkgfile=$1
	pkgname=`pacman -Qp $1 | cut -f 1 -d ' '`
	cat <<EOF >> filediff.report.md
## Package \`$pkgname\`

`pacman -Qpl $1 | grep -v "$pkgname \." | wc -l` files and directories.

EOF
	if pacman -Si $pkgname 2>/dev/null > /dev/null ; then
		pacman -Qpl $1 | grep -v "$pkgname \." | sed "s@$pkgname /@@" | sort > .$pkgname.new.list
		pacman -Fl $pkgname | grep -v -e "$pkgname \." | sed "s@$pkgname @@" | sort > .$pkgname.old.list
		diff -dN .$pkgname.old.list .$pkgname.new.list > .$pkgname.changes
		if [ -s .$pkgname.changes ]; then
			cat <<EOF >> filediff.report.md
<details>
  <summary>view diff (`tail -n+4 .$pkgname.changes | grep -e "^+" -e "^-" | wc -l` changes)</summary>

\`\`\`diff
`cat .$pkgname.changes`
\`\`\`

</details>
EOF
		else
			cat <<EOF >> filediff.report.md
No changes, no diff reported.

EOF
		fi
	else
		cat <<EOF >> filediff.report.md
New package, no diff reported.

EOF
	fi

}

export -f check_diff

cat <<EOF > filediff.report.md
# Package files diff check report

EOF

pacman -Fy --noconfirm
pacman -Sy --noconfirm

find $pkgloc | grep '.pkg.' | xargs -I @ bash -c "check_diff @"
