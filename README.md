# Azure Healthcare EDI Transform

> **Replacing IBM Sterling B2B Integrator EDI transformations with native Azure Logic Apps + Enterprise Integration Pack (EIP) for ANSI X12 Healthcare Transactions**

This project provides a complete, ready-to-deploy Azure infrastructure for processing HIPAA-compliant X12 healthcare EDI transactions. It demonstrates how to migrate from IBM Sterling B2B Integrator to Azure Logic Apps.

## 📋 Supported X12 Transaction Sets

| Transaction | Name | Description |
|-------------|------|-------------|
| **837** | Healthcare Claim | Professional (837P) and Institutional (837I) claim submissions |
| **835** | Remittance Advice | Claim payment/advice from payers to providers |
| **270** | Eligibility Inquiry | Coverage and benefit verification requests |
| **271** | Eligibility Response | Coverage and benefit information responses |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                Azure Healthcare EDI Transform Solution                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐                                                            │
│  │   Provider   │──── 837 Claim ────┐                                       │
│  │   System     │                    │                                       │
│  └──────────────┘                    │     ┌────────────────────────────┐   │
│                                      ├────▶│     Logic App Workflow     │   │
│  ┌──────────────┐                    │     │  ┌────────────────────┐   │   │
│  │    Payer     │──── 835 Remit ────┤     │  │  Switch by X-Type  │   │   │
│  │   System     │                    │     │  └─────────┬──────────┘   │   │
│  └──────────────┘                    │     │            │              │   │
│                                      │     │  ┌─────────▼──────────┐   │   │
│  ┌──────────────┐                    │     │  │  XSLT Transform    │   │   │
│  │  Clearning   │──── 270/271 ──────┤     │  │  (837/835/270/271) │   │   │
│  │    House     │                    │     │  └─────────┬──────────┘   │   │
│  └──────────────┘                    │     │            │              │   │
│                                      │     └────────────┼──────────────┘   │
│                                      │                  │                   │
│                                      │     ┌────────────▼──────────────┐   │
│                                      │     │   Integration Account     │   │
│  ┌──────────────┐                    │     │  ┌────────┐ ┌────────┐   │   │
│  │  Downstream  │◀─── JSON ─────────┘     │  │Schemas │ │ Maps   │   │   │
│  │   Systems    │                          │  │837/835 │ │ XSLT   │   │   │
│  └──────────────┘                          │  │270/271 │ │        │   │   │
│                                            │  └────────┘ └────────┘   │   │
│                                            └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
azure-edi-transform/
├── main.bicep                           # Main infrastructure template
├── schemas/
│   ├── x12-837-claim.xsd               # Healthcare Claim schema
│   ├── x12-835-remittance.xsd          # Remittance Advice schema
│   ├── x12-270-eligibility.xsd         # Eligibility Inquiry schema
│   └── x12-271-eligibility-response.xsd # Eligibility Response schema
├── maps/
│   ├── 837-to-json.xslt                # Claim to JSON transform
│   ├── 835-to-json.xslt                # Remittance to JSON transform
│   ├── 270-to-json.xslt                # Eligibility Inquiry to JSON
│   └── 271-to-json.xslt                # Eligibility Response to JSON
├── workflows/
│   └── edi-transform.json              # Logic App workflow (all transactions)
└── README.md
```

## 🚀 Deployment

### Prerequisites

```bash
# Install Azure CLI
brew install azure-cli    # macOS
# or: winget install Microsoft.AzureCLI  # Windows

# Login to Azure
az login
az account set --subscription "Your-Subscription"
```

### Deploy

```bash
# Deploy to existing resource group
az deployment group create \
  --resource-group rg-edi-transform-dev \
  --template-file main.bicep \
  --parameters environment=dev
```

### Get Endpoint URL

```bash
az deployment group show \
  --resource-group rg-edi-transform-dev \
  --name main \
  --query properties.outputs.logicAppUrl.value -o tsv
```

## 🧪 Testing

The Logic App uses the `X-Transaction-Type` header to route to the correct transform:

| Header Value | Transaction |
|--------------|-------------|
| `837` | Healthcare Claim (default if no header) |
| `835` | Remittance Advice |
| `270` | Eligibility Inquiry |
| `271` | Eligibility Response |

---

### Test 837 Healthcare Claim

```bash
curl -X POST "$LOGIC_APP_URL" \
  -H "Content-Type: application/xml" \
  -H "X-Transaction-Type: 837" \
  -d '<?xml version="1.0"?>
