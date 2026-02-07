<?xml version="1.0" encoding="utf-8"?>
<!--
  X12 835 Healthcare Claim Payment/Advice to JSON Transform
  ============================================================================
  Transforms X12 835 Remittance Advice XML to JSON-friendly structure.
  Used for processing claim payment responses from payers.
  ============================================================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:x12="http://schemas.microsoft.com/BizTalk/EDI/X12/2006"
    exclude-result-prefixes="x12">

  <xsl:output method="xml" indent="yes" omit-xml-declaration="no"/>
  <xsl:template match="text()"/>

  <xsl:template match="/">
    <xsl:apply-templates select="x12:X12_005010X221A1_835"/>
  </xsl:template>

  <xsl:template match="x12:X12_005010X221A1_835">
    <remittanceAdvice>
      <transactionInfo>
        <transactionSetId><xsl:value-of select="x12:ST/x12:ST01"/></transactionSetId>
        <controlNumber><xsl:value-of select="x12:ST/x12:ST02"/></controlNumber>
      </transactionInfo>

      <financialInfo>
        <transactionHandlingCode>
          <xsl:call-template name="getHandlingCode">
            <xsl:with-param name="code" select="x12:BPR/x12:BPR01"/>
          </xsl:call-template>
        </transactionHandlingCode>
        <totalPaymentAmount><xsl:value-of select="x12:BPR/x12:BPR02"/></totalPaymentAmount>
        <creditDebitFlag><xsl:value-of select="x12:BPR/x12:BPR03"/></creditDebitFlag>
        <paymentMethod>
          <xsl:call-template name="getPaymentMethod">
            <xsl:with-param name="code" select="x12:BPR/x12:BPR04"/>
          </xsl:call-template>
        </paymentMethod>
        <paymentDate>
          <xsl:call-template name="formatDate">
            <xsl:with-param name="date" select="x12:BPR/x12:BPR16"/>
          </xsl:call-template>
        </paymentDate>
      </financialInfo>

      <traceNumber>
        <originatingCompanyId><xsl:value-of select="x12:TRN/x12:TRN02"/></originatingCompanyId>
        <originatingCompanySupplementalCode><xsl:value-of select="x12:TRN/x12:TRN03"/></originatingCompanySupplementalCode>
      </traceNumber>

      <xsl:if test="x12:DTM">
        <productionDate>
          <xsl:call-template name="formatDate">
            <xsl:with-param name="date" select="x12:DTM/x12:DTM02"/>
          </xsl:call-template>
        </productionDate>
      </xsl:if>

      <payer>
        <name><xsl:value-of select="x12:Loop1000A/x12:N1/x12:N102"/></name>
        <identifier><xsl:value-of select="x12:Loop1000A/x12:N1/x12:N104"/></identifier>
        <xsl:if test="x12:Loop1000A/x12:N3">
          <address>
            <street><xsl:value-of select="x12:Loop1000A/x12:N3/x12:N301"/></street>
            <city><xsl:value-of select="x12:Loop1000A/x12:N4/x12:N401"/></city>
            <state><xsl:value-of select="x12:Loop1000A/x12:N4/x12:N402"/></state>
            <zip><xsl:value-of select="x12:Loop1000A/x12:N4/x12:N403"/></zip>
          </address>
        </xsl:if>
        <xsl:if test="x12:Loop1000A/x12:PER">
          <contact>
            <phone><xsl:value-of select="x12:Loop1000A/x12:PER/x12:PER04"/></phone>
          </contact>
        </xsl:if>
      </payer>

      <payee>
        <name><xsl:value-of select="x12:Loop1000B/x12:N1/x12:N102"/></name>
        <identifier><xsl:value-of select="x12:Loop1000B/x12:N1/x12:N104"/></identifier>
        <xsl:if test="x12:Loop1000B/x12:N3">
          <address>
            <street><xsl:value-of select="x12:Loop1000B/x12:N3/x12:N301"/></street>
            <city><xsl:value-of select="x12:Loop1000B/x12:N4/x12:N401"/></city>
            <state><xsl:value-of select="x12:Loop1000B/x12:N4/x12:N402"/></state>
            <zip><xsl:value-of select="x12:Loop1000B/x12:N4/x12:N403"/></zip>
          </address>
        </xsl:if>
      </payee>

      <claimPayments>
        <xsl:for-each select="x12:Loop2000/x12:Loop2100">
          <claimPayment>
            <claimId><xsl:value-of select="x12:CLP/x12:CLP01"/></claimId>
            <claimStatus>
              <xsl:call-template name="getClaimStatus">
                <xsl:with-param name="code" select="x12:CLP/x12:CLP02"/>
              </xsl:call-template>
            </claimStatus>
            <chargedAmount><xsl:value-of select="x12:CLP/x12:CLP03"/></chargedAmount>
            <paidAmount><xsl:value-of select="x12:CLP/x12:CLP04"/></paidAmount>
            <patientResponsibility><xsl:value-of select="x12:CLP/x12:CLP05"/></patientResponsibility>
            <claimFilingIndicator><xsl:value-of select="x12:CLP/x12:CLP06"/></claimFilingIndicator>
            <payerClaimControlNumber><xsl:value-of select="x12:CLP/x12:CLP07"/></payerClaimControlNumber>

            <xsl:if test="x12:CAS">
              <adjustments>
                <xsl:for-each select="x12:CAS">
                  <adjustment>
                    <groupCode>
                      <xsl:call-template name="getAdjustmentGroup">
                        <xsl:with-param name="code" select="x12:CAS01"/>
                      </xsl:call-template>
                    </groupCode>
                    <reasonCode><xsl:value-of select="x12:CAS02"/></reasonCode>
                    <amount><xsl:value-of select="x12:CAS03"/></amount>
                    <quantity><xsl:value-of select="x12:CAS04"/></quantity>
                  </adjustment>
                </xsl:for-each>
              </adjustments>
            </xsl:if>

            <xsl:if test="x12:NM1">
              <patient>
                <lastName><xsl:value-of select="x12:NM1[x12:NM101='QC']/x12:NM103"/></lastName>
                <firstName><xsl:value-of select="x12:NM1[x12:NM101='QC']/x12:NM104"/></firstName>
                <memberId><xsl:value-of select="x12:NM1[x12:NM101='QC']/x12:NM109"/></memberId>
              </patient>
            </xsl:if>

            <xsl:if test="x12:Loop2110">
              <serviceLines>
                <xsl:for-each select="x12:Loop2110">
                  <serviceLine>
                    <procedureCode><xsl:value-of select="x12:SVC/x12:SVC01/x12:SVC0102"/></procedureCode>
                    <modifier><xsl:value-of select="x12:SVC/x12:SVC01/x12:SVC0103"/></modifier>
                    <chargedAmount><xsl:value-of select="x12:SVC/x12:SVC02"/></chargedAmount>
                    <paidAmount><xsl:value-of select="x12:SVC/x12:SVC03"/></paidAmount>
                    <quantity><xsl:value-of select="x12:SVC/x12:SVC05"/></quantity>
                    <xsl:if test="x12:DTM">
                      <serviceDate>
                        <xsl:call-template name="formatDate">
                          <xsl:with-param name="date" select="x12:DTM[x12:DTM01='472']/x12:DTM02"/>
                        </xsl:call-template>
                      </serviceDate>
                    </xsl:if>
                    <xsl:if test="x12:CAS">
                      <adjustments>
                        <xsl:for-each select="x12:CAS">
                          <adjustment>
                            <groupCode><xsl:value-of select="x12:CAS01"/></groupCode>
                            <reasonCode><xsl:value-of select="x12:CAS02"/></reasonCode>
                            <amount><xsl:value-of select="x12:CAS03"/></amount>
                          </adjustment>
                        </xsl:for-each>
                      </adjustments>
                    </xsl:if>
                    <xsl:if test="x12:LQ">
                      <remarkCodes>
                        <xsl:for-each select="x12:LQ">
                          <remarkCode><xsl:value-of select="x12:LQ02"/></remarkCode>
                        </xsl:for-each>
                      </remarkCodes>
                    </xsl:if>
                  </serviceLine>
                </xsl:for-each>
              </serviceLines>
            </xsl:if>
          </claimPayment>
        </xsl:for-each>
      </claimPayments>

      <xsl:if test="x12:PLB">
        <providerAdjustments>
          <xsl:for-each select="x12:PLB">
            <providerAdjustment>
              <providerId><xsl:value-of select="x12:PLB01"/></providerId>
              <fiscalPeriodDate>
                <xsl:call-template name="formatDate">
                  <xsl:with-param name="date" select="x12:PLB02"/>
                </xsl:call-template>
              </fiscalPeriodDate>
              <adjustmentReasonCode><xsl:value-of select="x12:PLB03/x12:PLB0301"/></adjustmentReasonCode>
              <adjustmentAmount><xsl:value-of select="x12:PLB04"/></adjustmentAmount>
            </providerAdjustment>
          </xsl:for-each>
        </providerAdjustments>
      </xsl:if>

      <metadata>
        <transformVersion>1.0</transformVersion>
        <transactionType>835</transactionType>
        <sourceFormat>X12-005010X221A1</sourceFormat>
      </metadata>
    </remittanceAdvice>
  </xsl:template>

  <!-- Helper Templates -->
  <xsl:template name="formatDate">
    <xsl:param name="date"/>
    <xsl:if test="string-length($date) = 8">
      <xsl:value-of select="concat(substring($date,1,4),'-',substring($date,5,2),'-',substring($date,7,2))"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="getHandlingCode">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='C'">paymentAccompaniesRemittance</xsl:when>
      <xsl:when test="$code='D'">makePaymentOnly</xsl:when>
      <xsl:when test="$code='H'">notificationOnly</xsl:when>
      <xsl:when test="$code='I'">remittanceInformationOnly</xsl:when>
      <xsl:when test="$code='P'">prenotificationOfFutureTransfers</xsl:when>
      <xsl:when test="$code='U'">splitPaymentAndRemittance</xsl:when>
      <xsl:when test="$code='X'">handlingPartyOption</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getPaymentMethod">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='ACH'">automatedClearingHouse</xsl:when>
      <xsl:when test="$code='CHK'">check</xsl:when>
      <xsl:when test="$code='FWT'">federalReserveWireTransfer</xsl:when>
      <xsl:when test="$code='NON'">nonPaymentData</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getClaimStatus">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='1'">processed</xsl:when>
      <xsl:when test="$code='2'">processedSecondary</xsl:when>
      <xsl:when test="$code='3'">processedTertiary</xsl:when>
      <xsl:when test="$code='4'">denied</xsl:when>
      <xsl:when test="$code='19'">processedPrimary</xsl:when>
      <xsl:when test="$code='20'">processedSecondary</xsl:when>
      <xsl:when test="$code='21'">processedTertiary</xsl:when>
      <xsl:when test="$code='22'">reversal</xsl:when>
      <xsl:when test="$code='23'">notOurClaim</xsl:when>
      <xsl:otherwise>status_<xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getAdjustmentGroup">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='CO'">contractualObligation</xsl:when>
      <xsl:when test="$code='CR'">correction</xsl:when>
      <xsl:when test="$code='OA'">otherAdjustment</xsl:when>
      <xsl:when test="$code='PI'">payerInitiated</xsl:when>
      <xsl:when test="$code='PR'">patientResponsibility</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

