# EC2 infrastructure

This directory provisions two Ubuntu EC2 nodes for a K3s cluster in the
account's default VPC. It creates an AWS key-pair entry from the local Ed25519
public key and a shared security group for SSH and private node-to-node K3s
traffic.

## Files

- `versions.tf`: Terraform and AWS provider requirements.
- `providers.tf`: AWS provider configuration.
- `variables.tf`: configurable inputs and their defaults.
- `main.tf`: AMI lookup, key pair, security group, and K3s EC2 nodes.
- `outputs.tf`: instance IDs, public/private IPs, and SSH commands.
- `terraform.tfvars.example`: safe example of local input values.
- `.terraform.lock.hcl`: provider versions selected by `terraform init`.

## Before applying

1. Confirm `~/.ssh/id_ed25519` and `~/.ssh/id_ed25519.pub` exist.
2. Confirm the selected AWS CLI profile points to the expected account.
3. Copy `terraform.tfvars.example` to `terraform.tfvars`.
4. Replace the example `ssh_allowed_cidr` with your public IPv4 address and a
   `/32` suffix.
5. Confirm the selected AWS region has a default VPC.

Do not commit `terraform.tfvars`, private SSH keys, state files, or plan files.
The provider lock file should be committed.

## Commands

Run these commands from this directory, replacing `your-profile`:

```bash
cp terraform.tfvars.example terraform.tfvars
AWS_PROFILE=your-profile terraform init
AWS_PROFILE=your-profile terraform fmt -check
AWS_PROFILE=your-profile terraform validate
AWS_PROFILE=your-profile terraform plan -out=tfplan
AWS_PROFILE=your-profile terraform apply tfplan
```

After applying, display the node addresses and connection commands with:

```bash
terraform output k3s_nodes_public_ips
terraform output k3s_nodes_private_ips
terraform output ssh_command
```

Destroy the instances when they are no longer needed to avoid ongoing AWS
costs:

```bash
AWS_PROFILE=your-profile terraform destroy
```
