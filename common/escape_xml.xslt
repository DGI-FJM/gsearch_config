<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="*" mode="escape">
        <!-- Begin opening tag -->
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>

        <!-- Namespaces -->
        <xsl:for-each select="namespace::*">
          <xsl:choose>
            <!-- bit of a hack to ignore some unneeded name spaces in the output. -->
            <xsl:when test="name()='xsi'"></xsl:when>
            <xsl:when test="name()='foxml'"></xsl:when>
            <xsl:when test="name()='xml'"></xsl:when>
            <xsl:otherwise>
              <xsl:text> xmlns</xsl:text>
              <xsl:if test="name() != ''">
                  <xsl:text>:</xsl:text>
                  <xsl:value-of select="name()"/>
              </xsl:if>
              <xsl:text>='</xsl:text>
              <xsl:call-template name="escape-xml">
                  <xsl:with-param name="text" select="."/>
              </xsl:call-template>
              <xsl:text>'</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>

        <!-- Attributes -->
        <xsl:for-each select="@*">
            <xsl:text> </xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>='</xsl:text>
            <xsl:call-template name="escape-xml">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
            <xsl:text>'</xsl:text>
        </xsl:for-each>

        <!-- End opening tag -->
        <xsl:text>&gt;</xsl:text>

        <!-- Content (child elements, text nodes, and PIs) -->
        <xsl:apply-templates select="node()" mode="escape" />

        <!-- Closing tag -->
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
    </xsl:template>

    <xsl:template match="text()" mode="escape">
        <xsl:call-template name="escape-xml">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="processing-instruction()" mode="escape">
        <xsl:text>&lt;?</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="escape-xml">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
        <xsl:text>?&gt;</xsl:text>
    </xsl:template>

    <xsl:template name="escape-xml">
        <xsl:param name="text"/>
        <xsl:if test="$text != ''">
            <xsl:variable name="head" select="substring($text, 1, 1)"/>
            <xsl:variable name="tail" select="substring($text, 2)"/>
            <xsl:choose>
                <xsl:when test="$head = '&amp;'">&amp;amp;</xsl:when>
                <xsl:when test="$head = '&lt;'">&amp;lt;</xsl:when>
                <xsl:when test="$head = '&gt;'">&amp;gt;</xsl:when>
                <xsl:when test="$head = '&quot;'">&amp;quot;</xsl:when>
                <xsl:when test="$head = &quot;&apos;&quot;">&amp;apos;</xsl:when>
                <xsl:otherwise><xsl:value-of select="$head"/></xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="escape-xml">
                <xsl:with-param name="text" select="$tail"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>