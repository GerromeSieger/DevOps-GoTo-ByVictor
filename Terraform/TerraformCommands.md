# Essential Terraform Commands Guide

## Basic Commands

1. Initialize a Terraform working directory:
```bash
terraform init
```

2. Preview infrastructure changes:
```bash
terraform plan
```

3. Apply infrastructure changes:
```bash
terraform apply
```

4. Destroy provisioned infrastructure:
```bash
terraform destroy
```

## Advanced Planning Commands

5. Save the plan to a file:
```bash
terraform plan -out=tfplan
```

6. Apply a saved plan:
```bash
terraform apply tfplan
```

7. Plan with variable file:
```bash
terraform plan -var-file="prod.tfvars"
```

8. Plan with multiple variable files:
```bash
terraform plan -var-file="prod.tfvars" -var-file="secrets.tfvars"
```

## State Management

9. Show current state:
```bash
terraform show
```

10. List resources in state:
```bash
terraform state list
```

11. Remove resource from state:
```bash
terraform state rm 'aws_instance.example'
```

12. Move resource in state:
```bash
terraform state mv 'aws_instance.old' 'aws_instance.new'
```

## Workspace Management

13. List workspaces:
```bash
terraform workspace list
```

14. Create new workspace:
```bash
terraform workspace new dev
```

15. Select workspace:
```bash
terraform workspace select prod
```

## Advanced Operations

16. Format terraform files:
```bash
terraform fmt
```

17. Validate terraform files:
```bash
terraform validate
```

18. Refresh state file:
```bash
terraform refresh
```

19. Import existing infrastructure:
```bash
terraform import aws_instance.example i-1234567890abcdef0
```

20. Apply with auto-approve (use with caution):
```bash
terraform apply -auto-approve
```

## Additional Useful Commands

21. Show providers:
```bash
terraform providers
```

22. Clean up cached providers and modules:
```bash
terraform init -upgrade
```

23. Target specific resource:
```bash
terraform apply -target=aws_instance.example
```

24. Auto apply a specific plan:
```bash
terraform apply -auto-approve "tfplan"
```

25. Show output values:
```bash
terraform output
```

26. Show specific output value:
```bash
terraform output instance_ip
```

## Variables Usage Examples

### Command Line Variables
```bash
terraform plan -var="instance_count=2"
```

### Variable File (terraform.tfvars)
```hcl
instance_count = 2
environment = "production"
region = "us-west-2"
```

### Auto-loaded Variable Files
Terraform automatically loads these files in order:
- `terraform.tfvars`
- `terraform.tfvars.json`
- `*.auto.tfvars`
- `*.auto.tfvars.json`

### Environment Variables
```bash
export TF_VAR_instance_count=2
terraform plan
```

## Best Practices Tips

1. Always run `terraform plan` before `terraform apply`
2. Use `-out` flag to save plans for consistent applies
3. Use workspaces to manage different environments
4. Version control your terraform files
5. Don't commit `.tfstate` files
6. Use remote state storage when working in teams
7. Lock state files to prevent concurrent modifications
8. Use variables for values that might change
9. Format code using `terraform fmt` before committing
10. Use meaningful names for resources and data sources

Remember to handle sensitive data carefully and never commit secrets to version control!