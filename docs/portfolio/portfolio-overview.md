# AcmeCloud Enterprise Platform — DevOps Engineering Portfolio

## Project Summary

AcmeCloud Enterprise Platform is an end-to-end DevOps engineering project demonstrating automated provisioning, configuration, containerization, deployment, observability, security, resilience, and operational management of a production-style application platform on AWS.

The project brings together infrastructure as code, configuration management, containers, Kubernetes, CI/CD, monitoring, identity and access management, release engineering, failure recovery, and cloud cost control. It was developed progressively from traditional EC2-based infrastructure automation to a containerized Amazon EKS deployment model.

## DevOps Engineering Objectives

The platform was designed to demonstrate the ability to:

- Provision repeatable AWS infrastructure through reusable Terraform modules.
- Configure Linux systems consistently using Ansible roles and dynamic AWS inventory.
- Package web and application tiers as hardened Docker containers.
- Publish immutable application releases to Amazon ECR.
- Orchestrate containerized workloads on Amazon EKS.
- Expose Kubernetes workloads through AWS Load Balancer Controller and Application Load Balancer ingress.
- Build CI/CD automation with GitHub Actions and AWS authentication through GitHub OIDC.
- Apply container and Kubernetes runtime security controls.
- Monitor platform and workload health using Prometheus, Grafana, Alertmanager, and Amazon CloudWatch.
- Validate deployment resilience and deterministic rollback behaviour.
- Control cloud costs through automated environment shutdown and restoration.

## Technology Stack

| Area | Technologies |
| --- | --- |
| Cloud | AWS |
| Infrastructure as Code | Terraform |
| Configuration Management | Ansible |
| Containers | Docker, Docker Compose |
| Container Registry | Amazon ECR |
| Container Orchestration | Kubernetes, Amazon EKS |
| Traffic Management | Kubernetes Ingress, AWS Load Balancer Controller, Application Load Balancer |
| CI/CD | GitHub Actions |
| CI/CD Authentication | GitHub OIDC, AWS IAM |
| Observability | Prometheus, Grafana, Alertmanager, Amazon CloudWatch |
| Security | IAM, Security Groups, AWS Systems Manager, non-root containers, seccomp, dropped Linux capabilities |
| Data Services | Amazon RDS for MySQL, Amazon ElastiCache for Redis |
| Additional AWS Services | Amazon S3, Amazon Cognito, AWS Lambda |

## Architecture Overview

The final containerized delivery path follows this flow:

```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions CI/CD
   |-- validation and security checks
   |-- Docker image build
   |-- GitHub OIDC --> AWS IAM
   |-- immutable image publication --> Amazon ECR
   |-- gated Kubernetes deployment
   v
Amazon EKS
   |
   v
Kubernetes Ingress
   |
   v
AWS Load Balancer Controller
   |
   v
Application Load Balancer
   |
   v
Nginx Web Tier
   |
   +---- /app/ ----> Tomcat Application Tier

Observability:
EKS workloads --> Prometheus --> Grafana
                         |
                         +--> Alertmanager

Infrastructure and operations:
Terraform --> AWS infrastructure
Ansible   --> EC2 configuration management
CloudWatch --> EC2 monitoring
```

The repository also retains the earlier EC2-based architecture using Auto Scaling Groups, Apache, Tomcat, load balancers, Ansible, AWS Systems Manager, and CloudWatch. Keeping both implementations demonstrates progression from traditional infrastructure automation to Kubernetes-based application delivery.

For the detailed integrated architecture, see [`../architecture/production-architecture.md`](../architecture/production-architecture.md).

## Infrastructure as Code

AWS infrastructure is represented as reusable Terraform modules rather than manually created resources. The platform includes networking, security, compute, load balancing, storage and identity, data services, Amazon EKS, and GitHub OIDC integration.

Environment-level variables control optional infrastructure so expensive services can be enabled for production validation and disabled when the lab is not required. This makes infrastructure lifecycle management part of the engineering design rather than an afterthought.

## Configuration Management

Ansible provides repeatable Linux configuration for the EC2-based portion of the platform. The implementation progressed from static laboratory inventory to AWS dynamic inventory and reusable roles.

Configuration automation covers common operating-system configuration, SSH hardening, Apache, Java and Tomcat, and monitoring components. Idempotency checks were used to confirm that repeated execution does not introduce unnecessary configuration changes.

## Containerization and Release Engineering

The application consists of an Nginx web tier and a Tomcat application tier. Both services were containerized and tested together before being integrated with Kubernetes.

