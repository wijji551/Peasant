#!/bin/bash
# Sets up the village server for Defend the Village! on a fresh Ubuntu machine (Oracle Cloud's free one is fine),
# and keeps it running: it starts again by itself if it stops, or when the machine restarts.
#
# On the server, as the usual "ubuntu" user, run:
#   curl -fsSL https://raw.githubusercontent.com/wijji551/Peasant/main/relay/setup.sh | bash
#
# Running it again later updates the village server to the newest version.
set -e
GODOT_VER="4.7.2-stable"
PORT=24566
REPO="https://raw.githubusercontent.com/wijji551/Peasant/main/relay"
DIR="$HOME/village"

case "$(uname -m)" in
  x86_64)  BUILD="linux.x86_64" ;;
  aarch64) BUILD="linux.arm64" ;;
  *) echo "This machine's processor ($(uname -m)) is not one Godot is built for."; exit 1 ;;
esac

echo "== Installing the few things needed"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y -q
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q unzip curl iptables-persistent

echo "== Fetching Godot $GODOT_VER ($BUILD)"
mkdir -p "$DIR"
cd "$DIR"
if [ ! -x "$DIR/godot" ] || [ "$(cat "$DIR/godot.version" 2>/dev/null)" != "$GODOT_VER-$BUILD" ]; then
  curl -fL -o godot.zip "https://github.com/godotengine/godot/releases/download/$GODOT_VER/Godot_v${GODOT_VER}_${BUILD}.zip"
  unzip -o -q godot.zip
  mv -f "Godot_v${GODOT_VER}_${BUILD}" godot
  chmod +x godot
  rm -f godot.zip
  echo "$GODOT_VER-$BUILD" > godot.version
fi

echo "== Fetching the village server"
curl -fsSL -o relay.gd "$REPO/relay.gd"
curl -fsSL -o project.godot "$REPO/project.godot"

echo "== Keeping it running"
sudo tee /etc/systemd/system/village.service > /dev/null <<UNIT
[Unit]
Description=Defend the Village! village server
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
WorkingDirectory=$DIR
ExecStart=$DIR/godot --headless --path $DIR -s relay.gd -- --port $PORT
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable village > /dev/null 2>&1
sudo systemctl restart village

echo "== Letting players in (UDP port $PORT)"
# Oracle's Ubuntu turns away everything but SSH; let the village server's port through, before that rule
if ! sudo iptables -C INPUT -p udp --dport $PORT -j ACCEPT 2>/dev/null; then
  sudo iptables -I INPUT 1 -p udp --dport $PORT -j ACCEPT
fi
sudo netfilter-persistent save > /dev/null 2>&1 || true

sleep 3
echo
if systemctl is-active --quiet village; then
  IP=$(curl -fsS https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
  echo "The village server is running."
  echo
  echo "    Its address:  $IP"
  echo
  echo "Put that address in the game: the handbook's Options, \"Village server\" (or tell Claude, and it will"
  echo "become the game's own default). Remember to open UDP port $PORT in Oracle's Security List too."
  echo "To see what it is doing:  journalctl -u village -f"
else
  echo "Something went wrong: the village server is not running. What it said:"
  sudo journalctl -u village -n 30 --no-pager
fi
