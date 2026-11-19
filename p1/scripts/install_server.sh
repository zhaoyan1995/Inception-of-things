#!/user/bin/env bash

set -euo pipefail

SERVER_IP="192.168.56.110"

echo "Installing K3S Server on $SERVER_IP..."

curl -sfL https://get.k3s.io/ | sh -s - server --node-ip $SERVER_IP

TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"

until test -s "$TOKEN_FILE"; do
    sleep 2
done

echo "K3s Server token is ready".



