#!/usr/bin/env python3
"""Writes out/version.json: the note the game reads from GitHub to see whether a newer build is out.

    python3 tools/release_info.py [engine]      engine is the Godot the pack was made with, as "4.7"
"""
import hashlib, json, os, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ver = json.load(open(os.path.join(root, "godot", "version.json"), encoding="utf-8"))
pack = os.path.join(root, "out", "thornhallow.pck")
data = open(pack, "rb").read()
note = {
    "build": int(ver["build"]),
    "what": ver.get("what", ""),
    "engine": sys.argv[1] if len(sys.argv) > 1 else "4.7",
    "pack": "thornhallow.pck",
    "size": len(data),
    "sha256": hashlib.sha256(data).hexdigest(),
}
json.dump(note, open(os.path.join(root, "out", "version.json"), "w", encoding="utf-8"), indent=1)
print(json.dumps(note))