<x12:X12_005010X222A1_837 xmlns:x12="http://schemas.microsoft.com/BizTalk/EDI/X12/2006">
  <x12:ST>
    <x12:ST01>837</x12:ST01>
    <x12:ST02>0001</x12:ST02>
    <x12:ST03>005010X222A1</x12:ST03>
  </x12:ST>
  <x12:BHT>
    <x12:BHT01>0019</x12:BHT01>
    <x12:BHT02>00</x12:BHT02>
    <x12:BHT03>CLM123456</x12:BHT03>
    <x12:BHT04>20240215</x12:BHT04>
    <x12:BHT05>1200</x12:BHT05>
    <x12:BHT06>CH</x12:BHT06>
  </x12:BHT>
  <x12:Loop1000A>
    <x12:NM1>
      <x12:NM101>41</x12:NM101>
      <x12:NM102>2</x12:NM102>
      <x12:NM103>ACME HEALTHCARE BILLING</x12:NM103>
      <x12:NM108>46</x12:NM108>
      <x12:NM109>ACME001</x12:NM109>
    </x12:NM1>
    <x12:PER>
      <x12:PER01>IC</x12:PER01>
      <x12:PER02>BILLING DEPT</x12:PER02>
      <x12:PER03>TE</x12:PER03>
      <x12:PER04>5551234567</x12:PER04>
    </x12:PER>
  </x12:Loop1000A>
  <x12:Loop1000B>
    <x12:NM1>
      <x12:NM101>40</x12:NM101>
      <x12:NM102>2</x12:NM102>
      <x12:NM103>BLUE CROSS BLUE SHIELD</x12:NM103>
      <x12:NM108>46</x12:NM108>
      <x12:NM109>BCBS001</x12:NM109>
    </x12:NM1>
  </x12:Loop1000B>
  <x12:Loop2000A>
    <x12:HL>
      <x12:HL01>1</x12:HL01>
      <x12:HL03>20</x12:HL03>
      <x12:HL04>1</x12:HL04>
    </x12:HL>
    <x12:Loop2010AA>
      <x12:NM1>
        <x12:NM101>85</x12:NM101>
        <x12:NM102>2</x12:NM102>
        <x12:NM103>COMMUNITY MEDICAL CENTER</x12:NM103>
        <x12:NM108>XX</x12:NM108>
        <x12:NM109>1234567890</x12:NM109>
      </x12:NM1>
      <x12:N3><x12:N301>123 HEALTHCARE BLVD</x12:N301></x12:N3>
      <x12:N4>
        <x12:N401>CHICAGO</x12:N401>
        <x12:N402>IL</x12:N402>
        <x12:N403>60601</x12:N403>
      </x12:N4>
      <x12:REF>
        <x12:REF01>EI</x12:REF01>
        <x12:REF02>123456789</x12:REF02>
      </x12:REF>
    </x12:Loop2010AA>
    <x12:Loop2000B>
      <x12:HL>
        <x12:HL01>2</x12:HL01>
        <x12:HL02>1</x12:HL02>
        <x12:HL03>22</x12:HL03>
        <x12:HL04>1</x12:HL04>
      </x12:HL>
      <x12:SBR>
        <x12:SBR01>P</x12:SBR01>
        <x12:SBR02>18</x12:SBR02>
        <x12:SBR03>EMPLOYER123</x12:SBR03>
        <x12:SBR09>CI</x12:SBR09>
      </x12:SBR>
      <x12:Loop2010BA>
        <x12:NM1>
          <x12:NM101>IL</x12:NM101>
          <x12:NM102>1</x12:NM102>
          <x12:NM103>SMITH</x12:NM103>
          <x12:NM104>JOHN</x12:NM104>
          <x12:NM108>MI</x12:NM108>
          <x12:NM109>ABC123456789</x12:NM109>
        </x12:NM1>
        <x12:N3><x12:N301>456 PATIENT WAY</x12:N301></x12:N3>
        <x12:N4>
          <x12:N401>CHICAGO</x12:N401>
          <x12:N402>IL</x12:N402>
          <x12:N403>60602</x12:N403>
        </x12:N4>
        <x12:DMG>
          <x12:DMG01>D8</x12:DMG01>
          <x12:DMG02>19850315</x12:DMG02>
          <x12:DMG03>M</x12:DMG03>
        </x12:DMG>
      </x12:Loop2010BA>
      <x12:Loop2010BB>
        <x12:NM1>
          <x12:NM101>PR</x12:NM101>
          <x12:NM102>2</x12:NM102>
          <x12:NM103>BLUE CROSS BLUE SHIELD</x12:NM103>
          <x12:NM108>PI</x12:NM108>
          <x12:NM109>BCBS001</x12:NM109>
        </x12:NM1>
      </x12:Loop2010BB>
      <x12:Loop2300>
        <x12:CLM>
          <x12:CLM01>CLM789456</x12:CLM01>
          <x12:CLM02>1500.00</x12:CLM02>
          <x12:CLM05>
            <x12:CLM0501>11</x12:CLM0501>
            <x12:CLM0502>B</x12:CLM0502>
            <x12:CLM0503>1</x12:CLM0503>
          </x12:CLM05>
        </x12:CLM>
        <x12:HI>
          <x12:HI01>
            <x12:HI0101>ABK</x12:HI0101>
            <x12:HI0102>J069</x12:HI0102>
          </x12:HI01>
          <x12:HI02>
            <x12:HI0101>ABF</x12:HI0101>
            <x12:HI0102>R051</x12:HI0102>
          </x12:HI02>
        </x12:HI>
        <x12:Loop2400>
          <x12:LX><x12:LX01>1</x12:LX01></x12:LX>
          <x12:SV1>
            <x12:SV101>
              <x12:SV10101>HC</x12:SV10101>
              <x12:SV10102>99213</x12:SV10102>
              <x12:SV10103>25</x12:SV10103>
            </x12:SV101>
            <x12:SV102>150.00</x12:SV102>
            <x12:SV103>UN</x12:SV103>
            <x12:SV104>1</x12:SV104>
            <x12:SV107>11</x12:SV107>
          </x12:SV1>
          <x12:DTP>
            <x12:DTP01>472</x12:DTP01>
            <x12:DTP02>D8</x12:DTP02>
            <x12:DTP03>20240215</x12:DTP03>
          </x12:DTP>
        </x12:Loop2400>
      </x12:Loop2300>
    </x12:Loop2000B>
  </x12:Loop2000A>
  <x12:SE>
    <x12:SE01>25</x12:SE01>
    <x12:SE02>0001</x12:SE02>
  </x12:SE>
