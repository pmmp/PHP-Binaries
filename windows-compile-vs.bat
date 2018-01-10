@echo off

REM For future users: This file MUST have CRLF line endings. If it doesn't, lots of inexplicable undesirable strange behaviour will result.
REM Also: Don't modify this version with sed, or it will screw up your line endings.
set PHP_MAJOR_VER=7.2
set PHP_VER=%PHP_MAJOR_VER%.1
set PHP_IS_BETA="no"
set PHP_SDK_VER=2.0.13
set PATH=C:\Program Files\7-Zip;C:\Program Files (x86)\GnuWin32\bin;%PATH%
set VC_VER=vc15
set ARCH=x64
set CMAKE_TARGET=Visual Studio 15 2017 Win64

REM need this version to be able to compile as a shared library
set LIBYAML_VER=660242d6a418f0348c61057ed3052450527b3abf
set PTHREAD_W32_VER=2-9-1

set PHP_PTHREADS_VER=1c9787e5d918a3602661290ff5efe32ba3df74c8
set PHP_YAML_VER=2.0.2
set PHP_POCKETMINE_CHUNKUTILS_VER=master

set script_path=%~dp0
set log_file=%script_path%compile.log
echo.>"%log_file%"

set outpath="%cd%"

where git >nul 2>nul || (call :pm-echo-error "git is required" & exit 1)
where cmake >nul 2>nul || (call :pm-echo-error "cmake is required" & exit 1)
where 7z >nul 2>nul || (call :pm-echo-error "7z is required" & exit 1)

call :pm-echo "PHP Windows compiler"
call :pm-echo "Setting up environment..."
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %ARCH% >>"%log_file%" 2>&1 || exit 1

cd "%outpath%"

if exist bin (
	call :pm-echo "Deleting old binary folder..."
	rmdir /s /q bin >>"%log_file%" 2>&1 || exit 1
)

cd C:\

if exist pocketmine-php-sdk (
	call :pm-echo "Deleting old workspace..."
	rmdir /s /q pocketmine-php-sdk >>"%log_file%" 2>&1 || exit 1
)

call :pm-echo "Getting SDK..."
git clone https://github.com/OSTC/php-sdk-binary-tools.git -b php-sdk-%PHP_SDK_VER% --depth=1 -q pocketmine-php-sdk >>"%log_file%" 2>&1

cd pocketmine-php-sdk

call bin\phpsdk_setvars.bat >>"%log_file%" 2>&1

call :pm-echo "Downloading PHP source version %PHP_VER%..."
if "%PHP_IS_BETA%" == "yes" (
	git clone https://github.com/php/php-src -b php-%PHP_VER% --depth=1 -q php-src >>"%log_file%" 2>&1
) else (
	call :get-zip http://windows.php.net/downloads/releases/php-%PHP_VER%-src.zip >>"%log_file%" 2>&1
	move php-%PHP_VER%-src php-src >>"%log_file%" 2>&1
)

set DEPS_DIR_NAME="deps"
set DEPS_DIR="%cd%\%DEPS_DIR_NAME%"

call :pm-echo "Getting PHP dependencies..."
call bin\phpsdk_deps.bat -u -t %VC_VER% -b %PHP_MAJOR_VER% -a %ARCH% -f -d %DEPS_DIR_NAME% >>"%log_file%" 2>&1 || exit 1


call :pm-echo "Getting additional dependencies..."
cd "%DEPS_DIR%"

call :pm-echo "Downloading LibYAML version %LIBYAML_VER%..."
call :get-zip https://github.com/yaml/libyaml/archive/%LIBYAML_VER%.zip || exit 1
move libyaml-%LIBYAML_VER% libyaml >>"%log_file%" 2>&1
cd libyaml
cmake -G "%CMAKE_TARGET%" >>"%log_file%" 2>&1
call :pm-echo "Compiling..."
msbuild yaml.sln /p:Configuration=RelWithDebInfo /m >>"%log_file%" 2>&1 || exit 1
call :pm-echo "Copying files..."
copy RelWithDebInfo\yaml.lib "%DEPS_DIR%\lib\yaml.lib" >>"%log_file%" 2>&1
copy RelWithDebInfo\yaml.dll "%DEPS_DIR%\bin\yaml.dll" >>"%log_file%" 2>&1
copy RelWithDebInfo\yaml.pdb "%DEPS_DIR%\bin\yaml.pdb" >>"%log_file%" 2>&1
copy include\yaml.h "%DEPS_DIR%\include\yaml.h" >>"%log_file%" 2>&1

