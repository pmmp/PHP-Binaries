#!/bin/bash

CHANNEL="alpha"
BRANCH="master"
NAME="PocketMine-MP"
BUILD_URL=""

LINUX_BUILD="PHP_7.0.3_x86-64_Linux"
#CENTOS_BUILD="PHP_5.6.2_x86-64_CentOS"
MAC_BUILD="PHP_7.0.3_x86-64_MacOS"
update=off
forcecompile=off
alldone=no
checkRoot=on
alternateurl=off

INSTALL_DIRECTORY="./"

IGNORE_CERT="no"

while getopts "rucid:v:t:" opt; do
	case $opt in
		a)
			alternateurl=on
			;;
		r)
			checkRoot=off
			;;
		u)
			update=on
			;;
		c)
			forcecompile=on
			;;
		d)
			INSTALL_DIRECTORY="$OPTARG"
			;;
		i)
			IGNORE_CERT="yes"
			;;
		v)
			CHANNEL="$OPTARG"
			;;
		t)
			BUILD_URL="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done


if [ `getconf LONG_BIT` == "32" ]; then
	echo "[ERROR] PocketMine-MP is no longer supported on 32-bit systems."
	exit 1
fi

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
			alias download_file="curl --insecure --silent --show-error --location --globoff"
		else
			alias download_file="curl --silent --show-error --location --globoff"
		fi
	else
		echo "error, curl or wget not found"
		exit 1
	fi
fi

if [ "$checkRoot" == "on" ]; then
	if [ "$(id -u)" == "0" ]; then
		echo "This script is running as root, this is discouraged."
		echo "It is recommended to run it as a normal user as it doesn't need further permissions."
		echo "If you want to run it as root, add the -r flag."
		exit 1
	fi
fi

if [ "$CHANNEL" == "soft" ]; then
	NAME="PocketMine-Soft"
fi

ENABLE_GPG="no"
PUBLICKEY_URL="http://cdn.pocketmine.net/pocketmine.asc"
PUBLICKEY_FINGERPRINT="20D377AFC3F7535B3261AA4DCF48E7E52280B75B"
PUBLICKEY_LONGID="${PUBLICKEY_FINGERPRINT: -16}"
GPG_KEYSERVER="pgp.mit.edu"

function check_signature {
	echo "[*] Checking signature of $1"
	"$GPG_BIN" --keyserver "$GPG_KEYSERVER" --keyserver-options auto-key-retrieve=1 --trusted-key $PUBLICKEY_LONGID --verify "$1.sig" "$1"
	if [ $? -eq 0 ]; then
		echo "[+] Signature valid and checked!"
	else
		"$GPG_BIN" --refresh-keys > /dev/null 2>&1
		echo "[!] Invalid signature! Please check for file corruption or a wrongly imported public key (signed by $PUBLICKEY_FINGERPRINT)"
		exit 1
	fi
}

if [[ "$BUILD_URL" != "" && "$CHANNEL" == "custom" ]]; then
	BASE_VERSION="custom"
	VERSION="custom"
	BUILD="unknown"
	API_VERSION="unknown"
	VERSION_DATE_STRING="unknown"
	ENABLE_GPG="no"
	VERSION_DOWNLOAD="$BUILD_URL"
