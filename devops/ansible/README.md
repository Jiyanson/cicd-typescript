# Ansible beginner guide: create the K3s cluster

This guide explains how Ansible is used in this project. It assumes that this
is your first time using Ansible.

## 1. What Ansible does in this project

Terraform and Ansible have different jobs:

```text
Terraform                         Ansible
---------                         -------
Creates the AWS infrastructure   Connects to the EC2 instances
Creates two EC2 instances        Prepares Ubuntu
Creates the security group       Installs K3s
Creates the AWS key pair         Connects the agent to the server
Returns public/private IPs       Verifies the cluster
```

Terraform must create the EC2 instances before Ansible can configure them.

Ansible runs on your local computer. Your computer is called the **control
node**. The two EC2 instances are called the **managed nodes**.

```text
Your computer (Ansible)
        |
        | SSH with ~/.ssh/id_ed25519
        |
        +-------------------+
        |                   |
        v                   v
  k3s-server EC2      k3s-agent EC2
  control plane       worker node
```

Ansible does not need an agent installed on the EC2 instances. It connects
with SSH and uses Python, which is already available on the Ubuntu AMI.

## 2. Important Ansible vocabulary

### Inventory

The inventory tells Ansible which machines it should manage and how to connect
to them. In this project, the real inventory is:

```text
inventory/hosts.ini
```

It contains the public and private addresses of both EC2 instances.

### Playbook

A playbook is the main list of operations Ansible must perform. The playbook
for this project is:

```text
site.yml
```

It runs the roles in the correct order: prepare the nodes, install the server,
join the agent, and verify the cluster.

### Role

A role is a reusable group of related tasks. This project has three roles:

- `common`: prepares both Ubuntu machines.
- `k3s_server`: installs the K3s control plane.
- `k3s_agent`: installs the worker and joins it to the server.

### Task

A task is one action, such as installing a package, copying a file, or starting
a service.

### Module

A module is an Ansible tool used by a task. For example, the `apt` module
installs Ubuntu packages and the `systemd` module manages services.

### Idempotence

An idempotent playbook can be executed several times safely. The first run
changes the machines. A second run should mostly report `ok` because the
required configuration already exists.

## 3. Project structure

```text
devops/ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.ini
│   └── hosts.ini.example
├── roles/
│   ├── common/
│   │   ├── handlers/main.yml
│   │   └── tasks/main.yml
│   ├── k3s_server/
│   │   ├── defaults/main.yml
│   │   └── tasks/main.yml
│   └── k3s_agent/
│       ├── defaults/main.yml
│       └── tasks/main.yml
├── site.yml
└── README.md
```

### `ansible.cfg`

This is the local Ansible configuration. It tells Ansible to:

- use `inventory/hosts.ini` by default;
- find roles inside the `roles` directory;
- verify SSH host keys;
- use SSH pipelining to reduce connection overhead.

### `inventory/hosts.ini.example`

This is a safe template that can be committed to Git. It contains placeholders
instead of real IP addresses.

### `inventory/hosts.ini`

This is your real local inventory. It contains the actual EC2 addresses and is
ignored by Git.

### `site.yml`

This is the entry point. When you run `ansible-playbook site.yml`, Ansible
reads this file and executes every play in order.

## 4. Create the EC2 instances first

Go to the Terraform directory:

```bash
cd devops/terraform
```

Review the infrastructure:

```bash
AWS_PROFILE=terraform terraform plan
```

Create the two EC2 instances:

```bash
AWS_PROFILE=terraform terraform apply
```

Terraform should create:

- `k3s-server`;
- `k3s-agent`;
- one shared security group;
- one shared AWS key pair.

## 5. Get the EC2 addresses

Display the public addresses:

```bash
terraform output k3s_nodes_public_ips
```

Example result:

```text
{
  "k3s-agent"  = "13.50.10.20"
  "k3s-server" = "13.50.30.40"
}
```

Display the private addresses:

```bash
terraform output k3s_nodes_private_ips
```

Example result:

```text
{
  "k3s-agent"  = "172.31.20.10"
  "k3s-server" = "172.31.30.22"
}
```

The public addresses are used by Ansible for SSH. The private addresses are
used by K3s for communication inside the AWS VPC.

## 6. Prepare the inventory

Go to the Ansible directory:

```bash
cd ../ansible
```

If `inventory/hosts.ini` does not exist, copy the example:

```bash
cp inventory/hosts.ini.example inventory/hosts.ini
```

Open `inventory/hosts.ini` and replace the four placeholder addresses:

```ini
[k3s_server]
k3s-server ansible_host=SERVER_PUBLIC_IP k3s_private_ip=SERVER_PRIVATE_IP

[k3s_agents]
k3s-agent ansible_host=AGENT_PUBLIC_IP k3s_private_ip=AGENT_PRIVATE_IP

[k3s:children]
k3s_server
k3s_agents

[k3s:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
```

Meaning of each value:

- `k3s-server` and `k3s-agent` are Ansible host names.
- `ansible_host` is the EC2 public IP used for SSH.
- `k3s_private_ip` is the EC2 private IP used by K3s.
- `ansible_user=ubuntu` selects the Ubuntu SSH user.
- `ansible_ssh_private_key_file` selects your private SSH key.
- `ansible_python_interpreter` tells Ansible which Python executable to use.

Do not use the `.pub` file for `ansible_ssh_private_key_file`. SSH must use the
private key:

```text
Correct:   ~/.ssh/id_ed25519
Incorrect: ~/.ssh/id_ed25519.pub
```

