#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="192.168.56.110"

echo "Installing K3S Server on $SERVER_IP..."

if ! command -v k3s >/dev/null 2>&1; then
    echo "K3s not installed. Installing..."

    curl -sfL https://get.k3s.io | \
        sh -s - server --node-ip "$SERVER_IP"
else
    echo "K3s is already installed."
fi

if ! systemctl is-active --quiet k3s; then
    echo "Starting K3s service..."
    systemctl start k3s
fi

TOKEN_FILE="/var/lib/rancher/k3s/server/node-token"

for i in {1..60}; do
    if [[ -s "$TOKEN_FILE" ]]; then
        echo "K3s token is ready."
        break
    fi
    sleep 2
done

if [[ ! -s "$TOKEN_FILE" ]]; then
    echo "Error: K3s token was not generated." >&2
    exit 1
fi

SHARED_DIR="/vagrant/.secrets"
SHARED_TOKEN="${SHARED_DIR}/node-token"

mkdir -p "$SHARED_DIR"

install -m 600 "$TOKEN_FILE" "$SHARED_TOKEN"

echo "Token is ready for Worker."
