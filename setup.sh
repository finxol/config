#!/bin/bash

# This script automates the initial setup and hardening of a new Debian-based server.
# It must be run as root.
#
# The script will:
# 1. Create a new sudo user.
# 2. Move the root SSH key to the new user.
# 3. Harden the SSH server configuration.
# 4. Install bat, eza, and Docker.

# --- Configuration ---
readonly USERNAME="finxol"
# Define a temporary password. This will be immediately expired.
# WARNING: This password will be stored in the script file and potentially
# in your shell history. This is an acceptable risk for a brand new server
# where the password will be changed upon first login.
readonly TEMP_PASS="password"

# --- Script Execution ---

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error.
set -u
# Ensure that pipelines return the exit status of the last command to fail.
set -o pipefail

# --- Helper Functions ---
log() {
  echo
  echo "▶ $1"
  echo "--------------------------------------------------"
}

# --- Pre-flight Checks ---
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# --- User and Sudo Setup ---
log "Creating user '$USERNAME' and granting sudo privileges"

# Create a new user without an interactive password prompt.
adduser --disabled-password --gecos "" "$USERNAME"

# Programmatically set the temporary password for the new user.
echo "$USERNAME:$TEMP_PASS" | chpasswd
echo "Temporary password has been set for '$USERNAME'."

# Force the user to change their password on the next login.
chage -d 0 "$USERNAME"

# Add the new user to the 'sudo' group to grant administrative privileges.
usermod -aG sudo "$USERNAME"
echo "User '$USERNAME' created and added to the sudo group."
# --- SSH Key Migration ---
log "Migrating SSH key from root to '$USERNAME'"
# Create the .ssh directory for the new user if it doesn't exist.
mkdir -p "/home/$USERNAME/.ssh"

# Move the root user's authorized_keys file to the new user's .ssh directory.
mv /root/.ssh/authorized_keys "/home/$USERNAME/.ssh/authorized_keys"

# Set the correct ownership and permissions for the .ssh directory and its contents.
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"
chmod 700 "/home/$USERNAME/.ssh"
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
echo "SSH key successfully migrated."

# --- SSH Server Hardening ---
log "Hardening SSH server configuration"
readonly SSHD_CONFIG="/etc/ssh/sshd_config"

# A function to safely set a parameter in sshd_config.
# It comments out any existing instance of the key and appends the new setting.
set_ssh_config() {
  local key="$1"
  local value="$2"

  # Comment out any existing lines with the key to deactivate them.
  # The -E flag enables extended regular expressions for the '+' quantifier.
  sed -i -E "s/^[[:space:]]*#?[[:space:]]*($key)([[:space:]]+.*)?$/#\1\2/g" "$SSHD_CONFIG"

  # Append the new, correct setting to the end of the file.
  echo "$key $value" >> "$SSHD_CONFIG"
}

# --- Apply Hardening Rules ---
# Note: We are now using a function to ensure settings are applied correctly,
# preventing issues with duplicate or conflicting rules.

set_ssh_config "UsePAM" "yes"
set_ssh_config "PasswordAuthentication" "no"
set_ssh_config "KbdInteractiveAuthentication" "no"

set_ssh_config "PermitRootLogin" "no"
set_ssh_config "PermitEmptyPasswords" "no"
set_ssh_config "X11Forwarding" "no"
set_ssh_config "AllowAgentForwarding" "no"

# --- Custom Hardening Settings ---
set_ssh_config "ClientAliveInterval" "300"
set_ssh_config "ClientAliveCountMax" "2"
set_ssh_config "LoginGraceTime" "60"
set_ssh_config "MaxAuthTries" "3"
set_ssh_config "MaxSessions" "4"

# Validate the new sshd_config and restart the SSH service to apply changes.
sshd -t && systemctl restart sshd
echo "SSH server hardened and restarted."

# --- Package Installation ---
log "Updating package lists and installing applications"
apt-get update

# Install bat (a cat clone with syntax highlighting)
apt-get install -y bat
# On Debian/Ubuntu, the binary can be named 'batcat'. Create a symlink if needed.
if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
  ln -s /usr/bin/batcat /usr/bin/bat
fi

# Install eza (a modern replacement for ls)
apt-get install -y gpg
mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |
  gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" |
  tee /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
apt-get update
apt-get install -y eza

# Install Docker Engine
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  tee /etc/apt/sources.list.d/docker.list >/dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# Add the new user to the 'docker' group to allow running Docker without sudo.
# The '|| true' prevents the script from failing if the group already exists.
groupadd docker || true
usermod -aG docker "$USERNAME"
echo "Docker installed and '$USERNAME' added to the docker group."

# --- Finalization ---
log "Server setup complete!"
echo "You can now log out and reconnect as '$USERNAME' using your SSH key."
echo "Root login and password authentication have been disabled."
