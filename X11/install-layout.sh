#!/usr/bin/env bash
EXPECTDISTRO="Debian, Mint, Ubuntu, Manjaro or Arch"
EXPECTDISTROID="^(debian|linuxmint|ubuntu|manjaro|arch)"
[[ -t 1 ]] && { cG="\e[1;32m"; cR="\e[1;31m"; cB="\e[1;34m"; cW="\e[1;37m"; cY="\e[1;33m"; cG_="\e[0;32m"; cR_="\e[0;31m"; cB_="\e[0;34m"; cW_="\e[0;37m"; cY_="\e[0;33m"; cZ="\e[0m"; export cR cG cB cY cW cR_ cG_ cB_ cY_ cW_ cZ; }
declare -a TOOLS_NEEDED=(readlink)
for tool in "${TOOLS_NEEDED[@]}"; do type -p $tool > /dev/null 2>&1 || { printf "${cR}FATAL:${cZ} couldn't find '%s' which is required by this script.\n" "$tool"; exit 1; }; done
pushd $(dirname $0) > /dev/null; CURRABSPATH=$(readlink -nf "$(pwd)"); popd > /dev/null; # Get the directory in which the script resides
# Check superuser privileges
if [[ $UID -eq 0 ]]; then
	printf "${cW}INFO:${cZ} since we are running as ${cW}root${cZ}, this script will perform actual changes.\n"
else
	declare -r DRYRUN=1
	printf "${cY}WARNING:${cZ} since we are ${cY}NOT${cZ} running as ${cW}root${cZ}, this script will only pretend (dry mode).\n"
	# Mock destructive or privileged operations
	install() { printf "${cY}WOULD HAVE RUN:${cZ} ${cW}%s${cZ} %s\n" "${FUNCNAME[0]}" "${*}"; }
	rm() { printf "${cY}WOULD HAVE RUN:${cZ} ${cW}%s${cZ} %s\n" "${FUNCNAME[0]}" "${*}"; }
	setxkbmap() { printf "${cY}WOULD HAVE RUN:${cZ} ${cW}%s${cZ} %s\n" "${FUNCNAME[0]}" "${*}"; }
	udevadm() { printf "${cY}WOULD HAVE RUN:${cZ} ${cW}%s${cZ} %s\n" "${FUNCNAME[0]}" "${*}"; }
	ln() { printf "${cY}WOULD HAVE RUN:${cZ} ${cW}%s${cZ} %s\n" "${FUNCNAME[0]}" "${*}"; }
fi
# Check Debian-derivative
if [[ ! -e /etc/debian_version && ! -e /etc/arch-release && ! -e /etc/manjaro-release  && ! -e /etc/os-release ]]; then
	printf "${cR}FATAL:${cZ} This script is meant to be run on %s only.\n" "$EXPECTDISTRO"
	exit 1
fi
# Check distro
NAME=$(source /etc/os-release; echo $NAME) || { printf "${cR}FATAL:${cZ} Failed to retrieve distro name.\n"; exit 1; }
DISTROID=$(source /etc/os-release; echo $ID) || { printf "${cR}FATAL:${cZ} Failed to retrieve distro ID.\n"; exit 1; }
readonly NAME DISTROID
if [[ ! "$DISTROID" =~ $EXPECTDISTROID ]]; then
	printf "${cR}FATAL:${cZ} This script is meant to be run on %s (found %s).\n" "$EXPECTDISTRO" "$NAME"
	exit 1
fi
# Check for available tools
if [[ -e /etc/debian_version ]]; then
	TOOLS_NEEDED+=(dpkg-reconfigure)
fi
TOOLS_NEEDED+=(grep install ln patch rm sed setxkbmap udevadm)
for tool in "${TOOLS_NEEDED[@]}"; do type -p $tool > /dev/null 2>&1 || { printf "${cR}FATAL:${cZ} couldn't find '%s' which is required by this script.\n" "$tool"; exit 1; }; done

# Main script

readonly XKBDIR="${XKBDIR:-/usr/share/X11/xkb}"
# First check if the files both exist
for fname in "$XKBDIR/rules"/evdev.{lst,xml}; do
	if [[ ! -f "$fname" ]]; then
		printf "${cR}FATAL:${cZ} The file ${cW}%s${cZ} does not exist.\n" "$fname"
		exit 1
	fi
