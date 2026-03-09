@description('Azure region.')
param location string

@description('APIM instance name.')
param apimName string

@description('APIM publisher email.')
param apimPublisherEmail string

@description('APIM publisher name.')
param apimPublisherName string

@allowed([
  'Enabled'
  'Disabled'
])
@description('Public network access mode for APIM.')
param publicNetworkAccess string

@description('When true, deploy API/operations/policies. When false, update APIM only.')
param deployApi bool = true

@description('Azure OpenAI endpoint URL in Korea Central.')
param backend1Url string

@description('Azure OpenAI endpoint URL in Japan East.')
param backend2Url string

var apiName = 'chat-api'
var policyPrefix = '<policies><inbound><base />'
var policySuffix = '<authentication-managed-identity resource="https://cognitiveservices.azure.com/" /><set-method>POST</set-method></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
var routePolicyMiddle = '<rewrite-uri template="/openai/deployments/gpt-5.2/chat/completions" /><set-query-parameter name="api-version" exists-action="override"><value>2024-10-21</value></set-query-parameter>'

resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'StandardV2'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    publicNetworkAccess: publicNetworkAccess
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = if (deployApi) {
  parent: apim
  name: apiName
  properties: {
    displayName: 'Private Validation Chat API'
    path: 'chat'
    protocols: [
      'https'
    ]
    subscriptionRequired: false
    serviceUrl: 'https://example.invalid'
  }
}

resource opTest1 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' = if (deployApi) {
  parent: api
  name: 'test1-post'
  properties: {
    displayName: 'Proxy to Korea Central gpt-4o-mini'
    method: 'POST'
    urlTemplate: '/test1'
    request: {
      queryParameters: []
      headers: []
      representations: [
        {
          contentType: 'application/json'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
      }
      {
        statusCode: 403
      }
      {
        statusCode: 500
      }
    ]
  }
}

resource opTest2 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' = if (deployApi) {
  parent: api
  name: 'test2-post'
  properties: {
    displayName: 'Proxy to Japan East gpt-4o-mini'
    method: 'POST'
    urlTemplate: '/test2'
    request: {
      queryParameters: []
      headers: []
      representations: [
        {
          contentType: 'application/json'
        }
      ]
    }
    responses: [
      {
        statusCode: 200
      }
      {
        statusCode: 403
      }
      {
        statusCode: 500
      }
    ]
  }
}

resource opTest1Policy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-09-01-preview' = if (deployApi) {
  parent: opTest1
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '${policyPrefix}<set-backend-service base-url="${backend1Url}" />${routePolicyMiddle}${policySuffix}'
  }
}

resource opTest2Policy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-09-01-preview' = if (deployApi) {
  parent: opTest2
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: '${policyPrefix}<set-backend-service base-url="${backend2Url}" />${routePolicyMiddle}${policySuffix}'
  }
}

output apimId string = apim.id
output apimPrincipalId string = apim.identity.principalId!
output apimGatewayUrl string = 'https://${apim.name}.azure-api.net'
