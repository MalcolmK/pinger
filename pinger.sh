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
            terminal-notifier -message "$__hostname" -title "Ping failed"
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
            terminal-notifier -message "$__hostname" -title "Ping failed"
    fi
}

check_host_available $1
