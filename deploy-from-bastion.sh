#!/bin/bash
# deploy-from-bastion.sh

set -e

BASTION_IP=$(terraform output -raw bastion_external_ip)
LOAD_BALANCER_IP=$(terraform output -raw load_balancer_ip)
ZABBIX_IP=$(terraform output -raw zabbix_external_ip)

echo "🚀 Deploying from bastion ($BASTION_IP)..."

rsync -avz -e "ssh -i ~/.ssh/yc-ed25519" \
  --exclude='.git' \
  --exclude='terraform.tfstate*' \
  --exclude='key.json' \
  ./ ubuntu@$BASTION_IP:~/Diplom/

scp -i ~/.ssh/yc-ed25519 ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP:~/.ssh/

ssh -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << EOF
set -e

echo "🔧 Setting up bastion environment..."
chmod 600 ~/.ssh/yc-ed25519

cd ~/Diplom/ansible

# Экспортируем переменные для плейбука
export LOAD_BALANCER_IP='$LOAD_BALANCER_IP'
export ZABBIX_IP='$ZABBIX_IP'

echo "🎯 Running complete deployment..."
ansible-playbook deploy-all.yml

echo "✅ All playbooks executed successfully!"
EOF