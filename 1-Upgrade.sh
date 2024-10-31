#!/bin/sh
#This script will upgrade the factory default state OS from Debian Buster to Debian Bullseye on UniFi Cloud Key Model: UCK-G2-PLUS
#This script will disable or remove most UniFi packages, the device will no longer function as a Cloud Key for UniFi devices, but Emergency Recovery UI still works.
#****It is highly recommended to factory reset the Cloud Key before running script the first time****
#Factory reset Cloud Key: sudo ubnt-systool reset2defaults
#Default SSH user: root
#Default SSH password: ubnt
#Download script: sudo https://raw.githubusercontent.com/meokgo/UCK-G2-PLUS/refs/heads/main/1-Upgrade.sh
#Make script executable: sudo chmod +x 1-Upgrade.sh
#Run script: sudo ./1-Upgrade.sh

