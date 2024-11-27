output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_glob_state.arn
}
output "dynamodb_name" {
  value = aws_dynamodb_table.terraform_glob_state.name
}

output "dns_name" {
    value = aws_alb.my-alb.dns_name
}