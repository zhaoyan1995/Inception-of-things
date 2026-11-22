#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="192.168.56.110"

WORKER_IP="192.168.56.111"

K3S_URL="https://${SERVER_IP}:6443"

TOKEN_FILE="/vagrant/.secrets/node-token"
for i in {1..60}; do
    if [[ -s "$TOKEN_FILE" ]]; then
        echo "Token file is ready."
        break
    fi
    sleep 2
done

if [[ ! -s "$TOKEN_FILE" ]]; then
    echo "Error: Token file not found." >&2
    exit 1
fi
K3S_TOKEN="$(< "$TOKEN_FILE")"

echo "K3s Agent installed successfully."
: "${K3S_TOKEN:?K3S_TOKEN is required}"

K3S_URL="https://${SERVER_IP}:6443"

echo "Preparing K3s Agent on $WORKER_IP..."

curl -sfL https://get.k3s.io/ | \
  K3S_URL="$K3S_URL" \
  K3S_TOKEN="$K3S_TOKEN" \
  sh -s - agent --node-ip "$WORKER_IP"

rm -f "$TOKEN_FILE"



