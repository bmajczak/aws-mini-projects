# AWS Infrastructure Setup with Terraform

This Terraform project automates the setup of AWS resources for an image processing application. It performs the following tasks:

1. **Creates S3 Buckets**:
   - `static-image-gallery-654`: For serving static website content.
   - `image-storage-6552`: For storing images.

2. **Configures S3 Buckets**:
   - Applies bucket policies and blocks public access.
   - Sets up static website hosting for the `static-image-gallery-654` bucket.
   - Configures CORS for the `image-storage-6552` bucket.

3. **Sets Up Lambda Function**:
   - Creates an IAM role for the Lambda function with appropriate permissions.
   - Deploys the Lambda function for image processing.

4. **Creates and Configures API Gateway**:
   - Sets up an HTTP API.
   - Integrates the API with the Lambda function.
   - Configures routes and CORS for the API.

5. **Grants API Gateway Permission to Invoke Lambda**:
   - Provides permissions for API Gateway to invoke the Lambda function.

## Prerequisites

- **Terraform** installed on your local machine.
- **AWS CLI** installed and configured with appropriate permissions.
- **Lambda Function Code**:
  - `lambda_function.py`: Python script for the Lambda function.
  - `lambda-function.zip`: Lambda function code packaged into a ZIP file.

- **JSON Policy Files**:
  - `policy-gallery.json`: Bucket policy for `static-image-gallery-654`.
  - `policy-storage.json`: Bucket policy for `image-storage-6552`.
  - `trust-policy.json`: Trust policy for the Lambda role.
  - `lambda-policy.json`: Policy document for the Lambda role.

- **Static Content**:
  - `index.html`: HTML file to be served by the static website bucket.

## Terraform Configuration Files

### `provider.tf`
Defines the Terraform provider configuration:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.57.0"
    }
  }
}

provider "aws" {
  region = var.REGION
}
```
### `vars.tf`
Defines variables used in the configuration:
```hcl
variable "REGION" {
  default = "eu-central-1"
  type    = string
}

variable "image_gallery" {
  type    = string
  default = "static-image-gallery-654"
}

variable "image_storage" {
  type    = string
  default = "image-storage-6552"
}

variable "lambda_role" {
  type    = string
  default = "image-processing-lambda"
}

variable "function_name" {
  type    = string
  default = "lambda-function"
}

variable "api_name" {
  type    = string
  default = "image-processing-api"
}
```
### `bucket.tf`
Defines the S3 buckets and their configurations:
```hcl
resource "aws_s3_bucket" "image_gallery" {
  bucket        = var.image_gallery
  force_destroy = true
}

resource "aws_s3_bucket_policy" "image_gallery_policy" {
  bucket = aws_s3_bucket.image_gallery.id
  policy = file("${path.module}/resources/policy-gallery.json")
}

resource "aws_s3_bucket_public_access_block" "image_gallery_block" {
  bucket = aws_s3_bucket.image_gallery.id

  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = false
  block_public_policy     = false
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.image_gallery.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket" "image_storage" {
  bucket        = var.image_storage
  force_destroy = true
}

resource "aws_s3_bucket_policy" "image_storage_policy" {
  bucket = aws_s3_bucket.image_storage.id
  policy = file("${path.module}/resources/policy-storage.json")
}

resource "aws_s3_bucket_public_access_block" "image_storage_block" {
  bucket = aws_s3_bucket.image_storage.id

  block_public_acls       = true
  ignore_public_acls      = true
  restrict_public_buckets = false
  block_public_policy     = false
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.image_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://static-image-gallery-654.s3.eu-central-1.amazonaws.com"]
    expose_headers  = [""]
    max_age_seconds = 3000
  }
}
```
### `backend.tf`
Defines the Lambda function, API Gateway, and permissions:

```hcl
resource "aws_iam_role" "lambda_role" {
  name               = var.lambda_role
  assume_role_policy = file("${path.module}/resources/trust-policy.json")
  inline_policy {
    name   = "image_processing"
    policy = file("${path.module}/resources/lambda-policy.json")
  }
}

resource "aws_lambda_function" "image_processing_lambda" {
  function_name = var.function_name
  filename      = "${path.module}/resources/lambda-function.zip"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  source_code_hash = filebase64sha256("${path.module}/resources/lambda-function.zip")
}

resource "aws_apigatewayv2_api" "api" {
  protocol_type = "HTTP"
  name          = var.api_name
  route_key     = "GET /"
  target = aws_lambda_function.image_processing_lambda.arn
  cors_configuration {
    allow_origins  = ["http://static-image-gallery-654.s3-website.eu-central-1.amazonaws.com"]
    allow_methods  = ["GET"]
    allow_headers  = []
    expose_headers = []
    max_age        = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.image_processing_lambda.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  auto_deploy = true
  name        = "prod"
}

resource "aws_lambda_permission" "lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processing_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*/"
}
```

## How to Use

1. **Clone the Repository**: Clone or download the repository containing this Terraform configuration.

2. **Update Variables**: Modify the `terraform.tfvars` or variables directly in `vars.tf` to update the region, bucket names, role names, and other variables as needed.

3. **Prepare Files**: Ensure the following files are correctly defined and located in the `resources` directory:
   - `lambda_function.py`: Python script for the Lambda function.
   - `lambda-function.zip`: ZIP file containing the Lambda function code.
   - `policy-gallery.json`: Bucket policy for the `static-image-gallery-654` bucket.
   - `policy-storage.json`: Bucket policy for the `image-storage-6552` bucket.
   - `trust-policy.json`: Trust policy for the Lambda role.
   - `lambda-policy.json`: Policy document for the Lambda role.
   - `index.html`: HTML file to be served by the static website bucket.
4. **Plan the Deployment:** Generate an execution plan to review changes before applying:

    ```bash
    terraform plan
    ```
5. **Apply the Configuration:** Apply the Terraform configuration to create and configure the resources:

    ```bash
    terraform apply
    ```
    Review the plan and confirm the application of changes.

6. **Verify Deployment:** After applying the configuration, check the AWS Management Console or use the AWS CLI to verify that the resources were created correctly. Ensure the Lambda function, API Gateway, S3 buckets, and associated settings are in place.

7. **Update Static Content:** If applicable, update your static content or configurations in the Lambda function. For example, replace placeholders in your code or configuration files. Upload images to your S3 bucket under the images/ folder and update index.html with your API URL.

8. **Clean Up:** When you no longer need the resources, you can destroy them using Terraform:

    ```bash
    terraform destroy
    ```
    Confirm the destruction of resources when prompted.

## Additional Notes
- Ensure that the trust-policy.json and lambda-policy.json files are correctly defined and located in the resources directory.
- Make sure the Lambda function code is packaged into lambda-function.zip and placed in the resources directory.
- Adjust CORS settings and API Gateway configurations as needed based on your application's requirements.
For more information on how to use Terraform, refer to the official Terraform documentation.

**Feel free to adjust the content as needed based on your project specifics or any additional details you want to include. If you have any more sections or need further customization, let me know!**