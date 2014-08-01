CHANNEL="stable"
LINUX_32_BUILD="PHP_5.5.15_x86_Linux"
LINUX_64_BUILD="PHP_5.5.15_x86-64_Linux"
CENTOS_32_BUILD="PHP_5.5.15_x86_CentOS"
CENTOS_64_BUILD="PHP_5.5.15_x86-64_CentOS"
MAC_32_BUILD="PHP_5.5.15_x86_MacOS"
MAC_64_BUILD="PHP_5.5.15_x86-64_MacOS"
RPI_BUILD="PHP_5.5.15_ARM_Raspbian_hard"
# Temporal build
ODROID_BUILD="PHP_5.5.15_ARM_Raspbian_hard"
AND_BUILD="PHP_5.5.15_ARMv7_Android"
IOS_BUILD="PHP_5.5.13_ARMv6_iOS"
update=off
forcecompile=off
alldone=no

INSTALL_DIRECTORY="./"

#Needed to use aliases
shopt -s expand_aliases
type wget > /dev/null 2>&1
if [ $? -eq 0 ]; then
	alias download_file="wget --no-check-certificate -q -O -"
else
	type curl >> /dev/null 2>&1
	if [ $? -eq 0 ]; then
		alias download_file="curl --insecure --silent --location"
	else
		echo "error, curl or wget not found"
	fi
fi


while getopts "ucd:v:" opt; do
  case $opt in
    u)
	  update=on
      ;;
    c)
	  forcecompile=on
      ;;
	d)
	  INSTALL_DIRECTORY="$OPTARG"
      ;;
	v)
	  CHANNEL="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
	  exit 1
      ;;
  esac
done

VERSION_DATA=$(download_file "http://www.pocketmine.net/api/?channel=$CHANNEL")

VERSION=$(echo "$VERSION_DATA" | grep '"version"' | cut -d ':' -f2- | tr -d ' ",')
BUILD=$(echo "$VERSION_DATA" | grep build | cut -d ':' -f2- | tr -d ' ",')
API_VERSION=$(echo "$VERSION_DATA" | grep api_version | cut -d ':' -f2- | tr -d ' ",')
VERSION_DATE=$(echo "$VERSION_DATA" | grep '"date"' | cut -d ':' -f2- | tr -d ' ",')
VERSION_DOWNLOAD=$(echo "$VERSION_DATA" | grep '"download_url"' | cut -d ':' -f2- | tr -d ' ",')
if [ "$(uname -s)" == "Darwin" ]; then
	BASE_VERSION=$(echo "$VERSION" | sed -E 's/([A-Za-z0-9_\.]*).*/\1/')
	VERSION_DATE_STRING=$(date -j -f "%s" $VERSION_DATE)
else
	BASE_VERSION=$(echo "$VERSION" | sed -r 's/([A-Za-z0-9_\.]*).*/\1/')
	VERSION_DATE_STRING=$(date --date="@$VERSION_DATE")
fi

if [ "$VERSION" == "" ]; then
	echo "[ERROR] Couldn't get the latest PocketMine-MP version"
	exit 1
fi

echo "[INFO] Found PocketMine-MP $BASE_VERSION (build $BUILD) using API $API_VERSION"
echo "[INFO] This $CHANNEL build was released on $VERSION_DATE_STRING"

echo "[INFO] Installing/updating PocketMine-MP on directory $INSTALL_DIRECTORY"
mkdir -m 0777 "$INSTALL_DIRECTORY" 2> /dev/null
cd "$INSTALL_DIRECTORY"
echo "[1/3] Cleaning..."
rm -r -f src/
rm -f PocketMine-MP.phar
rm -f PocketMine-MP.php
rm -f README.md
rm -f CONTRIBUTING.md
rm -f LICENSE
rm -f start.sh
rm -f start.bat
echo -n "[2/3] Downloading PocketMine-MP $VERSION phar..."
set +e
download_file "$VERSION_DOWNLOAD" > PocketMine-MP.phar
if ! [ -s "PocketMine-MP.phar" ] || [ "$(head -n 1 PocketMine-MP.phar)" == '<!DOCTYPE html>' ]; then
	rm "PocketMine-MP.phar" 2> /dev/null
	echo " failed!"
	echo "[ERROR] Couldn't download PocketMine-MP automatically from $VERSION_DOWNLOAD"
	exit 1
