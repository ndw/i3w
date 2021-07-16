<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="h xs"
                version="3.0">

<xsl:output method="xhtml" encoding="utf-8" indent="no"/>

<xsl:template match="/">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="element()">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()">
  <xsl:copy/>
</xsl:template>

<xsl:template match="h:html">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
    <script type="text/javascript" src="js/ptime.js"></script>
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