cd "%DEPS_DIR%"

call :pm-echo "Downloading pthread-w32 version %PTHREAD_W32_VER%..."
mkdir pthread-w32
cd pthread-w32
call :get-zip http://www.mirrorservice.org/sites/sources.redhat.com/pub/pthreads-win32/pthreads-w32-%PTHREAD_W32_VER%-release.zip || exit 1
cd pthreads.2

REM Hack for HAVE_STRUCT_TIMESPEC for newer VS versions - it doesn't compile in VS2017 without it
REM really this should do some nice replacement, but text replace in batchfile is a pain
REM hack start
chcp 65001 & echo #ifndef HAVE_STRUCT_TIMESPEC^

#define HAVE_STRUCT_TIMESPEC 1^

#endif^
 >>config.h
REM hack end

call :pm-echo "Compiling..."
nmake VC-inlined >>"%log_file%" 2>&1 || exit 1

call :pm-echo "Copying files..."
copy pthread.h "%DEPS_DIR%\include\pthread.h" >>"%log_file%" 2>&1
copy sched.h "%DEPS_DIR%\include\sched.h" >>"%log_file%" 2>&1
copy semaphore.h "%DEPS_DIR%\include\semaphore.h" >>"%log_file%" 2>&1
copy pthreadVC2.lib "%DEPS_DIR%\lib\pthreadVC2.lib" >>"%log_file%" 2>&1
copy pthreadVC2.dll "%DEPS_DIR%\bin\pthreadVC2.dll" >>"%log_file%" 2>&1
copy pthreadVC2.pdb "%DEPS_DIR%\bin\pthreadVC2.pdb" >>"%log_file%" 2>&1

cd "%DEPS_DIR%"

cd ..

call :pm-echo "Getting additional PHP extensions..."
cd php-src\ext

call :pm-echo "Downloading PHP pthreads version %PHP_PTHREADS_VER%..."
call :get-zip https://github.com/krakjoe/pthreads/archive/%PHP_PTHREADS_VER%.zip || exit 1
move pthreads-%PHP_PTHREADS_VER% pthreads >>"%log_file%" 2>&1 || exit 1

call :pm-echo "Downloading PHP YAML version %PHP_YAML_VER%..."
call :get-zip https://github.com/php/pecl-file_formats-yaml/archive/%PHP_YAML_VER%.zip || exit 1
move pecl-file_formats-yaml-%PHP_YAML_VER% yaml >>"%log_file%" 2>&1 || exit 1

call :pm-echo "Downloading PocketMine-ChunkUtils version %PHP_POCKETMINE_CHUNKUTILS_VER%..."
call :get-zip https://github.com/dktapps/PocketMine-C-ChunkUtils/archive/%PHP_POCKETMINE_CHUNKUTILS_VER%.zip || exit 1
move PocketMine-C-ChunkUtils-%PHP_POCKETMINE_CHUNKUTILS_VER% pocketmine_chunkutils >>"%log_file%" 2>&1 || exit 1

cd ..\..

:skip
cd php-src
call :pm-echo "Configuring PHP..."
call buildconf.bat >>"%log_file%" 2>&1

call configure^
 --with-mp=auto^
 --with-prefix=pocketmine-php-bin^
 --enable-debug-pack^
 --disable-all^
 --disable-cgi^
 --enable-cli^
 --enable-zts^
 --enable-bcmath^
 --enable-calendar^
 --enable-ctype^
 --enable-filter^
 --enable-hash^
 --enable-json^
 --enable-mbstring^
 --disable-opcache^
 --enable-phar^
 --enable-pocketmine-chunkutils=shared^
 --enable-sockets^
 --enable-tokenizer^
 --enable-zip^
 --enable-zlib^
 --with-bz2=shared^
 --with-curl^
 --with-dom^
 --with-gd=shared^
 --with-gmp^
 --with-iconv^
 --with-libxml^
 --with-mysqli=shared^
 --with-mysqlnd^
 --with-openssl^
 --with-pcre-jit^
 --with-pthreads^
 --with-sodium^
 --with-sqlite3=shared^
 --with-xml^
 --with-yaml^
 --without-readline >>"%log_file%" 2>&1 || (call :pm-echo-error "Error configuring PHP" & exit 1)

