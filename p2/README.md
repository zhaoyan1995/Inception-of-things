# Part 2 — K3s and Three Web Applications

## 1. Overview

Part 2 of the Inception-of-Things project demonstrates how to deploy
and manage multiple web applications using Kubernetes (K3s).

The infrastructure consists of:

- One Ubuntu virtual machine managed by Vagrant and VirtualBox.
- One K3s Server.
- Three web applications running in Nginx containers.
- Kubernetes Deployments, Services, and ConfigMaps.
- Traefik as the Ingress Controller.

The objective is to route HTTP requests to different applications
based on the requested hostname.

| Hostname | Application | Replicas |
|----------|-------------|----------|
| app1.com | App 1 | 1 |
| app2.com | App 2 | 3 |
| Any other hostname | App 3 | 1 |

## 2. Infrastructure

### Virtual Machine

| Setting | Value |
|---------|-------|
| Operating System | Ubuntu 24.04 |
| Vagrant Box | bento/ubuntu-24.04 |
| Virtualization | VirtualBox |
| Hostname | helinS |
| IP Address | 192.168.56.110 |
| RAM | 1024 MB |
| CPU | 1 |

### Architecture

HTTP requests follow this path:

```text
                HTTP Request
                     |
                     v
             Traefik Ingress
                     |
          +----------+----------+
          |          |          |
          v          v          v
     app1-service app2-service app3-service
          |          |          |
          v          v          v
        App 1      App 2      App 3
        1 Pod      3 Pods     1 Pod
```

### Kubernetes Components

**Deployment**

Manages application Pods and maintains the desired number of replicas.

**Pod**

The smallest deployable unit in Kubernetes.
Each application Pod runs an Nginx container.

**Service**

Provides a stable network endpoint for accessing application Pods.

Services use label selectors to identify their corresponding Pods.

**ConfigMap**

Stores the HTML content displayed by each application.

**Volume / VolumeMount**

Mounts the HTML files from ConfigMaps into the Nginx containers.

**Ingress**

Defines HTTP routing rules based on hostnames.

**Traefik**

The Ingress Controller responsible for processing HTTP requests
and forwarding them to the appropriate Services.

## 3. Requirements

The following tools must be installed on the host machine:

- VirtualBox
- Vagrant
- Git

Hardware requirements:

- x86_64 architecture
- Hardware virtualization enabled
- Sufficient free RAM and disk space

The project has been tested using:

- Vagrant 2.4.9
- VirtualBox 7.2.22
- Ubuntu 24.04 as the guest operating system

## 4. Project Structure

```text
p2/
├── Vagrantfile
├── README.md
├── scripts/
│   ├── install_server.sh
│   └── deploy_apps.sh
└── confs/
    ├── app1-configmap.yaml
    ├── app1-deployment.yaml
    ├── app1-service.yaml
    ├── app2-configmap.yaml
    ├── app2-deployment.yaml
    ├── app2-service.yaml
    ├── app3-configmap.yaml
    ├── app3-deployment.yaml
    ├── app3-service.yaml
    ├── ingress.yaml
    └── default-ingress.yaml
```

### Scripts

`install_server.sh`

- Installs K3s Server.
- Configures the Kubernetes node IP.
- Starts the K3s service if necessary.
- Avoids reinstalling K3s when it is already installed.

`deploy_apps.sh`

- Waits for the Kubernetes API to become available.
- Deploys ConfigMaps.
- Deploys application Deployments.
- Creates Services.
- Configures Ingress routing.

Both scripts are executed automatically inside the VM by Vagrant.

## 5. Installation

### Start the Virtual Machine

From the `p2/` directory:

```bash
vagrant up --provider=virtualbox
```

Vagrant automatically:

1. Creates the Ubuntu virtual machine.
2. Configures the private network.
3. Installs K3s Server.
4. Waits for the Kubernetes API.
5. Deploys all three applications.
6. Configures Services and Ingress resources.

### Check VM Status

```bash
vagrant status
```

Expected result:

```text
helinS    running (virtualbox)
```

### Connect to the VM

