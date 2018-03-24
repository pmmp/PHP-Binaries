#!/bin/bash
git clone https://github.com/pmmp/PocketMine-MP.git --recursive
cd PocketMine-MP
../bin/composer install
./tests/travis.sh -p $(pwd)/../bin/php7/bin/php