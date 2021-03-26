
##########################################################
## Install DNS role on onprem and AZ DNS servers
##########################################################

resource "azurerm_virtual_machine_extension" "install-dns-onprem-dc" {

  name                 = "install-dns-onprem-dc"
  virtual_machine_id   = azurerm_virtual_machine.onprem-dns-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted Install-WindowsFeature -Name DNS -IncludeAllSubFeature -IncludeManagementTools; Add-DnsServerForwarder -IPAddress 8.8.8.8 -PassThru; exit 0"
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "install-dns-az-dc" {

  name                 = "install-dns-az-dc"
  virtual_machine_id   = azurerm_virtual_machine.az-dns-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted Install-WindowsFeature -Name DNS -IncludeAllSubFeature -IncludeManagementTools; exit 0"
    }
SETTINGS
}

##########################################################
## Install IIS role on onprem and AZ servers
##########################################################

resource "azurerm_virtual_machine_extension" "install-iis-onprem-vm" {
    
  name                 = "install-iis-onprem-vm"
  virtual_machine_id   = azurerm_virtual_machine.onprem-mgmt-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "install-iis-az-mgmt-vm" {
    
  name                 = "install-iis-az-mgmt-vm"
  virtual_machine_id   = azurerm_virtual_machine.az-mgmt-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "install-iis-az-srv-vm" {
    
  name                 = "install-iis-az-srv-vm"
  virtual_machine_id   = azurerm_virtual_machine.az-srv-vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

   settings = <<SETTINGS
    {
        "commandToExecute":"powershell -ExecutionPolicy Unrestricted Add-WindowsFeature Web-Server; powershell -ExecutionPolicy Unrestricted Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"
    }
SETTINGS
}
