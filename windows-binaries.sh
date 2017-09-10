#!/bin/bash
[ -z "$PHP_VERSION" ] && PHP_VERSION="7.0.23"
PHP_VERSION_BASE="${PHP_VERSION:0:3}"

PHP_IS_BETA="no"

PTHREADS_VERSION="3.1.6"
XDEBUG_VERSION="2.5.5"
WEAKREF_VERSION="0.3.3"
YAML_VERSION="2.0.2"

echo "[PocketMine] PHP Windows binary builder"
DIR="$(pwd)"

#Needed to use aliases
shopt -s expand_aliases
type wget >/dev/null 2>&1
if [ $? -eq 0 ]; then
	alias download_file="wget --no-check-certificate -q -O -"
else
	type curl >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		alias download_file="curl --insecure --silent --show-error --location --globoff"
	else
		echo "error, curl or wget not found"
		exit 1
	fi
fi

BUILD_TARGET="x86"

while getopts "::t:" OPTION; do

	case $OPTION in
		t)
			echo "[opt] Set target to $OPTARG"
			BUILD_TARGET="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTION$OPTARG" >&2
			exit 1
			;;
	esac
done

cd "$DIR" >/dev/null 2>&1

rm -rf "bin" >/dev/null 2>&1

rm -rf "temp_data" >/dev/null 2>&1

mkdir temp_data
cd temp_data

TMP_PATH="$DIR/temp_data"

echo -n "[PHP] downloading ${PHP_VERSION}..."

if [[ "$PHP_IS_BETA" == "yes" ]]; then
	download_file "http://windows.php.net/downloads/qa/php-$PHP_VERSION-Win32-VC14-$BUILD_TARGET.zip" > temp.zip && unzip -o temp.zip >/dev/null 2>&1 && rm temp.zip
	echo " done!"
else
	download_file "http://windows.php.net/downloads/releases/php-$PHP_VERSION-Win32-VC14-$BUILD_TARGET.zip" > temp.zip && unzip -o temp.zip >/dev/null 2>&1 && rm temp.zip
	echo " done!"
fi

if [ ! -d "ext" ]; then
	mkdir ext
fi
cd ext

echo -n "[pthreads] downloading ${PTHREADS_VERSION}..."
download_file "http://windows.php.net/downloads/pecl/releases/pthreads/$PTHREADS_VERSION/php_pthreads-$PTHREADS_VERSION-$PHP_VERSION_BASE-ts-vc14-$BUILD_TARGET.zip" > temp.zip && unzip -o temp.zip >/dev/null 2>&1 && rm temp.zip
echo " done!"

if [[ "$WEAKREF_VERSION" != "" ]]; then
	echo -n "[WeakRef] downloading ${WEAKREF_VERSION}..."
	download_file "http://windows.php.net/downloads/pecl/releases/weakref/$WEAKREF_VERSION/php_weakref-$WEAKREF_VERSION-$PHP_VERSION_BASE-ts-vc14-$BUILD_TARGET.zip" > temp.zip && unzip -o temp.zip >/dev/null 2>&1 && rm temp.zip
	echo " done!"
fi

echo -n "[YAML] downloading ${YAML_VERSION}..."
download_file "http://windows.php.net/downloads/pecl/releases/yaml/$YAML_VERSION/php_yaml-$YAML_VERSION-$PHP_VERSION_BASE-ts-vc14-$BUILD_TARGET.zip" > temp.zip && unzip -o temp.zip >/dev/null 2>&1 && rm temp.zip
echo " done!"

if [[ "$XDEBUG_VERSION" != "" ]]; then
	echo -n "[xdebug] downloading ${XDEBUG_VERSION}..."
	download_file "http://windows.php.net/downloads/pecl/releases/xdebug/$XDEBUG_VERSION/php_xdebug-$XDEBUG_VERSION-$PHP_VERSION_BASE-ts-vc14-$BUILD_TARGET.zip" > temp.zip && unzip -o temp.zip >/dev/null 2>&1 && rm temp.zip
	echo " done!"
