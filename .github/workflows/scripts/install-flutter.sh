#!/bin/bash

git clone https://github.com/flutter/flutter.git --depth 1 -b 3.0.3 "$GITHUB_WORKSPACE/_flutter"
echo "$GITHUB_WORKSPACE/_flutter/bin" >> $GITHUB_PATH
