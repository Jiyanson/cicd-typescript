# Terraform

This area is reserved for managed infrastructure and repository configuration.
The planned layout is:

```text
terraform/
├── environments/     # Development and staging configuration
└── modules/          # Reusable infrastructure components
```

Provider locks, state files, and generated plans must not be committed.
