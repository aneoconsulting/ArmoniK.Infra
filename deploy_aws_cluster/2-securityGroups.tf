locals {
  #node_port = range(30000-32768)
  #armonik_node_ports_tcp = [1081, 6379, 5672, 8161, 27017, 5001, 8080, 8081, 2379, 2380, 80, 53, 9153]
  armonik_node_ports_tcp = [5000, 5001]
  #armonik_node_ports_udp = [8285, 53, 9153]
  armonik_node_ports_udp = []

  kubernetes_master_node_ports_tcp  = [8472, 6443, 443, 2379, 2380, 10250, 10251, 10252, 10259, 10257, 4194]
  kubernetes_worker_node_ports_tcp  = [{ from_port = 443, to_port = 443 }, { from_port = 30000, to_port = 32767 }]
  kubernetes_client_access_port_tcp = [6443]


  calico_node_ports_tcp  = [179, 5473, 9098, 9099, 443, 6443]
  calico_node_ports_udp  = [4789, 51820, 51821]
  flannel_node_ports_udp = [8285, 8472]

  ingress_with_cidr_blocks_armonik_tcp = [
    for port in local.armonik_node_ports_tcp : {
      from_port   = port
      to_port     = port
      protocol    = "tcp"
      description = "ArmoniK services"
      #cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
      cidr_blocks = join(",", ["0.0.0.0/0"])
    }
  ]

  ingress_with_cidr_blocks_armonik_udp = [
    for port in local.armonik_node_ports_udp : {
      from_port   = port
      to_port     = port
      protocol    = "udp"
      description = "ArmoniK services"
      #cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
      cidr_blocks = join(",", ["0.0.0.0/0"])
    }
  ]

  ingress_with_cidr_blocks_kubernetes_client_tcp = [
    for port in local.kubernetes_client_access_port_tcp : {
      from_port   = port
      to_port     = port
      protocol    = "tcp"
      description = "kubernetes client access"
      #cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
      cidr_blocks = join(",", ["0.0.0.0/0"])
    }
  ]

  ingress_with_cidr_blocks_kubernetes_master = [
    for port in local.kubernetes_master_node_ports_tcp : {
      from_port   = port
      to_port     = port
      protocol    = "tcp"
      description = "kubernetes master ports (control-plane)"
      cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
      #cidr_blocks = join(",", ["0.0.0.0/0"])
    }
  ]

  ingress_with_cidr_blocks_kubernetes_worker = [
    for port_range in local.kubernetes_worker_node_ports_tcp : {
      from_port   = port_range.from_port
      to_port     = port_range.to_port
      protocol    = "tcp"
      description = "kubernetes worker ports (worker nodes)"
      #cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
      cidr_blocks = join(",", ["0.0.0.0/0"]) # When we will have a 5000/5001 'LoadBalancer' acces to the cluster, we could remove ingress 'nodePort' (30000-32768) access
    }
  ]

  ingress_with_cidr_blocks_calico = concat(
    [
      for port in local.calico_node_ports_tcp : {
        from_port   = port
        to_port     = port
        protocol    = "tcp"
        description = "calico ports tcp"
        cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
        #cidr_blocks = join(",", ["0.0.0.0/0"])
      }
    ],
    [
      for port in local.flannel_node_ports_udp : {
        from_port   = port
        to_port     = port
        protocol    = "udp"
        description = "calico udp ports"
        cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
        #cidr_blocks = join(",", ["0.0.0.0/0"])
      }
    ]
  )

  ingress_with_cidr_blocks_flannel = [
    for port_range in local.kubernetes_worker_node_ports_tcp : {
      from_port   = port_range.from_port
      to_port     = port_range.to_port
      protocol    = "udp"
      description = "flannel udp ports"
      cidr_blocks = join(",", module.vpc.public_subnets_cidr_blocks)
      #cidr_blocks = join(",", ["0.0.0.0/0"])
    }
  ]

}

module "kubernetes_workers_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "kubernetes ports-${var.suffix}"
  description = "Security group for kubernetes"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules & CIDR Blocks
  ingress_rules       = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags         = var.common_tags

  ingress_with_cidr_blocks = concat(
    local.ingress_with_cidr_blocks_kubernetes_worker,
    local.ingress_with_cidr_blocks_kubernetes_client_tcp
  )
}

module "kubernetes_master_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "armonik_services_sg-${var.suffix}"
  description = "Security group for accessing armonik services"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules & CIDR Blocks
  ingress_rules       = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags         = var.common_tags

  ingress_with_cidr_blocks = concat(
    local.ingress_with_cidr_blocks_kubernetes_master,
    local.ingress_with_cidr_blocks_kubernetes_client_tcp
  )
}

module "armonik_workers_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "armonik_services_sg-${var.suffix}"
  description = "Security group for accessing armonik services"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules & CIDR Blocks
  ingress_rules       = ["ssh-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  egress_rules = ["all-all"]
  tags         = var.common_tags

  ingress_with_cidr_blocks = concat(
    local.ingress_with_cidr_blocks_armonik_tcp,
    local.ingress_with_cidr_blocks_armonik_udp
  )
}

module "calico_network_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "calico_sg-${var.suffix}"
  description = "Security group for Calico networking"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules & CIDR Blocks
  #ingress_rules       = ["ssh-tcp"]
  #ingress_rules       = ["all-all"]
  #ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  #egress_rules = ["all-all"]
  tags = var.common_tags

  ingress_with_cidr_blocks = concat(
    local.ingress_with_cidr_blocks_calico
  )
}

module "flannel_network_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "4.17.1"
  name        = "flannel_sg-${var.suffix}"
  description = "Security group for flannel networking"
  vpc_id      = module.vpc.vpc_id

  # Ingress Rules & CIDR Blocks
  #ingress_rules       = ["ssh-tcp"]
  #ingress_rules       = ["all-all"]
  #ingress_cidr_blocks = ["0.0.0.0/0"]
  # Egress Rule - all-all open
  #egress_rules = ["all-all"]
  tags = var.common_tags

  ingress_with_cidr_blocks = concat(
    local.ingress_with_cidr_blocks_flannel
  )
}
