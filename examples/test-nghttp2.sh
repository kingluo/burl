#!/usr/bin/env burl

TEST_HOST=nghttp2.org



TEST 1: simple GET

REQ /httpbin/get --http3-only

HEADER "HTTP/3 200"
BODY '"Host": "nghttp2.org",'
JQ '.headers["Host"] == "nghttp2.org"'
