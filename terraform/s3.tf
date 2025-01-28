resource "aws_s3_bucket" "s3_bucket_glue_scripts" {
  bucket = "s3-glue-scripts"
}

resource "aws_s3_bucket_acl" "s3_bucket_glue_acl" {
  bucket     = aws_s3_bucket.s3_bucket_glue_scripts.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_glue_ownership_controls]
}

resource "aws_s3_bucket_versioning" "s3_bucket_glue_versioning" {
  bucket = aws_s3_bucket.s3_bucket_glue_scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_glue_public_access_block" {
  bucket                  = aws_s3_bucket.s3_bucket_glue_scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_glue_encryption" {
  bucket = aws_s3_bucket.s3_bucket_glue_scripts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_glue_ownership_controls" {
  bucket = aws_s3_bucket.s3_bucket_glue_scripts.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_glue_scripts_bucket_config" {
  bucket = aws_s3_bucket.s3_bucket_glue_scripts.id
  rule {
    id     = "borrar-tmp-glue-jobs"
    status = "Enabled"
    filter {
      prefix = "tmp/"
    }

    expiration {
      days = 15
    }

    noncurrent_version_expiration {
      noncurrent_days = 8
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 5
    }
  }

  rule {
    id     = "delete-markers"
    status = "Enabled"
    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_object" "job_file" {
  bucket       = aws_s3_bucket.s3_bucket_glue_scripts.bucket
  key          = "job_script/glue_job_data_mask_pii.py"
  source       = "${path.root}/templates/job_script/glue_job_data_mask_pii.py"
  etag         = filemd5("${path.root}/templates/job_script/glue_job_data_mask_pii.py")
}