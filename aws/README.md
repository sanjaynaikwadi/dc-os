# Install DC-OS with terraform
- Opensource version
- Enterprise version

### Prerequisites
- Terraform version 0.11 or greater
- verified Amazon Web Services (AWS) account and AWS IAM credentials
- SSH keypair to use for securely connecting to cluster nodes

### Allow SSH agent 
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/<your-key-name>

### Create main.tf file, and update the required informations

```bash
provider "aws" {
    access_key = "YOUR ACCESS KEY"
    secret_key = "YOUR SECRET KEY"
  # Change your default region here
  region = "sa-east-1"
}

module "dcos" {
  source  = "dcos-terraform/dcos/aws"
  version = "~> 0.1.0"

  cluster_name        = "sanjay-dcos-demo"
  ssh_public_key_file = "/Users/sanjay/Sanjay/SSH-Keys/sanjay-ssh-key.pub" # Specify your public key for making connection to nodes which you allowed via SSH Agent to connect
  admin_ips           = ["${data.http.whatismyip.body}/32"]

# Choose number of master/private/public nodes/agent to be spwan
  num_masters        = "1"
  num_private_agents = "3"
  num_public_agents  = "1"

  dcos_version = "1.12.3"

# Choose your instance type
  dcos_instance_os    = "centos_7.5"
  bootstrap_instance_type = "t2.medium"
  masters_instance_type  = "t2.medium"
  private_agents_instance_type = "t2.medium"
  public_agents_instance_type = "t2.medium"

# If you want to add an additional volume to private instance use the below block
  private_agents_extra_volumes = [
    {
      size        = "50"
      type        = "gp2"
      device_name = "/dev/xvdz"
    },
  ]

# Default AWS provider
  providers = {
    aws = "aws"
  }

# DC OS settings 
  dcos_variant              = "ee"    # If you want to install Enterprise version
  dcos_license_key_contents = "${file("./license.txt")}" # This is your license file and required when your installing the EE version
  # dcos_variant = "open"   # If you want to install opensource version
  dcos_superuser_username = "admin"  # Default user name
  # Password is admin, create your password hash and update it below 
  dcos_superuser_password_hash = "$6$rounds=656000$8CXbMqwuglDt3Yai$ZkLEj8zS.GmPGWt.dhwAv0.XsjYXwVHuS9aHh3DMcfGaz45OpGxC5oQPXUUpFLMkqlXCfhXMloIzE0Xh8VwHJ."
  dcos_install_mode = "${var.dcos_install_mode}"
  dcos_security = "permissive"  # Default mode is permissive if you want to enable security feature, change to "strict"
}

variable "dcos_install_mode" {
  description = "specifies which type of command to execute. Options: install or upgrade"
  default     = "install"
}

# Used to determine your public IP for forwarding rules
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}
```

### Lets Apply now
```bash
terraform init
terraform plan
terraform apply
```

### Your done now, you will get the output address where you can login with mention login details

### Tearing down the setup
```bash
terraform destroy
```

