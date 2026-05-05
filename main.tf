provider "aws" {
  region = var.aws_region
}


# IAM & Security


resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-sg-${var.environment}"
  description = "Security group for Redis Connector Lambda"
  vpc_id      = var.vpc_id

  # Egress to anywhere (standard for Lambda to reach external APIs if needed)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-${var.environment}"
    Environment = var.environment
  }
}


# Lambda Function


resource "aws_lambda_function" "redis_connector" {
  filename         = "lambda_function_payload.zip"
  function_name    = "${var.project_name}-${var.environment}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  vpc_config {
    subnet_ids         = [var.subnet_id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      REDIS_HOST  = var.redis_host
      REDIS_PORT  = tostring(var.redis_port)
      ORIGIN_HOST = var.origin_host
      APP_DOMAIN  = var.app_domain
      ENVIRONMENT = var.environment
    }
  }
}

# Lambda Function URL (Direct Invocation)
resource "aws_lambda_function_url" "connector_url" {
  function_name      = aws_lambda_function.redis_connector.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"] # Note: Restrict this in production
    allow_methods     = ["POST"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}


# API Gateway

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "API Gateway for Redis Connector"
}

resource "aws_api_gateway_resource" "resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "resource"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.redis_connector.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redis_connector.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# ==========================================
# Outputs
# ==========================================

output "lambda_function_url" {
  description = "Direct URL for the Lambda function"
  value       = aws_lambda_function_url.connector_url.function_url
}
