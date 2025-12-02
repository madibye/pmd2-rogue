#!/usr/bin/env bash

WD="$PWD/$1"
if [ ! -f "$PWD/.git/info/sparse-checkout" ]
    then
    "./initialize_sparse_checkout.sh"
    fi
cd "$WD" || return
git sparse-checkout add "$2"
git pull origin master
