#!/bin/bash
# deploy-from-bastion.sh

set -e

BASTION_IP=$(terraform output -raw bastion_external_ip)

echo "🚀 Deploying from bastion ($BASTION_IP)..."

# Создаем структуру папок на бастионе
ssh -i ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP "mkdir -p ~/Diplom"

# Копируем ТОЛЬКО папку ansible
rsync -avz -e "ssh -i ~/.ssh/yc-ed25519" \
  ./ansible/ ubuntu@$BASTION_IP:~/Diplom/ansible/

# Копируем SSH ключ
scp -i ~/.ssh/yc-ed25519 ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP:~/.ssh/

# Запускаем деплой
ssh -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << 'EOF'
set -e

echo "🔧 Setting up bastion environment..."
chmod 600 ~/.ssh/yc-ed25519

cd ~/Diplom/ansible

echo "🎯 Running deployment..."
ansible-playbook setup-webservers.yml
ansible-playbook zabbix-setup.yml  
ansible-playbook zabbix-agents.yml

echo "✅ Deployment completed!"
EOF