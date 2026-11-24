#!/usr/bin/env bash

set -euo pipefail

VAGRANT_DIR="/goinfre/$USER/vagrant"
VIRTUALBOX_DIR="/goinfre/$USER/VirtualBox VMs"

echo "Configuring Vagrant environment..."

# Check Goinfre mount
if ! mountpoint -q /goinfre; then
    echo "Error: /goinfre is not mounted."
    exit 1
fi

# Create storage directories
mkdir -p "$VAGRANT_DIR"
mkdir -p "$VIRTUALBOX_DIR"

# Configure Vagrant storage
export VAGRANT_HOME="$VAGRANT_DIR"

# Configure VirtualBox default machine folder
if ! command -v VBoxManage >/dev/null 2>&1; then
    echo "Error: VBoxManage is not installed or not in PATH."
    exit 1
fi

VBoxManage setproperty machinefolder "$VIRTUALBOX_DIR"

# Configure Bash
BASH_CONFIG="$HOME/.bashrc"
BASH_LINE='export VAGRANT_HOME="/goinfre/$USER/vagrant"'

if ! grep -Fxq "$BASH_LINE" "$BASH_CONFIG" 2>/dev/null; then
    echo "$BASH_LINE" >> "$BASH_CONFIG"
fi

# Configure Zsh
ZSH_CONFIG="$HOME/.zshrc"
ZSH_LINE='export VAGRANT_HOME="/goinfre/$USER/vagrant"'

if ! grep -Fxq "$ZSH_LINE" "$ZSH_CONFIG" 2>/dev/null; then
    echo "$ZSH_LINE" >> "$ZSH_CONFIG"
fi

# Configure Fish
FISH_DIR="$HOME/.config/fish/conf.d"
FISH_CONFIG="$FISH_DIR/vagrant.fish"

mkdir -p "$FISH_DIR"

cat > "$FISH_CONFIG" <<'EOF'
set -gx VAGRANT_HOME "/goinfre/$USER/vagrant"
EOF

# Check inaccessible VirtualBox VMs

cleanup_inaccessible_vms() {
    echo ""
    echo "Checking inaccessible VirtualBox VMs..."

    local line
    local uuid
    local answer

    while IFS= read -r line; do
        if [[ "$line" == *"<inaccessible>"* ]]; then
            uuid=$(echo "$line" | grep -oE '\{[^}]+\}' | tr -d '{}')

            echo ""
            echo "Found inaccessible VM: $uuid"

            read -r -p "Remove its registration only? [y/N] " answer </dev/tty

            if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                if VBoxManage unregistervm "$uuid"; then
                    echo "Registration removed: $uuid"
                else
                    echo "Error: Failed to unregister $uuid"
                fi
            else
                echo "Skipped: $uuid"
            fi
        fi
    done < <(VBoxManage list vms)
}

cleanup_inaccessible_vms

echo ""
echo "Vagrant environment configured successfully!"
echo "VAGRANT_HOME: $VAGRANT_HOME"
echo "VirtualBox VM directory: $VIRTUALBOX_DIR"
echo "Supported shells: Bash, Zsh, Fish"
echo "Please restart your terminal or reload your shell configuration."

