<?xml version="1.0" encoding="utf-8"?>
<!--
  X12 270 Eligibility Inquiry to JSON Transform
  ============================================================================
  Transforms X12 270 Eligibility Inquiry XML to JSON-friendly structure.
  Used for processing eligibility verification requests.
  ============================================================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:x12="http://schemas.microsoft.com/BizTalk/EDI/X12/2006"
    exclude-result-prefixes="x12">

  <xsl:output method="xml" indent="yes" omit-xml-declaration="no"/>
  <xsl:template match="text()"/>

  <xsl:template match="/">
    <xsl:apply-templates select="x12:X12_005010X279A1_270"/>
  </xsl:template>

  <xsl:template match="x12:X12_005010X279A1_270">
    <eligibilityInquiry>
      <transactionInfo>
        <transactionSetId><xsl:value-of select="x12:ST/x12:ST01"/></transactionSetId>
        <controlNumber><xsl:value-of select="x12:ST/x12:ST02"/></controlNumber>
        <hierarchicalStructure><xsl:value-of select="x12:BHT/x12:BHT01"/></hierarchicalStructure>
        <transactionPurpose>
          <xsl:call-template name="getPurpose">
            <xsl:with-param name="code" select="x12:BHT/x12:BHT02"/>
          </xsl:call-template>
        </transactionPurpose>
        <referenceId><xsl:value-of select="x12:BHT/x12:BHT03"/></referenceId>
        <transactionDate>
          <xsl:call-template name="formatDate">
            <xsl:with-param name="date" select="x12:BHT/x12:BHT04"/>
          </xsl:call-template>
        </transactionDate>
      </transactionInfo>

      <inquiries>
        <xsl:for-each select="x12:Loop2000A">
          <informationSource>
            <name><xsl:value-of select="x12:Loop2100A/x12:NM1/x12:NM103"/></name>
            <entityType>
              <xsl:call-template name="getEntityType">
                <xsl:with-param name="code" select="x12:Loop2100A/x12:NM1/x12:NM102"/>
              </xsl:call-template>
            </entityType>
            <identifier><xsl:value-of select="x12:Loop2100A/x12:NM1/x12:NM109"/></identifier>
          </informationSource>

          <xsl:for-each select="x12:Loop2000B">
            <informationReceiver>
              <name><xsl:value-of select="x12:Loop2100B/x12:NM1/x12:NM103"/></name>
              <entityType>
                <xsl:call-template name="getEntityType">
                  <xsl:with-param name="code" select="x12:Loop2100B/x12:NM1/x12:NM102"/>
                </xsl:call-template>
              </entityType>
              <identifier><xsl:value-of select="x12:Loop2100B/x12:NM1/x12:NM109"/></identifier>
              <xsl:if test="x12:Loop2100B/x12:PRV">
                <providerInfo>
                  <providerType><xsl:value-of select="x12:Loop2100B/x12:PRV/x12:PRV01"/></providerType>
                  <taxonomyCode><xsl:value-of select="x12:Loop2100B/x12:PRV/x12:PRV03"/></taxonomyCode>
                </providerInfo>
              </xsl:if>
            </informationReceiver>

            <xsl:for-each select="x12:Loop2000C">
              <subscriber>
                <xsl:if test="x12:TRN">
                  <traceNumber><xsl:value-of select="x12:TRN/x12:TRN02"/></traceNumber>
                </xsl:if>
                <lastName><xsl:value-of select="x12:Loop2100C/x12:NM1/x12:NM103"/></lastName>
                <firstName><xsl:value-of select="x12:Loop2100C/x12:NM1/x12:NM104"/></firstName>
                <middleName><xsl:value-of select="x12:Loop2100C/x12:NM1/x12:NM105"/></middleName>
                <memberId><xsl:value-of select="x12:Loop2100C/x12:NM1/x12:NM109"/></memberId>
                <xsl:if test="x12:Loop2100C/x12:REF">
                  <references>
                    <xsl:for-each select="x12:Loop2100C/x12:REF">
                      <reference>
                        <qualifier><xsl:value-of select="x12:REF01"/></qualifier>
                        <value><xsl:value-of select="x12:REF02"/></value>
                      </reference>
                    </xsl:for-each>
                  </references>
                </xsl:if>
                <xsl:if test="x12:Loop2100C/x12:N3">
                  <address>
                    <street><xsl:value-of select="x12:Loop2100C/x12:N3/x12:N301"/></street>
                    <city><xsl:value-of select="x12:Loop2100C/x12:N4/x12:N401"/></city>
                    <state><xsl:value-of select="x12:Loop2100C/x12:N4/x12:N402"/></state>
                    <zip><xsl:value-of select="x12:Loop2100C/x12:N4/x12:N403"/></zip>
                  </address>
                </xsl:if>
                <xsl:if test="x12:Loop2100C/x12:DMG">
                  <demographics>
                    <dateOfBirth>
                      <xsl:call-template name="formatDate">
                        <xsl:with-param name="date" select="x12:Loop2100C/x12:DMG/x12:DMG02"/>
                      </xsl:call-template>
                    </dateOfBirth>
                    <gender>
                      <xsl:call-template name="getGender">
                        <xsl:with-param name="code" select="x12:Loop2100C/x12:DMG/x12:DMG03"/>
                      </xsl:call-template>
                    </gender>
                  </demographics>
                </xsl:if>
                <xsl:if test="x12:Loop2100C/x12:Loop2110C">
                  <eligibilityInquiries>
                    <xsl:for-each select="x12:Loop2100C/x12:Loop2110C">
                      <inquiry>
                        <serviceTypeCode><xsl:value-of select="x12:EQ/x12:EQ01"/></serviceTypeCode>
                        <serviceType>
                          <xsl:call-template name="getServiceType">
                            <xsl:with-param name="code" select="x12:EQ/x12:EQ01"/>
                          </xsl:call-template>
                        </serviceType>
                        <xsl:if test="x12:EQ/x12:EQ02">
                          <procedureCode><xsl:value-of select="x12:EQ/x12:EQ02/x12:EQ0202"/></procedureCode>
                        </xsl:if>
                        <xsl:if test="x12:DTP">
                          <dateRange>
                            <xsl:call-template name="formatDate">
                              <xsl:with-param name="date" select="x12:DTP/x12:DTP03"/>
                            </xsl:call-template>
                          </dateRange>
                        </xsl:if>
                      </inquiry>
                    </xsl:for-each>
                  </eligibilityInquiries>
                </xsl:if>

                <xsl:if test="x12:Loop2000D">
                  <dependents>
                    <xsl:for-each select="x12:Loop2000D">
                      <dependent>
                        <lastName><xsl:value-of select="x12:Loop2100D/x12:NM1/x12:NM103"/></lastName>
                        <firstName><xsl:value-of select="x12:Loop2100D/x12:NM1/x12:NM104"/></firstName>
                        <xsl:if test="x12:Loop2100D/x12:DMG">
                          <dateOfBirth>
                            <xsl:call-template name="formatDate">
                              <xsl:with-param name="date" select="x12:Loop2100D/x12:DMG/x12:DMG02"/>
                            </xsl:call-template>
                          </dateOfBirth>
                          <gender>
                            <xsl:call-template name="getGender">
                              <xsl:with-param name="code" select="x12:Loop2100D/x12:DMG/x12:DMG03"/>
                            </xsl:call-template>
                          </gender>
                        </xsl:if>
                      </dependent>
                    </xsl:for-each>
                  </dependents>
                </xsl:if>
              </subscriber>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </inquiries>

      <metadata>
        <transformVersion>1.0</transformVersion>
        <transactionType>270</transactionType>
        <sourceFormat>X12-005010X279A1</sourceFormat>
      </metadata>
    </eligibilityInquiry>
  </xsl:template>

  <!-- Helper Templates -->
  <xsl:template name="formatDate">
    <xsl:param name="date"/>
    <xsl:if test="string-length($date) = 8">
      <xsl:value-of select="concat(substring($date,1,4),'-',substring($date,5,2),'-',substring($date,7,2))"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="getPurpose">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='13'">request</xsl:when>
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

  <xsl:template name="getServiceType">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='1'">medicalCare</xsl:when>
      <xsl:when test="$code='2'">surgical</xsl:when>
      <xsl:when test="$code='3'">consultation</xsl:when>
      <xsl:when test="$code='4'">diagnosticXRay</xsl:when>
      <xsl:when test="$code='5'">diagnosticLab</xsl:when>
      <xsl:when test="$code='6'">radiationTherapy</xsl:when>
      <xsl:when test="$code='7'">anesthesia</xsl:when>
      <xsl:when test="$code='12'">durableMedicalEquipment</xsl:when>
      <xsl:when test="$code='14'">renalDialysis</xsl:when>
      <xsl:when test="$code='30'">healthBenefitPlanCoverage</xsl:when>
      <xsl:when test="$code='33'">chiropractic</xsl:when>
      <xsl:when test="$code='35'">dentalCare</xsl:when>
      <xsl:when test="$code='42'">homeHealthCare</xsl:when>
      <xsl:when test="$code='47'">hospitalInpatient</xsl:when>
      <xsl:when test="$code='48'">hospitalOutpatient</xsl:when>
      <xsl:when test="$code='50'">hospitalEmergencyMedical</xsl:when>
      <xsl:when test="$code='51'">hospitalEmergencyRoom</xsl:when>
      <xsl:when test="$code='52'">hospitalAmbulatory</xsl:when>
      <xsl:when test="$code='53'">hospitalSurgical</xsl:when>
      <xsl:when test="$code='86'">emergencyServices</xsl:when>
      <xsl:when test="$code='88'">pharmacy</xsl:when>
      <xsl:when test="$code='98'">professionalPhysician</xsl:when>
      <xsl:otherwise>serviceType_<xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

