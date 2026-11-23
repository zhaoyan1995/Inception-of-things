#!/usr/bin/env bash

set -euo pipefail

echo "Waiting for Kubernetes API..."

for i in {1..60}; do
    if k3s kubectl get nodes >/dev/null 2>&1; then
        echo "Kubernetes API is ready."
        break
    fi
    sleep 2
done

if ! k3s kubectl get nodes >/dev/null 2>&1; then
    echo "Error: Kubernetes API is not ready." >&2
    exit 1
fi

echo "Deploying ConfigMaps..."

k3s kubectl apply -f /vagrant/confs/app1-configmap.yaml
k3s kubectl apply -f /vagrant/confs/app2-configmap.yaml
k3s kubectl apply -f /vagrant/confs/app3-configmap.yaml

k3s kubectl apply -f /vagrant/confs/app1-deployment.yaml
k3s kubectl apply -f /vagrant/confs/app2-deployment.yaml
k3s kubectl apply -f /vagrant/confs/app3-deployment.yaml

k3s kubectl apply -f /vagrant/confs/app1-service.yaml
k3s kubectl apply -f /vagrant/confs/app2-service.yaml
k3s kubectl apply -f /vagrant/confs/app3-service.yaml


k3s kubectl apply -f /vagrant/confs/default-ingress.yaml
k3s kubectl apply -f /vagrant/confs/ingress.yaml



