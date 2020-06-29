#!/bin/bash

#
# Checks if the armor system is running properly and registered.
#
# Exit codes:
#
#   0 = success
#   1 = Not Yet Active
#   2 = Unrecoverable error 
#
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

check_svc_status() {
  local svc="$1"
  local svc_status=""
  echo -n "Verifying $svc status... "
  svc_status="$(systemctl status $svc 2>&1)"
  (( $? == 0 )) && ok || not_ok "$svc_status"
}

# - armor-agent is the main Armor agent
check_svc_status armor-agent.service

# - qualys-cloud-agent is the Qualys vulnerability scanning agent installed by Armor
check_svc_status qualys-cloud-agent.service

# - ds_agent is the Trend Micro "deep security" agent isntalled by Armor
#   note: ds_agent is installed as a SysVInit and so isn't "enabled".
check_svc_status ds_agent.service

# - filebeat is used to send logs to Armor's log server
echo -n "Verifyng the filebeat service is running... "
(( $(ps aux | grep filebeat | wc -l) > 1 )) && ok || not_ok "(Not Running)"


echo "Checking trend statuses... (requesting agent status)"
json_out="$(sudo /opt/armor/armor trend status | grep 'Output:' | sed 's/Output: //g' 2>&1)"
if (( $? != 0 )); then
  echo "Failed to retrieve trend sub-agent JSON status!"
  echo "details:"
  echo
  echo "$json_out"
  echo
  exit 2
fi

# verify the Trend agent is connected to Trend server
echo -n "Checking trend agent connected... "
[[ "$(echo $json_out | jq -r '.computerStatus.agentStatusMessages[-1]')" == "Managed (Online)" ]] && ok || not_ok "(Not Managed)"

# Wait for the IPS/IDS agent to be active and configured by the Trend server
echo -n "Checking trend agent IPS/IDS status... "
[[ "$(echo $json_out | jq -r '.intrusionPrevention.moduleStatus.agentStatus')" == "active" ]] && ok || not_ok "(Not Active)"
echo -n "Checking trend agent IPS/IDS state... "
[[ "$(echo $json_out | jq -r '.intrusionPrevention.state')" == "detect" ]]  && ok || not_ok "(Not Detecting)"


# Wait for the FIM agent to be active and configured by the Trend server
echo -n "Checking trend agent FIM status... "
[[ "$(echo $json_out | jq -r '.integrityMonitoring.moduleStatus.agentStatus')" == "active" ]] && ok || not_ok "(Not Active)"
echo -n "Checking trend agent FIM state... "
[[ "$(echo $json_out | jq -r '.integrityMonitoring.state')" == "real-time" ]] && ok || not_ok "(Not Real-Time)"

# Wait for the Anti Malware agent to be active and on
echo -n "Checking trend agent Malware state... "
[[ "$(echo $json_out | jq -r '.antiMalware.state')" == "on" ]] && ok || not_ok "(Not Real-Time)"


echo
echo "Trend agent agent status json stored in /tmp/trendagent.json"
echo "$json_out" | jq "." > /tmp/trendagent.json

if (( failed_count > 0 ))
then
  exit 1
fi

exit 0