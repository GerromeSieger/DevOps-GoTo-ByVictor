# Setting Up GitLab CI/CD with Workload Identity Federation for GCP

This guide provides step-by-step instructions for integrating GitLab CI/CD with Google Cloud Platform (GCP) using Workload Identity Federation for secure, keyless authentication.

## Prerequisites

- GitLab account and repository containing your application code
- Google Cloud Platform account with a project
- Basic familiarity with GitLab CI/CD, Terraform, and GCP

## 1. Setting Up Your GCP Project

### 1.1 Enable Required APIs

```bash
# Enable the required APIs
gcloud services enable iam.googleapis.com
gcloud services enable iamcredentials.googleapis.com
gcloud services enable sts.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### 1.2 Set Environment Variables

```bash
# Set environment variables for easier script writing
export PROJECT_ID="your-gcp-project-id"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
export GITLAB_HOST="gitlab.com"  # Change if using self-hosted GitLab
export GITLAB_USERNAME="YourGitLabUsername"  # Your GitLab username or organization
export GITLAB_PROJECT_ID="YourProjectID"  # Your GitLab project ID (number)
export GITLAB_PROJECT_PATH="$GITLAB_USERNAME/YourProjectName"  # Path in format username/project
```

## 2. Setting Up GCP Workload Identity Federation

There are two methods to set up Workload Identity Federation for GitLab CI/CD: using gcloud commands or Terraform.

### 2.1 Method 1: Using gcloud Commands

```bash
# Create the Workload Identity Pool
gcloud iam workload-identity-pools create "gitlab-pool" \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitLab CI/CD Pool"

# Create the Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "gitlab-provider" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="gitlab-pool" \
  --display-name="GitLab Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.project_id=assertion.project_id,attribute.project_path=assertion.project_path,attribute.namespace_id=assertion.namespace_id,attribute.namespace_path=assertion.namespace_path,attribute.user_id=assertion.user_id,attribute.user_login=assertion.user_login" \
  --attribute-condition="attribute.project_path=='$GITLAB_PROJECT_PATH'" \
  --issuer-uri="https://gitlab.com"  # Change if using self-hosted GitLab

# Create a Service Account for GitLab CI
gcloud iam service-accounts create "gitlab-ci-sa" \
  --display-name="GitLab CI/CD Service Account" \
  --project="$PROJECT_ID"

# Grant the Service Account necessary permissions
# Modify these roles according to your needs
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:gitlab-ci-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:gitlab-ci-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/viewer"

# Allow the GitLab Workload Identity to use the Service Account
gcloud iam service-accounts add-iam-policy-binding \
  "gitlab-ci-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/gitlab-pool/attribute.project_id/$GITLAB_PROJECT_ID"

# Output the Workload Identity Provider resource name and Service Account email (for GitLab CI)
echo "Workload Identity Provider:"
echo "projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab-provider"
echo "Service Account Email:"
echo "gitlab-ci-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

### 2.2 Method 2: Using Terraform

Create two files in your repository:

#### variables.tf
```hcl
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "gitlab_project_id" {
  description = "GitLab project ID (numeric)"
  type        = string
}

variable "gitlab_username" {
  description = "GitLab username or organization"
  type        = string
}

variable "project_path" {
  description = "GitLab project path (username/project)"
  type        = string
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "gitlab-pool"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "gitlab-provider"
}

variable "service_account_id" {
  description = "Service Account ID"
  type        = string
  default     = "gitlab-ci-sa"
}
```

#### main.tf
```hcl
provider "google" {
  project = var.project_id
}

# Create the service account for GitLab CI
resource "google_service_account" "gitlab_ci_sa" {
  account_id   = var.service_account_id
  display_name = "GitLab CI/CD Service Account"
  description  = "Service account for GitLab CI/CD pipeline"
}

# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "gitlab_pool" {
  workload_identity_pool_id = var.pool_id
  display_name              = "GitLab project ID ${var.gitlab_project_id}"
  description               = "Identity pool for GitLab CI/CD"
  disabled                  = false
}

# Create the Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "gitlab_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitLab project ID ${var.gitlab_project_id}"
  description                        = "Workload Identity Provider for GitLab CI/CD"
  disabled                           = false
  
  attribute_mapping = {
    "google.subject"           = "assertion.sub"
    "attribute.namespace_path" = "assertion.namespace_path"
    "attribute.project_path"   = "assertion.project_path"
    "attribute.project_id"     = "assertion.project_id"
    "attribute.ref"            = "assertion.ref"
    "attribute.ref_type"       = "assertion.ref_type"
    "attribute.user_id"        = "assertion.user_id"
    "attribute.user_login"     = "assertion.user_login"
  }

  attribute_condition = "attribute.project_path=='${var.project_path}'"
  
  oidc {
    issuer_uri = "https://gitlab.com"
  }
}

# Grant the service account container developer role
resource "google_project_iam_member" "gitlab_sa_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.gitlab_ci_sa.email}"
}

# Grant the service account viewer role
resource "google_project_iam_member" "gitlab_sa_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.gitlab_ci_sa.email}"
}

# Get project number
data "google_project" "project" {
  project_id = var.project_id
}

# Allow the GitLab Workload Identity Pool to impersonate the service account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.gitlab_ci_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id}/attribute.project_id/${var.gitlab_project_id}"
  ]
}

# Outputs
output "workload_identity_provider" {
  description = "The Workload Identity Provider resource name to use in GitLab CI configuration"
  value       = "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gitlab_provider.workload_identity_pool_provider_id}"
}

output "service_account_email" {
  description = "The Service Account email to use in GitLab CI configuration"
  value       = google_service_account.gitlab_ci_sa.email
}

output "principal_set_for_project" {
  description = "The principal set string for the GitLab project"
  value       = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id}/attribute.project_id/${var.gitlab_project_id}"
}
```