```bash
vagrant ssh helinS
```

## 6. Kubernetes Verification

The following commands are executed inside the VM.

### Check the Kubernetes Node

```bash
sudo k3s kubectl get nodes -o wide
```

Expected:

- Node name: `helins`
- Status: `Ready`
- Internal IP: `192.168.56.110`

### Check Deployments

```bash
sudo k3s kubectl get deployments
```

Expected:

```text
NAME   READY
app1   1/1
app2   3/3
app3   1/1
```

### Check Pods

```bash
sudo k3s kubectl get pods -o wide
```

Expected:

- 1 Pod for App 1
- 3 Pods for App 2
- 1 Pod for App 3

All Pods should have the `Running` status and be ready.

### Check Services

```bash
sudo k3s kubectl get services
```

Expected Services:

```text
app1-service
app2-service
app3-service
```

### Check Ingress

```bash
sudo k3s kubectl get ingress
```

Expected Ingress resources:

```text
apps-ingress
default-ingress
```

`apps-ingress` handles requests for `app1.com` and `app2.com`.

`default-ingress` handles requests that do not match these hostnames.

## 7. HTTP Routing Tests

The following commands can be executed inside the VM.

### App 1

```bash
curl -H "Host: app1.com" http://192.168.56.110
```

Expected response:

```html
<h1>Hello from App 1</h1>
```

### App 2

```bash
curl -H "Host: app2.com" http://192.168.56.110
```

Expected response:

```html
<h1>Hello from App 2</h1>
```

### Default Application (App 3)

```bash
curl -H "Host: unknown.com" http://192.168.56.110
```

Expected response:

```html
<h1>Hello from App 3</h1>
```

### Why Use the Host Header?

All applications share the same external IP address:

`192.168.56.110`

Traefik examines the HTTP `Host` header to determine which
application should receive the request.

Using `curl -H` allows us to test hostname-based routing
without modifying DNS configuration.

## 8. Common Operations

The following Vagrant commands are executed on the host machine
from the `p2/` directory.

### Start the VM

```bash
vagrant up
```

### Stop the VM

```bash
vagrant halt
```

### Restart the VM

```bash
vagrant reload
```

### Run Provisioning Scripts Again

```bash
vagrant provision
```

This reruns the K3s installation check and applies all Kubernetes manifests.

The scripts are designed to support repeated execution.

### Restart and Run Provisioning

```bash
vagrant reload --provision
```

### Delete the VM

```bash
vagrant destroy helinS
```

WARNING: This deletes the virtual machine and its internal data.

The project files stored on the host machine are preserved.

## 9. Updating Kubernetes Resources

After modifying a YAML file, apply it again inside the VM.

Example:

```bash
sudo k3s kubectl apply -f /vagrant/confs/app1-deployment.yaml
```

Alternatively, rerun all provisioning scripts from the host:

```bash
vagrant provision
```

### Check Deployment Updates

```bash
sudo k3s kubectl rollout status deployment/app1
```

### Inspect a Pod

```bash
sudo k3s kubectl describe pod <pod-name>
```

### View Pod Logs

```bash
sudo k3s kubectl logs <pod-name>
```

### Inspect System Components

```bash
sudo k3s kubectl get pods -n kube-system
```

This includes components such as Traefik and CoreDNS.

## 10. Notes

- App 2 uses three replicas to demonstrate Kubernetes replica management.
- All three applications run on a single K3s node.
- The applications use separate ConfigMaps to provide different HTML content.
- ClusterIP addresses are assigned automatically by Kubernetes.
- Pod IP addresses may change when Pods are recreated.
- Services provide stable access to application Pods.
- Traefik routes incoming HTTP requests according to Ingress rules.
- The default backend is configured using a separate Ingress resource.
- P1 and P2 use the same private IP address and should not run simultaneously on the same host.

## 11. Cleanup

To stop the environment without deleting it:

```bash
vagrant halt
```

To completely remove the VM:

```bash
vagrant destroy helinS
```

To recreate the environment:

```bash
vagrant up --provider=virtualbox
```

All Kubernetes applications will be deployed automatically.

