<xsl:stylesheet version="1.0"
  xmlns:mods="http://www.loc.gov/mods/v3"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:java="http://xml.apache.org/xalan/java"
    exclude-result-prefixes="java mods">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  
  <!-- Basic MODS -->
  <xsl:template match="mods:mods" name="index_mods" mode="default">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
  
    
    <!-- Index stuff from the auth-module. -->
    <xsl:for-each select=".//*[@authorityURI='info:fedora'][@valueURI]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'related_object', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="@valueURI"/>
      </field>
    </xsl:for-each>
    
    <xsl:apply-templates>
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:apply-templates>
  </xsl:template>

  <!--************************************ MODS subset for Bibliographies ******************************************-->

  <!-- Main Title, with non-sorting prefixes -->
  <!--  bit of a hack, to make sortable -->
  <xsl:template match="mods:titleInfo[1]">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="base_title" select="normalize-space(mods:title/text())"/>
    <xsl:variable name="non_sort" select="normalize-space(mods:nonSort/text())"/>
    <xsl:variable name="sub_title" select="normalize-space(mods:subTitle/text())"/>

    <xsl:call-template name="title_info">
      <xsl:with-param name="base_title" select="$base_title"/>
      <xsl:with-param name="non_sort" select="$non_sort"/>
      <xsl:with-param name="sub_title" select="$sub_title"/>
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix">_mlt</xsl:with-param>
    </xsl:call-template>
    
    <xsl:call-template name="title_info">
      <xsl:with-param name="base_title" select="$base_title"/>
      <xsl:with-param name="non_sort" select="$non_sort"/>
      <xsl:with-param name="sub_title" select="$sub_title"/>
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:call-template>
  </xsl:template>
  
  <!--  index other main titles -->
  <xsl:template match="mods:titleInfo">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="base_title" select="normalize-space(mods:title/text())"/>
    <xsl:variable name="non_sort" select="normalize-space(mods:nonSort/text())"/>
    <xsl:variable name="sub_title" select="normalize-space(mods:subTitle/text())"/>
    <xsl:variable name="type" select="normalize-space(@type)"/>

    <xsl:call-template name="title_info">
      <xsl:with-param name="node" select="current()"/>
      <xsl:with-param name="base_title" select="$base_title"/>
      <xsl:with-param name="non_sort" select="$non_sort"/>
      <xsl:with-param name="sub_title" select="$sub_title"/>
      <xsl:with-param name="type" select="$type"/>
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:call-template>
    
    <!-- bit of a hack so it can be sorted on... -->
    <xsl:if test="position()=1">
      <xsl:call-template name="title_info">
        <xsl:with-param name="node" select="current()"/>
        <xsl:with-param name="base_title" select="$base_title"/>
        <xsl:with-param name="non_sort" select="$non_sort"/>
        <xsl:with-param name="sub_title" select="$sub_title"/>
        <xsl:with-param name="type" select="$type"/>
        <xsl:with-param name="prefix" select="$prefix"/>
        <xsl:with-param name="suffix">_mlt</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="title_info">
    <xsl:param name="node" select="node()"/>
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    <xsl:param name="base_title" select="normalize-space($node/mods:title/text())"/>
    <xsl:param name="non_sort" select="normalize-space($node/mods:nonSort/text())"/>
    <xsl:param name="sub_title" select="normalize-space($node/mods:subTitle/text())"/>
    <xsl:param name="type" select="normalize-space($node/@type)"/>
    
    <xsl:if test="$base_title">
      <field>
        <xsl:attribute name="name">
          <xsl:choose>
            <xsl:when test="$type">
              <xsl:value-of select="concat($prefix, 'title_', $type, $suffix)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat($prefix, 'title_local', $suffix)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:call-template name="title_info_title">
          <xsl:with-param name="node" select="$node"/>
          <xsl:with-param name="base_title" select="$base_title"/>
          <xsl:with-param name="non_sort" select="$non_sort"/>
          <xsl:with-param name="sub_title" select="$sub_title"/>
        </xsl:call-template>
      </field>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="title_info_title">
    <xsl:param name="node"/>
    <xsl:param name="base_title" select="normalize-space($node/mods:title/text())"/>
    <xsl:param name="non_sort" select="normalize-space($node/mods:nonSort/text())"/>
    <xsl:param name="sub_title" select="normalize-space($node/mods:subTitle/text())"/>
    
    <xsl:if test="$base_title">
      <!-- grab the first character, uppercase it, and concat stuff back together -->
      <xsl:variable name="first_temp" select="java:substring($base_title, 0, 1)"/>
      <xsl:variable name="first" select="java:toUpperCase($first_temp)"/>
      <xsl:variable name="remaining" select="java:substring($base_title, 1)"/>
      <xsl:value-of select="concat($first, $remaining)"/>
      <xsl:if test="$sub_title">
        <xsl:text>: </xsl:text>
        <xsl:value-of select="$sub_title"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Sub-title -->
  <xsl:template match="mods:subTitle">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
    </xsl:if>
  </xsl:template>

  <!-- Abstract -->
  <xsl:template match="mods:abstract">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
    </xsl:if>
  </xsl:template>

    <!-- Genre (a.k.a. specific doctype) -->
  <xsl:template match="mods:genre">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="authority">
      <xsl:choose>
        <xsl:when test="@authority">
          <xsl:value-of select="concat('_', @authority)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>_local_authority</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $authority, $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
    </xsl:if>
  </xsl:template>

    <!--  Resource Type (a.k.a. broad doctype) -->
  <xsl:template match="mods:typeOfResource">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, 'resource_type', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
    </xsl:if>
  </xsl:template>

    <!-- DOI, ISSN, ISBN, and any other typed IDs -->
  <xsl:template match="mods:identifier">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="@type">
          <xsl:value-of select="normalize-space(@type)"/>
        </xsl:when>
        <xsl:otherwise>local</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_', $type, $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
    </xsl:if>
  </xsl:template>

  <!--  index a name -->
  <xsl:template match="mods:name">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="role" select="normalize-space(mods:role/mods:roleTerm/text())"/>
    <xsl:variable name="spec">
      <xsl:choose>
        <xsl:when test="$role">
          <xsl:value-of select="concat('_', $role)"/>
        </xsl:when>
        <xsl:when test="@usage and @type">
          <xsl:value-of select="concat('_', @usage, '_', @type)"/>
        </xsl:when>
        <xsl:when test="@usage">
          <xsl:value-of select="concat('_', @usage)"/>
        </xsl:when>
        <xsl:when test="@type">
          <xsl:value-of select="concat('_', @type)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'name', $spec, $suffix)"/>
      </xsl:attribute>

      <xsl:call-template name="name_parts_given_first">
        <xsl:with-param name="node" select="current()"/>
      </xsl:call-template>
    </field>
    
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'rname', $spec, $suffix)"/>
      </xsl:attribute>

      <xsl:call-template name="name_parts_given_last">
        <xsl:with-param name="node" select="current()"/>
      </xsl:call-template>
    </field>
    
    <xsl:for-each select="mods:displayForm">
      <xsl:variable name="text_value" select="normalize-space(text())"/>
      <xsl:if test="$text_value">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, 'name_', $spec, '_', local-name(), $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="$text_value"/>
        </field>
      </xsl:if>
    </xsl:for-each>
    
    <xsl:variable name="associated_spec">
      <xsl:choose>
        <xsl:when test="@type">
          <xsl:text>_</xsl:text>
          <xsl:value-of select="@type"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- nothing doing -->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'name_associated', $associated_spec, $suffix)"/>
      </xsl:attribute>

      <xsl:call-template name="name_parts_given_first">
        <xsl:with-param name="node" select="current()"/>
      </xsl:call-template>
    </field>
    
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'rname_associated', $associated_spec, $suffix)"/>
      </xsl:attribute>

      <xsl:call-template name="name_parts_given_last">
        <xsl:with-param name="node" select="current()"/>
      </xsl:call-template>
    </field>
  </xsl:template>
  
  <xsl:template name="name_parts_given_last">
    <xsl:param name="node"/>
    
    <xsl:for-each select="$node/mods:namePart[@type='family']">
      <xsl:variable name="text_value" select="normalize-space(text())"/>
      <xsl:if test="$text_value">
        <xsl:value-of select="$text_value"/>
        <xsl:choose>
          <xsl:when test="position()!=last()">
            <xsl:text> </xsl:text>
          </xsl:when>
          <xsl:when test="position()=last() and $node/mods:namePart[not(@type='family')]">
            <xsl:text>, </xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:for-each>
      
    <xsl:for-each select="$node/mods:namePart[@type='given']">
      <xsl:variable name="text_value" select="normalize-space(text())"/>
      <xsl:if test="$text_value">
        <xsl:value-of select="$text_value"/>
        <xsl:if test="string-length($text_value)=1">
          <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="position()!=last()">
            <xsl:text> </xsl:text>
          </xsl:when>
          <xsl:when test="position()=last() and $node/mods:namePart[not(@type='family' or @type='given')]">
            <xsl:text>, </xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:for-each>
    
    <xsl:for-each select="$node/mods:namePart[not(@type='family' or @type='given')]">
      <xsl:variable name="text_value" select="normalize-space(text())"/>
      <xsl:if test="$text_value">
        <xsl:value-of select="normalize-space(text())"/>
        <xsl:if test="position()!=last()">
          <xsl:text>, </xsl:text>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="name_parts_given_first">
    <xsl:param name="node"/>
    
    <!--  given name -->
    <xsl:for-each select="$node/mods:namePart[@type='given']">
      <xsl:variable name="text_value" select="normalize-space(text())"/>
      <xsl:if test="$text_value">
        <xsl:value-of select="$text_value"/>
        
        <!--  use as an initial -->
        <xsl:if test="string-length($text_value)=1">
          <xsl:text>.</xsl:text>
        </xsl:if>
        <xsl:text> </xsl:text>
      </xsl:if>
    </xsl:for-each>
    
    <xsl:for-each select="$node/mods:namePart[@type='family']">
      <xsl:variable name="text_value" select="normalize-space(text())"/>
      <xsl:if test="$text_value">
        <xsl:value-of select="$text_value"/>
        <xsl:if test="position()!=last()">
          <xsl:text> </xsl:text>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
      
    <!-- Other parts -->
    <xsl:for-each select="$node/mods:namePart[not(@type='given' or @type='family')]">
      <xsl:variable name="text_value" select="normalize-space(text())"/>
      <xsl:if test="$text_value">
        <xsl:value-of select="$text_value"/>
        <xsl:if test="position()!=last()">
          <xsl:text> </xsl:text>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

    <!-- Notes -->
  <xsl:template match="mods:note | mods:topic | mods:geographic | mods:temporal | 
    mods:occupation | mods:continent | mods:country | mods:province | mods:region |
    mods:state | mods:territory | mods:county | mods:city | mods:island |
    mods:area | mods:extraTerrestrialArea | mods:citySection |
    mods:geographicCode | mods:number | mods:caption | mods:title | mods:start |
    mods:end | mods:total | mods:list | mods:date | mods:text | mods:form |
    mods:reformattingQuality | mods:internetMediaType | mods:extent |
    mods:digitalOrigin | mods:publisher | mods:edition |
    mods:language/mods:languageTerm | mods:issuance | mods:tableOfContents">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mods:name" mode="subject_content">
    <xsl:call-template name="name_parts_given_last">
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="mods:title" mode="subject_content">
    <xsl:call-template name="title_info_title">
      <xsl:with-param name="node" select="current()"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="*" mode="subject_content">
    <xsl:value-of select="normalize-space(text())"/>
  </xsl:template>

    <!-- Subjects / Keywords -->
  <xsl:template match="mods:subject">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
      <xsl:if test="./*">
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, 'subject', $suffix)"/>
          </xsl:attribute>
          <xsl:for-each select="./*">
            <xsl:apply-templates select="." mode="subject_content"/>
            <xsl:if test="position()!=last()">
              <xsl:text>--</xsl:text>
            </xsl:if>
          </xsl:for-each>
        </field>
      </xsl:if>
    
    
    <xsl:apply-templates>
      <xsl:with-param name="prefix" select="concat($prefix, 'subject_')"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="mods:hierarchicalGeographic | mods:part | mods:physicalDescription | mods:originInfo">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:apply-templates>
      <xsl:with-param name="prefix" select="concat($prefix, local-name(), '_')"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="mods:relatedItem[@type] | mods:detail[@type]">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:apply-templates>
      <xsl:with-param name="prefix" select="concat($prefix, @type, '_')"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="mods:place">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:apply-templates>
      <xsl:with-param name="prefix" select="$prefix"/>
      <xsl:with-param name="suffix" select="$suffix"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="mods:placeTerm[@type='text']">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, 'place_of_publication', $suffix)"/>
      </xsl:attribute>
      <xsl:value-of select="text()"/>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:dateIssued[1] | mods:dateCreated[1] | mods:dateCaptured[1]
  | mods:dateValid[1] | mods:dateModified[1] | mods:copyrightDate[1] | mods:dateOther[1]">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>
    
    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <!-- XXX: make the assumptions that we'll get copied into this field
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>-->
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_s')"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
      <xsl:if test="@encoding='iso8601'">
        <!--  XXX: need to add the joda jar to the lib directory to make work? -->
        <xsl:variable name="dp" select="java:org.joda.time.format.ISODateTimeFormat.dateTimeParser()"/>
        <xsl:variable name="parsed" select="java:parseDateTime($dp, $text_value)"/>
        
        <xsl:variable name="f" select="java:org.joda.time.format.ISODateTimeFormat.dateTime()"/>
        <xsl:variable name="df" select="java:withZoneUTC($f)"/>
        <xsl:variable name="date" select="java:print($df, $parsed)"/>
        
        <field>
          <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, local-name(), '_dt')"/>
          </xsl:attribute>
          <xsl:value-of select="$date"/>
        </field>
      </xsl:if>
    </xsl:if>
  </xsl:template>
 
  <xsl:template match="mods:dateIssued | mods:dateCreated | mods:dateCaptured
  | mods:dateValid | mods:dateModified | mods:copyrightDate | mods:dateOther">
    <xsl:param name="prefix">mods_</xsl:param>
    <xsl:param name="suffix">_ms</xsl:param>

    <xsl:variable name="text_value" select="normalize-space(text())"/>
    <xsl:if test="$text_value">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="$text_value"/>
      </field>
    </xsl:if>
  </xsl:template>
 
  <xsl:template match="text()"/>
</xsl:stylesheet>