call :pm-echo "Compiling PHP..."
nmake >>"%log_file%" 2>&1 || (call :pm-echo-error "Error compiling PHP" & exit 1)

call :pm-echo "Assembling artifacts..."
nmake snap >>"%log_file%" 2>&1 || (call :pm-echo-error "Error assembling artifacts" & exit 1)

cd "%outpath%"

call :pm-echo "Copying artifacts..."
mkdir bin
move C:\pocketmine-php-sdk\php-src\%ARCH%\Release_TS\php-%PHP_VER% bin\php
cd bin\php

set php_ini=php.ini
call :pm-echo "Generating php.ini..."
(echo ;Custom PocketMine-MP php.ini file)>"%php_ini%"
(echo display_errors=1)>>"%php_ini%"
(echo display_startup_errors=1)>>"%php_ini%"
(echo error_reporting=-1)>>"%php_ini%"
(echo zend.assertions=-1)>>"%php_ini%"
(echo phar.readonly=0)>>"%php_ini%"
(echo extension_dir=ext)>>"%php_ini%"
(echo extension=php_openssl.dll)>>"%php_ini%"
(echo extension=php_pocketmine_chunkutils.dll)>>"%php_ini%"
(echo ;zend_extension=php_opcache.dll)>>"%php_ini%"
echo ;The following extensions are included as shared extensions (DLLs) but disabled by default as they are optional. Uncomment the ones you want to enable.>>"%php_ini%"
(echo ;extension=php_gd2.dll)>>"%php_ini%"
(echo ;extension=php_mysqli.dll)>>"%php_ini%"
(echo ;extension=php_sqlite3.dll)>>"%php_ini%"
REM TODO: more entries

cd ..\..

call :pm-echo "Checking PHP build works..."
bin\php\php.exe --version >>"%log_file%" 2>&1 || (call :pm-echo-error "PHP build isn't working" & exit 1)



call :pm-echo "Getting Composer..."

set expect_signature=INVALID
for /f %%i in ('wget --no-check-certificate -q -O - https://composer.github.io/installer.sig') do set expect_signature=%%i

wget --no-check-certificate  -q -O composer-setup.php https://getcomposer.org/installer
set actual_signature=INVALID2
for /f %%i in ('bin\php\php.exe -r "echo hash_file(\"SHA384\", \"composer-setup.php\");"') do set actual_signature=%%i

call :pm-echo "Checking Composer installer signature..."
if "%expect_signature%" == "%actual_signature%" (
	call :pm-echo "Installing composer to 'bin'..."
	call bin\php\php.exe composer-setup.php --install-dir=bin >>"%log_file%" 2>&1 || exit 1
	rm composer-setup.php

	call :pm-echo "Creating bin\composer.bat..."
	echo @echo off >bin\composer.bat
	echo "%%~dp0php\php.exe" "%%~dp0composer.phar" %%* >>bin\composer.bat
) else (
	call :pm-echo-error "Bad signature on Composer installer, skipping"
)



call :pm-echo "Packaging build..."
set package_filename=php-%PHP_VER%-%VC_VER%-%ARCH%.zip
if exist %package_filename% rm %package_filename%
7z a -bd %package_filename% bin >nul || (call :pm-echo-error "Failed to package the build!" & exit 1)

call :pm-echo "Created build package %package_filename%"
call :pm-echo "Moving debugging symbols to output directory..."
move C:\pocketmine-php-sdk\php-src\%ARCH%\Release_TS\php-debug-pack*.zip .
call :pm-echo "Done?"

exit 0

:get-zip
wget %~1 --no-check-certificate -q -O temp.zip
7z x -y temp.zip >nul
rm temp.zip
exit /B 0

:pm-echo-error
call :pm-echo "[ERROR] %~1"
exit /B 0

:pm-echo
echo [PocketMine] %~1
echo [PocketMine] %~1 >>"%log_file%" 2>&1
exit /B 0