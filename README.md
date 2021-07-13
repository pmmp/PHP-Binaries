# Custom PHP build scripts for Voltage-MC
- [Logs build](install.log) PHP-8.0-Linux-x86_64.tar.gz

## compile.sh

Bash script used to compile PHP on Linux platforms. Make sure you have ``apt install -y autoconf automake libtool libtool-bin m4 wget gzip bzip2 bison g++ git cmake pkg-config re2c``.

| Script flags | Description                                                                           |
| ------------ | ------------------------------------------------------------------------------------- |
| -d           | Will compile with debug and the xdebug PHP extension                                  |
| -f           | Enabling abusive optimizations...                                                     |
| -g           | Will compile GD2                                                                      |
| -j           | Set make threads to #                                                                 |
| -l           | Will compile with LevelDB support                                                     |
| -n           | Don't remove sources after completing compilation                                     |
| -s           | Will compile everything statically                                                    |
| -t           | Set target                                                                            |
| -u           | Will compile PocketMine-ChunkUtils C extension (recommended if using PC Anvil worlds) |
| -v           | Enable Valgrind support in PHP                                                        |
| -x           | Specifies we are doing cross-compile                                                  |

### Example:

| Target          | Arguments                        |
| --------------- | -------------------------------- |
| linux64         | ``-t linux64 -l -j4 -f x86_64``  |

### Common pitfalls
- If used, the `-t` option (target) MUST be specified BEFORE the `-f` option (optimizations)
- Avoid using the script in directory trees containing spaces. Some libraries don't like trying to be built in directory trees containing spaces, e.g. `/home/user/my folder/pocketmine-mp/` might experience problems.