# terraform-azurerm-network

Terraform module to manage Azure Virtual Networks, Subnets, Network Security Groups, and Route Tables.

- Creates or references an existing Virtual Network (no data blocks — existing VNet is referenced by its component values)
- Creates one or more subnets within the VNet
- Optionally creates or attaches an existing NSG to each subnet
- Optionally creates or attaches an existing Route Table to each subnet

## Usage

### module.tf

```hcl
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

```

### variables.tf

```hcl
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

```

### module.tf.tfvars

```hcl
networks = {
  "network1" = {
    subscription        = "buildcloudio"
    environment         = "dev"
    usecase             = "test"
    location            = "westeurope"
    resource_group_name = "buildcloudio-dev-registry-rg"
    create_vnet         = true
    vnet_address_space  = ["10.0.0.0/16"]

    subnets = {
      "frontend" = {
        address_prefixes = ["10.0.1.0/24"]
        create_nsg       = true
        nsg_rules = [
          {
            name                       = "allow-https"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          },
          {
            name                       = "allow-http"
            priority                   = 110
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "80"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        ]
        create_route_table = true
        routes = [
          {
            name           = "internet"
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
        ]
      }

      "backend" = {
        address_prefixes = ["10.0.2.0/24"]
        create_nsg       = true
        nsg_rules = [
          {
            name                       = "allow-from-frontend"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "8080"
            source_address_prefix      = "10.0.1.0/24"
            destination_address_prefix = "*"
          }
        ]
        create_route_table = true
        routes             = []
      }

      "containers" = {
        address_prefixes   = ["10.0.3.0/24"]
        create_nsg         = false
        create_route_table = false
        delegation = {
          name         = "aci-delegation"
          service_name = "Microsoft.ContainerInstance/containerGroups"
          actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
        }
      }
    }
  }
}

```

### main.tf

```hcl
terraform {
  #backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.61.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

## Resource Naming

| Resource        | Name Pattern                                              | Example                                    |
|-----------------|-----------------------------------------------------------|--------------------------------------------|
| Virtual Network | `{subscription}-{environment}-{usecase}-vnet`            | `buildcloudio-dev-app-vnet`                |
| Subnet          | `{subscription}-{environment}-{usecase}-{subnet_key}-snet` | `buildcloudio-dev-app-frontend-snet`     |
| NSG             | `{subscription}-{environment}-{usecase}-{subnet_key}-nsg`  | `buildcloudio-dev-app-frontend-nsg`      |
| Route Table     | `{subscription}-{environment}-{usecase}-{subnet_key}-rt`   | `buildcloudio-dev-app-frontend-rt`       |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| subscription | Azure subscription identifier | `string` | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | yes |
| usecase | Use case or service name | `string` | yes |
| location | Azure region | `string` | yes |
| resource_group_name | Resource group for new resources | `string` | yes |
| create_vnet | Whether to create a new VNet | `bool` | no (default: `true`) |
| vnet_address_space | Address space for the new VNet | `list(string)` | when `create_vnet = true` |
| existing_vnet_config | Config object for the existing VNet (`name`, `resource_group`, `subscription_id`) | `object` | when `create_vnet = false` |
| subnets | Map of subnet configurations | `map(object)` | no (default: `{}`) |

### subnets object

| Name | Description | Type | Required |
|------|-------------|------|----------|
| address_prefixes | CIDR blocks for the subnet | `list(string)` | yes |
| delegation | Subnet delegation config (`name`, `service_name`, `actions`) | `object` | no (default: `null`) |
| create_nsg | Create a new NSG for this subnet | `bool` | no (default: `true`) |
| existing_nsg_id | ID of an existing NSG to associate | `string` | when `create_nsg = false` |
| nsg_rules | Security rules for the new NSG | `list(object)` | no (default: `[]`) |
| create_route_table | Create a new route table for this subnet | `bool` | no (default: `true`) |
| existing_route_table_id | ID of an existing route table to associate | `string` | when `create_route_table = false` |
| routes | Routes for the new route table | `list(object)` | no (default: `[]`) |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | The ID of the virtual network |
| vnet_name | The name of the virtual network |
| subnet_ids | Map of subnet keys to their resource IDs |
| subnet_names | Map of subnet keys to their resource names |
| nsg_ids | Map of subnet keys to newly created NSG IDs |
| route_table_ids | Map of subnet keys to newly created route table IDs |
