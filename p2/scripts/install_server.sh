#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="192.168.56.110"

echo "Installing K3s Server on $SERVER_IP..."

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

echo "K3s Server installation step completed." 