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
  source   = "buildcloudio/network/azurerm"
  version  = "x.x.x"

  subscription        = var.subscription
  environment         = var.environment
  usecase             = var.usecase
  location            = var.location
  resource_group_name = var.resource_group_name

  create_vnet        = true
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    "frontend" = {
      address_prefixes = ["10.0.1.0/24"]
      create_nsg       = true
      nsg_rules = [
        {
          name                   = "allow-https"
          priority               = 100
          direction              = "Inbound"
          access                 = "Allow"
          protocol               = "Tcp"
          destination_port_range = "443"
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
      address_prefixes        = ["10.0.2.0/24"]
      create_nsg              = false
      existing_nsg_id         = "/subscriptions/.../networkSecurityGroups/my-nsg"
      create_route_table      = false
      existing_route_table_id = "/subscriptions/.../routeTables/my-rt"
    }
  }
}
```

### Referencing an existing VNet (no data blocks)

```hcl
module "network" {
  source   = "buildcloudio/network/azurerm"
  version  = "x.x.x"

  subscription        = var.subscription
  environment         = var.environment
  usecase             = var.usecase
  location            = var.location
  resource_group_name = var.resource_group_name

  create_vnet = false
  existing_vnet_config = {
    name            = "my-existing-vnet"
    resource_group  = "my-network-rg"
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }

  subnets = {
    "app" = {
      address_prefixes   = ["10.1.1.0/24"]
      create_nsg         = true
      create_route_table = true
    }
  }
}
```

### variables.tf

```hcl
variable "subscription" { type = string }
variable "environment"  { type = string }
variable "usecase"      { type = string }
variable "location"     { type = string }
variable "resource_group_name" { type = string }
```

### module.tf.tfvars

```hcl
subscription        = "buildcloudio"
environment         = "dev"
usecase             = "app"
location            = "westeurope"
resource_group_name = "buildcloudio-dev-app-rg"
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
