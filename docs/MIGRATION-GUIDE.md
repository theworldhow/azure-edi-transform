# Sterling Integrator to Azure Logic Apps EIP Migration Guide

## Executive Summary

This document provides a comprehensive guide for migrating EDI transformations from IBM Sterling B2B Integrator to Azure Logic Apps with Enterprise Integration Pack (EIP). The migration offers significant cost savings, improved scalability, and reduced operational overhead while maintaining full EDI compliance.

---

## 1. Migration Steps

### Phase 1: Discovery & Assessment (Weeks 1-2)

#### 1.1 Inventory Current Sterling Assets

```
┌─────────────────────────────────────────────────────────────────┐
│                    STERLING ASSET INVENTORY                      │
├─────────────────────────────────────────────────────────────────┤
│  □ Document all active Business Processes (BPs)                 │
│  □ List all Maps (Sterling Mapper files)                        │
│  □ Catalog Flat File Schemas                                    │
│  □ Record Trading Partner configurations                        │
│  □ Document Mailbox structures                                  │
│  □ List all adapters in use (SFTP, AS2, HTTP, etc.)            │
│  □ Export envelope configurations (ISA/GS settings)             │
│  □ Document scheduled workflows                                 │
│  □ Record transformation rules and validations                  │
└─────────────────────────────────────────────────────────────────┘
```

#### 1.2 Categorize Transactions

| Priority | Transaction Types | Volume/Day | Complexity |
|----------|------------------|------------|------------|
| High | 837, 835, 270, 271 | 10,000+ | Medium |
| Medium | 834, 820, 997 | 1,000-10,000 | Low |
| Low | Custom/Legacy | < 1,000 | High |

#### 1.3 Identify Dependencies

- External system integrations
- Database connections
- Custom Java/XSLT code
- Third-party adapters

### Phase 2: Environment Setup (Week 3)

#### 2.1 Azure Prerequisites

```bash
# Create Resource Group
az group create --name rg-edi-prod --location eastus

# Create Integration Account (Standard for production)
az resource create \
  --resource-group rg-edi-prod \
  --resource-type Microsoft.Logic/integrationAccounts \
  --name edi-integration-account \
  --properties '{"sku":{"name":"Standard"}}'

# Create Logic App (Standard tier recommended)
az functionapp create \
  --resource-group rg-edi-prod \
  --name edi-logicapp-prod \
  --storage-account edistorage \
  --functions-version 4 \
  --runtime node
```

#### 2.2 Network Configuration

1. Create Virtual Network with dedicated subnet
2. Configure Private Endpoints for Integration Account
3. Set up ExpressRoute or VPN for on-premises connectivity
4. Configure NSG rules for trading partner IPs

### Phase 3: Schema Migration (Weeks 4-5)

#### 3.1 Convert Sterling Schemas to XSD

| Sterling Format | Azure EIP Format | Tool |
|-----------------|------------------|------|
| Sterling DDF | XSD Schema | Manual conversion |
| Sterling Map | XSLT Map | Sterling Map Editor export |
| Flat File Schema | XSD with annotations | BizTalk Schema Editor |

#### 3.2 Schema Conversion Process

```
Sterling DDF/Schema
        │
        ▼
┌───────────────────┐
│ Export to XML/XSD │
│ (Sterling Tools)  │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ Validate & Adjust │
│ for Azure EIP     │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ Upload to         │
│ Integration Acct  │
└───────────────────┘
```

#### 3.3 Upload Schemas via Bicep

```bicep
resource schema 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: integrationAccount
  name: 'X12-837-Claim'
  properties: {
    schemaType: 'Xml'
    content: loadTextContent('schemas/x12-837-claim.xsd')
    contentType: 'application/xml'
  }
}
```

### Phase 4: Map Migration (Weeks 6-8)

#### 4.1 Convert Sterling Maps to XSLT

**Option A: Manual Conversion**
- Analyze Sterling Map logic
- Recreate in XSLT 1.0 (Azure EIP compatible)
- Test with sample data

