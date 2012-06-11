<?xml version="1.0" encoding="UTF-8"?> 
<!-- TODO Reconsider how names are acquired:  If labels are set properly on change,
    going out to most metadata files could be avoided, as the labels are available
    from the Resource Index...  On the otherhnad, if the labels become desynced, 
    there could be problems...  Might make a script (run via cron) to check if the 
    label is correct, and index if it is not? -->
    
<xsl:stylesheet version="2.0"
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
            exclude-result-prefixes="exts m rdf res fds ns xalan set">
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    <xsl:include href="file:/var/www/html/drupal/sites/all/modules/islandora_fjm/xsl/url_util.xslt"/>
    
    <!-- FIXME:  Should probably get these as parameters, or sommat -->
    <xsl:param name="HOST" select="'localhost'"/>
    <xsl:param name="PORT" select="'8080'"/>
    <xsl:param name="PROT" select="'http'"/>
    <xsl:param name="URLBASE" select="concat($PROT, '://', $HOST, ':', $PORT, '/')"/>
    <xsl:param name="REPOSITORYNAME" select="'fedora'"/>
    <xsl:param name="RISEARCH" select="concat($URLBASE, 'fedora/risearch',
        '?type=tuples&amp;flush=TRUE&amp;format=Sparql&amp;query=')" />
    <!--<xsl:param name="FEDORAUSERNAME" select="'fedoraAdmin'"/>
    <xsl:param name="FEDORAPASSWORD" select="'fedoraAdmin'"/>-->
    <xsl:param name="FEDORAUSERNAME" select="''"/>
    <xsl:param name="FEDORAPASSWORD" select="''"/>
    <xsl:param name="NAMESPACE" select="'http://digital.march.es/atmusica#'"/>

    <xsl:template name="fjm-atm">
        <xsl:param name="pid" select="'no_pid'"/>
        <xsl:param name="previous_items" select="''"/>
        <!-- Index based on CModel -->
        <xsl:if test="not(contains($previous_items, $pid))">
            <xsl:for-each select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                    $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/RELS-EXT/content'))/rdf:RDF/rdf:Description/*[local-name()='hasModel' and @rdf:resource]">
                <xsl:choose>
                    <xsl:when test="@rdf:resource='info:fedora/atm:concertCModel'">
                        <xsl:call-template name="atm_concert">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="@rdf:resource='info:fedora/atm:performanceCModel'">
                        <xsl:call-template name="atm_performance">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template>
                        <!--
                        <xsl:call-template name="atm_performer">
                            <xsl:with-param name="performance" select="$pid"/>
                        </xsl:call-template>-->
                    </xsl:when>
                    <xsl:when test="@rdf:resource='info:fedora/atm:scoreCModel'">
                        <!-- Index the score and then all concerts which contain a performances based on the score -->
                        <xsl:call-template name="atm_score">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="@rdf:resource='info:fedora/atm:programCModel'">
                        <xsl:call-template name="atm_program">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template> 
                    </xsl:when>
                    <xsl:when test="@rdf:resource='info:fedora/atm:personCModel'">
                        <xsl:call-template name="atm_person">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="@rdf:resource='info:fedora/atm:lectureCModel'">
                        <xsl:call-template name="atm_lecture">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:when test="@rdf:resource='info:fedora/atm:movementCModel'">
                        <xsl:call-template name="atm_movement">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- Handled elsewhere...
                    <xsl:when test="@rdf:resource='info:fedora/atm:performerCModel'">
                        <xsl:call-template name="atm_performer">
                            <xsl:with-param name="pid" select="$pid"/>
                        </xsl:call-template>
                    </xsl:when>-->
                    <xsl:otherwise>
                        <doc>
                            <field name="PID">
                                <xsl:value-of select="$pid"/>
                            </field>
                            <xsl:call-template name="rels_ext">
                                <xsl:with-param name="pid" select="$pid"/>
                            </xsl:call-template>
                        </doc>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="atm_concert">
        <xsl:param name="pid" select="no_pid"/>
        
        <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/CustomXML/content'))"/>
        <doc>
            <field name="PID">
                <xsl:value-of select="$pid"/>
            </field>
            <field name="atm_type_s">Conciertos</field>
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
        
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
                    SELECT $score $performance $composer $concertTitle $concertDesc $composerName $pieceName $cycleName $program $thumbnail
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
            
            <field name="atm_concert_title_s">
                <xsl:value-of select="normalize-space($SCORES/res:result[1]/res:concertTitle/text())"/>
            </field>
            <field name="atm_concert_cycle_s">
                <xsl:value-of select="normalize-space($SCORES/res:result[1]/res:cycleName/text())"/>
            </field>
            <!-- Don't really think that this is necessary:
            <field name="atm_facet_concert_title_s">
                <xsl:value-of select="normalize-space($SCORES/res:result[1]/res:concertTitle/text())"/>
            </field>-->
            <field name="atm_facet_concert_cycle_s">
                <xsl:value-of select="normalize-space($SCORES/res:result[1]/res:cycleName/text())"/>
            </field>
            <field name="atm_concert_description_s">
                <xsl:value-of select="normalize-space($SCORES/res:result[1]/res:concertDesc/text())"/>
            </field>
        
            <!-- FIXME:  The date should be in MODS (and or somewhere else (DC?), and obtained from there), so the original XML need not be stored...
                Also, the whole "concat(..., 'Z')" seems a little flimsy-->
            <xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
            <field name="atm_concert_date_dt">
                <xsl:value-of select="$date"/>
            </field>
            <field name="atm_concert_year_s">
                <xsl:value-of select="substring($date, 1, 4)"/>
            </field>
            <field name="atm_facet_year_s">
                <xsl:value-of select="substring($date, 1, 4)"/>
            </field>
                        
            <xsl:variable name="LECT_TF">
                <xsl:call-template name="perform_query">
                    <xsl:with-param name="query" select="concat('
                      select $lecture from &lt;#ri&gt;
                      where $lecture &lt;fedora-rels-ext:isMemberOf&gt; &lt;fedora:', $pid, '&gt;
                      and $lecture &lt;fedora-rels-ext:hasModel&gt; &lt;fedora:atm:lectureCModel&gt;
                      and $lecture &lt;fedora-model:state&gt; &lt;fedora-model:Active&gt;
                      ;
                      ')"/>
                </xsl:call-template>
            </xsl:variable>
                        
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
                        
            <field name="atm_concert_lecture_b">
                <xsl:choose>
                    <xsl:when test="count(xalan:nodeset($LECT_TF)/res:sparql/res:results/res:result) &gt; 0">true</xsl:when>
                    <xsl:otherwise>false</xsl:otherwise>
                </xsl:choose>
            </field>
            
            <field name="atm_concert_program_titn_s">
                <xsl:value-of select="normalize-space($C_CUSTOM/Concierto/programa/titn_programa/text())"/>
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
                    SELECT $concert $score $scoreName $scoreTitn $composerName $composer $cycleName $concertName $order $scoreTitn
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

        <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                $HOST, ':', $PORT, '/fedora/objects/', substring-after($SCORES/res:concert/@uri, '/'), '/datastreams/CustomXML/content'))"/>
        <xsl:if test="$SCORES">            
            <doc>
                <field name="PID">
                    <xsl:value-of select="$pid"/>
                </field>
                
                <field name="atm_type_s">Obras</field>
                
                <xsl:call-template name="rels_ext">
                    <xsl:with-param name="pid" select="$pid"/>
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
                <xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
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
                        select $name $cOrder $pOrder from &lt;#ri&gt;
                        where $movement &lt;mulgara:is&gt; &lt;fedora:', $pid, '&gt;
                        and $movement &lt;dc:title&gt; $name
                        and $movement &lt;fedora-rels-ext:isMemberOf&gt; $performance
                        and $performance &lt;', $NAMESPACE, 'concertOrder&gt; $cOrder
                        and $movement &lt;', $NAMESPACE, 'pieceOrder&gt; $pOrder
                    ')"/>
                </xsl:call-template>
            </xsl:variable>
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
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
            
            <field name="atm_type_s">Partituras</field>
            
            <field name="atm_score_composer_s">
                <xsl:value-of select="normalize-space($SCORE_RESULT/res:composerName/text())"/>
            </field>
            <field name="atm_facet_composer_s">
                <xsl:value-of select="normalize-space($SCORE_RESULT/res:composerName/text())"/>
            </field>
            <field name="atm_score_composer_pid_s">
                <xsl:value-of select="substring-after($SCORE_RESULT/res:composer/@uri, '/')"/>
            </field>
            <field name="atm_score_title_s">
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
                        SELECT $concert $concertTitle $concertCycle $authorName $programTitn $pieceName
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
            
            <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($CONCERT_INFO/res:result[1]/res:concert/@uri, '/'), '/datastreams/CustomXML/content'))"/>
            <xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
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
                        SELECT $lectureTitle $concertTitle $concertCycle $concert
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
            <xsl:variable name="C_CUSTOM" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', substring-after($LECT/res:result[1]/res:concert/@uri, '/'), '/datastreams/CustomXML/content'))"/>
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
                <xsl:variable name="date" select="normalize-space(concat($C_CUSTOM/Concierto/FECHA/text(), 'Z'))"/>
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
                    SELECT $performance $concert $concertName $concertCycle $composer
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
            
            <xsl:call-template name="eac_cpf">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>
            
            <xsl:call-template name="rels_ext">
                <xsl:with-param name="pid" select="$pid"/>
            </xsl:call-template>

            <xsl:call-template name="digital_objects">
                <xsl:with-param name="objectType">composer</xsl:with-param>
                <xsl:with-param name="person" select="$pid"/>
            </xsl:call-template>
        </doc>
        
        <!-- Get a list of the concerts in which this person has played -->
        <xsl:variable name="PERFORMER_CONCERT_TF">
            <xsl:call-template name="perform_query">
                <xsl:with-param name="query" select="concat('
                    PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                    PREFIX fedora: &lt;info:fedora/&gt;
                    PREFIX atm: &lt;fedora:atm:&gt;
                    PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                    PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                    PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                    SELECT $concert $concertName $concertCycle $performer
                    FROM &lt;#ri&gt;
                    WHERE {
                        $performerObj atm-rel:player $performer ;
                                      atm-rel:performance $performance .
                        $performance fedora-rels-ext:isMemberOf $concert ;
                                     fedora-model:state fedora-model:Active .
                        $concert fedora-rels-ext:isMemberOf $cycle ;
                                 fedora-model:state fedora-model:Active ;
                                 dc:title $concertName .
                        $cycle dc:title $concertCycle .
                        FILTER(sameterm($performer, &lt;info:fedora/', $pid, '&gt;)) 
                    }
                ')"/>
                <xsl:with-param name="lang">sparql</xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
        
        <xsl:for-each select="xalan:nodeset($PERFORMER_CONCERT_TF)/res:sparql/res:results/res:result">
            <doc>
                <field name="atm_type_ms">Intérpretes</field>
                <field name="PID">
                    <xsl:value-of select="concat($pid, ':', substring-after(res:concert/@uri, '/'))"/>
                </field>
                <field name="atm_facet_concert_title_s"><xsl:value-of select="res:concertName/text()"/></field>
                <field name="atm_facet_concert_cycle_s"><xsl:value-of select="res:concertCycle/text()"/></field>
                <field name="atm_performer_concert_pid_s"><xsl:value-of select="substring-after(res:concert/@uri, '/')"/></field>
                
                <xsl:variable name="date" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                $HOST, ':', $PORT, '/fedora/objects/', substring-after(res:concert/@uri, '/'), '/datastreams/CustomXML/content'))/Concierto/FECHA/text()"/>
                <xsl:if test="$date">
                    <!-- FIXME (minor): Really, this should be done through the use of date faceting in solr, based on the _dt above (an actual date/time value)...  Same for other instances of similar code (grabbing the year from the date) -->
                    <field name="atm_person_year_s">
                        <xsl:value-of select="substring($date, 1, 4)"/>
                    </field>
                    <field name="atm_facet_year_s">
                        <xsl:value-of select="substring($date, 1, 4)"/>
                    </field>
                </xsl:if>
                
                <xsl:call-template name="eac_cpf">
                  <xsl:with-param name="pid" select="$pid"/>
                </xsl:call-template>
                
                <!-- Get a list of the concerts in which this person has played -->
                <xsl:variable name="PERFORMER_GROUP_TF">
                    <xsl:call-template name="perform_query">
                        <xsl:with-param name="query" select="concat('
                            PREFIX atm-rel: &lt;', $NAMESPACE, '&gt;
                            PREFIX fedora: &lt;info:fedora/&gt;
                            PREFIX atm: &lt;fedora:atm:&gt;
                            PREFIX fedora-rels-ext: &lt;info:fedora/fedora-system:def/relations-external#&gt;
                            PREFIX fedora-model: &lt;info:fedora/fedora-system:def/model#&gt;
                            PREFIX dc: &lt;http://purl.org/dc/elements/1.1/&gt;
                            SELECT $piece $groupName $instrumentName
                            FROM &lt;#ri&gt;
                            WHERE {
                                $performerObj atm-rel:player $performer ;
                                              atm-rel:performance $performance ;
                                              atm-rel:group $group ;
                                              atm-rel:instrument $instrument .
                                $instrument dc:title $instrumentName .
                                $group dc:title $groupName .
                                $performance fedora-rels-ext:isMemberOf $concert ;
                                             fedora-model:state fedora-model:Active ;
                                             atm-rel:basedOn $score .
                                $score dc:title $piece .
                                $concert fedora-model:state fedora-model:Active .
                                FILTER(sameterm($performer, &lt;info:fedora/', $pid, '&gt;) &amp;&amp; sameterm($concert, &lt;', res:concert/@uri, '&gt;)) 
                            }
                        ')"/>
                        <xsl:with-param name="lang">sparql</xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
                <!-- All the pieces -->
                <xsl:for-each select="set:distinct(xalan:nodeset($PERFORMER_GROUP_TF)/res:sparql/res:results/res:result/res:piece)">
                    <field name="atm_facet_piece_ms">
                        <xsl:value-of select="text()"/>
                    </field>
                </xsl:for-each>
                <!-- All the groups -->
                <xsl:for-each select="set:distinct(xalan:nodeset($PERFORMER_GROUP_TF)/res:sparql/res:results/res:result/res:groupName)">
                    <field name="atm_facet_group_ms">
                        <xsl:value-of select="text()"/>
                    </field>
                </xsl:for-each>
                <!-- All the instruments -->
                <xsl:for-each select="set:distinct(xalan:nodeset($PERFORMER_GROUP_TF)/res:sparql/res:results/res:result/res:instrumentName)">
                    <field name="atm_facet_instrument_ms">
                        <xsl:value-of select="text()"/>
                    </field>
                </xsl:for-each>
            </doc>
        </xsl:for-each>
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
                        SELECT $concert $performerObj $person $personName $instrumentName $instrumentClassName $groupName $concertTitle $cycleName $pieceName $concertOrder
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
                <xsl:variable name="date" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
                $HOST, ':', $PORT, '/fedora/objects/', substring-after(res:concert/@uri, '/'), '/datastreams/CustomXML/content'))/Concierto/FECHA/text()"/>
                <xsl:if test="$date">
                    <field name="atm_performer_date_dt">
                        <xsl:value-of select="concat($date, 'Z')"/>
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
                <xsl:call-template name="eac_cpf">
                    <xsl:with-param name="pid" select="substring-after(res:person/@uri, '/')"/>
                </xsl:call-template>
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
    
    <xsl:template name="eac_cpf">
        <xsl:param name="pid"/>
        <xsl:param name="dsid" select="'EAC-CPF'"/>
        <xsl:param name="prefix" select="'eaccpf_'"/>
        <xsl:param name="suffix" select="'_es'"/> <!-- 'edged' (edge n-gram) string (copied to *_et text)
            NOTE: As of writing this 2011/10/03 (about noon), *_es is single-valued, to allow sorting...  This'll
            explode if there are multiple values for a single field, though... Might be a good idea to select based on 
            distinct localTypes, and effectively merge them into a single field?-->

        <xsl:variable name="EAC_CPF" select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@',
            $HOST, ':', $PORT, '/fedora/objects/', $pid, '/datastreams/', $dsid, '/content'))"/>
        
        <xsl:variable name="cpfDesc" select="$EAC_CPF/eac-cpf/cpfDescription"/>
        <xsl:variable name="nameEntry" select="$cpfDesc/identity/nameEntry[@localType='primary']"/>
        
        <xsl:for-each select="$nameEntry/part[@localType]">
            <field>
                <xsl:attribute name="name">
                    <xsl:value-of select="concat($prefix, 'name_', @localType, $suffix)"/>
                </xsl:attribute>
                <xsl:value-of select="text()"/>
            </field>
        </xsl:for-each>
        
        <xsl:for-each select="$cpfDesc/description//place[@localType='primary']/address/addressLine[@localType]">
            <field>
                <xsl:attribute name="name">
                    <xsl:value-of select="concat($prefix, 'address_', @localType, $suffix)"/>
                </xsl:attribute>
                <xsl:value-of select="text()"/>
            </field>
        </xsl:for-each>
        
        <field>
            <xsl:attribute name="name">
                <xsl:value-of select="concat($prefix, 'complete', $suffix)"/>
            </xsl:attribute>
            <xsl:value-of select="normalize-space(concat($nameEntry/part[@localType='surname']/text(), ', ', $nameEntry/part[@localType='forename']/text()))"/>
        </field>
    </xsl:template>
    
    <xsl:template name="perform_query">
        <xsl:param name="query" select="no_query"/>
        <xsl:param name="lang" select="'itql'"/>
        <xsl:param name="additional_params" select="''"/>
        
        <xsl:variable name="encoded_query">
            <xsl:call-template name="url-encode">
                <xsl:with-param name="str" select="normalize-space($query)"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:for-each select="document(concat($RISEARCH, $encoded_query, '&amp;lang=', $lang,  $additional_params))">
            <?xalan-doc-cache-off?>
            <xsl:copy-of select="*"/>
        </xsl:for-each>
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
