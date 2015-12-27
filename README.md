# Custom PHP build scripts for PocketMine-MP

## compile.sh

Use this script to build the custom PHP binary. Make sure you have ``make autoconf automake libtool m4 wget getconf gzip bzip2 bison g++``.

| Flag   | Description                                                  |
| ------ | ------------------------------------------------------------ |
| -t     | Set target                                                   |
| -j     | Set make threads to #                                        |
| -c     | Will force compile cURL                                      |
| -l     | Will compile with LevelDB support (not supported with PHP7)  |
| -f     | Enabling abusive optimizations...                            |

### Example:

| Target  | Arguments |
| ------- | --------- |
| linux64 | ``-t linux64 -l -j 2 -c -f x86_64`` |
| mac64   | ``-t mac64 -l -j -c -f``            |

## installer.sh

Script to install PocketMine-MP and PHP binaries.

| Flag   | Description                         |
| ------ | ----------------------------------- |
| -u     | Update PocketMine-MP                |
| -d     | Install directory                   |
| -v     | Channel (stable or development)     |

## jenkins.sh

PHP binaries provided by PocketMine are build using this script. The script runs the ``compile.sh`` with some default arguments.
