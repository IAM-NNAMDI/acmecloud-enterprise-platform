# AcmeCloud Enterprise Platform

AcmeCloud Enterprise Platform is a production-style DevOps portfolio project that demonstrates the design, provisioning, configuration, security, and monitoring of a multi-tier application environment on AWS.

The platform combines **Terraform** for Infrastructure as Code (IaC) with **Ansible** for configuration management and **Amazon CloudWatch** for infrastructure monitoring.

The architecture implements a layered application environment consisting of:

- A public Application Load Balancer for incoming web traffic
- An auto-scaled Apache web tier
- An internal Application Load Balancer separating the web and application tiers
- An auto-scaled Apache Tomcat application tier
- Amazon RDS for MySQL
- Amazon ElastiCache for Redis
- Amazon S3 for application asset storage
- Amazon Cognito and AWS Lambda for identity and signup functionality
- AWS Systems Manager (SSM) for Ansible connectivity to EC2 instances
- Amazon CloudWatch Agent for operating-system-level monitoring

Infrastructure is organized into reusable Terraform modules, while server configuration is implemented through reusable and idempotent Ansible roles.

## Architecture

The platform uses a multi-tier AWS architecture with separate web, application, and database layers.

```text
                         Internet
                            |
                            v
                  +-------------------+
                  |   Public Web ALB  |
                  +-------------------+
                            |
                            v
                  +-------------------+
                  |  Apache Web Tier  |
                  | Auto Scaling Group|
                  +-------------------+
                            |
                            v
                  +-------------------+
                  | Internal App ALB  |
                  +-------------------+
                            |
                            v
                  +-------------------+
                  | Tomcat App Tier   |
                  | Auto Scaling Group|
                  +-------------------+
                       |           |
                       v           v
                +-----------+  +-----------+
                |   Redis   |  | RDS MySQL |
                +-----------+  +-----------+
```

### Network Segmentation

The VPC is divided into three subnet tiers across multiple Availability Zones:

- **Public subnets** — host internet-facing infrastructure such as the public ALB, NAT Gateway, and bastion host.
- **Private application subnets** — host the Tomcat application tier and internal Application Load Balancer.
- **Private database subnets** — isolate the RDS MySQL and Redis data services from direct internet access.

Security groups enforce communication between application layers so that traffic flows through the intended architecture rather than directly between unrestricted resources.

## Infrastructure as Code — Terraform

Terraform provisions the AWS infrastructure using reusable modules with clear separation of responsibilities.

### Terraform Modules

| Module | Responsibilities |
|---|---|
| `vpc` | VPC, public subnets, private application subnets, private database subnets, Internet Gateway, NAT Gateway, Elastic IP, route tables and route associations |
| `security` | Security groups for the bastion host, public ALB, web tier, internal application ALB, Tomcat application tier, Redis and RDS |
| `compute` | EC2 IAM role and instance profile, SSM access, CloudWatch Agent permissions, bastion host, launch templates and Auto Scaling Groups |
| `Alb` | Public web ALB, internal application ALB, target groups, listeners and Auto Scaling attachments |
| `Database` | Amazon RDS for MySQL and Amazon ElastiCache for Redis |
| `storage-identity` | Amazon S3, bucket security and lifecycle configuration, Amazon Cognito, AWS Lambda and Lambda IAM permissions |

## Configuration Management — Ansible

Ansible configures the EC2 instances after the AWS infrastructure has been provisioned by Terraform.

AWS EC2 instances are discovered dynamically and managed through AWS Systems Manager (SSM), allowing Ansible to configure the environment without relying on direct SSH access to private application instances.

### Ansible Roles

| Role | Responsibilities |
|---|---|
| `common` | Installs common administration packages and ensures time synchronization is running |
| `hardening` | Disables direct root SSH login, disables SSH password authentication and configures SSH idle timeout |
| `apache` | Installs Apache, deploys the AcmeCloud web page and health endpoint, and manages the Apache service |
| `tomcat` | Installs Java 17 and Apache Tomcat, creates the Tomcat service account, deploys the systemd service and manages the Tomcat service |
| `monitoring` | Installs, configures and starts the Amazon CloudWatch Agent |

