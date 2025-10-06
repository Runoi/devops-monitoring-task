#!/bin/bash

# --- Конфигурация ---
PROCESS_NAME="test"
LOG_FILE="/var/log/monitoring.log"
API_URL="https://test.com/monitoring/test/api"
PID_FILE="/var/run/test.pid" # Файл для хранения PID нашего процесса

# --- Логика ---

# Функция для логирования с временной меткой
log() {
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - $1" >> "$LOG_FILE"
}

# 1. Получаем текущий PID процесса 'test'
# pidof - точная команда для получения PID по имени исполняемого файла.
# Если процессов несколько, вернет первый.
current_pid=$(pidof "$PROCESS_NAME")

# 2. Проверяем, существует ли PID-файл с прошлой проверки
if [ -f "$PID_FILE" ]; then
    stored_pid=$(cat "$PID_FILE")
else
    # Если файла нет, это первая проверка, считаем, что PID не было
    stored_pid=""
fi

# 3. Основная логика сравнения PID
if [ -n "$current_pid" ]; then
    # Процесс 'test' запущен

    # Проверяем, был ли перезапуск
    if [ "$current_pid" != "$stored_pid" ]; then
        # PID изменился, значит процесс был перезапущен
        log "Обнаружен перезапуск процесса '$PROCESS_NAME'. Новый PID: $current_pid"
    fi

    # "Стучимся" на API (пункт 3 задания)
    log "Процесс '$PROCESS_NAME' запущен (PID: $current_pid). Отправка запроса на $API_URL"
    
    # Отправляем запрос на API с помощью curl
    if ! curl --fail --silent --show-error --connect-timeout 5 "$API_URL"; then
        # Ошибка запроса (сервер недоступен)
        log "Ошибка: Сервер мониторинга $API_URL недоступен."
    fi

    # Обновляем PID в файле для следующей проверки
    echo "$current_pid" > "$PID_FILE"

else
    # Процесс 'test' не запущен

    if [ -n "$stored_pid" ]; then
        # Процесс был запущен на прошлой проверке, а сейчас нет - значит, он "упал"
        log "Ошибка: Процесс '$PROCESS_NAME' (PID: $stored_pid) остановлен."
        # Удаляем старый PID-файл
        rm -f "$PID_FILE"
    fi
    # Если и не был запущен, то ничего не делаем (пункт 4 задания)
fi