output "bucket_name" {
  value = data.aws_s3_bucket.uploads.id
}

output "bucket_id" {
  value = data.aws_s3_bucket.uploads.id
}