## 7. Verify SSH manually

Ansible checks SSH host identities for security. Connect to each instance once
before running the playbook:

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@SERVER_PUBLIC_IP
```

Accept the server fingerprint only after checking that the address is correct,
then exit:

```bash
exit
```

Repeat the same operation for the agent public IP.

## 8. Understand what Ansible sees

From `devops/ansible`, display the inventory tree:

```bash
ansible-inventory --graph
```

Expected structure:

```text
@k3s:
  |--@k3s_server:
  |  |--k3s-server
  |--@k3s_agents:
  |  |--k3s-agent
```

This means that the `k3s` group contains the server and agent groups.

## 9. Test Ansible connectivity

Run the Ansible ping module:

```bash
ansible k3s -m ping
```

This is not a network ICMP ping. Ansible connects over SSH, starts Python on
the remote machine, and returns a result.

Expected result for both nodes:

```text
k3s-server | SUCCESS => ... "ping": "pong"
k3s-agent  | SUCCESS => ... "ping": "pong"
```

Do not run the installation playbook until both nodes return `SUCCESS`.

## 10. Check the playbook before running it

Validate its syntax:

```bash
ansible-playbook site.yml --syntax-check
```

Display the target hosts without changing anything:

```bash
ansible-playbook site.yml --list-hosts
```

Display the tasks that will be executed:

```bash
ansible-playbook site.yml --list-tasks
```

## 11. Install the K3s cluster

Run the complete playbook:

```bash
ansible-playbook site.yml
```

Ansible uses `become: true` to run administrative operations with `sudo`. The
default Ubuntu EC2 user can use sudo without entering a password.

The playbook performs these stages:

### Stage 1: validate the inventory

Ansible confirms that there is exactly one server and at least one agent.

### Stage 2: prepare both machines

The `common` role:

- installs `curl` and CA certificates;
- sets a unique hostname on each EC2;
- disables swap;
- loads the required kernel modules;
- enables IP forwarding and bridge networking.

### Stage 3: install the K3s server

The `k3s_server` role:

- downloads the official K3s installer;
- installs K3s in server mode;
- uses the server private IP;
- starts the `k3s` service;
- waits for the Kubernetes API on port `6443`;
- reads the node token generated by K3s.

The token is marked `no_log`, so Ansible does not print it in the terminal.

### Stage 4: join the agent

The `k3s_agent` role:

- receives the server private IP;
- receives the token kept in Ansible memory;
- installs K3s in agent mode;
- connects to the server private IP on port `6443`;
- starts the `k3s-agent` service.

### Stage 5: verify the cluster

Ansible runs the K3s version of `kubectl` on the server and prints the node
list.

## 12. Verify the result manually

Connect to the server with its public IP:

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@SERVER_PUBLIC_IP
```

List the nodes:

```bash
sudo k3s kubectl get nodes -o wide
```

Expected result:

```text
NAME          STATUS   ROLES                  ...
k3s-server   Ready    control-plane,master   ...
k3s-agent    Ready    <none>                 ...
```

Both nodes must have the `Ready` status.

You can also inspect the services:

```bash
sudo systemctl status k3s
```

On the agent, inspect:

```bash
sudo systemctl status k3s-agent
```

## 13. Run the playbook a second time

After the first successful run, execute it again:

```bash
ansible-playbook site.yml
```

Ansible should not reinstall the complete cluster. Most tasks should report
`ok` rather than `changed`. This confirms that the playbook is mostly
idempotent.

## 14. Common errors

### `Permission denied (publickey)`

Possible causes:

- the inventory uses the public `.pub` key instead of the private key;
- the private key does not correspond to the key uploaded by Terraform;
- the SSH user is not `ubuntu`;
- the private key permissions are too open.

Protect the private key with:

```bash
chmod 600 ~/.ssh/id_ed25519
```

### `Host key verification failed`

Connect manually to the host first and verify its fingerprint. This commonly
happens after Terraform replaces an EC2 instance and the public IP is reused.

### `Connection timed out`

Check that:

- the EC2 instance is running;
- `ansible_host` contains the public IP, not the private IP;
- the security group allows TCP port `22` from your current public IP;
- your local public IP has not changed since `terraform apply`.

### The agent cannot join the server

Check that:

- `k3s_private_ip` contains the private IP of each EC2;
- both instances use the same security group;
- TCP port `6443` is allowed between members of the security group;
- UDP port `8472` is allowed between the nodes;
- TCP port `10250` is allowed between the nodes.

### `sudo: a password is required`

Confirm that the inventory uses `ansible_user=ubuntu` and that the EC2 instance
was created from the expected Ubuntu AMI.

## 15. Security rules

- Never commit `inventory/hosts.ini` if it contains your real addresses.
- Never commit or share `~/.ssh/id_ed25519`.
- The `.pub` key can be shared with AWS; the private key cannot.
- Never print or commit the K3s node token.
- Keep SSH port `22` restricted to your public IP with a `/32` CIDR.
- Use private EC2 addresses for communication between K3s nodes.

## 16. Complete workflow summary

```text
1. terraform plan
2. terraform apply
3. terraform output public/private IPs
4. update inventory/hosts.ini
5. connect once to both EC2 instances with SSH
6. ansible-inventory --graph
7. ansible k3s -m ping
8. ansible-playbook site.yml --syntax-check
9. ansible-playbook site.yml
10. sudo k3s kubectl get nodes -o wide
11. run the playbook again to check idempotence
```
