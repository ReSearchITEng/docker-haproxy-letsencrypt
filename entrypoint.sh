#!/bin/bash

# Based on https://github.com/million12/docker-haproxy/blob/master/container-files/bootstrap.sh

HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"

set -u

# User params
HAPROXY_USER_PARAMS=$@

# Internal params
HAPROXY_PID_FILE="/var/run/haproxy.pid"
HAPROXY_CMD="haproxy -f ${HAPROXY_CONFIG} ${HAPROXY_USER_PARAMS} -D -p ${HAPROXY_PID_FILE}"
HAPROXY_CHECK_CONFIG_CMD="haproxy -f ${HAPROXY_CONFIG} -c"


#######################################
# Echo/log function
# Arguments:
#   String: value to log
#######################################
log() {
  if [[ "$@" ]]; then echo "[`date +'%Y-%m-%d %T'`] $@";
  else echo; fi
}

#######################################
# Dump current $HAPROXY_CONFIG
#######################################
print_config() {
  log "Current HAProxy config $HAPROXY_CONFIG:"
  printf '=%.0s' {1..100} && echo
  cat $HAPROXY_CONFIG
  printf '=%.0s' {1..100} && echo
}


# Launch HAProxy.
#log $HAPROXY_CMD && print_config
$HAPROXY_CHECK_CONFIG_CMD
$HAPROXY_CMD
# Exit immidiately in case of any errors or when we have interactive terminal
if [[ $? != 0 ]] || test -t 0; then exit $?; fi
log "HAProxy started with $HAPROXY_CONFIG config, pid $(cat $HAPROXY_PID_FILE)." && log

# Check if config or certificates were changed
while inotifywait -q -r --exclude '\.git/' -e modify -e create -e delete $HAPROXY_CONFIG /etc/letsencrypt; do
  if [ -f $HAPROXY_PID_FILE ]; then
    log "Restarting HAProxy due to config changes..." #&& print_config
    $HAPROXY_CHECK_CONFIG_CMD
    $HAPROXY_CMD -sf $(cat $HAPROXY_PID_FILE)
    log "HAProxy restarted, pid $(cat $HAPROXY_PID_FILE)." && log
  else
    log "Error: no $HAPROXY_PID_FILE present, HAProxy exited."
    break
  fi
done
