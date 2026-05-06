#!/bin/bash

# ===============================================
# Ubuntu Server Installer Script
# ===============================================
# This script automates the installation of Zsh, Oh My Zsh, Docker,
# Docker Compose, and various app directories for a server setup.
# It also handles SMB/NFS mounting and deploys Portainer.
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

echo "Starting the Ubuntu server setup."

# --- Step 1: Update and upgrade system packages ---
echo "Updating and upgrading system packages..."
sudo apt update -y
check_error "Failed to update packages."
sudo apt upgrade -y
check_error "Failed to upgrade packages."
echo -e "${GREEN}System packages updated.${NC}"

# --- Step 2: Install file system dependencies ---
echo "Installing cifs-utils, nfs-common, and curl..."
sudo apt install -y nfs-common cifs-utils curl
check_error "Failed to install required packages."
echo -e "${GREEN}File system dependencies installed.${NC}"

# --- Step 3: Check and remove Snap Docker installation ---
echo "Checking for existing Docker Snap installation..."
if snap list | grep -q "docker"; then
    echo "Found a Snap-based Docker installation. Removing it to prevent conflicts."
    sudo snap remove docker
    check_error "Failed to remove Docker Snap package."
    echo -e "${GREEN}Docker Snap installation removed.${NC}"
else
    echo "No Docker Snap installation found. Proceeding with Docker installation."
fi

# --- Step 4: Install Docker ---
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

# --- Step 5: Install Docker Compose ---
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
check_error "Failed to install Docker Compose."
echo -e "${GREEN}Docker Compose installed.${NC}"

# --- Step 6: Create application directories ---
echo "Creating application directories..."
mkdir -p docker/{sabnzbd,nzbhydra2,sonarr,radarr,mylar,lazylibrarian,calibre-web,lidarr,ombi,heimdall}
mkdir -p docker/shared
check_error "Failed to create directories."
echo -e "${GREEN}Directories created.${NC}"

# --- Step 7: Mount file share persistently with systemd automount for resilience ---
while true; do
    echo "Choose a mount option:"
    echo "  (N)FS  - For NFS shares"
    echo "  (S)MB  - For Windows/SMB shares"
    echo "  (Q)uit - Skip file share mounting"
    read -p "Your choice: " choice
    
    case "$choice" in
        [Nn])
            echo "Mounting NFS share..."
            read -p "Enter the NFS Server IP (e.g., 192.168.1.100): " nfs_server_ip
            read -p "Enter the NFS Share path (e.g., /mnt/nfs_share): " nfs_share_path

            # Use x-systemd.automount and soft for better resilience
            FSTAB_ENTRY="$nfs_server_ip:$nfs_share_path $HOME/docker/shared nfs auto,nofail,_netdev,x-systemd.automount,noatime,soft,intr,tcp,actimeo=1800 0 0"

            # Add the entry to /etc/fstab
            echo "Adding entry to /etc/fstab for persistent mount (using _netdev and x-systemd.automount)..."
            echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
            check_error "Failed to add NFS entry to /etc/fstab."

            # Mount all entries in fstab to verify and mount immediately
            echo "Mounting all filesystems listed in /etc/fstab..."
            sudo mount -a
            check_error "Failed to mount NFS share from /etc/fstab. Please check your IP and path."
            echo -e "${GREEN}NFS share mounted and configured to be persistent and resilient.${NC}"
            break
            ;;
        [Ss])
            echo "Mounting SMB share..."
            read -p "Enter the SMB Server IP or hostname: " smb_server_ip
            read -p "Enter the SMB Share name (e.g., Data): " smb_share_name
            read -p "Enter your SMB Username: " smb_username
            read -s -p "Enter your SMB Password: " smb_password
            echo

            # Create credentials file
            CRED_FILE="$HOME/.smb_credentials"
            echo "username=$smb_username" > "$CRED_FILE"
            echo "password=$smb_password" >> "$CRED_FILE"
            sudo chmod 600 "$CRED_FILE"
            check_error "Failed to create credentials file."
            echo -e "${GREEN}Credentials file created with secure permissions.${NC}"

            # Get user and group IDs for mount options
            USER_UID=$(id -u)
            USER_GID=$(id -g)

            # Use x-systemd.automount for better resilience
            FSTAB_ENTRY="//${smb_server_ip}/${smb_share_name} $HOME/docker/shared cifs credentials=${CRED_FILE},nofail,_netdev,x-systemd.automount,vers=3.0,uid=${USER_UID},gid=${USER_GID} 0 0"

            # Add the entry to /etc/fstab
            echo "Adding entry to /etc/fstab for persistent mount (using _netdev and x-systemd.automount)..."
            echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
            check_error "Failed to add SMB entry to /etc/fstab."

            # Mount all entries in fstab to verify and mount immediately
            echo "Mounting all filesystems listed in /etc/fstab..."
            sudo mount -a
            check_error "Failed to mount SMB share from /etc/fstab. Please check your IP, share name, username, and password."
            echo -e "${GREEN}SMB share mounted and configured to be persistent and resilient.${NC}"
            break
            ;;
        [Qq])
            echo "Skipping file share mounting."
            break
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter 'N', 'S', or 'Q'.${NC}"
            ;;
    esac
done

echo "Verifying permissions for the shared directory..."
ls -ld "$HOME/docker/shared"

# --- Step 8: Deploy Portainer with Docker Compose ---
echo "Deploying Portainer with docker-compose..."
echo "Please ensure you have the 'base.yml' file in this directory."
docker-compose -f base.yml -p base up -d
check_error "Failed to deploy Portainer. Please check your 'base.yml' file."
echo -e "${GREEN}Portainer deployed. Access it at http://<YOUR_SERVER_IP>:9000${NC}"

# --- Step 9: Deploy NZB stack and configure SABNZBD ---
echo "Deploying NZB stack with docker-compose..."
echo "Please ensure you have your 'nzb.yml' file in this directory."
docker-compose -f nzb.yml -p nzb up -d
check_error "Failed to deploy NZB stack. Please check your 'nzb.yml' file."
echo -e "${GREEN}SABNZBD has been deployed. You can now configure it through its web interface.${NC}"

echo -e "${GREEN}Setup complete!${NC}"
echo "You can now manage your containers via Portainer or continue with any manual configurations."
echo "Remember to log out and back in to use the 'docker' command without 'sudo'."

# --- Step 10: Optional Reboot ---
echo
read -p "The setup is complete. Would you like to reboot the server now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
fi
