#------------------------------------------------------------------
# Virtual Network
#------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  count               = var.create_vnet ? 1 : 0
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
}

#------------------------------------------------------------------
# Subnets
#------------------------------------------------------------------

resource "azurerm_subnet" "subnet" {
  for_each             = var.subnets
  name                 = lower("${var.subscription}-${var.environment}-${var.usecase}-${each.key}-snet")
  resource_group_name  = local.effective_vnet_rg
  virtual_network_name = local.effective_vnet_name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }

  depends_on = [azurerm_virtual_network.vnet]
}

#------------------------------------------------------------------
# Network Security Groups
#------------------------------------------------------------------

resource "azurerm_network_security_group" "nsg" {
  for_each = {
    for key, subnet in var.subnets : key => subnet
    if subnet.create_nsg
  }
  name                = lower("${var.subscription}-${var.environment}-${var.usecase}-${each.key}-nsg")
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "rule" {
  for_each = local.nsg_rules_flat

  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.subnet_key].name

  name                       = each.value.name
  priority                   = each.value.priority
  direction                  = each.value.direction
  access                     = each.value.access
  protocol                   = each.value.protocol
  source_port_range          = each.value.source_port_range
  destination_port_range     = each.value.destination_port_range
  source_address_prefix      = each.value.source_address_prefix
  destination_address_prefix = each.value.destination_address_prefix
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = {
    for key, subnet in var.subnets : key => subnet
    if subnet.create_nsg || subnet.existing_nsg_id != null
  }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = each.value.create_nsg ? azurerm_network_security_group.nsg[each.key].id : each.value.existing_nsg_id
}

#------------------------------------------------------------------
# Route Tables
#------------------------------------------------------------------

resource "azurerm_route_table" "rt" {
  for_each = {
    for key, subnet in var.subnets : key => subnet
    if subnet.create_route_table
  }
  name                = lower("${var.subscription}-${var.environment}-${var.usecase}-${each.key}-rt")
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_route" "route" {
  for_each = local.routes_flat

  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.rt[each.value.subnet_key].name

  name                   = each.value.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}

resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = {
    for key, subnet in var.subnets : key => subnet
    if subnet.create_route_table || subnet.existing_route_table_id != null
  }

  subnet_id      = azurerm_subnet.subnet[each.key].id
  route_table_id = each.value.create_route_table ? azurerm_route_table.rt[each.key].id : each.value.existing_route_table_id
}

#------------------------------------------------------------------
