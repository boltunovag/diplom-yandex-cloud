#!/bin/bash
# set -e  # ← ВРЕМЕННО ОТКЛЮЧЕНО ДЛЯ ОТЛАДКИ
BASTION_IP=$(terraform output -raw bastion_external_ip)
echo "🚀 Deploying from bastion ($BASTION_IP)..."

# Создаем директории на bastion с помощью sudo
ssh -i ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP "sudo mkdir -p /home/ubuntu/Diplom && sudo chown -R ubuntu:ubuntu /home/ubuntu/Diplom"

# Копируем файлы Ansible
rsync -avz -e "ssh -i ~/.ssh/yc-ed25519" ./ansible/ ubuntu@$BASTION_IP:~/Diplom/ansible/

# Копируем SSH ключ
scp -i ~/.ssh/yc-ed25519 ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP:~/.ssh/

# Исполняем команды на bastion
ssh -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << 'EOF'
# Устанавливаем права на ключ
chmod 600 ~/.ssh/yc-ed25519

# Создаем .ansible директорию с правильными правами
mkdir -p ~/.ansible/tmp
chmod 700 ~/.ansible

# Копируем SSH ключ на внутренние хосты (если нужно)
cd ~/Diplom/ansible

# Проверяем доступность хостов
echo "🔍 Testing SSH connections to internal hosts..."
ansible all -m ping -i inventory.yml

echo "📦 Installing web servers..."
ansible-playbook setup-webservers.yml -i inventory.yml

echo "📊 Installing Zabbix Server..."
ansible-playbook zabbix-setup.yml -i inventory.yml

echo "🔍 Installing Zabbix Agents..."
ansible-playbook zabbix-agents.yml -i inventory.yml

# Сначала установим Docker на все хосты
echo "🐳 Installing Docker on all hosts..."
ansible-playbook install-docker.yml -i inventory.yml

echo "🔍 Installing Elasticsearch, Kibana, Filebeat..."
ansible-playbook elk-stack.yml -i inventory.yml

echo "✅ Deployment completed!"
EOF

echo "✅ Deployment from bastion completed!"
echo ""
echo "🎉 INFRASTRUCTURE DEPLOYED!"
echo ""
echo "📋 NEXT STEPS (manual):"
echo "1. Wait 3-5 minutes for Kibana to fully initialize"
echo "2. Open: http://$(terraform output -raw kibana_external_ip):5601"
echo "3. Go to Dashboard → 'Filebeat nginx logs' to see logs"
echo ""
echo "🌐 All services:"
echo "- Website: http://$(terraform output -raw load_balancer_ip)"
echo "- Zabbix:  http://$(terraform output -raw zabbix_external_ip)"
echo "- Kibana:  http://$(terraform output -raw kibana_external_ip):5601"