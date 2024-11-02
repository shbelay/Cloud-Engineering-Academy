//Location for the Storage Account deployment.
param location string = 'eastus'

//Name of the Storage Account.
param storageAccountName string = 'belaystorageproj713'

resource stg 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: storageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
}
