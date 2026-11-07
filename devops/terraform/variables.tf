variable "aws_region" {
  description = "AWS region in which to create the EC2 instance"
  type        = string
  default     = "eu-north-1"
}

variable "public_key_path" {
  description = "Path to the local SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_allowed_cidr" {
  description = "Public IP allowed to connect with SSH, using /32"
  type        = string

  validation {
    condition = (
      can(cidrnetmask(var.ssh_allowed_cidr)) &&
      can(regex("/32$", var.ssh_allowed_cidr))
    )
    error_message = "ssh_allowed_cidr must be a valid IPv4 CIDR ending in /32."
  }
}

variable "k3s_nodes" {
  description = "Configuration des EC2 du cluster K3s"

  type = map(object({
    instance_type = string
    role          = string
  }))
}