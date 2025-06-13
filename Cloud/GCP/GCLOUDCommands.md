```bash
gcloud iam workload-identity-pools create github-pool \
  --project="plucky-furnace-450709-a6" \
  --location="global" \
  --display-name="GitHub Actions Pool"
```

```bash
gcloud iam workload-identity-pools providers create-oidc github-main-provider \
  --project="plucky-furnace-450709-a6" \
  --location="global" \
  --workload-identity-pool="github-main-pool" \
  --display-name="Github pool provider" \
  --description="My workload pool provider description" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="attribute.repository_owner=='GerromeSieger'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

```bash
gcloud iam service-accounts create terraform-github-sa \
  --display-name="Terraform GitHub Actions Service Account" \
  --project="plucky-furnace-450709-a6"
```

```bash
gcloud projects add-iam-policy-binding plucky-furnace-450709-a6 \
  --member="serviceAccount:terraform-github-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com" \
  --role="roles/editor"
```

```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform-github-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com \
  --project="plucky-furnace-450709-a6" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/475219846787/locations/global/workloadIdentityPools/github-main-pool/attribute.repository/GerromeSieger/Terraform-Scripts"
``` 

## Gitlab

# Create workload identity pool
gcloud iam workload-identity-pools create "gitlab-main-pool" \
  --project="plucky-furnace-450709-a6" \
  --location="global" \
  --display-name="GitLab project ID 67361666"

# Create OIDC provider with the required configuration in the workload identity pool
gcloud iam workload-identity-pools providers create-oidc "gitlab-main-provider" \
  --location="global" \
  --project="plucky-furnace-450709-a6" \
  --workload-identity-pool="gitlab-main-pool" \
  --issuer-uri="https://auth.gcp.gitlab.com/oidc/GerromeSieger" \
  --display-name="GitLab project ID 67361666" \
  --attribute-mapping="attribute.guest_access=assertion.guest_access,attribute.planner_access=assertion.planner_access,attribute.reporter_access=assertion.reporter_access,attribute.developer_access=assertion.developer_access,attribute.maintainer_access=assertion.maintainer_access,attribute.owner_access=assertion.owner_access,attribute.namespace_id=assertion.namespace_id,attribute.namespace_path=assertion.namespace_path,attribute.project_id=assertion.project_id,attribute.project_path=assertion.project_path,attribute.user_id=assertion.user_id,attribute.user_login=assertion.user_login,attribute.user_email=assertion.user_email,attribute.user_access_level=assertion.user_access_level,google.subject=assertion.sub"

# Grant the "container.clusters.get" permission to your service account
gcloud projects add-iam-policy-binding plucky-furnace-450709-a6 \
  --member="serviceAccount:gitlab-ci-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com" \
  --role="roles/container.developer"

# Allow the Workload Identity Pool to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  gitlab-ci-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com \
  --project="plucky-furnace-450709-a6" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principal://iam.googleapis.com/projects/475219846787/locations/global/workloadIdentityPools/gitlab-main-pool/subject/usr:GerromeSieger/pid:67361666/sys:ci:9280859960/nam:GerromeSieger"


## Bitbucket

# Create the workload identity pool for Bitbucket
gcloud iam workload-identity-pools create bitbucket-pool \
  --project="plucky-furnace-450709-a6" \
  --location="global" \
  --display-name="Bitbucket Pipelines Pool"

# Create the OIDC provider for Bitbucket
gcloud iam workload-identity-pools providers create-oidc bitbucket-provider \
  --project="plucky-furnace-450709-a6" \
  --location="global" \
  --workload-identity-pool="bitbucket-pool" \
  --display-name="Bitbucket pool provider" \
  --description="Bitbucket workload pool provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.workspace" \
  --attribute-condition="attribute.workspace=='gerrome'" \
  --issuer-uri="https://api.bitbucket.org/2.0/workspaces/gerrome/pipelines-config/identity/oidc" \
  --allowed-audiences="ari:cloud:bitbucket::workspace/126b78c5-9f0e-4226-bde2-f079f957fea0"

# Create a service account (only if you need a separate one from GitHub)
gcloud iam service-accounts create terraform-bitbucket-sa \
  --display-name="Terraform Bitbucket Pipelines Service Account" \
  --project="plucky-furnace-450709-a6"

# Grant IAM roles to the service account
gcloud projects add-iam-policy-binding plucky-furnace-450709-a6 \
  --member="serviceAccount:terraform-bitbucket-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com" \
  --role="roles/editor"

# Bind the service account to the workload identity
gcloud iam service-accounts add-iam-policy-binding \
  terraform-bitbucket-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com \
  --project="plucky-furnace-450709-a6" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/475219846787/locations/global/workloadIdentityPools/bitbucket-pool/attribute.repository/YOUR_REPOSITORY_NAME"    

gcloud iam workload-identity-pools providers update-oidc bitbucket-provider \
  --project="plucky-furnace-450709-a6" \
  --location="global" \
  --workload-identity-pool="bitbucket-pool" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.workspace" \
  --attribute-condition="attribute.workspace=='126b78c5-9f0e-4226-bde2-f079f957fea0'" \
  --issuer-uri="https://api.bitbucket.org/2.0/workspaces/gerrome/pipelines-config/identity/oidc" \
  --allowed-audiences="ari:cloud:bitbucket::workspace/126b78c5-9f0e-4226-bde2-f079f957fea0"

gcloud iam service-accounts add-iam-policy-binding \
  terraform-bitbucket-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com \
  --project="plucky-furnace-450709-a6" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/475219846787/locations/global/workloadIdentityPools/bitbucket-pool/attribute.workspace/126b78c5-9f0e-4226-bde2-f079f957fea0" 
  --condition=None


gcloud iam service-accounts add-iam-policy-binding \
  terraform-bitbucket-sa@plucky-furnace-450709-a6.iam.gserviceaccount.com \
  --member="principalSet://iam.googleapis.com/projects/475219846787/locations/global/workloadIdentityPools/bitbucket-pool/attribute.repository_uuid/8405f131-3b6d-42d2-815d-a5cae818ef4c" \
  --role="roles/iam.serviceAccountTokenCreator"