@echo off

set PHP_MAJOR_VER=7.2
set PHP_VER=%PHP_MAJOR_VER%.0RC1
set PHP_SDK_VER=2.0.10
set PATH=C:\Program Files\7-Zip;%PATH%
set VC_VER=vc15
set ARCH=x64
set CMAKE_TARGET=Visual Studio 15 2017 Win64

REM need this version to be able to compile as a shared library
set LIBYAML_VER=660242d6a418f0348c61057ed3052450527b3abf
set PTHREAD_W32_VER=2-9-1

set PHP_PTHREADS_VER=caca8dc42a5d75ddfb39e6fd15337e87e967517e
set PHP_YAML_VER=2.0.2

where git >nul 2>nul || (call :pm-echo-error "git is required" & exit 1)
where cmake >nul 2>nul || (call :pm-echo-error "cmake is required" & exit 1)
where 7z >nul 2>nul || (call :pm-echo-error "7z is required" & exit 1)

call :pm-echo "PHP Windows compiler"
call :pm-echo "Setting up environment..."
call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat" %ARCH% || exit 1

set script_path=%~dp0
if not exist "%script_path%win32\copy-static-deps.patch" (
	call :pm-echo "ERROR: Required patch %script_path%win32\copy-static-deps.patch not found"
	exit 1
)

if exist bin (
	call :pm-echo "Deleting old binary folder..."
	rmdir /s /q bin
)

pushd C:\

if exist pocketmine-php-sdk (
	call :pm-echo "Deleting old workspace..."
	rmdir /s /q pocketmine-php-sdk
)

call :pm-echo "Getting SDK..."
git clone https://github.com/OSTC/php-sdk-binary-tools.git -b php-sdk-%PHP_SDK_VER% --depth=1 -q pocketmine-php-sdk

cd pocketmine-php-sdk

call bin\phpsdk_setvars.bat

call :pm-echo "Downloading PHP source version %PHP_VER%..."
git clone https://github.com/php/php-src -b php-%PHP_VER% --depth=1 -q php-src
cd php-src

REM TODO: remove this (won't be needed as of RC2)
call :pm-echo "Applying mkdist patch..."
git apply --ignore-space-change --ignore-whitespace "%script_path%\win32\copy-static-deps.patch"
cd ..

call :pm-echo "Getting dependencies..."
call bin\phpsdk_deps.bat -u -t %VC_VER% -b %PHP_MAJOR_VER% -a %ARCH% -f -d deps


call :pm-echo "Getting additional extensions..."
cd php-src\ext

call :get-zip https://github.com/krakjoe/pthreads/archive/%PHP_PTHREADS_VER%.zip
move pthreads-%PHP_PTHREADS_VER% pthreads

call :get-zip https://github.com/php/pecl-file_formats-yaml/archive/%PHP_YAML_VER%.zip
move pecl-file_formats-yaml-%PHP_YAML_VER% yaml

cd ../..

call :pm-echo "Getting additional dependencies..."
cd deps

call :pm-echo "Downloading LibYAML version %LIBYAML_VER%..."
call :get-zip https://github.com/yaml/libyaml/archive/%LIBYAML_VER%.zip
move libyaml-%LIBYAML_VER% libyaml
cd libyaml
cmake -G "%CMAKE_TARGET%"
call :pm-echo "Compiling..."
msbuild yaml.sln /p:Configuration=RelWithDebInfo /m
call :pm-echo "Copying files..."
copy RelWithDebInfo\yaml.lib ..\lib\yaml.lib
copy RelWithDebInfo\yaml.dll ..\bin\yaml.dll
copy RelWithDebInfo\yaml.pdb ..\bin\yaml.pdb
copy include\yaml.h ..\include\yaml.h
cd ..

mkdir pthread-w32
cd pthread-w32
call :get-zip http://www.mirrorservice.org/sites/sources.redhat.com/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip
REM move pthreads-w32-2-9-1-release pthread-w32

copy Pre-built.2\include\pthread.h ..\include\pthread.h
copy Pre-built.2\include\sched.h ..\include\sched.h
copy Pre-built.2\include\semaphore.h ..\include\semaphore.h
copy Pre-built.2\lib\%ARCH%\pthreadVC2.lib ..\lib\pthreadVC2.lib
copy Pre-built.2\dll\%ARCH%\pthreadVC2.dll ..\bin\pthreadVC2.dll

cd ..\..

:skip
cd php-src
call :pm-echo "Configuring PHP..."
call buildconf.bat

REM Building GD would be nice, but there's some dependency issue in 7.2
call configure^
 --with-mp=auto^
 --with-prefix=pocketmine-php-bin^
 --enable-debug-pack^
 --disable-all^
 --disable-cgi^
 --enable-cli^
 --enable-zts^
 --enable-bcmath^
 --enable-ctype^
 --enable-filter^
 --enable-hash^
 --enable-json^
 --enable-mbstring^
 --enable-phar^
 --enable-sockets^
 --enable-zip^
 --enable-zlib^
 --with-curl^
 --without-gd^
 --with-gmp^
 --with-openssl^
 --with-pthreads^
 --with-sodium^
 --with-yaml^
 --without-readline

call :pm-echo "Compiling PHP..."
nmake

call :pm-echo "Assembling artifacts..."
nmake snap

popd

call :pm-echo "Copying artifacts..."
mkdir bin
move C:\pocketmine-php-sdk\php-src\%ARCH%\Release_TS\php-%PHP_VER% bin\php
REM TODO: create a php.ini

call :pm-echo "Packaging build..."
set package_filename=php-%PHP_VER%-%VC_VER%-%ARCH%.zip
if exist %package_filename% rm %package_filename%
7z a %package_filename% bin || (call :pm-echo-error "Failed to package the build!" & exit 1)

call :pm-echo "Created build package %package_filename%"
call :pm-echo "Done?"

exit 0

:get-zip
wget %~1 --no-check-certificate -q -O temp.zip
7z x -y temp.zip
rm temp.zip
exit /B 0

:pm-echo-error
call :pm-echo "[ERROR] %~1"
exit /B 0

:pm-echo
echo [PocketMine] %~1
exit /B 0