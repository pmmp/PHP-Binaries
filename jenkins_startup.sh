#!/bin/bash -e
export BRANCH
wget --no-check-certificate -q -O - https://github.com/PocketMine/php-build-scripts/raw/$BRANCH/jenkins.sh > "$WORKSPACE/jenkins.sh"
chmod +x "$WORKSPACE/jenkins.sh"
$WORKSPACE/jenkins.sh