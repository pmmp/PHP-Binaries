# Custom PHP build scripts for PocketMine-MP
[![Build status](https://github.com/pmmp/php-build-scripts/actions/workflows/main.yml/badge.svg)](https://github.com/pmmp/php-build-scripts/actions/workflows/main.yml)

## Looking for prebuilt binaries? Head over to [releases](https://github.com/pmmp/PHP-Binaries/releases/latest)

## compile.sh

Bash script used to compile PHP on MacOS and Linux platforms. Make sure you have ``make autoconf automake libtool m4 wget getconf gzip bzip2 bison g++ git cmake pkg-config re2c ca-certificates``.

### Recommendations
- If you're going to use the compiled binary only on the machine you're build it on, remove the `-t` option for best performance - this will allow the script to optimize for the current machine rather than a generic one.
- [`ext-gd2`](https://www.php.net/manual/en/book.image.php) is NOT included unless the `-g` flag is provided, as PocketMine-MP doesn't need it. However, if your plugins need it, don't forget to enable it using `-g`.
- The `-c` and `-l` options can be used to specify cache folders to speed up recompiling if you're recompiling many times (e.g. to improve the script).

### Common pitfalls
- Avoid using the script in directory trees containing spaces. Some libraries don't like trying to be built in directory trees containing spaces, e.g. `/home/user/my folder/pocketmine-mp/` might experience problems.

### Additional notes
#### Mac OSX (native compile)
- Most dependencies can be installed using Homebrew
- You will additionally need `glibtool` (GNU libtool, xcode libtool won't work)

#### Android 64-bit (cross-compile)
- Only aarch64 targets are supported for Android cross-compile.
- The `aarch64-linux-musl` toolchain is required. You can compile and install it using https://github.com/pmmp/musl-cross-make (PMMP fork includes musl-libc patches for DNS resolver config path and increasing stack size limit for LevelDB)
- It is strongly recommended that you enable abusive optimizations for Android targets (`-f` flag) for best performance.

| Script flags | Description                                                                                           |
|--------------|-------------------------------------------------------------------------------------------------------|
| -c           | Uses the folder specified for caching downloaded tarballs, zipballs etc.                              |
| -d           | Compiles with debugging symbols and disables optimizations (slow, but useful for debugging segfaults) |
| -g           | Will compile GD2                                                                                      |
| -j           | Set make threads to #                                                                                 |
| -l           | Uses the folder specified for caching compilation artifacts (useful for rapid rebuild and testing)    |
| -n           | Don't remove sources after completing compilation                                                     |
| -s           | Will compile everything statically                                                                    |
| -t           | Set target                                                                                            |
| -v           | Enable Valgrind support in PHP                                                                        |
| -x           | Specifies we are doing cross-compile                                                                  |
| -P           | Compiles extensions for the major PocketMine-MP version specified (can be `4` or `5`)                 |

### Example:

| Target          | Arguments                         |
|-----------------|-----------------------------------|
| linux64         | ``-t linux64 -j4 -P5``            |
| linux64, PM4    | ``-t linux64 -j4 -P4``            |
| mac64           | ``-t mac-x86-64 -j4 -P5``         |
| android-aarch64 | ``-t android-aarch64 -x -j4 -P5`` |

## windows-compile-vs.bat

Batch script utilizing Visual Studio on Windows to compile PHP binaries from sources.
Ensure you have Visual Studio 2019, `git`, `7z` and `wget` installed in your PATH.

This script doesn't accept parameters, but the following environment variables are influential:

| Variable | Description                                                                                                        |
| -------- |--------------------------------------------------------------------------------------------------------------------|
| `PHP_DEBUG_BUILD` | Disables optimisations and builds PHP with detailed debugging information (useful for debugging segfaults)|
| `SOURCES_PATH` | Where to put the downloaded sources for compilation                                                          |
| `VS_EDITION` | Edition of Visual Studio installed, set to `Community` by default                                              |
| `PM_VERSION_MAJOR` | Major version of PocketMine-MP to build extensions for (defaults to 4, can be `4` or `5`)                |