Container runtime security was strengthened by running workloads as non-root users and configuring Kubernetes security contexts with `runAsNonRoot`, `RuntimeDefault` seccomp, disabled privilege escalation, and dropped Linux capabilities.

Images are stored in private Amazon ECR repositories. Production releases use immutable 12-character Git commit SHA tags instead of mutable `latest` tags, providing direct traceability between source code, container images, and Kubernetes deployments.

## Kubernetes and Amazon EKS

The production-style container platform runs on Amazon EKS. Kubernetes manifests define separate web and application deployments and services, with two replicas per tier during final validation.

Kustomize provides the deployment base used to render a specific immutable release. Ingress is managed separately because its lifecycle depends on AWS Load Balancer Controller and the AWS environment lifecycle.

The deployment strategy supports rolling updates while maintaining workload availability through controlled surge and unavailable replica settings.

## CI/CD Engineering

GitHub Actions provides the CI/CD workflow for the platform. The pipeline includes infrastructure and Kubernetes validation, Docker builds, container security scanning, AWS identity validation, ECR publication, and a gated EKS deployment path.

AWS access from GitHub Actions uses OpenID Connect rather than stored long-lived AWS access keys. IAM trust is restricted to the intended GitHub repository and deployment permissions are scoped for the EKS workflow.

The deployment design captures the currently running container images before applying a new release. Rollout status is verified after deployment; if deployment fails, the workflow contains deterministic rollback logic capable of restoring the exact previous images.

The rollback mechanism was validated through controlled failure testing using deliberately invalid image references. The final integrated production validation was performed separately using the same immutable Kustomize release mechanism.

## Observability

The Kubernetes observability stack includes Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter, custom alert rules, and a platform dashboard.

Prometheus provides metrics collection and target health visibility, Grafana provides visualization, and Alertmanager supports alert handling. Amazon CloudWatch remains part of the EC2 monitoring path, demonstrating monitoring across both infrastructure models used by the project.

## Security Engineering

Security controls are applied across multiple layers of the platform:

- Network segmentation and security groups restrict traffic between platform tiers.
- GitHub Actions authenticates to AWS using OIDC instead of static AWS credentials.
- AWS IAM roles and EKS access controls restrict deployment access.
- EC2 management uses AWS Systems Manager where applicable.
- Containers run as non-root users.
- Kubernetes workloads use seccomp runtime defaults.
- Privilege escalation is disabled and Linux capabilities are dropped.
- Container images are scanned for high and critical vulnerabilities in CI.
- Sensitive Terraform inputs are handled without committing plaintext secrets to source control.

## Resilience and Recovery

Resilience was tested rather than documented only as a design goal. Controlled deployment failures were introduced to validate Kubernetes behaviour and recovery procedures.

The platform uses multiple replicas, rolling deployment controls, rollout verification, and deterministic rollback logic. Invalid image testing demonstrated that a failed release could be identified and the previously known-good application version restored.

## Cost-Controlled Operations

Because EKS control planes, NAT gateways, Application Load Balancers, and managed data services can create ongoing AWS charges, the project includes automated shutdown and restore workflows.

Terraform feature flags allow costly infrastructure to be disabled while preserving the reusable baseline. Shutdown and restore scripts coordinate the environment lifecycle so the production architecture can be recreated when required without leaving unnecessary chargeable resources running continuously.

This operational lifecycle is an important part of the project: infrastructure automation includes not only creation and deployment, but also safe teardown, restoration, and cost awareness.

## Final Integrated Validation

The final integrated release used the immutable release identifier:

```text
536b0e8455a0
```

The same release tag was used for both the Nginx web image and Tomcat application image, providing source-to-runtime traceability.

During final production validation:

- Web and application deployments reached their expected replica counts.
- Workloads were distributed across EKS worker nodes.
- Kubernetes monitoring components were healthy.
- AWS Load Balancer target health was confirmed.
- The public application endpoint returned HTTP `200` for `/`.
- The proxied application route returned HTTP `200` for `/app/`.
- The validated AWS environment was subsequently shut down using the project's cost-control process.

## What This Project Demonstrates

AcmeCloud demonstrates DevOps engineering across the complete delivery lifecycle: infrastructure provisioning, system configuration, container build and release, Kubernetes orchestration, automated CI/CD, secure cloud authentication, observability, deployment resilience, troubleshooting, validation, documentation, and operational cost management.

Rather than presenting each technology as an isolated exercise, the project integrates them into a single platform with reproducible infrastructure, immutable releases, measurable health, controlled failure recovery, and documented operational procedures.

## Repository Documentation

Detailed implementation material is available throughout the repository, including the main [`README.md`](../../README.md) and the [production architecture document](../architecture/production-architecture.md).
