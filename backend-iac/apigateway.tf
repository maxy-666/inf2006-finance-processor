# backend-iac/apigateway.tf

# 1. API Gateway to trigger the pre-signed URL generator
resource "aws_apigatewayv2_api" "http_api" {
  name          = "presigned-url-api"
  protocol_type = "HTTP"

  # This block is the fix
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.presigned_url_generator.invoke_arn
}

resource "aws_apigatewayv2_route" "get_upload_url" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /generate-upload-url"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url_generator.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*"
}

# Output the API endpoint URL for the front-end
output "api_endpoint_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}