</x12:X12_005010X222A1_837>'
```

---

### Test 270 Eligibility Inquiry

```bash
curl -X POST "$LOGIC_APP_URL" \
  -H "Content-Type: application/xml" \
  -H "X-Transaction-Type: 270" \
  -d '<?xml version="1.0"?>
<x12:X12_005010X279A1_270 xmlns:x12="http://schemas.microsoft.com/BizTalk/EDI/X12/2006">
  <x12:ST>
    <x12:ST01>270</x12:ST01>
    <x12:ST02>0001</x12:ST02>
    <x12:ST03>005010X279A1</x12:ST03>
  </x12:ST>
  <x12:BHT>
    <x12:BHT01>0022</x12:BHT01>
    <x12:BHT02>13</x12:BHT02>
    <x12:BHT03>ELG123456</x12:BHT03>
    <x12:BHT04>20240215</x12:BHT04>
    <x12:BHT05>1200</x12:BHT05>
  </x12:BHT>
  <x12:Loop2000A>
    <x12:HL>
      <x12:HL01>1</x12:HL01>
      <x12:HL03>20</x12:HL03>
      <x12:HL04>1</x12:HL04>
    </x12:HL>
    <x12:Loop2100A>
      <x12:NM1>
        <x12:NM101>PR</x12:NM101>
        <x12:NM102>2</x12:NM102>
        <x12:NM103>BLUE CROSS BLUE SHIELD</x12:NM103>
        <x12:NM108>PI</x12:NM108>
        <x12:NM109>BCBS001</x12:NM109>
      </x12:NM1>
    </x12:Loop2100A>
    <x12:Loop2000B>
      <x12:HL>
        <x12:HL01>2</x12:HL01>
        <x12:HL02>1</x12:HL02>
        <x12:HL03>21</x12:HL03>
        <x12:HL04>1</x12:HL04>
      </x12:HL>
      <x12:Loop2100B>
        <x12:NM1>
          <x12:NM101>1P</x12:NM101>
          <x12:NM102>2</x12:NM102>
          <x12:NM103>COMMUNITY MEDICAL CENTER</x12:NM103>
          <x12:NM108>XX</x12:NM108>
          <x12:NM109>1234567890</x12:NM109>
        </x12:NM1>
      </x12:Loop2100B>
      <x12:Loop2000C>
        <x12:HL>
          <x12:HL01>3</x12:HL01>
          <x12:HL02>2</x12:HL02>
          <x12:HL03>22</x12:HL03>
          <x12:HL04>0</x12:HL04>
        </x12:HL>
        <x12:TRN>
          <x12:TRN01>1</x12:TRN01>
          <x12:TRN02>TRC123456789</x12:TRN02>
        </x12:TRN>
        <x12:Loop2100C>
          <x12:NM1>
            <x12:NM101>IL</x12:NM101>
            <x12:NM102>1</x12:NM102>
            <x12:NM103>SMITH</x12:NM103>
            <x12:NM104>JOHN</x12:NM104>
            <x12:NM105>A</x12:NM105>
            <x12:NM108>MI</x12:NM108>
            <x12:NM109>ABC123456789</x12:NM109>
          </x12:NM1>
          <x12:DMG>
            <x12:DMG01>D8</x12:DMG01>
            <x12:DMG02>19850315</x12:DMG02>
            <x12:DMG03>M</x12:DMG03>
          </x12:DMG>
          <x12:DTP>
            <x12:DTP01>291</x12:DTP01>
            <x12:DTP02>D8</x12:DTP02>
            <x12:DTP03>20240215</x12:DTP03>
          </x12:DTP>
          <x12:Loop2110C>
            <x12:EQ>
              <x12:EQ01>30</x12:EQ01>
            </x12:EQ>
          </x12:Loop2110C>
        </x12:Loop2100C>
      </x12:Loop2000C>
    </x12:Loop2000B>
  </x12:Loop2000A>
  <x12:SE>
    <x12:SE01>15</x12:SE01>
    <x12:SE02>0001</x12:SE02>
  </x12:SE>
