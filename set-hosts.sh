#!/bin/bash
set -e
set -o pipefail

# useful constants
CONFIG_FILE="$HOME/.hosts/hosts.yml"
HOST_TABLE_FILE="/mnt/c/Windows/System32/drivers/etc/hosts"

# read hostnames from CONFIG_FILE
declare -a HOSTNAMES
HOSTNAMES=($(cat $CONFIG_FILE | grep -e '^[^ ].*' | perl -pe "s|(.*):|\1|"))

usage() {
    echo "Usage:"
    echo "  set                           Set the host table"
    echo "  edit config                   Edit the config file [default: $HOME/.hosts/hosts.yml]"
    echo "  edit table                    Edit the host table directly [default: /mnt/c/Windows/System32/drivers/etc/hosts]"
    echo "  list                          List the hosts table settings"
    printf "\n"
    echo "Options:"
    echo "  -f, CONFIG_FILE               The path of hosts.yml [default \"~/.hosts/hosts.yml\"]"
    echo "  -h                            Display the help menu"
    exit -1
}

list() {
    set +e
    for TARGET_HOSTNAME in ${HOSTNAMES[@]}; do
        ip=$(cat $HOST_TABLE_FILE | grep $TARGET_HOSTNAME | perl -pe 's|((?:[0-9]+\.){3}[0-9]+).*|\1|')
        
        if [[ $ip ]]; then 
            name=$(cat $CONFIG_FILE | grep $ip | perl -pe "s|\s*- [\"']*(.*):((?:[0-9]+\.){3}[0-9]+)[\"']*|\1|")
            
            if [[ $name ]]; then
                echo "$TARGET_HOSTNAME: $ip ($name)"
            else
                echo "$TARGET_HOSTNAME: $ip (ip not found in hosts.yml)"
            fi;
        else
            echo "$TARGET_HOSTNAME: (unset)"
        fi;
    done
    exit 0 
}

set_host() {
    echo "Select a hostname to be configured:"
    declare -a OPTIONS
    OPTIONS+=("Disable host table setting")
    ACTIVE=false

    while [[ ! $TARGET_HOSTNAME ]]; do
        select TARGET_HOSTNAME in ${HOSTNAMES[@]}; do
            if [[ ! $TARGET_HOSTNAME ]]; then
                printf "\nInvalid selection, try again:\n"
                break
            fi

            while read line; do
                if [[ $ACTIVE == 'true' ]]; then
                    if [[ ! $line =~ ^-.*$ ]]; then
                        break
                    fi;

                    desc=$(echo $line | perl -pe "s|- [\"']*(.*):((?:[0-9]+\.){3}[0-9]+)[\"']*|\1|")
                    ip=$(echo $line | perl -pe "s|- [\"']*(.*):((?:[0-9]+\.){3}[0-9]+)[\"']*|\2|")

                    OPTIONS+=("$ip ($desc)")
                fi

                if [[ $line == $TARGET_HOSTNAME: ]]; then
                    ACTIVE=true
                fi
            done < $CONFIG_FILE
            break
        done
    done

    printf "\nSelect an ip to be set to $TARGET_HOSTNAME:\n"

    while [[ ! $OPTION ]]; do
        select OPTION in "${OPTIONS[@]}"; do
            if [[ ! $OPTION ]]; then
                printf "\nInvalid selection, try again:\n"
                break
            fi

            if [[ $OPTION == 'Disable host table setting' ]]; then
                sed -i "/.*$TARGET_HOSTNAME.*/d" $HOST_TABLE_FILE
                printf "\nDisabled host table settings to $TARGET_HOSTNAME.\n"
                break
            fi

            IP=$(echo $OPTION | perl -pe "s|((?:[0-9]+\.){3}[0-9]+).*|\1|")
            if [[ $(cat $HOST_TABLE_FILE | grep $TARGET_HOSTNAME) ]]; then
                perl -i -pe "s|.*$TARGET_HOSTNAME.*|$IP $TARGET_HOSTNAME|" $HOST_TABLE_FILE
            else
                echo "$IP $TARGET_HOSTNAME" >> $HOST_TABLE_FILE
            fi;
            printf "\nSuccessfully set $TARGET_HOSTNAME to $IP.\n"
            break
        done
    done
}

# get options
while getopts ':f:h' OPT; do
case $OPT in
    f)
        CONFIG_FILE_STRING=$OPTARG
        if [[ $CONFIG_FILE_STRING =~ ^~.*$ ]]; then
            CONFIG_FILE_STRING=$(perl -pe 's|~(.*)|$HOME\1|')
        fi;
        CONFIG_FILE=$CONFIG_FILE_STRING
        HOSTNAMES=($(cat $CONFIG_FILE | grep -e '^[^ ].*' | perl -pe "s|(.*):|\1|"));;
    h) 
        usage;;
    \:) 
        printf "Error: Argument missing from -%s option\n\n" $OPTARG
        usage
        exit 2
        ;;
    \?) printf "Error: Unknown option: -%s\n\n" $OPTARG
        usage
        exit 2
        ;;
esac >&2
done
shift "$(($OPTIND - 1))"

if [[ $1 == "edit" ]]; then
    if [[ $2 == "config" ]]; then
        nano $CONFIG_FILE
        exit 0
    elif [[ $2 == "table" ]]; then
        nano $HOST_TABLE_FILE
        exit 0
    else
        usage
        exit 0
    fi
fi

if [[ $1 == "set" ]]; then
    set_host
    exit 0
fi

if [[ $1 == "list" ]]; then
    list
    exit 0
fi

if [[ $1 == "" ]]; then
    usage
    exit 0
fi
