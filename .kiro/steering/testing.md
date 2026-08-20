---
inclusion: fileMatch
fileMatchPattern: "**/*.tftest.hcl"
---

# Terraform Test Conventions

## Framework

Native `terraform test` (requires Terraform >= 1.6.0). All tests are plan-level — no AWS credentials required.

## Directory

Tests live in `tests/plan/`. Supporting fixture files (JSON policies, YAML configs) go in `tests/plan/fixtures/`.

## File structure

Every `.tftest.hcl` file must start with a `mock_provider "aws"` block:

```hcl
mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}
```

Add additional `mock_data` blocks for any data source whose computed values are consumed by validation logic downstream.

## Test design

- Use inline `variables {}` blocks — each `run` block should be self-contained.
- Assert against `output.repo_info` values (these cross module boundaries).
- Use plan success as a valid assertion for input combination correctness.
- Use `length()` checks for conditional resource creation.
- Group related assertions into a single `run` block where practical.

## What to test at plan level

- Naming and output logic (computed from inputs)
- Conditional resource creation (`count`/`for_each` based on inputs)
- Variable precedence / `try()` fallback chains
- Edge cases: empty inputs, null values, trimming
- `file()` calls with fallback paths

## What cannot be tested at plan level

- Internal resource attributes behind the upstream module boundary
- Provider-generated computed values (ARNs, IDs)
- Actual policy document content from mocked data sources

## Naming

Use descriptive `run` block names that clearly state what is being tested. Follow a numbered scheme per file (e.g. "Test 2.1: description").

## Running locally

```bash
terraform init -backend=false
terraform test -test-directory=tests/plan
```
