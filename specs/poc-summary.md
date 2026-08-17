# POC Summary: AI-Driven Terraform Test Automation

## Problem

- We have a backlog task to add foundational automated tests across all our Terraform module repos — there are many of them
- Writing these tests manually takes significant dev time and is repetitive work
- Investigating whether an AI agent can perform this activity for us
- This POC targets a single repo; the end goal is an agent-driven process that takes a list of repos and produces a PR per repo that is fully verified in the pipeline (tests pass, SonarQube clean)
- Human stays in the loop to review and merge the PR

## What We Delivered

- **Agent assessed the module autonomously** — identified meaningful test scenarios from the module logic without human guidance on what to test
- **Generated working tests end-to-end** — from initial assessment through to 17 passing plan-level tests, including iterating on failures (mock provider issues, module boundary constraints)
- **Produced a CI-ready workflow** — GitHub Actions pipeline that can be triggered from the UI, runs the full test suite, and integrates with the org's shared actions and SonarQube
- **Created reusable agent instructions** (`specs/instructions.md`) — a template that can be pointed at other repos to repeat this process
- **No human wrote any test code** — the agent handled assessment, implementation, debugging, and delivery
- **Zero AWS credentials needed** — all tests run with mocked providers, making them fast and safe for CI

### Artefacts

- `versions.tf` — terraform and provider version constraints
- `tests/plan/` — 7 test files covering naming, lifecycle fallback, tags, encryption, access, immutability, empty inputs
- `.github/workflows/terraform-plan-tests.yaml` — CI workflow with `workflow_dispatch`
- `specs/instructions.md` — reusable agent instructions
- `.gitignore` — housekeeping

## Observations

- Plan-level tests are fast (~5 seconds total) and require zero cloud access
- The `try()` fallback pattern is the most important logic to test in this module
- Deeper assertions (tags, encryption type on the resource) would require integration tests with `command = apply`
- `workflow_dispatch` makes this invocable from the GitHub Actions UI without a PR

## Next Steps

- **Get the agent working from the GitHub UI** — QE triggers the process from the Actions page (or a chatops command), agent runs autonomously
- **Target workflow:**
  1. Agent checks out the module repo
  2. Assesses the module — identifies resources, logic, and meaningful test scenarios
  3. Devises and creates tests following the standards in `specs/instructions.md`
  4. Adds the CI workflow using org conventions
  5. Raises a PR
  6. Verifies tests are passing (monitors checks, iterates on failures)
  7. Notifies the team that the PR is ready for review
- **Expand test scope over time:**
  - Current: plan-level unit tests (no credentials, fast feedback)
  - Next: apply-level tests in a sandbox account (real resource creation/verification)
  - Future: end-to-end tests covering multi-module compositions and policy compliance
- **Scale to multiple repos** — agent takes a list of repos and works through them, producing one PR per repo

## Token Usage

- Single session, ~15 minutes wall-clock time
- ~12 agent turns with ~50+ tool calls
- Agent self-corrected twice (mock provider fix, module boundary constraint workaround)
- Comparable human effort estimate: 2-4 hours for same deliverables