else
	download_file "https://raw.githubusercontent.com/PocketMine/PocketMine-MP/master/start.sh" > start.sh
	download_file "https://raw.githubusercontent.com/PocketMine/PocketMine-MP/master/LICENSE" > LICENSE
	download_file "https://raw.githubusercontent.com/PocketMine/PocketMine-MP/master/README.md" > README.md
	download_file "https://raw.githubusercontent.com/PocketMine/PocketMine-MP/master/CONTRIBUTING.md" > CONTRIBUTING.md
	download_file "https://raw.githubusercontent.com/PocketMine/php-build-scripts/master/compile.sh" > compile.sh
fi

chmod +x compile.sh
chmod +x start.sh

echo " done!"

if [ "$update" == "on" ]; then
	echo "[3/3] Skipping PHP recompilation due to user request"
else
	echo -n "[3/3] Obtaining PHP:"
	if [ "$(uname -s)" == "Darwin" ]; then
		SECONDS_10=$(date -v+10S +%s)
	else
		SECONDS_10=$(date --date="10 seconds" -u +%s)
	fi
	EXTRA_URL="?r=&ts=$SECONDS_10"
	echo " detecting if build is available..."
	if [ "$forcecompile" == "off" ] && [ "$(uname -s)" == "Darwin" ]; then
		set +e
		UNAME_M=$(uname -m)
		IS_IOS=$(expr match $UNAME_M 'iP[a-zA-Z0-9,]*' 2> /dev/null)
		set -e
		if [[ "$IS_IOS" -gt 0 ]]; then
			rm -r -f bin/ >> /dev/null 2>&1
			echo -n "[3/3] iOS PHP build available, downloading $IOS_BUILD.tar.gz..."
			download_file "https://downloads.sourceforge.net/project/pocketmine/builds/$IOS_BUILD.tar.gz$EXTRA_URL" | tar -zx > /dev/null 2>&1
			chmod +x ./bin/php5/bin/*
			echo -n " checking..."
			if [ $(./bin/php5/bin/php -r 'echo "yes";' 2>/dev/null) == "yes" ]; then
				echo -n " regenerating php.ini..."
				TIMEZONE=$(date +%Z)
				echo "" > "./bin/php5/bin/php.ini"
				#UOPZ_PATH="$(find $(pwd) -name uopz.so)"
				#echo "zend_extension=\"$UOPZ_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "date.timezone=$TIMEZONE" >> "./bin/php5/bin/php.ini"
				echo "short_open_tag=0" >> "./bin/php5/bin/php.ini"
				echo "asp_tags=0" >> "./bin/php5/bin/php.ini"
				echo "phar.readonly=0" >> "./bin/php5/bin/php.ini"
				echo "phar.require_hash=1" >> "./bin/php5/bin/php.ini"
				echo " done"
				alldone=yes
			else
				echo " invalid build detected"
			fi
		else
			rm -r -f bin/ >> /dev/null 2>&1
			if [ `getconf LONG_BIT` == "64" ]; then
				echo -n "[3/3] MacOS 64-bit PHP build available, downloading $MAC_64_BUILD.tar.gz..."
				MAC_BUILD="$MAC_64_BUILD"
			else
				echo -n "[3/3] MacOS 32-bit PHP build available, downloading $MAC_32_BUILD.tar.gz..."
				MAC_BUILD="$MAC_32_BUILD"
			fi
			download_file "https://downloads.sourceforge.net/project/pocketmine/builds/$MAC_BUILD.tar.gz$EXTRA_URL" | tar -zx > /dev/null 2>&1
			chmod +x ./bin/php5/bin/*
			echo -n " checking..."
			if [ $(./bin/php5/bin/php -r 'echo "yes";' 2>/dev/null) == "yes" ]; then
				echo -n " regenerating php.ini..."
				TIMEZONE=$(date +%Z)
				OPCACHE_PATH="$(find $(pwd) -name opcache.so)"
				XDEBUG_PATH="$(find $(pwd) -name xdebug.so)"
				echo "" > "./bin/php5/bin/php.ini"
				#UOPZ_PATH="$(find $(pwd) -name uopz.so)"
				#echo "zend_extension=\"$UOPZ_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$OPCACHE_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$XDEBUG_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable_cli=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.save_comments=0" >> "./bin/php5/bin/php.ini"
				echo "opcache.fast_shutdown=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.max_accelerated_files=4096" >> "./bin/php5/bin/php.ini"
				echo "opcache.interned_strings_buffer=8" >> "./bin/php5/bin/php.ini"
				echo "opcache.memory_consumption=128" >> "./bin/php5/bin/php.ini"
				echo "opcache.optimization_level=0xffffffff" >> "./bin/php5/bin/php.ini"
				echo "date.timezone=$TIMEZONE" >> "./bin/php5/bin/php.ini"
				echo "short_open_tag=0" >> "./bin/php5/bin/php.ini"
				echo "asp_tags=0" >> "./bin/php5/bin/php.ini"
				echo "phar.readonly=0" >> "./bin/php5/bin/php.ini"
				echo "phar.require_hash=1" >> "./bin/php5/bin/php.ini"
				echo " done"
				alldone=yes
			else
				echo " invalid build detected"
			fi
		fi
	else
		grep -q BCM2708 /proc/cpuinfi > /dev/null 2&1
		IS_RPI=$?
		grep -q sun7i /proc/cpuinfo > /dev/null 2>&1
		IS_BPI=$?
		grep -q ODROID /proc/cpuinfo > /dev/null 2>&1
		IS_ODROID=$?
		if ([ "$IS_RPI" -eq 0 ] || [ "$IS_BPI" -eq 0 ]) && [ "$forcecompile" == "off" ]; then
			rm -r -f bin/ >> /dev/null 2>&1
			echo -n "[3/3] Raspberry Pi PHP build available, downloading $RPI_BUILD.tar.gz..."
			download_file "https://downloads.sourceforge.net/project/pocketmine/builds/$RPI_BUILD.tar.gz$EXTRA_URL" | tar -zx > /dev/null 2>&1
			chmod +x ./bin/php5/bin/*
			echo -n " checking..."
			if [ $(./bin/php5/bin/php -r 'echo "yes";' 2>/dev/null) == "yes" ]; then
				echo -n " regenerating php.ini..."
				TIMEZONE=$(date +%Z)
				OPCACHE_PATH="$(find $(pwd) -name opcache.so)"
				XDEBUG_PATH="$(find $(pwd) -name xdebug.so)"
				echo "" > "./bin/php5/bin/php.ini"
				#UOPZ_PATH="$(find $(pwd) -name uopz.so)"
				#echo "zend_extension=\"$UOPZ_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$OPCACHE_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$XDEBUG_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable_cli=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.save_comments=0" >> "./bin/php5/bin/php.ini"
				echo "opcache.fast_shutdown=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.max_accelerated_files=4096" >> "./bin/php5/bin/php.ini"
				echo "opcache.interned_strings_buffer=8" >> "./bin/php5/bin/php.ini"
				echo "opcache.memory_consumption=128" >> "./bin/php5/bin/php.ini"
				echo "opcache.optimization_level=0xffffffff" >> "./bin/php5/bin/php.ini"
				echo "date.timezone=$TIMEZONE" >> "./bin/php5/bin/php.ini"
				echo "short_open_tag=0" >> "./bin/php5/bin/php.ini"
				echo "asp_tags=0" >> "./bin/php5/bin/php.ini"
				echo "phar.readonly=0" >> "./bin/php5/bin/php.ini"
				echo "phar.require_hash=1" >> "./bin/php5/bin/php.ini"
				echo " done"
				alldone=yes
			else
				echo " invalid build detected"
			fi
		elif [ "$IS_ODROID" -eq 0 ] && [ "$forcecompile" == "off" ]; then
			rm -r -f bin/ >> /dev/null 2>&1
			echo -n "[3/3] ODROID PHP build available, downloading $ODROID_BUILD.tar.gz..."
			download_file "https://downloads.sourceforge.net/project/pocketmine/builds/$ODROID_BUILD.tar.gz$EXTRA_URL" | tar -zx > /dev/null 2>&1
			chmod +x ./bin/php5/bin/*
			echo -n " checking..."
			if [ $(./bin/php5/bin/php -r 'echo "yes";' 2>/dev/null) == "yes" ]; then
				echo -n " regenerating php.ini..."
				OPCACHE_PATH="$(find $(pwd) -name opcache.so)"
				XDEBUG_PATH="$(find $(pwd) -name xdebug.so)"
				echo "" > "./bin/php5/bin/php.ini"
				#UOPZ_PATH="$(find $(pwd) -name uopz.so)"
				#echo "zend_extension=\"$UOPZ_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$OPCACHE_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$XDEBUG_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable_cli=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.save_comments=0" >> "./bin/php5/bin/php.ini"
				echo "opcache.fast_shutdown=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.max_accelerated_files=4096" >> "./bin/php5/bin/php.ini"
				echo "opcache.interned_strings_buffer=8" >> "./bin/php5/bin/php.ini"
				echo "opcache.memory_consumption=128" >> "./bin/php5/bin/php.ini"
				echo "opcache.optimization_level=0xffffffff" >> "./bin/php5/bin/php.ini"
				echo "date.timezone=$TIMEZONE" >> "./bin/php5/bin/php.ini"
				echo "short_open_tag=0" >> "./bin/php5/bin/php.ini"
				echo "asp_tags=0" >> "./bin/php5/bin/php.ini"
				echo "phar.readonly=0" >> "./bin/php5/bin/php.ini"
				echo "phar.require_hash=1" >> "./bin/php5/bin/php.ini"
				echo " done"
				alldone=yes
			else
				echo " invalid build detected"
			fi
		elif [ "$forcecompile" == "off" ] && [ "$(uname -s)" == "Linux" ]; then
			rm -r -f bin/ >> /dev/null 2>&1
			
			if [[ "$(cat /etc/redhat-release 2>/dev/null)" == *CentOS* ]]; then
				if [ `getconf LONG_BIT` = "64" ]; then
					echo -n "[3/3] CentOS 64-bit PHP build available, downloading $CENTOS_64_BUILD.tar.gz..."
					LINUX_BUILD="$CENTOS_64_BUILD"
				else
					echo -n "[3/3] CentOS 32-bit PHP build available, downloading $CENTOS_32_BUILD.tar.gz..."
					LINUX_BUILD="$CENTOS_32_BUILD"
				fi
			else
				if [ `getconf LONG_BIT` = "64" ]; then
					echo -n "[3/3] Linux 64-bit PHP build available, downloading $LINUX_64_BUILD.tar.gz..."
					LINUX_BUILD="$LINUX_64_BUILD"
				else
					echo -n "[3/3] Linux 32-bit PHP build available, downloading $LINUX_32_BUILD.tar.gz..."
					LINUX_BUILD="$LINUX_32_BUILD"
				fi
			fi
			
			download_file "https://downloads.sourceforge.net/project/pocketmine/builds/$LINUX_BUILD.tar.gz$EXTRA_URL" | tar -zx > /dev/null 2>&1
			chmod +x ./bin/php5/bin/*
			echo -n " checking..."
			if [ $(./bin/php5/bin/php -r 'echo "yes";' 2>/dev/null) == "yes" ]; then
				echo -n " regenerating php.ini..."
				OPCACHE_PATH="$(find $(pwd) -name opcache.so)"
				XDEBUG_PATH="$(find $(pwd) -name xdebug.so)"
				echo "" > "./bin/php5/bin/php.ini"
				#UOPZ_PATH="$(find $(pwd) -name uopz.so)"
				#echo "zend_extension=\"$UOPZ_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$OPCACHE_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "zend_extension=\"$XDEBUG_PATH\"" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.enable_cli=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.save_comments=0" >> "./bin/php5/bin/php.ini"
				echo "opcache.fast_shutdown=1" >> "./bin/php5/bin/php.ini"
				echo "opcache.max_accelerated_files=4096" >> "./bin/php5/bin/php.ini"
				echo "opcache.interned_strings_buffer=8" >> "./bin/php5/bin/php.ini"
				echo "opcache.memory_consumption=128" >> "./bin/php5/bin/php.ini"
				echo "opcache.optimization_level=0xffffffff" >> "./bin/php5/bin/php.ini"
				echo "date.timezone=$TIMEZONE" >> "./bin/php5/bin/php.ini"
				echo "short_open_tag=0" >> "./bin/php5/bin/php.ini"
				echo "asp_tags=0" >> "./bin/php5/bin/php.ini"
				echo "phar.readonly=0" >> "./bin/php5/bin/php.ini"
				echo "phar.require_hash=1" >> "./bin/php5/bin/php.ini"
				echo " done"
				alldone=yes
			else
				echo " invalid build detected"
			fi
		fi
		if [ "$alldone" == "no" ]; then
			set -e
			echo "[3/3] no build found, compiling PHP"
			exec "./compile.sh"
		fi
	fi
fi

rm compile.sh

echo "[INFO] Everything done! Run ./start.sh to start PocketMine-MP"
exit 0
