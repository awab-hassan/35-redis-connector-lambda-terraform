provider "aws" {
  alias  = "canada"
  region = "ca-central-1"
}

# Local variables for infrastructure components
locals {
  vpc_id     = "vpc-XXX"
  subnet_id  = "subnet-XXX"
  environment = "staging"
  redis_host = "redis-cluster.XXX.XXX.XXX.cache.amazonaws.com"
  redis_port = "6379"
  origin_host = "XX.XX.XX.XX"
  app_domain = "staging.etc.app"
}

resource "aws_security_group" "lambda_security_group" {
  provider    = aws.canada
  name_prefix = "lambda-sg"
  vpc_id      = local.vpc_id
  description = "Security group for Lambda function"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sg"
    Environment = local.environment
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  provider = aws.canada
  name = "lambda_execution_roll"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "lambda-execution-role"
    Environment = local.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  provider   = aws.canada
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "lambda_function" {
  provider      = aws.canada
  function_name = "redis-connector"
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  role          = aws_iam_role.lambda_execution_role.arn
  filename      = "lambda_function_payload.zip"

  vpc_config {
    subnet_ids         = [local.subnet_id]
    security_group_ids = [aws_security_group.lambda_security_group.id]
  }

  environment {
    variables = {
      REDIS_HOST       = local.redis_host
      REDIS_PORT       = local.redis_port
      ENVIRONMENT      = local.environment
      ORIGIN_HOST      = local.origin_host
      DOMAIN           = local.app_domain
    }
  }

  tags = {
    Name = "redis-connector"
    Environment = local.environment
  }
}

# Lambda Function URL
resource "aws_lambda_function_url" "lambda_url" {
  provider      = aws.canada
  function_name = aws_lambda_function.lambda_function.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  provider = aws.canada
  name = "redis-connector-api"

  tags = {
    Name = "redis-connector-api"
    Environment = local.environment
  }
}

resource "aws_api_gateway_resource" "api_resource" {
  provider    = aws.canada
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "resource"
}

resource "aws_api_gateway_method" "api_method" {
  provider      = aws.canada
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_integration" {
  provider               = aws.canada
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  provider    = aws.canada
  depends_on  = [aws_api_gateway_integration.api_integration]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = "prod"
  
  lifecycle {
    create_before_destroy = true
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  provider      = aws.canada
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*/*"
}
