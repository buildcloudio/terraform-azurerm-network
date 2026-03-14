variable "subscription" {
  description = "Azure subscription identifier"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "usecase" {
  description = "Use case or service name for the network resources"
  type        = string
}

variable "location" {
  description = "Azure region for the network resources (e.g., westeurope, eastus)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where new resources will be created"
  type        = string
}

#------------------------------------------------------------------
# Virtual Network
#------------------------------------------------------------------

variable "create_vnet" {
  description = "Whether to create a new virtual network. Set to false to reference an existing one."
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "Address space for the new virtual network. Required when create_vnet is true."
  type        = list(string)
  default     = null
}

variable "existing_vnet_config" {
  description = <<-EOT
    Configuration for referencing an existing virtual network. Required when create_vnet is false.
    The resource ID is constructed from these values — no data blocks are used.

    - name:            Name of the existing virtual network
    - resource_group:  Resource group of the existing virtual network
    - subscription_id: Subscription ID where the existing virtual network resides
  EOT
  type = object({
    name            = string
    resource_group  = string
    subscription_id = string
  })
  default = null
}

#------------------------------------------------------------------
# Subnets, NSGs, and Route Tables
#------------------------------------------------------------------

variable "subnets" {
  description = <<-EOT
    Map of subnets to create. Each subnet key is used in the resource name.
    Each subnet can optionally create or reference an existing NSG and route table.

    - create_nsg: create a new NSG for this subnet (default: true)
    - existing_nsg_id: ID of an existing NSG to associate (used when create_nsg is false)
    - nsg_rules: list of security rules for the new NSG
    - create_route_table: create a new route table for this subnet (default: true)
    - existing_route_table_id: ID of an existing route table (used when create_route_table is false)
    - routes: list of routes for the new route table
  EOT
  type = map(object({
    address_prefixes = list(string)

    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }), null)

    create_nsg      = optional(bool, true)
    existing_nsg_id = optional(string, null)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), [])

    create_route_table      = optional(bool, true)
    existing_route_table_id = optional(string, null)
    routes = optional(list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string, null)
    })), [])
  }))
  default = {}
}
