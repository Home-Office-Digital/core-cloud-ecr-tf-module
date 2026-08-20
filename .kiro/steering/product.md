---
inclusion: always
---

# Product Context

## Purpose

This is `core-cloud-ecr-tf-module`, an internal Terraform module that creates and manages AWS ECR private repositories. It wraps the community `terraform-aws-modules/ecr/aws` (v3.2.0) and adds organisational conventions.

## Ownership

Team: `@Home-Office-Digital/core-cloud-phoenix`

## How it works

- Consumers define repositories in a YAML file and pass the decoded structure as `ecr_config`.
- `ecr_config` has two keys: `common_options` (shared defaults) and `repo_list` (per-repo overrides).
- The module iterates `repo_list` with `for_each`, applying a three-level fallback pattern: per-repo value → `common_options` → module default.
- An optional `ecr_prefix` provides logical namespace separation (e.g. team/tenant name).

## Key behaviours

- Naming: `prefix/repo-name` when prefix is set, plain `repo-name` otherwise. Both are trimmed of leading/trailing hyphens and spaces.
- Encryption: AES256 by default, optional KMS with CMK lookup.
- Lifecycle: default 5-rule policy in `policies/default_lifecycle_policy.json`, overridable at common or per-repo level.
- Immutability: `IMMUTABLE_WITH_EXCLUSION` by default, `latest` tag excluded via wildcard filter.
- Tags: merged from `var.tags` → `common_options.tags` → per-repo `tags`.

## Release process

SemVer via PR labels (major/minor/patch). On merge to main, a workflow calculates and applies a git tag. No release branches.
