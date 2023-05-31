module "workers" {
  for_each = local.workers_cluster
  source   = "terraform-aws-modules/ec2-instance/aws"
  version  = "~> 4.3.0"
  name     = "${each.value.name}-${var.suffix}"
  ami      = each.value.ami

  instance_type = each.value.instance_type
  key_name      = aws_key_pair.public_key.key_name

  monitoring                  = false
  associate_public_ip_address = true
  vpc_security_group_ids = [
    module.kubernetes_workers_sg.security_group_id,
    module.armonik_workers_sg.security_group_id,
    module.calico_network_sg.security_group_id,
    module.flannel_network_sg.security_group_id,
  ]
  subnet_id  = module.vpc.public_subnets[0]
  tags       = var.common_tags
  depends_on = [module.vpc, module.kubernetes_workers_sg]
}
