# Setup a BUAS Coder.AI Environment

Setup a basic development environment with SSH access to github. This environment should be suitable for training AI models.

## Requirements

- Working access to the [BUas Coder.ai environment](http://coder.ai.buas.nl)
  - Authenticate with your student github account
  - Request a password from Dean vA
- [`setup.sh`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/setup.sh): Script for initializing the environment (right click the link to download)
- [`packages.txt`](https://raw.githubusercontent.com/AaronCiuffo245484/coder_ai_setup/main/packages.txt): Debian packages required for setting up the environment (right click the link to download)
  - Optional: Edit this to add or remove packages as needed prior to uploading
  - A working and active connection to the BUas VPN for off-campus access.

## Initial Setup

This step assumes that you have working access to the [BUas Coder.ai environment](http://coder.ai.buas.nl). 

**Note: you must have an active BUas VPN connection established or connected to the BUas network.**

From landing page do the following:

![Workspaces Page](./assets/workspaces_page.png)

1. Click on "Workspaces"
2. Choose: New Workspace > Student Dev Environment
3. Enter a Workspace name such as "Block-2a-dev"
4. Leave the other settings unchanged
5. Click "Create workspace"
6. Once the workspace is built, move on to the next section

## Environment Setup

This assumes that you have successfully created a workspace and can see the landing page. Before you start, select the appropriate image for your project and make sure it is "Running".

![Landing Page Example](./assets/landing_page.png)

1. From the server page, click on the "Jupyter Notebook" button to launch the file manager
2. From the file manager choose "Upload", browse for and select the `packages.txt` and `setup.sh` scripts 
    - You may close this when you are done
3. From the landing page, choose the "Terminal" button to launch a bash shell in a new window.
4. Make sure you are in the `/home/y2a/` directory
5. Run `chmod +x setup.sh` 
   - This makes the setup script executable
6. Run `./setup.sh`
    -  This will run the setup script, install necessary packages and setup and configure ssh access for github.
7. CAREFULLY read the instructions and follow them when prompted. **SEE BELOW!**

### Explanation of Steps

As the setup script runs, it will prompt you to add a newly created ssh public key to your BUAS Git account.

**NEVER, EVER, EVER, EVER DO THIS IF YOU DO NOT TRUST COMPLETELY THE PERSON GIVING YOU THE KEY!**

Adding a ssh public key to your repo allows whomever holds the private half of the key complete access to your git repo. In this case, you hold the private key in `~/.ssh/id_rsa`.  Never share this file with anyone. EVER.

Provided all the steps are completed properly, you will be prompted to enter the ssh clone URL for a repo. You can find this on the project page under `Code > Local > SSH`

![SSH Clone URL](./assets/clone_github.png)

Once the repo is cloned, you can begin using your repo as normal through the Jupyter file manager interface.

## Troubleshooting

If you encounter issues where `git` operations take a long time only to ultimately fail, try running the setup script again.
