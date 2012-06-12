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
           <xsl:if test="starts-with($PID,'atm')">
             <xsl:call-template name="fjm-atm">
               <xsl:with-param name="pid" select="$PID"/>
             </xsl:call-template>
           </xsl:if>
        </xsl:if>
      </xsl:if>
    </add>
  </xsl:template>
</xsl:stylesheet>
  
