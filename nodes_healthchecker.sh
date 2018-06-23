#!/bin/bash

# This script health checks nodes based on the results of https://validate.eosnation.io/report-endpoints.txt
# If ECHO_ONLY is set to false it will replace the /etc/nginx/sites-available/default server block with a
# reverse nginx proxy that load balances across given nodes for both http and https.

# YOU MUST HAVE AN SSL CERT FOR THIS.

SERVER_NAME="nodes.get-scatter.com"
SSL_CERT="/etc/letsencrypt/live/nodes.get-scatter.com/fullchain.pem;"
SSL_KEY="/etc/letsencrypt/live/nodes.get-scatter.com/privkey.pem;"

ECHO_ONLY="yes"

SERVER_BLOCK_PATH="/etc/nginx/sites-available/default"
SERVER_BLOCK=''

function check_node(){
    RESULT=$(curl -H "Origin: $1://scattellet.com" -XGET "$1://$2/v1/chain/get_info" --verbose --max-time 1 --stderr -)
    RESULT=${RESULT#*="Host: $2"}
    RESULT=${RESULT//[[:space:]]/}

    # Rejecting cloudflare as they mask CORS
    if [[ ${RESULT} == *"Server:cloudflare"* ]]; then
        return 1
    fi

    # Must return 200 OK
    if [[ ${RESULT} != *"200OK"* ]]; then
        return 1
    fi

    # App don't accept multi CORS
    CORS_COUNT=$(echo "${RESULT}" | awk -F"Access-Control-Allow-Origin" '{print NF-1}')
    if [[ $CORS_COUNT != 1 ]]; then
        return 1
    fi

    # Mainnet chainId present
    if [[ ${RESULT} != *"aca376f206b8fc25a6ed44dbdc66547c36c6c33e3a119ffbeaef943642f0e906"* ]]; then
        return 1
    fi

    # 0 is true in bash. :facepalm:
    return 0
}

ENDPOINTS=$(curl -XGET https://validate.eosnation.io/report-endpoints.txt)

HTTP=$(echo $ENDPOINTS | grep -Po '(?<=(==== api_http ==== )).*(?= ==== api_https ====)')
HTTP=${HTTP// /,}
HTTP=${HTTP//,,/,}

HTTPS=$(echo $ENDPOINTS | grep -Po '(?<=(==== api_https ==== )).*(?= ==== bnet ====)')
HTTPS=${HTTPS// /,}
HTTPS=${HTTPS//,,/,}

HTTP_NODES=()
HTTPS_NODES=()

function parse_nodes(){
    IFS=',' list=($1)

    for((n=0;n<${#list[@]};n++)); do
      if (( $(($n % 2 )) == 1 )); then

        if [[ $2 == "http" ]]; then
            item=${list[$n]//http:\/\//}
        else
            item=${list[$n]//https:\/\//}
        fi

        # Removing endpoints with ports
        if [[ ${item} != *":"* ]];then

            # Removing non-cors nodes
            if check_node "$2" "$item"; then
                echo "$item has cors and chain id"
                if [[ $2 == "http" ]]; then
                    HTTP_NODES+=("$item")
                else
                    HTTPS_NODES+=("$item")
                fi
            fi

        fi
      fi
    done
}

parse_nodes "$HTTP" "http"
parse_nodes "$HTTPS" "https"

SERVER_BLOCK+=$'upstream nodes {'
for node in "${HTTP_NODES[@]}"; do
    SERVER_BLOCK+=$'\n'
    SERVER_BLOCK+="    server $node;"
done
SERVER_BLOCK+=$'\n}\n'
SERVER_BLOCK+=$'\n'

SERVER_BLOCK+=$'upstream ssl_nodes {'
for node in "${HTTPS_NODES[@]}"; do
    SERVER_BLOCK+=$'\n'
    SERVER_BLOCK+="    server $node:443;"
done
SERVER_BLOCK+=$'\n}\n'

SERVER_BLOCK_DEFAULTS="
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
"

SERVER_BLOCK+="
server {
  listen 80;

  location / {
    proxy_pass http://nodes;
$SERVER_BLOCK_DEFAULTS
  }
}

server {
  listen 443 ssl;
  server_name $SERVER_NAME;

  proxy_ssl_session_reuse on;
  ssl_certificate $SSL_CERT
  ssl_certificate_key $SSL_KEY
  ssl_verify_client off;

  location / {
    proxy_pass https://ssl_nodes;
$SERVER_BLOCK_DEFAULTS
  }
}"

if [[ $ECHO_ONLY == "yes" ]]; then
    echo "$SERVER_BLOCK"
else
    echo "$SERVER_BLOCK" >$SERVER_BLOCK_PATH
    service nginx restart
fi
