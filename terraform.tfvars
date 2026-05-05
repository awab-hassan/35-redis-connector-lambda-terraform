aws_region   = "ca-central-1"
project_name = "redis-connector"
environment  = "prod"

# Network Configuration
vpc_id    = "vpc-xxx"
subnet_id = "subnet-xxx"

# Redis Configuration
redis_host = "my-redis-cluster.xyz.0001.cac1.cache.amazonaws.com"
redis_port = 6379

# Application Configuration
origin_host = "https://staging.example.com"
app_domain  = "staging.example.com"
