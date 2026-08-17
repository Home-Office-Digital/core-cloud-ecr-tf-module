### POC Brief: AI-Driven Terraform Test Automation

Build an AI-assisted service that accepts one or more Terraform module repositories and autonomously creates a tested, reviewable pull request for each.

The agent will:

- Assess the module and identify meaningful test scenarios.
- Add validation, `terraform test` unit/apply tests, and selective Terratest coverage.
- Reuse centrally managed instructions, templates, and GitHub workflows.
- Create an isolated branch and PR per repository.
- Run tests locally, monitor CI, diagnose failures, and iterate until passing.
- Document test coverage, exclusions, results, risks, and infrastructure costs.

The POC should progress from assessment-only, through supervised implementation, to closed-loop PR delivery and multi-repository rollout.

**Success measures:** passing pipelines, meaningful behavioural coverage, reduced engineering effort, limited repair attempts, controlled cloud cost, and high-quality reviewable PRs.