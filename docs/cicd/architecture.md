# AcmeCloud CI/CD Architecture

## Architecture

The AcmeCloud CI/CD architecture connects GitHub Actions with AWS through GitHub OIDC and separates continuous integration, image publishing, and Kubernetes deployment responsibilities.

    Developer
        |
        | git push
        v
    GitHub Repository
        |
        v
    GitHub Actions
        |
        +-- Repository validation
        +-- Docker build validation
        +-- Kubernetes manifest validation
        +-- Trivy security scanning
        |
        v
    GitHub OIDC
        |
        v
    AWS IAM Role
        |
        +-----------------------+
        |                       |
        v                       v
    Amazon ECR              Amazon EKS
        |                       |
        | SHA images            v
        +----------------> acmecloud namespace
                                |
                         +------+------+
                         |             |
                         v             v
                    app deployment  web deployment
                         |             |
                         +------+------+
                                |
                                v
                       Rollout Verification
                                |
                         +------+------+
                         |             |
                      Success        Failure
                         |             |
                         v             v
                   Release Live     Rollback
                                       |
                                       v
                              Previous Release

## Authentication Path

GitHub Actions requests an OIDC token from GitHub and exchanges that identity for temporary AWS credentials.

The authentication path is:

    GitHub Actions
          |
          v
    GitHub OIDC Provider
          |
          v
    AWS STS AssumeRoleWithWebIdentity
          |
          v
    acmecloud-production-github-actions
          |
          +--> Amazon ECR
          |
          +--> Amazon EKS

No static AWS access keys are required by the workflow.

## Release Path

Each production release follows this path:

    Git commit
        |
        v
    GitHub Actions
        |
        v
    Validation and security scanning
        |
        v
    Docker image build
        |
        v
    Commit-SHA image tag
        |
        v
    Amazon ECR
        |
        v
    Amazon EKS
        |
        v
    Kubernetes rollout verification

The Git commit SHA provides traceability between source code, container images, and the deployed Kubernetes release.

## Authorization Boundaries

The CI/CD identity is intentionally separated from infrastructure administration.

GitHub Actions is authorized to authenticate to AWS, publish AcmeCloud images to Amazon ECR, describe the target EKS cluster, and deploy application resources within the `acmecloud` namespace.

Terraform and platform administration remain responsible for VPC infrastructure, EKS lifecycle, managed node groups, IAM roles and policies, OIDC configuration, EKS access entries, namespace bootstrap, and infrastructure cost controls.

This creates a least-privilege boundary between application delivery and infrastructure management.

## Failure Handling

Kubernetes rolling updates retain healthy replicas while replacement pods become ready.

If rollout verification fails, the workflow contains rollback logic for both the application and web deployments.

    New Release
         |
         v
    App and Web Rollout
         |
         v
    Rollout Verification
         |
      +--+--+
      |     |
    Pass   Fail
      |     |
      v     v
    Live   Rollback
             |
             v
       Previous Release

A controlled test used nonexistent ECR image tags. Replacement pods entered `ErrImagePull` while existing healthy replicas remained available.

Both deployments were successfully restored to the previous known-good release.

The Kubernetes rollback mechanism was therefore directly validated. The GitHub Actions conditional rollback branch itself was not deliberately triggered by pushing a broken release to `main`.

## Monitoring Relationship

Application delivery and observability remain separate concerns.

The EKS workloads are monitored by the Phase 6 Prometheus and Grafana stack. Kubernetes workload state, pod readiness, restarts, resource usage, and deployment availability can therefore be observed independently from the CI/CD pipeline.

This architecture provides a foundation for future deployment strategies such as automated health-based rollback, canary releases, and progressive delivery.
