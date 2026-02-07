// ============================================================================
// Azure Healthcare EDI Transform - Main Bicep Template
// ============================================================================
// This template replaces IBM Sterling B2B Integrator EDI transformations
// using native Azure Logic Apps + Enterprise Integration Pack (EIP).
// Supports X12 837 (Claims), 835 (Remittance), 270/271 (Eligibility).
// ============================================================================

// ----------------------------------------------------------------------------
// PARAMETERS
// ----------------------------------------------------------------------------

@description('The Azure region for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Base name for all resources')
param baseName string = 'edi-transform'

@description('Integration Account SKU - Basic supports schemas/maps, Standard adds RosettaNet')
@allowed(['Free', 'Basic', 'Standard'])
param integrationAccountSku string = 'Basic'

// ----------------------------------------------------------------------------
// VARIABLES
// ----------------------------------------------------------------------------

var integrationAccountName = '${baseName}-ia-${environment}'
var logicAppName = '${baseName}-la-${environment}'

// Load schemas
var schema837 = loadTextContent('schemas/x12-837-claim.xsd')
var schema835 = loadTextContent('schemas/x12-835-remittance.xsd')
var schema270 = loadTextContent('schemas/x12-270-eligibility.xsd')
var schema271 = loadTextContent('schemas/x12-271-eligibility-response.xsd')

// Load maps
var map837 = loadTextContent('maps/837-to-json.xslt')
var map835 = loadTextContent('maps/835-to-json.xslt')
var map270 = loadTextContent('maps/270-to-json.xslt')
var map271 = loadTextContent('maps/271-to-json.xslt')

// Load workflow
var ediTransformWorkflow = loadJsonContent('workflows/edi-transform.json')

// ----------------------------------------------------------------------------
// INTEGRATION ACCOUNT
// ----------------------------------------------------------------------------

resource integrationAccount 'Microsoft.Logic/integrationAccounts@2019-05-01' = {
  name: integrationAccountName
  location: location
  sku: {
    name: integrationAccountSku
  }
  properties: {
    state: 'Enabled'
  }
  tags: {
    environment: environment
    purpose: 'Healthcare-EDI-Transform'
    migrationSource: 'IBM-Sterling-B2B'
  }
}

// ----------------------------------------------------------------------------
// SCHEMAS - X12 Healthcare Transaction Sets
// ----------------------------------------------------------------------------

// 837 - Healthcare Claim
resource schema837Resource 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: integrationAccount
  name: 'X12-837-Claim'
  properties: {
    schemaType: 'Xml'
    content: schema837
    contentType: 'application/xml'
    metadata: {
      version: '005010X222A1'
      transactionSet: '837'
      description: 'Healthcare Claim Professional/Institutional'
    }
  }
}

// 835 - Healthcare Claim Payment/Advice
resource schema835Resource 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: integrationAccount
  name: 'X12-835-Remittance'
  properties: {
    schemaType: 'Xml'
    content: schema835
    contentType: 'application/xml'
    metadata: {
      version: '005010X221A1'
      transactionSet: '835'
      description: 'Healthcare Claim Payment/Advice (Remittance)'
    }
  }
}

// 270 - Eligibility Inquiry
resource schema270Resource 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: integrationAccount
  name: 'X12-270-Eligibility'
  properties: {
    schemaType: 'Xml'
    content: schema270
    contentType: 'application/xml'
    metadata: {
      version: '005010X279A1'
      transactionSet: '270'
      description: 'Eligibility, Coverage, or Benefit Inquiry'
    }
  }
}

// 271 - Eligibility Response
resource schema271Resource 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: integrationAccount
  name: 'X12-271-EligibilityResponse'
  properties: {
    schemaType: 'Xml'
    content: schema271
    contentType: 'application/xml'
    metadata: {
      version: '005010X279A1'
      transactionSet: '271'
      description: 'Eligibility, Coverage, or Benefit Information'
    }
  }
}

// ----------------------------------------------------------------------------
// MAPS - XSLT Transformations
// ----------------------------------------------------------------------------

// 837 to JSON
resource map837Resource 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: integrationAccount
  name: '837-to-json'
  properties: {
    mapType: 'Xslt'
    content: map837
    contentType: 'application/xml'
    metadata: {
      sourceFormat: 'X12-837'
      targetFormat: 'JSON'
      description: 'Healthcare Claim to JSON'
    }
  }
}

// 835 to JSON
resource map835Resource 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: integrationAccount
  name: '835-to-json'
  properties: {
    mapType: 'Xslt'
    content: map835
    contentType: 'application/xml'
    metadata: {
      sourceFormat: 'X12-835'
      targetFormat: 'JSON'
      description: 'Remittance Advice to JSON'
    }
  }
}

// 270 to JSON
resource map270Resource 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: integrationAccount
  name: '270-to-json'
  properties: {
    mapType: 'Xslt'
    content: map270
    contentType: 'application/xml'
    metadata: {
      sourceFormat: 'X12-270'
      targetFormat: 'JSON'
      description: 'Eligibility Inquiry to JSON'
    }
  }
}

// 271 to JSON
resource map271Resource 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: integrationAccount
  name: '271-to-json'
  properties: {
    mapType: 'Xslt'
    content: map271
    contentType: 'application/xml'
    metadata: {
      sourceFormat: 'X12-271'
      targetFormat: 'JSON'
      description: 'Eligibility Response to JSON'
    }
  }
}

// ----------------------------------------------------------------------------
// LOGIC APP WORKFLOW
// ----------------------------------------------------------------------------
// Single Logic App handling all healthcare EDI transaction types:
// - 837 Healthcare Claims
// - 835 Remittance/Payment Advice
// - 270 Eligibility Inquiry
// - 271 Eligibility Response
// Routes to appropriate map based on transaction type header parameter.
// ----------------------------------------------------------------------------

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    integrationAccount: {
      id: integrationAccount.id
    }
    definition: ediTransformWorkflow.definition
    parameters: {}
  }
  tags: {
    environment: environment
    purpose: 'Healthcare-EDI-Transform'
    migrationSource: 'IBM-Sterling-B2B'
  }
  dependsOn: [
    map837Resource
    map835Resource
    map270Resource
    map271Resource
    schema837Resource
    schema835Resource
    schema270Resource
    schema271Resource
  ]
}

// ----------------------------------------------------------------------------
// OUTPUTS
// ----------------------------------------------------------------------------

@description('Logic App HTTP trigger URL')
output logicAppUrl string = listCallbackUrl('${logicApp.id}/triggers/Healthcare_EDI_Received', '2019-05-01').value

@description('Logic App name')
output logicAppName string = logicApp.name

@description('Integration Account name')
output integrationAccountName string = integrationAccount.name

@description('Deployed schemas')
output schemas array = [
  schema837Resource.name
  schema835Resource.name
  schema270Resource.name
  schema271Resource.name
]

@description('Deployed maps')
output maps array = [
  map837Resource.name
  map835Resource.name
  map270Resource.name
  map271Resource.name
]
