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

resource "aws_apigatewayv2_integration" "lambda_itegration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.image_processing_lambda.arn
  payload_format_version = "2.0"
}

# This part is necessary if you want to define specific routes in your API.
# The "aws_apigatewayv2_api" resource defines the API, and the "aws_apigatewayv2_integration" resource 
# specifies the integration with Lambda. However, you still need to explicitly define routes using the 
# "aws_apigatewayv2_route" resource to specify which routes should trigger the integration.
#
# In this configuration, the route is defined indirectly by using the `route_key` in "aws_apigatewayv2_api".
# If you need more control over routing or have multiple routes, you should define them explicitly with 
# "aws_apigatewayv2_route". For simple use cases with a single route, the existing setup is sufficient.
#
# resource "aws_apigatewayv2_route" "aws_apigatewayv2_route" {
#   api_id    = aws_apigatewayv2_api.api.id
#   route_key = "GET /"
# }


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