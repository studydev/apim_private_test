targetScope = 'resourceGroup'

@description('Azure region for all new resources.')
param location string = resourceGroup().location

@description('APIM instance name. Must be globally unique.')
param apimName string

@description('APIM publisher email.')
param apimPublisherEmail string

@description('APIM publisher name.')
param apimPublisherName string

@description('VM admin username.')
param vmAdminUsername string = 'azureuser'

@secure()
@description('VM admin password.')
param vmAdminPassword string

@description('Public source CIDR allowed for SSH to test VM. Example: 203.0.113.10/32')
param allowedSshSourceIp string

@description('Azure OpenAI endpoint URL in Korea Central. Example: https://xxx.openai.azure.com')
param backend1Url string

@description('Azure OpenAI endpoint URL in Japan East. Example: https://yyy.openai.azure.com')
param backend2Url string

var vnetName = 'vnet-apim-private-test'
var vmSubnetName = 'snet-vm'
var peSubnetName = 'snet-pe'
var nsgName = 'nsg-vm'
var vmName = 'vm-apim-test'

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    vnetName: vnetName
    vmSubnetName: vmSubnetName
    peSubnetName: peSubnetName
    nsgName: nsgName
    allowedSshSourceIp: allowedSshSourceIp
  }
}

module vm './modules/vm.bicep' = {
  name: 'vm'
  params: {
    location: location
    vmName: vmName
    vmSubnetId: network.outputs.vmSubnetId
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
  }
}

module apimEnabled './modules/apim.bicep' = {
  name: 'apim-enabled'
  params: {
    location: location
    apimName: apimName
    apimPublisherEmail: apimPublisherEmail
    apimPublisherName: apimPublisherName
    publicNetworkAccess: 'Enabled'
    deployApi: true
    backend1Url: backend1Url
    backend2Url: backend2Url
  }
}

module privateEndpoint './modules/private-endpoint.bicep' = {
  name: 'apim-private-endpoint'
  params: {
    location: location
    apimName: apimName
    peSubnetId: network.outputs.peSubnetId
    vnetId: network.outputs.vnetId
  }
  dependsOn: [
    apimEnabled
  ]
}

module apimDisabled './modules/apim.bicep' = {
  name: 'apim-disabled'
  params: {
    location: location
    apimName: apimName
    apimPublisherEmail: apimPublisherEmail
    apimPublisherName: apimPublisherName
    publicNetworkAccess: 'Disabled'
    deployApi: false
    backend1Url: backend1Url
    backend2Url: backend2Url
  }
  dependsOn: [
    privateEndpoint
  ]
}

output vmPublicIp string = vm.outputs.vmPublicIp
output apimGatewayHost string = '${apimName}.azure-api.net'
output apimGatewayUrl string = apimEnabled.outputs.apimGatewayUrl
output apimPrincipalId string = apimEnabled.outputs.apimPrincipalId
