#!/bin/sh

##
# Update DNS in DynDns using ipcheck.
# @author Marcio Ribeiro (mmr)
# @created 11/09/2005
# @version $Id: updateDns.sh,v 1.5 2006/03/08 02:16:13 mmr Exp $
#

##
# Absolute path to programs needed by this program.
IPCHECK="/usr/local/bin/ipcheck.py"

##
# Constants.
DIR="/home/mmr/dyndns"
USER="mribeiro"
PASS="dynpass"
DOMAINS="b1n.ath.cx,pasteb1n.ath.cx,urlb1n.ath.cx,cvb1n.ath.cx,vampb1n.ath.cx"

##
# Check if you have the needed apps to run this program properly.
hasNeededApps() {
    ret=0
    if ! test -x $IPCHECK; then
        echo "Hey, you dont have '$IPCHECK'."
        ret=1
    fi
    return $ret
}

##
# [ MAIN ]
if ! hasNeededApps; then
    echo "Sorry mate, you dont have the needed apps. Aborting."
    exit
fi

$IPCHECK -d $DIR -l -r checkip.dyndns.org:8245 $USER $PASS "$DOMAINS"
