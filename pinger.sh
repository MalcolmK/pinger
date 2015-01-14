#!/bin/sh
PATH=$PATH:/sbin:/usr/local/bin

# Get parameters
hostname=$1

function count_packages_received () {
    packages_received=$(echo ${ping_result_components[1]} | sed -e 's/[[:alpha:]]//g')
}

function count_packages_sent () {
    packages_sent=$(echo ${ping_result_components[0]} | sed -e 's/[[:alpha:]]//g')
}

function ping_host () {
    # Get parameters
    local __hostname=$1
    ping_result=$(ping -c 1 $__hostname | grep received)
    if [[ $ping_result == *"packet loss"* ]]
        then
            IFS=',' read -a ping_result_components <<< "${ping_result}"
        else
            notify $__hostname "Ping failed!"
    fi
}

function check_host_available () {
    # Get parameters
    local __hostname=$1
    ping_host $__hostname
    count_packages_sent
    count_packages_received

    if [ "$packages_sent" -ne "$packages_received" ]
        then
            notify $__hostname "Ping failed!"
    fi
}

function notify () {
    # Get parameters
    local __message=$1
    local __title=$2

    if ! which terminal-notifier;
        then
            # osascript -e 'display notification "$__message" with title "$__title"'
        else
            terminal-notifier -message "$__message" -title "$__title"
    fi
}

function show_help () {
    echo " "
    echo "Pinger to check or a host is available or not. If it is not available, it will be shown with a notification."
    echo " "
    echo "Usage:    pinger [-h] [-a]"
    echo " "
    echo "          -h, --help      Display help."
    echo "          -a, --add       Add cronjob."
    echo " "
}

# show_help

check_host_available $1
