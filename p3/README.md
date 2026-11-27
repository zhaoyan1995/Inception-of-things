# Part 3 - K3d and Argo CD

## Overview

This part of the Inception-of-Things project demonstrates GitOps using K3d, Kubernetes, and Argo CD.

The goal is to automatically deploy and update an application from a public GitHub repository.

## Architecture

```text
GitHub Repository
       |
       v
     Argo CD
       |
       v
  K3d / Kubernetes
       |
       v
  dev Namespace
       |
       v
 wil42/playground
```

- **K3d** runs a lightweight K3s cluster inside Docker containers.
- **Argo CD** monitors GitHub and automatically synchronizes Kubernetes resources.
- **GitHub** stores the desired application configuration.

## Project Structure

```text
p3/
├── confs/
│   └── application.yaml
├── scripts/
│   ├── install.sh
│   └── deploy.sh
└── README.md
```

- `install.sh`: Installs Docker, K3d, kubectl, and required tools.
- `deploy.sh`: Creates the cluster, installs Argo CD, and deploys the application.
- `application.yaml`: Configures the GitHub repository monitored by Argo CD.

## Installation

Run inside an Ubuntu 24.04 virtual machine.

### 1. Install dependencies

```bash
./scripts/install.sh
```

If Docker group permissions were changed, log out and log back in before continuing.

### 2. Deploy the infrastructure

```bash
./scripts/deploy.sh
```

## Verification

Check the Kubernetes cluster:

```bash
kubectl get nodes
kubectl get namespaces
```

Check Argo CD:

```bash
kubectl get applications -n argocd
```

Expected status:

```text
playground   Synced   Healthy
```

Check the application:

```bash
kubectl get pods -n dev
```

## Access the Application

Forward the application port:

```bash
kubectl port-forward -n dev svc/wil-playground-service 8888:8888
```

In another terminal:

```bash
curl http://localhost:8888/
```

Expected response:

```json
{"status":"ok","message":"v2"}
```

## GitOps

Application manifests are stored in a separate public repository:

https://github.com/zhaoyan1995/helin_iot-gitops

To update the application, change the image version in `deployment.yaml`:

```yaml
image: wil42/playground:v1
```

to:

```yaml
image: wil42/playground:v2
```

Commit and push the changes:

```bash
git add deployment.yaml
git commit -m "Upgrade playground to v2"
git push
```

Argo CD automatically detects the change and updates the Kubernetes Deployment.

No manual `kubectl apply` is required.
