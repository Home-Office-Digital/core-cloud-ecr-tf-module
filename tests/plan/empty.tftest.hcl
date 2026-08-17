mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# Test 2.13: Empty repo list produces no resources
run "empty_repo_list" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {}
      repo_list      = {}
    }
    tags = {}
  }

  assert {
    condition     = length(output.repo_info) == 0
    error_message = "Expected repo_info to be an empty map when repo_list is empty"
  }
}
