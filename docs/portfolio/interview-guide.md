# AcmeCloud Enterprise Platform — DevOps Interview Guide

## Purpose

This guide prepares you to explain the AcmeCloud Enterprise Platform in a DevOps Engineer interview. The answers are grounded in the engineering work implemented and validated in the project.

Use the answers as talking points rather than scripts to memorize word for word. In an interview, explain the problem, the engineering decision, how you implemented it, how you validated it, and what you learned.

## 2–3 Minute Project Walkthrough

**Question: Tell me about a DevOps project you have worked on.**

One of my main portfolio projects is AcmeCloud Enterprise Platform, an end-to-end DevOps platform that I built on AWS.

I started by creating the infrastructure using reusable Terraform modules. The infrastructure covers networking, security, compute, load balancing, storage and identity services, an optional data tier, Amazon EKS, and GitHub OIDC integration.

For configuration management, I used Ansible with reusable roles and AWS dynamic inventory. This allowed me to automate common Linux configuration, security hardening, Apache and Tomcat configuration, and monitoring-related tasks consistently across managed instances.

I then containerized the web and application tiers using Nginx and Tomcat. I hardened the containers to run as non-root users and published immutable images to private Amazon ECR repositories using Git commit SHA tags.

For orchestration, I deployed the containerized application to Amazon EKS. The web and application tiers run as replicated Kubernetes Deployments, and external traffic is routed through Kubernetes Ingress using AWS Load Balancer Controller and an Application Load Balancer.

I built a GitHub Actions CI/CD workflow that performs validation, container builds, vulnerability scanning, AWS authentication through GitHub OIDC, ECR publishing, gated EKS deployment, rollout verification, and deterministic rollback. Using OIDC means the pipeline does not depend on long-lived AWS access keys.

For observability, I integrated Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter, custom alerting rules, and a dashboard. I also retained CloudWatch monitoring for the EC2-based architecture.

I tested resilience by deliberately using invalid image references, observing the failed rollout, and validating restoration to a known-good release. During final integrated validation, the platform had distributed web and application replicas, healthy ALB targets, healthy monitoring components, and HTTP 200 responses from both the web and application routes.

Finally, because EKS, NAT Gateway, ALB, RDS, and ElastiCache can generate ongoing AWS costs, I developed automated shutdown and restoration workflows so I could preserve the reproducibility of the project without leaving expensive resources running.

The project gave me practical experience across the complete DevOps lifecycle: infrastructure, configuration, containers, Kubernetes, CI/CD, security, observability, resilience, troubleshooting, and operations.

---

## Architecture

### 1. How would you describe the architecture?

The project contains two complementary architecture paths.

The first demonstrates traditional infrastructure and configuration management using Terraform-provisioned AWS resources, EC2 Auto Scaling Groups, load balancing, Ansible, Systems Manager, and CloudWatch.

The second is the containerized production-style path. Docker images are stored in Amazon ECR and deployed to Amazon EKS. Kubernetes manages replicated web and application workloads. AWS Load Balancer Controller creates the ALB integration from Kubernetes Ingress. Prometheus, Grafana, and Alertmanager provide Kubernetes observability.

This progression demonstrates how traditional server automation can evolve toward container orchestration and automated application delivery.

### 2. What happens when a user accesses the application?

External HTTP traffic reaches an AWS Application Load Balancer created through the Kubernetes ingress integration.

The ALB routes traffic into the Kubernetes web service. Nginx serves the web tier, and requests for the application route are forwarded to the Tomcat application service.

The final integrated validation confirmed HTTP 200 responses for both `/` and `/app/`.

---

## Terraform and Infrastructure as Code

### 3. Why did you use Terraform?

I used Terraform to make the AWS infrastructure reproducible, version controlled, and modular.

Instead of manually creating cloud resources, infrastructure definitions are stored alongside the project. This allows infrastructure changes to be reviewed, validated, planned, and recreated consistently.

I separated major concerns into reusable modules, including networking, security, compute, load balancing, database services, EKS, storage and identity, and GitHub OIDC.

### 4. Why use modules instead of putting everything in one Terraform file?

Modules separate infrastructure responsibilities and make the configuration easier to maintain and reuse.

For example, networking logic belongs in the VPC module while EKS-specific resources belong in the EKS module. The root configuration connects the modules through inputs and outputs.

This reduces duplication and makes future changes easier to isolate.

### 5. What Terraform problems did you troubleshoot?

Examples included:

- Conditional NAT Gateway resources causing invalid index references.
- Module path case mismatches.
- Missing module outputs.
- Invalid AMI values.
- Bastion CIDR validation.
- RDS final snapshot requirements during destroy.
- Remote state and DynamoDB checksum inconsistencies after a state object had been removed.
- Variable validation when an optional database password was null.

For each issue, I inspected the configuration and state, identified the dependency or lifecycle problem, corrected the configuration, and validated the result before continuing.

### 6. How did you control infrastructure cost?

I made expensive components conditional and developed shutdown and restoration scripts.

The shutdown process disables EKS, NAT Gateway, ALB, RDS, and ElastiCache when they are not required. I verified that the expensive resources were actually removed rather than assuming Terraform had completed successfully.

The restore process rebuilds the required environment and validates the release before deploying it.

---

## Ansible and Configuration Management

### 7. Why did you use Ansible when you already had Terraform?

Terraform and Ansible solve different parts of the problem.

Terraform provisions infrastructure such as networks, security groups, compute resources, IAM, and EKS. Ansible configures operating systems and application software after compute resources exist.

Using both demonstrates separation between infrastructure provisioning and system configuration.

### 8. What did you automate with Ansible?

I created reusable roles for common operating-system configuration, security hardening, web-tier configuration, application-tier configuration, and monitoring-related configuration.

The project also moved from static lab inventory toward AWS dynamic inventory so instances could be discovered from AWS rather than maintained manually.

### 9. How did you validate Ansible idempotency?

I reran the playbooks after successful configuration and checked that Ansible did not make unnecessary changes when the desired state was already present.

That is important because configuration management should converge systems toward the declared state rather than repeatedly changing correctly configured servers.

---

## Docker and Amazon ECR

### 10. How did you containerize the application?

I separated the platform into a web container based on Nginx and an application container based on Tomcat.

I first validated the containers locally, including the communication between the web and application tiers, before integrating them with ECR and Kubernetes.

### 11. How did you secure the containers?

Both containers run as non-root users.

At Kubernetes level, I also configured `runAsNonRoot`, RuntimeDefault seccomp, disabled privilege escalation, and dropped Linux capabilities.

This reduces the permissions available to a compromised container.

### 12. Why did you use immutable image tags?

I used the first 12 characters of the Git commit SHA as the release identifier.

That gives each release a unique reference and provides traceability between source code and the images deployed to the platform.

The final validated release was:

`536b0e8455a0`

Both the web and application images used the same release identifier.

### 13. Why use ECR?

Amazon ECR provides a private AWS-native container registry that integrates naturally with IAM and EKS.

The project uses separate repositories for the web and application images and immutable release tagging rather than relying on `latest`.

---

## Kubernetes and Amazon EKS

### 14. Why did you use Kubernetes?

Kubernetes provides declarative workload management, replication, service discovery, rolling deployments, health management, and orchestration.

Using EKS allowed me to apply those concepts in an AWS-managed Kubernetes control-plane environment.

### 15. How was the application deployed to EKS?

The application uses Kubernetes Deployments and Services for the web and application tiers.

The production release is rendered using Kustomize with the immutable release tag. This prevents unresolved placeholder tags from being deployed and ensures both tiers use the intended release.

### 16. Why run multiple replicas?

Multiple replicas improve availability and allow Kubernetes to perform rolling updates without intentionally taking the entire application tier offline.

The final validation used two web replicas and two application replicas distributed across worker nodes.

### 17. How did external traffic reach EKS?

I installed AWS Load Balancer Controller and used Kubernetes Ingress.

The controller translates the Kubernetes ingress configuration into AWS Application Load Balancer resources and target groups.

During final validation, the ALB targets were healthy and both application routes returned HTTP 200.

---

## CI/CD and GitHub Actions

### 18. Explain your CI/CD pipeline.

The GitHub Actions workflow includes validation, Docker image builds, Kubernetes validation, container security scanning, AWS OIDC authentication testing, ECR publishing, and a gated EKS deployment path.

For deployment, the workflow renders the immutable release, applies it to Kubernetes, waits for rollout completion, and verifies the result.

Before changing the workloads, it records the currently deployed images. If deployment fails, the rollback logic restores those exact previous images rather than guessing which tag should be restored.

### 19. Why did you use GitHub OIDC?

OIDC allows GitHub Actions to request short-lived AWS credentials by assuming an IAM role.

This is preferable to storing long-lived AWS access keys as GitHub secrets because there are no permanent CI access keys to rotate or accidentally expose.

The IAM trust relationship restricts who can assume the role.

### 20. How does your deployment rollback work?

