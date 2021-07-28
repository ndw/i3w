<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:e="http://www.w3.org/1999/XSL/Spec/ElementSyntax"
                xmlns:m="http://docbook.org/ns/docbook/modes"
                xmlns:v="http://docbook.org/ns/docbook/variables"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="#all"
                version="3.0">

<!--
<xsl:import href="https://cdn.docbook.org/release/xsltng/current/xslt/docbook.xsl"/>
-->
<xsl:import href="/Users/ndw/projects/docbook/xslTNG/build/xslt/docbook.xsl"/>

<xsl:output method="html" html-version="5" encoding="utf-8" indent="no"/>

<xsl:param name="persistent-toc" select="'true'"/>

<xsl:param name="css-links"
           select="'css/docbook.css css/docbook-screen.css css/presentation.css'"/>

<xsl:variable name="v:templates" as="document-node()">
  <xsl:document>
    <db:article xmlns:tmp="http://docbook.org/ns/docbook/templates"
                context="empty(parent::*)">
      <header>
        <tmp:apply-templates select="db:title">
          <h1><tmp:content/></h1>
        </tmp:apply-templates>
        <tmp:apply-templates select="db:subtitle">
          <h2><tmp:content/></h2>
        </tmp:apply-templates>
        <tmp:apply-templates select="db:author">
          <div class="author">
            <h3><tmp:content/></h3>
            <tmp:apply-templates select="db:affiliation">
              <p class="affiliation"><tmp:content/></p>
            </tmp:apply-templates>
          </div>
        </tmp:apply-templates>
        <tmp:apply-templates select="db:pubdate">
          <p class="pubdate"><tmp:content/></p>
        </tmp:apply-templates>
        <tmp:apply-templates select="db:abstract"/>
      </header>
    </db:article>
  </xsl:document>
</xsl:variable>

<xsl:template match="db:affiliation" mode="m:titlepage">
  <xsl:apply-templates select="db:orgname/node()" mode="m:docbook"/>
</xsl:template>

<xsl:template match="db:chapter" mode="m:headline-label">
  <xsl:param name="purpose" as="xs:string" select="'title'"/>
  <xsl:param name="number" as="node()*" required="yes"/>
  <xsl:param name="title" as="node()*" required="yes"/>
  <xsl:sequence select="()"/>
</xsl:template>

</xsl:stylesheet>
