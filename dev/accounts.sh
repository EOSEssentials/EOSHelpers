#!/bin/bash

# Use for creating the same accounts every time.
# Great for when you want to blow away an entire and set it back up easily.

ACCOUNTS=(im an array of account names)

create(){
        cleos system newaccount eosio $1 \
                EOS5AwwyqQTsrMTkBbGxkbJz9vMugi7d3zHBRiGvbWv1eU4dGYc4v EOS5AwwyqQTsrMTkBbGxkbJz9vM$
                --stake-net "100.0000 SYS" \
                --stake-cpu "250.0000 SYS" \
                --buy-ram "2000.0000 SYS" \
                -p eosio

}

for name in "${ACCOUNTS[@]}"
do
        create $name
done
