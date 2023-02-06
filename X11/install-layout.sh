#!/usr/bin/env bash
EXPECTDISTRO="Ubuntu or Linux Mint"
EXPECTDISTROID="^(linuxmint|ubuntu)"
[[ -t 1 ]] && { cG="\e[1;32m"; cR="\e[1;31m"; cB="\e[1;34m"; cW="\e[1;37m"; cY="\e[1;33m"; cG_="\e[0;32m"; cR_="\e[0;31m"; cB_="\e[0;34m"; cW_="\e[0;37m"; cY_="\e[0;33m"; cZ="\e[0m"; export cR cG cB cY cW cR_ cG_ cB_ cY_ cW_ cZ; }
for tool in readlink; do type $tool > /dev/null 2>&1 || { echo -e "${cR}FATAL:${cZ} couldn't find '$tool' which is required by this script."; exit 1; }; done
pushd $(dirname $0) > /dev/null; CURRABSPATH=$(readlink -nf "$(pwd)"); popd > /dev/null; # Get the directory in which the script resides
# Check superuser privileges
[[ $UID -eq 0 ]] || { echo -e "${cR}FATAL:${cZ} This script must be run as ${cW}root${cZ}."; exit 1; }
# Check Debian-derivative
if [[ ! -e /etc/debian_version ]] && [[ ! -e /etc/os-release ]]; then
	echo -e "${cR}FATAL:${cZ} This script is meant to be run on $EXPECTDISTRO only (/etc/debian_version not found)."
	exit 1
fi
# Check distro
NAME=$(source /etc/os-release; echo $NAME)
DISTROID=$(source /etc/os-release; echo $ID)
if [[ ! "$DISTROID" =~ $EXPECTDISTROID ]]; then
	echo -e "${cR}FATAL:${cZ} This script is meant to be run on $EXPECTDISTRO (found $NAME)."
	exit 1
fi
# Check for available tools
for tool in dpkg-reconfigure install mv patch rm sed setxkbmap udevadm; do type $tool > /dev/null 2>&1 || { echo -e "${cR}FATAL:${cZ} couldn't find '$tool' which is required by this script."; exit 1; }; done

# Main script

XKBDIR=${XKBDIR:-/usr/share/X11/xkb}
# First check if the files both exist
for fname in $XKBDIR/rules/evdev.{lst,xml}; do
	if [[ ! -f "$fname" ]]; then
		echo -e "The file ${cW}$fname${cZ} does not exist."
		exit 1
	fi
done
for fname in $XKBDIR/rules/evdev.{lst,xml}; do
	PATCHNAME="$CURRABSPATH/${fname##*/}.patch"
	( set -x; patch --reject-file=- -bNut "$fname" "$PATCHNAME" ) # exit code is bogus for our purposes when patch already applied, so ignore it
done
fname="$CURRABSPATH/us_ext"
if ! ( set -x; install -p -m 0644 -g root -o root "$fname" $XKBDIR/symbols/ ); then
	echo "${cR}FATAL:${cZ} Removing $fname ..."
	rm -f "$fname"
	exit 1
fi
fname="$CURRABSPATH/ru_us"
if ! ( set -x; install -p -m 0644 -g root -o root "$fname" $XKBDIR/symbols/ ); then
	echo "${cR}FATAL:${cZ} Removing $fname ..."
	rm -f "$fname"
	exit 1
fi
( set -x; setxkbmap -layout us_ext )
( set -x; udevadm trigger --subsystem-match=input --action=change )
fname=/etc/default/keyboard
if [[ -f "$fname" ]] && ! grep -vq ^XKBLAYOUT=us_ext "$fname"; then
	if ! ( set -x; sed -i '/XKBLAYOUT/d; i XKBLAYOUT=us_ext' "$fname" ); then
		echo "${cR}ERROR:${cZ} Failed to modify keyboard layout $fname ..."
	else
		( set -x; dpkg-reconfigure xkb-data )
	fi
fi
# Remove backup files
( set -x; rm -f "$XKBDIR/rules"/evdev.{lst,xml}.orig )
echo -e "${cW}INFO:${cZ} don't forget to run ${cW}setxkbmap -layout us_ext${cZ} from your own user context"
