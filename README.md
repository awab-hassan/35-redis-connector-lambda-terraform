# Redis Connector — AWS Infrastructure (Terraform)

Terraform config for a Lambda-based Redis connector deployed in `ca-central-1`.

## What it provisions

- **Lambda function** (`redis-connector`) — Node.js 18.x, runs inside a VPC with access to Redis
- **API Gateway** — REST API proxying POST requests to the Lambda
- **Security Group** — Allows Lambda egress and Redis port (6379) access
- **IAM Role** — Execution role with VPC access permissions
- **Lambda Function URL** — Direct HTTPS endpoint with CORS enabled

## Configuration

Edit the `locals` block in `main.tf` to match your environment:

| Variable | Description |
|---|---|
| `vpc_id` | Target VPC |
| `subnet_id` | Subnet for Lambda VPC config |
| `redis_host` | ElastiCache cluster endpoint |
| `redis_port` | Redis port (default: 6379) |
| `origin_host` | Origin server IP |
| `app_domain` | App domain (e.g. `staging.etc.app`) |
| `environment` | Environment tag (e.g. `staging`) |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

> **Note:** A zipped Lambda deployment package (`lambda_function_payload.zip`) must exist in the working directory before applying.

## Endpoints

After deployment, two invocation options are available:
- **API Gateway:** `POST /resource` on the deployed stage URL
- **Lambda Function URL:** Direct HTTPS URL (no auth, CORS open)