variable "networks" {
  description = "Map of network configurations to deploy"
  type = map(object({
    subscription        = string
    environment         = string
    usecase             = string
    location            = string
    resource_group_name = string

    create_vnet        = optional(bool, true)
    vnet_address_space = optional(list(string), null)

    existing_vnet_config = optional(object({
      name            = string
      resource_group  = string
      subscription_id = string
    }), null)

    subnets = map(object({
      address_prefixes = list(string)

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
  }))
}
