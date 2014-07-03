#!/bin/bash

OUTPUT=$("$PHP_BINARIES" -r 'class MyThread extends \\Thread{ public function run(){ echo 1; }} $t = new MyThread; $t->start(); $t->join();')

if [ "$OUTPUT" != "1" ]; then
	exit 1
fi

exit 0