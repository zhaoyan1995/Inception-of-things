#!/usr/bin/env bash

set -euo pipefail

echo "=== IoT P3: Installing dependencies ==="

# 1. Check operating system

source /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
    echo "Error: This script requires Ubuntu." >&2
    exit 1
fi

# 2. Install basic packages

echo "Installing basic packages..."

sudo apt-get update

sudo apt-get install -y \
    curl \
    ca-certificates \
    git \
    gnupg

# 3. Install Docker

if ! command -v docker >/dev/null 2>&1; then
    echo "Installing Docker..."

    sudo apt-get install -y docker.io
else
    echo "Docker is already installed."
fi

# Check if docker run normally
echo "Checking Docker service..."

sudo systemctl enable --now docker

if ! sudo docker info >/dev/null 2>&1; then
    echo "Error: Docker daemon is not available." >&2
    exit 1
fi

echo "Docker is ready."

#Add current user to Docker group
if ! id -nG "$USER" | grep -qw docker; then
    echo "Adding $USER to Docker group..."
    sudo usermod -aG docker "$USER"
    echo "Please log out and log back in to activate Docker permissions."
fi

# 4. Install K3d

if ! command -v k3d >/dev/null 2>&1; then
    echo "Installing K3d..."
	
    curl -fsSL \
        https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \
        -o /tmp/install-k3d.sh

    TAG=v5.9.0 bash /tmp/install-k3d.sh

else
    echo "K3d is already installed."
fi

# 5. Install kubectl

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Installing kubectl..."

    KUBECTL_VERSION="v1.35.5"
    KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64"

    curl -fsSL \
        "${KUBECTL_URL}/kubectl" \
        -o /tmp/kubectl

    curl -fsSL \
        "${KUBECTL_URL}/kubectl.sha256" \
        -o /tmp/kubectl.sha256

    echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check

    sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

else
    echo "kubectl is already installed."
fi

# 6. Verify installation

echo "=== Verifying installations ==="

docker --version
k3d version
kubectl version --client

echo "=== Installation completed successfully ==="
