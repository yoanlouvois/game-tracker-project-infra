output "front_asg_name" {
  value = aws_autoscaling_group.front.name
}

output "back_asg_name" {
  value = aws_autoscaling_group.back.name
}