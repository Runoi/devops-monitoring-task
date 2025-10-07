# Используем образ с systemd
FROM ubuntu:22.04

# Устанавливаем нужные утилиты
RUN apt-get update && apt-get install -y procps curl systemd dos2unix && rm -rf /var/lib/apt/lists/*

# Копируем наш скрипт и делаем его исполняемым
COPY src/monitor.sh /usr/local/bin/monitor.sh
RUN dos2unix /usr/local/bin/monitor.sh
RUN chmod +x /usr/local/bin/monitor.sh

# Копируем systemd-юниты
COPY systemd/monitor.service /etc/systemd/system/monitor.service
COPY systemd/monitor.timer /etc/systemd/system/monitor.timer

# Создаем фальшивый "test" процесс, который теперь СОЗДАЕТ PID-файл
# $$ - это специальная переменная в bash, которая содержит PID текущего процесса
RUN echo '#!/bin/bash\necho $$ > /var/run/test.pid\necho "Это тестовый процесс..."\nsleep infinity' > /usr/local/bin/test
RUN chmod +x /usr/local/bin/test

# Создаем сервис для нашего "test" процесса
# Важно: используем Type=simple, чтобы $$ работал корректно
RUN echo '[Unit]\nDescription=Fake test process\n\n[Service]\nType=simple\nExecStart=/usr/local/bin/test\nRestart=always\n\n[Install]\nWantedBy=multi-user.target' > /etc/systemd/system/test.service

# Включаем наш таймер и тестовый сервис
RUN systemctl enable monitor.timer
RUN systemctl enable test.service

# Указываем команду для запуска systemd
CMD ["/lib/systemd/systemd"]