terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. The Resource Group
resource "azurerm_resource_group" "piano_rg" {
  name     = "piano-project-rg"
  location = "Central India"
}

# 2. Networking
resource "azurerm_virtual_network" "vnet" {
  name                = "piano-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.piano_rg.location
  resource_group_name = azurerm_resource_group.piano_rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.piano_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 3. Public IP for the Web App
resource "azurerm_public_ip" "public_ip" {
  name                = "piano-public-ip"
  resource_group_name  = azurerm_resource_group.piano_rg.name
  location            = azurerm_resource_group.piano_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 4. Network Security Group (Firewall)
resource "azurerm_network_security_group" "nsg" {
  name                = "piano-nsg"
  location            = azurerm_resource_group.piano_rg.location
  resource_group_name = azurerm_resource_group.piano_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  } # <--- This brace was missing!

  security_rule {
    name                       = "Grafana"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 5. The Virtual Machine (The Server)
resource "azurerm_linux_virtual_machine" "piano_vm" {
  name                = "piano-server"
  resource_group_name = azurerm_resource_group.piano_rg.name
  location            = azurerm_resource_group.piano_rg.location
  size                = "Standard_D2s_v3" # Cheap tier
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_password                  = "YourPassword12345!" # CHANGE THIS
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# (Networking Glue for the VM)
resource "azurerm_network_interface" "nic" {
  name                = "piano-nic"
  location            = azurerm_resource_group.piano_rg.location
  resource_group_name = azurerm_resource_group.piano_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "connect_nsg_to_nic" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 6. Azure SQL Database (To store your bookings)
resource "azurerm_mssql_server" "sql_server" {
  name                         = "piano-db-server-${random_integer.ri.result}"
  resource_group_name          = azurerm_resource_group.piano_rg.name
  location                     = azurerm_resource_group.piano_rg.location
  version                      = "12.0"
  administrator_login          = "dbadmin"
  administrator_login_password = "YourPassword123!" # CHANGE THIS
}

resource "azurerm_mssql_database" "piano_db" {
  name           = "pianobookings"
  server_id      = azurerm_mssql_server.sql_server.id
  sku_name       = "Basic"
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

# Allow Azure Services (like your VM/App) to talk to the SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Output the new server name so we don't have to guess it
output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