done
for fname in "$XKBDIR/rules"/evdev.{lst,xml}; do
	PATCHNAME="$CURRABSPATH/$DISTROID/${fname##*/}.patch"
	# Always create a local backup
	( set -x; cp -f -- "$fname" "$CURRABSPATH/$DISTROID/${fname##*/}" ) || { printf "${cR}ERROR:${cZ} failed to backup '${cW}%s${cZ}' to ${cW}%s${cZ}\n" "$fname" "$CURRABSPATH/$DISTROID/${fname##*/}.\n"; }
	if [[ -v DRYRUN && -n $DRYRUN ]]; then
		# In dry mode the backup file is what we run `patch` on (remember it'll drop .orig files)
		fname="$CURRABSPATH/$DISTROID/${fname##*/}"
	fi
	if [[ ! -e "$PATCHNAME" ]]; then
		printf "${cR}FATAL:${cZ} The patch file ${cW}%s${cZ} does not exist.\n" "$PATCHNAME"
		exit 1
	fi
	( [[ -n $DEBUG ]] && set -x; patch --reject-file=- -bNut -- "$fname" "$PATCHNAME" ) # exit code is bogus for our purposes when patch already applied, so ignore it
done
for fname in "$CURRABSPATH"/{us_ext,ru_us}; do
	if ! ( [[ -n $DEBUG ]] && set -x; install -p -m 0644 -g root -o root -- "$fname" $XKBDIR/symbols/ ); then
		printf "${cR}FATAL:${cZ} Removing '${cW}%s${cZ}' ...\n" "$fname"
		( [[ -n $DEBUG ]] && set -x; rm -f -- "$fname" )
		exit 1
	fi
done
declare -r FLAGDIR="/usr/share/kf5/locale/countries"
if [[ -d "$FLAGDIR" ]]; then
	printf "${cW}INFO:${cZ} Making flag icons available via '${cW}%s${cZ}' ...\n" "$FLAGDIR"
	for layout in us_ext ru_us; do
		if [[ -L "$FLAGDIR/$layout" ]]; then
			LNKTGT=$(readlink -nf -- "$FLAGDIR/$layout") || printf "${cY}WARNING:${cZ} failed to read symbolic link ${cW}%s${cZ}.\n" "$FLAGDIR/$layout"
			printf "${cW}INFO:${cZ} layout '${cW}%s${cZ}' symlinked (-> %s) ...\n" "$layout" "$LNKTGT"
		else
			printf "${cW}INFO:${cZ} going to symlink '${cW}%s${cZ}' to correct country.\n" "$layout"
			case "$layout" in
			us_ext)
				( set -x; cd -- "$FLAGDIR" && ln -s -- us "$layout" ) || { printf "${cR}ERROR:${cZ} failed to symlink '${cW}%s${cZ}'.\n"  "$layout"; }
				;;
			ru_us)
				( set -x; cd -- "$FLAGDIR" && ln -s -- ru "$layout" ) || { printf "${cR}ERROR:${cZ} failed to symlink '${cW}%s${cZ}'.\n"  "$layout"; }
				;;
			*)
				printf "${cY}WARNING:${cZ} unsupported layout named ${cW}%s${cZ}.\n" "$layout"
				;;
			esac
		fi
	done
fi
( [[ -n $DEBUG ]] && set -x; setxkbmap -v 10 -layout us_ext )
( [[ -n $DEBUG ]] && set -x; udevadm trigger --subsystem-match=input --action=change )
fname=/etc/default/keyboard
if [[ -f "$fname" ]] && ! grep -vq ^XKBLAYOUT=us_ext "$fname"; then
	if ! ( [[ -n $DEBUG ]] && set -x; sed -i '/XKBLAYOUT/d; i XKBLAYOUT=us_ext' -- "$fname" ); then
		printf "${cR}ERROR:${cZ} Failed to modify keyboard layout %s ...\n" "$fname"
	elif [[ -e /etc/debian_version ]]; then
		( [[ -n $DEBUG ]] && set -x; dpkg-reconfigure xkb-data )
	fi
fi
# Remove backup files
if [[ -v DRYRUN && -n $DRYRUN ]]; then
	CLEANUPDIR="$CURRABSPATH/$DISTROID"
else
	CLEANUPDIR="$XKBDIR/rules"
fi
( [[ -n $DEBUG ]] && set -x; rm -f -- "$CLEANUPDIR"/evdev.{lst,xml}.orig )
printf "${cW}INFO:${cZ} don't forget to run ${cW}setxkbmap -v 10 -layout us_ext${cZ} from your own user context\n"
