#!/bin/bash

if which mint >/dev/null; then
    mint run swiftformat Source/.
else
    echo "Mint not installed. Install mint using the instructions in the README."
fi
