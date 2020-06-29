#/bin/bash

#
# Install the Armor Anywhere Agent.
#
# see: https://docs.armor.com/display/KBSS/Install+the+Armor+Anywhere+Agent+3.0+-+Linux
#

if [[ -z "$ARMOR_AGENT_LICENSE" ]]; then
  echo "!! No ARMOR_AGENT_LICENSE configured !!"
  echo "Login to amp.armor.com -> Infarstructure -> Virtual Machines and retrieve the license,"
  echo "then ensure it gets passed to this script using the ARMOR_AGENT_LICENSE environment variable"
  exit 2
fi

echo
echo "Installing the Armor Anywhere Agent..."
echo

#
# This one-liner easily installs Armor. However the following happens when we
# try to use instances created from an AMI with Armor installed this way...
# 
#
#   1. Instances built from the AMI don't have any Trend services configured
#      and all Trend modules show as "inactive". This never seems to self
#      correct, even after waiting 15+ hours.
#
#   2. The Trend modules don't ever show up in the Armor Management Portal
#      since they were never configured with the Trend servers
#
# As a result, our current internal build process does not use this command.
# Instead, we omit the `-f` flag and manually install trend at build time
# using...
#
#    `opt/armor/armor trend install`
#
# Then we manually enable the services at instance boot time using the
# instructions found here under step 2:
#
#   https://docs.armor.com/display/KBSS/Install+the+Armor+Anywhere+Agent+3.0+-+Linux
# 
#
# Doing this resolves the trend services showing as inactive - but instances are
# not still shown in the Armor portal for up to 5 hours and there appears to
# be no other way to validate they are connected.
# 
#
sudo curl -sSL https://agent.armor.com/latest/armor_agent.sh \
        | sudo bash /dev/stdin -l "${ARMOR_AGENT_LICENSE}" \
                               -r us-west-armor -f