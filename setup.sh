#!/bin/bash

# ==============================================================================
# OpenRealms Server Setup Script
#
# This script automates the setup of an OpenRealms server environment. It performs
# the following actions:
# 1. Prompts the user to accept the Minecraft EULA.
# 2. Creates the main directory "OpenRealms".
# 3. Sets up a "Velocity" proxy server directory.
# 4. Clones the Velocity repository, removes the .git history, and downloads the
#    latest stable Velocity JAR from the PaperMC API.
# 5. Sets up a "GameServer" directory.
# 6. Clones the GameServer repository, removes the .git history, and downloads
#    the latest stable Paper 1.21.8 JAR from the PaperMC API.
# 7. Creates a `startservers.sh` script to easily launch both servers using 'screen'.
# 8. Creates the `eula.txt` file in the GameServer directory.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- EULA Check ---
echo "Before you proceed, you must agree to the Minecraft EULA."
echo "You can find the EULA here: https://account.mojang.com/documents/minecraft_eula"
echo "Do you agree to the EULA? (yes/no)"
read -r response

# Check the user's response (case-insensitive)
if [[ ! " ${response,,} " =~ " yes " ]] && [[ ! " ${response,,} " =~ " y " ]]; then
    echo "EULA not accepted. The script will be aborted."
    exit 1
fi

echo "EULA accepted. Starting the setup..."
echo ""

# --- Main Directory Setup ---
echo "--> Creating main directory 'OpenRealms'..."
mkdir -p OpenRealms
cd OpenRealms

# --- Velocity Setup ---
echo "--> Setting up Velocity server..."
mkdir -p Velocity
cd Velocity
echo "    - Cloning the Velocity repository..."
git clone https://github.com/OpenRealms-MC/Velocity .
echo "    - Removing .git history..."
rm -rf .git
echo "    - Downloading the latest Velocity JAR..."
# NOTE: The version and build numbers below are current as of this date.
# If this script fails in the future, you may need to update these values.
wget -O velocity.jar https://api.papermc.io/v2/projects/velocity/versions/3.4.0-SNAPSHOT/builds/523/downloads/velocity-3.4.0-SNAPSHOT-523.jar
cd ..

# --- GameServer Setup ---
echo "--> Setting up GameServer..."
mkdir -p GameServer
cd GameServer
echo "    - Cloning the GameServer repository..."
git clone https://github.com/OpenRealms-MC/GameServer .
echo "    - Removing .git history..."
rm -rf .git
echo "    - Downloading the latest Paper 1.21.8 JAR..."
# NOTE: The build number (25) is current as of this date.
# If this script fails in the future, you may need to update this value.
wget -O paper.jar https://api.papermc.io/v2/projects/paper/versions/1.21.8/builds/25/downloads/paper-1.21.8-25.jar
cd ..

# --- Server Startup Script Creation ---
echo "--> Creating 'startservers.sh' script..."
cat > startservers.sh <<EOF
#!/bin/bash

# ------------------------------------------------------------------------------
# OpenRealms Server Launcher
#
# This script starts the Velocity proxy server and the Paper GameServer,
# each in its own 'screen' session.
#
# How to use 'screen':
# - 'screen -ls' lists all running server sessions.
# - 'screen -r [SESSION_NAME]' (e.g., 'screen -r velocity') connects you to
#   a server's console.
# - Press 'Ctrl + A' and then 'D' to leave (detach from) the console
#   without stopping the server.
# ------------------------------------------------------------------------------

# --- Start Velocity in a screen session ---
echo "Starting Velocity in a 'screen' session named 'velocity'..."
cd Velocity || exit
screen -dmS velocity java -Xms512M -Xmx1G -jar velocity.jar nogui
cd ..

# --- Start GameServer in a screen session ---
echo "Starting GameServer in a 'screen' session named 'gameserver'..."
cd GameServer || exit
screen -dmS gameserver java -Xms1G -Xmx2G -jar paper.jar nogui
cd ..

echo ""
echo "Servers are starting. Consoles are running in the background in 'screen' sessions."
echo "You can list active sessions with 'screen -ls'."
echo "To connect to a console, use 'screen -r [SESSION_NAME]'."
echo "The script has finished successfully."
EOF

# Make the start script executable
chmod +x startservers.sh

# --- Create eula.txt ---
echo "--> Creating eula.txt in the GameServer folder..."
echo "eula=true" > GameServer/eula.txt

echo "----------------------------------------------------------------"
echo "Script finished successfully!"
echo "The 'OpenRealms' directory is ready."
echo "You can start the servers by running './startservers.sh' inside the directory."
echo "----------------------------------------------------------------"
