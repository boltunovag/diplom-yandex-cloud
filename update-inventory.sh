#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Creating FQDN-only inventory...${NC}"

# Создаем директорию ansible если её нет
mkdir -p ansible

# Создаем inventory ТОЛЬКО с FQDN (без IP)
cat > ansible/inventory.yml << 'INVENTORY_EOF'
---
all:
  children:
    webservers:
      hosts:
        web-1:
          ansible_host: web-1.ru-central1.internal
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/yc-ed25519
          ansible_ssh_common_args: -o ProxyCommand="ssh -W %h:%p -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/yc-ed25519 ubuntu@bastion.ru-central1.internal"
        web-2:
          ansible_host: web-2.ru-central1.internal
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/yc-ed25519
          ansible_ssh_common_args: -o ProxyCommand="ssh -W %h:%p -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/yc-ed25519 ubuntu@bastion.ru-central1.internal"
    bastion:
      hosts:
        bastion-host:
          ansible_host: bastion.external.ru-central1.internal
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/yc-ed25519
    monitoring:
      hosts:
        zabbix:
          ansible_host: zabbix.external.ru-central1.internal
          ansible_user: ubuntu
          ansible_ssh_private_key_file: ~/.ssh/yc-ed25519
INVENTORY_EOF

echo -e "${GREEN}✅ Pure FQDN inventory created${NC}"

# Проверяем синтаксис
echo -e "${YELLOW}🔍 Validating YAML syntax...${NC}"
if python3 -c "import yaml; yaml.safe_load(open('ansible/inventory.yml'))" 2>/dev/null; then
    echo -e "${GREEN}✅ YAML syntax is valid${NC}"
else
    echo -e "${RED}❌ YAML syntax error${NC}"
    exit 1
fi

# Тестируем
cd ansible
echo -e "${YELLOW}🔍 Testing FQDN resolution...${NC}"

# Проверяем резолвятся ли FQDN
for host in "bastion.external.ru-central1.internal" "zabbix.external.ru-central1.internal" "web-1.ru-central1.internal" "web-2.ru-central1.internal"; do
    if host "$host" > /dev/null 2>&1; then
        echo -e "  ✅ $host resolves"
    else
        echo -e "  ⚠️  $host does not resolve (may need internal DNS)"
    fi
done

echo -e "${YELLOW}🔍 Testing Ansible connectivity...${NC}"

if ansible-inventory --list > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ansible can parse inventory${NC}"
    
    # Тестируем доступность (может не работать без правильного DNS)
    if ansible bastion -m ping; then
        echo -e "${GREEN}✅ Bastion is reachable via FQDN${NC}"
    else
        echo -e "${YELLOW}⚠️  Bastion may need external DNS setup${NC}"
    fi
else
    echo -e "${RED}❌ Ansible cannot parse inventory${NC}"
fi

cd ..

echo -e "${GREEN}🎉 FQDN inventory created!${NC}"
echo -e "${BLUE}📝 This is a permanent solution - no more IP dependencies!${NC}"