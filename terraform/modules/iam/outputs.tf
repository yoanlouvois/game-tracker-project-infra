output "front_instance_profile_name" {
  value = aws_iam_instance_profile.front_ec2.name
}

output "back_instance_profile_name" {
  value = aws_iam_instance_profile.back_ec2.name
}