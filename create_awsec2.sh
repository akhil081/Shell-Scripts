#!/bin/bash

set -euo pipefail

check_awscli() {
	command -v aws &> /dev/null
	if [ $? -eq 0 ]; then
		echo "AWS CLI is installed"
	else
		echo "AWS CLI is not installed"
	fi
}

install_awscli() {
	echo "Installing AWS CLI v2 on Linux....."
	mkdir tmp
	cd tmp
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	#sudo apt-get install unzip -y	
	unzip awscliv2.zip
	sudo ./aws/install --update 
	aws --version
	rm -rf awscliv2.zip ./tmp
}



wait_for_instance() {
	local instance_id="$1"
	echo "waiting for $instance_id to be in running state......."

	while true; do
		state=$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[0].Instances[0].State.Name' --output text)
		if [["$state" == "running"]]; then
			echo "Instance $instance_id is now running...."
			break
		fi
		sleep 10
	done
}



create_ec2_instance() {
	local ami_id="$1"
	local instance_type="$2"
	local key_name="$3"
	local subnet_id="$4"
	local security_group_id="$5"
	local instance_name="$6"

	instance_id=$(aws ec2 run-instances \
		--image-id "$ami_id" \
		--instance-type "$instance_type" \
		--key-name "$key_name" \
		--subnet-id "$subnet_id" \
		--security-group-ids "$security_group_id" \
		--query 'Instances[0].InstnaceId' \
		--output text
	)

	if [ -z "$instance_id" ]; then
		echo "Failed to create EC2 instance" >&2
		exit 1
	fi

	echo "Instance $instance_id created successfully"

	wait_for_instance "instance_id"

}



main() {
	if ! check_awscli ; then
		install_awscli || exit 1
	fi


	echo "Creating EC2 instance...."

	AMI_ID="ami-0862be96e41dcbf74"
	INSTANCE_TYPE="t2.micro"
	KEY_NAME="ubuntu"
	SUBNET_ID="subnet-e860e083"
	SECURITY_GROUP_IDS="sg-01a9a43e0e72f68d9"
	INSTANCE_NAME="Script_Instance"

	create_ec2_instance "$AMI_ID" "$INSTANCE_TYPE" "$KEY_NAME" "$SUBNET_ID" "$SECURITY_GROUP_IDS" "$INSTANCE_NAME"

	echo "EC2 instance creation completed"
}

main "$@"








