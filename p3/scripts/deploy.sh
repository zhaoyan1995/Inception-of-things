#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== IoT P3: Deploying Kubernetes infrastructure ==="

# 1. Check dependencies

echo "Checking dependencies..."

for cmd in docker k3d kubectl jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running or permission is denied." >&2
    exit 1
fi

# 2. Create K3d cluster

echo "Checking K3d cluster..."

if ! CLUSTERS_JSON=$(k3d cluster list -o json); then
    echo "Error: Failed to list K3d clusters." >&2
    exit 1
fi

if jq -e 'any(.[]; .name == "iot")' >/dev/null <<< "$CLUSTERS_JSON"; then
    echo "Cluster iot already exists."
else
    echo "Creating cluster iot..."
    k3d cluster create iot
fi

# 3. Create namespaces

echo "Selecting K3d context..."

kubectl config use-context k3d-iot

echo "Creating namespaces..."

kubectl create namespace argocd \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl create namespace dev \
    --dry-run=client -o yaml | kubectl apply -f -


# 4. Install Argo CD

echo "Checking Argo CD installation..."

ARGOCD_VERSION="v3.6.3"

if ! kubectl get deployment argocd-server -n argocd >/dev/null 2>&1; then
    echo "Installing Argo CD ${ARGOCD_VERSION}..."

    kubectl apply \
        --server-side \
        -n argocd \
        -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
else
    echo "Argo CD is already installed."
fi

# 5. Waiting for Argo CD 

echo "Waiting for Argo CD..."

kubectl rollout status deployment/argocd-server \
    -n argocd \
    --timeout=300s

kubectl rollout status deployment/argocd-repo-server \
    -n argocd \
    --timeout=300s

kubectl rollout status statefulset/argocd-application-controller \
    -n argocd \
    --timeout=300s

echo "Waiting for Application CRD..."

kubectl wait \
    --for=condition=Established \
    crd/applications.argoproj.io \
    --timeout=120s

# 6. Deploy Application

echo "Deploying Argo CD Application..."

kubectl apply -f "$SCRIPT_DIR/../confs/application.yaml"

# 7. Wait for Application

echo "Waiting for playground Deployment..."

for i in {1..60}; do
    if kubectl get deployment wil-playground -n dev >/dev/null 2>&1; then
        echo "Playground Deployment found."
        break
    fi

    sleep 5
done

if ! kubectl get deployment wil-playground -n dev >/dev/null 2>&1; then
    echo "Error: Playground Deployment was not created." >&2
    exit 1
fi

echo "Waiting for playground to be ready..."

kubectl rollout status deployment/wil-playground \
    -n dev \
    --timeout=600s

# 8. Verify deployment

echo "Waiting for Argo CD Application to become Synced and Healthy..."

for i in {1..60}; do
    SYNC_STATUS=$(kubectl get application playground -n argocd \
        -o jsonpath='{.status.sync.status}')

    HEALTH_STATUS=$(kubectl get application playground -n argocd \
        -o jsonpath='{.status.health.status}')

    if [[ "$SYNC_STATUS" == "Synced" && "$HEALTH_STATUS" == "Healthy" ]]; then
        echo "Argo CD Application is Synced and Healthy."
        break
    fi

    echo "Waiting... Sync=$SYNC_STATUS, Health=$HEALTH_STATUS"
    sleep 5
done

# Check final status

if [[ "$SYNC_STATUS" != "Synced" || "$HEALTH_STATUS" != "Healthy" ]]; then
    echo "Error: Argo CD Application is not ready." >&2
    exit 1
fi

echo "=== Kubernetes Nodes ==="
kubectl get nodes

echo "=== Argo CD Application ==="
kubectl get applications -n argocd

echo "=== Playground ==="
kubectl get deployments,pods,services -n dev

echo "=== Deployment completed successfully ==="
