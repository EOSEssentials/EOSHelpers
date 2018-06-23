#!/bin/bash

# ------------------------------------------
# This script helps a quicker dev process when writing smart contracts.
# to use simply navigate to the directory your smart contract is in, and type
# comptract.sh <ACCOUNT NAME> <Contract Name Which Matches Folder Name>
# ------------------------------------------

# Example:
# ------------------------------------------
# If your contract is called 'hello', name your directory 'hello' as well.
# cd ~/hello
# comptract.sh someaccount hello
# ------------------------------------------

# SET UP:
# ------------------------------------------
# cd ~
# mkdir scripts
# cd scripts
# nano comptract.sh
# --- PASTE IN THIS SCRIPT ---
# save ( ctrl+x, y, enter )
# chmod +x comptract.sh
# --- Add      export PATH=$PATH:~/scripts      to the end of your `~/.profile` ( nano ~/.profile )
# export PATH=$PATH:~/scripts
# ------------------------------------------



if [[ $# -ne 2 ]]; then
    echo "USAGE: comptract.sh <ACCOUNT NAME> <Contract Name> from within the directory"
    exit 1
fi

ACCOUNT=$1
CONTRACT=$2

eosiocpp -o ${CONTRACT}.wast ${CONTRACT}.cpp &&
eosiocpp -g ${CONTRACT}.abi ${CONTRACT}.cpp &&
cleos set contract ${ACCOUNT} ../${CONTRACT}