</x12:X12_005010X279A1_270>'
```

---

### Test with Postman

1. **Method**: POST
2. **URL**: Logic App trigger URL
3. **Headers**:
   - `Content-Type: application/xml`
   - `X-Transaction-Type: 837` (or `835`, `270`, `271`)
4. **Body**: Raw XML (examples above)

## 📊 X12 Segment Reference

### Common Segments

| Segment | Name | Description |
|---------|------|-------------|
| ST | Transaction Set Header | Identifies transaction type |
| SE | Transaction Set Trailer | Segment count and control number |
| BHT | Beginning of Hierarchical Transaction | Transaction purpose and date |
| HL | Hierarchical Level | Defines hierarchy structure |
| NM1 | Individual or Organizational Name | Entity identification |
| N3 | Address Information | Street address |
| N4 | Geographic Location | City, state, postal code |
| REF | Reference Identification | Reference numbers |
| DTP | Date or Time Period | Date information |
| DMG | Demographic Information | DOB, gender |

### 837 Specific Segments

| Segment | Description |
|---------|-------------|
| CLM | Claim information (ID, amount, facility) |
| SBR | Subscriber information |
| HI | Health care diagnosis codes |
| SV1 | Professional service line |
| SV2 | Institutional service line |
| PRV | Provider information |

### 835 Specific Segments

| Segment | Description |
|---------|-------------|
| BPR | Financial information (payment amount, method) |
| TRN | Trace number for reconciliation |
| CLP | Claim level payment data |
| CAS | Claim adjustment codes |
| SVC | Service line payment information |
| PLB | Provider level adjustment |

### 270/271 Specific Segments

| Segment | Description |
|---------|-------------|
| EQ | Eligibility or benefit inquiry |
| EB | Eligibility or benefit information |
| AAA | Request validation errors |
| INS | Insured benefit |
| HSD | Health care services delivery |
| MSG | Free-form message text |

## ⚠️ Production Considerations

### HIPAA Compliance

- Enable diagnostic logging with PHI masking
- Use VNet integration with private endpoints
- Enable encryption at rest (Azure default)
- Implement audit trails
- Use managed identities (no connection strings)

### Recommended Architecture

```bicep
// Production: Use Logic Apps Standard
resource logicAppStandard 'Microsoft.Web/sites@2022-03-01' = {
  name: logicAppName
  kind: 'functionapp,workflowapp'
  identity: { type: 'SystemAssigned' }
  properties: {
    virtualNetworkSubnetId: subnetId
    // ... additional config
  }
}
```

### High Availability

- Deploy to multiple regions
- Use Azure Front Door for routing
- Implement retry policies
- Monitor with Application Insights

## 🔄 Sterling B2B Migration Mapping

| Sterling B2B Component | Azure EIP Equivalent |
|------------------------|----------------------|
| Sterling Integrator Maps | XSLT Maps in Integration Account |
| Business Process Definition | Logic App Workflow |
| X12 Envelope Handler | X12 Decode/Encode Connector |
| Flat File Schema | XSD Schema in Integration Account |
| Trading Partner Profile | Partner + Agreement resources |
| Mailbox | Service Bus Queue |
| SFTP Adapter | SFTP-SSH Connector |
| AS2 Adapter | AS2 Connector + Agreement |

## 📚 Resources

- [Azure Logic Apps Documentation](https://docs.microsoft.com/azure/logic-apps/)
- [Enterprise Integration Pack](https://docs.microsoft.com/azure/logic-apps/logic-apps-enterprise-integration-overview)
- [X12 Processing in Logic Apps](https://docs.microsoft.com/azure/logic-apps/logic-apps-enterprise-integration-x12)
- [HIPAA Compliance in Azure](https://docs.microsoft.com/azure/compliance/offerings/offering-hipaa-us)
- [X12 Implementation Guides](https://x12.org/)

## 📄 License

MIT License

---

**Note:** This solution processes Protected Health Information (PHI). Ensure compliance with HIPAA, HITECH, and your organization's security requirements before production deployment.
