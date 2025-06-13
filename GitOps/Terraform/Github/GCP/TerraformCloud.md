# Setting Up Terraform Cloud with GitHub Actions and Workload Identity Federation for GCP

This guide provides step-by-step instructions for integrating Terraform Cloud with GitHub using Workload Identity Federation for secure, keyless authentication to Google Cloud Platform (GCP).

## Prerequisites

- GitHub account and repository containing your Terraform code
- Terraform Cloud account
- Google Cloud Platform account with a project
- Basic familiarity with Terraform, GitHub Actions, and GCP

## 1. Setting Up Terraform Cloud

### 1.1 Create a Terraform Cloud Account

1. Navigate to [Terraform Cloud](https://app.terraform.io/signup/account) and sign up for an account if you don't already have one
2. Verify your email address

### 1.2 Create an Organization

1. After logging in, you'll be prompted to create an organization
2. Enter an organization name (e.g., `your-company-name`)
3. Click "Create organization"

### 1.3 Create a Workspace

1. In your organization, click "New Workspace"
2. Select "Version control workflow"
3. Choose GitHub as your VCS provider
4. If you haven't connected your GitHub account yet, click "Connect to GitHub" and follow the authorization process
5. Select your repository containing Terraform code
6. Enter a workspace name (e.g., `gcp-infrastructure`)
7. Click "Create workspace"

### 1.4 Configure Workspace Variables for GCP

1. Navigate to your new workspace
2. Go to "Variables" tab
3. Add the following environment variables:
   - `GOOGLE_PROJECT`: Your GCP project ID

### 1.5 Create a Team API Token

1. Go to "Organization Settings" → "Teams"
2. Click on your team (or create a new one)
3. Navigate to the "Team API Token" section
4. Click "Generate Token"
5. Copy and securely store this token (you'll need it for GitHub Actions)

## 2. Setting Up GCP Workload Identity Federation

There are two methods to set up Workload Identity Federation for GitHub Actions: using gcloud commands or Terraform.

### 2.1 Method 1: Using gcloud Commands

Run the following commands to set up Workload Identity Federation:

```bash
# Create the Workload Identity Pool
gcloud iam workload-identity-pools create github-pool \
  --project="YOUR_PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create the Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc github-provider \
  --project="YOUR_PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="Github pool provider" \
  --description="Workload Identity Provider for GitHub Actions" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="attribute.repository_owner=='YOUR_GITHUB_USERNAME'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create a Service Account for GitHub Actions
gcloud iam service-accounts create terraform-github-sa \
  --display-name="Terraform GitHub Actions Service Account" \
  --project="YOUR_PROJECT_ID"

# Grant the Service Account necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:terraform-github-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Get the project number
PROJECT_NUMBER=$(gcloud projects describe YOUR_PROJECT_ID --format='value(projectNumber)')

# Allow the GitHub Workload Identity to use the Service Account
gcloud iam service-accounts add-iam-policy-binding \
  terraform-github-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --project="YOUR_PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME"

# Get the Workload Identity Provider resource name (for GitHub Actions)
echo "Workload Identity Provider:"
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
```

Make sure to replace:
- `YOUR_PROJECT_ID` with your GCP project ID
- `YOUR_GITHUB_USERNAME` with your GitHub username or organization
- `YOUR_REPO_NAME` with your repository name

### 2.2 Method 2: Using Terraform

Create two files in your repository:

#### variables.tf
```hcl
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-pool"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "github-provider"
}
```

#### main.tf
```hcl
provider "google" {
  project = var.project_id
}

locals {
  service_account_id  = "terraform-github-sa"
  service_account_email = "${local.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

# Create the Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "Github pool provider"
  description                        = "Workload Identity Provider for GitHub Actions"
  disabled                           = false
  
  attribute_mapping = {
    "google.subject"         = "assertion.sub"
    "attribute.repository"   = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  
  attribute_condition = "attribute.repository_owner=='${var.github_repo_owner}'"
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create the Service Account
resource "google_service_account" "github_sa" {
  account_id   = local.service_account_id
  display_name = "Terraform GitHub Actions Service Account"
  description  = "Service account for GitHub Actions to deploy Terraform"
}

# Grant editor role to the Service Account
resource "google_project_iam_member" "github_sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

# Get project details
data "google_project" "project" {
  project_id = var.project_id
}

# Allow the GitHub Workload Identity Pool to impersonate the Service Account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repo_owner}/${var.github_repo}"
  ]
}

# Output the Workload Identity Provider resource name (for GitHub Actions)
output "workload_identity_provider" {
  description = "The Workload Identity Provider resource name to use in GitHub Actions"
  value       = "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github_provider.workload_identity_pool_provider_id}"
}

output "service_account_email" {
  description = "The Service Account email to use in GitHub Actions"
  value       = google_service_account.github_sa.email
}
```

To deploy:

```bash
terraform init
terraform apply -var="project_id=YOUR_PROJECT_ID" -var="github_repo_owner=YOUR_GITHUB_USERNAME" -var="github_repo=YOUR_REPO_NAME"
```

Make note of the outputs, which you'll need for your GitHub Actions workflow.

## 3. Configuring Your Terraform Code

### 3.1 Create or Update Terraform Backend Configuration

Create or update your `backend.tf` file to use Terraform Cloud:

```hcl
terraform {
  backend "remote" {
    organization = "your-organization-name"

    workspaces {
      name = "gcp-infrastructure"
    }
  }
}
```

### 3.2 Configure GCP Provider

Create or update your provider configuration in `providers.tf`:

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}
```

### 3.3 Structure Your Terraform Files

Ensure your repository has a well-organized structure:

```
.
├── .github/
│   └── workflows/
│       └── terraform.yml
├── modules/
│   └── ...
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── backend.tf
└── README.md
```

## 4. Setting Up GitHub Actions with Workload Identity Federation

### 4.1 Create GitHub Secrets

1. In your GitHub repository, go to "Settings" → "Secrets and variables" → "Actions"
2. Add the following repository secrets:
   - `TF_API_TOKEN`: The Team API Token you created in Terraform Cloud
   - `GCP_PROJECT_ID`: Your Google Cloud project ID

### 4.2 Create GitHub Actions Workflow

Create a file at `.github/workflows/terraform.yml`:

```yaml
name: 'Terraform for GCP'

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    name: 'Terraform'
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      id-token: write # Required for requesting the JWT for workload identity federation
      pull-requests: write # Required for commenting on PRs
    
    defaults:
      run:
        shell: bash

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - id: 'auth'
      name: 'Authenticate to Google Cloud'
      uses: 'google-github-actions/auth@v1'
      with:
        workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/providers/github-provider'
        service_account: 'terraform-github-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com'
        create_credentials_file: true

    - name: Set up Google Cloud SDK
      uses: google-github-actions/setup-gcloud@v1
      with:
        install_components: 'beta'

    - name: 'Verify Authentication'
      run: 'gcloud compute zones list --limit=1'
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

    - name: Terraform Format
      id: fmt
      run: terraform fmt -check -recursive
      continue-on-error: true

    - name: Terraform Init
      id: init
      run: terraform init

    - name: Terraform Validate
      id: validate
      run: terraform validate

    - name: Terraform Plan
      id: plan
      if: github.event_name == 'pull_request'
      run: terraform plan -var="project_id=${{ secrets.GCP_PROJECT_ID }}"
      continue-on-error: true

    - name: Update Pull Request
      uses: actions/github-script@v6
      if: github.event_name == 'pull_request'
      env:
        PLAN: "terraform\n${{ steps.plan.outputs.stdout }}"
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        script: |
          const output = `#### Terraform Format and Style 🖌\`${{ steps.fmt.outcome }}\`
          #### Terraform Initialization ⚙️\`${{ steps.init.outcome }}\`
          #### Terraform Validation 🤖\`${{ steps.validate.outcome }}\`
          #### Terraform Plan 📖\`${{ steps.plan.outcome }}\`

          <details><summary>Show Plan</summary>

          \`\`\`\n
          ${process.env.PLAN}
          \`\`\`

          </details>

          *Pushed by: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: output
          })

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve -var="project_id=${{ secrets.GCP_PROJECT_ID }}"
```

Make sure to replace:
- `PROJECT_NUMBER` with your GCP project number
- `YOUR_PROJECT_ID` with your GCP project ID

## 5. Handling Terraform Execution in GitHub Actions vs Terraform Cloud

When using Workload Identity Federation with GitHub Actions, you have two options for executing Terraform:

### 5.1 Option 1: Execute Terraform Locally in GitHub Actions

This is the approach demonstrated in the GitHub Actions workflow above. The workflow:
1. Authenticates to GCP using Workload Identity Federation
2. Runs Terraform commands directly in the GitHub Actions runner
3. Uses Terraform Cloud only for state management

Pros:
- Authentication is simpler since Workload Identity Federation works directly in the GitHub runner
- No need to pass credentials to Terraform Cloud

Cons:
- Less visibility into runs in the Terraform Cloud UI
- Cannot use Terraform Cloud's policy enforcement features

### 5.2 Option 2: Using Terraform Cloud Run Tasks

To use Terraform Cloud for execution while still leveraging Workload Identity Federation for authentication:

1. Modify your GitHub workflow to set environment variables for Terraform Cloud:

```yaml
- name: Generate GCP Access Token
  id: gcp-token
  run: |
    TOKEN=$(gcloud auth print-access-token)
    echo "GCP_ACCESS_TOKEN=$TOKEN" >> $GITHUB_ENV

- name: Configure Terraform Cloud Variables
  run: |
    curl \
      --header "Authorization: Bearer ${{ secrets.TF_API_TOKEN }}" \
      --header "Content-Type: application/vnd.api+json" \
      --request PATCH \
      --data '{
        "data": {
          "type": "vars",
          "attributes": {
            "key": "GOOGLE_OAUTH_ACCESS_TOKEN",
            "value": "${{ env.GCP_ACCESS_TOKEN }}",
            "category": "env",
            "sensitive": true
          }
        }
      }' \
      https://app.terraform.io/api/v2/workspaces/ws-YOUR_WORKSPACE_ID/vars/YOUR_VAR_ID
```

2. Update your provider configuration in Terraform to use the access token:

```hcl
provider "google" {
  project     = var.project_id
  region      = var.region
  access_token = var.google_oauth_access_token
}

variable "google_oauth_access_token" {
  description = "Google OAuth Access Token"
  type        = string
  sensitive   = true
}
```

Note: This approach is more complex and the access token has a limited lifetime (typically 1 hour).

## 6. Testing Your Setup

### 6.1 Create GCP Infrastructure Test

Create a simple test in `main.tf` to verify your setup:

```hcl
resource "google_storage_bucket" "test_bucket" {
  name          = "tf-test-bucket-${random_id.suffix.hex}"
  location      = "US"
  force_destroy = true
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "bucket_name" {
  value = google_storage_bucket.test_bucket.name
}
```

### 6.2 Make a Commit and Create a Pull Request

```bash
git checkout -b feature/test-wif
git add .
git commit -m "Test Workload Identity Federation setup"
git push origin feature/test-wif
```

Then create a pull request in GitHub and verify that:
1. GitHub Actions authenticates successfully with GCP
2. Terraform plan runs successfully
3. Terraform applies when merged to main

## 7. Best Practices and Advanced Configuration

### 7.1 Security Best Practices

For better security:

1. Use the principle of least privilege for your service account
2. Refine the attribute mapping and condition to be more specific
3. Regularly audit your Workload Identity Federation setup

Example of a more specific attribute condition:
```
attribute.repository_owner=='YOUR_GITHUB_USERNAME' && attribute.repository=='YOUR_REPO_NAME'
```

### 7.2 Working with Multiple Environments

For multiple environments (dev, staging, prod):

1. Create separate workspaces in Terraform Cloud for each environment
2. Create environment-specific GitHub workflows
3. Set up different attribute conditions for different environments

Example attribute condition for production:
```
attribute.repository_owner=='YOUR_GITHUB_USERNAME' && attribute.repository=='YOUR_REPO_NAME' && attribute.ref=='refs/heads/main'
```

### 7.3 Troubleshooting Workload Identity Federation

If you encounter authentication issues:

1. Check that the GitHub repository matches the attribute condition
2. Verify the Workload Identity Pool and Provider are correctly configured
3. Check that the service account has the necessary permissions
4. Verify the GitHub Actions permissions include `id-token: write`

To debug:
```yaml
- name: Debug Authentication
  run: |
    echo "GitHub Repository: $GITHUB_REPOSITORY"
    echo "GitHub Ref: $GITHUB_REF"
    echo "GitHub Actor: $GITHUB_ACTOR"
    gcloud auth list
```

## Conclusion

By following this guide, you've set up a secure, keyless authentication mechanism between GitHub Actions and GCP using Workload Identity Federation. This approach eliminates the need for long-lived service account keys, enhancing your security posture while making infrastructure deployment more efficient.

The workflow enables you to:
- Authenticate securely using short-lived tokens
- Automate testing and validation of your Terraform code
- Deploy infrastructure changes in a controlled manner
- Maintain separation of concerns between GitHub and GCP