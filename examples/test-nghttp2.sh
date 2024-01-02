#!/usr/bin/env burl

TEST_HOST=nghttp2.org



TEST 1: simple GET

# send request
REQ /httpbin/get --http3-only

# validate the response headers
HEADER -x "HTTP/3 200"

# validate the response body
BODY '"Host": "nghttp2.org",'
JQ '.headers["Host"] == "nghttp2.org"'



TEST 2: GET XML

# send request
REQ /httpbin/xml

# validate the response headers
HEADER -x "HTTP/1.1 200 OK"
HEADER -x "Content-Type: application/xml"

# validate the response XML body
XML '.slideshow["@author"]=="Yours Truly"'
