param location string
param bastion_name string
param pip_bastion_name string
param vnet_hpc_name string
param vnet_hpc_prefix string
param snet_bastion_prefix string
param snet_user_prefix string
param snet_compute_prefix string
param snet_cycle_prefix string

param vm_cycle_nic_name string
param vm_cycle_name string
param vm_cycle_size string
param dataDisks array
param vm_user_nic_name string
param vm_user_name string
param vm_user_size string
param private_dns_zone_name string
param storage_account_name string

@secure()
param adminUsername string
@secure()
param adminPasssword string

resource pipbastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: pip_bastion_name
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionhpc 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastion_name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipbastion.id
          }
          subnet: {
            id: vnethpc.properties.subnets[3].id
          }
        }
      }
    ]
  }
}

resource vnethpc 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnet_hpc_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_hpc_prefix
      ]
    }
    subnets: [
      {
        name: 'snet-user'
        properties: {
          addressPrefix: snet_user_prefix
        }
      }
      {
        name: 'snet-compute'
        properties: {
          addressPrefix: snet_compute_prefix
        }
      }
      {
        name: 'snet-cycle'
        properties: {
          addressPrefix: snet_cycle_prefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: snet_bastion_prefix
        }
      }
    ]
  }
}

resource vmniccycle 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: vm_cycle_nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnethpc.properties.subnets[2].id
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource vmcycle 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vm_cycle_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vm_cycle_size
    }
    storageProfile: {
      imageReference: {
        publisher: 'azurecyclecloud'
        offer: 'azure-cyclecloud'
        sku: 'cyclecloud8'
        version: 'latest'
      }
      dataDisks: [for item in dataDisks: {
        lun: item.lun
        name: item.name
        createOption: item.createOption
        caching: item.caching
        diskSizeGB: item.diskSizeGB
        managedDisk: {
          storageAccountType: item.storageAccountType
        }
        deleteOption: item.deleteOption
        writeAcceleratorEnabled: item.writeAcceleratorEnabled
      }]
      osDisk: {
        osType: 'Linux'
        name: '${vm_cycle_name}_osDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: vm_cycle_name
      adminUsername: adminUsername
      adminPassword: adminPasssword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmniccycle.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
  plan: {
    name: 'cyclecloud8'
    publisher: 'azurecyclecloud'
    product: 'azure-cyclecloud'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource vmnicuser 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: vm_user_nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnethpc.properties.subnets[0].id
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource vmuser 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vm_user_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vm_user_size
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        name: '${vm_user_name}_osDisk'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmnicuser.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    osProfile: {
      computerName: vm_user_name
      adminUsername: adminUsername
      adminPassword: adminPasssword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        provisionVMAgent: true
      }
    }
  }
}

resource cyclecloudlocker 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storage_account_name
  location: location
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    allowCrossTenantReplication: false
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource privatednszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: private_dns_zone_name
  location: 'global'
}

resource vnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privatednszone.name}/vnet-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnethpc.id
    }
    registrationEnabled: false
  }
}

resource privateendpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'pe-${cyclecloudlocker.name}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-${cyclecloudlocker.name}'
        properties: {
          privateLinkServiceId: cyclecloudlocker.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: vnethpc.properties.subnets[2].id
    }
  }
}

resource dnsrecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privatednszone.name}/${cyclecloudlocker.name}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: privateendpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}
