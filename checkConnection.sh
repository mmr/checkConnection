#!/bin/sh

##
# Check if PPP connection is OK, reconnecting if needed.
# @author Marcio Ribeiro (mmr)
# @created 11/09/2005
# @version $Id: checkConnection.sh,v 1.6 2005/09/14 10:48:33 mmr Exp $
#

##
# Absolute path to programs needed by this program.
PING="/sbin/ping"
PKILL="/usr/bin/pkill"
PPP="/usr/sbin/ppp"
RM="/bin/rm"
SLEEP="/bin/sleep"
DATE="/bin/date"
TEE="/usr/bin/tee"
UPDATE_DNS="/usr/sbin/updateDns.sh"

##
# Arguments for programs needed by this program.
PING_COUNT="1"
PING_TIMEOUT="5"
PING_HOST="200.221.2.130"
DATE_FORMAT="+%c"
PPP_CONNECTION="speedy"
SLEEP_SECONDS_BETWEEN_CHECKS=5

##
# Constants.
LOCK_FILE="/tmp/checkConnection.lock"
LOG_FILE="/var/log/checkConnection.log"

##
# Logging constants.
ERROR="ERROR"
NOTICE="NOTICE"
WARN="WARN"
DEBUG="DEBUG"

##
# [ Auxiliar Functions ]

##
# Check if user running the app is root (ie. has 0 uid).
isRoot() {
    test $(id -u) == 0
}

##
# Check if you have the needed apps to run this program properly.
hasNeededApps() {
    ret=0
    for app in $PING $PKILL $PPP $RM $SLEEP $DATE $TEE $UPDATE_DNS; do
        if ! test -x $app; then
            echo "Hey, you dont have '$app'."
            ret=1
        fi
    done
    return $ret
}

##
# Check if is connected.
isConnected() {
    $PING -c $PING_COUNT -w $PING_TIMEOUT $PING_HOST >/dev/null 2>&1
}

##
# Try to reconnect, restarting the PPP process and keep checking if is
# connected, exits when connection is finally achieved or lock is manually
# removed.
reconnect() {
    killPPP
    startPPP

    # Check if did connect (or lock was forced to destruction)
    while true; do
        if isConnected; then
            logMessage $NOTICE "HOORAY, Connected!"
            break
        fi
        if ! isLocked; then
            logMessage $ERROR "Lock was removed! Aborting."
            break
        fi
        $SLEEP $SLEEP_SECONDS_BETWEEN_CHECKS
    done
}

##
# Kill PPP process.
killPPP() {
    $PKILL ppp >/dev/null 2>&1
}

##
# Start PPP process.
startPPP() {
    $PPP -nat -ddial $PPP_CONNECTION > /dev/null 2>&1
}

##
# Create lock file.
createLock() {
    echo "Lock created at $($DATE $DATE_FORMAT)" > "$LOCK_FILE"
}

##
# Unlink lock file.
destroyLock() {
    $RM "$LOCK_FILE"
}

##
# Check if lock file exists.
isLocked() {
    test -f "$LOCK_FILE"
}

##
# Update DNS entry in DynDns after reconnecting.
updateDns() {
    logMessage $NOTICE "Updating DNS in DynDns."
    $UPDATE_DNS >/dev/null 2>&1
}

##
# Log a message with a certain log level to stdout and log file.
logMessage() {
    echo "$($DATE $DATE_FORMAT) $1 $2" | $TEE -a $LOG_FILE
}

##
# [ MAIN ]
if ! isRoot; then
    echo "Sorry mate, you have to be root to run this app."
    exit
fi

if ! hasNeededApps; then
    echo "Sorry mate, you dont have the needed apps. Aborting."
    exit
fi

if isLocked; then
    logMessage $WARN "Locked, please wait."
else
    createLock
    if ! isConnected; then
        logMessage $WARN "Not connected! Reconnecting..."
        reconnect
        updateDns
    fi
    destroyLock
fi
