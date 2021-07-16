<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xf="http://www.w3.org/2002/xforms" 
		xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
		xmlns:xhtml="http://www.w3.org/1999/xhtml" 
		version="1.0">
  <!-- Stylesheet to do nothing but extract the appropriate
       title and author links.  Very much pull style. -->

  <xsl:output method="html"/>
  
  <!-- 'slot' parameter has a form like 'Monday/10:00'.  Our job
       is to parse it into day and time, find the matching
       program event, and return the title and authors (with bio links
       and inter-author commas) in HTML. -->  
  <xsl:param name="slot" select=" 'Monday/11:00' "/>
  <xsl:param name="day" select="substring-before($slot, '/')"/>
  <xsl:param name="time" select="substring-after($slot, '/')"/>

  <xsl:template match="/">
    <xsl:variable name="e"
		  select="//xhtml:div[@class='ProgramEvent']
			  [xhtml:span[@class='EventDateTime']
			  [xhtml:span[@class='Day' and string() = $day]]
			  [xhtml:span[@class='timestart' and string() = $time]]
			  ]"/>

    <xsl:choose>
      <xsl:when test="count($e) > 0">
	<div>
	  <xsl:choose>
	    <xsl:when test="$e/xhtml:h2[@class='Speakers']
			    /xhtml:a[@class='biolink']">
	      <xsl:attribute name="class">talk</xsl:attribute>
	    </xsl:when>
	    <xsl:otherwise>
	      <xsl:attribute name="class">lb</xsl:attribute>
	    </xsl:otherwise>
	  </xsl:choose>	  
	  <xsl:apply-templates select="$e/xhtml:h2[@class='EventTitle']"/>
	  <xsl:apply-templates select="$e/xhtml:h2[@class='Speakers']"/>
	</div>
      </xsl:when>
      <xsl:otherwise>
	<div class="none">No talk scheduled.</div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="xhtml:h2[@class='EventTitle']">
    <span class="title">
      <xsl:attribute name="title">
	<xsl:value-of select="string(../xhtml:p[@class='blurb'])"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="xhtml:h2[@class='Speakers']">
    <xsl:apply-templates select="xhtml:a[@class='biolink']"/>
  </xsl:template>

  <xsl:template match="xhtml:h2[@class='Speakers']/xhtml:a[@class='biolink']">

    <xsl:choose>
      <xsl:when test="preceding-sibling::xhtml:a">
	<span>, </span>
      </xsl:when>
      <xsl:otherwise>
	<span> &#x2014; </span>
      </xsl:otherwise>
    </xsl:choose>
	
    <a>
      <xsl:attribute name="href">
	<xsl:value-of select="concat('http://Balisage.net/2020/', @href)"/>
      </xsl:attribute>
      <xsl:attribute name="title">
	<xsl:value-of select="string(following-sibling::xhtml:span[@class='affil'][1])"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>
</xsl:stylesheet>