Before deployment, the workflow captures the exact currently deployed web and application image references.

It then applies the new release and waits for Kubernetes rollout verification.

If the rollout fails, the rollback logic restores the captured image references and waits for the restored workloads to become healthy.

I separately validated the rollback mechanism by introducing invalid ECR image references and restoring the known-good release.

### 21. Did GitHub Actions deploy the final validated release?

I would not claim that without workflow-run evidence.

The GitHub Actions workflow implements the gated EKS deployment and deterministic rollback capability. The final integrated validation used the same immutable Kustomize release mechanism and validated the resulting platform end to end.

Keeping those claims separate makes the project evidence accurate.

---

## Observability

### 22. What monitoring did you implement?

For Kubernetes, I implemented Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter, custom alerting rules, and a platform dashboard.

Prometheus collects metrics, Grafana provides visualization, and Alertmanager handles alert routing.

For the EC2-based architecture, CloudWatch remains part of the monitoring approach.

### 23. What is the difference between monitoring and observability?

Monitoring tells me whether known conditions are healthy or unhealthy through metrics, dashboards, and alerts.

Observability is broader: it is the ability to understand system behaviour using telemetry and investigate why a system is behaving a certain way.

In this project, Prometheus metrics, Grafana dashboards, Kubernetes state metrics, node metrics, alerts, and CloudWatch infrastructure visibility provide the basis for operational investigation.

---

## Security

### 24. What security controls did you implement?

Security was applied at several layers:

- AWS IAM and GitHub OIDC for controlled CI/CD authentication.
- Security groups for network access control.
- Private ECR repositories.
- SSM-based instance management in the AWS configuration-management path.
- Non-root container execution.
- Kubernetes `runAsNonRoot`.
- RuntimeDefault seccomp.
- Disabled privilege escalation.
- Dropped Linux capabilities.
- Container vulnerability scanning in CI.
- Immutable image releases for traceability.

### 25. Why is running containers as non-root important?

If an application is compromised, a non-root process has fewer privileges inside the container.

It does not eliminate all container risk, but it reduces the potential impact and supports defence in depth.

---

## Resilience and Troubleshooting

### 26. How did you test failure rather than only testing the happy path?

I deliberately introduced invalid image references.

Kubernetes could not successfully roll out those workloads, which allowed me to observe deployment failure behaviour and validate restoration to the known-good release.

This tested both failure detection and recovery rather than simply confirming that a correct deployment worked.

### 27. What was one significant troubleshooting lesson from the project?

A recurring lesson was to validate the system at the layer where the failure occurs instead of assuming the previous automation step proves success.

For example, after Terraform or Kubernetes operations, I checked the actual AWS resources, workload state, target health, monitoring components, and HTTP responses.

This became especially important during cost-control shutdown, deployment troubleshooting, and final production validation.

### 28. Give an example of a container/Kubernetes issue you solved.

The Nginx container originally caused a Kubernetes `runAsNonRoot` issue because the runtime could not reliably establish that the configured user was non-root.

I changed the image to use the numeric Nginx UID/GID and validated the image and deployment again. This allowed Kubernetes to enforce `runAsNonRoot` correctly.

### 29. Give an example of an AWS/Terraform issue you solved.

One example was conditional NAT Gateway creation. Terraform attempted to reference the first NAT Gateway even when the resource count resulted in an empty collection.

I corrected the conditional resource/dependency logic so the configuration could support both NAT-enabled and cost-controlled NAT-disabled environments.

---

## Production Engineering Discussion

### 30. Is this a real production system?

I describe it as a production-style portfolio platform rather than claiming it is a commercial production workload.

It implements production-relevant engineering practices such as modular IaC, immutable releases, CI/CD, short-lived cloud authentication, workload hardening, monitoring, multiple replicas, rollout verification, rollback, failure testing, and cost-aware operations.

That distinction keeps the description technically credible.

### 31. What would you improve before supporting a real business-critical workload?

I would extend the platform with areas such as:

- HTTPS and certificate management throughout the public entry point.
- DNS and domain management.
- A formal secrets-management service and rotation strategy for application secrets.
- Backup and restore testing for stateful services.
- Multi-environment promotion such as development, staging, and production.
- Stronger policy enforcement and admission controls.
- Centralized application logging and trace correlation.
- Defined SLOs/SLIs and alert thresholds based on business requirements.
- Autoscaling policies validated against realistic load.
- Disaster-recovery objectives and tested recovery procedures.
- More comprehensive automated integration and end-to-end tests.