**Option B: Export & Transform**
- Export Sterling Map to XML
- Use transformation tools to convert to XSLT
- Validate and optimize

#### 4.2 Map Testing Checklist

```
□ Unit test each map with sample EDI files
□ Validate output against expected results
□ Test edge cases (empty segments, special characters)
□ Performance test with large files
□ Validate namespace handling
□ Test date/time conversions
□ Verify numeric precision
```

### Phase 5: Trading Partner Setup (Weeks 9-10)

#### 5.1 Create Partner Profiles

```bicep
resource tradingPartner 'Microsoft.Logic/integrationAccounts/partners@2019-05-01' = {
  parent: integrationAccount
  name: 'BCBS-Partner'
  properties: {
    partnerType: 'B2B'
    content: {
      b2b: {
        businessIdentities: [
          {
            qualifier: 'ZZ'
            value: 'BCBS001'
          }
        ]
      }
    }
  }
}
```

#### 5.2 Create X12 Agreements

```bicep
resource x12Agreement 'Microsoft.Logic/integrationAccounts/agreements@2019-05-01' = {
  parent: integrationAccount
  name: 'BCBS-X12-Agreement'
  properties: {
    agreementType: 'X12'
    hostPartner: 'HostOrg'
    guestPartner: 'BCBS-Partner'
    hostIdentity: { qualifier: 'ZZ', value: 'MYORG001' }
    guestIdentity: { qualifier: 'ZZ', value: 'BCBS001' }
    content: {
      x12: {
        receiveAgreement: {
          protocolSettings: {
            validationSettings: { /* ... */ }
            envelopeSettings: { /* ... */ }
          }
        }
        sendAgreement: {
          protocolSettings: { /* ... */ }
        }
      }
    }
  }
}
```

### Phase 6: Workflow Development (Weeks 11-14)

#### 6.1 Logic App Workflow Pattern

```json
{
  "definition": {
    "triggers": {
      "When_file_received": { "type": "ApiConnection" }
    },
    "actions": {
      "Decode_X12": { "type": "X12DecodeMessages" },
      "Transform": { "type": "Xslt" },
      "Route_to_System": { "type": "Http" },
      "Send_997_Ack": { "type": "X12EncodeMessages" }
    }
  }
}
```

#### 6.2 Sterling BP to Logic App Mapping

| Sterling Component | Logic App Equivalent |
|-------------------|---------------------|
| Translator | X12 Decode/Encode connector |
| Map | XSLT Transform action |
| Mailbox Service | Service Bus Queue |
| File System Adapter | Azure Blob/SFTP connector |
| HTTP Adapter | HTTP trigger/action |
| Scheduler | Recurrence trigger |
| BP Sequence | Workflow actions |

### Phase 7: Testing (Weeks 15-17)

#### 7.1 Test Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    TESTING PHASES                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Week 15: Unit Testing                                       │
│  ├── Individual map tests                                    │
│  ├── Schema validation tests                                 │
│  └── Connector tests                                         │
│                                                              │
│  Week 16: Integration Testing                                │
│  ├── End-to-end transaction flows                           │
│  ├── Partner connectivity tests                              │
│  └── Error handling scenarios                                │
│                                                              │
│  Week 17: UAT & Performance                                  │
│  ├── Business user acceptance                                │
│  ├── Load testing (peak volumes)                            │
│  └── Failover testing                                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Phase 8: Cutover & Go-Live (Week 18)

#### 8.1 Cutover Checklist

```
Pre-Cutover:
□ Final data sync from Sterling
□ Notify all trading partners
□ Backup Sterling configuration
□ Document rollback procedures

Cutover:
□ Stop Sterling schedulers
□ Redirect incoming connections to Azure
□ Enable Logic App workflows
□ Monitor first transactions

Post-Cutover:
□ Verify successful transactions
□ Check 997 acknowledgments
□ Monitor error queues
□ Trading partner confirmation
```

---

## 2. Benefits & Cost Comparison

