<?xml version="1.0" encoding="utf-8"?>
<!--
  X12 271 Eligibility Response to JSON Transform
  ============================================================================
  Transforms X12 271 Eligibility Response XML to JSON-friendly structure.
  Used for processing eligibility verification responses from payers.
  ============================================================================
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:x12="http://schemas.microsoft.com/BizTalk/EDI/X12/2006"
    exclude-result-prefixes="x12">

  <xsl:output method="xml" indent="yes" omit-xml-declaration="no"/>
  <xsl:template match="text()"/>

  <xsl:template match="/">
    <xsl:apply-templates select="x12:X12_005010X279A1_271"/>
  </xsl:template>

  <xsl:template match="x12:X12_005010X279A1_271">
    <eligibilityResponse>
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
        <responseDate>
          <xsl:call-template name="formatDate">
            <xsl:with-param name="date" select="x12:BHT/x12:BHT04"/>
          </xsl:call-template>
        </responseDate>
      </transactionInfo>

      <responses>
        <xsl:for-each select="x12:Loop2000A">
          <informationSource>
            <name><xsl:value-of select="x12:Loop2100A/x12:NM1/x12:NM103"/></name>
            <identifier><xsl:value-of select="x12:Loop2100A/x12:NM1/x12:NM109"/></identifier>
            <xsl:if test="x12:AAA">
              <errors>
                <xsl:for-each select="x12:AAA">
                  <error>
                    <validRequest><xsl:value-of select="x12:AAA01"/></validRequest>
                    <rejectReasonCode><xsl:value-of select="x12:AAA03"/></rejectReasonCode>
                    <followUpAction><xsl:value-of select="x12:AAA04"/></followUpAction>
                  </error>
                </xsl:for-each>
              </errors>
            </xsl:if>
          </informationSource>

          <xsl:for-each select="x12:Loop2000B">
            <informationReceiver>
              <name><xsl:value-of select="x12:Loop2100B/x12:NM1/x12:NM103"/></name>
              <identifier><xsl:value-of select="x12:Loop2100B/x12:NM1/x12:NM109"/></identifier>
            </informationReceiver>

            <xsl:for-each select="x12:Loop2000C">
              <subscriber>
                <xsl:if test="x12:TRN">
                  <traceNumber><xsl:value-of select="x12:TRN/x12:TRN02"/></traceNumber>
                </xsl:if>
                <lastName><xsl:value-of select="x12:Loop2100C/x12:NM1/x12:NM103"/></lastName>
                <firstName><xsl:value-of select="x12:Loop2100C/x12:NM1/x12:NM104"/></firstName>
                <memberId><xsl:value-of select="x12:Loop2100C/x12:NM1/x12:NM109"/></memberId>

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

                <xsl:if test="x12:Loop2100C/x12:INS">
                  <insuranceInfo>
                    <isSubscriber><xsl:value-of select="x12:Loop2100C/x12:INS/x12:INS01"/></isSubscriber>
                    <relationshipCode><xsl:value-of select="x12:Loop2100C/x12:INS/x12:INS02"/></relationshipCode>
                  </insuranceInfo>
                </xsl:if>

                <xsl:if test="x12:Loop2100C/x12:Loop2110C">
                  <eligibilityBenefits>
                    <xsl:for-each select="x12:Loop2100C/x12:Loop2110C">
                      <benefit>
                        <eligibilityInfo>
                          <xsl:call-template name="getEligibilityInfo">
                            <xsl:with-param name="code" select="x12:EB/x12:EB01"/>
                          </xsl:call-template>
                        </eligibilityInfo>
                        <xsl:if test="x12:EB/x12:EB02">
                          <coverageLevel>
                            <xsl:call-template name="getCoverageLevel">
                              <xsl:with-param name="code" select="x12:EB/x12:EB02"/>
                            </xsl:call-template>
                          </coverageLevel>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB03">
                          <serviceType>
                            <xsl:call-template name="getServiceType">
                              <xsl:with-param name="code" select="x12:EB/x12:EB03"/>
                            </xsl:call-template>
                          </serviceType>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB04">
                          <insuranceType><xsl:value-of select="x12:EB/x12:EB04"/></insuranceType>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB05">
                          <planCoverageDescription><xsl:value-of select="x12:EB/x12:EB05"/></planCoverageDescription>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB06">
                          <timePeriodQualifier>
                            <xsl:call-template name="getTimePeriod">
                              <xsl:with-param name="code" select="x12:EB/x12:EB06"/>
                            </xsl:call-template>
                          </timePeriodQualifier>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB07">
                          <monetaryAmount><xsl:value-of select="x12:EB/x12:EB07"/></monetaryAmount>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB08">
                          <percentage><xsl:value-of select="x12:EB/x12:EB08"/></percentage>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB09">
                          <quantityQualifier><xsl:value-of select="x12:EB/x12:EB09"/></quantityQualifier>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB10">
                          <quantity><xsl:value-of select="x12:EB/x12:EB10"/></quantity>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB11">
                          <authorizationRequired>
                            <xsl:choose>
                              <xsl:when test="x12:EB/x12:EB11='Y'">true</xsl:when>
                              <xsl:when test="x12:EB/x12:EB11='N'">false</xsl:when>
                              <xsl:otherwise><xsl:value-of select="x12:EB/x12:EB11"/></xsl:otherwise>
                            </xsl:choose>
                          </authorizationRequired>
                        </xsl:if>
                        <xsl:if test="x12:EB/x12:EB12">
                          <inPlanNetwork>
                            <xsl:choose>
                              <xsl:when test="x12:EB/x12:EB12='Y'">true</xsl:when>
                              <xsl:when test="x12:EB/x12:EB12='N'">false</xsl:when>
                              <xsl:otherwise><xsl:value-of select="x12:EB/x12:EB12"/></xsl:otherwise>
                            </xsl:choose>
                          </inPlanNetwork>
                        </xsl:if>
                        <xsl:if test="x12:DTP">
                          <dates>
                            <xsl:for-each select="x12:DTP">
                              <date>
                                <qualifier><xsl:value-of select="x12:DTP01"/></qualifier>
                                <value>
                                  <xsl:call-template name="formatDate">
                                    <xsl:with-param name="date" select="x12:DTP03"/>
                                  </xsl:call-template>
                                </value>
                              </date>
                            </xsl:for-each>
                          </dates>
                        </xsl:if>
                        <xsl:if test="x12:MSG">
                          <messages>
                            <xsl:for-each select="x12:MSG">
                              <message><xsl:value-of select="x12:MSG01"/></message>
                            </xsl:for-each>
                          </messages>
                        </xsl:if>
                      </benefit>
                    </xsl:for-each>
                  </eligibilityBenefits>
                </xsl:if>
              </subscriber>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:for-each>
      </responses>

      <metadata>
        <transformVersion>1.0</transformVersion>
        <transactionType>271</transactionType>
        <sourceFormat>X12-005010X279A1</sourceFormat>
      </metadata>
    </eligibilityResponse>
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
      <xsl:when test="$code='11'">response</xsl:when>
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

  <xsl:template name="getEligibilityInfo">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='1'">activeCoverage</xsl:when>
      <xsl:when test="$code='2'">activeFullRisk</xsl:when>
      <xsl:when test="$code='3'">activeServicesCapitated</xsl:when>
      <xsl:when test="$code='4'">activeServiceCapitatedPrimaryCare</xsl:when>
      <xsl:when test="$code='5'">activePendingInvestigation</xsl:when>
      <xsl:when test="$code='6'">inactive</xsl:when>
      <xsl:when test="$code='7'">inactivePendingEligibilityUpdate</xsl:when>
      <xsl:when test="$code='8'">inactivePendingInvestigation</xsl:when>
      <xsl:when test="$code='A'">coInsurance</xsl:when>
      <xsl:when test="$code='B'">coPay</xsl:when>
      <xsl:when test="$code='C'">deductible</xsl:when>
      <xsl:when test="$code='CB'">coverageBasis</xsl:when>
      <xsl:when test="$code='D'">benefitDescription</xsl:when>
      <xsl:when test="$code='E'">exclusions</xsl:when>
      <xsl:when test="$code='F'">limitations</xsl:when>
      <xsl:when test="$code='G'">outOfPocket</xsl:when>
      <xsl:when test="$code='H'">unlimitedCoverage</xsl:when>
      <xsl:when test="$code='I'">nonCovered</xsl:when>
      <xsl:when test="$code='J'">costContainment</xsl:when>
      <xsl:when test="$code='K'">reserve</xsl:when>
      <xsl:when test="$code='L'">primaryCareProvider</xsl:when>
      <xsl:when test="$code='M'">preExistingCondition</xsl:when>
      <xsl:when test="$code='MC'">managedCareCoverage</xsl:when>
      <xsl:when test="$code='N'">servicesRestrictedToFollowing</xsl:when>
      <xsl:when test="$code='O'">notDeemed</xsl:when>
      <xsl:when test="$code='P'">benefitDisclaimer</xsl:when>
      <xsl:when test="$code='Q'">secondSurgicalOpinion</xsl:when>
      <xsl:when test="$code='R'">otherOrAdditionalPayer</xsl:when>
      <xsl:when test="$code='S'">priorYearHistory</xsl:when>
      <xsl:when test="$code='T'">cardReported</xsl:when>
      <xsl:when test="$code='U'">contactFollowing</xsl:when>
      <xsl:when test="$code='V'">cannotProcess</xsl:when>
      <xsl:when test="$code='W'">otherSource</xsl:when>
      <xsl:when test="$code='X'">healthCareFacility</xsl:when>
      <xsl:when test="$code='Y'">spendDown</xsl:when>
      <xsl:otherwise>info_<xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getCoverageLevel">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='CHD'">childrenOnly</xsl:when>
      <xsl:when test="$code='DEP'">dependentsOnly</xsl:when>
      <xsl:when test="$code='ECH'">employeeAndChildren</xsl:when>
      <xsl:when test="$code='EMP'">employeeOnly</xsl:when>
      <xsl:when test="$code='ESP'">employeeAndSpouse</xsl:when>
      <xsl:when test="$code='FAM'">family</xsl:when>
      <xsl:when test="$code='IND'">individual</xsl:when>
      <xsl:when test="$code='SPC'">spouseAndChildren</xsl:when>
      <xsl:when test="$code='SPO'">spouseOnly</xsl:when>
      <xsl:otherwise><xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getServiceType">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='1'">medicalCare</xsl:when>
      <xsl:when test="$code='30'">healthBenefitPlanCoverage</xsl:when>
      <xsl:when test="$code='35'">dentalCare</xsl:when>
      <xsl:when test="$code='47'">hospitalInpatient</xsl:when>
      <xsl:when test="$code='48'">hospitalOutpatient</xsl:when>
      <xsl:when test="$code='88'">pharmacy</xsl:when>
      <xsl:when test="$code='98'">professionalPhysician</xsl:when>
      <xsl:otherwise>service_<xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="getTimePeriod">
    <xsl:param name="code"/>
    <xsl:choose>
      <xsl:when test="$code='6'">hour</xsl:when>
      <xsl:when test="$code='7'">day</xsl:when>
      <xsl:when test="$code='21'">years</xsl:when>
      <xsl:when test="$code='22'">serviceYear</xsl:when>
      <xsl:when test="$code='23'">calendarYear</xsl:when>
      <xsl:when test="$code='24'">yearToDate</xsl:when>
      <xsl:when test="$code='25'">contract</xsl:when>
      <xsl:when test="$code='26'">episode</xsl:when>
      <xsl:when test="$code='27'">visit</xsl:when>
      <xsl:when test="$code='28'">outlier</xsl:when>
      <xsl:when test="$code='29'">remaining</xsl:when>
      <xsl:when test="$code='30'">exceeded</xsl:when>
      <xsl:when test="$code='31'">notExceeded</xsl:when>
      <xsl:when test="$code='32'">lifetime</xsl:when>
      <xsl:when test="$code='33'">lifetimeRemaining</xsl:when>
      <xsl:when test="$code='34'">month</xsl:when>
      <xsl:when test="$code='35'">week</xsl:when>
      <xsl:when test="$code='36'">admission</xsl:when>
      <xsl:otherwise>period_<xsl:value-of select="$code"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

