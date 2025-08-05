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
