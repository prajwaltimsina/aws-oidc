# Securing AWS Access with Terraform, GitHub Actions, and OIDC

This repository demonstrates a **secure, access** on AWS using **Terraform**, **OIDC** and **GitHub Actions**.

The project provisions cloud infrastructure using **Infrastructure as Code**, enforces **HTTPS-only traffic**, and authenticates to AWS using **OpenID Connect (OIDC)** — eliminating the need for long-lived access keys.

---

## 🔧 Technologies Used

* **AWS** (EC2, VPC, IAM)
* **Terraform** (Infrastructure as Code)
* **GitHub Actions** (CI/CD)
* **OIDC Federation** (passwordless authentication)
* **Amazon Linux 2** (Free Tier eligible)
* **Nginx (HTTPS enforced)**

---

## 🧱 Architecture Overview

```
Developer Push
      ↓
GitHub Actions (CI/CD)
      ↓
OIDC Authentication (No AWS Keys)
      ↓
AWS IAM Role (Temporary Credentials)
      ↓
Terraform Provisioning
      ↓
Secure EC2 (HTTPS-only)
```

---

## 🔐 Secure Authentication (OIDC)

This project **does not use AWS access keys**.

Instead:

* GitHub is configured as an **OIDC Identity Provider**
* GitHub Actions requests a short-lived identity token
* AWS IAM exchanges it for **temporary credentials**
* Credentials automatically expire after the pipeline run

✅ No secrets stored in GitHub
✅ No key rotation
✅ Reduced credential-leak risk

---

## ☁️ Infrastructure as Code

All AWS resources are defined in Terraform:

* Custom VPC (Sydney region)
* Public subnet in `ap-southeast-2`
* Internet gateway & routing
* Security group:

  * ✅ Port 443 (HTTPS)
  * ✅ Port 22 (SSH)
  * ❌ No HTTP (Port 80)
* EC2 instance using latest Amazon Linux 2 AMI

Infrastructure is fully reproducible and auditable via Git.

---

## 🔒 HTTPS Enforcement

* HTTP traffic is blocked at the firewall level
* Nginx is configured to serve content **only over HTTPS**
* TLS certificates are generated automatically at instance startup

This ensures all traffic is encrypted by default.

---

## 🤖 CI/CD Pipeline

The GitHub Actions pipeline:

1. Triggers automatically on push to `main`
2. Authenticates to AWS using OIDC
3. Initializes Terraform
4. Validates configuration
5. Applies infrastructure changes

There are:

* no SSH sessions
* no manual AWS console interaction
* no stored credentials

---

## ✅ Security Principles Applied

| Principle               | Implementation        |
| ----------------------- | --------------------- |
| Least privilege         | IAM role-bound access |
| Secrets management      | OIDC (no static keys) |
| Encryption              | HTTPS enforced        |
| Config drift prevention | IaC                   |
| Automation              | CI/CD driven          |

---

## 📌 Project Goals

This project was built to demonstrate:

* Secure cloud authentication patterns
* DevSecOps pipeline design
* Infrastructure lifecycle automation
* Practical AWS security controls
* Modern infrastructure-as-code workflows

---

## 📍 Region & Costs

* AWS Region: **ap-southeast-2 (Sydney)**
* Instance type: **t2.micro** (Free Tier eligible)

---

## 📂 Repository Structure

```
.
├── main.tf
├── .github/
│   └── workflows/
│       └── deploy.yml
└── README.md
```

---

## 📝 Notes

* HTTPS certificates are self-signed (expected browser warning)
* Designed for learning and demonstration purposes
* Easily extendable with WAF, ALB, and Trivy

---

## ✅ Summary

This repository demonstrates how **secure infrastructure can be built and deployed automatically**, without exposing credentials or manually managing cloud resources.

Security is enforced by design — not added as an afterthought.

---
