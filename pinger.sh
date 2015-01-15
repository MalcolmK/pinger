#!/bin/sh
PATH=$PATH:/sbin:/usr/local/bin
version="0.2"

function count_packages_received () {
    packages_received=$(echo ${ping_result_components[1]} | sed -e 's/[[:alpha:]]//g')
}

function count_packages_sent () {
    packages_sent=$(echo ${ping_result_components[0]} | sed -e 's/[[:alpha:]]//g')
}

function ping_host () {
    ping_result=$(ping -c $count -W $waittime $hostname | grep received)
    if [[ $ping_result == *"packet loss"* ]]
        then
            IFS=',' read -a ping_result_components <<< "${ping_result}"
        else
            notify $hostname "Ping failed!"
    fi
}

function check_host_available () {
    ping_host
    count_packages_sent
    count_packages_received

    if [ "$packages_sent" -ne "$packages_received" ]
        then
            notify $hostname "Ping failed!"
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
    cat <<PINGER_USAGE

Pinger to check or a host is available or not. If it is not available, it will be shown with a notification.

Usage:
    pinger [OPTIONS]

Options:
    -c, --count [count]         Set the number of packages that will be send.
    -h, --help                  Display help.
    -p [hostname]               Hostname that will be pinged.
    -v, --version               Display version number
    -W, --wait [waittime]       Time to wait in milliseconds for a reply for each sent package.

PINGER_USAGE
}

function set_default_options () {
    count=1
    waittime=1000
}

function show_about () {
    cat <<PINGER_ABOUT

Version:        $version
Last updated:   2015/01/15
Created by:     Malcolm Kindermans <malcolm.k.x@gmail.com>
Source:         https://github.com/MalcolmK/pinger

PINGER_ABOUT
}

# Set default options
set_default_options

# Parse the passed parameters
OPTIND=1
while getopts "c:hp:vW:" flag
do
    case "$flag" in
        h|help)     show_help; exit 0;;
        c|count)    count=$OPTARG;;
        p)          hostname=$OPTARG;;
        v|version)  show_about; exit 0;;
        W|wait)     waittime=$OPTARG;;
    esac
done

if [ -n "$hostname" ]; then check_host_available; fi
