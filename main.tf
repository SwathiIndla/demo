provider "azurerm" {
  features { }
}

resource "azurerm_resource_group" "demo-rm" {
 name = "demo-rm"
 location = "eastus"  
}
resource "tls_private_key" "key-value" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "azurerm_ssh_public_key" "public-key" {
  name       = "example-ssh-key"
  resource_group_name = azurerm_resource_group.demo-rm.name
  location   = azurerm_resource_group.demo-rm.location
  public_key = tls_private_key.key-value.public_key_openssh
}
resource "azurerm_storage_account" "demo-sca" {
  name                     = "sgeaccountname"
  resource_group_name      = "demo-rm"
  location                 = azurerm_resource_group.demo-rm.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "demo-con" {
  name                  = "swaswekav"
  storage_account_name  = azurerm_storage_account.demo-sca.name
  container_access_type = "private"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vm-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo-rm.location
  resource_group_name = azurerm_resource_group.demo-rm.name
}

resource "azurerm_subnet" "subnet11" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.demo-rm.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_public_ip" "public" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.demo-rm.location
  resource_group_name = azurerm_resource_group.demo-rm.name
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "nic1" {
  name                = "vm-nic"
  location            = azurerm_resource_group.demo-rm.location
  resource_group_name = azurerm_resource_group.demo-rm.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet11.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_network_security_group" "nsg1" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.demo-rm.location
  resource_group_name = azurerm_resource_group.demo-rm.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.demo-rm.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
}
resource "azurerm_virtual_machine" "demo-vm" {
  name                  = "rm-vm"
  location              = azurerm_resource_group.demo-rm.location
  resource_group_name   = azurerm_resource_group.demo-rm.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = tls_private_key.key-value.public_key_openssh
    }
  }
  

  provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/testadmin/app.py"  # Replace with the path on the remote instance
    connection {
    type        = "ssh"
    user        = "testadmin"  # Replace with the appropriate username for your EC2 instance
    private_key =  tls_private_key.key-value.private_key_openssh
                     # Replace with the path to your private key
    host        = azurerm_network_interface.nic1.private_ip_address
  }
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/testadmin",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }
  tags = {
    environment = "staging"
  }
}
