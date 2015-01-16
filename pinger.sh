#!/bin/sh
PATH=$PATH:/sbin:/usr/local/bin
version="0.4"

function count_packages_received () {
    packages_received=$(echo ${ping_package_transmission_components[1]} | sed -e 's/[[:alpha:]]//g')
    debug "Packages received: $packages_received"
}

function count_packages_sent () {
    packages_sent=$(echo ${ping_package_transmission_components[0]} | sed -e 's/[[:alpha:]]//g')
    debug "Packages sent: $packages_sent"
}

function ping_host () {
    ping_result=$(ping -c $count -W $waittime $hostname)
    debug "Ping result: $ping_result"
}

function set_ping_package_transmission_stats () {
    local __package_transmission_stats=$(echo "$ping_result" | grep received)
    debug "Package transmission statistics: $__package_transmission_stats"

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
    local __tmp=$(echo ${package_result_stats_components[0]})
    min_package_time=${__tmp%.*}
}

function set_avg_package_time () {
    local __tmp=$(echo ${package_result_stats_components[1]})
    avg_package_time=${__tmp%.*}
}

function set_max_package_time () {
    local __tmp=$(echo ${package_result_stats_components[2]})
    max_package_time=${__tmp%.*}
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
    -c [count]          Set the number of packages that will be send.
    -d                  Provide debug information.
    -h                  Display help.
    -p [hostname]       Hostname that will be pinged.
    -s [time]           Detect when the server responds slow. Give the max response time of the server in ms.
    -v                  Display version number
    -W [waittime]       Time to wait in milliseconds for a reply for each sent package.

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

function check_slow_server () {
    if [ -z "$avg_package_time" ]; then
        debug "Average package time not provided"
        return
    fi

    if [ $avg_package_time -gt $slow_server_time ]; then
        notify "Server $hostname is responding slow" "Slow server"
    fi
}

function execute () {
    check_host_available

    if [ "$check_slow_server" ]; then
        check_slow_server
    fi
}

function debug () {
    # Get parameters
    local __message=$1

    if [ "$debug_mode" ]; then
        echo $__message
    fi
}

# Set default options
set_default_options

# Parse the passed parameters
OPTIND=1
while getopts "c:dhp:s:vW:" flag
do
    case "$flag" in
        h) show_help; exit 0;;
        c) count=$OPTARG;;
        d) debug_mode=true;;
        p) hostname=$OPTARG;;
        s) check_slow_server=true; slow_server_time=$OPTARG;;
        v) show_about; exit 0;;
        W) waittime=$OPTARG;;
    esac
done

if [ -n "$hostname" ]; then execute; fi
