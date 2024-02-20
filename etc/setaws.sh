#!/bin/bash
# Generate AWS environment variables for the current instance when being run on an EC2 instance git runner.
# This was originally created for an Gitlab-Automation runner.

TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
AWSKEYS=`curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/YourGitlabRunnerIAMRoleHere -H "X-aws-ec2-metadata-token: $TOKEN"`

AWS_ACCESS_KEY_ID=$(echo $AWSKEYS | jq -r .AccessKeyId)
AWS_SECRET_ACCESS_KEY=$(echo $AWSKEYS | jq -r .SecretAccessKey)
AWS_REGION=eu-central-1
AWS_SESSION_TOKEN=$(echo $AWSKEYS | jq -r .Token)
AWS_ACCOUNT=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document -H "X-aws-ec2-metadata-token: $TOKEN" | jq -r .accountId)

echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" > awsenv
echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> awsenv
echo "export AWS_REGION=$AWS_REGION" >> awsenv
echo "export AWS_ACCOUNT=$AWS_ACCOUNT" >> awsenv
echo "export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN" >> awsenv

cat awsenv
