<?xml version="1.0" encoding="utf-8"?>
<!--
  X12 837 Healthcare Claim to JSON Transform
  ============================================================================
  Transforms X12 837 Healthcare Claim XML to JSON-friendly structure.
  Supports both Professional (837P) and Institutional (837I) claims.
  ============================================================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:x12="http://schemas.microsoft.com/BizTalk/EDI/X12/2006"
    exclude-result-prefixes="x12">

  <xsl:output method="xml" indent="yes" omit-xml-declaration="no"/>
  <xsl:template match="text()"/>

  <xsl:template match="/">
    <xsl:apply-templates select="x12:X12_005010X222A1_837"/>
  </xsl:template>

  <xsl:template match="x12:X12_005010X222A1_837">
    <healthcareClaim>
      <transactionInfo>
        <transactionSetId><xsl:value-of select="x12:ST/x12:ST01"/></transactionSetId>
        <controlNumber><xsl:value-of select="x12:ST/x12:ST02"/></controlNumber>
        <hierarchicalStructure><xsl:value-of select="x12:BHT/x12:BHT01"/></hierarchicalStructure>
        <transactionPurpose>
          <xsl:call-template name="getTransactionPurpose">
            <xsl:with-param name="code" select="x12:BHT/x12:BHT02"/>
          </xsl:call-template>
        </transactionPurpose>
        <referenceId><xsl:value-of select="x12:BHT/x12:BHT03"/></referenceId>
        <creationDate>
          <xsl:call-template name="formatDate">
            <xsl:with-param name="date" select="x12:BHT/x12:BHT04"/>
          </xsl:call-template>
        </creationDate>
        <transactionType>
          <xsl:call-template name="getTransactionType">
            <xsl:with-param name="code" select="x12:BHT/x12:BHT06"/>
          </xsl:call-template>
        </transactionType>
      </transactionInfo>

      <submitter>
        <name><xsl:value-of select="x12:Loop1000A/x12:NM1/x12:NM103"/></name>
        <entityType>
          <xsl:call-template name="getEntityType">
            <xsl:with-param name="code" select="x12:Loop1000A/x12:NM1/x12:NM102"/>
          </xsl:call-template>
        </entityType>
        <identifierType><xsl:value-of select="x12:Loop1000A/x12:NM1/x12:NM108"/></identifierType>
        <identifier><xsl:value-of select="x12:Loop1000A/x12:NM1/x12:NM109"/></identifier>
        <xsl:if test="x12:Loop1000A/x12:PER">
          <contact>
            <name><xsl:value-of select="x12:Loop1000A/x12:PER/x12:PER02"/></name>
            <phone><xsl:value-of select="x12:Loop1000A/x12:PER/x12:PER04"/></phone>
          </contact>
        </xsl:if>
      </submitter>

      <receiver>
        <name><xsl:value-of select="x12:Loop1000B/x12:NM1/x12:NM103"/></name>
        <identifier><xsl:value-of select="x12:Loop1000B/x12:NM1/x12:NM109"/></identifier>
      </receiver>

      <claims>
        <xsl:for-each select="x12:Loop2000A">
          <xsl:for-each select="x12:Loop2000B">
            <xsl:for-each select="x12:Loop2300">
              <claim>
                <claimId><xsl:value-of select="x12:CLM/x12:CLM01"/></claimId>
                <totalChargeAmount><xsl:value-of select="x12:CLM/x12:CLM02"/></totalChargeAmount>
                <facilityCode><xsl:value-of select="x12:CLM/x12:CLM05/x12:CLM0501"/></facilityCode>
                <claimFrequency><xsl:value-of select="x12:CLM/x12:CLM05/x12:CLM0503"/></claimFrequency>
                
                <billingProvider>
                  <name><xsl:value-of select="../../x12:Loop2010AA/x12:NM1/x12:NM103"/></name>
                  <npi><xsl:value-of select="../../x12:Loop2010AA/x12:NM1/x12:NM109"/></npi>
                  <address>
                    <street><xsl:value-of select="../../x12:Loop2010AA/x12:N3/x12:N301"/></street>
                    <city><xsl:value-of select="../../x12:Loop2010AA/x12:N4/x12:N401"/></city>
                    <state><xsl:value-of select="../../x12:Loop2010AA/x12:N4/x12:N402"/></state>
                    <zip><xsl:value-of select="../../x12:Loop2010AA/x12:N4/x12:N403"/></zip>
                  </address>
                  <taxId><xsl:value-of select="../../x12:Loop2010AA/x12:REF[x12:REF01='EI']/x12:REF02"/></taxId>
                </billingProvider>

                <subscriber>
                  <lastName><xsl:value-of select="../x12:Loop2010BA/x12:NM1/x12:NM103"/></lastName>
                  <firstName><xsl:value-of select="../x12:Loop2010BA/x12:NM1/x12:NM104"/></firstName>
                  <memberId><xsl:value-of select="../x12:Loop2010BA/x12:NM1/x12:NM109"/></memberId>
                  <xsl:if test="../x12:Loop2010BA/x12:DMG">
                    <dateOfBirth>
                      <xsl:call-template name="formatDate">
                        <xsl:with-param name="date" select="../x12:Loop2010BA/x12:DMG/x12:DMG02"/>
                      </xsl:call-template>
                    </dateOfBirth>
                    <gender>
                      <xsl:call-template name="getGender">
                        <xsl:with-param name="code" select="../x12:Loop2010BA/x12:DMG/x12:DMG03"/>
                      </xsl:call-template>
                    </gender>
                  </xsl:if>
                  <xsl:if test="../x12:Loop2010BA/x12:N3">
                    <address>
                      <street><xsl:value-of select="../x12:Loop2010BA/x12:N3/x12:N301"/></street>
                      <city><xsl:value-of select="../x12:Loop2010BA/x12:N4/x12:N401"/></city>
                      <state><xsl:value-of select="../x12:Loop2010BA/x12:N4/x12:N402"/></state>
                      <zip><xsl:value-of select="../x12:Loop2010BA/x12:N4/x12:N403"/></zip>
                    </address>
                  </xsl:if>
                </subscriber>

                <payer>
                  <name><xsl:value-of select="../x12:Loop2010BB/x12:NM1/x12:NM103"/></name>
                  <payerId><xsl:value-of select="../x12:Loop2010BB/x12:NM1/x12:NM109"/></payerId>
                </payer>

                <xsl:if test="x12:HI">
                  <diagnoses>
                    <xsl:for-each select="x12:HI">
                      <xsl:if test="x12:HI01">
                        <diagnosis>
                          <codeType><xsl:value-of select="x12:HI01/x12:HI0101"/></codeType>
                          <code><xsl:value-of select="x12:HI01/x12:HI0102"/></code>
                          <qualifier>principal</qualifier>
                        </diagnosis>
                      </xsl:if>
                      <xsl:if test="x12:HI02">
                        <diagnosis>
                          <codeType><xsl:value-of select="x12:HI02/x12:HI0101"/></codeType>
                          <code><xsl:value-of select="x12:HI02/x12:HI0102"/></code>
                          <qualifier>secondary</qualifier>
                        </diagnosis>
                      </xsl:if>
                    </xsl:for-each>
                  </diagnoses>
                </xsl:if>

                <serviceLines>
                  <xsl:for-each select="x12:Loop2400">
                    <serviceLine>
                      <lineNumber><xsl:value-of select="x12:LX/x12:LX01"/></lineNumber>
                      <xsl:if test="x12:SV1">
                        <procedureCode><xsl:value-of select="x12:SV1/x12:SV101/x12:SV10102"/></procedureCode>
                        <modifier><xsl:value-of select="x12:SV1/x12:SV101/x12:SV10103"/></modifier>
                        <chargeAmount><xsl:value-of select="x12:SV1/x12:SV102"/></chargeAmount>
                        <unitOfMeasure><xsl:value-of select="x12:SV1/x12:SV103"/></unitOfMeasure>
                        <quantity><xsl:value-of select="x12:SV1/x12:SV104"/></quantity>
                        <placeOfService><xsl:value-of select="x12:SV1/x12:SV107"/></placeOfService>
                      </xsl:if>
                      <xsl:if test="x12:SV2">
                        <revenueCode><xsl:value-of select="x12:SV2/x12:SV201"/></revenueCode>
                        <procedureCode><xsl:value-of select="x12:SV2/x12:SV202/x12:SV20202"/></procedureCode>
                        <chargeAmount><xsl:value-of select="x12:SV2/x12:SV203"/></chargeAmount>
                        <unitOfMeasure><xsl:value-of select="x12:SV2/x12:SV204"/></unitOfMeasure>
                        <quantity><xsl:value-of select="x12:SV2/x12:SV205"/></quantity>
                      </xsl:if>
                      <xsl:for-each select="x12:DTP">
                        <serviceDate>
                          <xsl:call-template name="formatDate">
                            <xsl:with-param name="date" select="x12:DTP03"/>
                          </xsl:call-template>
                        </serviceDate>
                      </xsl:for-each>
                    </serviceLine>
                  </xsl:for-each>
                </serviceLines>
              </claim>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </claims>

      <metadata>
        <transformVersion>1.0</transformVersion>
        <transactionType>837</transactionType>
        <sourceFormat>X12-005010X222A1</sourceFormat>
      </metadata>
    </healthcareClaim>
  </xsl:template>

  <!-- Helper Templates -->
  <xsl:template name="formatDate">
    <xsl:param name="date"/>
    <xsl:if test="string-length($date) = 8">
      <xsl:value-of select="concat(substring($date,1,4),'-',substring($date,5,2),'-',substring($date,7,2))"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="getTransactionPurpose">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='00'">original</xsl:when>
      <xsl:when test="$code='18'">reissue</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getTransactionType">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='CH'">chargeable</xsl:when>
      <xsl:when test="$code='RP'">reporting</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getEntityType">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='1'">person</xsl:when>
      <xsl:when test="$code='2'">organization</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getGender">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='M'">male</xsl:when>
      <xsl:when test="$code='F'">female</xsl:when>
      <xsl:when test="$code='U'">unknown</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

