xquery version "3.1";

  module namespace xpol="http://amclark42.net/ns/xpollinator";
(:  LIBRARIES  :)
(:  NAMESPACES  :)
  (:declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";:)
  declare namespace array="http://www.w3.org/2005/xpath-functions/array";
  declare namespace http="http://expath.org/ns/http-client";
  (:declare namespace map="http://www.w3.org/2005/xpath-functions/map";:)
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
  
  (: W3C spec, Saxon PE/EE :)
  declare function xpol:transform($options as map(*)) {
    let $standard := function-lookup(xs:QName('fn:transform'), 1)
    let $fallbackMap := map {
        QName('http://exist-db.org/xquery/transform', 'transform:transform'): map {
            'arity': ''
          },
        QName('http://http://basex.org/modules/xslt', 'xslt:transform'): map {
            'apply': function($f, $opts as map(*)) {
                let $input := $opts?('source-node')
                let $xsl := xpol:get-transform-stylesheet($opts)
                return
                  $f($input, $xsl)
              }
          }
      }
    return
      if ( exists($standard) ) then
        $standard($options)
      else $standard?('source-node')
  };
  
  (: BaseX arity 2 :)
  (:declare function xpol:transform($input, $stylesheet) {
  };:)
  
  (: eXist, BaseX arity 3 :)
  (:declare function xpol:transform($input, $stylesheet, $parameters) {
  };:)

(:  SUPPORT FUNCTIONS  :)
  
  declare function xpol:get-transform-stylesheet($xsl-options as map(*)) as item() {
    let $node := $xsl-options?('stylesheet-node')
    let $uri := $xsl-options?('stylesheet-location')
    let $unparsed := $xsl-options?('stylesheet-text')
    let $badParamErr := xs:QName('err:FOXT0002')
    return
      if ( count(($node, $uri, $unparsed)) gt 1 ) then
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