fi

cd ../..

mkdir -p bin/php
cd bin/php


echo -n "Selecting files..."

cp "$TMP_PATH/php.exe" .
cp "$TMP_PATH/php7ts.dll" .
cp "$TMP_PATH/libeay32.dll" .
cp "$TMP_PATH/libssh2.dll" .
cp "$TMP_PATH/ssleay32.dll" .
cp "$TMP_PATH/license.txt" .
cp "$TMP_PATH/news.txt" .
cp "$TMP_PATH/readme-redist-bins.txt" .
cp "$TMP_PATH/ext/php_com_dotnet.dll" .
cp "$TMP_PATH/ext/php_curl.dll" .
cp "$TMP_PATH/ext/php_gmp.dll" .
cp "$TMP_PATH/ext/php_mbstring.dll" .
cp "$TMP_PATH/ext/php_mysqli.dll" .
cp "$TMP_PATH/ext/php_opcache.dll" .
#cp "$TMP_PATH/ext/php_openssl.dll" .
cp "$TMP_PATH/ext/php_pthreads.dll" .
cp "$TMP_PATH/ext/php_sockets.dll" .
cp "$TMP_PATH/ext/php_gd2.dll" .
cp "$TMP_PATH/ext/php_sqlite3.dll" .
cp "$TMP_PATH/ext/php_weakref.dll" .
cp "$TMP_PATH/ext/php_xdebug.dll" .
cp "$TMP_PATH/ext/php_yaml.dll" .
cp "$TMP_PATH/ext/yaml.dll" .
cp "$TMP_PATH/ext/pthreadVC2.dll" .

echo " done!"

echo -n "Creating php.ini..."

echo ";Custom PocketMine php.ini file" > php.ini
echo "zend.enable_gc = On" >> php.ini
echo "max_execution_time = 0" >> php.ini
echo "memory_limit = 256M" >> php.ini
echo "error_reporting = -1" >> php.ini
echo "display_errors = stderr" >> php.ini
echo "display_startup_errors = On" >> php.ini
echo "register_argc_argv = On" >> php.ini
echo 'default_charset = "UTF-8"' >> php.ini
echo 'include_path = ".;.\ext"' >> php.ini
echo 'extension_dir = "./"' >> php.ini
echo "enable_dl = On" >> php.ini
echo "allow_url_fopen = On" >> php.ini

echo "extension=php_weakref.dll" >> php.ini
echo "extension=php_curl.dll" >> php.ini
echo "extension=php_mysqli.dll" >> php.ini
#echo "extension=php_openssl.dll" >> php.ini
echo "extension=php_sqlite3.dll" >> php.ini
echo "extension=php_sockets.dll" >> php.ini
echo "extension=php_mbstring.dll" >> php.ini
echo "extension=php_yaml.dll" >> php.ini
echo "extension=php_pthreads.dll" >> php.ini
echo "extension=php_com_dotnet.dll" >> php.ini
echo "extension=php_gd2.dll" >> php.ini

echo "zend_extension=php_opcache.dll" >> php.ini
echo ";zend_extension=php_xdebug.dll" >> php.ini

echo "cli_server.color = On" >> php.ini
echo "phar.readonly = Off" >> php.ini
echo "phar.require_hash = On" >> php.ini
echo "zend.assertions=-1" >> php.ini
echo "opcache.enable=1" >> php.ini
echo "opcache.enable_cli=1" >> php.ini
echo "opcache.memory_consumption=128" >> php.ini
echo "opcache.interned_strings_buffer=8" >> php.ini
echo "opcache.max_accelerated_files=4000" >> php.ini
echo "opcache.save_comments=1" >> php.ini
echo "opcache.load_comments=1" >> php.ini
echo "opcache.fast_shutdown=0" >> php.ini
echo "opcache.optimization_level=0xffffffff" >> php.ini

TIMEZONE=$(date +%Z)
echo "date.timezone=$TIMEZONE" >> php.ini

echo " done!"

cd ../..
