output "vnet_id" {
  description = "The ID of the virtual network"
  value       = var.create_vnet ? azurerm_virtual_network.vnet[0].id : local.existing_vnet_id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = local.effective_vnet_name
}

output "subnet_ids" {
  description = "Map of subnet keys to their resource IDs"
  value       = { for key, subnet in azurerm_subnet.subnet : key => subnet.id }
}

output "subnet_names" {
  description = "Map of subnet keys to their resource names"
  value       = { for key, subnet in azurerm_subnet.subnet : key => subnet.name }
}

output "nsg_ids" {
  description = "Map of subnet keys to their newly created NSG resource IDs"
  value       = { for key, nsg in azurerm_network_security_group.nsg : key => nsg.id }
}

output "route_table_ids" {
  description = "Map of subnet keys to their newly created route table resource IDs"
  value       = { for key, rt in azurerm_route_table.rt : key => rt.id }
}
