<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: demoFoxmlToLucene.xslt 5734 2006-11-28 11:20:15Z gertsp $ -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
  xmlns:islandora-exts="xalan://ca.upei.roblib.DataStreamForXSLT"
    		exclude-result-prefixes="exts"
  xmlns:zs="http://www.loc.gov/zing/srw/"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
  xmlns:mods="http://www.loc.gov/mods/v3"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
  xmlns:rel="info:fedora/fedora-system:def/relations-external#"
  xmlns:dwc="http://rs.tdwg.org/dwc/xsd/simpledarwincore/"
  xmlns:fedora-model="info:fedora/fedora-system:def/model#"
  xmlns:uvalibdesc="http://dl.lib.virginia.edu/bin/dtd/descmeta/descmeta.dtd"
  xmlns:uvalibadmin="http://dl.lib.virginia.edu/bin/admin/admin.dtd/"
  xmlns:eaccpf="urn:isbn:1-931666-33-4"
  xmlns:res="http://www.w3.org/2001/sw/DataAccess/rf1/result"
  xmlns:xalan="http://xml.apache.org/xalan"
  xmlns:xlink="http://www.w3.org/1999/xlink">
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
  
  <xsl:include href="file:///usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/common/basicFJMToSolr.xslt"/>
  <xsl:include href="file:///usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/common/escape_xml.xslt"/>
  <xsl:include href="file:///usr/local/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/common/mods_to_solr_fields.xslt"/>

  <xsl:param name="REPOSITORYNAME" select="repositoryName"/>
  <xsl:param name="FEDORASOAP" select="repositoryName"/>
  <xsl:param name="FEDORAUSER" select="repositoryName"/>
  <xsl:param name="FEDORAPASS" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPATH" select="repositoryName"/>
  <xsl:param name="TRUSTSTOREPASS" select="repositoryName"/>

  <!-- Test of adding explicit parameters to indexing -->
  <xsl:param name="EXPLICITPARAM1" select="defaultvalue1"/>
  <xsl:param name="EXPLICITPARAM2" select="defaultvalue2"/>
<!--
	 This xslt stylesheet generates the IndexDocument consisting of IndexFields
     from a FOXML record. The IndexFields are:
       - from the root element = PID
       - from foxml:property   = type, state, contentModel, ...
       - from oai_dc:dc        = title, creator, ...
     The IndexDocument element gets a PID attribute, which is mandatory,
     while the PID IndexField is optional.
     Options for tailoring:
       - IndexField types, see Lucene javadoc for Field.Store, Field.Index, Field.TermVector
       - IndexField boosts, see Lucene documentation for explanation
       - IndexDocument boosts, see Lucene documentation for explanation
       - generation of IndexFields from other XML metadata streams than DC
         - e.g. as for uvalibdesc included above and called below, the XML is inline
         - for not inline XML, the datastream may be fetched with the document() function,
           see the example below (however, none of the demo objects can test this)
       - generation of IndexFields from other datastream types than XML
         - from datastream by ID, text fetched, if mimetype can be handled
         - from datastream by sequence of mimetypes,
           text fetched from the first mimetype that can be handled,
           default sequence given in properties.
-->

  <xsl:template match="/">
    <xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>
    <add>
      <!-- The following allows only active FedoraObjects to be indexed. -->
      <xsl:if test="foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state']">
        <xsl:if test="not(foxml:digitalObject/foxml:datastream[@ID='METHODMAP' or @ID='DS-COMPOSITE-MODEL'])">
           <xsl:if test="starts-with($PID, 'jt')">
             <doc>
               <xsl:apply-templates select="/foxml:digitalObject" mode="activeFedoraObject">
                 <xsl:with-param name="PID" select="$PID"/>
               </xsl:apply-templates>
               <xsl:apply-templates select="/foxml:digitalObject" mode="add-turina-thumbnail">
                 <xsl:with-param name="pid" select="$PID"/>
               </xsl:apply-templates>
             </doc>
           </xsl:if>
        </xsl:if>
      </xsl:if>
    </add>
  </xsl:template>
  
  <xsl:template match="/foxml:digitalObject" mode="add-turina-thumbnail">
    <xsl:param name="pid"/>
    
    <xsl:variable name="results_tf">
      <xsl:call-template name="perform_query">
        <xsl:with-param name="query">
