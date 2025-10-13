# backend-iac/apigateway.tf

resource "aws_apigatewayv2_api" "http_api" {
  name          = "presigned-url-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "PUT", "POST"]
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

# --- THIS SECTION IS UPDATED ---

# Create an explicit deployment. The triggers ensure that a new deployment
# happens every time the route changes.
resource "aws_apigatewayv2_deployment" "api_deployment" {
  api_id = aws_apigatewayv2_api.http_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_route.get_upload_url.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# The stage now points to the explicit deployment and has auto-deploy disabled.
resource "aws_apigatewayv2_stage" "default" {
  api_id        = aws_apigatewayv2_api.http_api.id
  name          = "$default"
  auto_deploy   = false # Disabled in favor of explicit deployment
  deployment_id = aws_apigatewayv2_deployment.api_deployment.id
}
# --------------------------------

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presigned_url_generator.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "api_endpoint_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}