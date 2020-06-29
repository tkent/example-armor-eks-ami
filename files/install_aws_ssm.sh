#/bin/bash

#
# Install the AWS SSM agent, which does not come pre-installed on the EKS AMIs
#
# see:
#  * https://github.com/terraform-aws-modules/terraform-aws-eks/issues/224
#  * https://github.com/awslabs/amazon-eks-ami/issues/127
#
echo
echo "Installing the AWS SSM agent..."
echo

sudo yum install -y amazon-ssm-agent
if (( $? != 0 )); then
  echo "!! Failed to install the amazon-ssm-agent !!"
  exit 1
fi

sudo systemctl start amazon-ssm-agent
if (( $? != 0 )); then
  echo "!! Failed to start the amazon-ssm-agent !!"
  exit 1
fi

sudo systemctl enable amazon-ssm-agent
if (( $? != 0 )); then
  echo "!! Failed to enable the amazon-ssm-agent !!"
  exit 1
fi

sudo yum clean all

echo
echo "Successfully installed the amazon-ssm-agent"
echo

exit 0