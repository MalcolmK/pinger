#!/bin/sh
PATH=$PATH:/sbin:/usr/local/bin
version="0.3"

function count_packages_received () {
    packages_received=$(echo ${ping_package_transmission_components[1]} | sed -e 's/[[:alpha:]]//g')
}

function count_packages_sent () {
    packages_sent=$(echo ${ping_package_transmission_components[0]} | sed -e 's/[[:alpha:]]//g')
}

function ping_host () {
    ping_result=$(ping -c $count -W $waittime $hostname)
}

function set_ping_package_transmission_stats () {
    local __package_transmission_stats=$(echo "$ping_result" | grep received)
    if [[ $ping_result == *"packet loss"* ]]
        then
            IFS=',' read -a ping_package_transmission_components <<< "${__package_transmission_stats}"
        else
            notify $hostname "Ping failed!"
    fi

    count_packages_sent
    count_packages_received
}

function set_min_package_time () {
    min_package_time=$(echo ${package_result_stats_components[0]})
}

function set_avg_package_time () {
    avg_package_time=$(echo ${package_result_stats_components[1]})
}

function set_max_package_time () {
    max_package_time=$(echo ${package_result_stats_components[2]})
}

function set_ping_round_trip_stats () {
    local __package_result_stats=$(echo "$ping_result" | grep round-trip | sed -e 's/.*= //' | sed 's/ ms//')
    IFS='/' read -a package_result_stats_components <<< "${__package_result_stats}"

    set_min_package_time
    set_avg_package_time
    set_max_package_time
}

function set_ping_stats () {
    set_ping_package_transmission_stats
    set_ping_round_trip_stats
}

function check_host_available () {
    ping_host
    set_ping_stats

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

function execute () {
    check_host_available
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

if [ -n "$hostname" ]; then execute; fi
