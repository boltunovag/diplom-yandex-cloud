#!/bin/bash
echo "🌐 Генерация тестового трафика для проверки сервисов..."

LOAD_BALANCER_IP=$(terraform output -raw load_balancer_ip)
echo "Target: http://$LOAD_BALANCER_IP"

echo "Отправляем 20 запросов..."
for i in {1..20}; do
  echo "Запрос $i..."
  curl -s "http://$LOAD_BALANCER_IP?test=$i" | grep -i "<h1>"
  sleep 1 
done

echo "✅ Тестовый трафик отправлен!"
