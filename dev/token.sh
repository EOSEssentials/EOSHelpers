!/bin/bash

#adds a new token to the eosio.token contract.

if [ "$#" -ne 3 ]; then
    echo "Usage: token.sh <ISSUER_ACCOUNT_NAME> <ISSUER_PUBLIC_KEY> <SYMBOL>"
    exit 1
fi

ISSUER=$1
PUBLIC_KEY=$2
SYMBOL=$3

cleos system newaccount eosio $ISSUER \
                $PUBLIC_KEY $PUBLIC_KEY \
                --stake-net "200.0000 SYS" \
                --stake-cpu "2000.0000 SYS" \
                --buy-ram "1000.0000 SYS" \
                -p eosio

PARAMS="[\"$ISSUER\", \"1000000000.0000 $SYMBOL\"]"
cleos push action eosio.token create "$PARAMS" -p eosio.token
