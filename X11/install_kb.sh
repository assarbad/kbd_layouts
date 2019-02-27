#!/usr/bin/env bash
[[ -t 1 ]] && { cG="\e[1;32m"; cR="\e[1;31m"; cB="\e[1;34m"; cW="\e[1;37m"; cY="\e[1;33m"; cG_="\e[0;32m"; cR_="\e[0;31m"; cB_="\e[0;34m"; cW_="\e[0;37m"; cY_="\e[0;33m"; cZ="\e[0m"; export cR cG cB cY cW cR_   cG_ cB_ cY_ cW_ cZ; }
[[ $UID -eq 0 ]] || { echo -e "${cR}ERROR:${cZ} This script must be run as ${cW}root${cZ}."; exit 1; }
for tool in readlink awk cp; do type $tool > /dev/null 2>&1 || { echo -e "${cR}ERROR:${cZ} couldn't find '$tool' which is required by this script."; exit 1; }; done
pushd $(dirname $0) > /dev/null; CURRABSPATH=$(readlink -nf "$(pwd)"); popd > /dev/null; # Get the directory in which the script resides
LAYOUTNAME=us_ext
KBDTITLE="English v8 (US + DE, IS, PL, Nordic)"
XKBDIR=/usr/share/X11/xkb
XMLFILE="$XKBDIR/rules/evdev.xml"
LSTFILE="$XKBDIR/rules/evdev.lst"
KBDFILE="$XKBDIR/symbols/$LAYOUTNAME"
read -d '' awkXmlAdjust << 'EOF'
EOF
read -d '' awkLstAdjust << EOF
BEGIN { LAYOUT=0; }
/^! layout/ { print; LAYOUT=1; }
LAYOUT == 0 {
	if (\$1 != "us_ext") {
		print;
	}
}
LAYOUT == 1 {
	if (\$1 == "us") {
		print;
		print "  $LAYOUTNAME          $KBDTITLE"
		LAYOUT=0;
	}
}
EOF
###############################################################################
if [[ ! -d "$XKBDIR" ]]; then
	echo -e "${cR}ERROR:${cZ} no such directory $XKBDIR"
	exit 1
fi
if [[ ! -d "$XKBDIR/rules" ]]; then
	echo -e "${cR}ERROR:${cZ} no such directory $XKBDIR/rules"
	exit 1
fi
if [[ ! -d "$XKBDIR/symbols" ]]; then
	echo -e "${cR}ERROR:${cZ} no such directory $XKBDIR/symbols"
	exit 1
fi
if [[ ! "$CURRABSPATH/$LAYOUTNAME" -ef "$KBDFILE" ]]; then
	echo -en "${cW}Copying layout file ... ${cZ}"
	cp -f "$CURRABSPATH/$LAYOUTNAME" "$KBDFILE" || { echo -e "${cR}failed\nERROR:${cZ} failed to copy $KBDFILE into place."; exit 1; }
	echo -e "${cG}OK${cZ}"
fi
if [[ -f "$LSTFILE" ]]; then
	echo -ne "${cW}Adding $LAYOUTNAME to $LSTFILE ... ${cZ}"
	if command awk "$awkLstAdjust" "$LSTFILE" > "$LSTFILE.new"; then
		echo -e "${cG}OK${cZ}"
		command diff -u "$LSTFILE" "$LSTFILE.new"
		command mv "$LSTFILE.new" "$LSTFILE" || { echo -e "${cR}ERROR:${cZ} failed to move $LSTFILE into place."; exit 1; }
	else
		echo -e "${cR}failed\nERROR:${cZ} failed to adjust $LSTFILE."
		exit 1
	fi
fi
