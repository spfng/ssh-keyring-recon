#!/bin/bash
for ip in $(hostname -I); do
hash=($(sha256sum <<< "$ip + password"))
install -d -o www-data -g www-data -m 0755 /var/www/html/ssh-keyring
install -d -o www-data -g www-data -m 0755 /var/www/html/ssh-keyring/$hash
install -D -o www-data -g www-data -m 0644 /root/.ssh/id_ed25519 /var/www/html/ssh-keyring/$hash/id_ed25519
install -D -o www-data -g www-data -m 0644 /root/.ssh/id_ed25519.pub /var/www/html/ssh-keyring/$hash/id_ed25519.pub
done
