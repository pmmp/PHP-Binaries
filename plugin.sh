#!/bin/bash

BRANCH="master"
DEVTOOLS="DevTools.phar"
CONSOLE_SCRIPT="https://raw.githubusercontent.com/PocketMine/DevTools/master/src/DevTools/ConsoleScript.php"

PHP="$(which php)"

function usage {
    echo "Usage: $0 [-b branch] [-d /path/to/DevTools.phar] [-p /path/to/php] <url>"
    exit 1
}

while getopts "p:b:d:h" opt; do
    case $opt in
        b)
            BRANCH="$2"
            ;;
        d)
            DEVTOOLS="$2"
            ;;
        p)
            PHP="$2"
            ;;
        h)
            usage
    esac
done

shift $(expr $OPTIND - 1 )
URL="$1"

if [ "$($PHP -r 'echo 1;' 2>/dev/null)" != "1" ]; then
    echo "[*] PHP not found"
    usage
fi

if [ ! -f $DEVTOOLS ]; then
    if [ ! -f "ConsoleScript.php" ]; then
        echo "[*] Downloading ConsoleScript.php"
        wget --no-check-certificate -O - "$CONSOLE_SCRIPT" > ConsoleScript.php
    fi
    DEVTOOLS="$(pwd)/ConsoleScript.php"
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

$PHP -dphar.readonly=0 "$DEVTOOLS" --make="./plugin/" --relative="./plugin/" --out "${PLUGIN_NAME}_v${PLUGIN_VERSION}-${GIT_COMMIT:0:8}.phar"
rm -fr plugin
