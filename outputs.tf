output "chartio-ec2-public-ip" {
  value = "${aws_instance.chartio-ec2.public_ip}"
}

output "chartio-rds-endpoint" {
  value = "${aws_db_instance.chartio-rds.endpoint}"
}
