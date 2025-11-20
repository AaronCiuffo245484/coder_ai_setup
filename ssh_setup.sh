#!/usr/bin/env bash
set -e

echo "=== SSH Server Setup ==="
echo ""
echo "This script configures the SSH server on this coder.ai instance"
echo "so you can connect via reverse tunnel from your local machine."
echo ""

# Use sudo if not running as root
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# -----------------------------
# Install SSH server
# -----------------------------
echo "Installing OpenSSH server..."
$SUDO apt-get update -qq
$SUDO apt-get install -y openssh-server
echo "SSH server installed"
echo ""

# -----------------------------
# Configure SSH for root login
# -----------------------------
echo "Configuring SSH to allow root login..."
$SUDO sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
$SUDO sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
$SUDO sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# -----------------------------
# Fix SSH host key permissions
# -----------------------------
echo "Setting correct permissions on SSH host keys..."
$SUDO chmod 600 /etc/ssh/ssh_host_*_key
$SUDO chmod 644 /etc/ssh/ssh_host_*_key.pub

# -----------------------------
# Start SSH service
# -----------------------------
echo "Starting SSH service..."
$SUDO service ssh start

# Verify it's running
if $SUDO service ssh status | grep -q "is running"; then
  echo "SSH service is running successfully"
else
  echo "WARNING: SSH service may not have started correctly"
fi
echo ""

# -----------------------------
# Copy authorized_keys if it exists
# -----------------------------
PERSISTENT_DIR="$PWD"
AUTHORIZED_KEYS="$PERSISTENT_DIR/ssh/authorized_keys"

if [[ -f "$AUTHORIZED_KEYS" ]]; then
  echo "Found authorized_keys in persistent storage"
  echo "Copying to ~/.ssh/authorized_keys for key-based authentication..."
  
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  
  cp "$AUTHORIZED_KEYS" ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  
  echo "Authorized keys installed"
  echo "You should be able to connect without a password"
  echo ""
else
  echo "No authorized_keys found at $AUTHORIZED_KEYS"
  echo "To enable passwordless login:"
  echo "  1. Copy your public key to $AUTHORIZED_KEYS"
  echo "  2. Run this script again"
  echo ""
fi

# -----------------------------
# Create coder.ai environment compatibility file
# -----------------------------
echo "Creating coder.ai environment compatibility file..."

# Create environment file in persistent storage
cat > "$PERSISTENT_DIR/.coder_env" <<'ENVEOF'
# Environment variables for coder.ai compatibility
# These match the environment provided by the coder.ai web terminal
export PIP_BREAK_SYSTEM_PACKAGES=1
export PIP_DEFAULT_TIMEOUT=100
export PIP_DISABLE_PIP_VERSION_CHECK=1
export TF_PYTHON_VERSION=3.12
export PYTHONIOENCODING=utf-8
ENVEOF

# Add sourcing to .bashrc if not already there
if ! grep -q "source $PERSISTENT_DIR/.coder_env" ~/.bashrc 2>/dev/null; then
  echo "" >> ~/.bashrc
  echo "# Source coder.ai environment variables" >> ~/.bashrc
  echo "if [ -f $PERSISTENT_DIR/.coder_env ]; then" >> ~/.bashrc
  echo "    source $PERSISTENT_DIR/.coder_env" >> ~/.bashrc
  echo "fi" >> ~/.bashrc
  echo "Environment variables will be sourced from .bashrc"
else
  echo "Environment variables already configured in .bashrc"
fi

# Source it now for current session
source "$PERSISTENT_DIR/.coder_env"

echo "Coder.ai environment configured"
echo ""

# -----------------------------
# Set root password
# -----------------------------
if [[ -f "$AUTHORIZED_KEYS" ]]; then
  echo "Authorized keys are configured for passwordless login."
  read -p "Do you still want to set a root password? (y/n): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Setting root password..."
    $SUDO passwd root
    echo ""
  else
    echo "Skipping password setup"
    echo ""
  fi
else
  echo "No authorized keys found. You need to set a password for root login."
  echo "This password will be used when connecting via the tunnel."
  echo ""
  $SUDO passwd root
  echo ""
fi

# -----------------------------
# Test local SSH
# -----------------------------
echo "Testing local SSH connection..."
if timeout 3 ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@localhost echo "success" 2>/dev/null | grep -q "success"; then
  echo "SSH is configured correctly"
else
  echo "Note: SSH is running but key-based auth may not be configured"
  echo "Password authentication should work"
fi
echo ""

# -----------------------------
# Summary
# -----------------------------
cat <<'SUMMARY'
========================================
SSH SERVER SETUP COMPLETE
========================================

Your SSH server is now running and configured.

Next steps:
  1. Run the tunnel script to create a reverse tunnel:
     bash tunnel.sh

  2. The tunnel script will give you instructions for
     connecting from your laptop.

========================================
SUMMARY