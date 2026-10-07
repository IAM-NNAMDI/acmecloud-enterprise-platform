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
| `eks` | Amazon EKS cluster, managed node group, Kubernetes networking dependencies, OIDC integration and AWS Load Balancer Controller IAM resources |
| `github-oidc` | GitHub OIDC provider, GitHub Actions IAM role, ECR publishing permissions and EKS deployment permissions |

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
├── .github/
│   └── workflows/
│       └── ci.yml
│
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
├── docker/
│   ├── app/
│   │   └── Dockerfile
│   ├── web/
│   │   ├── Dockerfile
│   │   └── index.html
│   └── compose.yml
│
├── docs/
│   ├── architecture/
│   │   └── production-architecture.md
│   └── cicd/
│       ├── architecture.md
│       └── README.md
│
├── kubernetes/
│   └── eks/
│       ├── app/
│       │   ├── deployment.yaml
│       │   └── service.yaml
│       ├── web/
│       │   ├── deployment.yaml
│       │   └── service.yaml
│       ├── ingress.yaml
│       ├── kustomization.yaml
│       └── namespace.yaml
│
├── monitoring/
│   ├── alerts/
│   │   └── acmecloud-alerts.yaml
│   ├── architecture/
│   │   └── README.md
│   ├── dashboards/
│   │   └── acmecloud-overview.json
│   ├── MONITORING.md
│   ├── README.md
│   └── values.yaml
│
├── scripts/
│   ├── aws-lab-restore.sh
│   └── aws-lab-shutdown.sh
│
├── terraform/
│   ├── modules/
│   │   ├── Alb/
│   │   ├── compute/
│   │   ├── Database/
│   │   ├── eks/
│   │   ├── github-oidc/
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

Production releases are published to Amazon ECR using immutable tags derived from the first 12 characters of the Git commit SHA.

The final integrated release validated during production testing was:

- `acmecloud-app:536b0e8455a0`
- `acmecloud-web:536b0e8455a0`

Using the same immutable release identifier for both services provides traceability between the Git commit, CI/CD pipeline, ECR images, and Kubernetes deployment.

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


Production releases are published to Amazon ECR using immutable tags derived from the first 12 characters of the Git commit SHA.

The final validated EKS release used:

- `acmecloud-web:536b0e8455a0`
- `acmecloud-app:536b0e8455a0`

The release tag is injected into the Kubernetes manifests through Kustomize rather than storing a mutable or historical production image version directly in the deployment manifests.

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


## Phase 7 — GitHub Actions CI/CD

Phase 7 implements the AcmeCloud automated CI/CD pipeline using GitHub Actions.

The pipeline validates the repository and Kubernetes manifests, validates Docker builds, scans container images with Trivy, authenticates to AWS through GitHub OIDC, publishes immutable commit-SHA-tagged images to Amazon ECR, and deploys releases to Amazon EKS.

GitHub Actions uses the dedicated `acmecloud-production-github-actions` IAM role without storing long-lived AWS access keys. Application deployment authorization is scoped to the `acmecloud` Kubernetes namespace.

Successful deployments are verified using Kubernetes rollout status. The pipeline also contains rollback controls for failed rollout verification.

The Kubernetes rollback procedure was tested using deliberately invalid ECR image tags. Existing healthy replicas remained available while replacement pods entered `ErrImagePull`, after which both deployments were successfully restored to the previous known-good release.

Detailed CI/CD documentation:

    docs/cicd/README.md
    docs/cicd/architecture.md

## Phase 8 — Production Integration

Phase 8 integrates the individual AcmeCloud components into a complete production-style DevOps platform.

The final integration connects Terraform, Ansible, Docker, Amazon ECR, Amazon EKS, Kubernetes ingress, Prometheus and Grafana observability, GitHub Actions CI/CD, AWS IAM/OIDC security, deployment resilience, and AWS cost-control automation.

The definitive production architecture is documented in:

`docs/architecture/production-architecture.md`

### Production Release Model

AcmeCloud uses immutable production releases derived from the first 12 characters of the Git commit SHA.

The final validated release was:

```text
536b0e8455a0
```

Both application components use the same release identifier:

```text
acmecloud-app:536b0e8455a0
acmecloud-web:536b0e8455a0
```

GitHub Actions builds and publishes both images to Amazon ECR.

Kustomize injects the selected immutable release into the Kubernetes manifests before deployment. The base deployment manifests contain the `RELEASE_TAG` placeholder rather than a historical deployable image version, preventing stale releases from being silently redeployed.

The release path is:

```text
Git Commit
    |
    v
GitHub Actions
    |
    v
Build + Security Scan
    |
    v
Amazon ECR
    |
    | Immutable SHA images
    v
Kustomize Release Rendering
    |
    v
Amazon EKS
    |
    v
Rollout Verification
```

