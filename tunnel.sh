#!/usr/bin/env bash
set -e

echo "=== Reverse SSH Tunnel Setup ==="
echo ""

# Configuration
PERSISTENT_DIR="$PWD"
SSH_KEY="$PERSISTENT_DIR/ssh/id_ed25519"
LOCAL_PORT=22
REMOTE_PORT=10022
REMOTE_SSH_PORT=443

# -----------------------------
# Verify SSH key exists
# -----------------------------
if [[ ! -f "$SSH_KEY" ]]; then
  echo "ERROR: SSH key not found at $SSH_KEY"
  echo "Please run setup.sh first to generate SSH keys"
  exit 1
fi

# -----------------------------
# Verify SSH server is running
# -----------------------------
if ! pgrep -x sshd >/dev/null; then
  echo "ERROR: SSH server is not running on this instance"
  echo "Please run ssh_setup.sh first to configure SSH server"
  exit 1
fi

# -----------------------------
# Get remote server details
# -----------------------------
echo "This script will create a reverse SSH tunnel to your server."
echo "You'll be able to connect from your laptop through your server."
echo ""

read -p "Enter your remote server hostname (e.g., ssh.myhost.com): " REMOTE_HOST
if [[ -z "$REMOTE_HOST" ]]; then
  echo "ERROR: Remote host cannot be empty"
  exit 1
fi

read -p "Enter your username on $REMOTE_HOST: " REMOTE_USER
if [[ -z "$REMOTE_USER" ]]; then
  echo "ERROR: Username cannot be empty"
  exit 1
fi

echo ""
echo "Configuration:"
echo "  Remote server: $REMOTE_HOST:$REMOTE_SSH_PORT"
echo "  Remote user: $REMOTE_USER"
echo "  Tunnel port on remote server: $REMOTE_PORT"
echo "  Local SSH port: $LOCAL_PORT"
echo ""

read -p "Is this correct? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Tunnel setup cancelled"
  exit 1
fi

# -----------------------------
# Start tunnel in background
# -----------------------------
echo "Starting reverse tunnel in background..."

# Kill any existing tunnel to the same remote
pkill -f "ssh.*-R $REMOTE_PORT:localhost:$LOCAL_PORT.*$REMOTE_USER@$REMOTE_HOST" 2>/dev/null || true

# Start new tunnel in background with autossh-like behavior
nohup ssh -N -T \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -o ExitOnForwardFailure=yes \
  -o StrictHostKeyChecking=no \
  -R $REMOTE_PORT:localhost:$LOCAL_PORT \
  -p $REMOTE_SSH_PORT \
  -i "$SSH_KEY" \
  "$REMOTE_USER@$REMOTE_HOST" \
  >/tmp/tunnel.log 2>&1 &

TUNNEL_PID=$!

# Wait a moment and check if tunnel is still running
sleep 2

if kill -0 $TUNNEL_PID 2>/dev/null; then
  echo "Tunnel started successfully (PID: $TUNNEL_PID)"
  echo ""
  
  # Save tunnel info
  echo "$TUNNEL_PID" > /tmp/tunnel.pid
  echo "$REMOTE_HOST" > /tmp/tunnel.host
  echo "$REMOTE_USER" > /tmp/tunnel.user
  
  # -----------------------------
  # Display connection instructions
  # -----------------------------
  cat <<INSTRUCTIONS
========================================
TUNNEL ACTIVE
========================================

The reverse tunnel is now running in the background.
You can safely close this terminal window.

To connect from your laptop:

  1. SSH to your server:
     ssh $REMOTE_USER@$REMOTE_HOST

  2. From your server, connect to this coder.ai instance:
     ssh -p $REMOTE_PORT root@localhost

  (You'll be prompted for the root password you set)

To check tunnel status:
  ps aux | grep $TUNNEL_PID

To view tunnel logs:
  tail -f /tmp/tunnel.log

To stop the tunnel:
  kill $TUNNEL_PID
  (or run: bash tunnel_stop.sh)

========================================
INSTRUCTIONS

else
  echo "ERROR: Tunnel failed to start"
  echo "Check the logs: tail /tmp/tunnel.log"
  exit 1
fi