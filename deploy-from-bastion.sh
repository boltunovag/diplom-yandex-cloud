#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_DIR="logs"
LOCAL_LOG="$LOG_DIR/deploy-$TIMESTAMP.log"
BASTION_LOG="/tmp/deploy-$TIMESTAMP.log"

echo -e "${YELLOW}🚀 Starting deployment at $(date)${NC}"
echo -e "${BLUE}📝 Local log: $LOCAL_LOG${NC}"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOCAL_LOG") 2>&1

# Get bastion IP
BASTION_IP=$(terraform output -raw bastion_external_ip 2>/dev/null || echo "")
if [ -z "$BASTION_IP" ]; then
    echo -e "${RED}❌ Cannot get bastion IP${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Bastion IP: $BASTION_IP${NC}"

# Создаем скрипт для выполнения на бастионе
cat > /tmp/deploy-script.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

LOG_FILE="/tmp/deploy-$(date +%s).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== DEPLOYMENT START: $(date) ==="
echo "Working directory: $(pwd)"
echo "User: $(whoami)"
echo ""

cd ~/ansible || { echo "ERROR: No ansible directory"; exit 1; }

echo "📋 Files in ansible directory:"
ls -la *.yml 2>/dev/null || echo "No YAML files found"
echo ""

# Check for Docker playbook
DOCKER_FILE="install-docker.yml"
if [ ! -f "$DOCKER_FILE" ]; then
    echo "⚠️  install-docker.yml not found, searching alternatives..."
    ALT_FILE=$(find . -name "*docker*.yml" -o -name "*Docker*.yml" 2>/dev/null | head -1)
    if [ -n "$ALT_FILE" ]; then
        echo "Found: $ALT_FILE"
        DOCKER_FILE="$ALT_FILE"
    else
        echo "❌ No Docker playbook found!"
        exit 1
    fi
fi

echo "🔍 Testing connectivity..."
ansible all -m ping || {
    echo "❌ Connectivity test failed"
    exit 1
}

echo ""
echo "1️⃣  Installing Docker from: $DOCKER_FILE"
if ! ansible-playbook "$DOCKER_FILE" -v; then
    echo "❌ FAILED: Docker installation"
    exit 1
fi

echo ""
echo "2️⃣  Setting up web servers"
if ! ansible-playbook setup-webservers.yml -v; then
    echo "❌ FAILED: Web servers"
    exit 1
fi

echo ""
echo "3️⃣  Deploying Zabbix"
if ! ansible-playbook zabbix-setup.yml -v; then
    echo "❌ FAILED: Zabbix"
    exit 1
fi

echo ""
echo "4️⃣  Installing Zabbix agents"
if ! ansible-playbook zabbix-agents.yml -v; then
    echo "❌ FAILED: Zabbix agents"
    exit 1
fi

echo ""
echo "5️⃣  Deploying ELK stack"
if ! ansible-playbook elk-stack.yml -v; then
    echo "❌ FAILED: ELK stack"
    exit 1
fi

echo ""
echo "=== DEPLOYMENT COMPLETE: $(date) ==="
echo "✅ All playbooks executed successfully"

# Save log path to a known location
echo "$LOG_FILE" > /tmp/deploy-log-path.txt
SCRIPT_EOF

# Копируем файлы на бастион
echo -e "${YELLOW}📦 Copying files to bastion...${NC}"
scp -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no -q \
    /tmp/deploy-script.sh ubuntu@$BASTION_IP:/tmp/ 2>&1

# Копируем ansible директорию если нужно
if [ -d "ansible" ]; then
    echo "Copying Ansible directory..."
    rsync -avz -e "ssh -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no" \
        --exclude='*.retry' --exclude='*.log' \
        ansible/ ubuntu@$BASTION_IP:~/ansible/ 2>&1 | tail -5
fi

echo -e "${YELLOW}🛠️  Executing on bastion...${NC}"
echo -e "${BLUE}=== Output from bastion (live) ===${NC}"

# Запускаем на бастионе и сохраняем вывод
ssh -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no -T ubuntu@$BASTION_IP \
    "chmod +x /tmp/deploy-script.sh && /tmp/deploy-script.sh" 2>&1 | \
    tee -a "$LOCAL_LOG" &
    
SSH_PID=$!

# Ждем завершения с таймаутом
wait $SSH_PID 2>/dev/null
SSH_EXIT=$?

echo -e "${BLUE}=== End of bastion output ===${NC}"

# Пытаемся получить лог с бастиона даже при ошибке
echo -e "${YELLOW}📥 Retrieving logs from bastion...${NC}"
scp -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no -q \
    ubuntu@$BASTION_IP:/tmp/deploy-*.log ./bastion-deploy.log 2>/dev/null || \
    scp -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no -q \
        ubuntu@$BASTION_IP:/tmp/deploy-log-path.txt ./log-path.txt 2>/dev/null

if [ -f "log-path.txt" ]; then
    LOG_PATH=$(cat log-path.txt)
    scp -i ~/.ssh/yc-ed25519 -o StrictHostKeyChecking=no -q \
        ubuntu@$BASTION_IP:"$LOG_PATH" ./bastion-deploy.log 2>/dev/null || true
fi

# Анализ результатов
if [ $SSH_EXIT -eq 0 ]; then
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    
    # Показываем доступы
    echo ""
    echo -e "${GREEN}📊 Service URLs:${NC}"
    LB_IP=$(terraform output -raw load_balancer_ip 2>/dev/null || echo "N/A")
    ZABBIX_IP=$(terraform output -raw zabbix_external_ip 2>/dev/null || echo "N/A")
    KIBANA_IP=$(terraform output -raw kibana_external_ip 2>/dev/null || echo "N/A")
    
    echo "🌐 Website: http://$LB_IP"
    echo "📊 Zabbix: http://$ZABBIX_IP (Login: Admin / Password: zabbix)"
    echo "🔍 Kibana: http://$KIBANA_IP:5601"
    echo "🔑 Bastion SSH: ssh -i ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP"
    
    # Сохраняем summary
    cat > deploy-summary.txt << EOF
Deployment completed: $(date)
Bastion: $BASTION_IP
Website: http://$LB_IP
Zabbix: http://$ZABBIX_IP
Kibana: http://$KIBANA_IP:5601
Log file: $LOCAL_LOG
EOF
    
    echo -e "${GREEN}📄 Summary saved to: deploy-summary.txt${NC}"
    
else
    echo -e "${RED}❌ Deployment failed with exit code: $SSH_EXIT${NC}"
    echo ""
    
    # Проверяем логи
    if [ -f "./bastion-deploy.log" ]; then
        echo -e "${YELLOW}📋 Last 20 lines from bastion log:${NC}"
        tail -20 ./bastion-deploy.log
        echo ""
        echo -e "${YELLOW}🔍 Full log: ./bastion-deploy.log${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not retrieve bastion log${NC}"
    fi
    
    echo -e "${YELLOW}🚨 Debug steps:${NC}"
    echo "1. Check local log: less $LOCAL_LOG"
    echo "2. Connect to bastion: ssh -i ~/.ssh/yc-ed25519 ubuntu@$BASTION_IP"
    echo "3. Check manually: cd ansible && ansible-playbook install-docker.yml -vvv"
    
    exit 1
fi