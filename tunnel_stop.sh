#!/usr/bin/env bash

echo "=== Stopping Reverse SSH Tunnel ==="
echo ""

# Check if tunnel info exists
if [[ ! -f /tmp/tunnel.pid ]]; then
  echo "No active tunnel found"
  exit 0
fi

TUNNEL_PID=$(cat /tmp/tunnel.pid)
REMOTE_HOST=$(cat /tmp/tunnel.host 2>/dev/null || echo "unknown")
REMOTE_USER=$(cat /tmp/tunnel.user 2>/dev/null || echo "unknown")

# Check if process is still running
if kill -0 $TUNNEL_PID 2>/dev/null; then
  echo "Stopping tunnel (PID: $TUNNEL_PID) to $REMOTE_USER@$REMOTE_HOST..."
  kill $TUNNEL_PID
  
  # Wait a moment
  sleep 1
  
  # Force kill if still running
  if kill -0 $TUNNEL_PID 2>/dev/null; then
    echo "Force stopping tunnel..."
    kill -9 $TUNNEL_PID
  fi
  
  echo "Tunnel stopped"
else
  echo "Tunnel process $TUNNEL_PID is not running"
fi

# Clean up
rm -f /tmp/tunnel.pid /tmp/tunnel.host /tmp/tunnel.user

echo "Done"