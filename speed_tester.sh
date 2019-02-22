#!/bin/bash

### VARIABLES ###
#URL="http://ovh.net/files/10Mio.dat"
URL="http://ovh.net/files/1Mio.dat"
#URL="http://seldongroup.ru/f/seldonfaq-1.pdf"

CURL_COMMAND="curl -OLs -4 $URL --write-out \"%{size_download};%{speed_download};%{time_connect};%{time_namelookup};%{time_total};\""
OFILE=/home/eg/Tests/result.txt
TRIES=3

LOGFILE=/var/log/modems.log

DBUSER="user"
PGPASSWORD="password"
DATABASE="db"
DBTABLE="db.table"
DBHOST="127.0.0.1"

interfaces="tele2 sbt"
interfaces_array=(${interfaces})

DEBUG=false

### VARIABLES END ###

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cd /tmp

if [ "$DEBUG" = true ]; then
        dhclient="/sbin/dhclient -v"

elif [ "$DEBUG" = false ]; then
        dhclient="/sbin/dhclient"
fi

gather_data() {
        CURL_OUTPUT=`echo $1 | sed 's/"//g'`
        dt=\'`date +%m-%d-%Y\ %H:%M:%S`\'
        operator=\'$2\'

        local_pub_ip=\'`curl -s ipinfo.io/ip`\'

        size_download=`echo $CURL_OUTPUT | cut -d';' -f1`

        speed_download=`echo $CURL_OUTPUT | cut -d';' -f2`
        speed_download=${speed_download%.*}
        let "speed_download= $speed_download * 8"

        time_connect=`echo $CURL_OUTPUT | cut -d';' -f3`
        time_namelookup=`echo $CURL_OUTPUT | cut -d';' -f4`
        time_total=`echo $CURL_OUTPUT | cut -d';' -f5`

        echo $CURL_OUTPUT
        echo "PGPASSWORD=sbtele psql -h $DBHOST -U $DBUSER -d $DATABASE -c \"INSERT INTO $DBTABLE (dt, operator, local_pub_ip, size_download, speed_download, time_connect, time_namelookup, time_total) VALUES($dt, $operator, $local_pub_ip, $size_download, $speed_download, $time_connect, $time_namelookup, $time_total);\""

        PGPASSWORD=sbtele psql -h $DBHOST -U $DBUSER -d $DATABASE -c "INSERT INTO $DBTABLE (dt, operator, local_pub_ip, size_download, speed_download, time_connect, time_namelookup, time_total) VALUES($dt, $operator, $local_pub_ip, $size_download, $speed_download, $time_connect, $time_namelookup, $time_total);"

}


download () {
        for i in `seq $TRIES`; do

                DATE="`date +%m-%d-%Y\ %H:%M:%S`"

                CURL_OUTPUT=`$CURL_COMMAND`
                [[ $? -eq 0 ]] && echo "$DATE ::: curl susccessfull for $1, result:   $CURL_OUTPUT" >> $LOGFILE
                gather_data $CURL_OUTPUT $1
        done
}

disable_ifs () {
for IF in "${interfaces_array[@]}"; do
        $dhclient -r $IF &>> $LOGFILE
        ip link set down $IF
done

}

enable_if() {
        ip link set up $1
        $dhclient $1 &>> $LOGFILE
        sleep 5 
}

check_ip() {
        DATE="`date +%m-%d-%Y\ %H:%M:%S`"
        #IP_ADDR=`ip -4 a show dev $1 | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]" | head -1`
        IP_ADDR=`ip -4 a show dev $1 | wc -l`

        #if [ -z "$IP_ADDR" ]; then
        #       echo "$DATE :::  $IP_ADDR assigned to $1" >> $LOGFILE
        #else
        #       echo "$DATE :::  no IP assigned to $1" >> $LOGFILE
        #fi

        if [ "$IP_ADDR" -eq 0 ]; then
                echo "$DATE :::  ***NO*** IP assigned to $1" >> $LOGFILE
        else
                echo "$DATE :::  IP assigned to $1" >> $LOGFILE
        fi

}

main2 () {

for M in "${interfaces_array[@]}"; do

        DATE="`date +%m-%d-%Y\ %H:%M:%S`"
        echo "$DATE :::  Started speed test for $M" >> $LOGFILE

        disable_ifs
        sleep 10

        enable_if $M
        sleep 5

        check_ip $M

        if [ "$M" = "sbt" ]; then
                OPERATOR="Sberbank"
        elif [ "$M" = "tele2" ]; then
                OPERATOR="Tele2"
        fi

        download $OPERATOR

done

disable_ifs
}


main2
