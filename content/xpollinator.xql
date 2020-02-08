xquery version "3.1";

  module namespace xpol="http://amclark42.net/ns/xpollinator";
(:  LIBRARIES  :)
(:  NAMESPACES  :)
  declare namespace array="http://www.w3.org/2005/xpath-functions/array";
  declare namespace http="http://expath.org/ns/http-client";
(:  declare namespace map="http://www.w3.org/2005/xpath-functions/map";:)
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  (:declare namespace request="http://exquery.org/ns/request";:)
  declare namespace rest="http://exquery.org/ns/restxq";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";

(:~
  xPollinator
  
  @author Ashley M. Clark, Northeastern University Women Writers Project
  2020
 :)
 
(:  VARIABLES  :)
  

(:  FUNCTIONS  :) 
(: QName('URI', 'pre:FN') :)

  declare function xpol:keys($map as map(*)) {
    let $standard :=
      function-lookup(QName('http://www.w3.org/2005/xpath-functions/map', 'keys'), 1)
    return
      if ( exists($standard) ) then
        $standard($map)
      else () (: TODO :)
  };
  
  (: W3C spec, Saxon PE/EE :)
  declare function xpol:transform($options as map(*)) {
    let $standard := function-lookup(xs:QName('fn:transform'), 1)
    return
      if ( exists($standard) ) then
        $standard($options)
      else
        let $input := $options?('source-node')
        let $xsl := xpol:get-transform-stylesheet($options)
        let $xslParams := $options?('stylesheet-params')
        let $arity := 
          if ( not(exists($xslParams)) ) then 2 else 3
        let $fallbackMap := map {
            QName('http://exist-db.org/xquery/transform', 'transform:transform'): map {
                'arity': $arity
              },
            QName('http://basex.org/modules/xslt', 'xslt:transform'): map {
                'arity': $arity
              }
          }
        let $transform := xpol:get-fallback($fallbackMap)
        let $implementation :=
          $fallbackMap?(function-name($transform))
        let $result :=
          if ( $arity eq 2 ) then
            $transform($input, $xsl)
          else
            $transform($input, $xsl, $xslParams)
        return map {
            'output': $result
          }
  };
  (: eXist, BaseX arity 3 :)
  (:declare function xpol:transform($input, $stylesheet, $parameters) {
  };:)


(:  SUPPORT FUNCTIONS  :)
  
  declare %private function xpol:get-fallback($fallback-map as map(*)) {
    let $functions :=
      for $qName in xpol:keys($fallback-map)
      let $implMap := $fallback-map?($qName)
      let $arity := $implMap?('arity')
      return function-lookup($qName, $arity)
    return
      if ( count($functions) gt 0 ) then
        $functions[1]
      else error(xs:QName('err:XPST0017'))
  };
  
  declare %private function xpol:get-transform-stylesheet($xsl-options as map(*)) as item() {
    let $node := $xsl-options?('stylesheet-node')
    let $uri := $xsl-options?('stylesheet-location')
    let $unparsed := $xsl-options?('stylesheet-text')
    let $badParamErr := xs:QName('err:FOXT0002')
    return
      if ( count(($node, $uri, $unparsed)) ne 1 ) then
        error($badParamErr, "The transformation map must contain one of 'stylesheet-node', 'stylesheet-location', or 'stylesheet-text'.")
      else if ( exists($unparsed) ) then
        let $xsl :=
          try { parse-xml($unparsed) } catch * { () }
        return
          if ( $unparsed eq '' or empty($xsl) ) then
            error($badParamErr, "The stylesheet given in the transformation map is not XML.")
          else $xsl
      else
        ($node, $uri)[1]
  };
