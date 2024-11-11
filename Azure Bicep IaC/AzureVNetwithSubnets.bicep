param VirtualNetworkName string = 'MyVPC'
param loadBalancers_WebTierLB_name string = 'WebTierLB'
param Location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: VirtualNetworkName
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'PublicSubnet1A'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'AppPrivateSubnet1A'
        properties: {
          addressPrefix: '10.0.1.0/24'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'DataPrivateSubnet1A'
        properties: {
          addressPrefix: '10.0.2.0/24'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.3.0/26'
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: '10.0.3.64/26'
        }
      }
    ]
    
  }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2024-01-01' = [for i in range(0, numberOfPublicIPAddresses): {
  name: '${azurepublicIpname}${i + 1}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}]

resource firewallPolicies 'Microsoft.Network/firewallPolicies@2024-01-01' = {
  name: 'FWpolicy'
  location: 'eastus'
  properties: {
    sku: {
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    intrusionDetection: {
      mode: 'Off'
    }
  }
}

resource DefaultDnatRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-01-01' = {
  parent: firewallPolicies
  name: 'DefaultDnatRuleCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'Dnat'
        }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'ToWebVMSS'
            translatedAddress: '10.0.0.6'
            translatedPort: '80'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '135.234.227.207'
            ]
            destinationPorts: [
              '80'
            ]
          }
        ]
        name: 'ToWebTier'
        priority: 200
      }
    ]
  }
}


resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: 'PublicFirewall'
  location: 'eastus'
  zones: ['1','2']
  dependsOn: [
    vnet
    publicIpAddress
    DefaultDnatRuleCollectionGroup
  ]
  properties: {
    ipConfigurations: [
      name: 'FW-pip'
    ]
    firewallPolicy: {
      id: 'FW-policy.id'}
  }
}

resource loadBalancers_WebTierLB_name_resource 'Microsoft.Network/loadBalancers@2024-01-01' = {
  name: loadBalancers_WebTierLB_name
  location: 'eastus'
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'WebFrontLB'
        id: '${loadBalancers_WebTierLB_name_resource.id}/frontendIPConfigurations/WebFrontLB'
        properties: {
          privateIPAddress: '10.0.0.6'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetworks_MyVPC_name_PublicSubnet1A.id
          }
          privateIPAddressVersion: 'IPv4'
        }
        zones: [
          '2'
          '1'
          '3'
        ]
      }
    ]
    backendAddressPools: [
      {
        name: 'WebBackEndLB'
        id: WebBackEndLB.id
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'VNetBicepRG_WebVMSS-nic01-72bd37eeWebVMSS-nic01-defaultIpConfiguration'
              properties: {}
            }
            {
              name: 'VNetBicepRG_WebVMSS-nic01-22f05c6bWebVMSS-nic01-defaultIpConfiguration'
              properties: {}
            }
          ]
        }
      }
    ]
    loadBalancingRules: []
    probes: []
    inboundNatRules: []
    outboundRules: []
    inboundNatPools: []
  }
}
  resource loadBalancer 'Microsoft.Network/loadBalancers@2024-01-01' = {
    name: 'AppLB'
    location:: 'eastus'
    sku: {
      name: 'Standard'
    }
    properties: {
      privateIpAddress: '10.0.1.4'
      privateIpAllocationMethod: 'Dynamic'
      subnet: 'AppPrivateSubnet1A' 
      privateIPAddressVersion: 'IPv4'
    }
    zones:[
      '1','2','3'
    ]
    backendAddressPools: [
      {
        name: 'AppBackEndLB'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: ''
            }
            {
              name: ''
            }
          ]
        }
      }
    ]
  }

  resource vmScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
    name: WebVMSS
    location: 'eastus'
    sku: {
      name: vmSku
      tier: 'Standard'
      capacity: instanceCount
    }
    properties: {
      overprovision: true
      upgradePolicy: {
        mode: 'Automatic'
      }
      virtualMachineProfile: {
        osProfile: {
          computerNamePrefix: WebVMSS
          adminUsername: azureadmin
          adminPassword: Password@123
        }
        networkProfile: {
          networkInterfaceConfigurations: [
            {
              name: WebVMSS-nic
              properties: {
                primary: true
                ipConfigurations: [
                  {
                    name: ipConfigName
                    properties: {
                      subnet: {
                        id: 'PublicSubnet1A'
                      }
                      loadBalancerBackendAddressPools: [
                        {
                          id: 'WebTierLB'
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }

  resource vmScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
    name: AppVMSS
    location: 'eastus'
    sku: {
      name: vmSku
      tier: 'Standard'
      capacity: instanceCount
    }
    properties: {
      overprovision: true
      upgradePolicy: {
        mode: 'Automatic'
      }
      virtualMachineProfile: {
        osProfile: {
          computerNamePrefix: AppVMSS
          adminUsername: azureadmin
          adminPassword: Password@123
        }
        networkProfile: {
          networkInterfaceConfigurations: [
            {
              name: AppVMSS-nic
              properties: {
                primary: true
                ipConfigurations: [
                  {
                    name: ipConfigName
                    properties: {
                      subnet: {
                        id: 'AppPrivateSubnet1A'
                      }
                      loadBalancerBackendAddressPools: [
                        {
                          id: 'AppTierLB'
                        }
                      ]
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }
}