else
	echo "[*] Retrieving latest build data for channel \"$CHANNEL\""

	VERSION_DATA=$(download_file "https://jenkins.pmmp.io/job/PocketMine-MP/$(tr '[:lower:]' '[:upper:]' <<< ${CHANNEL:0:1})${CHANNEL:1}/api/json?pretty=true&tree=url,artifacts[fileName],number,timestamp")

	if [ "$VERSION_DATA" != "" ]; then
		FILENAME="unknown"

		IFS=$'\n' FILENAMES=($(echo "$VERSION_DATA" | grep '"fileName"' | cut -d ':' -f2- | tr -d ' ",'))
		for (( i=0; i<${#FILENAMES[@]}; i++ ))
		do
			if [[ ${FILENAMES[$i]} == PocketMine*.phar ]]; then
				FILENAME=${FILENAMES[$i]}
				break
			fi
		done
		if [ "$FILENAME" == "unknown" ]; then
			echo "[!] Couldn't determine filename of artifact to download"
			exit 1
		fi

		VERSION=$(echo $FILENAME | cut -d '_' -f2- | cut -d '-' -f1)
		BUILD=$(echo "$VERSION_DATA" | grep '"number"' | cut -d ':' -f2- | tr -d ' ",')
		API_VERSION=$(echo $FILENAME | cut -d '-' -f4- | sed -e 's/\.[^.]*$//')
		VERSION_DATE=$(($(echo "$VERSION_DATA" | grep -m 1 '"timestamp"' | cut -d ':' -f2- | tr -d ' ",') / 1000))
		BASE_URL=$(echo "$VERSION_DATA" | grep '"url"' | cut -d ':' -f2- | tr -d ' ",')
		VERSION_DOWNLOAD="${BASE_URL}artifact/${FILENAME}"

		if [ "$alternateurl" == "on" ]; then
			VERSION_DOWNLOAD=$(echo "$VERSION_DATA" | grep '"alternate_download_url"' | cut -d ':' -f2- | tr -d ' ",')
		fi

		if [ "$(uname -s)" == "Darwin" ]; then
			BASE_VERSION=$(echo "$VERSION" | sed -E 's/([A-Za-z0-9_\.]*).*/\1/')
			VERSION_DATE_STRING=$(date -r $VERSION_DATE)
		else
			BASE_VERSION=$(echo "$VERSION" | sed -r 's/([A-Za-z0-9_\.]*).*/\1/')
			VERSION_DATE_STRING=$(date --date="@$VERSION_DATE")
		fi

		GPG_SIGNATURE=$(echo "$VERSION_DATA" | grep '"signature_url"' | cut -d ':' -f2- | tr -d ' ",')

		if [ "$GPG_SIGNATURE" != "" ]; then
			ENABLE_GPG="yes"
		fi

		if [ "$VERSION" == "" ]; then
			echo "[!] Couldn't get the latest $NAME version"
			exit 1
		fi

		GPG_BIN=""

		if [ "$ENABLE_GPG" == "yes" ]; then
			type gpg > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				GPG_BIN="gpg"
			else
				type gpg2 > /dev/null 2>&1
				if [ $? -eq 0 ]; then
					GPG_BIN="gpg2"
				fi
			fi
			if [ "$GPG_BIN" != "" ]; then
				gpg --fingerprint $PUBLICKEY_FINGERPRINT > /dev/null 2>&1
				if [ $? -ne 0 ]; then
					download_file $PUBLICKEY_URL | gpg --trusted-key $PUBLICKEY_LONGID --import
					gpg --fingerprint $PUBLICKEY_FINGERPRINT > /dev/null 2>&1
					if [ $? -ne 0 ]; then
						gpg --trusted-key $PUBLICKEY_LONGID --keyserver "$GPG_KEYSERVER" --recv-key $PUBLICKEY_FINGERPRINT
					fi
				fi
			else
				ENABLE_GPG="no"
			fi
		fi
	else
		echo "[!] Couldn't download version automatically from Jenkins server"
		exit 1
	fi
fi

echo "[*] Found $NAME $BASE_VERSION (build $BUILD) using API $API_VERSION"
echo "[*] This $CHANNEL build was released on $VERSION_DATE_STRING"

if [ "$ENABLE_GPG" == "yes" ]; then
	echo "[+] The build was signed, will check signature"
elif [ "$GPG_SIGNATURE" == "" ]; then
	if [[ "$CHANNEL" == "beta" ]] || [[ "$CHANNEL" == "stable" ]]; then
		echo "[-] This channel should have a signature, none found"
	fi
fi

echo "[*] Installing/updating $NAME on directory $INSTALL_DIRECTORY"
mkdir -m 0777 "$INSTALL_DIRECTORY" 2> /dev/null
cd "$INSTALL_DIRECTORY"
echo "[1/3] Cleaning..."
rm -f "$NAME.phar"
rm -f README.md
rm -f CONTRIBUTING.md
rm -f LICENSE
rm -f start.sh
rm -f start.bat

#Old installations
rm -f PocketMine-MP.php
rm -r -f src/

echo -n "[2/3] Downloading $NAME $VERSION phar..."
set +e
download_file "$VERSION_DOWNLOAD" > "$NAME.phar"
if ! [ -s "$NAME.phar" ] || [ "$(head -n 1 $NAME.phar)" == '<!DOCTYPE html>' ]; then
	rm "$NAME.phar" 2> /dev/null
	echo " failed!"
	echo "[!] Couldn't download $NAME automatically from $VERSION_DOWNLOAD"
	exit 1
else
	if [ "$CHANNEL" == "soft" ]; then
		download_file "https://raw.githubusercontent.com/PocketMine/PocketMine-Soft/${BRANCH}/resources/start.sh" > start.sh
	else
		download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BRANCH}/start.sh" > start.sh
	fi
	download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BRANCH}/LICENSE" > LICENSE
	download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BRANCH}/README.md" > README.md
	download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BRANCH}/CONTRIBUTING.md" > CONTRIBUTING.md
	download_file "https://raw.githubusercontent.com/pmmp/php-build-scripts/${BRANCH}/compile.sh" > compile.sh
