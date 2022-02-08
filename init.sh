#!/bin/bash
sudo apt -y update
sudo apt -y install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt -y install ansible
#sudo chmod 400 ssh-keys/key1
#sudo chmod 400 ssh-keys/key2
