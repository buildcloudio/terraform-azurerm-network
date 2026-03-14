module "network" {
  for_each = var.networks
  source   = "../"

  subscription        = each.value.subscription
  environment         = each.value.environment
  usecase             = each.value.usecase
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  create_vnet        = each.value.create_vnet
  vnet_address_space = each.value.vnet_address_space

  existing_vnet_config = each.value.existing_vnet_config

  subnets = each.value.subnets
}
