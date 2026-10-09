#!/bin/bash
# Co-op on one computer: a host and a friend, two copies of the game talking over the network.
#   tests/net_test.sh [path to godot]
G=${1:-godot}
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
timeout 150 "$G" --headless --path . -s res://tests/net_host.gd > "$OUT/host.txt" 2>&1 &
H=$!
timeout 150 "$G" --headless --path . -s res://tests/net_client.gd > "$OUT/client.txt" 2>&1 &
C=$!
wait $H; HR=$?
wait $C; CR=$?
grep -hE "PASS|FAIL|SCRIPT ERROR|pass," "$OUT/host.txt" "$OUT/client.txt"
exit $((HR + CR))