### Feature Comparison

| Feature | IBM Sterling B2B Integrator | Azure Logic Apps + EIP |
|---------|----------------------------|------------------------|
| **Deployment Model** | On-premises / VM-based | Cloud-native PaaS |
| **Scaling** | Manual (add servers) | Automatic (serverless) |
| **High Availability** | Manual clustering setup | Built-in (99.95% SLA) |
| **Disaster Recovery** | Manual replication | Geo-redundant by default |
| **Updates/Patches** | Manual maintenance windows | Automatic, zero-downtime |
| **X12 Support** | ✅ Full | ✅ Full (5010, 4010) |
| **EDIFACT Support** | ✅ Full | ✅ Full |
| **AS2 Protocol** | ✅ Native | ✅ Native connector |
| **SFTP Support** | ✅ Adapter | ✅ Native connector |
| **Custom Transformations** | Sterling Maps | XSLT / Liquid |
| **API Integration** | Requires development | Native HTTP/REST |
| **Real-time Monitoring** | Sterling Dashboard | Azure Monitor + Log Analytics |
| **Development Tools** | Sterling Studio | Azure Portal / VS Code |
| **Version Control** | Limited | Git-native (Bicep/ARM) |
| **CI/CD Support** | Complex | Native Azure DevOps |
| **Learning Curve** | Steep (proprietary) | Moderate (industry standard) |

### Cost Comparison (Annual)

| Cost Category | Sterling B2B (On-Prem) | Sterling B2B (SaaS) | Azure Logic Apps EIP |
|--------------|------------------------|---------------------|---------------------|
| **Software License** | $150,000 - $500,000 | $200,000 - $600,000 | $0 (Pay-per-use) |
| **Infrastructure** | $50,000 - $150,000 | Included | $12,000 - $36,000 |
| **Maintenance (20%)** | $30,000 - $100,000 | Included | $0 (managed service) |
| **Staff (2 FTEs)** | $200,000 - $300,000 | $150,000 - $200,000 | $100,000 - $150,000 |
| **Training** | $10,000 - $20,000 | $10,000 - $20,000 | $5,000 - $10,000 |
| **DR/HA Setup** | $25,000 - $50,000 | Included | Included |
| **Total Annual** | **$465,000 - $1,120,000** | **$360,000 - $820,000** | **$117,000 - $196,000** |

### ROI Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    COST SAVINGS ANALYSIS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Sterling On-Prem (Mid-range):     $750,000 / year              │
│  Azure Logic Apps EIP:             $150,000 / year              │
│  ────────────────────────────────────────────────               │
│  Annual Savings:                   $600,000 (80%)               │
│                                                                  │
│  Migration Cost (one-time):        $200,000                     │
│  Break-even Period:                4 months                      │
│                                                                  │
│  5-Year TCO Comparison:                                          │
│  ├── Sterling:    $3,750,000                                    │
│  ├── Azure EIP:   $950,000 (including migration)                │
│  └── Savings:     $2,800,000 (75%)                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Operational Benefits

| Benefit | Impact |
|---------|--------|
| **Reduced Downtime** | 99.95% SLA vs ~99% on-prem |
| **Faster Partner Onboarding** | Days vs weeks |
| **Automatic Scaling** | Handle 10x volume spikes |
| **No Maintenance Windows** | Zero-downtime updates |
| **Global Deployment** | Multi-region in minutes |
| **Developer Productivity** | 50% faster development |
| **Reduced Security Burden** | Azure handles compliance |

---

## 3. Implementation Timeline

### Standard Migration Timeline: 18-24 Weeks

```
Week:  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20
       │──────│──│─────│────────│─────│───────────│────────│──│────│
       │      │  │     │        │     │           │        │  │    │
       ▼      ▼  ▼     ▼        ▼     ▼           ▼        ▼  ▼    ▼
    Discovery │ Schema│  Map    │Partner│  Workflow │ Testing│Go│Support
    Assessment│ Setup │Migration│ Setup │Development│        │Live│
```

