# Custom PHP build scripts for PocketMine-MP

## compile.sh

Use this script to build the custom PHP binary. Make sure you have ``make autoconf automake libtool m4 wget getconf gzip bzip2 bison g++``.


### Additional notes
#### Mac OSX (native compile)
- Most dependencies can be installed using Homebrew
- You will additionally need `glibtool` (GNU libtool, xcode libtool won't work)
- You also MUST specify target as `mac` or `mac64` if building for Mac, on Mac.

#### Android 64-bit (cross-compile)
- Only aarch64 targets are supported for Android cross-compile.
- The `aarch64-linux-musl` toolchain is required. You can compile and install it using https://github.com/richfelker/musl-cross-make
- Android cross-compile binaries MUST be compiled statically (using `-s`) or the binary will not work correctly.
- It is strongly recommended that you enable abusive optimizations for Android targets (`-f` flag) for best performance.

| Script flags | Description                                                                           |
| ------------ | ------------------------------------------------------------------------------------- |
| -c           | Will force compile cURL                                                               |
| -d           | Will compile with debug and the xdebug PHP extension                                  |
| -f           | Enabling abusive optimizations...                                                     |
| -g           | Will compile GD2                                                                      |
| -j           | Set make threads to #                                                                 |
| -l           | Will compile with LevelDB support (experimental with PHP7)                            |
| -s           | Will compile everything statically                                                    |
| -t           | Set target                                                                            |
| -u           | Will compile PocketMine-ChunkUtils C extension (recommended if using PC Anvil worlds) |
| -x           | Specifies we are doing cross-compile                                                  |

### Example:

| Target          | Arguments                           |
| --------------- | ----------------------------------- |
| linux64         | ``-t linux64 -l -j4 -c -f x86_64``  |
| mac64           | ``-t mac64 -l -j4 -c -f``           |
| android-aarch64 | ``-t android-aarch64 -x -s -j4 -f`` |

### Common pitfalls
- If used, the `-t` option (target) MUST be specified BEFORE the `-f` option (optimizations)
- Avoid using the script in directory trees containing spaces. Some libraries don't like trying to be built in directory trees containing spaces, e.g. `/home/user/my folder/pocketmine-mp/` might experience problems.

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
