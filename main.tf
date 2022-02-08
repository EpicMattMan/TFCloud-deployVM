provider "azurerm" {
  version =  "2.66.0"
  
  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.clientSecret
  tenant_id = var.tenant_id
  
  features{}
  
}

resource "azurerm_resource_group" "rg" {
  name =var.rgName
  location = var.location
}

# Create virtual network
resource "azurerm_virtual_network" "TFCNet" {
    name                = "TFC-VNet1"
    address_space       = ["10.1.0.0/16"]
    location            =  azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name 

    tags = {
        environment = "TFC test"
    }
}

# Create subnet
resource "azurerm_subnet" "subnet1" {
    name                 = "TFCSubnet"
    resource_group_name = azurerm_resource_group.rg.name  
    virtual_network_name = azurerm_virtual_network.TFCNet.name
    address_prefix       = "10.1.1.0/24"
}


#Deploy Public IP
resource "azurerm_public_ip" "pip1" {
  name                = "TFC-pip1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name  
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

#Create NIC
resource "azurerm_network_interface" "nic1" {
  name                = "TFC-TestVM-Nic"  
  location            = azurerm_resource_group.rg.location  
  resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet1.id 
    private_ip_address_allocation  = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
}

#Create Boot Diagnostic Account
resource "azurerm_storage_account" "sa" {
  name                     = "tfcdiagnosticstore1191" 
  resource_group_name      = azurerm_resource_group.rg.name  
  location                 = azurerm_resource_group.rg.location
   account_tier            = "Standard"
   account_replication_type = "LRS"

   tags = {
    environment = "TFC test"
   }
  }

#Create Virtual Machine
resource "azurerm_virtual_machine" "TFCVM" {
  name                  = "TF-TestVM-1"  
  location              = azurerm_resource_group.rg.location 
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_B1s"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk1"
    disk_size_gb      = "128"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "TFC-AwesomeVM1" 
    admin_username = "azureuser"
    admin_password = "Password12345!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

boot_diagnostics {
        enabled     = "true"
        storage_uri = azurerm_storage_account.sa.primary_blob_endpoint
    }
}
