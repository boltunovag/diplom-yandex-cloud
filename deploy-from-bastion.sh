#!/bin/bash
# deploy-from-bastion.sh

set -e

BASTION_IP=$(terraform output -raw bastion_external_ip)
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

if [ ! -f ansible.cfg ]; then
    cat > ansible.cfg << 'CFG_EOF'
[defaults]
inventory = inventory.yml
host_key_checking = False
remote_user = ubuntu
private_key_file = ~/.ssh/yc-ed25519

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
CFG_EOF
fi

echo "🔍 Testing connectivity..."
ansible all -m ping

echo "🚀 Deploying web servers..."
ansible-playbook setup-webservers.yml

echo "✅ Deployment completed!"
EOF
