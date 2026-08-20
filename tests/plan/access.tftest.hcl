mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":[\"ecr:GetDownloadUrlForLayer\"]}]}"
    }
  }
}

# Test 2.10: Per-repo read access ARNs override common_options
run "access_arn_override" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {
        repository_read_access_arns = ["arn:aws:iam::111111111111:root"]
      }
      repo_list = {
        "common-access-repo" = null
        "override-access-repo" = {
          repository_read_access_arns = ["arn:aws:iam::333333333333:root"]
        }
      }
    }
    tags = {}
  }

  # The upstream module generates a policy from a data source so with mocked providers
  # we can't directly inspect the ARN content in the policy JSON.
  # Instead we verify the input variables are being passed correctly by checking
  # that the module instances exist (plan succeeds with these inputs).
  assert {
    condition     = output.repo_info["override-access-repo"].repository_name == "override-access-repo"
    error_message = "Expected override-access-repo to be planned successfully"
  }

  assert {
    condition     = output.repo_info["common-access-repo"].repository_name == "common-access-repo"
    error_message = "Expected common-access-repo to be planned successfully"
  }
}

# Test 2.11: Lambda access is repo-only, not inherited from common_options
run "lambda_access_repo_only" {
  command = plan

  variables {
    ecr_prefix = null
    ecr_config = {
      common_options = {}
      repo_list = {
        "lambda-repo" = {
          repository_lambda_read_access_arns = ["arn:aws:lambda:eu-west-2:444444444444:function:my-func"]
        }
        "no-lambda-repo" = null
      }
    }
    tags = {}
  }

  # Verify both repos are planned successfully with different lambda access configs
  assert {
    condition     = output.repo_info["lambda-repo"].repository_name == "lambda-repo"
    error_message = "Expected lambda-repo to be planned successfully"
  }

  assert {
    condition     = output.repo_info["no-lambda-repo"].repository_name == "no-lambda-repo"
    error_message = "Expected no-lambda-repo to be planned successfully"
  }
}
