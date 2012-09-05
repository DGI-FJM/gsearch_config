<?xml version="1.0" encoding="UTF-8"?> 
<!-- TODO Reconsider how names are acquired:  If labels are set properly on change,
    going out to most metadata files could be avoided, as the labels are available
    from the Resource Index...  On the otherhnad, if the labels become desynced, 
    there could be problems...  Might make a script (run via cron) to check if the 
    label is correct, and index if it is not? -->
    
<xsl:stylesheet version="1.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"   
        xmlns:foxml="info:fedora/fedora-system:def/foxml#"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:m="http://www.loc.gov/mods/v3"
        xmlns:res="http://www.w3.org/2001/sw/DataAccess/rf1/result"
        xmlns:fds="http://www.fedora.info/definitions/1/0/access/"
        xmlns:ns="http://digital.march.es/atmusica#"
        xmlns:xalan="http://xml.apache.org/xalan"
        xmlns:set="http://exslt.org/sets"
        xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
        xmlns:fedora-rels-ext="info:fedora/fedora-system:def/relations-external#"
        xmlns:encoder="xalan://java.net.URLEncoder"
        xmlns:eac-cpf="urn:isbn:1-931666-33-4"
            exclude-result-prefixes="exts m rdf res fds ns xalan set encoder eac-cpf">
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <!-- FIXME:  Should probably get these as parameters, or sommat -->
    <xsl:param name="HOST">localhost</xsl:param>
    <xsl:param name="PORT">8080</xsl:param>
    <xsl:param name="PROT">http</xsl:param>
    <xsl:param name="URLBASE" select="concat($PROT, '://', $HOST, ':', $PORT, '/')"/>
    <xsl:param name="REPOSITORYNAME" select="'fedora'"/>
    <xsl:param name="RISEARCH" select="concat($URLBASE, 'fedora/risearch',
        '?type=tuples&amp;flush=TRUE&amp;format=Sparql&amp;query=')" />
    <!--<xsl:param name="FEDORAUSERNAME" select="'fedoraAdmin'"/>
    <xsl:param name="FEDORAPASSWORD" select="'fedoraAdmin'"/>-->
    <xsl:param name="FEDORAUSERNAME" select="''"/>
    <xsl:param name="FEDORAPASSWORD" select="''"/>
    <xsl:param name="NAMESPACE" select="'http://digital.march.es/atmusica#'"/>
    
    <xsl:template name="traverse_graph">
      <xsl:param name="start"/> <!--  the PID we're starting from -->
      
      <!-- traverse the graph up. -->
      <xsl:variable name="traversed_up">
        <res:result>
        <xsl:call-template name="_traverse_graph">
          <xsl:with-param name="to_traverse_in">
            <res:result>
              <res:obj>
                <xsl:attribute name="uri">info:fedora/<xsl:value-of select="$start"/></xsl:attribute>
              </res:obj>
            </res:result>
          </xsl:with-param>
          <xsl:with-param name="query">
PREFIX atm-rel: &lt;http://digital.march.es/atmusica#&gt;
PREFIX fedora: &lt;info:fedora/&gt;
PREFIX atm: &lt;fedora:atm:&gt;
PREFIX fre: &lt;info:fedora/fedora-system:def/relations-external#&gt;
PREFIX fm: &lt;info:fedora/fedora-system:def/model#&gt;
PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
SELECT ?obj
FROM &lt;#ri&gt;
WHERE {
  {
    ?sub fm:hasModel &lt;info:fedora/atm:performanceCModel&gt; ;
         fre:isMemberOf ?obj .
    ?obj fm:hasModel &lt;info:fedora/atm:concertCModel&gt; .
  }
  UNION {
    ?sub fm:hasModel &lt;info:fedora/atm:lectureCModel&gt; ;
         fre:isMemberOf ?obj .
    ?obj fm:hasModel &lt;info:fedora/atm:concertCModel&gt; .
  }
  UNION {
    ?sub fm:hasModel &lt;info:fedora/atm:programCModel&gt; ;
         fre:isMemberOf ?obj .
    ?obj fm:hasModel &lt;info:fedora/atm:concertCModel&gt; .
  }
  UNION{
    ?sub fm:hasModel &lt;info:fedora/atm:scoreCModel&gt; .
    ?obj atm-rel:basedOn ?sub ;
         fm:hasModel &lt;info:fedora/atm:performanceCModel&gt; .
  }
  UNION {
    ?sub fm:hasModel &lt;info:fedora/atm:performerCModel&gt; ;
         atm-rel:performance ?obj .
    ?obj fm:hasModel &lt;info:fedora/atm:performanceCModel&gt; .
  }
  UNION {
    ?sub fm:hasModel &lt;info:fedora/atm:personCModel&gt; .
    {
      ?obj atm-rel:composedBy ?sub ;
           fm:hasModel &lt;info:fedora/atm:scoreCModel&gt; .
    }
    UNION {
      ?obj atm-rel:person ?sub ;
           fm:hasModel &lt;info:fedora/atm:performerCModel&gt; .
    }
  }
  UNION{
    ?sub fm:hasModel &lt;info:fedora/atm:movementCModel&gt; ;
         fre:isMemberOf ?obj .
    ?obj fm:hasModel &lt;info:fedora/atm:performanceCModel&gt; .
  }
  UNION{
    ?sub fm:hasModel &lt;info:fedora/atm:instrumentClassCModel&gt; .
    ?obj fre:isMemberOf ?sub ;
         fm:hasModel &lt;info:fedora/atm:instrumentCModel&gt; .
  }
  UNION{
    ?sub fm:hasModel &lt;info:fedora/atm:instrumentCModel&gt; .
    ?obj atm-rel:instrument ?sub ;
         fm:hasModel &lt;info:fedora/atm:performerCModel&gt; .
  }
  UNION{
    ?sub fm:hasModel &lt;info:fedora/atm:groupCModel&gt; .
    ?obj fre:isMemberOf ?sub ;
         fm:hasModel &lt;info:fedora/atm:performerCModel&gt; .
  }
  FILTER(sameTerm(?sub, &lt;%PID_URI%&gt;))
}
          </xsl:with-param>
        </xsl:call-template>
        </res:result>
      </xsl:variable>
      
      <res:result>
        <!-- traverse the graph down. -->
        <xsl:call-template name="_traverse_graph">
          <xsl:with-param name="to_traverse_in">
            <res:result>
              <res:obj>
                <xsl:attribute name="uri">info:fedora/<xsl:value-of select="$start"/></xsl:attribute>
              </res:obj>
            </res:result>
          </xsl:with-param>
          <xsl:with-param name="traversed_in">
            <res:result>
              <xsl:copy-of select="xalan:nodeset($traversed_up)/res:result/res:obj[not(@uri=concat('info:fedora/', $start))]"/>
            </res:result>
          </xsl:with-param>
          <xsl:with-param name="query">
PREFIX atm-rel: &lt;http://digital.march.es/atmusica#&gt;
PREFIX fedora: &lt;info:fedora/&gt;
PREFIX atm: &lt;fedora:atm:&gt;
PREFIX fre: &lt;info:fedora/fedora-system:def/relations-external#&gt;
PREFIX fm: &lt;info:fedora/fedora-system:def/model#&gt;
PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
SELECT ?obj
FROM &lt;#ri&gt;
WHERE {
  {
    ?sub fm:hasModel &lt;info:fedora/atm:concertCModel&gt; .
    {
      ?obj fre:isMemberOf ?sub ;
           fm:hasModel &lt;info:fedora/atm:performanceCModel&gt; .
    }
    UNION {
      ?obj fre:isMemberOf ?sub ;
           fm:hasModel &lt;info:fedora/atm:lectureCModel&gt; .
    }
    UNION {
      ?obj fre:isMemberOf ?sub ;
           fm:hasModel &lt;info:fedora/atm:programCModel&gt; .
    }
  }
  UNION {
    ?sub fm:hasModel &lt;info:fedora/atm:performanceCModel&gt; .
    {
      ?sub atm-rel:basedOn ?obj .
      ?obj fm:hasModel &lt;info:fedora/atm:scoreCModel&gt; .
    }
    UNION {
      ?obj atm-rel:performance ?sub ;
           fm:hasModel &lt;info:fedora/atm:performerCModel&gt; .
    }
    UNION {
      ?obj fre:isMemberOf ?sub ;
           fm:hasModel &lt;info:fedora/atm:movementCModel&gt; .
    }
  }
  UNION {
    ?sub fm:hasModel &lt;info:fedora/atm:scoreCModel&gt; ;
         atm-rel:composedBy ?obj .
  }
  UNION {
    ?sub fm:hasModel &lt;info:fedora/atm:performerCModel&gt; .
    {
      ?sub atm-rel:instrument ?obj .
    }
    UNION {
      ?sub atm-rel:group ?obj .
    }
    UNION {
      ?sub atm-rel:instrument ?obj .
    }
  }
  FILTER(sameTerm(?sub, &lt;%PID_URI%&gt;))
}
          </xsl:with-param>
        </xsl:call-template>
      </res:result>
    </xsl:template>
    
    <!-- traverse the graph -->
    <xsl:template name="_traverse_graph">
      <xsl:param name="to_traverse_in"/>
      <xsl:param name="traversed_in"/>
      <xsl:param name="query"/>
      
      <xsl:variable name="traverse" select="xalan:nodeset($to_traverse_in)"/>
      <xsl:message>Traverse:
        <xsl:for-each select="$traverse//*[@uri]">
          <xsl:value-of select="name()"/>:<xsl:value-of select="@uri"/>
        </xsl:for-each>
      </xsl:message>
      <xsl:variable name="traversed" select="xalan:nodeset($traversed_in)"/>
      <xsl:message>Traversed:
        <xsl:for-each select="$traversed//*[@uri]">
          <xsl:value-of select="name()"/>:<xsl:value-of select="@uri"/>
        </xsl:for-each>
      </xsl:message>
      <xsl:variable name="difference" select="xalan:nodeset(set:difference($traverse, $traversed))"/>
      <xsl:message>Difference:
        <xsl:value-of select="count($difference/res:result/res:obj)"/>
        <xsl:for-each select="$difference//*[@uri]">
          <xsl:value-of select="name()"/>:<xsl:value-of select="@uri"/>
        </xsl:for-each>
      </xsl:message>
      <xsl:choose>
        <xsl:when test="count($difference/res:result/res:obj) = 0">
          <!-- There is nothing to traverse which has not already been traversed...  -->
          <!--  TODO: Start indexing/return! -->
          <xsl:message>
            To index:
            <xsl:for-each select="$traversed//*[@uri]">
              <xsl:value-of select="@uri"/>
            </xsl:for-each>
          </xsl:message>
          <xsl:copy-of select="$traversed/res:result/res:obj"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="to_traverse">
            <res:result>
              <xsl:for-each select="$difference/res:result/res:obj">
                <xsl:message>diff: <xsl:value-of select="@uri"/></xsl:message>
                <xsl:variable name="query_results">
                  <xsl:call-template name="perform_query">
                    <!-- TODO:  Add the query... -->
                    <xsl:with-param name="query">
                      <xsl:value-of select="substring-before($query, '%PID_URI%')"/>
                      <xsl:value-of select="@uri"/>
                      <xsl:value-of select="substring-after($query, '%PID_URI%')"/>
                    </xsl:with-param>
                    <xsl:with-param name="lang">sparql</xsl:with-param>
                  </xsl:call-template>
                </xsl:variable>
                <xsl:copy-of select="xalan:nodeset($query_results)/res:sparql/res:results/res:result/res:obj"/>
              </xsl:for-each>
            </res:result>
          </xsl:variable>
          
          <xsl:call-template name="_traverse_graph">
            <xsl:with-param name="to_traverse_in" select="set:distinct(xalan:nodeset($to_traverse))"/>
            <xsl:with-param name="traversed_in">
              <res:result>
                <xsl:copy-of select="$traversed/res:result/res:obj | $difference/res:result/res:obj"/>
              </res:result>
            </xsl:with-param>
            <xsl:with-param name="query" select="$query"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:template>
    
    <xsl:template name="get_models">
      <xsl:param name="pid"/>
      
      <xsl:call-template name="perform_query">
        <xsl:with-param name="lang">sparql</xsl:with-param>
        <xsl:with-param name="query">
