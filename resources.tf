data "aws_ami" "ubuntu-ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

}

data "aws_key_pair" "auth-key" { 
  key_name = "${var.key_name}" 
}
data "aws_instance" "master_node" {
  instance_id = aws_instance.master-node.id
} 

data "aws_rds_engine_version" "test" {
  engine = "postgres"
}

output "testt000" {
  value = tolist(data.aws_rds_engine_version.test.valid_major_targets)[0]
} 
 
# Output the public IPs of the instances
output "master_node_public_ip" {
  value = "ssh root@${aws_instance.master-node.public_ip}"
}

output "worker_node_public_ip" {
  value = "ssh root@${aws_instance.worker-node.public_ip}"
}