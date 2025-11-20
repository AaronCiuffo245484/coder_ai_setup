# Setup a BUas Coder.AI Environment

Setup a development environment with SSH access to GitHub and optional reverse tunneling for direct terminal access. This environment is suitable for training AI models and general development work.

## Requirements

- Working access to the [BUas Coder.ai environment](http://coder.ai.buas.nl)
  - Authenticate with your student GitHub account
  - Request a password from your instructor
- A working and active connection to the BUas VPN for off-campus access
- Setup scripts (download these to your local machine first):
  - [`setup.sh`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/setup.sh): Initial environment configuration
  - [`startup.sh`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/startup.sh): Post-restart restoration script
  - [`packages.txt`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/packages.txt): System packages to install (optional - edit as needed)

## Initial Workspace Creation

**Note: You must have an active BUas VPN connection or be connected to the BUas network.**

From the Coder.ai landing page:

![Workspaces Page](./assets/workspaces_page.png)

1. Click on "Workspaces"
2. Choose: New Workspace > Student Dev Environment
3. Enter a workspace name (e.g., "Block-2a-dev")
4. Leave other settings unchanged
5. Click "Create workspace"
6. Wait for the workspace to build

Once created, select the appropriate image for your project and ensure it shows "Running" status.

## Environment Setup

### Upload Setup Scripts

![Landing Page Example](./assets/landing_page.png)

1. From the workspace page, click "Jupyter Notebook" to launch the file manager
2. Navigate to your home directory (typically `/home/<your year & block>/`)
3. Click "Upload" and select the downloaded scripts:
   - `setup.sh`
   - `startup.sh`
   - `packages.txt` (optional)
4. Close the file manager when complete

### Run Initial Setup

1. From the workspace page, click "Terminal" to launch a bash shell
2. Verify you're in your home directory:
   ```bash
   pwd
   # Should show something like /home/y2b/ or /home/y3a/
   cd /home/<your year & block>/
   ```
3. Make scripts executable:
   ```bash
   chmod +x setup.sh startup.sh
   ```
4. Run the setup script:
   ```bash
   ./setup.sh
   ```
5. When prompted, verify the directory path is correct and type `y` to continue
6. Follow the on-screen instructions carefully

### Understanding SSH Keys

The setup script will generate an SSH key pair and prompt you to add the public key to GitHub.

**SECURITY WARNING: NEVER add an SSH public key to your GitHub account unless you completely trust the source!**

Adding an SSH public key to your GitHub account grants complete access to your repositories to whoever holds the private key. In this case, YOU hold the private key at `/home/<your year & block>/ssh/id_ed25519`. 

**NEVER share this private key file with anyone. EVER.**

#### Adding Your SSH Key to GitHub

When prompted by the setup script:

1. Copy the public key displayed (the entire line starting with `ssh-ed25519`)
2. Visit https://github.com/settings/keys
3. Click "New SSH key"
4. Enter a title like "BUas Coder.ai Workspace"
5. Paste the key in the "Key" field
6. Click "Add SSH key"
7. Return to the terminal and press Enter to continue

#### Cloning Your Repository

After adding your SSH key, you'll be prompted to enter a repository URL. You can find this on your GitHub project page:

![SSH Clone URL](./assets/clone_github.png)

1. Go to your repository on GitHub
2. Click "Code" > "Local" > "SSH"
3. Copy the URL (format: `git@github.com:username/repo.git`)
4. Paste it when prompted by the setup script

The repository will be cloned to your home directory.

## Customizing Your Environment with packages.txt

The `packages.txt` file allows you to automatically install system packages every time your workspace starts. This is useful for installing tools and libraries that aren't included in the base image.

### Format

The file should contain one package name per line:

```
# This is a comment - lines starting with # are ignored
vim
htop
tmux
tree
```

### Common Packages

Here are some commonly useful packages:

**Text editors:**
- `vim` - Vi improved text editor
- `nano` - Simple text editor
- `emacs` - Extensible text editor

**System monitoring:**
- `htop` - Interactive process viewer
- `iotop` - I/O monitoring
- `ncdu` - Disk usage analyzer

**Development tools:**
- `tmux` - Terminal multiplexer
- `tree` - Directory structure viewer
- `jq` - JSON processor
- `curl` - Data transfer tool
- `wget` - File downloader

**Build tools:**
- `build-essential` - Compilation tools (gcc, make, etc.)
- `cmake` - Cross-platform build system
- `git-lfs` - Git Large File Storage

### How It Works

When you run `startup.sh` after a workspace restart:
1. The script checks if `packages.txt` exists in your home directory
2. If found, it reads the file (skipping comments and empty lines)
3. Checks if the apt package cache is older than 15 days
4. Updates the cache if needed
5. Installs all listed packages using `apt-get install`

### Adding Packages

You can edit `packages.txt` at any time:

**Via Jupyter file manager:**
1. Open Jupyter from the workspace page
2. Navigate to your home directory
3. Open `packages.txt` (or create it if it doesn't exist)
4. Add one package name per line
5. Save the file

**Via terminal:**
```bash
# Add a package to the file
echo "htop" >> /home/<your year & block>/packages.txt

# Edit the file directly
nano /home/<your year & block>/packages.txt
```

### Notes

- Package installation requires the apt cache to be updated, which can take time on first run
- Not all packages are available - if a package fails, check the name on https://packages.ubuntu.com
- Python packages should be installed via `pip`, not through `packages.txt`
- The workspace may already have many development tools pre-installed

## After Workspace Restarts

When your workspace restarts (due to inactivity or maintenance), you'll need to restore your SSH configuration:

1. Open a terminal from the workspace page
2. Navigate to your home directory:
   ```bash
   cd /home/<your year & block>/
   ```
3. Run the startup script:
   ```bash
   ./startup.sh
   ```
4. Verify the directory and type `y` to continue

The startup script will:
- Restore your SSH keys from persistent storage
- Install any packages listed in `packages.txt`
- Test your GitHub connection

You can then continue working with git as normal.

## Troubleshooting

### Problem: Git reports "Dubious permisisons" on files after server restart

**Cause**: The ownership of your ssh directory no longer maps to "your" user. 

**Solution**: Run `chown -R root:root /ssh/` and then `chmod 600 /ssh/id_rsa` <- This resets ownership for your current user and ensures proper permissions.

Thanks to Alex K for pointing this out.

### Git Operations Fail or Timeout

If `git` operations take a long time and ultimately fail:

1. Run the startup script again to restore SSH configuration:
   ```bash
   cd /home/<your year & block>/
   ./startup.sh
   ```
2. Test GitHub connectivity:
   ```bash
   ssh -T git@github.com
   ```
   You should see: "Hi username! You've successfully authenticated..."

### SSH Key Not Working

If you can't authenticate with GitHub:

1. Verify your public key is added to GitHub at https://github.com/settings/keys
2. Check that your SSH keys exist in persistent storage:
   ```bash
   ls -la /home/<your year & block>/ssh/
   ```
3. Re-run startup.sh to restore keys to `~/.ssh/`

### Packages Not Installing

If packages fail to install:

1. Check your `packages.txt` file for syntax errors (one package per line)
2. Verify you have sudo/root privileges
3. Manually update apt cache:
   ```bash
   sudo apt-get update
   ```

---

## Optional: Direct SSH Access via Reverse Tunnel

For advanced users who prefer working in a local terminal instead of the web interface, you can set up a reverse SSH tunnel to connect directly from your laptop.

### Requirements

- A server with a public IP address that you control (e.g., `ssh.myhost.com`)
- SSH access to that server on port 443
- Your coder.ai workspace SSH public key added to your server's authorized_keys

### Additional Scripts

Download these additional scripts:

- [`ssh_setup.sh`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/ssh_setup.sh): Configure SSH server on coder.ai
- [`tunnel.sh`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/tunnel.sh): Start reverse tunnel
- [`tunnel_stop.sh`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/tunnel_stop.sh): Stop reverse tunnel

### Setup Process

1. Upload the additional scripts to your home directory
2. Make them executable:
   ```bash
   cd /home/<your year & block>/
   chmod +x ssh_setup.sh tunnel.sh tunnel_stop.sh
   ```

3. **Configure SSH server** (run once per workspace instance):
   ```bash
   ./ssh_setup.sh
   ```
   This will:
   - Install OpenSSH server
   - Configure it for root login
   - Set up your authorized_keys for passwordless access (if available)
   - Prompt you to set a root password

4. **Add your laptop's public key** for passwordless access:
   
   On your laptop:
   ```bash
   cat ~/.ssh/id_ed25519.pub  # or id_rsa.pub
   ```
   
   Copy the output, then on coder.ai:
   ```bash
   echo "YOUR_PUBLIC_KEY" > /home/<your year & block>/ssh/authorized_keys
   ```
   
   Run `ssh_setup.sh` again to install the key.

5. **Start the reverse tunnel**:
   ```bash
   ./tunnel.sh
   ```
   
   When prompted:
   - Enter your server hostname (e.g., `ssh.myhost.com`)
   - Enter your username on that server
   - Verify the configuration
   
   The tunnel will start in the background and display connection instructions.

### Connecting from Your Laptop

Once the tunnel is running, you can connect from your laptop:

**Basic two-hop connection:**
```bash
ssh USERNAME@ssh.myhost.com
ssh -p 10022 root@localhost
```

**With iTerm2 tmux integration (recommended):**

For the best experience with native iTerm2 tmux integration, use:
```bash
ssh -t -p 443 USERNAME@ssh.myhost.com 'ssh -t -p 10022 root@localhost "tmux -CC new -A -s myshell"'
```

Replace `USERNAME` with your actual username and `443` with your server's SSH port if different.

This command:
- Creates or attaches to a tmux session named "myshell"
- Uses iTerm2's native tmux integration mode (`-CC`)
- Properly handles the nested SSH connection with double `-t` flags

**Setting up an iTerm2 profile:**

For easy access, create an iTerm2 profile:
1. Open iTerm2 → Preferences → Profiles
2. Create a new profile (e.g., "Coder.ai")
3. In the "General" tab, set the command to:
   ```bash
   ssh -t -p 443 USERNAME@ssh.myhost.com 'ssh -t -p 10022 root@localhost "tmux -CC new -A -s myshell"'
   ```
4. Save the profile

Now you can launch your coder.ai workspace with native tmux integration directly from iTerm2.

### Managing the Tunnel

**Check tunnel status:**
```bash
ps aux | grep ssh | grep 10022
tail -f /tmp/tunnel.log
```

**Stop the tunnel:**
```bash
./tunnel_stop.sh
```

**Restart after workspace restart:**

After each workspace restart, you'll need to:
1. Run `./ssh_setup.sh` to restore SSH server
2. Run `./tunnel.sh` to restart the reverse tunnel

### Security Considerations

- The reverse tunnel requires your server to have `GatewayPorts` configured appropriately
- Keep `GatewayPorts no` (default) for maximum security - this restricts tunnel access to localhost on your server
- Never share your private SSH keys
- Use strong passwords or key-based authentication only
- Consider setting up firewall rules on your server to restrict access

---

## Additional Resources

- [GitHub SSH Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Git Basics Documentation](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)
- [iTerm2 tmux Integration](https://iterm2.com/documentation-tmux-integration.html)

## Support

For issues related to:
- Workspace access: Contact your instructor
- VPN connection: Contact BUas IT support
- Script errors: Check the troubleshooting section above