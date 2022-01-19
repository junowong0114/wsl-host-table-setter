#!/bin/bash
set -e
set -o pipefail

usage() {
  echo "Usage:"
  printf "hosts.sh [-f CONFIG_FILE] \n\n"
  echo "Description:"
  echo "-f, CONFIG_FILE       The path of config.yml [default \"~/.hosts/config.yml\"]"
  exit -1
}

CONFIG_FILE=~/.hosts/config.yml

while getopts 'f:h' OPT; do
  case $OPT in
    f) CONFIG_FILE=$OPTARG;;
    h) usage;;
    ?) ;;
  esac
done

declare -a HOSTNAMES
HOSTNAMES=($(cat $CONFIG_FILE | grep -e '^[^ ].*' | perl -pe "s|(.*):|\1|"))

echo "Select a hostname to be configured:"
declare -a OPTIONS
OPTIONS+=("Disable host table setting")
ACTIVE=false

select HOSTNAME in ${HOSTNAMES[@]}; do
    while read line; do
        if [[ $ACTIVE == 'true' ]]; then
            if [[ ! $line =~ ^-.*$ ]]; then
                break
            fi;

            desc=$(echo $line | perl -pe "s|- [\"']*(.*):((?:[0-9]+\.){3}[0-9]+)[\"']*|\1|")
            ip=$(echo $line | perl -pe "s|- [\"']*(.*):((?:[0-9]+\.){3}[0-9]+)[\"']*|\2|")

            OPTIONS+=("$ip ($desc)")
        fi

        if [[ $line == $HOSTNAME: ]]; then
            ACTIVE=true
        fi
    done < $CONFIG_FILE
    break
done

HOST_TABLE_FILE="/mnt/c/Windows/System32/drivers/etc/hosts"

printf "\nSelect an ip to be set to $HOSTNAME:\n"
select OPTION in "${OPTIONS[@]}"; do
    if [[ $OPTION == 'Disable host table setting' ]]; then
        sed -i "/.*$HOSTNAME.*/d" $HOST_TABLE_FILE
        printf "\nDisabled host table settings to $HOSTNAME.\n"
        break
    fi

    IP=$(echo $OPTION | perl -pe "s|((?:[0-9]+\.){3}[0-9]+).*|\1|")
    if [[ $(cat $HOST_TABLE_FILE | grep $HOSTNAME) ]]; then
        perl -i -pe "s|.*$HOSTNAME.*|$IP $HOSTNAME|" $HOST_TABLE_FILE
    else
        echo "$IP $HOSTNAME" >> $HOST_TABLE_FILE
    fi;
    printf "\nSuccessfully set $HOSTNAME to $IP.\n"
    break
done