To deploy:

```bash
terraform init
terraform apply \
  -var="project_id=your-gcp-project-id" \
  -var="gitlab_project_id=12345678" \
  -var="gitlab_username=YourGitLabUsername" \
  -var="project_path=YourGitLabUsername/YourProjectName"
```

Make note of the outputs, which you'll need for your GitLab CI/CD configuration.

## 3. Setting Up GitLab CI/CD with Workload Identity Federation

### 3.1 Create GitLab CI/CD Variables

In your GitLab repository:

1. Go to "Settings" → "CI/CD"
2. Expand the "Variables" section
3. Add the following variables:
   - `GCP_PROJECT_ID`: Your GCP project ID
   - `GCP_PROJECT_NUMBER`: Your GCP project number
   - `WORKLOAD_IDENTITY_POOL_ID`: The ID of your workload identity pool (e.g., "gitlab-pool")
   - `WORKLOAD_IDENTITY_PROVIDER_ID`: The ID of your workload identity provider (e.g., "gitlab-provider")
   - `SERVICE_ACCOUNT_EMAIL`: The email of the service account (from Terraform output)

### 3.2 Create GitLab CI/CD Pipeline Configuration for Terraform

Create or update `.gitlab-ci.yml` in your repository:

```yaml
# Custom Terraform CI with GCP Workload Identity Federation

stages:
  - validate
  - test
  - plan
  - apply
  - cleanup

# SAST scanning for Terraform
include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml

variables:
  TF_ROOT: ${CI_PROJECT_DIR}
  TF_STATE_NAME: default
  # Set this to true when you're ready to use Terraform Cloud
  TF_CLOUD_ENABLED: "true"

# Base configuration for Terraform jobs
.terraform:
  image: google/cloud-sdk:slim
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}
  before_script:
    # Configure GCP Workload Identity Federation
    - echo "$GITLAB_OIDC_TOKEN" > token.txt
    - gcloud iam workload-identity-pools create-cred-config "projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}" --service-account="${SERVICE_ACCOUNT_EMAIL}" --service-account-token-lifetime-seconds=3600 --output-file="$CI_PROJECT_DIR/credentials.json" --credential-source-file="token.txt" --credential-source-type=text
    - export GOOGLE_APPLICATION_CREDENTIALS="$CI_PROJECT_DIR/credentials.json"
    
    # Install Terraform
    - apt-get update && apt-get install -y wget unzip
    - wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
    - unzip terraform_1.5.7_linux_amd64.zip && mv terraform /usr/local/bin/
    
    # Configure Terraform Cloud authentication
    - |
      if [ "$TF_CLOUD_ENABLED" = "true" ]; then
        mkdir -p ~/.terraform.d
        echo '{"credentials":{"app.terraform.io":{"token":"'"${TF_API_TOKEN}"'"}}}' > ~/.terraform.d/credentials.tfrc.json
      fi
    
    # Navigate to Terraform directory
    - cd ${TF_ROOT}
    - terraform --version

fmt:
  extends: .terraform
  stage: validate
  script:
    - terraform fmt -check -recursive
  allow_failure: true
  needs: []

validate:
  extends: .terraform
  stage: validate
  script:
    - terraform init
    - terraform validate
  needs: []

plan:
  extends: .terraform
  stage: plan
  script:
    - terraform init
    - terraform plan -out=plan.tfplan -var="project_id=$GCP_PROJECT_ID"
  artifacts:
    paths:
      - ${TF_ROOT}/plan.tfplan
    expire_in: 1 week
  environment:
    name: $TF_STATE_NAME
    action: prepare

apply:
  extends: .terraform
  stage: apply
  script:
    - terraform init
    - terraform apply -auto-approve plan.tfplan 
  dependencies:
    - plan
  environment:
    name: $TF_STATE_NAME
    action: start
 # when: manual
```