### Kubernetes Security

The production workloads apply container and pod-level security controls.

The web container runs as numeric UID/GID `101:101`, while the application container runs as numeric UID/GID `1000:1000`.

Kubernetes workload security includes:

- Non-root container execution
- Numeric container users
- `allowPrivilegeEscalation: false`
- All Linux capabilities dropped
- `RuntimeDefault` seccomp profile
- Private Amazon ECR repositories
- Immutable production image tags

Using numeric users also allows Kubernetes to verify that containers satisfy the `runAsNonRoot` requirement.

### Prometheus and Grafana Observability

The EKS environment uses `kube-prometheus-stack` to provide Kubernetes and application observability.

The monitoring stack contains:

- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node-exporter

Prometheus collects worker-node, Kubernetes object, container, and workload metrics.

Grafana provides the AcmeCloud platform dashboard using Prometheus as its default metrics data source.

Alertmanager processes alerts generated by Prometheus rules.

Custom AcmeCloud alerts monitor:

- Node availability
- High node CPU utilization
- High node memory utilization
- Container restarts
- Deployment replica availability
- Pods remaining not ready

Monitoring services remain private using Kubernetes ClusterIP services. Administrative access can be provided through local Kubernetes port forwarding without creating another public AWS load balancer.

Detailed monitoring documentation is available in:

`monitoring/README.md`

`monitoring/MONITORING.md`

`monitoring/architecture/README.md`

### Deployment Resilience and Rollback

The Kubernetes deployments use rolling updates designed to maintain healthy replicas while replacement pods become ready.

Failure behavior was tested using deliberately invalid ECR image references.

During the resilience test:

- Existing healthy replicas remained available
- Replacement pods entered `ErrImagePull`
- The failed rollout was detected
- The previous known-good application and web images were restored
- Both deployments returned to a healthy state

Before deployment, the CI/CD workflow records the currently running application and web image references.

If rollout verification fails, the rollback path restores those exact previous images rather than relying on a mutable tag.

### GitHub OIDC and Deployment Authorization

GitHub Actions authenticates to AWS using OpenID Connect rather than stored long-lived AWS access keys.

The workflow assumes the dedicated IAM role:

```text
acmecloud-production-github-actions
```

The role can publish AcmeCloud images to Amazon ECR and access the target EKS environment.

Kubernetes deployment authorization is scoped to the `acmecloud` namespace.

Infrastructure administration remains separate from application deployment permissions, creating a least-privilege boundary between CI/CD and platform administration.

### Cost-Control Automation

AcmeCloud includes explicit lifecycle automation for AWS resources that generate significant ongoing lab cost.

The repository provides:

```text
scripts/aws-lab-restore.sh
scripts/aws-lab-shutdown.sh
```

The restore workflow requires an explicit immutable `RELEASE_TAG`.

Before restoring chargeable infrastructure, the restore script verifies that the selected release exists in both AcmeCloud ECR repositories.

The shutdown workflow removes or disables chargeable lab resources including:

- Amazon EKS
- EKS managed worker nodes
- Kubernetes-created Application Load Balancer
- NAT Gateway
- NAT Elastic IP
- Optional RDS and Redis data tier

This allows the reusable baseline infrastructure to remain while expensive runtime components are disabled between demonstrations.

### End-to-End Production Validation

The final integrated production release `536b0e8455a0` was validated end to end.

Validation confirmed:

- Both immutable release images existed in Amazon ECR
- Application deployment reached 2/2 available replicas
- Web deployment reached 2/2 available replicas
- Workloads were distributed across both EKS worker nodes
- Application workloads completed the final rollout with zero restarts
- AWS Load Balancer Controller successfully reconciled the ingress
- Internet-facing Application Load Balancer was provisioned
- Both current ALB targets reported healthy
- `/` returned HTTP 200
- `/app/` returned HTTP 200
- Prometheus was operational
- Grafana was operational
- Alertmanager was operational
- Custom AcmeCloud Prometheus rules were loaded
- Monitoring components were healthy

After production validation, the EKS cluster, Application Load Balancer, NAT Gateway, and NAT Elastic IP were successfully removed as part of the cost-control shutdown.

### Operational Lifecycle

The production demonstration lifecycle is:

```text
Select Immutable Release
        |
        v
Restore AWS Runtime Infrastructure
        |
        v
Restore Amazon EKS
        |
        v
Render Kubernetes Release
        |
        v
Deploy Application
        |
        v
Provision ALB Ingress
        |
        v
Restore Observability
        |
        v
Validate Production
        |
        v
Demonstrate / Test Platform
        |
        v
Shutdown Chargeable Resources
```

This design allows the complete AcmeCloud platform to be restored for demonstrations and validation while avoiding unnecessary ongoing AWS lab costs.
