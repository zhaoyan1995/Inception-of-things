#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="192.168.56.110"

echo "Installing K3s Server on $SERVER_IP..."

curl -sfL https://get.k3s.io | \
    sh -s - server --node-ip "$SERVER_IP"