#!/usr/bin/env bash

region="eu-central-1"

# static website
image_gallery="static-image-gallery-654"
aws s3api create-bucket \
  --bucket "$image_gallery" \
  --region "$region" \
  --create-bucket-configuration LocationConstraint="$region"

# storage bucket
image_storage="image-storage-6552"
aws s3api create-bucket \
  --bucket "$image_storage" \
  --region "$region" \
  --create-bucket-configuration LocationConstraint="$region"

# put bucket policy, block public access and cors policy
aws s3api put-public-access-block --bucket "$image_storage" --public-access-block-configuration file://block-public-acces.json
aws s3api put-public-access-block --bucket "$image_gallery" --public-access-block-configuration file://block-public-acces.json
aws s3api put-bucket-policy --bucket "$image_storage" --policy file://policy-storage.json
aws s3api put-bucket-policy --bucket "$image_gallery" --policy file://policy-gallery.json
aws s3api put-bucket-cors --bucket "$image_storage" --cors-configuration file://cors.json

# enable static website hosting
aws s3api put-bucket-website --bucket "$image_gallery" --website-configuration file://website-configuration.json

# create role for lambda function
lambda_role="image-processing-lambda"
aws iam create-role --role-name "$lambda_role" --assume-role-policy-document file://trust-policy.json
aws iam put-role-policy --role-name "$lambda_role" --policy-name image-processing --policy-document file://lambda-policy.json

sleep 20

# create lambda function
lambda_function_name="lambda-function"
lambda_role_arn="arn:aws:iam::332428815411:role/image-processing-lambda"
aws lambda create-function \
  --region "$region" \
  --function-name "$lambda_function_name" \
  --runtime python3.8 \
  --role "$lambda_role_arn" \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda-function.zip \
  --description "My Lambda function"

# create api
api_name="image-processing-api"

api_id=$(aws apigatewayv2 create-api \
  --name "$api_name" \
  --protocol-type "HTTP" \
  --region "$region" \
  --query "ApiId" \
  --output text)

# integrate api with lambda
lambda_function_arn="arn:aws:lambda:eu-central-1:332428815411:function:lambda-function"

# create a route and integration for the api
integration_id=$(aws apigatewayv2 create-integration \
  --api-id "$api_id" \
  --integration-type AWS_PROXY \
  --integration-uri "$lambda_function_arn" \
  --payload-format-version 2.0 \
  --region "$region" \
  --query "IntegrationId" \
  --output text)

route_id=$(aws apigatewayv2 create-route \
  --api-id "$api_id" \
  --route-key 'GET /' \
  --region "$region" \
  --query "RouteId" \
  --output text)

aws apigatewayv2 update-route \
  --api-id "$api_id" \
  --route-id "$route_id" \
  --target "integrations/$integration_id" \
  --region "$region"

# update cors configuration
aws apigatewayv2 update-api \
  --api-id "$api_id" \
  --cors-configuration file://api-cors.json \
  --region "$region"

# create automatic stage
aws apigatewayv2 create-stage \
  --api-id "$api_id" \
  --stage-name prod \
  --auto-deploy \
  --region "$region"

# add permission to invoke lambda function
aws lambda add-permission \
  --function-name "$lambda_function_name" \
  --principal apigateway.amazonaws.com \
  --statement-id lambda-invoke-permissions \
  --action lambda:InvokeFunction \
  --source-arn "arn:aws:execute-api:$region:332428815411:$api_id/*/*/" \
  --region $region

# upload index.html
# change api url in index.html
aws s3api put-object --bucket "$image_gallery" --key index.html --body index.html --content-type "text/html"
