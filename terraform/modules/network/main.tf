module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "~> 5.0" 

    create_vpc = var.create_vpc
    name = var.name
    

    cidr = var.cidr
    azs = var.azs

    enable_dns_hostnames                    = var.enable_dns_hostnames
    enable_dns_support                      = var.enable_dns_support
    enable_network_address_usage_metrics    = var.enable_network_address_usage_metrics
    

    public_subnets   = var.public_subnets
    private_subnets  = var.private_subnets
    database_subnets = var.database_subnets

    private_subnet_names              = var.private_subnet_names
    private_subnet_suffix             = var.private_subnet_suffix
    create_private_nat_gateway_route  = var.create_private_nat_gateway_route

    map_public_ip_on_launch             = var.map_public_ip_on_launch
    public_subnet_names                 = var.public_subnet_names
    public_subnet_suffix                = var.public_subnet_suffix

    database_subnet_names                   = var.database_subnet_names
    database_subnet_suffix                  = var.database_subnet_suffix
    create_database_subnet_route_table      = var.create_database_subnet_route_table
    create_database_internet_gateway_route = var.create_database_internet_gateway_route
    create_database_nat_gateway_route       = var.create_database_nat_gateway_route
    create_database_subnet_group            = var.create_database_subnet_group
    database_subnet_group_name              = var.database_subnet_group_name

    public_dedicated_network_acl   = var.public_dedicated_network_acl
    public_inbound_acl_rules       = var.public_inbound_acl_rules
    public_outbound_acl_rules      = var.public_outbound_acl_rules

    private_dedicated_network_acl  = var.private_dedicated_network_acl
    private_inbound_acl_rules      = var.private_inbound_acl_rules
    private_outbound_acl_rules     = var.private_outbound_acl_rules

    database_dedicated_network_acl = var.database_dedicated_network_acl
    database_inbound_acl_rules     = var.database_inbound_acl_rules
    database_outbound_acl_rules    = var.database_outbound_acl_rules

    create_igw                          = var.create_igw
    enable_nat_gateway                  = var.enable_nat_gateway
    single_nat_gateway                  = var.single_nat_gateway
    nat_gateway_destination_cidr_block  = var.nat_gateway_destination_cidr_block

    enable_flow_log                       = var.enable_flow_log
    vpc_flow_log_iam_role_name            = var.vpc_flow_log_iam_role_name
    flow_log_max_aggregation_interval     = var.flow_log_max_aggregation_interval
    create_flow_log_cloudwatch_log_group = var.create_flow_log_cloudwatch_log_group
    create_flow_log_cloudwatch_iam_role  = var.create_flow_log_cloudwatch_iam_role

    tags                        = var.tags
    vpc_tags                    = var.vpc_tags
    public_subnet_tags          = var.public_subnet_tags
    public_route_table_tags     = var.public_route_table_tags
    public_acl_tags             = var.public_acl_tags
    private_subnet_tags         = var.private_subnet_tags
    private_route_table_tags    = var.private_route_table_tags
    private_acl_tags            = var.private_acl_tags
    database_subnet_tags        = var.database_subnet_tags
    database_route_table_tags   = var.database_route_table_tags
    database_subnet_group_tags  = var.database_subnet_group_tags
    database_acl_tags           = var.database_acl_tags
    igw_tags                    = var.igw_tags
    nat_gateway_tags            = var.nat_gateway_tags
    nat_eip_tags                = var.nat_eip_tags

}