SELECT ?model
WHERE {
  &lt;info:fedora/<xsl:value-of select="$pid"/>&gt; &lt;fedora-model:hasModel&gt; ?model .
}
        </xsl:with-param>
      </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="fjm-atm">
      <xsl:param name="pid" select="'no_pid'"/>

      <xsl:variable name="to_index_tf">
        <xsl:call-template name="traverse_graph">
          <xsl:with-param name="start" select="$pid"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:message terminate="yes">Hard stop.</xsl:message>
        
      <xsl:for-each select="xalan:nodeset($to_index_tf)/res:result/res:obj">
        <xsl:variable name="pid_to_index" select="substring-after(@uri, '/')"/>
        <xsl:message>PID: <xsl:value-of select="$pid_to_index"/></xsl:message>
        
        <!-- Index based on CModel -->
        <xsl:variable name="models">
          <xsl:call-template name="get_models">
            <xsl:with-param name="pid" select="$pid_to_index"/>
          </xsl:call-template>
        </xsl:variable>
      
        <xsl:for-each select="xalan:nodeset($models)/res:sparql/res:results/res:result/res:model">
          <xsl:message>Model: <xsl:value-of select="@uri"/></xsl:message>
            <!--  TODO:  Make use the models returned from the "get_models" call, instead of grabbing the RDF. -->
            <!-- <xsl:for-each select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                    $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/RELS-EXT/content'))/rdf:RDF/rdf:Description/*[local-name()='hasModel' and @rdf:resource]"> -->
          <xsl:choose>
            <xsl:when test="@uri='info:fedora/atm:concertCModel'">
                <xsl:call-template name="atm_concert">
                    <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="@uri='info:fedora/atm:performanceCModel'">
                <xsl:call-template name="atm_performance">
                    <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template>
                <!--
                <xsl:call-template name="atm_performer">
                    <xsl:with-param name="performance" select="$pid"/>
                </xsl:call-template>-->
            </xsl:when>
            <xsl:when test="@uri='info:fedora/atm:scoreCModel'">
                <!-- Index the score and then all concerts which contain a performances based on the score -->
                <xsl:call-template name="atm_score">
                    <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="@uri='info:fedora/atm:programCModel'">
                <xsl:call-template name="atm_program">
                    <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template> 
            </xsl:when>
            <xsl:when test="@uri='info:fedora/atm:personCModel'">
                <xsl:call-template name="atm_person">
                    <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="@uri='info:fedora/atm:lectureCModel'">
                <xsl:call-template name="atm_lecture">
                    <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="@uri='info:fedora/atm:movementCModel'">
                <xsl:call-template name="atm_movement">
                    <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template>
            </xsl:when>
            <!-- Handled elsewhere...  Likely through performance.
            <xsl:when test="@rdf:resource='info:fedora/atm:performerCModel'">
                <xsl:call-template name="atm_performer">
                    <xsl:with-param name="pid" select="$$pid_to_index"/>
                </xsl:call-template>
            </xsl:when>-->
            <xsl:when test="@uri='info:fedora/fedora-system:FedoraObject-3.0'"/>
            <xsl:otherwise>
              <doc>
                <field name="PID">
                  <xsl:value-of select="$pid_to_index"/>
                </field>
                <xsl:call-template name="rels_ext">
                  <xsl:with-param name="pid" select="$pid_to_index"/>
                </xsl:call-template>
              </doc>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:template>
    
    <!--  get the naem of the cycle for the current concert -->
    <xsl:template match="rdf:Description" mode="atm_concert">
      <xsl:variable name="cycle_pid" select="fedora-rels-ext:isMemberOf/@rdf:resource"/>
      <xsl:if test="$cycle_pid">
        <xsl:variable name="cycle_dc" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                    $HOST, ':', $PORT, '/fedora/objects/', substring-after($cycle_pid, '/'), '/datastreams/DC/content'))"/>
        <xsl:variable name="cycle_title" select="normalize-space($cycle_dc/oai_dc:dc/dc:title/text())"
          xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
          xmlns:dc="http://purl.org/dc/elements/1.1/"/>
        <xsl:if test='$cycle_title'>
          <field name="atm_concert_cycle_s"><xsl:value-of select="$cycle_title"/></field>
          <field name="atm_facet_concert_cycle_s"><xsl:value-of select="$cycle_title"/></field>
        </xsl:if>
      </xsl:if>
    </xsl:template>
    
    <!--  get the date of the concert, and delegate others -->
    <xsl:template match="m:mods" mode="atm_concert">
      <xsl:param name="pid"/>
      
      <xsl:variable name="temp_titn">
        <xsl:choose>
          <xsl:when test="m:identifier[@type='titn']">
           <xsl:value-of select="normalize-space(m:identifier[@type='titn']/text())"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/CustomXML/content'))"/>
            <xsl:value-of select="normalize-space($C_CUSTOM/Concierto/programa/titn_programa/text())"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="date">
        <xsl:call-template name="get_concert_date">
          <xsl:with-param name="concert_pid" select="$pid"/>
          <xsl:with-param name="mods" select="current()"/>
        </xsl:call-template>
      </xsl:variable>
      
      <xsl:if test="$date">
        <field name="atm_concert_date_dt"><xsl:value-of select="$date"/></field>
        <field name="atm_concert_year_s"><xsl:value-of select="substring($date, 1, 4)"/></field>
        <field name="atm_facet_year_s"><xsl:value-of select="substring($date, 1, 4)"/></field>
      </xsl:if>
        
      <xsl:if test="$temp_titn">
        <field name="atm_concert_program_titn_s"><xsl:value-of select="$temp_titn"/></field>
      </xsl:if>

      <xsl:apply-templates mode="atm_concert"/>
    </xsl:template>
    
    <xsl:template name="get_ISO8601_date" xmlns:java="http://xml.apache.org/xalan/java">
      <xsl:param name="date"/>

      <xsl:variable name="frac">([.,][0-9]+)</xsl:variable>
      <xsl:variable name="sec_el">(\:[0-9]{2}<xsl:value-of select="$frac"/>?)</xsl:variable>
      <xsl:variable name="min_el">(\:[0-9]{2}(<xsl:value-of select="$frac"/> | <xsl:value-of select="$sec_el"/>))</xsl:variable>
      <xsl:variable name="time_el">([0-9]{2}(<xsl:value-of select="$frac"/> | <xsl:value-of select="$min_el"/>))</xsl:variable>
      <xsl:variable name="time_offset">(Z|[+-]<xsl:value-of select="$time_el"/>)</xsl:variable>
      <xsl:variable name="time_pattern">T<xsl:value-of select="$time_el"/><xsl:value-of select="$time_offset"/>?</xsl:variable>

      <xsl:variable name="day_el">(-[0-9]{2})</xsl:variable>
      <xsl:variable name="month_el">(-[0-9]{2}<xsl:value-of select="$day_el"/>?)</xsl:variable>
      <xsl:variable name="date_el">([0-9]{4}<xsl:value-of select="$month_el"/>?)</xsl:variable>
      <xsl:variable name="date_opt_pattern">(<xsl:value-of select="$date_el"/><xsl:value-of select="$time_el"/>?)</xsl:variable>
      <xsl:variable name="pattern">(<xsl:value-of select="$time_pattern"/> | <xsl:value-of select="$date_opt_pattern"/>)</xsl:variable>

      <xsl:if test="java:matches(string($date), $pattern)"> 
        <!--  XXX: need to add the joda jar to the lib directory to make work? -->
        <xsl:variable name="dp" select="java:org.joda.time.format.ISODateTimeFormat.dateTimeParser()"/>
        <xsl:variable name="parsed" select="java:parseDateTime($dp, $date)"/>
      
        <xsl:variable name="f" select="java:org.joda.time.format.ISODateTimeFormat.dateTime()"/>
        <xsl:variable name="df" select="java:withZoneUTC($f)"/>
        <xsl:value-of select="java:print($df, $parsed)"/>
      </xsl:if>
    </xsl:template>
    
    <xsl:template name="get_concert_date">
      <xsl:param name="concert_pid"/>
      <xsl:param name="mods" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $concert_pid, '/datastreams/MODS/content'))//m:mods"/>
      
      <xsl:variable name="temp_date">
        <xsl:choose>
          <xsl:when test="$mods/m:originInfo/m:dateCreated[@encoding='iso8601']">
            <xsl:value-of select="normalize-space($mods/m:originInfo/m:dateCreated[@encoding='iso8601']/text())"/>
          </xsl:when>
          <xsl:otherwise>
              <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $concert_pid, '/datastreams/CustomXML/content'))"/>
              <!-- FIXME:  The date should be in MODS (and/or somewhere else (DC?), and obtained from there), so the original XML need not be stored...
                  Also, the whole "concat(..., 'Z')" seems a little flimsy-->
              <xsl:value-of select="normalize-space($C_CUSTOM/Concierto/FECHA/text())"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:if test="normalize-space($temp_date)">
        <xsl:call-template name="get_ISO8601_date">
          <xsl:with-param name="date" select="$temp_date"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:template>
    
    <xsl:template name="mods_titleInfo">
      <xsl:param name="node"/>
      <xsl:param name="nonSort" select="normalize-space($node/m:nonSort/text())"/>
      <xsl:param name="title" select="normalize-space($node/m:title/text())"/>
      <xsl:param name="subTitle" select="normalize-space($node/m:subTitle/text())"/>
      
      <xsl:if test="$nonSort">
        <xsl:value-of select="$nonSort"/>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:value-of select="$title"/>
      <xsl:if test="$subTitle">
        <xsl:text>: </xsl:text>
        <xsl:value-of select="$subTitle"/>
      </xsl:if>
    </xsl:template>
    
    <!-- build the title for the current concert from MODS titleInfo -->
    <xsl:template match="m:titleInfo" mode="atm_concert">
      <xsl:variable name="title">
        <xsl:call-template name="mods_titleInfo">
          <xsl:with-param name="node" select="current()"/>
        </xsl:call-template>
      </xsl:variable>
      
      <field name="atm_concert_title_s"><xsl:value-of select="normalize-space($title)"/></field>
    </xsl:template>
    
    <xsl:template match="m:abstract" mode="atm_concert">
      <field name="atm_concert_description_s"><xsl:value-of select="normalize-space(text())"/></field>
    </xsl:template>
    
    <xsl:template match="* | text()" mode="atm_concert"/>
    
    <xsl:template name="add_referenced_pids">
      <xsl:param name="results"/>
      
      <xsl:for-each select="res:result/*[@uri]">
        <field name="referenced_pids_ms">
          <xsl:value-of select="normalize-space(substring-after(@uri, '/'))"/>
        </field>
      </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="atm_concert">
        <xsl:param name="pid" select="no_pid"/>
        
        <doc>
            <field name="PID">
                <xsl:value-of select="$pid"/>
            </field>
            <field name="atm_type_s">Conciertos</field>
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
            
            <xsl:apply-templates mode="atm_concert" select="document(concat($PROT, '://', encoder:encode($FEDORAUSERNAME), ':', encoder:encode($FEDORAPASSWORD), '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/MODS/content'))//m:mods">
              <xsl:with-param name="pid" select="$pid"/>
            </xsl:apply-templates>
            <xsl:apply-templates mode="atm_concert" select="document(concat($PROT, '://', encoder:encode($FEDORAUSERNAME), ':',  encoder:encode($FEDORAPASSWORD), '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/RELS-EXT/content'))//rdf:Description[@rdf:about=concat('info:fedora/', $pid)]">
              <xsl:with-param name="pid" select="$pid"/>
            </xsl:apply-templates>
            
            <!-- FIXME:  This depends on having a program... -->
            <xsl:variable name="SCORE_QUERY_TF">
                <xsl:call-template name="perform_query">
                    <xsl:with-param name="query" select="concat('
                    PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                    PREFIX fedora: &lt;info:fedora/&gt;
                    PREFIX atm: &lt;fedora:atm:&gt;
                    PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                    PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                    PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                    SELECT $score $performance $composer $concertTitle $concertDesc $composerName $pieceName $concertCycle $cycleName $program $thumbnail
                    FROM &lt;#ri&gt;
                    WHERE {
                      $performance fedora-rels-ext:isMemberOf $concert .
                      $score dc:title $pieceName .
                      $concert dc:title $concertTitle ;
                               fedora-rels-ext:isMemberOf $concertCycle .
                      $concertCycle dc:title $cycleName .
                      $performance atm-rel:basedOn $score .
                      $score atm-rel:composedBy $composer .
                      $composer dc:title $composerName .
                      $score fedora-model:state fedora-model:Active .
                      $performance fedora-model:state fedora-model:Active .
                      $composer fedora-model:state fedora-model:Active .
                      OPTIONAL {
                        $program fedora-rels-ext:isMemberOf $concert ;
                                 fedora-model:hasModel atm:programCModel .
                      } .
                      OPTIONAL {
                        $concert dc:description $concertDesc
                      } .
                      OPTIONAL {
                        $thumbnail atm-rel:isIconOf $concert
                      } .
                      FILTER sameterm($concert, &lt;fedora:', $pid, '&gt;) .
                    }
                      ')"/>
                    <xsl:with-param name="lang" select="'sparql'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="SCORES" select="xalan:nodeset($SCORE_QUERY_TF)/res:sparql/res:results"/>
                        
            <!-- reference pids -->
            <xsl:call-template name="add_referenced_pids">
              <xsl:with-param name="results" select="$SCORES"/>
            </xsl:call-template>
            
            <xsl:for-each select='$SCORES/res:result'>
                <field name="atm_concert_piece_ms">
                    <xsl:value-of select="normalize-space(res:pieceName/text())"/>
                </field>
                <field name="atm_facet_piece_ms">
                    <xsl:value-of select="normalize-space(res:pieceName/text())"/>
                </field>
            
                <!-- TODO assumed only one composer per piece (here and elsewhere)...  may need to change? ...  
                    Should I get it from the label? -->
                <field name="atm_concert_composer_ms">
                    <xsl:value-of select="normalize-space(res:composerName/text())"/>
                </field>
                <field name="atm_facet_composer_ms">
                    <xsl:value-of select="normalize-space(res:composerName/text())"/>
                </field>
                
                <xsl:variable name="PERSON_GROUP_MEMBERSHIP">
                    <people><!-- Need a "root" element, so add one. -->
                        <xsl:call-template name="atm_performer">
                            <xsl:with-param name="performance" select="substring-after(res:performance/@uri, '/')"/>
                        </xsl:call-template>
                    </people>
                </xsl:variable>
                <xsl:for-each select="xalan:nodeset($PERSON_GROUP_MEMBERSHIP)/people/doc[field[@name='atm_type_s']/text()='Intérpretes']">
                    <!--  referenced pids -->
                    <xsl:copy-of select="field[@name='referenced_pids_ms']"/>
                    <field name="atm_concert_group_ms">
                        <xsl:value-of select="field[@name='atm_performer_group_s']/text()"/>
                    </field>
                    <field name="atm_concert_player_ms">
                        <xsl:value-of select="field[@name='atm_performer_name_s']/text()"/>
                    </field>
                    <field name="atm_concert_instrument_ms">
                        <xsl:value-of select="field[@name='atm_performer_instrument_s']/text()"/>
                    </field>
                    <field name="atm_concert_instrument_class_ms">
                        <xsl:value-of select="field[@name='atm_performer_instrument_class_s']/text()"/>
                    </field>
                    <field name="atm_facet_group_ms">
                        <xsl:value-of select="field[@name='atm_performer_group_s']/text()"/>
                    </field>
                    <field name="atm_facet_player_ms">
                        <xsl:value-of select="field[@name='atm_performer_name_s']/text()"/>
                    </field>
                    <field name="atm_facet_instrument_ms">
                        <xsl:value-of select="field[@name='atm_performer_instrument_s']/text()"/>
                    </field>
                    <field name="atm_facet_instrument_class_ms">
                        <xsl:value-of select="field[@name='atm_performer_instrument_class_s']/text()"/>
                    </field>
                </xsl:for-each>
            </xsl:for-each>
            
            <xsl:call-template name="digital_objects">
                <xsl:with-param name="objectType" select="'concert'"/>
                <xsl:with-param name="concert" select="$pid"/>
            </xsl:call-template>
            
            <field name="atm_concert_program_pdf_b">
                <xsl:choose>
                    <xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($SCORES/res:result[1]/res:program/@uri, '/'), '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']">true</xsl:when>
                    <xsl:otherwise>false</xsl:otherwise>
                </xsl:choose>
            </field>
            
            <field name="atm_concert_program_pdf_pid_s">
                <xsl:value-of select="substring-after($SCORES/res:result[1]/res:program/@uri, '/')"/>
            </field>
        
            <xsl:for-each select="$SCORES/res:result[res:thumbnail[@uri]][1]">
                <field name="atm_concert_iconpid_s">
                    <xsl:value-of select="substring-after(res:thumbnail/@uri, '/')"/>
                </field>
            </xsl:for-each>
        </doc>
    </xsl:template>
    
    <!-- FIXME:  Assumed there was only one composer...  (Limited to one result returned, really...) -->
    <xsl:template name="atm_performance">
        <xsl:param name="pid" select="no_pid"/>
        
        <xsl:variable name="SCORE_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query" select="concat('
                    PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                    PREFIX atm: &lt;fedora:atm:&gt;
                    PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                    PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                    PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                    PREFIX fjm-titn: &lt;http://digital.march.es/titn#&gt;
                    SELECT $concert $score $scoreName $scoreTitn $composerName $composer $concertCycle $cycleName $concertName $order $scoreTitn
                    FROM &lt;#ri&gt;
                    WHERE {
                        $performance atm-rel:basedOn $score ;
                                     fedora-rels-ext:isMemberOf $concert ;
                                     atm-rel:concertOrder $order .
                        $concert fedora-rels-ext:isMemberOf $concertCycle ;
                                 dc:title $concertName ;
                                 fedora-model:state fedora-model:Active .
                        $concertCycle dc:title $cycleName .
                        $score atm-rel:composedBy $composer .
                        $score dc:title $scoreName .
                        OPTIONAL{$score fjm-titn:score $scoreTitn} .
                        $composer dc:title $composerName .
                        $score fedora-model:state fedora-model:Active .
                        $composer fedora-model:state fedora-model:Active .
                        FILTER(sameterm($performance, &lt;info:fedora/', $pid, '&gt;))
                    }
                ')"/>
                <xsl:with-param name="lang" select="'sparql'"/>
                <xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="SCORES" select="xalan:nodeset($SCORE_TF)/res:sparql/res:results/res:result"/>
        
        <!-- Perform a query which grabs all players name and the name of the instrument they played, based on the label in Fedora -->
        <xsl:variable name="PLAYER_QUERY_TF">
            <people><!-- Need a "root" element... -->
                <xsl:call-template name="atm_performer">
                    <xsl:with-param name="performance" select="$pid"/>
                </xsl:call-template>
            </people>
        </xsl:variable>
        <xsl:variable name="PLAYERS" select="xalan:nodeset($PLAYER_QUERY_TF)"/>
        
        <xsl:variable name="MOVEMENT_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query" select="concat('
                    PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                    PREFIX atm: &lt;fedora:atm:&gt;
                    PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                    PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                    PREFIX fedora-view: &lt;info:fedora/fedora-system:def/view#&gt;
                    PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                    PREFIX fjm-titn: &lt;http://digital.march.es/titn#&gt;
                    SELECT $movement_pid $order $movementName $movementMP3
                    WHERE {
                        $movement_pid fedora-rels-ext:isMemberOf $performance ;
                                      atm-rel:pieceOrder $order ;
                                      dc:title $movementName ;
                                      fedora-model:state fedora-model:Active .
                        OPTIONAL {
                            $movement_pid fedora-view:disseminates $movementMP3 .
                            $movementMP3 fedora-view:disseminationType &lt;info:fedora/*/MP3&gt; .
                        }
                        FILTER(sameterm($performance, &lt;info:fedora/', $pid, '&gt;))
                    }
                    ORDER BY $order
                ')"/>
                <xsl:with-param name="lang">sparql</xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="MOVEMENTS" select="xalan:nodeset($MOVEMENT_TF)"/>

        <xsl:if test="$SCORES">            
            <doc>
                <field name="PID">
                    <xsl:value-of select="$pid"/>
                </field>
                
                <field name="atm_type_s">Obras</field>
                
                <!--  referenced pids -->
                <xsl:for-each select="$SCORES/*[@uri]">
                  <field name="referenced_pids_ms">
                    <xsl:value-of select="normalize-space(substring-after(@uri, '/'))"/>
                  </field>
                </xsl:for-each>
                
                <xsl:call-template name="rels_ext">
                    <xsl:with-param name="pid" select="$pid"/>
                </xsl:call-template>
                
                <!--  referenced pids -->
                <xsl:call-template name="add_referenced_pids">
                  <xsl:with-param name="results" select="$MOVEMENTS/res:sparql/res:results"/>
                </xsl:call-template>
                
                <xsl:for-each select="$MOVEMENTS/res:sparql/res:results/res:result">
                    <field name="atm_performance_movement_ms">
                        <xsl:value-of select="substring-after(res:movement_pid/@uri, '/')"/>
                    </field>
                    <field name="atm_performance_movement_name_ms">
                        <xsl:value-of select="res:movementName/text()"/>
                    </field>
                    <field name="atm_performance_movement_mp3_ms">
                        <xsl:choose>
                            <xsl:when test="res:movementMP3/@uri">true</xsl:when>
                            <xsl:otherwise>false</xsl:otherwise>
                        </xsl:choose>
                    </field>
                </xsl:for-each>
                
                <!-- Use the retrieved metadatastreams -->
                <field name="atm_performance_piece_title_s">
                    <xsl:value-of select="normalize-space($SCORES/res:scoreName/text())"/>
                </field>
                <field name="atm_performance_concert_name_s">
                    <xsl:value-of select="normalize-space($SCORES/res:concertName/text())"/>
                    <!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:titleInfo[@type='alternative'][1]/m:title/text())"/>-->
                </field>
                <field name="atm_performance_concert_cycle_s">
                    <xsl:value-of select="normalize-space($SCORES/res:cycleName/text())"/>
                    <!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:name[@type='conference']/m:namePart/text())"/>-->
                </field>
                <field name="atm_facet_concert_title_s">
                    <xsl:value-of select="normalize-space($SCORES/res:concertName/text())"/>
                    <!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:titleInfo[@type='alternative'][1]/m:title/text())"/>-->
                </field>
                <field name="atm_facet_concert_cycle_s">
                    <xsl:value-of select="normalize-space($SCORES/res:cycleName/text())"/>
                    <!--<xsl:value-of select="normalize-space($C_MODS/m:modsCollection/m:mods/m:name[@type='conference']/m:namePart/text())"/>-->
                </field>

                <xsl:variable name="date">
                  <xsl:call-template name="get_concert_date">
                    <xsl:with-param name="concert_pid" select="substring-after($SCORES/res:concert/@uri, '/')"/>
                  </xsl:call-template>
                </xsl:variable>
                
                <xsl:if test="$date">
                  <xsl:variable name="year" select="substring($date, 1, 4)"/>
                  <field name="atm_facet_concert_date_dt">
                      <xsl:value-of select="$date"/>
                  </field>
                  <field name="atm_facet_year_s">
                      <xsl:value-of select="$year"/>
                  </field>
                  <!-- TODO (minor): Determine if these other date fields are really necessary... -->
                  <field name="atm_performance_concert_date_dt">
                      <xsl:value-of select="$date"/>
                  </field>
                  <field name="atm_performance_year_s">
                      <xsl:value-of select="$year"/>
                  </field>
                </xsl:if>
                
                <field name="atm_performance_composer_name_s">
                    <xsl:value-of select="normalize-space($SCORES/res:composerName/text())"/>
                </field>
                <field name="atm_facet_composer_s">
                    <xsl:value-of select="normalize-space($SCORES/res:composerName/text())"/>
                </field>
                <field name="atm_performance_composer_pid_s">
                    <xsl:value-of select="substring-after($SCORES/res:composer/@uri, '/')"/>
                </field>
                
                <field name="atm_performance_order_i">
                    <xsl:value-of select="normalize-space($SCORES/res:order/text())"/>
                </field>
                <!-- check if the score object has a PDF datastream...  Might this be better done with the resource index? -->
                <field name="atm_performance_score_pdf_b">
                    <xsl:choose>
                        <xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD,
                        '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($SCORES/res:score/@uri, 
                        '/') , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']"
                        >true</xsl:when>
                        <xsl:otherwise>false</xsl:otherwise>
                    </xsl:choose>
                </field>
                <xsl:if test="$SCORES/res:scoreTitn/text()">
                    <field name="atm_performance_score_titn_s">
                        <xsl:value-of select="$SCORES/res:scoreTitn/text()"/>
                    </field>
                </xsl:if>
        
                <!-- check if there is an MP3 in this performance (otherwise, they have to be in the movements) -->
                <field name="atm_performance_mp3_b">
                    <xsl:choose>
                        <xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD,
                        '@', $HOST, ':', $PORT, '/fedora/objects/', $pid , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='MP3']"
                        >true</xsl:when>
                        <xsl:otherwise>false</xsl:otherwise>
                    </xsl:choose>
                </field>
                
                <!-- TODO:  Is this what they want? -->
                <xsl:call-template name="digital_objects">
                    <xsl:with-param name="objectType" select="'performance'"/>
                    <xsl:with-param name="performance" select="$pid"/>
                </xsl:call-template>
                
                <!-- Use the XSLT extensions distinct function to count the number of players in a piece, based on pid...  Might want to select the pid better/more carefully? -->
                <xsl:variable name="number_of_performers" select="count(set:distinct($PLAYERS/people/doc[./field[@name='atm_type_s' and text()='Intérpretes']]/field[@name='rels_player_ms' and contains(text(), ':')]))"/>
                <field name="atm_facet_number_of_performers_s">
                    <xsl:choose>
                        <xsl:when test="$number_of_performers = 1">solo</xsl:when>
                        <xsl:when test="$number_of_performers = 2">duo</xsl:when>
                        <xsl:when test="$number_of_performers = 3">trio</xsl:when>
                        <xsl:when test="$number_of_performers = 4">cuarteto</xsl:when>
                        <xsl:when test="$number_of_performers = 5">quintento</xsl:when>
                        <xsl:otherwise>ensemble</xsl:otherwise>
                    </xsl:choose>
                </field>
        
                <xsl:for-each select="$PLAYERS/people/doc[field[@name='atm_type_s']/text()='Intérpretes']">
                    <!--  referenced pids -->
                    <xsl:copy-of select="field[@name='referenced_pids_ms']"/>
                    <xsl:variable name="person_pid" select="normalize-space(field[@name='PID']/text())"/>
                    <xsl:variable name="name" select="normalize-space(field[@name='atm_performer_name_s']/text())"/>
                    <xsl:variable name="group" select="normalize-space(field[@name='atm_performer_group_s']/text())"/> 
                    <xsl:variable name="inst" select="normalize-space(field[@name='atm_performer_instrument_s']/text())"/>
                    <xsl:variable name="class" select="normalize-space(field[@name='atm_performer_instrument_class_s']/text())"/>
                    <field name="atm_performance_player_pid_ms">
                        <xsl:value-of select="$person_pid"/>
                    </field>
                    <field name="atm_performance_player_ms">
                        <xsl:value-of select="$name"/>
                    </field>
                    <field name="atm_performance_inst_ms">
                        <xsl:value-of select="$inst"/>
                    </field>
                    <field name="atm_performance_inst_class_ms">
                        <xsl:value-of select="$class"/>
                    </field>
                    <field name="atm_facet_player_pid_ms">
                        <xsl:value-of select="$person_pid"/>
                    </field>
                    <field name="atm_facet_player_ms">
                        <xsl:value-of select="$name"/>
                    </field>
                    <field name="atm_facet_group_ms">
                        <xsl:value-of select="$group"/>
                    </field>
                    <field name="atm_facet_instrument_ms">
                        <xsl:value-of select="$inst"/>
                    </field>
                    <field name="atm_facet_instrument_class_ms">
                        <xsl:value-of select="$class"/>
                    </field>
                </xsl:for-each>
            </doc>
        </xsl:if>
    </xsl:template>
    
    
    <xsl:template name="atm_movement">
        <xsl:param name="pid"/>
        
        <doc>
            <field name="PID">
                <xsl:value-of select="$pid"/>
            </field>
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
            <field name="hasMP3_b">
                <xsl:choose>
                    <xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid , '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='MP3']">true</xsl:when>
                    <xsl:otherwise>false</xsl:otherwise>
                </xsl:choose>
            </field>
            <xsl:variable name="ITEM_TF">
                <xsl:call-template name="perform_query">
                    <xsl:with-param name="query" select="concat('
                        select $name $cOrder $pOrder $performance from &lt;#ri&gt;
                        where $movement &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
                        and $movement &lt;dc:title&gt; $name
                        and $movement &lt;fedora-rels-ext:isMemberOf&gt; $performance
                        and $performance &lt;', $NAMESPACE, 'concertOrder&gt; $cOrder
                        and $movement &lt;', $NAMESPACE, 'pieceOrder&gt; $pOrder
                    ')"/>
                </xsl:call-template>
            </xsl:variable>
            
            <!--  referenced pids -->
            <xsl:call-template name="add_referenced_pids">
              <xsl:with-param name="results" select="xalan:nodeset($ITEM_TF)/res:sparql/res:results"/>
            </xsl:call-template>
            
            <xsl:for-each select="xalan:nodeset($ITEM_TF)/res:sparql/res:results/res:result">
                <field name="title_s">    
                    <xsl:value-of select="normalize-space(res:name/text())"/>
                </field>
                <field name="cOrder_s">
                    <xsl:value-of select="res:cOrder/text()"/>
                </field>
                <field name="pOrder_s">
                    <xsl:value-of select="res:pOrder/text()"/>
                </field>
                <field name="cOrder_i">
                    <xsl:value-of select="res:cOrder/text()"/>
                </field>
                <field name="pOrder_i">
                    <xsl:value-of select="res:pOrder/text()"/>
                </field>
            </xsl:for-each>
        </doc>
    </xsl:template>
    
    <!-- get the title of the piece, composers name, titn id, and PDF status -->
    <xsl:template name="atm_score">
        <xsl:param name="pid" select="no_pid"/>
        
        <xsl:variable name="SCORE_RESULT_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query" select="concat('
                    PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                    PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                    PREFIX fjm-titn: &lt;http://digital.march.es/titn#&gt;
                    SELECT $title $composerName $composer $titn 
                    FROM &lt;#ri&gt;
                    WHERE {
                      $score dc:title $title ;
                             atm-rel:composedBy $composer .
                      OPTIONAL{$score fjm-titn:score $titn}.
                      $composer dc:title $composerName .
                      FILTER(sameterm($score, &lt;fedora:', $pid, '&gt;))
                    }
                ')"/>
                <xsl:with-param name="lang" select="'sparql'"/>
                <xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="CONCERT_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query" select="concat('
                    select $performance $concert from &lt;#ri&gt;
                    where $score &lt;mulgara:is&gt; &lt;info:fedora/', $pid, '&gt;
                    and $performance &lt;', $NAMESPACE, 'basedOn&gt; $score
                    and $performance &lt;fedora-rels-ext:isMemberOf&gt; $concert
                    and $performance &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
                ')"/>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:variable name="SCORE_RESULT" select="xalan:nodeset($SCORE_RESULT_TF)/res:sparql/res:results/res:result"/>
        <xsl:variable name="SCORE_XML" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                    $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/OriginalXML/content'))"/>
        <xsl:variable name="SCORE_DATASTREAMS" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                    $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams?format=xml'))"/>
        <doc>
            <field name="PID">
                <xsl:value-of select="$pid"/>
            </field>
            
            <!--  referenced pids -->
            <xsl:for-each select="$SCORE_RESULT/*[@uri]">  
              <field name="referenced_pids_ms">
                <xsl:value-of select="normalize-space(substring-after(@uri, '/'))"/>
              </field>
            </xsl:for-each>
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
            
            <field name="atm_type_s">Partituras</field>
            
            <field name="atm_score_composer_es">
                <xsl:value-of select="normalize-space($SCORE_RESULT/res:composerName/text())"/>
            </field>
            <field name="atm_facet_composer_s">
                <xsl:value-of select="normalize-space($SCORE_RESULT/res:composerName/text())"/>
            </field>
            <field name="atm_score_composer_pid_s">
                <xsl:value-of select="substring-after($SCORE_RESULT/res:composer/@uri, '/')"/>
            </field>
            <field name="atm_score_title_es">
                <xsl:value-of select="normalize-space($SCORE_RESULT/res:title/text())"/>
            </field>
            <field name="atm_score_titn_s">
                <xsl:choose>
                    <xsl:when test="$SCORE_RESULT/res:titn/@bound">
                        <!-- FIXME:  Magic numbers?  Not too bad, I suppose... -->
                        <xsl:value-of select="-1"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$SCORE_RESULT/res:titn/text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </field>
            
            <xsl:for-each select="xalan:nodeset($CONCERT_TF)/res:sparql/res:results/res:result/res:performance">
                <xsl:variable name="PERFORMER_TF">
                    <people>
                        <xsl:call-template name="atm_performer">
                            <xsl:with-param name="performance" select="substring-after(@uri, '/')"/>
                        </xsl:call-template>
                    </people>
                </xsl:variable>
                <xsl:for-each select="xalan:nodeset($PERFORMER_TF)/people/doc[field[@name='atm_type_s']/text()='Intérpretes']">
                    <!--  referenced pids -->
                    <xsl:copy-of select="field[@name='referenced_pids_ms']"/>
                    
                    <field name="atm_score_concert_pid_ms">
                        <xsl:value-of select="field[@name='atm_performer_concert_pid_s']"/>
                    </field>
                    <field name="atm_score_concert_title_ms">
                        <xsl:value-of select="field[@name='atm_performer_concert_title_s']"/>
                    </field>
                    <field name="atm_score_concert_cycle_ms">
                        <xsl:value-of select="field[@name='atm_performer_concert_cycle_s']"/>
                    </field>
                    <field name="atm_facet_concert_title_ms">
                        <xsl:value-of select="field[@name='atm_performer_concert_title_s']"/>
                    </field>
                    <field name="atm_facet_concert_cycle_ms">
                        <xsl:value-of select="field[@name='atm_performer_concert_cycle_s']"/>
                    </field>
                    <field name="atm_score_perfomer_name_ms">
                        <xsl:value-of select="field[@name='atm_performer_name_s']"/>
                    </field>
                    <field name="atm_score_performer_group_ms">
                        <xsl:value-of select="field[@name='atm_performer_group_s']"/>
                    </field>
                </xsl:for-each>
            </xsl:for-each>
            
            <xsl:choose>
                <xsl:when test="$SCORE_DATASTREAMS/fds:objectDatastreams/fds:datastream[@dsid='PDF']">
                    <field name="atm_score_pdf_b">true</field>
                    <field name="atm_digital_objects_ms">Partitura</field>
                </xsl:when>
                <xsl:otherwise>
                    <field name="atm_score_pdf_b">false</field>
                </xsl:otherwise>
            </xsl:choose>
            
        </doc>
    </xsl:template>
    
    <xsl:template name="atm_program">
        <xsl:param name="pid" select="no_pid"/>
        
        <doc>
            <field name="PID">
                <xsl:value-of select="$pid"/>
            </field>
            
            <field name="atm_type_s">Programas de mano</field>
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
            
            <xsl:variable name="CONCERT_QUERY_TF">
                <xsl:call-template name="perform_query">
                    <xsl:with-param name="query" select="concat('
                        PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                        PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                        PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                        PREFIX fedora-view: &lt;info:fedora/fedora-system:def/view#&gt;
                        PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                        PREFIX atm: &lt;info:fedora/atm:&gt;
                        SELECT $concert $concertTitle $cycle $concertCycle $author $authorName $programTitn $score $pieceName
                        FROM &lt;#ri&gt;
                        WHERE {
                            $program fedora-rels-ext:isMemberOf $concert .
                            $concert fedora-rels-ext:isMemberOf $cycle ;
                                     fedora-model:hasModel atm:concertCModel ;
                                     dc:title $concertTitle .
                            $performance fedora-rels-ext:isMemberOf $concert ;
                                         fedora-model:hasModel atm:performanceCModel ;
                                         atm-rel:basedOn $score .
                            $score dc:title $pieceName .
                            $cycle dc:title $concertCycle .
                            OPTIONAL {
                                $program atm-rel:authoredBy $author .
                                $author dc:title $authorName
                            } .
                            OPTIONAL {
                                $program fjm-titn:program $programTitn
                            } .
                            FILTER(sameterm($program, &lt;info:fedora/', $pid, '&gt;))
                        }
                    ')"/>
                    <xsl:with-param name="lang" select="'sparql'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="CONCERT_INFO" select="xalan:nodeset($CONCERT_QUERY_TF)/res:sparql/res:results"/>
            
            <xsl:call-template name="add_referenced_pids">
              <xsl:with-param name="results" select="$CONCERT_INFO"/>
            </xsl:call-template>
            
            <field name="atm_program_concert_title_s">
                <xsl:value-of select="normalize-space($CONCERT_INFO/res:result[1]/res:concertTitle/text())"/>
            </field>
            <field name="atm_program_concert_cycle_s">
                <xsl:value-of select="normalize-space($CONCERT_INFO/res:result[1]/res:concertCycle/text())"/>
            </field>
            <field name="atm_facet_concert_title_s">
                <xsl:value-of select="normalize-space($CONCERT_INFO/res:result[1]/res:concertTitle/text())"/>
            </field>
            <field name="atm_facet_concert_cycle_s">
                <xsl:value-of select="normalize-space($CONCERT_INFO/res:result[1]/res:concertCycle/text())"/>
            </field>
            
            <xsl:for-each select="$CONCERT_INFO/res:result">
                <field name="atm_facet_piece_ms">
                    <xsl:value-of select="normalize-space(res:pieceName/text())"/>
                </field>
            </xsl:for-each>
            
            <!-- FIXME: Titn is currently only in the concert level...  Perhaps during import it might be moved
                to a better space (i.e. inside the program object) -->
            <xsl:if test="$CONCERT_INFO/res:result/res:programTitn[text()]">
                <field name="atm_program_titn_s">
                    <xsl:value-of select="$CONCERT_INFO/res:result/res:programTitn/text()"/>
                </field>
            </xsl:if>
            
            <xsl:variable name="date">
              <xsl:call-template name="get_concert_date">
                <xsl:with-param name="concert_pid" select="substring-after($CONCERT_INFO/res:result[1]/res:concert/@uri, '/')"/>
              </xsl:call-template>
            </xsl:variable>
            <field name="atm_program_date_dt">
                <xsl:value-of select="$date"/>
            </field>
            <field name="atm_program_year_s">
                <xsl:value-of select="substring($date, 1, 4)"/>
            </field>
            <field name="atm_facet_year_s">
                <xsl:value-of select="substring($date, 1, 4)"/>
            </field>
            
            <!-- FIXME (major): Trigger reindex when author object changes.
                NOTE:  The 'Texto Compositores' entry is created on ingest, and is actually created from the object "atm:composerText"-->
            <xsl:for-each select="$CONCERT_INFO/res:result[./res:authorName/text()]">
                <field name="atm_program_author_ms">
                    <xsl:value-of select="normalize-space(res:authorName/text())"/>
                </field>
            </xsl:for-each>
            
            
            <xsl:choose>
                <xsl:when test="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams?format=xml'))/fds:objectDatastreams/fds:datastream[@dsid='PDF']">
                    <field name="atm_program_pdf_b">true</field>
                </xsl:when>
                <xsl:otherwise>
                    <field name="atm_program_pdf_b">false</field>
                </xsl:otherwise>
            </xsl:choose>
            
            
        </doc>
    </xsl:template>
    
    <xsl:template name="atm_lecture">
        <xsl:param name="pid" select="''"/>
        
        <doc>
            <field name="PID">
                <xsl:value-of select="$pid"/>
            </field>
            <xsl:variable name="LECT_TF">
                <xsl:call-template name="perform_query">
                    <xsl:with-param name="query" select="concat('
                        PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                        PREFIX fedora: &lt;info:fedora/&gt;
                        PREFIX atm: &lt;fedora:atm:&gt;
                        PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                        PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                        PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                        SELECT $lectureTitle $concertTitle $cycle $concertCycle $concert
                        FROM &lt;#ri&gt;
                        WHERE {
                            $lecture fedora-rels-ext:isMemberOf $concert ;
                                     fedora-model:hasModel atm:lectureCModel ;
                                     fedora-model:state fedora-model:Active .
                            OPTIONAL { $lecture dc:description $lectureTitle } .
                            $concert dc:title $concertTitle ;
                                     fedora-rels-ext:isMemberOf $cycle ;
                                     fedora-model:state fedora-model:Active .
                            $cycle dc:title $concertCycle .
                            FILTER(sameterm($lecture, &lt;fedora:', $pid, '&gt;))
                        }
                        ')"/>
                    <xsl:with-param name="lang" select="'sparql'"/>
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="LECT" select="xalan:nodeset($LECT_TF)/res:sparql/res:results"/>
            
            <!--  referenced pids -->
            <xsl:call-template name="add_referenced_pids">
              <xsl:with-param name="results" select="$LECT"/>
            </xsl:call-template>
            
            <xsl:for-each select="$LECT/res:result[1]">
                <field name="atm_type_s">Archivo de voz</field>
                <field name="atm_lecture_title_s">
                    <xsl:value-of select="res:lectureTitle/text()"/>
                </field>
                <field name="atm_lecture_concert_title_s">
                    <xsl:value-of select="res:concertTitle/text()"/>
                </field>
                <field name="atm_lecture_concert_cycle_s">
                    <xsl:value-of select="res:concertCycle/text()"/>
                </field>
                <field name="atm_facet_concert_title_s">
                    <xsl:value-of select="normalize-space(res:concertTitle/text())"/>
                </field>
                <field name="atm_facet_concert_cycle_s">
                    <xsl:value-of select="normalize-space(res:concertCycle/text())"/>
                </field>
                <xsl:variable name="date">
                  <xsl:call-template name="get_concert_date">
                    <xsl:with-param name="concert_pid" select="substring-after($LECT/res:result[1]/res:concert/@uri, '/')"/>
                  </xsl:call-template>
                </xsl:variable>
                <field name="atm_facet_concert_date_dt">
                    <xsl:value-of select="$date"/>
                </field>
                <field name="atm_facet_year_s">
                    <xsl:value-of select="substring($date, 1, 4)"/>
                </field>
            </xsl:for-each>
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
        </doc>
    </xsl:template>
    
    <xsl:template name="atm_person">
        <xsl:param name="pid" select="'empty'"/>
        
        <xsl:variable name="COMPOSER_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query" select="concat('
                    PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                    PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                    SELECT $icon $name
                    FROM &lt;#ri&gt;
                    WHERE {
                        $person dc:title $name .
                        OPTIONAL{$icon atm-rel:isIconOf $person} .
                        FILTER(sameterm($person, &lt;info:fedora/', $pid, '&gt;))
                    }
                ')"/>
                <xsl:with-param name="lang">sparql</xsl:with-param>
                <xsl:with-param name="additional_params" select="'&amp;limit=1'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="COMPOSER_CONCERT_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query" select="concat('
                    PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                    PREFIX fedora: &lt;info:fedora/&gt;
                    PREFIX atm: &lt;fedora:atm:&gt;
                    PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                    PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                    PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                    SELECT $performance $concert $concertName $cycle $score $concertCycle $composer
                    FROM &lt;#ri&gt;
                    WHERE {
                        $performance fedora-rels-ext:isMemberOf $concert ;
                                     fedora-model:state fedora-model:Active ;
                                     atm-rel:basedOn $score .
                        $concert fedora-rels-ext:isMemberOf $cycle ;
                                 fedora-model:state fedora-model:Active ;
                                 dc:title $concertName .
                        $cycle dc:title $concertCycle .
                        $score atm-rel:composedBy $composer .
                        FILTER(sameterm($composer, &lt;info:fedora/', $pid, '&gt;)) 
                    }
                ')"/>
                <xsl:with-param name="lang">sparql</xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        
        <doc>
            <field name="PID">
                    <xsl:value-of select="$pid"/>
            </field>
            
            <xsl:for-each select="xalan:nodeset($COMPOSER_TF)/res:sparql/res:results/res:result">
                <!--  referenced pids -->
                <xsl:for-each select="*[@uri]">
                  <field name="referenced_pids_ms">
                    <xsl:value-of select="substring-after(@uri, '/')"/>
                  </field>
                </xsl:for-each>
                <field name="atm_composer_name_s">
                    <xsl:value-of select="normalize-space(res:name/text())"/>
                </field>
                <!-- I'm not quite liking this at the moment, as it binds to a single image if there isn't one...  Should be left up to the theme layer somehow?  Setup stuff in the Drupal preprocessor function to allow it to change? -->
                <field name="atm_composer_icon_s">
                    <xsl:choose>
                        <xsl:when test="res:icon/@uri">                            
                            <xsl:value-of select="substring-after(res:icon/@uri, '/')"/>
                        </xsl:when>
                        <xsl:otherwise>atm:defaultPersonImage</xsl:otherwise>
                    </xsl:choose>
                </field>
                <field name="person_name_s">
                    <xsl:value-of select="normalize-space(res:name/text())"/>
                </field>
                <xsl:if test="res:icon/@uri">
                    <field name="person_icon_s">
                        <xsl:value-of select="substring-after(res:icon/@uri, '/')"/>
                    </field>
                </xsl:if>
            </xsl:for-each>
            
            <xsl:if test="count(xalan:nodeset($COMPOSER_CONCERT_TF)/res:sparql/res:results/res:result[res:composer[@uri]]) &gt; 0">
                <field name="atm_type_ms">Compositores</field>
            </xsl:if>
            
            <xsl:for-each select="xalan:nodeset($COMPOSER_CONCERT_TF)/res:sparql/res:results/res:result">
                <!--  referenced pids -->
                <xsl:for-each select="*[@uri]">
                  <field name="referenced_pids_ms">
                    <xsl:value-of select="substring-after(@uri, '/')"/>
                  </field>
                </xsl:for-each>
                
                <field name="atm_facet_concert_title_ms">
                    <xsl:value-of select="res:concertName/text()"/>
                </field>
                <field name="atm_facet_concert_cycle_ms">
                    <xsl:value-of select="res:concertCycle/text()"/>
                </field>
                <field name="atm_person_concert_pid_ms">
                    <xsl:value-of select="substring-after(res:concert/@uri, '/')"/>
                </field>
                
                <xsl:variable name="date" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                $HOST, ':', $PORT, '/fedora/objects/', substring-after(res:concert/@uri, '/'), '/datastreams/CustomXML/content'))/Concierto/FECHA/text()"/>
                <xsl:if test="$date">
                    <!-- FIXME (minor): Really, this should be done through the use of date faceting in solr, based on the _dt above (an actual date/time value)...  Same for other instances of similar code (grabbing the year from the date) -->
                    <field name="atm_person_year_ms">
                        <xsl:value-of select="substring($date, 1, 4)"/>
                    </field>
                    <field name="atm_facet_concert_year_ms">
                        <xsl:value-of select="substring($date, 1, 4)"/>
                    </field>
                </xsl:if>
                
                <xsl:call-template name="digital_objects">
                    <xsl:with-param name="objectType" select="'performance'"/>
                    <xsl:with-param name="performance" select="substring-after(res:performance/@uri, '/')"/>
                </xsl:call-template>
            </xsl:for-each>
            
            <xsl:apply-templates select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
            $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/', 'EAC-CPF', '/content'))/*"/>
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>

            <xsl:call-template name="digital_objects">
                <xsl:with-param name="objectType">composer</xsl:with-param>
                <xsl:with-param name="person" select="$pid"/>
            </xsl:call-template>
        </doc>
    </xsl:template>
    
    <xsl:template name="atm_performer">
        <!-- Only a single parameter should be given... -->
        <xsl:param name="pid" select="'no'"/> <!-- based on "performer pid" -->
        <xsl:param name="performance" select="'no'"/> <!-- based on "performance pid", and so on -->
        <xsl:param name="person" select="'no'"/>
        <xsl:param name="concert">no</xsl:param>
        
        <xsl:variable name="PERFORMER_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query">
                    <xsl:value-of select="concat('
                        PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                        PREFIX atm: &lt;info:fedora/atm:&gt;
                        PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                        PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                        PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                        SELECT $concert $performerObj $performance $person $personName $instrument $instrumentName $instrumentClass $instrumentClassName $group $groupName $concertTitle $concertCycle $cycleName $score $pieceName $concertOrder
                        WHERE {
                            $performerObj atm-rel:performance $performance ;
                                          atm-rel:player $person ;
                                          atm-rel:instrument $instrument ;
                                          atm-rel:group $group .
                            $performance fedora-rels-ext:isMemberOf $concert ;
                                         atm-rel:concertOrder $concertOrder ;
                                         atm-rel:basedOn $score .
                            $concert dc:title $concertTitle ;
                                     fedora-rels-ext:isMemberOf $concertCycle ;
                                     fedora-model:state fedora-model:Active .
                            $concertCycle dc:title $cycleName .
                            $person dc:title $personName .
                            $instrument dc:title $instrumentName ;
                                        fedora-rels-ext:isMemberOf $instrumentClass .
                            $instrumentClass dc:title $instrumentClassName .
                            $group dc:title $groupName .
                            $score dc:title $pieceName ;
                                   fedora-model:state fedora-model:Active .
                            FILTER(
                    ')"/>
                    <!-- choose the performer docs to create depending on the input parameters -->
                    <xsl:choose>
                        <xsl:when test="not($pid='no')">
                            <xsl:value-of select="concat('sameterm($performerObj, &lt;info:fedora/', $pid, '&gt;)')"/>
                        </xsl:when>
                        <xsl:when test="not($performance='no')">
                            <xsl:value-of select="concat('sameterm($performance, &lt;info:fedora/', $performance, '&gt;)')"/>
                        </xsl:when>
                        <xsl:when test="not($person='no')">
                            <xsl:value-of select="concat('sameterm($person, &lt;info:fedora/', $person, '&gt;)')"/>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:value-of select="')}'"/>
                </xsl:with-param>
                <xsl:with-param name="lang">sparql</xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:for-each select="xalan:nodeset($PERFORMER_TF)/res:sparql/res:results/res:result">
            <doc>
                <field name="PID">
                    <xsl:value-of select="substring-after(res:performerObj/@uri, '/')"/>
                </field>
                <field name="atm_type_s">Intérpretes</field>
                
                <!--  referenced pids -->
                <xsl:for-each select="*[@uri]">
                  <field name="referenced_pids_ms">
                    <xsl:value-of select="substring-after(@uri, '/')"/>
                  </field>
                </xsl:for-each>
            
                <field name="atm_performer_name_s">
                    <xsl:value-of select="normalize-space(res:personName/text())"/>
                </field>
                <field name="atm_performer_concert_pid_s">
                    <xsl:value-of select="substring-after(res:concert/@uri, '/')"/>
                </field>
                <field name="atm_performer_instrument_s">
                    <xsl:value-of select="normalize-space(res:instrumentName/text())"/>
                </field>
                <field name="atm_performer_instrument_class_s">
                    <xsl:value-of select="normalize-space(res:instrumentClassName/text())"/>
                </field>
                <field name="atm_performer_group_s">
                    <xsl:value-of select="normalize-space(res:groupName/text())"/>
                </field>
                <field name="atm_performer_concert_title_s">
                    <xsl:value-of select="normalize-space(res:concertTitle/text())"/>
                </field>
                <field name="atm_performer_concert_cycle_s">
                    <xsl:value-of select="normalize-space(res:cycleName/text())"/>
                </field>
                <field name="atm_performer_piece_title_s">
                    <xsl:value-of select="normalize-space(res:pieceName/text())"/>
                </field>
                <field name="atm_performer_concert_order_s">
                    <xsl:value-of select="normalize-space(res:concertOrder/text())"/>
                </field>
                <field name="atm_facet_group_s">
                    <xsl:value-of select="normalize-space(res:groupName/text())"/>
                </field>
                <field name="atm_facet_instrument_s">
                    <xsl:value-of select="normalize-space(res:instrumentName/text())"/>
                </field>
                <field name="atm_facet_instrument_class_s">
                    <xsl:value-of select="normalize-space(res:instrumentClassName/text())"/>
                </field>
                <field name="atm_facet_concert_title_s">
                    <xsl:value-of select="normalize-space(res:concertTitle/text())"/>
                </field>
                <field name="atm_facet_concert_cycle_s">
                    <xsl:value-of select="normalize-space(res:cycleName/text())"/>
                </field>
                <field name="atm_facet_piece_s">
                    <xsl:value-of select="normalize-space(res:pieceName/text())"/>
                </field>
                <!-- TODO: get the concert date from somewhere... -->
                <xsl:variable name="date">
                  <xsl:call-template name="get_concert_date">
                    <xsl:with-param name="concert_pid" select="substring-after(res:concert/@uri, '/')"/>
                  </xsl:call-template>
                </xsl:variable>
                <xsl:if test="$date">
                    <field name="atm_performer_date_dt">
                        <xsl:value-of select="$date"/>
                    </field>
                    
                    <!-- FIXME (minor): Really, this should be done through the use of date faceting in solr, based on the _dt above (an actual date/time value)...  Same for other instances of similar code (grabbing the year from the date) -->
                    <field name="atm_performer_year_s">
                        <xsl:value-of select="substring($date, 1, 4)"/>
                    </field>
                    <field name="atm_facet_concert_year_s">
                        <xsl:value-of select="substring($date, 1, 4)"/>
                    </field>
                </xsl:if>
                
                <xsl:call-template name="rels_ext">
                    <xsl:with-param name="pid" select="substring-after(res:performerObj/@uri, '/')"/>
                </xsl:call-template>
                
                <!-- Not really needed, but it'll allow them to sort nicely... (Used in A-Z selector)  Blargh. -->
                <xsl:apply-templates select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
            $HOST, ':', $PORT, '/fedora/objects/', substring-after(res:person/@uri, '/'), '/datastreams/', 'EAC-CPF', '/content'))/*"/>
            </doc>
            
            <xsl:call-template name="atm_person">
                <xsl:with-param name="pid" select="substring-after(res:person/@uri, '/')"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="digital_objects">
        <xsl:param name="objectType"/>
        <xsl:param name="performance"/>
        <xsl:param name="concert"/>
        <xsl:param name="person"/>
        
        <xsl:choose>
            <xsl:when test="$objectType='performance'">
                <xsl:variable name="PERFORMANCE_TF">
                    <xsl:call-template name="perform_query">
                        <xsl:with-param name="query" select="concat('
                            PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                            PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                            PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                            PREFIX fedora-view: &lt;info:fedora/fedora-system:def/view#&gt;
                            PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                            PREFIX atm: &lt;info:fedora/atm:&gt;
                            SELECT $score_DSs $perf_DSs $mov_DSs
                            FROM &lt;#ri&gt;
                            WHERE {
                                $performance fedora-model:hasModel atm:performanceCModel ;
                                             atm-rel:basedOn $score ;
                                             fedora-model:state fedora-model:Active .
                                OPTIONAL {
                                    $performance fedora-view:disseminates $perf_DSs .
                                    $perf_DSs fedora-view:disseminationType &lt;info:fedora/*/MP3&gt; 
                                } .
                                OPTIONAL { 
                                    $score fedora-view:disseminates $score_DSs .
                                    $score_DSs fedora-view:disseminationType &lt;info:fedora/*/PDF&gt; 
                                } .
                                OPTIONAL {
                                    $movement fedora-rels-ext:isMemberOf $performance ;
                                              fedora-model:hasModel atm:movementCModel ;
                                              fedora-view:disseminates $mov_DSs .
                                    $mov_DSs fedora-view:disseminationType &lt;info:fedora/*/MP3&gt; .
                                } .
                                FILTER(sameterm($performance, &lt;info:fedora/', $performance, '&gt;))
                            }
                        ')"/>
                        <xsl:with-param name="lang" select="'sparql'"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="PERFORMANCES" select="xalan:nodeset($PERFORMANCE_TF)/res:sparql/res:results"/>
                <xsl:if test="count($PERFORMANCES/res:result[./res:perf_DSs/@uri or ./res:mov_DSs/@uri]) > 0">
                    <field name="atm_digital_objects_ms">Audio Concierto</field>
                </xsl:if>
                <xsl:if test="count($PERFORMANCES/res:result[./res:score_DSs/@uri]) > 0">
                    <field name="atm_digital_objects_ms">Partitura</field>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$objectType='concert'">
                <xsl:variable name="TYPES_TF">
                    <xsl:call-template name="perform_query">
                        <!-- Would these types of queries make more sense using 'OPTIONAL' instead of 'UNION' -->
                        <xsl:with-param name="query" select="concat('
                            PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                            PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                            PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                            PREFIX fedora-view: &lt;info:fedora/fedora-system:def/view#&gt;
                            PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                            PREFIX atm: &lt;info:fedora/atm:&gt;
                            SELECT $lecture $lect_type $performance $score $program
                            FROM &lt;#ri&gt;
                            WHERE {
                                {
                                    $program fedora-rels-ext:isMemberOf $concert ;
                                             fedora-model:hasModel atm:programCModel ;
                                             fedora-view:disseminates $prog_DSs .
                                    $prog_DSs fedora-view:disseminationType &lt;info:fedora/*/PDF&gt; .
                                }
                                UNION
                                {
                                    $lecture fedora-rels-ext:isMemberOf $concert ;
                                             fedora-model:hasModel atm:lectureCModel ;
                                             dc:subject $lect_type .
                                }
                                UNION
                                {
                                    $performance fedora-rels-ext:isMemberOf $concert ;
                                                 fedora-model:hasModel atm:performanceCModel ;
                                                 fedora-view:disseminates $perf_DSs .
                                    $perf_DSs fedora-view:disseminationType $perf_DT .
                                    OPTIONAL {
                                        $performance atm-rel:basedOn $score .
                                        $score fedora-model:hasModel atm:scoreCModel ;
                                               fedora-view:disseminates $score_DSs .
                                        $score_DSs fedora-view:disseminationType &lt;info:fedora/*/PDF&gt;
                                    } .
                                    OPTIONAL {
                                        $movement fedora-rels-ext:isMemberOf $performance ;
                                                  fedora-model:hasModel atm:movementCModel ;
                                                  fedora-view:disseminates $mov_DSs .
                                        $mov_DSs fedora-view:disseminationType $mov_DT .
                                    }
                                    FILTER(sameterm($perf_DT, &lt;info:fedora/*/MP3&gt;) || sameterm($mov_DT, &lt;info:fedora/*/MP3&gt;))
                                }
                                FILTER(sameterm($concert, &lt;info:fedora/', $concert, '&gt;))
                            }
                        ')"/>
                        <xsl:with-param name="lang" select="'sparql'"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="TYPES" select="xalan:nodeset($TYPES_TF)"/>
                <xsl:for-each select="$TYPES/res:sparql/res:results/res:result[res:lecture/@uri]">
                    <field name="atm_digital_objects_ms">
                    <xsl:choose>
                        <!-- May have to handle others differently...  This handles the three which are currently present (Conferencia, Presentacions and Agradecimientos) -->
                        <xsl:when test="false">Garbage</xsl:when>
                        <xsl:otherwise>Audio <xsl:value-of select="normalize-space(res:lect_type/text())"/></xsl:otherwise>
                    </xsl:choose>
                    </field>
                </xsl:for-each>
                <xsl:if test="count($TYPES/res:sparql/res:results/res:result/res:performance[@uri]) > 0">
                    <field name="atm_digital_objects_ms">Audio Concierto</field>
                </xsl:if>
                <!--<xsl:if test="count($TYPES/res:sparql/res:results/res:result/res:program[@uri]) > 0">
                    <field name="atm_digital_objects_ms">Programa de mano en PDF</field>
                </xsl:if>-->
                <xsl:if test="count($TYPES/res:sparql/res:results/res:result/res:score[@uri]) > 0">
                    <field name="atm_digital_objects_ms">Partitura</field>
                </xsl:if>
            </xsl:when>
            <xsl:when test="$objectType='composer'">
                <xsl:variable name="PERFORMANCE_TF">
                    <xsl:call-template name="perform_query">
                        <xsl:with-param name="query" select="concat('
                            PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                            PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                            PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                            PREFIX fedora-view: &lt;info:fedora/fedora-system:def/view#&gt;
                            PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                            PREFIX atm: &lt;info:fedora/atm:&gt;
                            SELECT $score_DSs $perf_DSs $mov_DSs
                            FROM &lt;#ri&gt;
                            WHERE {
                                $performance fedora-model:hasModel atm:performanceCModel ;
                                             atm-rel:basedOn $score ;
                                             fedora-model:state fedora-model:Active .
                                $score atm-rel:composedBy $composer .
                                OPTIONAL {
                                    $performance fedora-view:disseminates $perf_DSs .
                                    $perf_DSs fedora-view:disseminationType &lt;info:fedora/*/MP3&gt; 
                                } .
                                OPTIONAL { 
                                    $score fedora-view:disseminates $score_DSs .
                                    $score_DSs fedora-view:disseminationType &lt;info:fedora/*/PDF&gt; 
                                } .
                                OPTIONAL {
                                    $movement fedora-rels-ext:isMemberOf $performance ;
                                              fedora-model:hasModel atm:movementCModel ;
                                              fedora-view:disseminates $mov_DSs .
                                    $mov_DSs fedora-view:disseminationType &lt;info:fedora/*/MP3&gt; .
                                } .
                                FILTER(sameterm($composer, &lt;info:fedora/', $person, '&gt;))
                            }
                        ')"/>
                        <xsl:with-param name="lang" select="'sparql'"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="PERFORMANCES" select="xalan:nodeset($PERFORMANCE_TF)/res:sparql/res:results"/>
                <xsl:if test="count($PERFORMANCES/res:result[./res:perf_DSs/@uri or ./res:mov_DSs/@uri]) > 0">
                    <field name="atm_digital_objects_ms">Audio Concierto</field>
                </xsl:if>
                <xsl:if test="count($PERFORMANCES/res:result[./res:score_DSs/@uri]) > 0">
                    <field name="atm_digital_objects_ms">Partitura</field>
                </xsl:if>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="eac-cpf:nameEntry[@localType='primary']">
      <xsl:param name="prefix"/>
      <xsl:param name="suffix"/>
      
      <xsl:for-each select="eac-cpf:part[@localType]">
          <field>
              <xsl:attribute name="name">
                  <xsl:value-of select="concat($prefix, 'name_', @localType, $suffix)"/>
              </xsl:attribute>
              <xsl:value-of select="text()"/>
          </field>
      </xsl:for-each>
      
      <field>
        <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, 'complete', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="normalize-space(concat(eac-cpf:part[@localType='surname']/text(), ', ', eac-cpf:part[@localType='forename']/text()))"/>
      </field>
    </xsl:template>
    
    <xsl:template match="eac-cpf:addressLine">
      <xsl:param name="prefix"/>
      <xsl:param name="suffix"/>
      
      <field>
          <xsl:attribute name="name">
              <xsl:value-of select="concat($prefix, 'address_', @localType, $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="text()"/>
      </field>
    </xsl:template>
    
    <xsl:template match="eac-cpf:eac-cpf">
      <xsl:param name="prefix">eaccpf_</xsl:param>
      <xsl:param name="suffix">_es</xsl:param> <!-- 'edged' (edge n-gram) string (copied to *_et text)
            NOTE: As of writing this 2011/10/03 (about noon), *_es is single-valued, to allow sorting...  This'll
            explode if there are multiple values for a single field, though... Might be a good idea to select based on 
            distinct localTypes, and effectively merge them into a single field?-->
      <xsl:apply-templates select="eac-cpf:cpfDescription/eac-cpf:description//eac-cpf:place[@localType='primary']/eac-cpf:address/eac-cpf:addressLine[@localType] |
          eac-cpf:cpfDescription/eac-cpf:identity/eac-cpf:nameEntry[@localType='primary']">
        <xsl:with-param name="prefix" select="$prefix"/>
        <xsl:with-param name="suffix" select="$suffix"/>
      </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="nameEntry[@localType='primary']">
      <xsl:param name="prefix"/>
      <xsl:param name="suffix"/>
      
      <xsl:for-each select="part[@localType]">
          <field>
              <xsl:attribute name="name">
                  <xsl:value-of select="concat($prefix, 'name_', @localType, $suffix)"/>
              </xsl:attribute>
              <xsl:value-of select="text()"/>
          </field>
      </xsl:for-each>
      
      <field>
        <xsl:attribute name="name">
            <xsl:value-of select="concat($prefix, 'complete', $suffix)"/>
        </xsl:attribute>
        <xsl:value-of select="normalize-space(concat(part[@localType='surname']/text(), ', ', part[@localType='forename']/text()))"/>
      </field>
    </xsl:template>
    
    <xsl:template match="addressLine">
      <xsl:param name="prefix"/>
      <xsl:param name="suffix"/>
      
      <field>
          <xsl:attribute name="name">
              <xsl:value-of select="concat($prefix, 'address_', @localType, $suffix)"/>
          </xsl:attribute>
          <xsl:value-of select="text()"/>
      </field>
    </xsl:template>
    
    <xsl:template match="eac-cpf">
      <xsl:param name="prefix">eaccpf_</xsl:param>
      <xsl:param name="suffix">_es</xsl:param> <!-- 'edged' (edge n-gram) string (copied to *_et text)
            NOTE: As of writing this 2011/10/03 (about noon), *_es is single-valued, to allow sorting...  This'll
            explode if there are multiple values for a single field, though... Might be a good idea to select based on 
            distinct localTypes, and effectively merge them into a single field?-->
      <xsl:apply-templates select="cpfDescription/description//place[@localType='primary']/address/addressLine[@localType] |
          cpfDescription/identity/nameEntry[@localType='primary']">
        <xsl:with-param name="prefix" select="$prefix"/>
        <xsl:with-param name="suffix" select="$suffix"/>
      </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template name="perform_query">
        <xsl:param name="query"/>
        <xsl:param name="lang">itql</xsl:param>
        <xsl:param name="additional_params"/>
        
        <xsl:variable name="encoded_query" select="encoder:encode(normalize-space($query))"/>
        
        <xsl:variable name="query_url" select="concat($RISEARCH, $encoded_query, '&amp;lang=', $lang,  $additional_params)"/>
        <?xalan-doc-cache-off?>
        <xsl:copy-of select="document($query_url)"/>
        <!-- Doesn't work, as I input this into a variable...  Blargh
        <xsl:comment>
            <xsl:value-of select="$full_query"/>
        </xsl:comment>
        <xsl:copy-of select="$full_query"/>-->
    </xsl:template>
    
    <xsl:template name="rels_ext">
        <xsl:param name="pid" select="'no_pid'"/>
        
        <xsl:variable name="RELS_EXT" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/RELS-EXT/content'))"/>
        <xsl:for-each select="$RELS_EXT/rdf:RDF/rdf:Description/*">
            <field>
                <xsl:attribute name="name">
                    <xsl:value-of select="concat('rels_', local-name(), '_ms')"/>
                </xsl:attribute>
                <xsl:choose>
                    <xsl:when test="@rdf:resource">
                        <xsl:value-of select="substring-after(@rdf:resource, '/')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="text()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </field>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Get the value of the labels for all performers of the piece -->
    <xsl:template name="correlate_group_membership">
        <xsl:param name="pid" select="no_pid"/>

        <xsl:variable name="QUERIED">
            <xsl:call-template name="atm_performer">
                <xsl:with-param name="performance" select="$pid"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:copy-of select="xalan:nodeset($QUERIED)"/>
    </xsl:template>
</xsl:stylesheet>
