# 🔐 P2 — IAM in Depth

> **Zero Trust identity architecture on AWS — built ClickOps first, deployed as Infrastructure as Code with Terraform.**

![AWS](https://img.shields.io/badge/AWS-IAM%20%7C%20Organizations%20%7C%20SSO-FF9900?style=flat&logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![Security](https://img.shields.io/badge/Security-Zero%20Trust-red?style=flat)
![Region](https://img.shields.io/badge/Region-sa--east--1%20only-blue?style=flat)

---

## What is this?

A hands-on security project demonstrating **IAM in depth** — from first principles to production-grade access control enforced at the organization level.

Built as part of my AWS SAA-C03 preparation and portfolio. Every concept was first understood through the console (ClickOps), then codified into Terraform and deployed as a complete, reproducible architecture.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   AWS Organizations                     │
│                                                         │
│  SCP: deny-outside-sa-east1                            │
│  └── Blocks ALL actions outside sa-east-1              │
│       (applied at root, affects entire account)         │
│                                                         │
│  ┌──────────────────────────────────────────────┐      │
│  │              AWS Account                     │      │
│  │                                              │      │
│  │  IAM Identity Center (SSO)                  │      │
│  │  └── Permission Set: ReadOnlyAccess         │      │
│  │       └── joaquin.dev (federated user)      │      │
│  │                                              │      │
│  │  IAM Groups                                 │      │
│  │  └── Admins                                 │      │
│  │       └── joaquin-admin (AdministratorAccess│      │
│  │            via group — no direct policies)  │      │
│  │                                              │      │
│  │  IAM Role: ec2-readonly-role                │      │
│  │  └── Trust: IAM users (same account)                    │      │
│  │  └── Policy: ReadOnlyAccess                 │      │
│  │  └── STS AssumeRole (temporary credentials)│      │
│  │                                              │      │
│  │  Permission Boundary: developer-boundary    │      │
│  │  └── Ceiling: EC2 + CloudWatch only          │      │
│  │  └── Cannot escalate beyond boundary        │      │
│  │                                              │      │
│  │  Custom Policies                            │      │
│  │  ├── s3-sa-east1-only (region lock)        │      │
│  │  ├── deny-all-s3 (explicit deny)           │      │
│  │  └── s3-mfa-delete-protection              │      │
│  └──────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

**Key design principle:** No user holds direct policies. All permissions flow through groups or roles. The SCP enforces region isolation at the organization level — even AdministratorAccess cannot bypass it.

---

## AWS Services Used

| Service | Role |
|---|---|
| **IAM** | Users, groups, roles, policies, Permission Boundaries |
| **AWS Organizations** | SCP enforcement at root level |
| **IAM Identity Center** | Centralized SSO with Permission Sets |
| **STS** | Temporary credentials via AssumeRole |
| **Terraform** | Full infrastructure as code |

---

## Security Design

### Zero Trust Principles Applied

- **No standing permissions** — `joaquin-admin` has no direct policies; access flows exclusively through the `Admins` group managed by Terraform
- **Least privilege** — every role and policy scoped to minimum required actions
- **Explicit deny wins** — SCPs enforce region isolation regardless of identity-based policies
- **Temporary credentials** — EC2 role uses STS AssumeRole instead of long-lived access keys
- **Permission Boundaries** — developer persona cannot escalate privileges beyond S3 + CloudWatch ceiling

### Policy Evaluation Logic (SAA-C03)

```
Request → SCP allow? → No → DENY (hard stop)
              ↓ Yes
        → Explicit deny? → Yes → DENY
              ↓ No
        → Permission Boundary allow? → No → DENY
              ↓ Yes
        → Identity-based policy allow? → No → DENY
              ↓ Yes
        → ALLOW
```

---

## Infrastructure as Code

The entire stack is provisioned with Terraform. All sensitive values (account ID, SSO ARNs) are managed via `.tfvars` — never committed to version control.

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

### Repository Structure

```
p2-iam-portfolio/
├── main.tf                          # All IAM resources (14 managed)
├── variables.tf                     # Variable definitions (no hardcoded values)
├── outputs.tf                       # ARNs and IDs of deployed resources
├── providers.tf                     # AWS provider + us-east-1 alias for SSO
├── terraform.tfvars.example         # Template — copy and fill with your values
├── .gitignore                       # Excludes *.tfvars, .terraform/, state files
└── policies/
    ├── s3-sa-east1-only.json        # Condition: aws:RequestedRegion
    ├── deny-all-s3.json             # Explicit deny for S3 access
    ├── s3-mfa-delete-protection.json
    ├── developer-boundary.json      # Permission Boundary definition
    └── scp-deny-outside-sa-east1.json
```

---

## Key Concepts (SAA-C03 Domain 3 — Security)

| Concept | What this project demonstrates |
|---|---|
| **Permission Boundaries** | Set the maximum permissions ceiling; identity policies cannot exceed them |
| **SCPs** | Restrict what accounts *can* do — they never grant permissions on their own |
| **AssumeRole + STS** | Temporary credentials scoped to a role, no long-lived keys on EC2 |
| **Explicit Deny** | Always wins — used in SCPs and resource-based policies |
| **IAM Identity Center** | Replaces manual cross-account role assignments with centralized SSO |
| **Group-based access** | Users inherit permissions from groups; direct policies avoided by design |

---

## Incidents Resolved During Deployment

Real troubleshooting is part of the learning. Two incidents occurred during this deployment:

**1. Self-inflicted Access Denied (Break-Glass scenario)**
After removing direct permissions from `joaquin-admin` before the Terraform group was fully applied, the user lost console access. Resolution: authenticated as root (MFA), verified the Terraform state, confirmed group membership, and restored access through clean group inheritance. No manual policy changes — everything through IaC.

**2. Terraform state collision**
Drift between manually created resources (ClickOps phase) and Terraform state required `terraform import` and state reconciliation before a clean `apply` could succeed. Experienced AWS eventual consistency firsthand during this process — console reflected stale state while the API had already applied changes.

---

## How to Deploy

1. Clone the repo
2. Copy `terraform.tfvars.example` → `terraform.tfvars` and fill in your values
3. Run `terraform init && terraform apply`
4. Verify with `aws sts get-caller-identity --profile your-profile`

> ⚠️ IAM Identity Center (`aws_ssoadmin_*`) resources require `us-east-1` region — the providers file handles this automatically via a provider alias.

---

## Part of a Larger Portfolio

| Project | Stack | Focus |
|---|---|---|
| [S3ntient](https://github.com/Jbaigorria22) | AWS Lambda · DynamoDB · OpenAI · Terraform | Multi-user RAG system |
| [La Fortaleza](https://github.com/Jbaigorria22) | VPC · ALB · ASG · EC2 · Terraform | Production-grade network architecture |
| [NexaStock AI](https://github.com/Jbaigorria22) | Lambda · FastAPI · DynamoDB · GitHub Actions | Serverless supply chain AI |
| **P2 — IAM in Depth** | IAM · Organizations · SSO · Terraform | Zero Trust identity architecture |

---

*Built by [Joaquin Baigorria](https://www.linkedin.com/in/joaquinbaigorria) — AWS Cloud & Serverless Engineer · Córdoba, Argentina*