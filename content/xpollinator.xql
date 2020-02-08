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
  
  @author Ashley M. Clark
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
    let $standardName := xs:QName('fn:transform')
    let $standardFunction := function-lookup($standardName, 1)
    return
      if ( exists($standardFunction) ) then
        $standardFunction($options)
      else
        let $hasParams := exists($options?('stylesheet-params'))
        let $fallbackMap := map {
            QName('http://exist-db.org/xquery/transform', 'transform'): map {
                'arity': 3,
                'xwalk': function($f, $opt-map) {
                    let $src := $options?('source-node')
                    let $input :=
                      if ( empty($src) or not($src instance of node()) ) then
                        error(xs:QName('err:FOXT0002'), 
                          "The transformation map should include a document in 'source-node'.")
                      else $src
                    let $xsl := xpol:get-transform-stylesheet($options)
                    let $paramMap := $options?('stylesheet-params')
                    let $xslParams :=
                      let $keys :=
                        if ( $paramMap instance of map(*) ) then
                          xpol:keys($paramMap)
                        else ()
                      return
                        <parameters>
                        {
                          for $name in $keys
                          return
                            <param name="{$name}" value="{$paramMap?($name)}"/>
                        }
                        </parameters>
                    return
                      $f($input, $xsl, $xslParams)
                  }
              },
            QName('http://basex.org/modules/xslt', 'transform'): map {
                'arity': if ( not($hasParams) ) then 2 else 3,
                'xwalk': function($f, $opt-map) {
                    let $input := $options?('source-node')
                    let $xsl := xpol:get-transform-stylesheet($options)
                    let $xslParams := $options?('stylesheet-params')
                    return
                      if ( not($hasParams) ) then
                        $f($input, $xsl)
                      else
                        $f($input, $xsl, $xslParams)
                  }
              }
          }
        let $transform := xpol:get-fallback($standardName, $fallbackMap)
        let $implementation :=
          $fallbackMap?(function-name($transform))
        let $result :=
          $implementation?('xwalk')($transform, $options)
        return map {
            'output': $result
          }
  };


(:  SUPPORT FUNCTIONS  :)
  
  declare %private function xpol:get-fallback($standard-function as xs:QName, $fallback-map as map(*)) {
    let $functions :=
      for $qName in xpol:keys($fallback-map)
      let $implMap := $fallback-map?($qName)
      let $arity := $implMap?('arity')
      return function-lookup($qName, $arity)
    return
      if ( count($functions) gt 0 ) then
        $functions[1]
      else error(xs:QName('err:XPST0017'), concat("Function '",$standard-function,"' not implemented"))
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
          try { parse-xml($unparsed) } catch * { '' }
        return
          if ( $unparsed eq '' ) then
            error($badParamErr, "The stylesheet given in the transformation map is not XML.")
          else $xsl
      else if ( exists($uri) ) then
        doc($uri)
      else $node
  };
