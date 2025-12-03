#!/bin/bash
set -e
BASTION_IP=$(terraform output -raw bastion_external_ip)
echo "🚀 Deploying from bastion ($BASTION_IP)..."

# Создаем структуру папок на бастионе
ssh -i ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP "mkdir -p ~/Diplom"

# Копируем  папку ansible
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

echo "📦 Installing web servers..."
ansible-playbook setup-webservers.yml

echo "📊 Installing Zabbix Server..."
ansible-playbook zabbix-setup.yml

echo "🔍 Installing Zabbix Agents..."
ansible-playbook zabbix-agents.yml

echo "🔍 Installing Elasticsearch..."
ansible-playbook elasticsearch-setup.yml

echo "👁️  Installing Kibana..."
ansible-playbook kibana-setup.yml

echo "Installing FileBeat..." 
ansible-playbook filebeat-webservers.yml

echo "🔧 Configuring Zabbix automation..."
ansible-playbook zabbix-automation.yml

echo "✅ Deployment completed!"
EOF
