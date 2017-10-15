@echo off

set PHP_MAJOR_VER=7.2
set PHP_VER=%PHP_MAJOR_VER%.0RC4
set PHP_SDK_VER=2.0.10
set PATH=C:\Program Files\7-Zip;C:\Program Files (x86)\GnuWin32\bin;%PATH%
set VC_VER=vc15
set ARCH=x64
set CMAKE_TARGET=Visual Studio 15 2017 Win64

REM need this version to be able to compile as a shared library
set LIBYAML_VER=660242d6a418f0348c61057ed3052450527b3abf
set PTHREAD_W32_VER=2-9-1

set PHP_PTHREADS_VER=caca8dc42a5d75ddfb39e6fd15337e87e967517e
set PHP_YAML_VER=2.0.2
set PHP_POCKETMINE_CHUNKUTILS_VER=master

set script_path=%~dp0
set log_file=%script_path%compile.log
echo.>"%log_file%"

where git >nul 2>nul || (call :pm-echo-error "git is required" & exit 1)
where cmake >nul 2>nul || (call :pm-echo-error "cmake is required" & exit 1)
where 7z >nul 2>nul || (call :pm-echo-error "7z is required" & exit 1)

call :pm-echo "PHP Windows compiler"
call :pm-echo "Setting up environment..."
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %ARCH% >>"%log_file%" || exit 1

if exist bin (
	call :pm-echo "Deleting old binary folder..."
	rmdir /s /q bin >>"%log_file%" || exit 1
)

pushd C:\

if exist pocketmine-php-sdk (
	call :pm-echo "Deleting old workspace..."
	rmdir /s /q pocketmine-php-sdk >>"%log_file%" || exit 1
)

call :pm-echo "Getting SDK..."
git clone https://github.com/OSTC/php-sdk-binary-tools.git -b php-sdk-%PHP_SDK_VER% --depth=1 -q pocketmine-php-sdk >>"%log_file%"

cd pocketmine-php-sdk

call bin\phpsdk_setvars.bat >>"%log_file%"

call :pm-echo "Downloading PHP source version %PHP_VER%..."
git clone https://github.com/php/php-src -b php-%PHP_VER% --depth=1 -q php-src >>"%log_file%"

call :pm-echo "Getting PHP dependencies..."
call bin\phpsdk_deps.bat -u -t %VC_VER% -b %PHP_MAJOR_VER% -a %ARCH% -f -d deps >>"%log_file%" || exit 1


call :pm-echo "Getting additional dependencies..."
cd deps

call :pm-echo "Downloading LibYAML version %LIBYAML_VER%..."
call :get-zip https://github.com/yaml/libyaml/archive/%LIBYAML_VER%.zip || exit 1
move libyaml-%LIBYAML_VER% libyaml >>"%log_file%"
cd libyaml
cmake -G "%CMAKE_TARGET%" >>"%log_file%"
call :pm-echo "Compiling..."
msbuild yaml.sln /p:Configuration=RelWithDebInfo /m >>"%log_file%" || exit 1
call :pm-echo "Copying files..."
copy RelWithDebInfo\yaml.lib ..\lib\yaml.lib >>"%log_file%"
copy RelWithDebInfo\yaml.dll ..\bin\yaml.dll >>"%log_file%"
copy RelWithDebInfo\yaml.pdb ..\bin\yaml.pdb >>"%log_file%"
copy include\yaml.h ..\include\yaml.h >>"%log_file%"
cd ..

call :pm-echo "Downloading pthread-w32 version %PTHREAD_W32_VER%..."
mkdir pthread-w32
cd pthread-w32
call :get-zip http://www.mirrorservice.org/sites/sources.redhat.com/pub/pthreads-win32/pthreads-w32-%PTHREAD_W32_VER%-release.zip || exit 1

call :pm-echo "Copying files..."
copy Pre-built.2\include\pthread.h ..\include\pthread.h >>"%log_file%"
copy Pre-built.2\include\sched.h ..\include\sched.h >>"%log_file%"
copy Pre-built.2\include\semaphore.h ..\include\semaphore.h >>"%log_file%"
copy Pre-built.2\lib\%ARCH%\pthreadVC2.lib ..\lib\pthreadVC2.lib >>"%log_file%"
copy Pre-built.2\dll\%ARCH%\pthreadVC2.dll ..\bin\pthreadVC2.dll >>"%log_file%"