The roles are designed to be reusable and idempotent, allowing the configuration to be applied repeatedly without introducing unnecessary changes.

## Monitoring — Amazon CloudWatch

The platform uses the Amazon CloudWatch Agent to collect operating-system-level metrics from the EC2 web and application instances.

The agent is installed and configured automatically through the Ansible `monitoring` role.

Metrics are published to the custom CloudWatch namespace:

`AcmeCloud/EC2`

The current monitoring configuration collects:

- Memory utilization (`mem_used_percent`)
- Disk utilization (`disk_used_percent`)
- Swap utilization (`swap_used_percent`)

Metrics include EC2 instance and Auto Scaling Group dimensions, allowing individual instances and scaling groups to be monitored within CloudWatch.

## Repository Structure

```text
acmecloud-enterprise-platform/
├── ansible/
│   ├── inventories/
│   │   ├── aws/
│   │   ├── production/
│   │   └── static/
│   ├── playbooks/
│   ├── roles/
│   │   ├── apache/
│   │   ├── common/
│   │   ├── hardening/
│   │   ├── monitoring/
│   │   └── tomcat/
│   ├── requirements.yml
│   └── ansible.cfg
│
├── terraform/
│   ├── modules/
│   │   ├── Alb/
│   │   ├── compute/
│   │   ├── Database/
│   │   ├── security/
│   │   ├── storage-identity/
│   │   └── vpc/
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── variable.tf
│   ├── terraform.tfvars.example
│   └── versions.tf
│
├── .gitignore
└── README.md
```

## Security Design

The platform applies defense-in-depth principles across the network, compute, and configuration layers.

Key security controls include:

- Security groups dedicated to the public ALB, web tier, internal application ALB, Tomcat tier, Redis, RDS, and bastion host.
- Application traffic is restricted between tiers using security-group-to-security-group rules.
- Tomcat application instances are placed in private application subnets without direct public exposure.
- RDS and Redis are isolated within private database subnets.
- AWS Systems Manager provides Ansible management connectivity without requiring direct SSH access to private application instances.
- EC2 instances use IAM roles instead of embedded AWS access keys.
- Direct root SSH login and SSH password authentication are disabled through Ansible hardening.
- Amazon S3 public access blocking and server-side encryption are enabled for application asset storage.
- Sensitive Terraform values and generated state files are excluded from Git through `.gitignore`.

## Deployment Workflow

The platform follows a two-phase infrastructure and configuration workflow:

1. **Terraform provisions the AWS infrastructure**
   - Creates the VPC and subnet architecture.
   - Configures routing, Internet Gateway, and NAT Gateway.
   - Creates security groups and IAM resources.
   - Deploys the bastion host, launch templates, and Auto Scaling Groups.
   - Creates the public and internal Application Load Balancers.
   - Provisions RDS MySQL, ElastiCache Redis, S3, Cognito, and Lambda.

2. **Ansible discovers and configures EC2 instances**
   - Uses the AWS dynamic inventory to discover web and application instances.
   - Connects to managed EC2 instances through AWS Systems Manager.
   - Applies common server configuration and SSH hardening.
   - Configures Apache on the web tier.
   - Installs Java 17 and Apache Tomcat on the application tier.
   - Installs and configures the Amazon CloudWatch Agent.

3. **Validation**
   - Ansible playbooks are rerun to verify idempotency.
   - Application Load Balancer target health is checked.
   - Web and application endpoints are tested.
   - CloudWatch metrics are verified in the `AcmeCloud/EC2` namespace.

## Prerequisites

The following tools and access are required to deploy and manage the platform:

