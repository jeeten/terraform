# output "public_ip" {
#     description = "This is the public ip"
#     sensitive = false

#     value = aws_instance.my_instance.public_ip
# }

output "dns_name" {
    value = aws_alb.my-alb.dns_name
}