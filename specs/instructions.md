# Instructions: Terraform Plan-Level Test Automation

This document provides the instructions for an AI agent to implement plan-level `terraform test` coverage for the `core-cloud-ecr-tf-module` module, along with the supporting CI workflow and foundational changes.

---

## Scope

This iteration covers:

1. Foundational changes (version constraints, directory structure).
2. Plan-only `terraform test` unit tests (no AWS credentials required).
3. A GitHub Actions CI workflow to run the tests on PR and push to `main`.

Out of scope for now: integration tests (apply/destroy), Terratest, security policy tests.

---

## 1. Foundation

### 1.1 Add `versions.tf`

Create a `versions.tf` at the module root with:

- `required_version >= 1.6.0` (minimum for native `terraform test` support).
- `required_providers` block declaring the `aws` provider (source `hashicorp/aws`, version constraint matching what the upstream `terraform-aws-modules/ecr/aws` v3.2.0 expects).

### 1.2 Directory Structure

```
tests/
  plan/
    *.tftest.hcl       # Plan-level test files
    fixtures/
      default/         # Fixture for default/common scenarios
        main.tf
        *.yaml         # Test YAML configs
      kms/             # Fixture for KMS encryption path
        main.tf
        *.yaml
      ...              # Additional fixtures as needed
```

- Test files live in `tests/plan/`.
- Each fixture is a minimal Terraform configuration that calls the module under test with specific inputs.
- Fixtures should include their own provider blocks (with `skip_requesting_account_id = true` or mock configuration to avoid AWS calls during plan).

---

## 2. Test Cases

All tests use `command = plan` (no apply). They validate the planned resource graph and output values.

### 2.1 Repository Naming — No Prefix

- Input: `ecr_prefix = null`, `repo_list` with keys `"app-one"`, `"app-two"`.
- Assert: planned repository names equal the keys exactly (trimmed of leading/trailing hyphens).

### 2.2 Repository Naming — With Prefix

- Input: `ecr_prefix = "my-tenant"`, `repo_list` with key `"service-a"`.
- Assert: planned repository name is `"my-tenant/service-a"`.

### 2.3 Repository Naming — Prefix Trimming

- Input: `ecr_prefix = "-padded-"`, `repo_list` with key `"-svc-"`.
- Assert: planned repository name is `"padded/svc"` (hyphens/spaces trimmed from both).

### 2.4 Lifecycle Policy Fallback — Default

- Input: no `repository_lifecycle_policy` at repo or common_options level.
- Assert: the lifecycle policy content matches `policies/default_lifecycle_policy.json`.

### 2.5 Lifecycle Policy — Common Options Override

- Input: `common_options.repository_lifecycle_policy` points to a custom policy file in the fixture.
- Assert: lifecycle policy content matches the custom file, not the default.

### 2.6 Lifecycle Policy — Per-Repo Override

- Input: per-repo `repository_lifecycle_policy` set, common_options also set.
- Assert: lifecycle policy matches the per-repo file (highest precedence).

### 2.7 Tag Merge Order

- Input: module-level `tags`, `common_options.tags`, and per-repo `tags` all set with overlapping keys.
- Assert: the final tags on the planned resource reflect the correct merge precedence (per-repo wins over common_options, which wins over module-level).

### 2.8 Encryption — AES256 Default

- Input: `repo_encryption_type` not set (defaults to `"AES256"`), `repo_kms_key = null`.
- Assert: planned encryption type is `"AES256"`, no KMS key data source is created.

### 2.9 Encryption — KMS Path

- Input: `repo_encryption_type = "KMS"`, `repo_kms_key = "alias/my-key"`.
- Assert: KMS key data source is planned, encryption type is `"KMS"`.

### 2.10 Access ARN Precedence

- Input: `common_options.repository_read_access_arns = ["arn:common"]`, per-repo `repository_read_access_arns = ["arn:override"]`.
- Assert: the planned repo uses `["arn:override"]`, not the common value.

### 2.11 Lambda Access — Repo-Only

- Input: `common_options` does NOT define `repository_lambda_read_access_arns`. One repo defines it, another does not.
- Assert: only the repo that defines lambda ARNs has them in plan; the other has an empty list.

### 2.12 Immutability Defaults

- Input: no overrides for tag mutability.
- Assert: planned `repository_image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"` with exclusion filter containing `latest`.

### 2.13 Empty Repo List

- Input: `repo_list = {}`.
- Assert: no ECR module instances are planned. Output `repo_info` is an empty map.

---

## 3. Test File Conventions

- Use descriptive `run` block names that clearly state what is being tested.
- Group related assertions into a single `run` block where practical.
- Use `variables` blocks within test files or reference fixture `.tfvars` files.
- Prefer inline `variables` for clarity unless the input is large (then use a fixture YAML file).
- Use `mock_provider` blocks to avoid real AWS API calls during plan:

```hcl
mock_provider "aws" {}
```

- Reference the module under test from fixtures using a relative `source` path back to the module root.

---

## 4. CI Workflow

### 4.1 Create `.github/workflows/terraform-plan-tests.yaml`

Follow this structure:

```yaml
name: Terraform Plan Tests

on:
  pull_request:
    types: [opened, reopened, synchronize]
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read
  pull-requests: write

jobs:
  terraform-plan-tests:
    name: Terraform Plan Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@b9cd54a3c349d3f38e8881555d616ced269862dd

      - name: Terraform init
        run: terraform init -backend=false

      - name: Terraform validate
        run: terraform validate

      - name: Terraform test
        id: terraform-test
        uses: Home-Office-Digital/core-cloud-workflow-terraform-actions/actions/test@main
        with:
          working-directory: .
          test-directory: tests/plan
          sonar-host-url: ${{ secrets.SONAR_HOST_URL }}
          sonar-token: ${{ secrets.SONAR_TOKEN }}
```

Key points:
- Use pinned commit SHAs for actions (not version tags) for supply-chain security.
- The test action from `Home-Office-Digital/core-cloud-workflow-terraform-actions` handles running `terraform test` and reporting.
- `test-directory` points to `tests/plan` where all `.tftest.hcl` files live.
- The workflow does NOT need AWS credentials since all tests are plan-only with mocked providers.

---

## 5. Execution Steps (Agent Checklist)

1. Create `versions.tf` at module root.
2. Create directory structure: `tests/plan/fixtures/`.
3. Create fixture modules (one per logical test group) with minimal `main.tf` and input YAML files.
4. Write `.tftest.hcl` files in `tests/plan/` covering all test cases in Section 2.
5. Run `terraform init -backend=false` to verify the module initialises cleanly.
6. Run `terraform test -test-directory=tests/plan` locally to validate all tests pass.
7. Fix any failures, iterating until all tests pass.
8. Create `.github/workflows/terraform-plan-tests.yaml` per Section 4.
9. Create a feature branch, commit all changes, and open a PR.
10. Verify CI passes on the PR.

---

## 6. Quality Criteria

- All test cases pass locally with `terraform test`.
- No AWS credentials are required to run the test suite.
- Test file names and run block names are self-documenting.
- Fixtures are minimal — only the inputs needed for the test group.
- CI workflow triggers correctly on PR and push to `main`.
- No changes to existing module logic (this is additive only).

---

## 7. References

- Module source: `terraform-aws-modules/ecr/aws` v3.2.0
- Testing strategy: `specs/testing.md`
- Example usage: `example/` directory
- Default lifecycle policy: `policies/default_lifecycle_policy.json`
- Terraform test docs: https://developer.hashicorp.com/terraform/language/tests
