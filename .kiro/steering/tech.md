---
inclusion: always
---

# Tech Stack and Conventions

## Stack

- Terraform >= 1.6.0
- AWS provider >= 5.37.0
- Upstream module: `terraform-aws-modules/ecr/aws` v3.2.0
- CI: GitHub Actions with pinned SHA references for all actions
- Shared org actions: `Home-Office-Digital/core-cloud-workflow-*`
- SAST: Checkov + SonarQube

## Module structure

```
main.tf              # Core logic: locals, data sources, module invocation
variables.tf         # Input interface
outputs.tf           # repo_info map output
versions.tf          # Terraform and provider version constraints
policies/            # Default lifecycle policy JSON
example/             # Usage examples (Terraform, Terragrunt, YAML config)
tests/plan/          # Plan-level tftest.hcl files
specs/               # Agent instructions and POC documentation
```

## Patterns

- **`try()` fallback chains**: the dominant logic pattern. Per-repo → common_options → default. Always use `try()` for optional nested values.
- **No backend in module**: consumers provide their own backend. Tests use `terraform init -backend=false`.
- **YAML-driven config**: the module does not define repos internally. The calling layer decodes YAML and passes the structure in.
- **Additive-only changes to tests**: never modify existing module logic when adding test coverage.

## CI workflows

| Workflow | Purpose |
|----------|---------|
| `terraform-plan-tests.yaml` | Init, validate, run plan-level tests via shared action |
| `sast-scans.yaml` | Checkov + SonarQube scans |
| `pull-request-semver-label-check.yaml` | Enforce exactly one semver label on PRs |
| `pull-request-semver-tag-merge.yaml` | Apply semver git tag on merge to main |

## Conventions

- Pin action versions to commit SHAs (supply-chain security).
- Use descriptive names in Terraform resources and test `run` blocks.
- Keep the module interface minimal — complexity lives in the YAML config layer.
- All outputs go through `outputs.tf` — never expose upstream module internals directly.
