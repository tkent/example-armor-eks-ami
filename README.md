# armor-eks-ami

A simple packer build that adds armor + aws ssm on top of the amazon-eks-ami.

---

### Local Tooling

* Make: (any recent version)
* [packer](https://www.packer.io/docs/install): `1.6.0+`
* [jq](https://stedolan.github.io/jq/download/): `1.6+`
* [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html): `0.12.26`
* [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html#cli-chap-install-v1): Version 1, `1.17.10+`
  * [AWS Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)


### Usage

#### Building the AMI

1. Have your shell setup with AWS credentials
2. Set the environment variable `armor_agent_license`. This configures the
agent license key in the AMI.
3. Run `make build`, this will produce the AMI

> Note, if you need to customize the vpc or source AMI, see variables in the
makefile.


#### Launching an AMI instance using the test fixture

Once you've created an AMI, you can us the included test fixture to quickly
deploy an instance. . It sets up a single instance which can be
accessed using AWS SSM.

> For all the included commands, replace the $TEST_ variables with those
specific to your environment

1. Specify a VPC to use. We recommend just using the regions default VPC which
can be cound using the following command.
		```
		aws ec2 describe-vpcs --region=$TEST_REGION --output=json
		```

2. Pick a subnet in the VPC found earlier, any subnet with public IPs will do
		```
		aws ec2 describe-subnets --region=$TEST_REGION \
		  --filters "Name=vpc-id,Values=$TEST_VPC_ID" --output=json
		```

Now, call terraform in the `test/fixture` folder using the following

```
terraform init
terraform apply\
	 -var ami_id=$TEST_AMI_ID\
	 -var vpc_id=$TEST_VPC_ID\
	 -var subnet_id=$TEST_SUBNET_ID\
	 -var region=$TEST_REGION
```

Then you can access the instance using
```
aws ssm start-session --region=$TEST_REGION --target $TEST_INSTANCE_ID
```

When done, use the command below to destroy the create resources

```
terraform destroy\
	 -var ami_id=$TEST_AMI_ID\
	 -var vpc_id=$TEST_VPC_ID\
	 -var subnet_id=$TEST_SUBNET_ID\
	 -var region=$TEST_REGION
```