fi

chmod +x compile.sh
chmod +x start.sh

echo " done!"

if [ "$ENABLE_GPG" == "yes" ]; then
	download_file "$GPG_SIGNATURE" > "$NAME.phar.sig"
	check_signature "$NAME.phar"
fi

if [ "$update" == "on" ]; then
	echo "[3/3] Skipping PHP recompilation due to user request"
else
	echo -n "[3/3] Obtaining PHP: detecting if build is available..."
	while [ "$forcecompile" == "off" ]
	do
		rm -r -f bin/ >> /dev/null 2>&1

		#TODO: this needs to check what PHP version is required by the downloaded PM version instead of using hardcoded crap

		if [ "$(uname -s)" == "Darwin" ]; then
			echo -n " MacOS PHP build available, downloading $MAC_BUILD.tar.gz..."

			download_file "https://dl.bintray.com/pocketmine/PocketMine/$MAC_BUILD.tar.gz" | tar -zx > /dev/null 2>&1
		elif [ "$(uname -s)" == "Linux" ]; then
			#if [[ "$(cat /etc/redhat-release 2>/dev/null)" == *CentOS* ]]; then
			#echo -n " CentOS PHP build available, downloading $CENTOS_BUILD.tar.gz..."
			#download_file "https://dl.bintray.com/pocketmine/PocketMine/$CENTOS_BUILD.tar.gz" | tar -zx > /dev/null 2>&1
			#else

			#TODO: check architecture (we might not be on an x86_64 system)

			echo -n " Linux PHP build available, downloading $LINUX_BUILD.tar.gz..."
			download_file "https://dl.bintray.com/pocketmine/PocketMine/$LINUX_BUILD.tar.gz" | tar -zx > /dev/null 2>&1

			#fi
		else
			echo " no prebuilt PHP download available"
			break
		fi

		chmod +x ./bin/php7/bin/*
		if [ -f ./bin/composer ]; then
			chmod +x ./bin/composer
		fi

		echo -n " checking..."

		if [ "$(./bin/php7/bin/php -r 'echo 1;' 2>/dev/null)" == "1" ]; then
			echo -n " updating php.ini..."

			sed -i'.bak' "s/date.timezone=.*/date.timezone=$(date +%Z)/" bin/php7/bin/php.ini

			EXTENSION_DIR=$(find "$(pwd)/bin" -name *debug-zts*) #make sure this only captures from `bin` in case the user renamed their old binary folder

			if [ $(grep -c "extension_dir" bin/php7/bin/php.ini) -gt 0 ]; then
				echo -n " updating extension directory..."
				sed -i'.bak' "s{extension_dir=.*{extension_dir=\"$EXTENSION_DIR\"{" bin/php7/bin/php.ini
			else
				echo -n " setting extension directory..."
				echo "extension_dir=\"$EXTENSION_DIR\"" >> bin/php7/bin/php.ini
			fi

			echo " done"
			alldone=yes
		else
			echo " downloaded PHP build doesn't work on this platform!"
		fi

		break
	done
	if [ "$alldone" == "no" ]; then
		set -e
		echo "[3/3] No prebuilt PHP found, compiling PHP automatically. This might take a while."
		echo
		exec "./compile.sh"
	fi
fi

rm compile.sh

echo "[*] Everything done! Run ./start.sh to start $NAME"
exit 0