PREFIX fre: &lt;info:fedora/fedora-system:def/relations-external#&gt;
PREFIX fm: &lt;info:fedora/fedora-system:def/model#&gt;
PREFIX fv: &lt;info:fedora/fedora-system:def/view#&gt;
PREFIX ip: &lt;info:islandora/islandora-system:def/pageinfo#&gt;
SELECT ?thumbnail ?thumbnail_obj
FROM &lt;#ri&gt;
WHERE {
  ?thumbnail_obj ip:isPageOf &lt;info:fedora/<xsl:value-of select="$pid"/>&gt; ;
                 fm:state fm:Active ;
                 fv:disseminates ?thumbnail .
  ?thumbnail fv:disseminationType &lt;info:fedora/*/TN&gt; ;
             fm:state fm:Active .
  &lt;info:fedora/<xsl:value-of select="$pid"/>&gt; fm:state fm:Active .
}
        </xsl:with-param>
        <xsl:with-param name='lang'>sparql</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:for-each select="xalan:nodeset($results_tf)/res:sparql/res:results/res:result[position() = 1]">
      <field name="turina_thumbnail_s">
        <xsl:value-of select="substring-after(res:thumbnail_obj/@uri, 'info:fedora/')"/>
      </field>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="/foxml:digitalObject" mode="activeFedoraObject">
    <xsl:param name="PID"/>

    <field name="PID" boost="2.5">
      <xsl:value-of select="$PID"/>
    </field>
    
    <xsl:apply-templates select="foxml:objectProperties/foxml:property"/>

    <!-- index DC -->
    <xsl:apply-templates mode="simple_set" select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/*">
      <xsl:with-param name="prefix">dc.</xsl:with-param>
      <xsl:with-param name="suffix"></xsl:with-param>
    </xsl:apply-templates>

    <!-- Index the Rels-ext (using match="rdf:RDF") -->
    <xsl:apply-templates select="foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion[last()]/foxml:xmlContent/rdf:RDF">
      <xsl:with-param name="prefix">rels_</xsl:with-param>
      <xsl:with-param name="suffix">_ms</xsl:with-param>
    </xsl:apply-templates>

    <!-- OCR -->
    <xsl:for-each select="foxml:datastream[@ID='OCR']/foxml:datastreamVersion[last()]">
      <field>
        <xsl:attribute name="name">ocr</xsl:attribute>
      <xsl:value-of select="exts:getDatastreamText($PID, $REPOSITORYNAME, 'OCR', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
            <xsl:message><xsl:value-of select="exts:getDatastreamText($PID, $REPOSITORYNAME, 'OCR', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/></xsl:message>
           <!-- <xsl:value-of select="islandora-exts:getDatastreamTextRaw($PID, $REPOSITORYNAME, 'OCR', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/> -->
     	</field>
    </xsl:for-each>

      <!-- Names and Roles -->
    <xsl:apply-templates select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods" mode="default"/>
    <xsl:apply-templates select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods" mode="turina"/>
    
    <!-- store an escaped copy of MODS... -->
    <xsl:if test="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods">
      <field name="mods_fullxml_store">
        <xsl:apply-templates select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:mods" mode="escape"/>
      </field>
    </xsl:if>

    <xsl:for-each select="foxml:datastream[@ID][foxml:datastreamVersion[last()]]">
        <xsl:choose>
          <!-- Don't bother showing some... -->
          <xsl:when test="@ID='AUDIT'"></xsl:when>
          <xsl:when test="@ID='DC'"></xsl:when>
          <xsl:when test="@ID='ENDNOTE'"></xsl:when>
          <xsl:when test="@ID='MODS'"></xsl:when>
          <xsl:when test="@ID='RIS'"></xsl:when>
          <xsl:when test="@ID='SWF'"></xsl:when>
          <xsl:otherwise>
            <field name="fedora_datastreams_ms">
              <xsl:value-of select="@ID"/>
            </field>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="/foxml:digitalObject" mode="inactiveFedoraObject">
    <xsl:param name="PID"/>
    
    <field name="PID">
      <xsl:value-of select="$PID"/>
    </field>
    <xsl:apply-templates select="foxml:property"/>
  </xsl:template>
  
  <xsl:template match="/foxml:digitalObject" mode="deletedFedoraObject">
    <xsl:param name="PID"/>

    <field name="PID">
      <xsl:value-of select="$PID"/>
    </field>
    <xsl:apply-templates select="foxml:property"/>
  </xsl:template>
  
  <xsl:template match="foxml:property">
    <xsl:param name="prefix">fgs_</xsl:param>
    <xsl:param name="suffix">_s</xsl:param>
    <xsl:param name="date_suffix">_dt</xsl:param>
    
    <xsl:variable name="name" select="substring-after(@NAME,'#')"/>
    
    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, $name, $suffix)"/>
      </xsl:attribute>
      <xsl:value-of select="@VALUE"/>
    </field>
    
    <xsl:if test="$name='lastModifiedDate' or $name='createdDate'">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, $name, $date_suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="@VALUE"/>
      </field>
    </xsl:if>
  </xsl:template>

  <xsl:template name="strip_end">
    <xsl:param name="to_strip">.</xsl:param>
    <xsl:param name="text"/>

    <xsl:variable name="to_strip_length" select="string-length($to_strip)"/>
    <xsl:variable name="length" select="string-length($text)"/>
    <xsl:variable name="end" select="$length - $to_strip_length"/>
    <xsl:choose>
      <xsl:when test="$end > 0 and substring($text, $end + 1)=$to_strip">
        <xsl:call-template name="strip_end">
          <xsl:with-param name="to_strip" select="$to_strip"/>
          <xsl:with-param name="text" select="substring($text, 1, $end)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
         <!--XXX:  Debug stuff, get rid of at some point...
         <xsl:message>
To strip:<xsl:value-of select="$to_strip"/>
End position:<xsl:value-of select="$end"/>
Text:<xsl:value-of select="$text"/>
Subbed:<xsl:value-of select="substring($text, $end + 1)"/>
To strip length:<xsl:value-of select="$to_strip_length"/>
         </xsl:message>-->
         <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="mods:mods" mode="turina">
    <field name="turina_type_s">
      <xsl:choose>
        <xsl:when test="starts-with(normalize-space(mods:location/mods:shelfLocation/text()), 'LJT-P-')">Partitura</xsl:when>
        <xsl:when test="starts-with(normalize-space(mods:location/mods:shelfLocation/text()), 'LJT-Pre-')">Prensa</xsl:when>
        <xsl:when test="starts-with(normalize-space(mods:location/mods:shelfLocation/text()), 'LJT-M')">Manuscrito</xsl:when>
        <xsl:when test="starts-with(normalize-space(mods:location/mods:shelfLocation/text()), 'LJT-Cor')">Correspondencia</xsl:when>
        <xsl:when test="mods:genre[@authority='Joaquín_Turina' and starts-with(normalize-space(text()), 'Programa')]">Programa de Mano</xsl:when>
        <xsl:when test="mods:genre[@authority='Joaquín_Turina'][starts-with(normalize-space(text()), 'Tarjeta Postal') or 
          starts-with(normalize-space(text()), 'Fotograf')]">Archivo Fotográfico</xsl:when>
        <xsl:when test="mods:genre[@authority='ingest' and starts-with(normalize-space(text()), 'Diarios')]">Diario</xsl:when>
        <xsl:otherwise>Unknown types</xsl:otherwise>
      </xsl:choose>
    </field>
    <xsl:for-each select="mods:genre">
      <xsl:variable name="temp_text">
        <xsl:call-template name="strip_end">
          <xsl:with-param name="to_strip">.</xsl:with-param>
          <xsl:with-param name="text" select="normalize-space(text())"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="text_value" select="normalize-space($temp_text)"/>
      <xsl:if test="$text_value">
        <field name="turina_cleaned_genre_ms">
          <xsl:value-of select="$text_value"/>
        </field>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="rdf:RDF">
    <xsl:param name="prefix">rels_</xsl:param>
    <xsl:param name="suffix">_s</xsl:param>

    <xsl:for-each select=".//rdf:Description/*[@rdf:resource]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_uri', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="@rdf:resource"/>
      </field>
    </xsl:for-each>
    <xsl:for-each select=".//rdf:Description/*[not(@rdf:resource)][normalize-space(text())]">
      <field>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($prefix, local-name(), '_literal', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="text()"/>
      </field>
    </xsl:for-each>
  </xsl:template>

  <!-- Create fields for the set of selected elements, named according to the 'local-name' and containing the 'text' -->
  <xsl:template match="*" mode="simple_set">
    <xsl:param name="prefix">changeme_</xsl:param>
    <xsl:param name="suffix">_t</xsl:param>

    <field>
      <xsl:attribute name="name">
        <xsl:value-of select="concat($prefix, local-name(), $suffix)"/>
      </xsl:attribute>
      <xsl:value-of select="text()"/>
    </field>
  </xsl:template>
</xsl:stylesheet>
