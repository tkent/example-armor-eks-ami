#!/bin/bash

RESET="\e[39m"
CHECK="\e[32m\xE2\x9C\x94"
CROSS="\e[31mx"

failed_count=0

ok() {
  echo -e "$CHECK$RESET"
}

not_ok() {
  echo -e "$CROSS$RESET"
  if [[ ! -z "$1" ]]; then
    echo "details: "
    echo
    echo "$1"
    echo
  fi
  (( failed_count++ ))
}

#
# Check whether a systemsctl service (unit) is enabled and running
#
check_svc_enabled() {
  local svc="$1"
  echo -n "Verifying $svc is enabled... "
  [[ "$(systemctl is-enabled $svc 2>&1)" = "enabled" ]] && ok || not_ok
}

check_svc_status() {
  local svc="$1"
  local svc_status=""
  echo -n "Verifying $svc status... "
  svc_status="$(systemctl status $svc 2>&1)"
  (( $? == 0 )) && ok || not_ok "$svc_status"
}

echo
echo "Running self test..."

echo
echo "*** AWS SSM installation ***"
check_svc_enabled amazon-ssm-agent.service
check_svc_status amazon-ssm-agent.service


echo
echo "*** Armor Agent installation ***"
echo -n "Verifying Armor agent is installed... "
[[ -f /opt/armor/armor ]] && ok || not_ok
echo -n "Verifying the Trend sub-agent is installed... "
(( $(ps aux | grep ds_agent | wc -l) > 1 )) && ok || not_ok

# Used when we provision new instances that configure on themselves 
# on first boot. Not currently included in this example.
# 
#echo -n "Verifying the Armor configuration script is installed to run on boot... "
#[[ -f /var/lib/cloud/scripts/per-instance/01.configure_armor.sh ]] && ok || not_ok

if (( $failed_count > 0 ))
then
  exit 1
fi

exit 0