cd ..\..

call :pm-echo "Getting additional PHP extensions..."
cd php-src\ext

call :pm-echo "Downloading PHP pthreads version %PHP_PTHREADS_VER%..."
call :get-zip https://github.com/krakjoe/pthreads/archive/%PHP_PTHREADS_VER%.zip || exit 1
move pthreads-%PHP_PTHREADS_VER% pthreads >>"%log_file%" || exit 1

call :pm-echo "Downloading PHP YAML version %PHP_YAML_VER%..."
call :get-zip https://github.com/php/pecl-file_formats-yaml/archive/%PHP_YAML_VER%.zip || exit 1
move pecl-file_formats-yaml-%PHP_YAML_VER% yaml >>"%log_file%" || exit 1

call :pm-echo "Downloading PocketMine-ChunkUtils version %PHP_POCKETMINE_CHUNKUTILS_VER%..."
call :get-zip https://github.com/dktapps/PocketMine-C-ChunkUtils/archive/%PHP_POCKETMINE_CHUNKUTILS_VER%.zip || exit 1
move PocketMine-C-ChunkUtils-%PHP_POCKETMINE_CHUNKUTILS_VER% pocketmine_chunkutils >>"%log_file%" || exit 1

cd ../..

:skip
cd php-src
call :pm-echo "Configuring PHP..."
call buildconf.bat >>"%log_file%"

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
 --enable-zip^
 --enable-zlib^
 --with-bz2=shared^
 --with-curl^
 --with-gd=shared^
 --with-gmp^
 --with-mysqli=shared^
 --with-mysqlnd^
 --with-openssl^
 --with-pcre-jit^
 --with-pthreads^
 --with-sodium^
 --with-sqlite3=shared^
 --with-yaml^
 --without-readline >>"%log_file%" || (call :pm-echo-error "Error configuring PHP" & exit 1)

call :pm-echo "Compiling PHP..."
nmake >>"%log_file%" || (call :pm-echo-error "Error compiling PHP" & exit 1)

call :pm-echo "Assembling artifacts..."
nmake snap >>"%log_file%" || (call :pm-echo-error "Error assembling artifacts" & exit 1)

popd

call :pm-echo "Copying artifacts..."
mkdir bin
move C:\pocketmine-php-sdk\php-src\%ARCH%\Release_TS\php-%PHP_VER% bin\php
cd bin\php

call :pm-echo "Generating php.ini..."
echo extension_dir=ext >php.ini
echo extension=php_openssl.dll >>php.ini
echo extension=php_pocketmine_chunkutils.dll >>php.ini
echo ;zend_extension=php_opcache.dll >>php.ini
echo zend.assertions=-1 >>php.ini
echo ;The following extensions are included as shared extensions (DLLs) but disabled by default as they are optional. Uncomment the ones you want to enable. >>php.ini
echo ;extension=php_gd2.dll >>php.ini
echo ;extension=php_mysqli.dll >>php.ini
echo ;extension=php_sqlite3.dll >>php.ini
REM TODO: more entries

cd ..\..

call :pm-echo "Checking PHP build works..."
bin\php\php.exe --version >>"%log_file%" || (call :pm-echo-error "PHP build isn't working" & exit 1)



call :pm-echo "Getting Composer..."

set expect_signature=INVALID
for /f %%i in ('wget --no-check-certificate -q -O - https://composer.github.io/installer.sig') do set expect_signature=%%i

wget --no-check-certificate  -q -O composer-setup.php https://getcomposer.org/installer
set actual_signature=INVALID2
for /f %%i in ('bin\php\php.exe -r "echo hash_file(\"SHA384\", \"composer-setup.php\");"') do set actual_signature=%%i

call :pm-echo "Checking Composer installer signature..."
if "%expect_signature%" == "%actual_signature%" (
	call :pm-echo "Installing composer to 'bin'..."
	call bin\php\php.exe composer-setup.php --install-dir=bin >>"%log_file%" || exit 1
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
echo [PocketMine] %~1 >>"%log_file%"
exit /B 0