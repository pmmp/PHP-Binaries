# Custom PHP build scripts for PocketMine-MP

## compile.sh

Use this script to build the custom PHP binary. Make sure you have ``make autoconf automake libtool m4 wget getconf gzip bzip2 bison g++``.

| Flag   | Description                                                |
| ------ | ---------------------------------------------------------- |
| -t     | Set target                                                 |
| -j     | Set make threads to #                                      |
| -c     | Will force compile cURL                                    |
| -l     | Will compile with LevelDB support (experimental with PHP7) |
| -f     | Enabling abusive optimizations...                          |

### Example:

| Target  | Arguments |
| ------- | --------- |
| linux64 | ``-t linux64 -l -j 2 -c -f x86_64`` |
| mac64   | ``-t mac64 -l -j -c -f``            |


## installer.sh

Script to install PocketMine-MP and PHP binaries on Unix platforms.

| Flag   | Description                         |
| ------ | ----------------------------------- |
| -u     | Update PocketMine-MP                |
| -d     | Install directory                   |
| -v     | Channel (stable or development)     |


## windows-binaries.ps1

PowerShell script which can be executed on Windows to assemble a PHP binary with the extensions needed to run PocketMine-MP. Note that this script requires **PowerShell version 5** or later.

| Option | Description |
|:-------|:------------|
| -t, -target | Arch to build for (x86 (32-bit) or x64 (64-bit)) |
| -d, -debug | Include xdebug and enable debugging assertions by default. |
| -p, -path | Where to create the build. |
| -z, -zip | Zip the build after creation. Used by CI for distribution. |

Additionally, prebuilt Windows binaries can be downloaded from [AppVeyor](https://ci.appveyor.com/project/pmmp/php-build-scripts/build/artifacts).


## Extra libraries

### Unix

- https://github.com/madler/zlib/
- http://sourceforge.net/projects/mcrypt/
- https://gmplib.org/
- https://tls.mbed.org/
- https://github.com/bagder/curl/
- http://pyyaml.org/ or https://github.com/yaml/libyaml/
- https://sourceforge.net/projects/libpng/
- https://pecl.php.net/package/pthreads
- https://pecl.php.net/package/Weakref
- https://github.com/php/pecl-file_formats-yaml/

### Windows

- http://windows.php.net/downloads/pecl/releases/pthreads/
- http://windows.php.net/downloads/pecl/releases/weakref/
- http://windows.php.net/downloads/pecl/releases/yaml/
