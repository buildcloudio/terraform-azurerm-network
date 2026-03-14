networks = {
  "network1" = {
    subscription        = "buildcloudio"
    environment         = "dev"
    usecase             = "test"
    location            = "westeurope"
    resource_group_name = "buildcloudio-dev-test-rg"
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
    }
  }
}
