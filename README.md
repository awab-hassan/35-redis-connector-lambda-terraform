# Project 35: Redis Connector Lambda on AWS

Terraform module that provisions a Node.js Lambda Redis connector in `ca-central-1`. The Lambda runs inside an existing VPC with access to an ElastiCache Redis cluster and is exposed through both an API Gateway REST endpoint and a direct Lambda Function URL.

## What It Provisions

- **Lambda function** (`redis-connector`) — Node.js 18.x, VPC-attached for private Redis access
- **API Gateway** — REST API proxying `POST` requests to the Lambda
- **Security Group** — allows Lambda egress and Redis access on port 6379
- **IAM execution role** — VPC access permissions and CloudWatch Logs
- **Lambda Function URL** — direct HTTPS endpoint with CORS enabled

## Configuration

Edit the `locals` block in `main.tf` to match the target environment:

| Variable | Description |
|---|---|
| `vpc_id` | Target VPC |
| `subnet_id` | Subnet for the Lambda VPC config |
| `redis_host` | ElastiCache cluster endpoint |
| `redis_port` | Redis port (default: 6379) |
| `origin_host` | Origin server address used by the handler |
| `app_domain` | Application domain (e.g. `staging.example.com`) |
| `environment` | Environment tag (e.g. `staging`, `prod`) |

## Stack

Terraform · AWS Lambda (Node.js 18.x) · API Gateway (REST) · IAM · VPC · ElastiCache Redis (pre-existing) · ca-central-1

## Repository Layout

```
redis-connector-lambda-terraform/
├── main.tf
├── lambda_function_payload.zip   # Built and placed before apply (gitignored)
├── .gitignore
└── README.md
```

## Prerequisites

- Terraform >= 1.x
- AWS credentials with permissions for Lambda, API Gateway, IAM, EC2 (security groups), and VPC access
- An existing VPC with at least one subnet
- An existing ElastiCache Redis cluster reachable from that subnet
- A built `lambda_function_payload.zip` in the working directory before applying

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## Endpoints

After deployment, the Lambda is reachable via two paths:

- **API Gateway:** `POST /resource` on the deployed stage URL
- **Lambda Function URL:** direct HTTPS URL

## Notes

- **Lambda Function URL has no authentication and CORS is open (`*`).** Anyone with the URL can invoke the function. Restrict CORS to specific origins and add IAM auth (`AuthType = AWS_IAM`) before exposing externally, or remove the Function URL entirely and route traffic only through API Gateway with an authorizer.
- **API Gateway has no authorizer configured.** Add an IAM, Cognito, or Lambda authorizer for production use.
- **Single subnet attachment.** The Lambda is attached to one subnet, which means one AZ. For HA, attach the Lambda to subnets in at least two AZs.
- **Redis credentials.** If the target Redis cluster uses AUTH, inject the token via Lambda environment variables (avoid committing values) or fetch at runtime from AWS Secrets Manager.
- This module is the single-region equivalent of a multi-region VPC-peering setup. For cross-region Redis access, see the companion VPC peering module.
