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
<xsl:variable name="UTC" select="adjust-dateTime-to-timezone(current-dateTime(), $Z)"/>
<xsl:variable name="first-day" select="xs:date('2021-07-31')"/>

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
    <xsl:apply-templates select="ixsl:page()//p[@class='controls']"
                         mode="ics"/>
  </xsl:result-document>
  <ixsl:set-style name="display" select="'block'"
                  object="ixsl:page()//p[@id='schedlink']"/>
</xsl:template>

<!-- ============================================================ -->

<xsl:template match="p" mode="ics">
  <xsl:variable name="vtimezone" as="xs:string">BEGIN:VTIMEZONE
TZID:America/New_York
BEGIN:DAYLIGHT
TZOFFSETFROM:-0500
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU
DTSTART:20070311T020000
TZNAME:EDT
TZOFFSETTO:-0400
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:-0400
RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU
DTSTART:20071104T020000
TZNAME:EST
TZOFFSETTO:-0500
END:STANDARD
END:VTIMEZONE
</xsl:variable>

  <xsl:variable name="vevents" as="xs:string*">
    <xsl:apply-templates select="//div[@class='ProgramEvent']" mode="ics"/>
  </xsl:variable>

  <xsl:variable name="calendar" as="xs:string*">BEGIN:VCALENDAR
METHOD:PUBLISH
VERSION:2.0
X-WR-CALNAME:Balisage 2021
PRODID:-//Apple Inc.//macOS 11.4//EN
X-WR-TIMEZONE:America/New_York
CALSCALE:GREGORIAN
<xsl:sequence select="$vtimezone"/>
<xsl:sequence select="string-join($vevents,'&#10;')"/>
END:VCALENDAR</xsl:variable>

  <xsl:text> (</xsl:text>
  <a href="data:text/ics;charset=utf-8,{encode-for-uri(string-join($calendar, ''))}"
       target="_blank" download="Balisage-2021.ics">ICS</a>
  <xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="div[@class='ProgramEvent']" mode="ics" as="xs:string">
  <xsl:variable name="day"
                select="ancestor::div[@class='Program-Day']"/>
  <xsl:variable name="daypos"
                select="count($day/preceding-sibling::div[@class='Program-Day'])"/>

  <xsl:variable name="dtstamp"
                select="format-dateTime($UTC, '[Y0001][M01][D01]T[h01][m01][s01]Z')"/>

  <xsl:variable name="ts"
                select="tokenize(substring(span/span[@class='timestart'], 1 , 5), ':')"/>
  <xsl:variable name="te"
                select="tokenize(substring(span/span[@class='timeend'], 1, 5), ':')"/>

  <xsl:variable name="date" select="$first-day + xs:dayTimeDuration('P'||$daypos||'D')"/>

  <xsl:variable name="dtstart"
                select="format-date($date, '[Y0001][M01][D01]T')
                        || $ts[1] || $ts[2] || '00'"/>

  <xsl:variable name="dtend"
                select="format-date($date, '[Y0001][M01][D01]T')
                        || $te[1] || $te[2] || '00'"/>


  <xsl:variable name="speakers" as="xs:string*"
                select=".//span[@class='SpeakerName']"/>

  <xsl:variable name="speakers" as="xs:string*">
    <xsl:for-each select="$speakers">
      <xsl:if test="position() gt 1 and count($speakers) gt 2">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:if test="position() gt 1 and position() = last()">
        <xsl:text> and </xsl:text>
      </xsl:if>
      <xsl:sequence select="."/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="description" as="xs:string*">
    <xsl:sequence select="string-join($speakers, '')"/>
    <xsl:sequence select="normalize-space(p[@class='blurb'])"/>
  </xsl:variable>

  <xsl:variable name="event" as="node()">
    <xsl:text expand-text="yes">BEGIN:VEVENT
TRANSP:OPAQUE
DTSTAMP:{$dtstamp}
UID:{f:uuid(@id)}
DTSTART;TZID=America/New_York:{$dtstart}
DTEND;TZID=America/New_York:{$dtend}
DESCRIPTION:{string-join($description, '\n\n')}
URL;VALUE=URI:https://www.balisage.net/2021/Program.html#{@id}
SEQUENCE:1
SUMMARY:{normalize-space(h2[@class='EventTitle'])}
LAST-MODIFIED:{$dtstamp}
CREATED:{$dtstamp}
END:VEVENT</xsl:text>
  </xsl:variable>

  <xsl:sequence select="string($event)"/>
</xsl:template>

<xsl:function name="f:uuid" as="xs:string">
  <xsl:param name="seed" as="xs:string"/>

  <xsl:variable name="hexdigits" select="('0', '1', '2', '3', '4', '5', '6', '7',
                                          '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')"/>

  <xsl:variable name="hexstring" as="xs:string">
    <xsl:iterate select="1 to 32">
      <xsl:param name="digits" select="''"/>
      <xsl:param name="random" select="random-number-generator($seed)"/>
      <xsl:on-completion select="$digits"/>

      <xsl:variable name="hex" select="floor($random?number * 16) + 1"/>

      <xsl:next-iteration>
        <xsl:with-param name="digits" select="$digits || subsequence($hexdigits, $hex, 1)"/>
        <xsl:with-param name="random" select="$random?next()"/>
      </xsl:next-iteration>
    </xsl:iterate>
  </xsl:variable>

  <xsl:sequence select="substring($hexstring, 1, 8)
                        || '-'
                        || substring($hexstring, 9, 4)
                        || '-'
                        || substring($hexstring, 13, 4)
                        || '-'
                        || substring($hexstring, 17, 4)
                        || '-'
                        || substring($hexstring, 21)"/>

</xsl:function>

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
