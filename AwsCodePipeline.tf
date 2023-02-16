# Define the AWS provider

provider "aws" {

  region = "us-west-2"

}

# Define the CodePipeline resources

resource "aws_codepipeline" "example" {

  name     = "example-pipeline"

  role_arn = aws_iam_role.pipeline.arn

  artifact_store {

    type     = "S3"

    location = "example-bucket"

  }

  stage {

    name = "Source"

    action {

      name            = "Source"

      category        = "Source"

      owner           = "ThirdParty"

      provider        = "GitHub"

      version         = "1"

      output_artifacts = ["source"]

      configuration {

        Owner          = "example"

        Repo           = "example-repo"

        Branch         = "master"

        OAuthToken     = var.github_token

      }

    }

  }

  stage {

    name = "Build"

    action {

      name            = "Build"

      category        = "Build"

      owner           = "AWS"

      provider        = "CodeBuild"

      version         = "1"

      input_artifacts = ["source"]

      output_artifacts = ["build"]

      configuration {

        ProjectName = "example-build-project"

      }

    }

  }

  stage {

    name = "Approval"

    action {

      name            = "Approval"

      category        = "Approval"

      owner           = "AWS"

      provider        = "Manual"

      version         = "1"

      input_artifacts = ["build"]

      configuration {

        CustomData = "Please approve this deployment"

      }

    }

  }

  stage {

    name = "Deploy"

    action {

      name            = "Deploy"

      category        = "Deploy"

      owner           = "AWS"

      provider        = "ECS"

      version         = "1"

      input_artifacts = ["build"]

      configuration {

        ClusterName = "example-cluster"

        ServiceName = "example-service"

        FileName   = "imagedefinitions.json"

      }

    }

  }

}

# Define the IAM role for the pipeline

resource "aws_iam_role" "pipeline" {

  name = "example-pipeline-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Principal = {

          Service = "codepipeline.amazonaws.com"

        }

        Action = "sts:AssumeRole"

      }

    ]

  })

}

# Attach the necessary policies to the IAM role

resource "aws_iam_role_policy_attachment" "pipeline" {

  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"

  role       = aws_iam_role.pipeline.name

}

resource "aws_iam_role_policy_attachment" "codebuild" {

  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"

  role       = aws_iam_role.pipeline.name

}

resource "aws_iam_role_policy_attachment" "ecs" {

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerServiceFullAccess"

  role       = aws_iam_role.pipeline.name

}

# Define any necessary variables

variable "github_token" {

  type        = string

  description = "GitHub personal access token for CodePipeline source stage"

}

