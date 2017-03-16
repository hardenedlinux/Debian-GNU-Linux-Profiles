#!/bin/sh
exec gpg -o $(basename $1).sig --detach-sign $1
