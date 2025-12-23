#!/bin/bash

IP_b=$(terraform output -raw bastion_external_ip)
K=~/.ssh/yc-ed25519
ssh -i $K ubuntu@"$IP_b" "sudo chown -R ubuntu:ubuntu /home/ubuntu/Diplom"
rsync -avz -e "ssh -i $K" ansible/ ubuntu@"$IP_b":~/Diplom/ansible
scp -i $K $K ubuntu@"$IP_b":~/.ssh/
ssh -i $K -o StrictHostKeyChecking=no ubuntu@"$IP_b" << 'EOF'
chmod 600 ~/.ssh/yc-ed25519
mkdir -p ~/.ansible/tmp
chmod 700 ~/.ansible
#echo "🔍 Testing folders..."
cd Diplom/ansible
ls -l
#ansible all -m ping -i inventory.yml
EOF


