#!/bin/bash
aws ecs update-service --service $(aws ecs list-services  --cluster arn:aws:ecs:eu-central-1:$AWS_ACCOUNT:cluster/mycluster_cluster | jq -r '.serviceArns[] | select(contains("daemon"))') --cluster arn:aws:ecs:eu-central-1:$AWS_ACCOUNT:cluster/mycluster_cluster --force-new-deployment | jq .

