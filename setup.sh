#!/bin/bash

# ===============================================
# Ubuntu Media Server Installer Script
# ===============================================
# This script automates the installation of Zsh, Oh My Zsh, Docker,
# Docker Compose, and various app directories for a media server setup.
# It also handles NFS mounting and deploys Portainer.
#
# NOTE: This script must be run by a user with sudo privileges.
# ===============================================

# Define color codes for a better user experience
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check for errors and exit
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}" >&2
        exit 1
    fi
}

echo "Starting the Ubuntu Media Server setup."

# --- Step 1: Update and upgrade system packages ---
echo "Updating and upgrading system packages..."
sudo apt update -y
check_error "Failed to update packages."
sudo apt upgrade -y
check_error "Failed to upgrade packages."
echo -e "${GREEN}System packages updated.${NC}"

# --- Step 2: Install Zsh and NFS dependencies ---
echo "Installing Zsh, NFS, and curl..."
sudo apt install -y zsh nfs-common curl
check_error "Failed to install required packages."
echo -e "${GREEN}Zsh and NFS dependencies installed.${NC}"

# --- Step 3: Install Docker ---
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y ca-certificates gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
check_error "Failed to install Docker."

echo "Adding current user to the 'docker' group to run Docker commands without sudo."
sudo usermod -aG docker "$USER"
echo "You may need to log out and log back in for the group changes to take effect."

# --- Step 4: Install Docker Compose ---
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
check_error "Failed to install Docker Compose."
echo -e "${GREEN}Docker Compose installed.${NC}"

# --- Step 5: Create application directories ---
echo "Creating media application directories..."
mkdir -p docker/{sabnzbd,nzbhydra2,sonarr,radarr,mylar,lazylibrarian,calibre-web,lidarr,ombi,heimdall}
mkdir -p docker/shared
check_error "Failed to create directories."
echo -e "${GREEN}Directories created.${NC}"

# --- Step 6: Mount NFS share persistently ---
echo "Mounting NFS share..."
read -p "Enter the NFS Server IP (e.g., 192.168.1.100): " nfs_server_ip
read -p "Enter the NFS Share path (e.g., /mnt/nfs_media_share): " nfs_share_path

# Create a variable to hold the fstab entry
FSTAB_ENTRY="$nfs_server_ip:$nfs_share_path $HOME/docker/shared nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0"

# Add the entry to /etc/fstab
echo "Adding entry to /etc/fstab for persistent mount..."
echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
check_error "Failed to add NFS entry to /etc/fstab."

# Mount all entries in fstab to verify and mount immediately
echo "Mounting all filesystems listed in /etc/fstab..."
sudo mount -a
check_error "Failed to mount NFS share from /etc/fstab. Please check your IP and path."
echo -e "${GREEN}NFS share mounted and configured to be persistent.${NC}"

echo "Verifying permissions for the shared directory..."
ls -ld "$HOME/docker/shared"

# --- Step 7: Deploy Portainer with Docker Compose ---
echo "Deploying Portainer with docker-compose..."
echo "Please ensure you have the 'base.yml' file in this directory."
docker-compose -f base.yml -p base up -d
check_error "Failed to deploy Portainer. Please check your 'base.yml' file."
echo -e "${GREEN}Portainer deployed. Access it at http://<YOUR_SERVER_IP>:9000${NC}"

# --- Step 8: Deploy NZB stack and configure SABNZBD ---
echo "Deploying NZB stack with docker-compose..."
echo "Please ensure you have your 'nzb.yml' file in this directory."
docker-compose -f nzb.yml -p nzb up -d
check_error "Failed to deploy NZB stack. Please check your 'nzb.yml' file."
echo -e "${GREEN}SABNZBD has been deployed. You can now configure it through its web interface.${NC}"

echo -e "${GREEN}Setup complete!${NC}"
echo "You can now manage your containers via Portainer or continue with any manual configurations."
echo "Remember to log out and back in to use the 'docker' command without 'sudo'."

# --- Step 9: Optional Reboot ---
echo
read -p "The setup is complete. Would you like to reboot the server now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
fi
