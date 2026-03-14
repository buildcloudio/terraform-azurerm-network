locals {
  vnet_name           = lower("${var.subscription}-${var.environment}-${var.usecase}-vnet")
  effective_vnet_name = var.create_vnet ? local.vnet_name : var.existing_vnet_config.name
  effective_vnet_rg   = var.create_vnet ? var.resource_group_name : var.existing_vnet_config.resource_group

  # Construct the existing VNet resource ID from its component values (no data blocks needed)
  existing_vnet_id = var.create_vnet ? null : "/subscriptions/${var.existing_vnet_config.subscription_id}/resourceGroups/${var.existing_vnet_config.resource_group}/providers/Microsoft.Network/virtualNetworks/${var.existing_vnet_config.name}"

  # Flatten NSG rules across all subnets for use with azurerm_network_security_rule
  nsg_rules_flat = {
    for pair in flatten([
      for subnet_key, subnet in var.subnets : [
        for rule in (subnet.create_nsg ? subnet.nsg_rules : []) : {
          key        = "${subnet_key}-${rule.name}"
          subnet_key = subnet_key
          rule       = rule
        }
      ]
    ]) : pair.key => merge(pair.rule, { subnet_key = pair.subnet_key })
  }

  # Flatten routes across all subnets for use with azurerm_route
  routes_flat = {
    for pair in flatten([
      for subnet_key, subnet in var.subnets : [
        for route in (subnet.create_route_table ? subnet.routes : []) : {
          key        = "${subnet_key}-${route.name}"
          subnet_key = subnet_key
          route      = route
        }
      ]
    ]) : pair.key => merge(pair.route, { subnet_key = pair.subnet_key })
  }
}
