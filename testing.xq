xquery version "3.1";

  (:declare boundary-space preserve;:)
(:  LIBRARIES  :)
  import module namespace xpol="http://amclark42.net/ns/xpollinator"
    at "xpollinator.xql";
(:  NAMESPACES  :)
  (:declare default element namespace "http://www.wwp.northeastern.edu/ns/textbase";:)
  declare namespace array="http://www.w3.org/2005/xpath-functions/array";
  (:declare namespace map="http://www.w3.org/2005/xpath-functions/map";:)
  declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
  declare namespace tei="http://www.tei-c.org/ns/1.0";
  declare namespace wwp="http://www.wwp.northeastern.edu/ns/textbase";
(:  OPTIONS  :)
  declare option output:method "json";

(:~
  Testing xPollinator library.
  
  @author Ashley M. Clark, Northeastern University Women Writers Project
  2020
 :)
 
(:  VARIABLES  :)
  

(:  FUNCTIONS  :)
  

(:  MAIN QUERY  :)

let $xsl := "file:/home/ashley/Documents/Xplorator/resources/xsl/xmlViewer.xsl"
let $doc := "file:/home/ashley/Documents/Xplorator/resources/xml/whyXPath.xml"
let $xslText := 
  '<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:wwp="http://www.wwp.northeastern.edu/ns/textbase"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns=""
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="tei wwp xs"
    version="2.0">
    
  </xsl:stylesheet>'
let $transformMap := map {
    'stylesheet-text': $xslText,
    'source-node': doc($doc)
  }
return
  (:xpol:get-transform-stylesheet($transformMap):)
  (:transform($transformMap):)
  xpol:transform($transformMap)
