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
# 7. Downloads plugins for both Velocity and GameServer.
# 8. Creates a `startservers.sh` script to easily launch both servers using 'screen'.
# 9. Creates the `eula.txt` file in the GameServer directory.
# 10. Displays final warnings about the community plugins.
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

# --- Community Mythic Plugins Check ---
echo "----------------------------------------------------------------"
echo "ATTENTION: This setup can install community versions of Mythic plugins."
echo "These are outdated and may cause some server features to not work correctly."
echo "It is highly recommended to update with the premium versions as soon as possible."
echo "----------------------------------------------------------------"
echo "Do you want to download the community versions of the Mythic plugins? (yes/no)"
read -r mythic_response

if [[ " ${mythic_response,,} " =~ " yes " ]] || [[ " ${mythic_response,,} " =~ " y " ]]; then
    DOWNLOAD_MYTHIC=true
    echo "Community Mythic plugins will be downloaded."
else
    DOWNLOAD_MYTHIC=false
    echo "Community Mythic plugins will NOT be downloaded."
fi
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
wget -O velocity.jar https://api.papermc.io/v2/projects/velocity/versions/3.4.0-SNAPSHOT/builds/523/downloads/velocity-3.4.0-SNAPSHOT-523.jar

echo "    - Downloading Velocity plugins..."
mkdir -p plugins
wget -O velocity-plugins.txt https://github.com/OpenRealms-MC/Velocity-Plugins/blob/main/plugins-downloads.txt?raw=true
while IFS= read -r url || [[ -n "$url" ]]; do
    url=$(echo "$url" | xargs) # trim whitespace
    if [[ -n "$url" ]]; then
        echo "        - Downloading $(basename "$url")..."
        wget -P plugins "$url"
    fi
done < "velocity-plugins.txt"
rm velocity-plugins.txt
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
wget -O paper.jar https://api.papermc.io/v2/projects/paper/versions/1.21.8/builds/25/downloads/paper-1.21.8-25.jar

# --- Plugin Downloads ---
echo "--> Downloading plugins for GameServer..."
mkdir -p plugins

# Function to download plugins from a list of URLs
download_plugins() {
    local url_list_file="$1"
    local plugin_dir="plugins"
    while IFS= read -r url || [[ -n "$url" ]]; do
        url=$(echo "$url" | xargs) # trim whitespace
        if [[ -n "$url" ]]; then
            echo "    - Downloading $(basename "$url")..."
            wget -P "$plugin_dir" "$url"
        fi
    done < "$url_list_file"
}

# Download core plugins
wget -O plugins-downloads.txt https://github.com/OpenRealms-MC/GameServer-Plugins/blob/dev/plugins-downloads.txt?raw=true
echo "    - Downloading core plugins..."
download_plugins "plugins-downloads.txt"
rm plugins-downloads.txt

# Download Mythic plugins if the user agreed
if [ "$DOWNLOAD_MYTHIC" = true ]; then
    wget -O mythic-plugins.txt https://github.com/OpenRealms-MC/GameServer-Plugins/blob/dev/mythic-plugins.txt?raw=true
    echo "    - Downloading community Mythic plugins..."
    download_plugins "mythic-plugins.txt"
    rm mythic-plugins.txt
fi

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
#    a server's console.
# - Press 'Ctrl + A' and then 'D' to leave (detach from) the console
#    without stopping the server.
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
echo ""
echo "!!! IMPORTANT WARNINGS !!!"
echo "The 'CraftEngine' plugin installed is a community version. It is limited to a maximum of 20 players."
echo "To unlock the full functionality, please replace it with the premium version."
if [ "$DOWNLOAD_MYTHIC" = true ]; then
    echo ""
    echo "You have installed the community versions of the Mythic plugins. These are outdated."
    echo "For full server functionality, it is strongly recommended to replace them with the purchased premium versions."
fi
echo "----------------------------------------------------------------"
