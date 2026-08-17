Testing Strategy
This document defines multiple levels of testing for the Terraform ECR module so changes can be validated quickly and safely.

Goals
Catch syntax and style issues early.
Catch schema and logic issues before apply.
Validate behavior of generated ECR resources.
Reduce risk of security and policy regressions.
Test Levels
1. Format and Documentation Checks (Fast)
Purpose: Ensure consistent formatting and docs hygiene.

Commands:

terraform fmt -check -recursive
Optional (if you manage generated docs):

terraform-docs markdown table .
Recommended frequency:

Run locally before commits.
Run in CI on every pull request.
2. Static Validation (Fast)
Purpose: Catch invalid Terraform configuration and type/shape errors.

Commands:

terraform init -backend=false
terraform validate
Recommended frequency:

Run locally for all module changes.
Required CI gate on every pull request.
3. Linting and Best Practices (Fast to Medium)
Purpose: Catch Terraform anti-patterns and maintainability issues.

Tools:

tflint
tfsec or checkov (security-focused static checks)
Commands:

tflint --init
tflint
Examples:

tfsec .
# or
checkov -d .
Recommended frequency:

Run in CI on pull requests.
Treat high severity findings as blocking.
4. Unit-Style Module Tests (Medium)
Purpose: Validate module behavior for key input combinations without full account-level integration complexity.

Suggested approach:

Use Terraform test framework (terraform test) with .tftest.hcl files.
Add fixtures for:
Default lifecycle policy behavior.
Repo-level override behavior.
KMS encryption path (repo_encryption_type = "KMS").
Access policy merge behavior (common_options + repo overrides).
Example assertions to include:

Repository names are generated as expected.
Output map repo_info contains all requested repos.
Lifecycle policy source selection follows fallback order.
Recommended frequency:

Run in CI on pull requests.
5. Integration Tests in AWS (Slow, High Confidence)
Purpose: Verify real creation and behavior of ECR repositories in a test AWS account.

Suggested approach:

Use Terratest (Go) or scripted Terraform apply/destroy in a dedicated test account.
Use unique test prefixes to avoid collisions.
Always destroy resources in teardown.
Key scenarios:

Create multiple repos from YAML.
Verify policy attachment and expected principals.
Verify lifecycle policy exists and parses.
Verify repository URLs and registry IDs in repo_info outputs.
Recommended frequency:

Run nightly or on merge to main.
Optionally run on pull request for high-risk changes.
6. Security and Compliance Policy Tests (Medium)
Purpose: Enforce organizational policy expectations.

Examples:

Fail if repo encryption is not approved.
Fail if wildcard policy statements are used without required conditions.
Fail if lifecycle policy is missing when required by policy.
Suggested tools:

OPA/Conftest
Checkov custom policies
Recommended frequency:

Run in CI for pull requests and main branch merges.
7. Release and Regression Tests (Slow)
Purpose: Prevent regressions for module consumers.

Suggested checks before release tag:

Run all fast checks (fmt, validate, lint, security scan).
Run integration suite in test account.
Verify example configurations still pass terraform validate.
Verify README input/output docs match module behavior.
Suggested CI Pipeline Stages
fmt-and-validate
lint-and-security
module-tests
integration-tests (nightly or protected-branch)
release-gates
Minimum Baseline to Start
If you want a phased rollout, start with this baseline:

terraform fmt -check -recursive
terraform init -backend=false && terraform validate
tflint
Then add terraform test and integration tests in the next iteration.

Notes for This Module
This module is driven by decoded YAML (ecr_config), so test coverage should focus heavily on default-vs-override precedence.
Because the module wraps terraform-aws-modules/ecr/aws, tests should validate both wrapper logic and expected downstream outputs.
Include at least one test case for repositories that require Lambda read access (repository_lambda_read_access_arns).