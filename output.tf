# Outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.lambda_function.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.lambda_function.function_name
}

output "lambda_function_url" {
  description = "URL of the Lambda function"
  value       = aws_lambda_function_url.lambda_url.function_url
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}/${aws_api_gateway_resource.api_resource.path_part}"
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.api_gateway.id
}