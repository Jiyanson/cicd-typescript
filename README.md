# Task: Provision an EC2 node with Terraform and configure it with Ansible

## Goal

Create a small Linux server in AWS with Terraform, then configure it with Ansible so it runs Docker. Show that the full cycle works and can be repeated: create, configure, verify, destroy.

## Environment

| Item | Value |
|---|---|
| AWS region | `eu-north-1` (Stockholm) |
| Instance type | `t3.micro` (use `t2.micro` if `t3.micro` is rejected) |
| OS | Ubuntu 24.04 LTS |
| Terraform | `>= 1.5`, AWS provider `~> 5.0` |
| Ansible | Installed on the local machine |

Use `eu-north-1` everywhere. Region matters because the account's service control policy (SCP) blocks some regions and actions. Earlier, `eu-west-1` was denied for EC2 calls while `eu-north-1` worked.

## Prerequisites

- AWS CLI configured with a profile that can create EC2 resources
- `aws sts get-caller-identity` returns the expected account
- An SSH key pair at `~/.ssh/id_ed25519` (create with `ssh-keygen -t ed25519` if missing)
- Terraform and Ansible installed

## Folder layout

```
terraform/
├── main.tf          # provider, security group, key pair, AMI lookup, EC2 instance
└── terraform.tfstate  # local state (do not commit)
ansible/
├── inventory.ini    # the public IP of the node
└── site.yml         # installs Docker and configures the ubuntu user
```

## Steps

### 1. Check the region

```bash
aws ec2 describe-availability-zones --region eu-north-1
```

Expected: a list of zones with `"State": "available"`.

### 2. Create the infrastructure

```bash
cd terraform
terraform init
terraform plan  -var="my_ip_cidr=$(curl -s https://checkip.amazonaws.com)/32"
terraform apply -var="my_ip_cidr=$(curl -s https://checkip.amazonaws.com)/32"
```

Read the plan before applying. It should create only the security group, key pair, and EC2 instance. It should not create a VPC, because the configuration uses the existing default VPC.

Record the output:

```bash
terraform output public_ip
```

### 3. Configure the node with Ansible

Put the IP in `ansible/inventory.ini`:

```ini
[devops]
<PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
```

Then run:

```bash
cd ../ansible
ansible devops -i inventory.ini -m ping
ansible-playbook -i inventory.ini site.yml
```

### 4. Verify

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@<PUBLIC_IP> docker --version
```

Run the playbook a second time. The second run should report no changes. This shows the playbook is idempotent.

### 5. Destroy the node

Cost control matters, so destroy the resources after the demo:

```bash
cd ../terraform
terraform destroy -var="my_ip_cidr=<your-ip>/32"
```

Check the EC2 console in `eu-north-1` afterward to confirm no instance is running.

## Acceptance criteria

- [ ] `terraform plan` shows only the expected resources
- [ ] `terraform apply` finishes with a public IP output
- [ ] `ansible ... -m ping` returns `pong`
- [ ] `docker --version` works on the node over SSH
- [ ] A second Ansible run reports no changes
- [ ] `terraform destroy` completes and no instance remains in `eu-north-1`

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `UnauthorizedOperation ... explicit deny in a service control policy` | The SCP blocks that action or region | Use `eu-north-1`, or check the SCP with your account admin |
| `terraform state list` is empty but resources exist | State file doesn't match the resources | Check the console, then delete manually or import |
| SSH times out | Security group doesn't allow your current IP | Re-run `terraform apply` with your current IP |
| `Permission denied (publickey)` | Wrong key or user | Confirm `ansible_user=ubuntu` and the key path |
| Playbook changes on every run | Task not idempotent | Use Ansible modules instead of raw shell commands |

## Interview summary

- **Terraform** creates and tracks infrastructure. `plan` before `apply`, and `destroy` to clean up.
- **Ansible** configures the server. Playbooks are idempotent, so repeated runs are safe.
- **Least privilege:** SSH is limited to one IP, not `0.0.0.0/0`.
- **Credentials:** a production pipeline should use OIDC instead of long-lived access keys. Explain that the account's SCP limits forced a different setup here.
