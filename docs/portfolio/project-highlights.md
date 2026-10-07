# AcmeCloud Enterprise Platform — Project Highlights

## DevOps Engineer Portfolio Highlights

AcmeCloud Enterprise Platform is an end-to-end AWS DevOps engineering project demonstrating infrastructure automation, configuration management, containerization, Kubernetes orchestration, CI/CD, observability, security, resilience, and cloud cost control.

### Core Engineering Achievements

- Designed reusable Terraform modules for AWS networking, security, compute, load balancing, data services, Amazon EKS, storage and identity services, and GitHub OIDC integration.
- Implemented Ansible configuration management using reusable roles, AWS dynamic inventory, idempotent automation, and AWS Systems Manager connectivity.
- Containerized Nginx and Apache Tomcat application tiers and published immutable application releases to private Amazon ECR repositories.
- Hardened container workloads to run as non-root users with privilege escalation disabled, Linux capabilities dropped, and Kubernetes RuntimeDefault seccomp profiles.
- Deployed a multi-replica web and application architecture on Amazon EKS and exposed workloads through Kubernetes Ingress, AWS Load Balancer Controller, and an Application Load Balancer.
- Built GitHub Actions CI/CD covering infrastructure and Kubernetes validation, container builds, vulnerability scanning, AWS OIDC authentication, ECR publishing, gated EKS deployment, rollout verification, and deterministic rollback.
- Replaced long-lived AWS CI credentials with GitHub OIDC and IAM role assumption.
- Implemented immutable release traceability using 12-character Git commit SHA image tags shared by the web and application tiers.
- Integrated Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter, custom alerting rules, and an application/platform dashboard for Kubernetes observability.
- Retained Amazon CloudWatch monitoring for the EC2-based configuration-management architecture.
- Validated deployment resilience by introducing invalid container image references, observing failed rollout behaviour, and restoring the known-good release through the rollback mechanism.
- Validated the integrated platform with distributed EKS replicas, healthy ALB targets, healthy monitoring components, and successful HTTP 200 responses for both `/` and `/app/`.
- Developed automated AWS lab shutdown and restoration workflows to remove expensive EKS, NAT Gateway, ALB, RDS, and ElastiCache resources when not required.

## CV-Ready Project Entry

**AcmeCloud Enterprise Platform — DevOps Engineer Portfolio Project**

- Engineered an end-to-end AWS DevOps platform using Terraform, Ansible, Docker, Amazon ECR, Kubernetes, Amazon EKS, GitHub Actions, Prometheus, Grafana, and CloudWatch.
- Built modular Infrastructure as Code for networking, security, compute, load balancing, EKS, data services, identity, storage, and CI/CD authentication.
- Automated Linux configuration using Ansible roles, dynamic AWS inventory, and idempotent playbooks.
- Built and hardened Nginx and Tomcat containers, publishing immutable Git-SHA-tagged releases to private ECR repositories.
- Implemented GitHub Actions CI/CD with validation, container vulnerability scanning, GitHub OIDC authentication, ECR publishing, gated EKS deployment, rollout verification, and deterministic rollback.
- Deployed and validated multi-replica workloads on EKS behind ALB ingress with Prometheus/Grafana observability and custom alerting.
- Applied Kubernetes workload security controls including non-root execution, seccomp, disabled privilege escalation, and dropped Linux capabilities.
- Automated AWS environment shutdown and restoration to reduce unnecessary cloud costs while preserving reproducibility.

## LinkedIn Project Description

**AcmeCloud Enterprise Platform | AWS DevOps Engineering**

Built an end-to-end production-style DevOps platform on AWS, progressing from Terraform-provisioned and Ansible-managed EC2 infrastructure to a containerized Amazon EKS deployment.

The project integrates Terraform, Ansible, Docker, Amazon ECR, Kubernetes, Amazon EKS, GitHub Actions, GitHub OIDC, Prometheus, Grafana, Alertmanager, and CloudWatch. It demonstrates modular Infrastructure as Code, immutable container releases, hardened non-root workloads, Kubernetes ingress through AWS Load Balancer Controller, CI/CD validation and security scanning, gated deployment, deterministic rollback, observability, resilience testing, and automated cloud cost control.

Final integrated validation confirmed distributed application replicas, healthy ALB targets, healthy monitoring components, and HTTP 200 responses across the web and application routes.

## GitHub Repository Summary

**Short description**

Production-style AWS DevOps platform using Terraform, Ansible, Docker, ECR, EKS, GitHub Actions, OIDC, Prometheus, Grafana, and automated cost controls.

**Suggested repository topics**

`aws` · `terraform` · `ansible` · `docker` · `kubernetes` · `eks` · `ecr` · `github-actions` · `devops` · `prometheus` · `grafana` · `oidc` · `infrastructure-as-code` · `cicd`

## Recruiter Talking Points

When describing the project, focus on the engineering lifecycle rather than listing tools:

1. **Infrastructure:** reusable Terraform modules create the AWS foundation and EKS platform.
2. **Configuration:** Ansible provides repeatable, idempotent Linux configuration for the EC2-based architecture.
3. **Packaging:** Docker produces hardened Nginx and Tomcat application images.
4. **Release management:** ECR stores immutable releases identified by Git commit SHA.
5. **Orchestration:** EKS manages replicated web and application workloads.
6. **Traffic:** Kubernetes Ingress and AWS Load Balancer Controller provide external ALB routing.
7. **Delivery:** GitHub Actions validates, scans, publishes, and supports gated Kubernetes deployment using AWS OIDC.
8. **Security:** IAM/OIDC and hardened container/Kubernetes security contexts reduce credential and runtime risk.
9. **Observability:** Prometheus, Grafana, Alertmanager, and CloudWatch provide infrastructure and workload visibility.
10. **Resilience:** rolling updates, health checks, rollout verification, and deterministic rollback protect application availability.
11. **Operations:** automated shutdown and restoration control AWS cost without sacrificing reproducibility.

## Evidence-Based Results

The final integrated release used the immutable release identifier:

`536b0e8455a0`

Both application tiers used the same release identifier, providing direct traceability between source revision and deployed container images.

The completed validation demonstrated:

- Two web replicas and two application replicas running across EKS worker nodes.
- Healthy Application Load Balancer targets.
- Successful HTTP 200 responses from `/` and `/app/`.
- Healthy Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter components.
- Custom Prometheus alerting rules and Grafana dashboard integration.
- Recovery from deliberately invalid image references to a known-good release.
- Successful removal of expensive AWS resources after validation through the cost-control shutdown process.

## Accuracy Note

The GitHub Actions workflow implements gated EKS deployment, rollout verification, and deterministic rollback. The rollback mechanism was validated through controlled failure testing. The final integrated production validation used the same immutable Kustomize release approach, but should not be described as a specific GitHub Actions deployment run unless workflow-run evidence is separately retained.

The RDS and Redis data tier is part of the optional Terraform architecture and was not required for the final EKS application validation.