### Detailed Timeline by Transaction Volume

| Scenario | Transactions | Partners | Duration |
|----------|-------------|----------|----------|
| **Small** | < 10 types | < 20 | 12-14 weeks |
| **Medium** | 10-30 types | 20-100 | 16-20 weeks |
| **Large** | 30+ types | 100+ | 24-32 weeks |
| **Enterprise** | Complex custom | 500+ | 36-52 weeks |

### Resource Requirements

| Phase | Duration | Resources Needed |
|-------|----------|-----------------|
| Discovery | 2 weeks | 1 Sterling SME, 1 Azure Architect |
| Environment Setup | 1 week | 1 Azure Engineer |
| Schema Migration | 2-4 weeks | 2 EDI Developers |
| Map Migration | 4-8 weeks | 2-4 EDI Developers |
| Partner Setup | 2 weeks | 1 EDI Analyst |
| Workflow Dev | 4-6 weeks | 2 Logic App Developers |
| Testing | 3 weeks | 2 QA Engineers, Business Users |
| Cutover | 1 week | Full team |

---

## 4. Infrastructure & Maintenance Costs

### Azure Resource Costs (Monthly)

| Resource | SKU | Monthly Cost | Annual Cost |
|----------|-----|-------------|-------------|
| **Integration Account** | Standard | $1,000 | $12,000 |
| **Logic App (Consumption)** | Pay-per-execution | $500 - $2,000 | $6,000 - $24,000 |
| **Logic App (Standard)** | WS1 | $150 - $500 | $1,800 - $6,000 |
| **Storage Account** | Standard LRS | $50 | $600 |
| **Service Bus** | Standard | $10 - $100 | $120 - $1,200 |
| **Key Vault** | Standard | $5 | $60 |
| **Log Analytics** | Pay-per-GB | $100 - $300 | $1,200 - $3,600 |
| **Application Insights** | Pay-per-GB | $50 - $150 | $600 - $1,800 |
| **Virtual Network** | Basic | $50 | $600 |
| **Private Endpoints** | Per endpoint | $7.50 each | $90 each |

### Cost by Transaction Volume

| Daily Transactions | Logic App Type | Monthly Cost | Annual Cost |
|-------------------|----------------|--------------|-------------|
| 1,000 - 5,000 | Consumption | $1,500 | $18,000 |
| 5,000 - 20,000 | Consumption | $3,000 | $36,000 |
| 20,000 - 100,000 | Standard WS2 | $5,000 | $60,000 |
| 100,000+ | Standard WS3 | $10,000 | $120,000 |

### Maintenance Costs (Annual)

| Category | Sterling B2B | Azure Logic Apps |
|----------|-------------|------------------|
| Software Updates | $30,000+ | $0 (included) |
| Security Patches | $15,000 | $0 (automatic) |
| Hardware Refresh | $25,000 | $0 (no hardware) |
| DR Testing | $10,000 | $2,000 |
| Monitoring Tools | $15,000 | $3,000 (Azure Monitor) |
| Staff Training | $10,000 | $5,000 |
| Support Contract | $50,000+ | $0 (Azure support optional) |
| **Total** | **$155,000+** | **$10,000** |

### Total Cost of Ownership (5-Year)

