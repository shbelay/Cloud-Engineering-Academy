param VirtualNetworkName string = 'BicepVNet'
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
        name: 'Subnet1'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'Subnet2'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      
    ]
  }
}
