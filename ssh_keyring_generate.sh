#!/bin/bash
ssh-keygen -q -t ed25519 -N "" -C "" -f /root/.ssh/id_ed25519
install -D -o root -g root -m 0644 /root/.ssh/id_ed25519.pub /root/.ssh/authorized_keys