```
┌─────────────────────────────────────────────────────────────────┐
│              5-YEAR TOTAL COST OF OWNERSHIP                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STERLING B2B INTEGRATOR (On-Premises)                          │
│  ├── Initial Setup:           $200,000                          │
│  ├── Annual License:          $300,000 × 5 = $1,500,000         │
│  ├── Infrastructure:          $100,000 × 5 = $500,000           │
│  ├── Maintenance:             $155,000 × 5 = $775,000           │
│  ├── Staff (2 FTE):           $250,000 × 5 = $1,250,000         │
│  └── TOTAL:                   $4,225,000                        │
│                                                                  │
│  AZURE LOGIC APPS + EIP                                         │
│  ├── Migration (one-time):    $200,000                          │
│  ├── Azure Resources:         $50,000 × 5 = $250,000            │
│  ├── Maintenance:             $10,000 × 5 = $50,000             │
│  ├── Staff (1 FTE):           $125,000 × 5 = $625,000           │
│  └── TOTAL:                   $1,125,000                        │
│                                                                  │
│  ═══════════════════════════════════════════════════════════    │
│  5-YEAR SAVINGS:              $3,100,000 (73%)                  │
│  ═══════════════════════════════════════════════════════════    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Splunk Integration for Monitoring

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ┌───────────┐    ┌──────────────┐    ┌───────────────────┐    │
│  │ Logic App │───▶│ Diagnostic   │───▶│ Event Hub         │    │
│  │ Workflows │    │ Settings     │    │ (Streaming)       │    │
│  └───────────┘    └──────────────┘    └─────────┬─────────┘    │
│                                                  │              │
│  ┌───────────┐    ┌──────────────┐              │              │
│  │Integration│───▶│ Log Analytics│──────────────┤              │
│  │ Account   │    │ Workspace    │              │              │
│  └───────────┘    └──────────────┘              │              │
│                                                  │              │
│                                                  ▼              │
│                          ┌──────────────────────────────────┐  │
│                          │         SPLUNK CLOUD             │  │
│                          │  ┌────────────────────────────┐  │  │
│                          │  │ Azure Event Hub Add-on     │  │  │
│                          │  └────────────────────────────┘  │  │
│                          │  ┌────────────────────────────┐  │  │
│                          │  │ EDI Transaction Dashboard  │  │  │
│                          │  └────────────────────────────┘  │  │
│                          │  ┌────────────────────────────┐  │  │
│                          │  │ Alerts & Notifications     │  │  │
│                          │  └────────────────────────────┘  │  │
│                          └──────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Step 1: Configure Azure Event Hub

```bicep
// Event Hub Namespace for Splunk streaming
resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
  name: 'edi-monitoring-hub'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  parent: eventHubNamespace
  name: 'edi-transactions'
  properties: {
    partitionCount: 4
    messageRetentionInDays: 7
  }
}

