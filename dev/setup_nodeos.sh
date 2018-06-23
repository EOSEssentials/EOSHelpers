#!/bin/bash

# Sets up nodeos after blowing it away or from a fresh install.
# Uses the standard EOSIO public key to initialize.
# Defaults the the `eos` directory to `~/eos` if no path is specified

# !!!FAQ!!! You might need to run this twice.
# It seems to time out on setting the eosio.system contract.

EOS_BASE_PATH="$HOME/eos"

if [ "$#" -eq 1 ]; then
    EOS_BASE_PATH=$1
fi

PKEY=EOS6MRyAjQq8ud7hVNYcfnVPJqcVpscN5So8BhtHuGYqET5GDW5CV

cleos create account eosio eosio.ram $PKEY $PKEY -p eosio
cleos create account eosio eosio.ramfee $PKEY $PKEY -p eosio
cleos create account eosio eosio.stake $PKEY $PKEY -p eosio
cleos create account eosio eosio.token $PKEY $PKEY -p eosio

cleos set contract eosio.token $EOS_BASE_PATH/build/contracts/eosio.token/ -p eosio.token
cleos push action eosio.token create '[ "eosio", "1000000000.0000 SYS"]' -p eosio.token
cleos push action eosio.token issue '[ "eosio", "1000000000.0000 SYS", "init" ]' -p eosio

cleos set contract eosio $EOS_BASE_PATH/build/contracts/eosio.system/ -p eosio

# Mimics mainnet on 64gb RAM
cleos push action eosio setram '{"max_ram_size":"64599818083"}' -p eosio
