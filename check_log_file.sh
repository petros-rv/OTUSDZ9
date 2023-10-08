#!/bin/bash
# Считаем количество строк в  лог файле и записываем в переменную kolStr
kolStr=$(cat ./access-4560-644067.log | wc -l)
# Проверим наличие файла nomer_posl_str, если есть считаем данные если нет задаим переменной nomerStr значение 1 
if [ -f ./nomer_posl_str ]; then nomerStr=$(cat ./nomer_posl_str)
let "nomerStr+=1"
else
nomerStr=1
fi
# Зададим функцию определения периода времени getTimePeriod
getTimePeriod() {
  local timeN=$(awk '{print $4 $5}' ./access-4560-644067.log | sed 's/\[//; s/\]//' | sed -n "$1"p)
  local timeF=$(awk '{print $4 $5}' ./access-4560-644067.log | sed 's/\[//; s/\]//' | sed -n "$2"p)
  echo -e "$timeN - $timeF"
}
# Период времени запишем в переменную pp
period="$(getTimePeriod "$nomerStr" "$kolStr")"
# Определение количества запросов с IP адресов
ip=$(awk '{if (NR >= '$nomerStr') print $1}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ IP Количество"} {if($1>=5) n=n+$1; if($1>=5) print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)
# Определение кооличества адресов
addresses=$(awk '($9<400) && !($7==400) {if (NR >= '$nomerStr') print $7}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ Строка_адреса  Количество"} {if($1>=5) n=n+$1; if($1>=5) print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)
# все коды возврата сервера c момента последнего запуска
servers=$(awk '{if (NR >= '$nomerStr') print $9}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ Код_возврата  Количество"} {n=n+$1;print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)
# все ошибки сервера
errors=$(awk '($9>=400) || ($9 ~/-/){if (NR >= '$nomerStr') print $9}' ./access-4560-644067.log | sort | uniq -c |sort -nr |awk 'BEGIN {print "\n№ Код_ошибки  Количество"} {n=n+$1;print FNR, $2,$1} END {print "-", "ИТОГО",n}'|column -t)
# Отправка почты
echo -e "\nДанные за период:$period\n\n"IP адреса c которых поступает больше 5 запросов :"\n$ip\n\n"Запрашиваемые больше 5 раз URL адреса:"\n$addresses\n\n"Все ошибки:"\n$errors\n\n"Все коды возврата сервера"\n$servers" | mail -s "CHEK LOG FILE NGINX " root@localhost
# Запишем количество строк в файл npstr
echo $kolStr > ./nomer_posl_str