- An AWS account with permissions to provision the resources defined by the Terraform configuration.
- Terraform `>= 1.9.0`.
- AWS Provider for Terraform `~> 5.0`.
- AWS CLI v2 configured with valid AWS credentials.
- Ansible Core 2.15 or compatible version.
- Python 3.
- Access to the required Ansible Galaxy collections.

This project was developed and tested with:

- Terraform `1.9.8`
- Ansible Core `2.15.13`
- AWS CLI `2.34.57`
- Python `3.9.21`
- `amazon.aws` collection `6.5.0`
- `community.aws` collection `6.4.0`

Install the required Ansible collections with:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

## Deployment

### 1. Clone the Repository

```bash
git clone git@github.com:IAM-NNAMDI/acmecloud-enterprise-platform.git
cd acmecloud-enterprise-platform
```

### 2. Prepare the Terraform Remote Backend

Terraform state is stored remotely using an Amazon S3 backend with DynamoDB state locking.

The current backend configuration expects:

- S3 bucket: `acmecloud-terraform-state-dev`
- State key: `dev/terraform.tfstate`
- AWS Region: `us-east-1`
- DynamoDB locking table: `terraform-locks`
- Server-side state encryption enabled

These backend resources must already exist before running `terraform init`.

For a separate deployment or AWS account, update `terraform/backend.tf` to reference backend resources created for that environment.

### 3. Configure Terraform Variables

Move into the Terraform directory:

```bash
cd terraform
```

Create your local variable file from the provided example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace the placeholder values:

```hcl
bastion_allowed_cidr = "YOUR_PUBLIC_IP/32"
ami_id                = "ami-xxxxxxxxxxxxxxxxx"
key_name              = "your-key-pair-name"
db_password           = "REPLACE_WITH_SECURE_PASSWORD"
s3_bucket_name        = "your-unique-acmecloud-assets-bucket"
```

`terraform.tfvars` is excluded from Git and must not be committed because it can contain sensitive values.

### 4. Initialize and Validate Terraform

```bash
terraform init
terraform fmt -check -recursive
terraform validate
```

### 5. Review the Terraform Plan

```bash
terraform plan -out=tfplan
```

Review the proposed infrastructure changes before applying them.

### 6. Provision the AWS Infrastructure

```bash
terraform apply tfplan
```

Terraform provisions the AWS networking, security, compute, load balancing, database, cache, storage, and identity resources defined by the platform.

### 7. Configure the EC2 Instances with Ansible

After Terraform has provisioned the AWS infrastructure, move into the Ansible directory:

```bash
cd ../ansible
```

Install the required Ansible Galaxy collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Verify that the AWS dynamic inventory can discover the EC2 instances:

```bash
ansible-inventory -i inventories/aws/ --graph
```

The dynamic inventory organizes the managed instances into the `web` and `app` groups under the `acmecloud` parent group. The bastion host is discovered separately.

Verify connectivity to the managed web and application instances:

```bash
ansible acmecloud -i inventories/aws/ -m ansible.builtin.ping
```

Apply the complete AcmeCloud server configuration:

```bash
ansible-playbook -i inventories/aws/ playbooks/site.yml
```

The playbook applies:

- Common operating-system configuration
- SSH security hardening
- Amazon CloudWatch Agent installation and configuration
- Apache configuration on the web tier
- Java 17 and Apache Tomcat configuration on the application tier

Run the playbook again to verify idempotency. A successful second run should complete without unnecessary configuration changes.

## Containerization — Docker and Amazon ECR

The AcmeCloud web and application tiers are containerized using Docker, providing a consistent and portable runtime environment for the application.

The containerized architecture consists of two services:

- **Web Tier** — Nginx serves the AcmeCloud web interface and acts as a reverse proxy for application requests.
- **Application Tier** — Apache Tomcat 10 hosts the Java/JSP application on port `8080`.

Docker Compose is used to build and run the services on a dedicated bridge network. Only the Nginx web tier is published to the host, while the Tomcat application tier remains accessible only through the internal Docker network.

