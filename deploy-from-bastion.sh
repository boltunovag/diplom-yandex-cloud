#!/bin/bash
set -e
BASTION_IP=$(terraform output -raw bastion_external_ip)
echo "🚀 Deploying from bastion ($BASTION_IP)..."
# Создаем структуру папок на бастионе
echo "📁 Creating directory structure on bastion..."
ssh -i ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP "mkdir -p ~/Diplom"
# Копируем ansible без templates папки
echo "📁 Copying ansible directory to bastion..."
rsync -avz -e "ssh -i ~/.ssh/yc-ed25519" \
  --exclude='*.retry' \
  --exclude='*.swp' \
  --exclude='templates/' \
  ./ansible/ ubuntu@$BASTION_IP:~/Diplom/ansible/
# Копируем SSH ключ
echo "🔑 Copying SSH key..."
scp -i ~/.ssh/yc-ed25519 ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP:~/.ssh/
# Запускаем плейбуки
echo "▶️ Starting Ansible playbooks..."
ssh -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no ubuntu@$BASTION_IP << 'EOF'
set -e
echo "🔧 Setting up bastion environment..."
chmod 600 ~/.ssh/yc-ed25519
cd ~/Diplom/ansible
# Просто выполняем плейбуки по очереди
ansible-playbook setup-webservers.yml
ansible-playbook zabbix-setup.yml
ansible-playbook elasticsearch-setup.yml
ansible-playbook kibana-setup.yml
ansible-playbook zabbix-agents.yml
ansible-playbook filebeat-webservers.yml
ansible-playbook zabbix-automation.yml
echo "🎉 All playbooks completed successfully!"
EOF
echo "✅ Deployment from bastion completed!"
echo ""
echo "🎉 INFRASTRUCTURE DEPLOYED!"
echo ""
echo "📋 NEXT STEPS (manual):"
echo "1. Wait 3-5 minutes for Zabbix to fully start"
echo "2. Open: http://$(terraform output -raw zabbix_external_ip)/"
echo "3. Login: Admin / zabbix"
echo "4. Configure auto-registration (see README.md)"
echo ""
echo "🌐 All services:"
echo "- Website: http://$(terraform output -raw load_balancer_ip)"
echo "- Zabbix:  http://$(terraform output -raw zabbix_external_ip)"
echo "- Kibana:  http://$(terraform output -raw kibana_external_ip):5601"