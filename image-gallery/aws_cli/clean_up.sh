#!/usr/bin/env bash

aws s3 rb --force s3://static-image-gallery-654
aws s3 rb --force s3://image-storage-6552

aws iam delete-role-policy --role-name image-processing-lambda --policy-name image-processing
aws iam delete-role --role-name image-processing-lambda

aws lambda delete-function --function-name lambda-function --region eu-central-1

# change api id
aws apigatewayv2 delete-api --api-id v0cljgcf04 --region eu-central-1
