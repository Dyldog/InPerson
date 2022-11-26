#!/bin/bash

if which mint >/dev/null; then
    mint run swiftlint --config .swiftlint.yml
else
    echo "Mint not installed. Install mint using the instructions in the README."
fi
