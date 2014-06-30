#!/bin/bash

OUTPUT=$("$PHP_BINARIES/bin/php" -r 'echo 1;')

if [ "$OUTPUT" != "1" ]; then
	exit 1
fi

exit 0