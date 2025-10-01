#!/usr/bin/env bash

PKGFILE="/home/y2a/packages.txt"
KEYDIR="/home/y2a/ssh"
KEYFILE="$KEYDIR/id_rsa"
STAMP="/var/lib/apt/periodic/update-success-stamp"
THRESHOLD_DAYS=15
THRESHOLD_SEC=$((THRESHOLD_DAYS * 24 * 60 * 60))

# Use sudo for apt if not root
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
else
  SUDO=""
fi

# -----------------------------
# Apt cache freshness check
# -----------------------------
# Determine last update mtime
if [[ -f "$STAMP" ]]; then
  mtime=$(stat -c %Y "$STAMP")
else
  # Fallback: newest file in apt lists, or 0 if none
  mtime=$(find /var/lib/apt/lists -type f -printf '%T@ %p\n' 2>/dev/null \
          | sort -nr | head -n1 | awk '{print int($1)}')
  mtime=${mtime:-0}
fi

now=$(date +%s)
age=$(( now - mtime ))

if [[ "$mtime" -eq 0 || "$age" -ge "$THRESHOLD_SEC" ]]; then
  echo "Package cache missing or older than $THRESHOLD_DAYS days. Running apt update..."
  $SUDO apt update
else
  days=$(( age / 86400 ))
  echo "Package cache is fresh (${days} days old). Skipping update."
fi

# -----------------------------
# Package install from file
# -----------------------------
if [[ -f "$PKGFILE" ]]; then
  echo "Found $PKGFILE. Installing packages..."
  # expects one package per line
  $SUDO xargs -r -a "$PKGFILE" apt install -y
else
  echo "Package list $PKGFILE not found. Skipping install."
fi

# -----------------------------
# SSH key: create if missing
# -----------------------------
if [[ -f "$KEYFILE" && -f "$KEYFILE.pub" ]]; then
  echo "SSH key already exists at $KEYFILE"
else
  echo "Generating new SSH key at $KEYFILE

Simply press the Return key for passphrase prompts if you want a blank passphrase."
  mkdir -p "$KEYDIR"
  # Generate RSA 4096 as you started with; consider ed25519 if allowed
  ssh-keygen -t rsa -b 4096 -f "$KEYFILE"
  chmod 600 "$KEYFILE"
  chmod 644 "$KEYFILE.pub"
fi

# -----------------------------
# Prompt to add key to GitHub
# -----------------------------
cat <<'MSG'
You must now add the generated key to GitHub to provide access to your repos.

Follow these steps:
  1. Copy the text below starting with "ssh-rsa ..."
  2. Visit https://github.com/settings/keys
  3. Click "New SSH key"
  4. Enter a title such as BUas Server
  5. Paste the key in the key box
  6. Finish any approvals GitHub requires

Press Enter when you are done.
MSG

cat "$KEYFILE.pub"
read -r

# -----------------------------
# SSH config for GitHub on 443
# -----------------------------
cat > "$KEYDIR/config" <<'EOF'
Host github.com
  HostName ssh.github.com
  User git
  Port 443
  IdentitiesOnly yes
EOF

# Host key for GitHub:443
ssh-keyscan -p 443 ssh.github.com >> "$KEYDIR/known_hosts"

# -----------------------------
# Fix SSH permissions and ownership
# -----------------------------
echo "Setting correct SSH permissions and ownership..."

if [[ $EUID -eq 0 ]]; then
  # Running as root
  chown -R root:root "$KEYDIR"
else
  # Running as regular user
  chown -R "$USER:$(id -gn)" "$KEYDIR"
fi

# Permissions are sometimes reset by the instance. Reapply them.
chmod 700 "$KEYDIR"
chmod 600 "$KEYDIR/config"
chmod 600 "$KEYFILE"
chmod 644 "$KEYFILE.pub"
chmod 600 "$KEYDIR/known_hosts" 2>/dev/null || true

echo "SSH permissions configured."

# -----------------------------
# Link ~/.ssh if not present
# -----------------------------
echo "Creating symlink for ssh at ~/.ssh"
if [[ ! -e "$HOME/.ssh" ]]; then
  ln -s "$KEYDIR" "$HOME/.ssh"
  echo "Symlink created."
else
  echo "~/.ssh already exists, skipping."
fi

# -----------------------------
# Test GitHub SSH
# -----------------------------
echo "Testing GitHub access"
out="$(ssh -T git@github.com 2>&1)"
rc=$?
if [[ $rc -eq 1 && "$out" == *"successfully authenticated"* ]]; then
  echo "Success! You have access to GitHub via SSH"
else
  echo "Your SSH keys are not valid or GitHub SSH is not reachable."
  echo "Details:"
  echo "$out"
  exit 1
fi

# -----------------------------
# Optional: prompt to clone
# -----------------------------
cat <<'NOTE'

Enter a GitHub repo URL, for example:
  git@github.com:owner/repo.git

You can find this on the repo page under Code > Local > SSH.
NOTE

read -r -p "REPO URL: " REPO
if [[ -n "$REPO" ]]; then
  echo "Cloning $REPO..."
  if git clone "$REPO"; then
    echo "Clone successful."
  else
    echo "Clone failed. Please check the URL or your SSH setup."
  fi
else
  cat <<'HINT'
No URL provided. You can manually clone later with:
  git clone git@github.com:you/repo.git
HINT
fi

# -----------------------------
# Example: install project deps
# -----------------------------
if [[ -f /home/y2a/fae2-nlpr-group-group-22/python/requirements.txt ]]; then
  pip install -r /home/y2a/fae2-nlpr-group-group-22/python/requirements.txt
fi