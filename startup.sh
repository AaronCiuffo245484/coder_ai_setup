#!/usr/bin/env bash
set -e

echo "=== Coder.ai Startup Script ==="
echo ""

# Configuration - use current directory as persistent storage
PERSISTENT_DIR="$PWD"

echo "Using persistent storage directory:"
echo "  $PERSISTENT_DIR"
echo ""
read -p "Is this correct? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Startup cancelled. Please cd to your persistent storage directory and run again."
  exit 1
fi

SSH_DIR="$PERSISTENT_DIR/ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
ROOT_SSH="$HOME/.ssh"
PACKAGES_FILE="$PERSISTENT_DIR/packages.txt"

# Use sudo if not running as root
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# -----------------------------
# Restore SSH keys
# -----------------------------
echo "Restoring SSH keys from persistent storage..."

if [[ ! -f "$SSH_KEY" ]]; then
  echo "ERROR: SSH key not found at $SSH_KEY"
  echo "Please run setup.sh first to generate SSH keys"
  exit 1
fi

# Create ~/.ssh directory
mkdir -p "$ROOT_SSH"
chmod 700 "$ROOT_SSH"

# Copy keys from persistent storage
cp "$SSH_KEY" "$ROOT_SSH/id_ed25519"
cp "$SSH_KEY.pub" "$ROOT_SSH/id_ed25519.pub"
cp "$SSH_DIR/config" "$ROOT_SSH/config"

# Set correct permissions
chmod 600 "$ROOT_SSH/id_ed25519"
chmod 644 "$ROOT_SSH/id_ed25519.pub"
chmod 600 "$ROOT_SSH/config"

echo "SSH keys restored to ~/.ssh/"
echo ""

# -----------------------------
# Test GitHub connection
# -----------------------------
echo "Testing GitHub SSH access..."
if timeout 5 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "Success! GitHub SSH is working"
else
  echo "Warning: GitHub SSH test failed"
  echo "This might mean:"
  echo "  - Your SSH key is not added to GitHub yet"
  echo "  - Network connectivity issues"
  echo "  - Port restrictions"
  echo ""
  echo "You can test manually with: ssh -T git@github.com"
fi
echo ""

# -----------------------------
# Install packages from packages.txt
# -----------------------------
if [[ -f "$PACKAGES_FILE" ]]; then
  echo "Found $PACKAGES_FILE, checking packages..."
  
  # Check if apt cache needs updating
  APT_STAMP="/var/lib/apt/periodic/update-success-stamp"
  THRESHOLD_DAYS=15
  THRESHOLD_SEC=$((THRESHOLD_DAYS * 24 * 60 * 60))
  
  if [[ -f "$APT_STAMP" ]]; then
    mtime=$(stat -c %Y "$APT_STAMP")
  else
    # Fallback to newest file in apt lists
    mtime=$(find /var/lib/apt/lists -type f -printf '%T@\n' 2>/dev/null | sort -nr | head -n1 | awk '{print int($1)}')
    mtime=${mtime:-0}
  fi
  
  now=$(date +%s)
  age=$((now - mtime))
  
  if [[ "$mtime" -eq 0 || "$age" -ge "$THRESHOLD_SEC" ]]; then
    days=$((age / 86400))
    echo "Package cache is $days days old, updating..."
    $SUDO apt-get update -qq
  else
    days=$((age / 86400))
    echo "Package cache is $days days old, skipping update"
  fi
  
  # Read packages, skipping comments and empty lines
  mapfile -t packages < <(grep -v '^#' "$PACKAGES_FILE" | grep -v '^[[:space:]]*$')
  
  if [[ ${#packages[@]} -gt 0 ]]; then
    echo "Installing packages: ${packages[*]}"
    $SUDO apt-get install -y -qq "${packages[@]}"
    echo "Packages installed successfully"
  else
    echo "No packages specified in $PACKAGES_FILE"
  fi
else
  echo "No $PACKAGES_FILE found, skipping package installation"
  echo "(Create $PACKAGES_FILE with one package name per line to auto-install)"
fi

echo ""
echo "=== Startup Complete ==="
echo "Your environment is ready for ML work"
echo ""