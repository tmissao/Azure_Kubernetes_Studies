resource "azurerm_network_security_group" "vm" {
  name                = "VM1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "22"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_public_ip" "vm" {
  name = "ServerPublicIp"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Static"
  tags = var.tags
}

resource "azurerm_network_interface" "vm" {
  name = "vm1"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name = "vm1"
    subnet_id = azurerm_subnet.subnets["backend"].id
    public_ip_address_id = azurerm_public_ip.vm.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}

# resource "azurerm_network_interface_security_group_association" "vm" {
#   network_interface_id      = azurerm_network_interface.vm.id
#   network_security_group_id = azurerm_network_security_group.vm.id
# }

data "template_file" "init" {
  template = file("${path.module}/scripts/init.cfg")
}

data "template_file" "shell-script" {
  template = file("${path.module}/scripts/setup.sh")
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.init.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.shell-script.rendered
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name = "Server"
  admin_username = "adminuser"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm.id]
  size = "Standard_B2s"
  custom_data = data.template_cloudinit_config.config.rendered
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  os_disk {
    caching = "None"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}