This pipeline uses the Google Cloud SDK image with Terraform installed to:
1. Authenticate to GCP using Workload Identity Federation
2. Run terraform validate and plan on all merge requests
3. Apply changes after manual approval on the main branch
```

## 4. Testing Your Setup

After setting up your pipeline, you'll want to test that everything is working correctly:

1. Commit your changes including the `.gitlab-ci.yml` file:
   ```bash
   git add .gitlab-ci.yml
   git commit -m "Add Terraform pipeline with GCP Workload Identity Federation"
   git push
   ```

2. In GitLab, navigate to CI/CD → Pipelines to see your pipeline run.

3. Verify that the validate and plan stages complete successfully.

The first time you run this pipeline, it may take a bit longer as it needs to download Terraform providers and modules.

## 5. Best Practices and Advanced Configuration

### 6.1 Security Best Practices

For better security:

1. Use the principle of least privilege for your service account
2. Refine the attribute mapping and condition to be more specific
3. Regularly audit your Workload Identity Federation setup

Example of a more specific attribute condition:
```
attribute.project_path=='YourGitLabUsername/YourProjectName' && attribute.ref_type=='branch' && attribute.ref=='main'
```

### 6.2 Working with Multiple Environments

For multiple environments (dev, staging, prod):

1. Use GitLab environments to define deployment targets
2. Create environment-specific service accounts in GCP
3. Set up different attribute conditions for different environments

Example `.gitlab-ci.yml` with multiple environments:

```yaml
stages:
  - deploy

.deploy_template: &deploy_template
  image: google/cloud-sdk:slim
  before_script:
    # Configure workload identity
    - echo "$GITLAB_OIDC_TOKEN" > token.txt
    - gcloud iam workload-identity-pools create-cred-config "projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}" --service-account="${SERVICE_ACCOUNT_EMAIL}" --output-file="$CI_PROJECT_DIR/credentials.json" --credential-source-file="token.txt"
    - export GOOGLE_APPLICATION_CREDENTIALS="$CI_PROJECT_DIR/credentials.json"
    - gcloud auth login --cred-file="$CI_PROJECT_DIR/credentials.json"
    - gcloud config set project "${GCP_PROJECT_ID}"

deploy_dev:
  <<: *deploy_template
  stage: deploy
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}
  variables:
    SERVICE_ACCOUNT_EMAIL: ${DEV_SERVICE_ACCOUNT_EMAIL}
  script:
    - echo "Deploying to dev environment"
    - gcloud compute instances list --filter="name~'dev-*'"
  environment:
    name: development
  only:
    - develop

deploy_prod:
  <<: *deploy_template
  stage: deploy
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}
  variables:
    SERVICE_ACCOUNT_EMAIL: ${PROD_SERVICE_ACCOUNT_EMAIL}
  script:
    - echo "Deploying to production environment"
    - gcloud compute instances list --filter="name~'prod-*'"
  environment:
    name: production
  only:
    - main
  when: manual
```

### 6.3 Using with GitLab Self-Managed

If you're using a self-managed GitLab instance, adjust the issuer URI in your Workload Identity Provider:

```hcl
oidc {
  issuer_uri = "https://your-gitlab-instance.example.com"
}
```

And in your `.gitlab-ci.yml`, update the audience accordingly:

```yaml
id_tokens:
  GITLAB_OIDC_TOKEN:
    aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}
```

### 6.4 Additional Troubleshooting

If you encounter authentication issues:

1. Check the logs for error messages
2. Verify that the GitLab project ID matches what's in your attribute condition
3. Ensure the Workload Identity Pool and Provider are correctly configured
4. Verify the service account has the necessary permissions

Add this debugging job to your pipeline:

```yaml
debug-wif:
  image: google/cloud-sdk:slim
  stage: test
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}
  script:
    # Save token to file and display some of its content
    - echo "$GITLAB_OIDC_TOKEN" > token.txt
    - echo "First 20 characters of token: $(head -c 20 token.txt)"
    
    # Print GitLab environment variables
    - echo "GitLab Project ID: $CI_PROJECT_ID"
    - echo "GitLab Project Path: $CI_PROJECT_PATH"
    - echo "GitLab User: $GITLAB_USER_LOGIN"
    
    # Install jq
    - apt-get update && apt-get install -y jq
    
    # Decode JWT token (without signature)
    - jq -R 'split(".") | .[1] | @base64d | fromjson' token.txt
    
    # Try authentication and capture detailed error
    - >
      gcloud iam workload-identity-pools create-cred-config 
      "projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_ID}/providers/${WORKLOAD_IDENTITY_PROVIDER_ID}" 
      --service-account="${SERVICE_ACCOUNT_EMAIL}" 
      --output-file="$CI_PROJECT_DIR/credentials.json" 
      --credential-source-file="token.txt" 
      --credential-source-type=text 
      2>&1 | tee auth_error.log || echo "Authentication failed, see log for details"
    
    # Check GCP Workload Identity Pool configuration
    - gcloud iam workload-identity-pools providers describe "${WORKLOAD_IDENTITY_PROVIDER_ID}" --location=global --workload-identity-pool="${WORKLOAD_IDENTITY_POOL_ID}" --project="${GCP_PROJECT_ID}" 2>&1 | tee provider_config.log || echo "Failed to retrieve provider configuration"