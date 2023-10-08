# OTUS-DZ9
Cкрипт на языке Bash
=======
# Домашние задание по теме "Bash"

1. Написать скрипт для CRON, который раз в час будет формировать письмо и отправлять на заданную почту.
   Необходимая информация в письме:
	1.Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
	2.Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
	3.Ошибки веб-сервера/приложения c момента последнего запуска;
2. Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.
3. В письме должен быть прописан обрабатываемый временной диапазон.


Пишем скрипт check_log_file.sh


### 1.  Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова ‘ALERT’
        (файл лога и ключевое слово должны задаваться в /etc/sysconfig).

####    1.1 Создадим файл настроек /etc/sysconfig/watchlog

	touch /etc/sysconfig/watchlog
	echo  WORD='"ALERT"' >> /etc/sysconfig/watchlog
	echo  LOG=/var/log/watchlog.log >> /etc/sysconfig/watchlog
 
####    1.2 Cоздаем /var/log/watchlog.log и впишем туда клĀчевое слово ‘ALERT’

	touch /etc/sysconfig/watchlog
	tail /var/log/dmesg >> /var/log/watchlog.log
	echo -e "\nALERT\n" >> /var/log/watchlog.log
	tail /var/log/dmesg >> /var/log/watchlog.log
	echo -e "\nALERT\n" >> /var/log/watchlog.log
	tail /var/log/dmesg >> /var/log/watchlog.log


          
####    1.3 Cоздаем скрипт /opt/watchlog.sh

	ouch /opt/watchlog.sh
	echo '#!/bin/bash' >> /opt/watchlog.sh
	echo 'WORD=$1' >> /opt/watchlog.sh
	echo 'LOG=$2' >> /opt/watchlog.sh
	echo 'DATE=`date`' >> /opt/watchlog.sh
	echo 'if grep $WORD $LOG &> /dev/null' >> /opt/watchlog.sh
	echo 'then' >> /opt/watchlog.sh
	echo '  logger "$DATE: I found word, Master!"' >> /opt/watchlog.sh
	echo 'else' >> /opt/watchlog.sh
	echo 'exit 0' >> /opt/watchlog.sh
	echo 'fi' >> /opt/watchlog.sh


####    1.4 Добавляем права запуска скрипта /opt/watchlog.sh

        chmod +x /opt/watchlog.sh
           
####    1.5 Создаем unit для сервиса 

	touch /etc/systemd/system/watchlog.service
	chmod 664 /etc/systemd/system/watchlog.service
	cat <<'EOF1' > /etc/systemd/system/watchlog.service
	[Unit]
	Description=My watchlog service
	After=syslog.target
	[Service]
	User=root
	Type=oneshot
	EnvironmentFile=/etc/sysconfig/watchlog
	ExecStart=/opt/watchlog.sh $WORD $LOG
	[Install]
	WantedBy=multi-user.target
	EOF1

####    1.6 Запускаем  unit watchlog.service
	systemctl daemon-reload
        systemctl  start watchlog.service

####    1.7 Создаем unit для таймера

	touch /etc/systemd/system/watchlog.timer
        echo '[Unit]' >> /etc/systemd/system/watchlog.timer
        echo 'Description=Run watchlog script every 30 second' >>  /etc/systemd/system/watchlog.timer
        echo ' ' >>  /etc/systemd/system/watchlog.timer
        echo '[Timer]' >>  /etc/systemd/system/watchlog.timer
        echo 'OnActiveSec=1sec' >> /etc/systemd/system/watchlog.timer
        echo 'OnCalendar=*:*:0/30' >>  /etc/systemd/system/watchlog.timer
        echo 'Unit=watchlog.service' >>  /etc/systemd/system/watchlog.timer
        echo ' ' >>  /etc/systemd/system/watchlog.timer
        echo '[Install]' >>  /etc/systemd/system/watchlog.timer 
        echo ' WantedBy=multi-user.target' >>  /etc/systemd/system/watchlog.timer

         
####    1.8 Стартуем таймер

	systemctl daemon-reload
        systemctl start watchlog.timer
        
####    1.9 Проверяем /var/log/messages        
        
	timeout 40 tail -f /var/log/messages
         
### 2.  Задание 2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл

####    2.1 Установим необходимые программы

	yum install -y -q epel-release  
        yum install -y -q spawn-fcgi php php-cli httpd mod_fcgid
    	sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi
	sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi
        
####    2.2 Создаем unit-файл для spawn-fcgi
 
	touch /etc/systemd/system/spawn-fcgi.service
        chmod 664 /etc/systemd/system/spawn-fcgi.service
        cat <<'EOF2' >/etc/systemd/system/spawn-fcgi.service
	[Unit]
	Description=Spawn-fcgi startup service by Otus
	After=network.target
	
	[Service]
	Type=simple
	PIDFile=/var/run/spawn-fcgi.pid
	EnvironmentFile=/etc/sysconfig/spawn-fcgi
	ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
	KillMode=process

	[Install]
	WantedBy=multi-user.target
	EOF2
        
####    2.3 Запускаем и проверяем юнит

	systemctl daemon-reload
        systemctl enable --now spawn-fcgi.service
        systemctl status spawn-fcgi.service 
     
###    3. Дополнить unit-файл httpd (apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.


####    3.1 Установим  софт и настроим selinux.

	 yum install -y -q policycoreutils-python
         semanage port -m -t http_port_t -p tcp 8080
        
####    3.2 Скопируем и изменим файл сервиса httpd.service в шаблон

	cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service
        sed -i 's*EnvironmentFile=/etc/sysconfig/httpd*EnvironmentFile=/etc/sysconfig/%i*' /etc/systemd/system/httpd@.service

####    3.3 Скопируем и изменим файлы настройки сервиса httpd.service

	 cp /etc/sysconfig/httpd /etc/sysconfig/httpd-first 
         cp /etc/sysconfig/httpd /etc/sysconfig/httpd-second
         sed -i 's*#OPTIONS=*OPTIONS=-f /etc/httpd/conf/first.conf*' /etc/sysconfig/httpd-first
         sed -i 's*#OPTIONS=*OPTIONS=-f /etc/httpd/conf/second.conf*' /etc/sysconfig/httpd-second
         
####     3.4 Скопируем и изменим файлы настройки демона httpd"
         cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
         cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
         sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/second.conf
         echo "PidFile /var/run/httpd/httpd-first.pid" >> /etc/httpd/conf/first.conf
         echo "PidFile /var/run/httpd/httpd-second.pid" >> /etc/httpd/conf/second.conf
        
####    3.5 Запуcтим и проверим работу двух конфигураций apache на стандартном 80 порту и 8080 
	
	systemctl daemon-reload
        systemctl enable --now httpd@httpd-first.service
        systemctl enable --now httpd@httpd-second.service
        systemctl status httpd@httpd-first.service
        systemctl status httpd@httpd-second.service          
        ss -ntl

### Задание 1,2,3 выполнено. 
>>>>>>> 4145437 (The one)