// Consumer group for Splunk
resource consumerGroup 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = {
  parent: eventHub
  name: 'splunk-consumer'
}
```

### Step 2: Configure Diagnostic Settings

```bicep
// Send Logic App logs to Event Hub
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'splunk-diagnostics'
  scope: logicApp
  properties: {
    eventHubAuthorizationRuleId: eventHubAuthRule.id
    eventHubName: eventHub.name
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
```

### Step 3: Add Custom Logging in Logic App

```json
{
  "Log_EDI_Transaction": {
    "type": "Http",
    "inputs": {
      "method": "POST",
      "uri": "@parameters('eventHubUri')",
      "headers": {
        "Content-Type": "application/json"
      },
      "body": {
        "timestamp": "@utcNow()",
        "transactionId": "@variables('messageId')",
        "transactionType": "@outputs('Get_Transaction_Type')",
        "sender": "@body('Decode_X12')?['senderQualifier']",
        "receiver": "@body('Decode_X12')?['receiverQualifier']",
        "controlNumber": "@body('Decode_X12')?['interchangeControlNumber']",
        "status": "success",
        "processingTime": "@div(sub(ticks(utcNow()),ticks(variables('startTime'))),10000)",
        "fileSize": "@length(triggerBody())"
      }
    }
  }
}
```

### Step 4: Install Splunk Add-on for Azure

1. **Install Add-on**
   - Splunk > Apps > Find More Apps
   - Search: "Splunk Add-on for Microsoft Cloud Services"
   - Install and configure

2. **Configure Event Hub Input**
   ```
   Settings > Data Inputs > Azure Event Hub
   
   Event Hub Namespace: edi-monitoring-hub
   Event Hub: edi-transactions
   Consumer Group: splunk-consumer
   Connection String: <from Azure Portal>
   ```

### Step 5: Create Splunk Dashboards

#### Sample SPL Queries

```spl
# Transaction Volume by Type
index=azure_edi source="eventhub:edi-transactions"
| stats count by transactionType
| sort -count

# Failed Transactions
index=azure_edi source="eventhub:edi-transactions" status="failed"
| table timestamp, transactionId, transactionType, errorMessage
| sort -timestamp

# Average Processing Time by Transaction Type
index=azure_edi source="eventhub:edi-transactions"
| stats avg(processingTime) as avgTime by transactionType
| eval avgTimeSeconds = round(avgTime/1000, 2)
| table transactionType, avgTimeSeconds

# Transactions by Trading Partner
index=azure_edi source="eventhub:edi-transactions"
| stats count by sender, receiver
| sort -count

# Hourly Transaction Trend
index=azure_edi source="eventhub:edi-transactions"
| timechart span=1h count by transactionType
```

#### Dashboard XML

```xml
<dashboard>
  <label>EDI Transaction Monitor</label>
  <row>
    <panel>
      <title>Transaction Volume (24h)</title>
      <single>
        <search>
          <query>index=azure_edi | stats count</query>
          <earliest>-24h</earliest>
        </search>
      </single>
    </panel>
    <panel>
      <title>Success Rate</title>
      <single>
        <search>
          <query>
            index=azure_edi 
            | stats count(eval(status="success")) as success, count as total 
            | eval rate=round(success/total*100,1)."%"
          </query>
        </search>
      </single>
    </panel>
    <panel>
      <title>Avg Processing Time</title>
      <single>
        <search>
          <query>
            index=azure_edi 
            | stats avg(processingTime) as avg 
            | eval avg=round(avg,0)."ms"
          </query>
        </search>
      </single>
    </panel>
  </row>
  <row>
    <panel>
      <title>Transaction Trend</title>
      <chart>
        <search>
          <query>index=azure_edi | timechart span=1h count by transactionType</query>
        </search>
        <option name="charting.chart">area</option>
      </chart>
    </panel>
  </row>
  <row>
    <panel>
      <title>Recent Failures</title>
      <table>
        <search>
          <query>
            index=azure_edi status="failed" 
            | table timestamp, transactionType, sender, errorMessage 
            | head 20
          </query>
        </search>
      </table>
    </panel>
  </row>
</dashboard>
```

### Step 6: Configure Alerts

```spl
# Alert: High Failure Rate
index=azure_edi earliest=-15m
| stats count(eval(status="failed")) as failures, count as total
| eval failureRate = failures/total*100
| where failureRate > 5

# Alert: Processing Time Spike
index=azure_edi earliest=-15m
| stats avg(processingTime) as avgTime
| where avgTime > 5000

# Alert: No Transactions (Dead System)
index=azure_edi earliest=-30m
| stats count
| where count < 1
```

### Alternative: Direct Azure Monitor to Splunk

For simpler setup, use Azure Monitor's native Splunk integration:

```bash
# Azure Function to forward logs to Splunk HEC
az functionapp create \
  --name edi-splunk-forwarder \
  --resource-group rg-edi-prod \
  --consumption-plan-location eastus \
  --runtime node \
  --functions-version 4
```

---

## Summary

### Key Takeaways

| Aspect | Recommendation |
|--------|---------------|
| **Migration Approach** | Phased migration, starting with high-volume transactions |
| **Timeline** | 18-24 weeks for medium complexity |
| **Cost Savings** | 70-80% reduction in TCO |
| **Staffing** | Reduce from 2 FTEs to 1 FTE |
| **Monitoring** | Splunk via Event Hub for real-time visibility |

### Next Steps

1. ☐ Complete Sterling asset inventory
2. ☐ Set up Azure sandbox environment
3. ☐ Pilot migration with one transaction type (837)
4. ☐ Validate with trading partner
5. ☐ Plan full migration phases

---

*Document Version: 1.0*  
*Last Updated: February 2026*  
*Author: EDI Migration Team*

