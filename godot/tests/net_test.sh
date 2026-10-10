#!/bin/bash
# Co-op on one computer: a host and a friend, two copies of the game talking over the network.
#   tests/net_test.sh [path to godot]           directly, host to friend
#   tests/net_test.sh [path to godot] relay     through a village server (relay/), run here too
G=${1:-godot}
MODE=${2:-direct}
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
# the latecomer waits for a file the host writes once the week has begun: clear away the last run's, or it sets off early
rm -f "$HOME/.local/share/godot/app_userdata/Peasant Defence/test_started.txt" "$HOME/.local/share/godot/app_userdata/Peasant Defence/test_code.txt"
R=""
if [ "$MODE" = "relay" ]; then
  timeout 160 "$G" --headless --path ../relay -s relay.gd > "$OUT/relay.txt" 2>&1 &
  R=$!
  export DTV_RELAY=127.0.0.1
  sleep 2
fi
timeout 150 "$G" --headless --path . -s res://tests/net_host.gd > "$OUT/host.txt" 2>&1 &
H=$!
timeout 150 "$G" --headless --path . -s res://tests/net_client.gd > "$OUT/client.txt" 2>&1 &
C=$!
timeout 150 "$G" --headless --path . -s res://tests/net_late.gd > "$OUT/late.txt" 2>&1 &
L=$!
wait $H; HR=$?
wait $C; CR=$?
wait $L; LR=$?
CR=$((CR + LR))
[ -n "$R" ] && kill $R 2>/dev/null
grep -hE "PASS|FAIL|SCRIPT ERROR|pass," "$OUT/host.txt" "$OUT/client.txt" "$OUT/late.txt"
[ "$MODE" = "relay" ] && grep -E "opened|joined|left|closed" "$OUT/relay.txt"
exit $((HR + CR))
