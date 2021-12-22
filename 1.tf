terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}

#for_each = {
#  machine-1 = { addr = "10.1.1.0/24", key = "~/.ssh/key1.pub" },
#  machine-2 = { addr = "10.1.2.0/24", key = "~/.ssh/key2.pub" }
#}
variable "machines" {
  type = map(any)
  default = {
    machine-1 = {
      addr = "10.1.1.0/24",
      key  = "~/.ssh/key1.pub"
    },
    machine-2 = {
      addr = "10.1.2.0/24",
      key  = "~/.ssh/key2.pub"
    }
  }
}
locals {
  env_variables_prod = {
    DOCKER_REGISTRY_SERVER_URL      = "testregk8s.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME = "testRegK8s"
    DOCKER_REGISTRY_SERVER_PASSWORD = "GSmPiVOGUT/D01OZCGYdy4fn=WOSZsYR"
  }
  env_variables_staging = {
    DOCKER_REGISTRY_SERVER_URL      = "testregk8s.azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME = "testRegK8s"
    DOCKER_REGISTRY_SERVER_PASSWORD = "GSmPiVOGUT/D01OZCGYdy4fn=WOSZsYR"
  }
}

resource "azurerm_resource_group" "myterraformgroup" {
  name     = "Ansible-test"
  location = "eastus"
}
resource "azurerm_resource_group" "ansible-tmp" {
  name     = "Ansible-tmp-vm"
  location = "eastus"
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  tags = {
    environment = "Ansible Demo"
  }
}
resource "azurerm_virtual_network" "ansible-tmp-vnet" {
  name                = "ansible-tmp-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.ansible-tmp.name
  tags = {
    environment = "Ansible Demo"
  }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet1" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.myterraformgroup.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_subnet" "ansible-tmp-subnet" {
  for_each             = var.machines
  name                 = "ansible-tmp-subnet-${each.key}"
  resource_group_name  = azurerm_resource_group.ansible-tmp.name
  virtual_network_name = azurerm_virtual_network.ansible-tmp-vnet.name
  address_prefixes     = [each.value["addr"]]
}

# Create public IPs

resource "azurerm_public_ip" "myterraformpublicip" {
  name                = "myPublicIP"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "unique-vm-vm-22"
  tags = {
    environment = "Ansible Demo"
  }
}
resource "azurerm_public_ip" "ansible-tmp-pip" {
  for_each            = var.machines
  name                = "ansible-tmp-pip-${each.key}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.ansible-tmp.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Ansible Demo"
  }
}





# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
  name                = "NSG-web-1"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name
  security_rule {
    name                       = "SSH"
    priority                   = 937
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Http"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https_port"
    priority                   = 998
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "Ansible Demo"
  }
}

resource "azurerm_network_security_group" "ansible-tmp-nsg" {
  for_each            = var.machines
  name                = "ansible-nsg-${each.key}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.ansible-tmp.name
  security_rule {
    name                       = "SSH"
    priority                   = 937
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Http"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https_port"
    priority                   = 998
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {
    environment = "Ansible Demo"
  }
}



# Create network interface
resource "azurerm_network_interface" "myterraformnic1" {
  name                = "myNIC1"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.myterraformgroup.name

  ip_configuration {
    name                          = "web-ni-conf-1"
    subnet_id                     = azurerm_subnet.myterraformsubnet1.id
    private_ip_address            = "10.0.1.4"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
  }

  tags = {
    environment = "Ansible Demo"
  }
}

resource "azurerm_network_interface" "ansible-tmp-nic" {
  for_each            = var.machines
  name                = "ansible-tmp-nic-${each.key}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.ansible-tmp.name

  ip_configuration {
    name      = "ansible-tmp-web-ni-conf-${each.key}"
    subnet_id = azurerm_subnet.ansible-tmp-subnet[each.key].id
    #private_ip_address            = "10.0.1.4"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ansible-tmp-pip[each.key].id
  }

  tags = {
    environment = "Ansible Demo"
  }
}


# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.myterraformnic1.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}
resource "azurerm_network_interface_security_group_association" "ansible-tmp-nsg-associat" {
  for_each                  = var.machines
  network_interface_id      = azurerm_network_interface.ansible-tmp-nic[each.key].id
  network_security_group_id = azurerm_network_security_group.ansible-tmp-nsg[each.key].id
}
# Create virtual machine
resource "azurerm_linux_virtual_machine" "myterraformvm1" {
  name                  = "myVM1"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.myterraformgroup.name
  network_interface_ids = [azurerm_network_interface.myterraformnic1.id]
  size                  = "Standard_b1s"
  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_data                     = base64encode(file("init.sh"))
  computer_name                   = "myvm1"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  connection {
    type        = "ssh"
    user        = "azureuser"
    private_key = file("~/.ssh/id_rsa")
    host        = "unique-vm-vm-22.eastus.cloudapp.azure.com"
  }
  provisioner "remote-exec" {
    #    command = "sudo mkdir /home/azureuser/ans-test/"
    inline = ["mkdir /home/azureuser/ans-test/"]
  }
  provisioner "file" {
    source      = "./ansible-dir/"
    destination = "/home/azureuser/"
#    destination = "/home/azureuser/ans-test/"
  }
}

resource "azurerm_linux_virtual_machine" "ansible-tmp-vm" {
  for_each              = var.machines
  name                  = "ansible-tmp-vm-${each.key}"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.ansible-tmp.name
  network_interface_ids = [azurerm_network_interface.ansible-tmp-nic[each.key].id]
  size                  = "Standard_b1s"
  os_disk {
    name                 = "myOsDisk-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  #  custom_data                     = base64encode(file("init.sh"))
  computer_name                   = "ansible-tmp-${each.key}"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file(each.value["key"])
  }

}
