#!/bin/sh
PATH=$PATH:/sbin:/usr/local/bin

# Get parameters
# hostname=$1

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

    if ! which terminal-notifier; then
        osascript -e 'display notification "The terminal-notifier package is needed." with title "Missing package."'
    else
        terminal-notifier -message "$__message" -title "$__title"
    fi
}

function show_help () {
    echo " "
    echo "Pinger to check or a host is available or not. If it is not available, it will be shown with a notification."
    echo " "
    echo "Usage:    pinger [-h] [-p HOSTNAME]"
    echo " "
    echo "          -h, --help      Display help."
    # echo "          -a, --add       Add cronjob. -- not implemented yet."
    # echo "          -c, --count     Set the number of packages that will be send. -- not implemented yet."
    echo "          -p [HOSTNAME]   Hostname that will be pinged."
    # echo "          -r, --remove    Remove cronjob. -- not implemented yet."
    echo " "
}

# show_help

# check_host_available $1

# Parse the options
OPTIND=1
while getopts ":a:c:hp:r:" flag
do
    case "$flag" in
        h|help)
            shift;
            show_help;;
        p)
            shift;
            check_host_available $OPTARG;
            shift;;
    esac
    # echo "flag: $flag" $OPTIND $OPTARG
done


# while getopts ":h" opt; do
#   case $opt in
#     h)
#       show_help
#       ;;
#   esac
# done
