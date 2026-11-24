# Part 1 — K3s and Vagrant

## 1. Overview

Part 1 of the Inception-of-Things project focuses on creating
a lightweight Kubernetes cluster using K3s, Vagrant, and VirtualBox.

The infrastructure consists of two virtual machines:

- One K3s Server (Control Plane)
- One K3s Worker (Agent)

Vagrant automatically creates and configures both virtual machines.
Shell provisioning scripts install K3s and connect the Worker to
the Server.

## 2. Infrastructure

### Virtual Machines

| Setting | Server | Worker |
|---------|--------|--------|
| VM Name | helinS | helinSW |
| Hostname | helinS | helinSW |
| IP Address | 192.168.56.110 | 192.168.56.111 |
| Operating System | Ubuntu 24.04 | Ubuntu 24.04 |
| Memory | 1024 MB | 1024 MB |
| CPU | 1 | 1 |
| K3s Role | Server | Agent |

### Architecture

```text
                 Host Machine (Linux)
                         |
                  VirtualBox
                         |
             +-----------+-----------+
             |                       |
             v                       v
      +-------------+         +-------------+
      | K3s Server  |         | K3s Worker  |
      |   helinS    |         |   helinSW   |
      |             |         |             |
      |192.168.56.110|        |192.168.56.111|
      +-------------+         +-------------+
             |                       |
             +----------+------------+
                        |
                 K3s Cluster
```

The Server manages the Kubernetes cluster.

The Worker joins the cluster and can run Kubernetes workloads.

Both machines communicate through a VirtualBox private network.

## 3. Requirements

The following tools must be installed on the host machine:

- Git
- Vagrant
- VirtualBox

Hardware requirements:

- x86_64 architecture
- Hardware virtualization support
- Sufficient available RAM and disk space

Tested environment:

- Vagrant 2.4.9
- VirtualBox 7.2.22
- Ubuntu 24.04 guest systems

## 4. Project Structure

```text
p1/
├── Vagrantfile
├── README.md
└── scripts/
    ├── install_server.sh
    └── install_worker.sh
```

### Vagrantfile

The `Vagrantfile` defines:

- The two virtual machines.
- Their hostnames and private IP addresses.
- CPU and memory allocation.
- Shell provisioning scripts.

### install_server.sh

This script:

1. Installs K3s Server.
2. Configures the Server IP.
3. Starts the K3s service.
4. Waits for the Kubernetes API.
5. Obtains the K3s node token.
6. Copies the token temporarily into a shared directory.

### install_worker.sh

This script:

1. Waits for the shared token.
2. Configures the K3s Server URL.
3. Installs the K3s Agent.
4. Connects the Worker to the Server.
5. Removes the temporary shared token.

The node token is sensitive and must not be committed to Git.

## 5. Installation

### Start the Virtual Machines

From the `p1/` directory:

```bash
vagrant up --provider=virtualbox
```

Vagrant automatically:

1. Creates both Ubuntu virtual machines.
2. Configures their network interfaces.
3. Installs K3s Server.
4. Generates the Server node token.
5. Installs K3s Agent on the Worker.
6. Connects the Worker to the cluster.

### Check VM Status

```bash
vagrant status
```

Expected:

```text
helinS     running (virtualbox)
helinSW    running (virtualbox)
```

### Connect to the Server

```bash
vagrant ssh helinS
```

### Connect to the Worker

```bash
vagrant ssh helinSW
```

## 6. Verification

### Check Kubernetes Nodes

Connect to the Server:

```bash
vagrant ssh helinS
```

Then execute:

```bash
sudo k3s kubectl get nodes -o wide
```

Expected:

```text
NAME      STATUS   ROLES           INTERNAL-IP
helins    Ready    control-plane   192.168.56.110
helinsw   Ready    <none>          192.168.56.111
```

Both nodes must be in the `Ready` state.

### Check Network Configuration

On the Server:

```bash
ip -br addr
```

Expected private IP:

```text
192.168.56.110
```

On the Worker:

```bash
ip -br addr
```

Expected private IP:

```text
192.168.56.111
```

### Test Network Connectivity

From the Server:

```bash
ping -c 3 192.168.56.111
```

From the Worker:

```bash
ping -c 3 192.168.56.110
```

Both machines should be able to communicate.

### Check K3s Services

On the Server:

```bash
sudo systemctl status k3s
```

On the Worker:

```bash
sudo systemctl status k3s-agent
```

Both services should be active.

## 7. Token Management

K3s uses a node token to authenticate the Worker when joining
the cluster.

The Server stores its token at:

```text
/var/lib/rancher/k3s/server/node-token
```

During provisioning, the token is temporarily copied into:

```text
/vagrant/.secrets/node-token
```

The `/vagrant` directory is shared between the host and guest VMs.

The Worker reads the token and uses it to connect to:

```text
https://192.168.56.110:6443
```

After installation, the temporary shared token is removed.

The original token remains on the Server.

IMPORTANT:

- Never commit the token to GitHub.
- Keep `.secrets/` in `.gitignore`.
- Do not print the token in terminal logs.
- The shared-folder approach is intended for this local lab environment.

## 8. Common Operations

The following commands must be executed on the host machine
from the `p1/` directory.

### Start Both VMs

```bash
vagrant up
```

### Stop Both VMs

```bash
vagrant halt
```

### Restart Both VMs

```bash
vagrant reload
```

### Re-run Provisioning

```bash
vagrant provision
```

### Provision Only the Server

```bash
vagrant provision helinS
```

### Provision Only the Worker

```bash
vagrant provision helinSW
```

### Stop Only the Worker

```bash
vagrant halt helinSW
```

### Delete Both VMs

```bash
vagrant destroy
```

WARNING: This removes the virtual machines and their internal data.

The project files stored on the host are preserved.

## 9. Troubleshooting

### VM Does Not Start

Check the current VM state:

```bash
vagrant status
```

Check VirtualBox machines:

```bash
VBoxManage list vms
```

### Worker Does Not Join the Cluster

On the Server:

```bash
sudo k3s kubectl get nodes
```

On the Worker:

```bash
sudo systemctl status k3s-agent
```

Check whether the Worker can reach the Server:

```bash
ping -c 3 192.168.56.110
```

### Check K3s Logs

Server:

```bash
sudo journalctl -u k3s -n 50 --no-pager
```

Worker:

```bash
sudo journalctl -u k3s-agent -n 50 --no-pager
```

### No Space Left on Device

Vagrant boxes and VirtualBox virtual machines require
several gigabytes of disk space.

Check available space:

```bash
df -h
```

On school computers with limited home storage, Vagrant
and VirtualBox data may need to be stored on a larger
filesystem.

## 10. Notes

- The Server and Worker communicate through a private network.
- The Server uses TCP port 6443 for the Kubernetes API.
- The Worker joins the cluster using the Server URL and node token.
- K3s uses containerd as its container runtime.
- Pod networking is managed by K3s.
- Provisioning scripts are executed inside the VMs.
- The `/vagrant` directory provides a shared folder between the host and guests.
- P1 and P2 use the same Server IP address and should not run simultaneously on the same host.

## 11. Cleanup

Stop both VMs without deleting their data:

```bash
vagrant halt
```

Completely remove both VMs:

```bash
vagrant destroy
```

Recreate the environment:

```bash
vagrant up --provider=virtualbox
```

Vagrant will automatically provision the K3s cluster.