### Container Architecture

```text
Client
  |
  | :8081
  v
Nginx Web Container
  |
  | Docker bridge network
  v
Tomcat Application Container
     :8080
```

The application container includes a Docker health check. Docker Compose waits for the application to become healthy before starting the dependent web service.

### Amazon ECR

The AcmeCloud container images are stored in private Amazon Elastic Container Registry (ECR) repositories:

- `acmecloud-web` — stores the Nginx web-tier container image.
- `acmecloud-app` — stores the Tomcat application-tier container image.

The ECR repositories are configured with immutable image tags and image scanning on push to improve image integrity and security.

Docker BuildKit provenance metadata was disabled when building the images to ensure compatibility with the ECR image manifest format used during this phase.

Current validated container releases:

- `acmecloud-app:v3`
- `acmecloud-web:v5`


## Phase 5 — Kubernetes and Amazon EKS

Phase 5 migrated the containerized AcmeCloud web and application tiers from Docker Compose to Kubernetes and then deployed the same workloads to Amazon EKS.

### Kubernetes Architecture

The application uses a two-tier Kubernetes architecture:

- **Web tier:** Nginx containers
- **Application tier:** Apache Tomcat containers
- **Container registry:** Amazon ECR
- **Orchestration:** Kubernetes / Amazon EKS
- **Ingress:** AWS Application Load Balancer
- **Load balancer integration:** AWS Load Balancer Controller
- **AWS authentication:** IAM Roles for Service Accounts (IRSA)
- **Networking:** Private EKS worker nodes with public ALB ingress

### Deployment Architecture

```text
Internet
   |
   v
AWS Application Load Balancer
   |
   v
Kubernetes Ingress
   |
   v
acmecloud-web Service (ClusterIP)
   |
   +-- Nginx Pod
   +-- Nginx Pod
          |
          | /app/
          v
acmecloud-app Service (ClusterIP)
          |
   +------+------+
   |             |
   v             v
Tomcat Pod    Tomcat Pod
```

### Amazon ECR Integration

The EKS worker nodes pull the AcmeCloud container images directly from private Amazon ECR repositories using their IAM permissions.

Validated container images:

- `acmecloud-web:v5`
- `acmecloud-app:v3`

No manually managed ECR image pull secret is required in the EKS environment.

### AWS Load Balancer Controller

The AWS Load Balancer Controller was installed using Helm.

Terraform provisions the supporting AWS resources, including:

- EKS OIDC identity provider
- IAM policy for the AWS Load Balancer Controller
- IAM role using IRSA
- Public subnet tags for Kubernetes load balancer discovery

The Kubernetes Ingress uses ALB IP target mode, allowing the Application Load Balancer to route directly to the Nginx pod IP addresses.

### Validation

The final EKS deployment was successfully validated with:

- Two EKS worker nodes in `Ready` state
- Two Nginx web pods running
- Two Tomcat application pods running
- Workloads distributed across both EKS worker nodes
- `acmecloud-web` configured as a ClusterIP Service
- `acmecloud-app` configured as a ClusterIP Service
- Successful private Amazon ECR image pulls
- AWS Load Balancer Controller running successfully
- Internet-facing AWS Application Load Balancer provisioned through Kubernetes Ingress
- ALB target type configured as `ip`
- `/` returning HTTP 200
- `/app/` returning HTTP 200 through Nginx to Tomcat
- Final Terraform plan reporting no infrastructure drift

The validated request path is:

```text
Internet
    |
    v
AWS Application Load Balancer
    |
    v
Kubernetes Ingress
    |
    v
Nginx Web Tier
    |
    | /app/
    v
Kubernetes Service / DNS
    |
    v
Tomcat Application Tier
```

This phase demonstrates Kubernetes workload orchestration, Amazon EKS, Amazon ECR integration, private worker-node networking, Kubernetes service discovery, Helm, IAM/OIDC integration, IRSA, and AWS Application Load Balancer ingress.
