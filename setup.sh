#!/usr/bin/env bash
set -e

echo "=== Coder.ai Environment Setup ==="
echo ""

# Configuration - use current directory as persistent storage
PERSISTENT_DIR="$PWD"

echo "This script will use the following directory for persistent storage:"
echo "  $PERSISTENT_DIR"
echo ""
read -p "Is this correct? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Setup cancelled. Please cd to your persistent storage directory and run again."
  exit 1
fi

SSH_DIR="$PERSISTENT_DIR/ssh"
SSH_KEY="$SSH_DIR/id_ed25519"

# -----------------------------
# Create SSH directory structure
# -----------------------------
echo "Setting up SSH directory in persistent storage..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# -----------------------------
# Generate SSH key if needed
# -----------------------------
if [[ -f "$SSH_KEY" && -f "$SSH_KEY.pub" ]]; then
  echo "SSH key already exists at $SSH_KEY"
  echo ""
else
  echo "Generating new ed25519 SSH key..."
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "coder-workspace"
  chmod 600 "$SSH_KEY"
  chmod 644 "$SSH_KEY.pub"
  echo "SSH key generated successfully"
  echo ""
fi

# -----------------------------
# Test GitHub connectivity
# -----------------------------
echo "Testing GitHub connectivity..."
echo ""

GITHUB_PORT=22
GITHUB_HOST="github.com"

# Test port 22 with a short timeout
echo "Testing GitHub on port 22..."
if timeout 3 ssh -T -p 22 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "Port 22 is working"
  GITHUB_PORT=22
  GITHUB_HOST="github.com"
else
  # Port 22 failed, try port 443
  echo "Port 22 failed or timed out, testing port 443..."
  if timeout 3 ssh -T -p 443 -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$SSH_KEY" git@ssh.github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "Port 443 is working, using ssh.github.com:443"
    GITHUB_PORT=443
    GITHUB_HOST="ssh.github.com"
  else
    echo "WARNING: Neither port 22 nor 443 worked. Using port 443 as default."
    echo "You may need to add your SSH key to GitHub before this works."
    GITHUB_PORT=443
    GITHUB_HOST="ssh.github.com"
  fi
fi

# -----------------------------
# Create SSH config
# -----------------------------
echo "Creating SSH configuration..."
cat > "$SSH_DIR/config" <<EOF
Host github.com
    HostName $GITHUB_HOST
    Port $GITHUB_PORT
    User git
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

chmod 600 "$SSH_DIR/config"
echo "SSH configuration created (GitHub using port $GITHUB_PORT)"
echo ""

# -----------------------------
# Display public key
# -----------------------------
cat <<'MSG'
========================================
ADD THIS PUBLIC KEY TO GITHUB
========================================
MSG

cat "$SSH_KEY.pub"

cat <<'MSG'
========================================

To add this key to GitHub:
  1. Copy the key above (the entire line starting with "ssh-ed25519")
  2. Visit https://github.com/settings/keys
  3. Click "New SSH key"
  4. Enter a title like "Coder.ai Workspace"
  5. Paste the key in the "Key" field
  6. Click "Add SSH key"

MSG

read -p "Press Enter after you've added the key to GitHub..."
echo ""

# -----------------------------
# Run startup.sh to set up ephemeral environment
# -----------------------------
echo "Running startup.sh to configure this session..."
echo ""

STARTUP_SCRIPT="$PERSISTENT_DIR/startup.sh"
if [[ -f "$STARTUP_SCRIPT" ]]; then
  bash "$STARTUP_SCRIPT"
else
  echo "ERROR: startup.sh not found at $STARTUP_SCRIPT"
  echo "Please ensure startup.sh is in $PERSISTENT_DIR"
  exit 1
fi

# -----------------------------
# Final instructions
# -----------------------------
cat <<FINAL

========================================
SETUP COMPLETE
========================================

Your SSH keys are stored in persistent storage at:
  $PERSISTENT_DIR/ssh/

IMPORTANT: After each workspace restart, you must run:
  cd $PERSISTENT_DIR
  bash startup.sh

This will restore your SSH keys and install packages.

You can now clone repositories with:
  git clone git@github.com:username/repo.git

========================================
FINAL