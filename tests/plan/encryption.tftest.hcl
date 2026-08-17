mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# Test 2.8: AES256 encryption by default — plan succeeds with defaults
run "aes256_default_encryption" {
  command = plan

  variables {
    ecr_prefix           = null
    repo_encryption_type = "AES256"
    repo_kms_key         = null
    ecr_config = {
      common_options = {}
      repo_list = {
        "aes-repo" = null
      }
    }
    tags = {}
  }

  # Plan succeeds with AES256 defaults and no KMS key lookup
  assert {
    condition     = output.repo_info["aes-repo"].repository_name == "aes-repo"
    error_message = "Expected aes-repo to be planned successfully with AES256 encryption"
  }

  # No KMS data source should be created
  assert {
    condition     = length(data.aws_kms_key.this) == 0
    error_message = "Expected no KMS key data source when repo_kms_key is null"
  }
}

# Test 2.9: KMS encryption path — plan succeeds and KMS data source is created
run "kms_encryption" {
  command = plan

  variables {
    ecr_prefix           = null
    repo_encryption_type = "KMS"
    repo_kms_key         = "alias/ecr-test-key"
    ecr_config = {
      common_options = {}
      repo_list = {
        "kms-repo" = null
      }
    }
    tags = {}
  }

  assert {
    condition     = output.repo_info["kms-repo"].repository_name == "kms-repo"
    error_message = "Expected kms-repo to be planned successfully with KMS encryption"
  }

  # KMS data source should be planned
  assert {
    condition     = length(data.aws_kms_key.this) == 1
    error_message = "Expected KMS key data source to be created when repo_kms_key is provided"
  }
}
