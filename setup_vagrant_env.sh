#!/usr/bin/env bash

set -euo pipefail

VAGRANT_DIR="/goinfre/$USER/vagrant"

echo "Configuring Vagrant environment..."

# Check Goinfre mount
if ! mountpoint -q /goinfre; then
    echo "Error: /goinfre is not mounted."
    exit 1
fi

# Create Vagrant storage directory
mkdir -p "$VAGRANT_DIR"

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

echo "VAGRANT_HOME configured successfully!"
echo "Location: $VAGRANT_DIR"
echo "Supported shells: Bash, Zsh, Fish"
echo "Please restart your terminal or reload your shell configuration."

