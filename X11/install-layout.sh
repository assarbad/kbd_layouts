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
	cp() { printf "${cY}WOULD HAVE RUN:${cZ} ${cW}%s${cZ} %s\n" "${FUNCNAME[0]}" "${*}"; }
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
TOOLS_NEEDED+=(awk diff grep install ln patch python3 rm sed setxkbmap udevadm)
for tool in "${TOOLS_NEEDED[@]}"; do type -p $tool > /dev/null 2>&1 || { printf "${cR}FATAL:${cZ} couldn't find '%s' which is required by this script.\n" "$tool"; exit 1; }; done

function load_xml
{
	python3 - "$@" <<"EOF"
import sys
import xml.etree.ElementTree as ET

target_path = sys.argv[1]
if len(sys.argv) > 1:
	names_to_test = sys.argv[2:]
	names_to_test = set([x for x in names_to_test if x]) if isinstance(names_to_test, list) else set([names_to_test])

# Parse the target document
try:
	tree = ET.parse(target_path)
	root = tree.getroot()
except ET.ParseError:
	sys.exit("FATAL: not an XML file?!")

# Find the layoutList element (adjust XPath if it's nested deeper or namespaced)
layout_list = root.find(".//layoutList")
if layout_list is None:
	sys.exit("FATAL: <layoutList> element not found")

if names_to_test:
	first_name = root.find('.//layoutList/layout/configItem/name')
	if first_name is None or first_name.text not in names_to_test:
		sys.exit(f"FATAL: expected first name to be one of {names_to_test}, got {first_name.text if first_name is not None else None!r}")
EOF
}

function insert_xml
{
	local WORKDIR
	WORKDIR="$(mktemp --tmpdir -d KBDLAYOUTS.XXXXXXX)"
	local -r TGTPATH="$1"
	local -r SNIPPET_FILE="$2"
	local -r WORK_TGTPATH="$WORKDIR/${TGTPATH##*/}"
	local FINAL_DIR="${TGTPATH%/*}"
	if [[ -n $DEBUG ]]; then
		FINAL_DIR="$CURRABSPATH"
	fi
	(
		set -euo pipefail
		if [[ -n $DEBUG ]]; then
			printf -- "${cW}WORK_TGTPATH${cG}=${cZ}%s\n" "$WORK_TGTPATH" >&2
		fi
		if ( [[ -n $DEBUG ]] && set -x; awk -v snippet="$SNIPPET_FILE" '
		{
			print
			if ($0 ~ /<layoutList>/) {
				while ((getline line < snippet) > 0)
					print line
				close(snippet)
			}
		}
		' "$TGTPATH" ) > "$WORK_TGTPATH"; then
			( [[ -n $DEBUG ]] && set -x; mv -- "$WORK_TGTPATH" "$FINAL_DIR"/ )
		else
			printf -- "${cR}ERROR:${cZ} failed to patch and move '%s'.\n" "${TGTPATH##*/}" >&2
		fi
	)
}

function insert_lst
{
	local WORKDIR
	WORKDIR="$(mktemp --tmpdir -d KBDLAYOUTS.XXXXXXX)"
	local -r TGTPATH="$1"
	local -r SNIPPET_FILE="$2"
	local -r WORK_TGTPATH="$WORKDIR/${TGTPATH##*/}"
	local FINAL_DIR="${TGTPATH%/*}"
	if [[ -n $DEBUG ]]; then
		FINAL_DIR="$CURRABSPATH"
	fi
	(
		set -euo pipefail
		if [[ -n $DEBUG ]]; then
			printf -- "${cW}WORK_TGTPATH${cG}=${cZ}%s\n" "$WORK_TGTPATH" >&2
		fi
		if ( [[ -n $DEBUG ]] && set -x; awk -v snippet="$SNIPPET_FILE" '
		{
			print
			if ($1 == "us" && $2 == "English" && $3 == "(US)") {
				while ((getline line < snippet) > 0)
					print line
				close(snippet)
			}
		}
		' "$TGTPATH" ) > "$WORK_TGTPATH"; then
			( [[ -n $DEBUG ]] && set -x; mv -- "$WORK_TGTPATH" "$FINAL_DIR"/ )
		else
			printf -- "${cR}ERROR:${cZ} failed to patch and move '%s'.\n" "${TGTPATH##*/}" >&2
		fi
	)
}

function patch_system_files
{
	local -r TARGET_LST=$(readlink -nf -- "$CURRABSPATH/evdev.lst.system")
	local -r TARGET_XML=$(readlink -nf -- "$CURRABSPATH/evdev.xml.system")
	echo "TARGET_LST=$TARGET_LST"
	echo "TARGET_XML=$TARGET_XML"

	# Check if already patched
	if load_xml "$TARGET_XML" al; then
		if insert_xml "$TARGET_XML" "$CURRABSPATH/snippet.evdev.xml" &&
			insert_lst "$TARGET_LST" "$CURRABSPATH/snippet.evdev.lst"; then
			local -r XML_TO_VALIDATE="$CURRABSPATH/${TARGET_XML##*/}"
			local -r LST_TO_VALIDATE="$CURRABSPATH/${TARGET_LST##*/}"
			if load_xml "$XML_TO_VALIDATE" ru_us; then
				( [[ -n $DEBUG ]] && set -x; diff -u -- "$CURRABSPATH/evdev.xml.system" "$XML_TO_VALIDATE" )
				( [[ -n $DEBUG ]] && set -x; diff -u -- "$CURRABSPATH/evdev.lst.system" "$LST_TO_VALIDATE" )
				return 0
			fi
		fi
	elif load_xml "$TARGET_XML" ru_us; then
		printf "${cR}FATAL:${cZ} '%s' is already patched, assuming the same for the .lst file ...\n" "$TARGET_XML"
		exit 1
	fi
}

function make_flags_available
{
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
}

function main
{
	local XKBDIR=$(readlink -nf -- "$CURRABSPATH/xkb")
	readonly XKBDIR="${XKBDIR:-/usr/share/X11/xkb}"
	# First check if the files both exist
	for fname in "$XKBDIR/rules"/evdev.{lst,xml}; do
		if [[ ! -f "$fname" ]]; then
			printf "${cR}FATAL:${cZ} The file ${cW}%s${cZ} does not exist.\n" "$fname"
			exit 1
		fi
	done
	for fname in "$CURRABSPATH"/{us_ext,ru_us}; do
		if ! ( [[ -n $DEBUG ]] && set -x; install -p -m 0644 -g root -o root -- "$fname" $XKBDIR/symbols/ ); then
			printf "${cR}FATAL:${cZ} Removing '${cW}%s${cZ}' ...\n" "$fname"
			( [[ -n $DEBUG ]] && set -x; rm -f -- "$fname" )
			exit 1
		fi
	done
	for fname in "$XKBDIR/rules"/evdev.{lst,xml}; do
		if ! ( set -x; cp -f -- "$fname"{,.orig} ); then
			printf "${cR}FATAL:${cZ} Failed to backup '${cW}%s${cZ}' to ${cW}%s${cZ}\n" "$fname" "$fname.orig"
			exit 2
		fi
	done
	if ! patch_system_files "$@"; then
		printf "${cR}FATAL:${cZ} Failed to patch evdev.{lst,xml} ...\n"
		exit 3
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
	printf "${cW}INFO:${cZ} don't forget to run ${cW}setxkbmap -v 10 -layout us_ext${cZ} from your own user context\n"
}


main "$@"
