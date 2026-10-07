# AcmeCloud Project Evidence

This directory contains reproducible technical evidence from the AcmeCloud Enterprise Platform implementation and final validation.

The screenshots complement the source code, Git history, architecture documentation, and infrastructure definitions in the repository.

## Terraform

### Configuration Validation

![Terraform validation](terraform/01-terraform-validation.png)

Terraform configuration successfully passes `terraform validate`.

### Terraform Modules

![Terraform modules](terraform/02-terraform-modules.png)

The infrastructure is separated into reusable modules for networking, security, compute, load balancing, data services, storage and identity, EKS, and GitHub OIDC.

## Ansible

### Playbook Syntax Validation

![Ansible syntax check](ansible/01-ansible-syntax-check.png)

The main Ansible configuration playbook successfully passes syntax validation.

### AWS Dynamic Inventory

![AWS dynamic inventory](ansible/02-aws-dynamic-inventory.png)

Amazon EC2 instances are dynamically grouped into bastion, web, and application tiers.

## Docker and Amazon ECR

### Immutable Production Release

![Immutable ECR release](docker-ecr/01-immutable-ecr-release.png)

The final integrated web and application images use the same immutable Git-SHA-derived release identifier.

### ECR Security Configuration

![ECR security configuration](docker-ecr/02-ecr-security-configuration.png)

The private ECR repositories use immutable image tags and image scanning on push.

## Kubernetes and Amazon EKS

### Kustomize Validation

![Kustomize validation](kubernetes-eks/01-kustomize-validation.png)

Kustomize successfully renders the namespace, services, deployments, and ingress resources.

### Workload Security Hardening

![Kubernetes workload security](kubernetes-eks/02-workload-security-hardening.png)

Web and application workloads disable privilege escalation, drop Linux capabilities, require non-root execution, and use the RuntimeDefault seccomp profile.

## GitHub Actions CI/CD

### AWS OIDC Authentication

![GitHub OIDC authentication](cicd/01-github-oidc-authentication.png)

GitHub Actions uses OIDC federation to assume the deployment IAM role without storing long-lived AWS credentials.

### EKS Deployment Verification

![EKS deployment verification](cicd/02-eks-deployment-verification.png)

The deployment workflow renders the immutable release, applies the Kubernetes resources, and verifies application and web rollouts.

### Automatic Rollback

![Automatic rollback](cicd/03-automatic-rollback.png)

The CI/CD workflow preserves the previously running images and restores them when rollout verification fails.

## Monitoring

### Prometheus Alert Rules

![Prometheus alert rules](monitoring/01-prometheus-alert-rules.png)

Custom alert rules cover node availability, CPU, memory, container restarts, deployment availability, and pod readiness.

### Grafana Dashboard

![Grafana dashboard panels](monitoring/02-grafana-dashboard-panels.png)

The AcmeCloud Grafana dashboard includes workload, restart, CPU, memory, node, and alert visibility.

## Cost-Control Validation

### AWS Runtime Resource Audit

![AWS cost-control audit](validation/01-aws-cost-control-audit.png)

The post-demonstration AWS audit confirms that chargeable EKS, load balancer, NAT Gateway, RDS, and ElastiCache runtime resources were removed.

### Terraform Cost-Control Flags

![Terraform cost-control configuration](validation/02-terraform-cost-control.png)

Terraform feature flags keep optional chargeable runtime components disabled between demonstrations.

---

These screenshots represent configuration, validation, and current reproducible project evidence. Historical implementation claims are additionally supported by the repository source code, Git history, and project documentation.
