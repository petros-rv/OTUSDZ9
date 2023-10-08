# OTUS-DZ9
Cкрипт на языке Bash
=================================
# Домашние задание по теме "Bash"

1. Написать скрипт для CRON, который раз в час будет формировать письмо и отправлять на заданную почту.
   Необходимая информация в письме:
	1.Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
	2.Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
	3.Ошибки веб-сервера/приложения c момента последнего запуска;
	4.Все коды возврата веб-сервера/приложения c момента последнего запуска;
2. Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.
3. В письме должен быть прописан обрабатываемый временной диапазон.


### 1.  Пишем скрипт, который будет анаизировать log файл  веб сервера NGINX.
            
####    1.1 Считаем количество строк в  лог файле access-4560-644067.log и записываем в переменную kolStr

kolStr=$(cat ./access-4560-644067.log | wc -l)

####    1.2 Проверим наличие файла nomer_posl_str, если есть считаем данные если нет задаим переменной nomerStr значение 1 

if [ -f ./nomer_posl_str ]; then nomerStr=$(cat ./nomer_posl_str)
let "nomerStr+=1"
else
nomerStr=1
fi

####    1.3 Зададим функцию определения периода времени getTimePeriod

getTimePeriod() {
  local timeN=$(awk '{print $4 $5}' ./access-4560-644067.log | sed 's/\[//; s/\]//' | sed -n "$1"p)
  local timeF=$(awk '{print $4 $5}' ./access-4560-644067.log | sed 's/\[//; s/\]//' | sed -n "$2"p)
  echo -e "$timeN - $timeF"
}

####    1.4 Анализ ip адресов (с количеством запроов от 5) с указанием кол-ва запросов c момента последнего запуска скрипта

ip=$(awk '{if (NR >= '$nomerStr') print $1}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ IP Количество"} {if($1>=5) n=n+$1; if($1>=5) print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)

####    1.5 Анализ URL запросов (с количеством запроов от 5) с с указанием кол-ва запросов c момента последнего запуска скрипта

addresses=$(awk '($9<400) && !($7==400) {if (NR >= '$nomerStr') print $7}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ Строка_адреса  Количество"} {if($1>=5) n=n+$1; if($1>=5) print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)

####    1.6 Ошибки веб-сервера NGINX с указанием кол-ва запросов c момента последнего запуска скрипта

servers=$(awk '{if (NR >= '$nomerStr') print $9}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ Код_возврата  Количество"} {n=n+$1;print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)

####    1.7 Все коды возврата веб-сервера NGINX с указанием кол-ва запросов c момента последнего запуска скрипта

errors=$(awk '($9>=400) || ($9 ~/-/){if (NR >= '$nomerStr') print $9}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ Код_ошибки  Количество"} {n=n+$1;print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)

####    1.8 Отправим результат на почту (root@localhost)

echo -e "\nДанные за период:$period\n\n"IP адреса c которых поступает больше 5 запросов :"\n$ip\n\n"Запрашиваемые больше 5 раз URL адреса:"\n$addresses\n\n"Все ошибки:"\n$errors\n\n"Все коды возврата сервера"\n$servers" | mail -s "CHEK LOG FILE NGINX " root@localhost 


### 2.  Предтвращение одновременного запуска скрипта check_log_file.sh обеспечим использовав программу flock 

/usr/bin/flock /tmp/check_log_file.lock 

### 3.  Создадим задание в CRON на запуск каждый час скрипта check_log_file.sh 

crontab -e
0**** /usr/bin/flock /tmp/check_log_file.lock /var/log/nginx/check_log_file.sh

### Прикрепленные файлы:

1. [/log0/access-4560-644067.log] - log файл укороченный
2. [/log1/access-4560-644067.log] - log файл полный
3. [check_log_file.sh]            - скрипт анализирующий log файл access-4560-644067.log
4. [mail_check_result.txt]        - результат работы скрипта check_log_file.sh

[/log0/access-4560-644067.log]:https://github.com/petros-rv/OTUSDZ9/blob/main/log0/access-4560-644067.log
[/log1/access-4560-644067.log]:https://github.com/petros-rv/OTUSDZ9/blob/main/log1/access-4560-644067.log
[check_log_file.sh]:https://github.com/petros-rv/OTUSDZ9/blob/main/check_log_file.sh
[mail_check_result.txt]:https://github.com/petros-rv/OTUSDZ9/blob/main/mail_check_result.txt

# Задание выполнено. 

