# The village server

A small program that lets players of Defend the Village! find each other from anywhere. It does not run the game: one
player still hosts each village. It gives each village a five-letter code and passes messages between the host and
the people who join. Everybody connects out to it, so nobody's router has to let anyone in, and it stays on when
you are not playing, so your friends can host their own villages whenever they like.

It runs on Godot's free Linux download, with no other software. One small server carries many villages at once.

## Setting it up on Oracle Cloud (free)

**1. An account.** Go to cloud.oracle.com and sign up for the Free Tier. They ask for a card to check you are a real
person; the "Always Free" machines are not charged. Pick a home region near you and your friends (UK South (London),
for example). It cannot be changed later.

**2. A machine.** In the Oracle console: the menu, then Compute, then Instances, then **Create instance**.
- Name: `village`.
- Image: **Canonical Ubuntu** (24.04).
- Shape: one marked **Always Free-eligible**: either *VM.Standard.A1.Flex* (Ampere; 1 OCPU and 6 GB is plenty) or
  *VM.Standard.E2.1.Micro*. If Oracle says there is no room for the Ampere one, try the Micro, or another time.
- Networking: make the network first (Networking, Virtual cloud networks, **Create VCN** with its wizard's internet
  connectivity), then here pick that network and its **public subnet**, and check **Automatically assign public IPv4
  address** is on. (Making a new subnet from this page can leave that switch greyed out, and the machine with no address.)
- SSH keys: **Generate a key pair for me**, and **Save private key**. Keep that file safe: it is how you get in.
- Create. After a minute or two it says *Running*, with a **Public IP address**. Note it down.

**3. Open the door.** On the instance's page, under *Primary VNIC*, click the **Subnet**, then the **Default Security
List**, then **Add Ingress Rules**:
- Source CIDR: `0.0.0.0/0`
- IP Protocol: **UDP**
- Destination Port Range: `24566`
- Add.

**4. Get in.** On Windows, open PowerShell and type (with your key file's real name and place, and the address):

    ssh -i "$HOME\Downloads\ssh-key-2026-10-09.key" ubuntu@YOUR.IP.ADDRESS

Say `yes` the first time. If Windows complains that the key is *unprotected*, run this once and try again:

    icacls "$HOME\Downloads\ssh-key-2026-10-09.key" /inheritance:r /grant:r "$($env:USERNAME):R"

**5. Set it up.** Now on the server, paste:

    curl -fsSL https://raw.githubusercontent.com/wijji551/Peasant/main/relay/setup.sh | bash

It takes a minute, and ends by saying *The village server is running* and its address.

**Or skip steps 4 and 5:** before Create, under the shape's *Advanced options*, *Initialization script*, choose *Paste
cloud-init script* and paste `relay/cloud-init.sh`. The machine sets itself up a few minutes after it starts, and
*SSH keys* can be *No SSH keys*. (This is how the game's own server was made.)

**6. Tell the game.** Either put the address in the game (the handbook, Options, *Village server*), or give it to
Claude and it becomes the game's own default, so nobody has to type it.

That is all. To update the village server later, run step 5 again.

## Looking after it

- See what it is doing: `journalctl -u village -f` (Ctrl+C to stop looking). It writes a line when a village opens,
  someone joins or leaves, and a village closes.
- Restart it: `sudo systemctl restart village`.
- It starts again by itself if it stops, and when the machine restarts.

## Trying it on one computer

    godot --headless --path relay -s relay.gd
    godot/tests/net_test.sh godot relay       # a host and a friend, through it
