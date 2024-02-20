#!/bin/bash
aws s3 cp deploy_container/dagster.yaml s3://my-dagster-config-bucket/config/dagster.yaml
aws s3 cp deploy_container/workspace.yaml s3://my-dagster-config-bucket/config/workspace.yaml

aws ecs update-service --service $(aws ecs list-services  --cluster arn:aws:ecs:eu-central-1:$AWS_ACCOUNT:cluster/mycluster_cluster | jq -r '.serviceArns[] | select(contains("webserver"))') --cluster arn:aws:ecs:eu-central-1:$AWS_ACCOUNT:cluster/mycluster_cluster --force-new-deployment | jq .

