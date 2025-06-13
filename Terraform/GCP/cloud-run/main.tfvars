# Core GCP project configuration
project_id      = "plucky-furnace-450709-a6"
region          = "us-central1"
zone            = "us-central1-a"
network_name    = "default"
subnetwork_name = "default"

# Service configuration
service_name          = "my-application"
container_port        = 80
container_cpu         = "1000m" # 1 vCPU
container_memory      = "512Mi" # 512 MB RAM
min_instances         = 1       # Keep at least 1 instance warm
max_instances         = 10      # Scale up to 10 instances
container_concurrency = 80      # Handle 80 concurrent requests per instance
request_timeout       = 300     # 5-minute timeout
cpu_throttling        = true    # Enable CPU throttling when idle

# Service account for Cloud Run (leave empty to use default compute service account)
service_account_email = ""

# Environment variables for your application
environment_vars = {
  NODE_ENV      = "production"
  LOG_LEVEL     = "info"
  DATABASE_HOST = "10.0.0.1"
  DATABASE_NAME = "mydb"
  # Do not include sensitive values in tfvars - use Secret Manager instead
  # DATABASE_PASSWORD   = "sensitive-value-should-not-be-here"
}

# Labels to apply to resources
labels = {
  environment = "production"
  team        = "backend"
  application = "my-app"
  managed-by  = "terraform"
  cost-center = "123456"
}

# Allow public access to the Cloud Run service
allow_public_access = true