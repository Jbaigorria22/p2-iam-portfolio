# =============================================
# FASE 1 — IAM Hardening
# =============================================

# Grupo Admins
resource "aws_iam_group" "admins" {
  name = var.admin_group_name
}

# Attach AdministratorAccess al grupo
resource "aws_iam_group_policy_attachment" "admins_policy" {
  group      = aws_iam_group.admins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# =============================================
# FASE 2 — Politicas Custom
# =============================================

resource "aws_iam_policy" "s3_sa_east1_only" {
  name   = "s3-sa-east1-only"
  policy = file("policies/s3-sa-east1-only.json")
}

resource "aws_iam_policy" "deny_all_s3" {
  name   = "deny-all-s3"
  policy = file("policies/deny-all-s3.json")
}

resource "aws_iam_policy" "s3_mfa_delete_protection" {
  name   = "s3-mfa-delete-protection"
  policy = file("policies/s3-mfa-delete-protection.json")
}

# =============================================
# FASE 3 — Roles y STS
# =============================================

resource "aws_iam_role" "ec2_readonly" {
  name = "ec2-readonly-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_readonly_policy" {
  role       = aws_iam_role.ec2_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# =============================================
# FASE 4 — Permission Boundary
# =============================================

resource "aws_iam_policy" "developer_boundary" {
  name   = "developer-boundary"
  policy = file("policies/developer-boundary.json")
}

# =============================================
# FASE 5 — SCP Organizations
# =============================================

resource "aws_organizations_policy" "deny_outside_sa_east1" {
  name    = "deny-outside-sa-east1"
  type    = "SERVICE_CONTROL_POLICY"
  content = file("policies/scp-deny-outside-sa-east1.json")
}

resource "aws_organizations_policy_attachment" "scp_root" {
  policy_id = aws_organizations_policy.deny_outside_sa_east1.id
  target_id = "r-c20p"
}

# =============================================
# FASE 6 — IAM Identity Center
# =============================================

resource "aws_ssoadmin_permission_set" "readonly" {
  provider         = aws.us_east_1
  name             = "Portfolio-ReadOnly"
  instance_arn     = var.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly_policy" {
  provider           = aws.us_east_1
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_identitystore_user" "joaquin_dev" {
  provider          = aws.us_east_1
  identity_store_id = var.identity_store_id

  user_name    = "joaquin.dev"
  display_name = "Joaquin Developer"

  name {
    given_name  = "Joaquin"
    family_name = "Baigorria"
  }

  emails {
    value   = "joaquinbaigorria22@gmail.com"
    type    = "work"
    primary = true
  }
}

resource "aws_ssoadmin_account_assignment" "joaquin_dev_readonly" {
  provider           = aws.us_east_1
  instance_arn       = var.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  target_id          = var.account_id
  target_type        = "AWS_ACCOUNT"
  principal_type     = "USER"
  principal_id       = aws_identitystore_user.joaquin_dev.user_id
}
