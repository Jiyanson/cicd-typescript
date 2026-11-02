# Ansible

This area is reserved for host provisioning and platform bootstrap automation.
The planned layout is:

```text
ansible/
├── inventories/       # Environment host inventories
├── playbooks/         # Top-level orchestration
└── roles/             # Docker, Kubernetes tools, and Argo CD roles
```

Add those directories when their first executable configuration is introduced;
empty placeholder directories are intentionally avoided.
