# Custom PHP build scripts for Voltage-Groups

use ``./compile.sh -t linux64 -j 4 -f -g``
- [Logs build](install.log) PHP_Linux-x86_64.tar.gz

## compile.sh

Bash script used to compile PHP on Linux platforms. Make sure you have ``apt install -y autoconf automake libtool libtool-bin m4 wget gzip bzip2 bison g++ git cmake pkg-config re2c libssh2-1 libssh2-1-dev``.

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
## Contents

- [License](./EUPL.md)

## Community

Active channels:

- Twitter: [@voltagegroups](https://twitter.com/VoltageGroups?t=wSiFVaX5GiHx8Z-LmSC7iQ&s=09)
- Discord: [ntF6gH6NNm](https://discord.gg/ntF6gH6NNm)
- © Voltage-Groups
<div align="center">
  <img src="http://image.noelshack.com/fichiers/2021/39/5/1633118741-logo-no-background.png" height="50" width="50" align="left"></img>
</div>
<br/><br/>

## © Voltage-Groups

Voltage-Groups are not affiliated with Mojang. All brands and trademarks belong to their respective owners. Voltage-Groups is not a Mojang-approved software, nor is it associated with Mojang.
