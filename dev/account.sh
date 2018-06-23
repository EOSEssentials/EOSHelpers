#!/bin/bash

# Creaates a new account with self delegated resources

if [ "$#" -ne 2 ]; then
    echo "Usage: account.sh <ACCOUNT_NAME> <PUBLIC_KEY>"
    exit 1
fi

cleos system newaccount eosio $1 \
        $2 $2 \
        --stake-net "100.0000 SYS" \
        --stake-cpu "2000.0000 SYS" \
        --buy-ram "10000.0000 SYS" \
        -p eosio
