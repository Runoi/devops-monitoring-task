#!/bin/bash

# --- Конфигурация ---
# Убираем LOG_FILE, он нам больше не нужен
PROCESS_NAME="test"
API_URL="https://test.com/monitoring/test/api"
PID_FILE="/var/run/test.pid"

# --- Логика ---

current_pid=$(systemctl show --property MainPID --value test.service)

if [ -f "$PID_FILE" ]; then
    stored_pid=$(cat "$PID_FILE")
else
    stored_pid=""
fi

if [ -n "$current_pid" ]; then
    if [ "$current_pid" != "$stored_pid" ]; then
        echo "Обнаружен перезапуск процесса '$PROCESS_NAME'. Новый PID: $current_pid"
    fi

    echo "Процесс '$PROCESS_NAME' запущен (PID: $current_pid). Отправка запроса на $API_URL"
    
    if ! curl --fail --silent --show-error --connect-timeout 5 "$API_URL"; then
        echo "Ошибка: Сервер мониторинга $API_URL недоступен."
    fi

    echo "$current_pid" > "$PID_FILE"

else
    if [ -n "$stored_pid" ]; then
        echo "Ошибка: Процесс '$PROCESS_NAME' (PID: $stored_pid) остановлен."
        rm -f "$PID_FILE"
    fi
fi