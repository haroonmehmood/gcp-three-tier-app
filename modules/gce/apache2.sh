#!/bin/bash
# Startup scripts already run as root, so no sudo is needed here.
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y apache2
systemctl enable --now apache2
