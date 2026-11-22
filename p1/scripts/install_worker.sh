#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="192.168.56.110"

WORKER_IP="192.168.56.111"

: "${K3S_TOKEN:?K3S_TOKEN is required}"

K3S_URL="https://${SERVER_IP}:6443"

echo "Preparing K3s Agent on $WORKER_IP..."

curl -sfL https://get.k3s.io/ | \
  K3S_URL="$K3S_URL" \
  K3S_TOKEN="$K3S_TOKEN" \
  sh -s - agent --node-ip "$WORKER_IP"




