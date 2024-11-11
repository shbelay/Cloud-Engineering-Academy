param Location string = resourceGroup().location
param VirtualNetworkName string = '3TierVNet'
param WebTierLoadBalancerName string = 'WebTierLB'
param AppTierLoadBalancerName string = 'AppTierLB'
param WebTierVMSSname string = 'WebTierVMSS'
param WebTierVMSS_VM1name string = 'WebTierVMSS_VM1'
param WebTierVMSS_VM2name string = 'WebTierVMSS_VM2'
param WebTierVMSSautoScaleName string = 'WebTierVMSSautoScale'
param AppTierVMSSname string = 'AppTierVMSS'
param AppTierVMSS_VM1name string = 'AppTierVMSS_VM1'
param AppTierVMSS_VM2name string = 'AppTierVMSS_VM2'
param AppTierVMSSautoScaleName string = 'AppTierVMSSautoScale'

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

resource WebTierVMSSname_resource 'Microsoft.Compute/virtualMachineScaleSets@2024-07-01' = {
  name: WebTierVMSSname
  location: 'eastus'
  sku: {
    name: 'Standard_B2s'
    tier: 'Standard'
    capacity: 2
  }
  zones: [
    '1'
    '2'
  ]
  properties: {
    singlePlacementGroup: false
    orchestrationMode: 'Flexible'
    upgradePolicy: {
      mode: 'Manual'
    }
    scaleInPolicy: {
      rules: [
        'Default'
      ]
      forceDeletion: false
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'webtiervm'
        adminUsername: 'shbelay'
        windowsConfiguration: {
          provisionVMAgent: true
          enableAutomaticUpdates: true
          patchSettings: {
            patchMode: 'AutomaticByOS'
            assessmentMode: 'ImageDefault'
            enableHotpatching: false
          }
        }
        secrets: []
        allowExtensionOperations: true
        requireGuestProvisionSignal: true
      }
      storageProfile: {
        osDisk: {
          osType: 'Windows'
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          deleteOption: 'Delete'
          diskSizeGB: 127
        }
        imageReference: {
          publisher: 'microsoftwindowsdesktop'
          offer: 'windows-11'
          sku: 'win11-22h2-ent'
          version: 'latest'
        }
        diskControllerType: 'SCSI'
      }
      networkProfile: {
        networkApiVersion: '2020-11-01'
        networkInterfaceConfigurations: [
          {
            name: 'WebVMSS-nic01'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              disableTcpStateTracking: false
              enableIPForwarding: false
              auxiliaryMode: 'None'
              auxiliarySku: 'None'
              deleteOption: 'Delete'
              ipConfigurations: [
                {
                  name: 'WebVMSS-nic01-defaultIpConfiguration'
                  properties: {
                    privateIPAddressVersion: 'IPv4'
                    subnet: {id: }
                
                    
                    primary: true
                    applicationSecurityGroups: []
                    loadBalancerBackendAddressPools: [
                      {
                        id: '${loadBalancers_PublicLB_externalid}/backendAddressPools/bepool'
                      }
                    ]
                    applicationGatewayBackendAddressPools: []
                  }
                }
              ]
              networkSecurityGroup: {
                id: networkSecurityGroups_basicNsgWebVMSS_nic01_name_resource.id
              }
              dnsSettings: {
                dnsServers: []
              }
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
      extensionProfile: {
        extensions: []
      }
      licenseType: 'Windows_Client'
      securityProfile: {
        uefiSettings: {
          secureBootEnabled: true
          vTpmEnabled: true
        }
        securityType: 'TrustedLaunch'
      }
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    zoneBalance: false
    platformFaultDomainCount: 1
    constrainedMaximumCapacity: false
  }
}

resource WebTierVMSSautoScaleName_resource 'microsoft.insights/autoscalesettings@2022-10-01' = {
  name: WebTierVMSSautoScaleName
  location: 'eastus'
  properties: {
    profiles: [
      {
        name: 'Default condition'
        capacity: {
          minimum: '2'
          maximum: '20'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: WebTierVMSSname
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: '80'
              dividePerInstance: false
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: WebTierVMSSname
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: '20'
              dividePerInstance: false
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
    enabled: false
    name: WebTierVMSSautoScaleName
    targetResourceUri: WebTierVMSSname
    predictiveAutoscalePolicy: {
      scaleMode: 'Disabled'
    }
  }
}

resource WebTierVMSS_VM1name_resource 'Microsoft.Compute/virtualMachineScaleSets/virtualMachines@2024-07-01' = {
  parent: WebTierVMSSname_resource
  name: WebTierVMSS_VM1name
  location: 'eastus'
  zones: [
    '1'
  ]
}

resource virtualMachineScaleSets_WebTierVMSS_name_virtualMachineScaleSets_WebTierVMSS_name_18552cbc 'Microsoft.Compute/virtualMachineScaleSets/virtualMachines@2024-07-01' = {
  parent: WebTierVMSSname_resource
  name: WebTierVMSS_VM2name
  location: 'eastus'
  zones: [
    '2'
  ]
}
