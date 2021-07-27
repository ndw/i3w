<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:array="http://www.w3.org/2005/xpath-functions/array"
                xmlns:f="https://nwalsh.com/ns/functions"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
                xmlns:js="http://saxonica.com/ns/globalJS"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="#all"
                version="3.0">

<xsl:output method="html" html-version="5" encoding="utf-8" indent="no"/>

<xsl:variable name="Z" select="xs:dayTimeDuration('PT0H')"/>

<xsl:key name="slot" match="div[@class='ProgramEvent']"
         use="span[@class='EventDateTime']/span[@class='Day']
              || '/'
              || span[@class='EventDateTime']/span[@class='timestart']"/>

<xsl:key name="id" match="*" use="@id"/>

<!-- ============================================================ -->

<xsl:template name="xsl:initial-template">
  <xsl:result-document href="#schedule" method="ixsl:replace-content">
    <xsl:apply-templates select="ixsl:page()/html/body/div[@id='schedule']"/>
  </xsl:result-document>
  <xsl:result-document href="#schedlink" method="ixsl:replace-content">
    <xsl:text>🖝 </xsl:text>
    <a href='#schedule'>Interactive schedule-at-a-glance</a>
  </xsl:result-document>
  <ixsl:set-style name="display" select="'block'"
                  object="ixsl:page()//p[@id='schedlink']"/>
</xsl:template>

<!-- ============================================================ -->

<xsl:template match="div[@id='schedule']">
  <xsl:apply-templates/>
  <ixsl:set-style name="display" select="'block'"/>
</xsl:template>

<xsl:template match="td[@data-slot]">
  <xsl:variable name="event" select="key('slot', @data-slot)"/>

  <xsl:copy>
    <xsl:apply-templates select="@* except @class"/>

    <xsl:choose>
      <xsl:when test="$event">
        <xsl:sequence select="f:event-class(@class, $event)"/>
        <xsl:apply-templates select="$event" mode="data-content"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="class"
                       select="normalize-space(@class || ' none')"/>
        <xsl:text>No talk scheduled.</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:copy>
</xsl:template>

<xsl:function name="f:event-class" as="attribute()?">
  <xsl:param name="class" as="attribute()?"/>
  <xsl:param name="event" as="element(h:div)"/>

  <xsl:choose>
    <xsl:when test="empty($event/h2[@class='Speakers']/a)">
      <xsl:attribute name="class"
                     select="normalize-space($class || ' lb')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="$class"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:template match="h:div" mode="data-content">
  <span class="title" title="{normalize-space(p[@class='blurb'])}">
    <xsl:sequence select="string(h2[@class='EventTitle'])"/>
  </span>
  <xsl:apply-templates select="h2[@class='Speakers']/a"/>
</xsl:template>

<xsl:template match="h2/a">
  <xsl:sequence select="if (empty(preceding-sibling::a))
                        then '—'
                        else ', '"/>
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:sequence select="span[@class='SpeakerName']"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="element()">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()">
  <xsl:copy/>
</xsl:template>

<!-- ============================================================ -->

<xsl:template mode="ixsl:onclick" match="input[@id='clock24']">
  <xsl:apply-templates select="ixsl:page()" mode="update-times"/>
</xsl:template>

<xsl:template mode="ixsl:onchange" match="select[@id='tz']">
  <xsl:apply-templates select="ixsl:page()" mode="update-times">
    <xsl:with-param name="changetz" select="true()"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="/" mode="update-times">
  <xsl:param name="changetz" select="false()"/>

  <xsl:variable name="zone" select="ixsl:get(//select[@id='tz'], 'value')"/>

  <xsl:variable name="hours"
                select="xs:integer(substring-before($zone, ':'))"/>
  <xsl:variable name="minutes"
                select="xs:integer(substring-after($zone, ':'))"/>

  <xsl:variable name="iso8601"
                select="(if ($hours lt 0) then '-' else '')
                        || 'PT' || abs($hours) || 'H' || $minutes || 'M'"/>

  <xsl:if test="$changetz">
    <ixsl:set-property name="checked" select="$hours ge 0" object="//input[@id='clock24']"/>
  </xsl:if>

  <xsl:variable name="ampm" select="not(ixsl:get(//input[@id='clock24'], 'checked'))"/>

  <xsl:variable name="format"
                select="if ($ampm)
                        then '[h1]:[m01][P]'
                        else '[H01]:[m01]'"/>

  <xsl:variable name="tz" select="xs:dayTimeDuration($iso8601)"/>
  <xsl:for-each select="//div[@id='schedule']//time">
    <xsl:variable name="conftime" select="xs:dateTime(@datetime)"/>
    <xsl:variable name="dt"
                  select="adjust-dateTime-to-timezone($conftime, $tz)"/>
    <xsl:result-document href="?." method="ixsl:replace-content">
      <xsl:choose>
        <xsl:when test="hours-from-dateTime($dt) = 0
                        and minutes-from-dateTime($dt) = 0">
          <xsl:text>midnight</xsl:text>
        </xsl:when>
        <xsl:when test="hours-from-dateTime($dt) = 12
                        and minutes-from-dateTime($dt) = 0">
          <xsl:sequence select="if ($ampm) then 'noon' else 'midday'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="format-dateTime($dt, $format)"/>
          <xsl:if test="day-from-dateTime($conftime) != day-from-dateTime($dt)">
            <br/>
            <xsl:text> (the next day)</xsl:text>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:result-document>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
