#!/bin/bash

# setup_ctf_server.sh
# This script sets up a simple Python web server as a systemd service.
# It creates a specified directory, sets up 'lin' and 'win' subdirectories,
# and configures the service to run on a given port.

# --- Configuration ---
# Default values if no arguments are provided
DEFAULT_LOCATION="/opt/ctf_server"
DEFAULT_PORT="4444"

# --- Functions ---

# Function to display usage information
usage() {
    echo "Usage: $0 [location] [port]"
    echo "  location: The directory to serve files from. Default: ${DEFAULT_LOCATION}"
    echo "  port:     The port for the web server to listen on. Default: ${DEFAULT_PORT}"
    exit 1
}

# Function to handle errors and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# --- Main Script ---

# Check if running as root, which is required for creating service files
if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run as root to create the systemd service."
fi

# Assign arguments to variables or use defaults
SERVER_LOCATION="${1:-$DEFAULT_LOCATION}"
SERVER_PORT="${2:-$DEFAULT_PORT}"

echo "[+] Using server location: ${SERVER_LOCATION}"
echo "[+] Using server port: ${SERVER_PORT}"

# Create the server directory and subdirectories
echo "[*] Creating server directories at ${SERVER_LOCATION}..."
mkdir -p "${SERVER_LOCATION}/lin" || error_exit "Failed to create directory ${SERVER_LOCATION}/lin"
mkdir -p "${SERVER_LOCATION}/win" || error_exit "Failed to create directory ${SERVER_LOCATION}/win"
echo "[+] Directories created successfully."

# Define the service file path
SERVICE_FILE="/etc/systemd/system/ctf-server.service"

# Create the systemd service file
echo "[*] Creating systemd service file at ${SERVICE_FILE}..."
cat << EOF > "${SERVICE_FILE}"
[Unit]
Description=CTF Web Server for Pentesting Tools
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${SERVER_LOCATION}
ExecStart=/usr/bin/python3 -m http.server ${SERVER_PORT}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

if [ $? -ne 0 ]; then
    error_exit "Failed to create systemd service file."
fi

echo "[+] Service file created."

# Reload systemd, enable and start the service
echo "[*] Reloading systemd daemon..."
systemctl daemon-reload || error_exit "Failed to reload systemd daemon."

echo "[*] Enabling the ctf-server service to start on boot..."
systemctl enable ctf-server.service || error_exit "Failed to enable the service."

echo "[*] Starting the ctf-server service..."
systemctl start ctf-server.service || error_exit "Failed to start the service."

# Check the status of the service
echo "[*] Checking service status..."
systemctl status ctf-server.service --no-pager

echo ""
echo "[+] Setup complete!"
echo "[+] Your CTF web server is running on port ${SERVER_PORT} and serving files from ${SERVER_LOCATION}"
echo "[+] You can now use the 'ctfsrv-add' script to add files."