The exact additions would depend on the application's availability, compliance, security, and recovery requirements.

### 32. Why is cost control part of DevOps engineering?

Cloud operations are not only about deploying resources. Engineers also need to understand lifecycle and cost.

For a portfolio environment, leaving EKS, NAT Gateway, ALB, RDS, and ElastiCache running continuously would create unnecessary cost.

I therefore treated shutdown and restoration as engineering workflows rather than manually deleting resources. This preserves reproducibility while controlling spend.

---

## Behavioural Questions Using the Project

### 33. Tell me about a difficult problem you solved.

A strong example is the final EKS integration.

**Situation:** The infrastructure and individual platform components had been built, but the integrated production-style deployment still had to be validated.

**Task:** I needed to restore the AWS environment, deploy an immutable release, verify Kubernetes workload security and availability, validate ingress and monitoring, and then safely shut expensive resources down.

**Action:** I corrected issues in the restore workflow, fixed Terraform null validation, resolved the Nginx non-root UID issue, consolidated the Kustomize release mechanism, deployed a shared immutable release tag, and validated the application from Kubernetes through the ALB.

**Result:** The final environment had healthy distributed replicas, healthy ALB targets, healthy observability components, and HTTP 200 responses for both application routes. I then verified removal of the expensive AWS resources through the shutdown workflow.

### 34. Tell me about a time something did not work as expected.

One example was the Nginx workload failing Kubernetes non-root validation.

Instead of weakening the Kubernetes security setting, I investigated why the runtime could not prove the container user was non-root. I changed the image to use the numeric Nginx UID/GID, rebuilt and validated the container, and then redeployed it.

The lesson was to fix the workload so it satisfies the security control rather than disabling the control to make the deployment pass.

### 35. How did you approach learning unfamiliar technology?

The project was developed incrementally.

I first validated individual concepts in smaller environments—for example, static Ansible inventory before AWS dynamic inventory and local Docker integration before EKS deployment. Once each layer worked, I integrated it into the wider platform.

That approach reduced the number of variables involved when troubleshooting and gave me evidence that each component worked before combining the full system.

---

## Rapid-Fire Technical Questions

### What is Infrastructure as Code?

Infrastructure as Code means defining infrastructure in version-controlled configuration so environments can be provisioned and changed consistently through automation rather than manual console configuration.

### What is idempotency?

An idempotent operation can be run repeatedly and still converge on the same desired state without making unnecessary changes once that state has been achieved.

### What is a Docker image?

A Docker image is an immutable package containing the application, runtime, dependencies, and filesystem layers required to start a container.

### What is a Kubernetes Deployment?

A Deployment declaratively manages replicated application Pods and supports controlled updates and rollback behaviour.

### What is a Kubernetes Service?

A Service provides stable network access to a set of Pods selected by labels.

### What is Ingress?

Ingress defines external HTTP/HTTPS routing into Kubernetes services. In this project, AWS Load Balancer Controller integrates the ingress definition with an AWS Application Load Balancer.

### What is a rolling update?

A rolling update gradually replaces old application replicas with new ones so the application can remain available during deployment when capacity and health conditions allow.

### What is OIDC?

OpenID Connect is an identity protocol. In this project, GitHub Actions uses OIDC federation to assume an AWS IAM role and receive short-lived credentials instead of storing permanent AWS access keys.

### What is Prometheus?

Prometheus is a metrics collection and querying system commonly used for infrastructure and Kubernetes monitoring.

### What is Grafana?

Grafana provides dashboards and visualization for telemetry sources such as Prometheus.

### What is Alertmanager?

Alertmanager receives alerts from Prometheus and manages grouping, routing, and notification handling.

---

## Questions to Ask the Interviewer

Useful questions for a DevOps Engineer interview include:

- How is infrastructure currently provisioned and reviewed?
- How are application releases promoted between environments?
- What CI/CD platform does the team use?
- How does the team manage cloud authentication for CI/CD?
- What Kubernetes responsibilities sit with the DevOps/platform team?
- How are observability, alerting, and incident response handled?
- How are secrets managed and rotated?
- What availability and recovery objectives does the platform have?
- How does the team balance platform reliability with cloud cost?
- What would you expect the successful candidate to improve during the first six months?

---

## Interview Reminder

Do not try to impress an interviewer by claiming every technology is production experience.

Explain exactly what you built, why you chose the approach, how you tested it, what failed, how you diagnosed it, and what you would change in a business production environment.

That demonstrates the engineering judgement behind the tools rather than simply listing technologies.
