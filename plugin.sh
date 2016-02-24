#!/bin/bash

BRANCH="master"
CONSOLE_SCRIPT="ConsoleScript.php"
CONSOLE_SCRIPT_URL="https://raw.githubusercontent.com/PocketMine/DevTools/master/src/DevTools/ConsoleScript.php"
OUTDIR="$(pwd)"
IGNORE_CERT="yes"
PHP="$(which php)"

function usage {
    echo "Usage: $0 [-b branch] [-p /path/to/php] [-o /out/dir] <url>"
    exit 1
}

#Needed to use aliases
shopt -s expand_aliases
type wget > /dev/null 2>&1
if [ $? -eq 0 ]; then
	if [ "$IGNORE_CERT" == "yes" ]; then
		alias download_file="wget --no-check-certificate -q -O -"
	else
		alias download_file="wget -q -O -"
	fi
else
	type curl >> /dev/null 2>&1
	if [ $? -eq 0 ]; then
		if [ "$IGNORE_CERT" == "yes" ]; then
			alias download_file="curl --insecure --silent --location"
		else
			alias download_file="curl --silent --location"
		fi
	else
		echo "error, curl or wget not found"
	fi
fi

while getopts "b:ho:p:h" opt; do
    case $opt in
        b)
            BRANCH="$2"
            ;;
        h)
            usage
            ;;
        o)
            OUTDIR="$2"
            ;;
        p)
            PHP="$2"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

shift $(expr $OPTIND - 1 )
URL="$1"

if [ "$($PHP -r 'echo 1;' 2>/dev/null)" != "1" ]; then
    echo "[*] PHP not found"
    usage
fi

if [ ! -f $CONSOLE_SCRIPT ]; then
    echo "[*] Downloading ConsoleScript.php"
    download_file "$CONSOLE_SCRIPT_URL" > ConsoleScript.php
fi

if [ ! -d $OUTDIR ]; then
    mkdir -p "$OUTDIR"
fi

if [ "$URL" == "" ]; then
    usage
fi

git clone -b "$BRANCH" "$URL" plugin

cd plugin
PLUGIN_NAME=$(grep 'name: ' plugin.yml | sed 's/^[^:]*: \(.*\)$/\1/g')
PLUGIN_VERSION=$(grep 'version: ' plugin.yml | sed 's/^[^:]*: \(.*\)$/\1/g')
GIT_COMMIT="$(git rev-parse HEAD)"
cd ..

$PHP -dphar.readonly=0 "$CONSOLE_SCRIPT" --make="./plugin/" --relative="./plugin/" --out "$OUTDIR/${PLUGIN_NAME}_v${PLUGIN_VERSION}-${GIT_COMMIT:0:8}.phar"

# cleanup
rm -fr plugin ConsoleScript.php
