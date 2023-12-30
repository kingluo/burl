#!/usr/bin/env burl

# configure apisix
TEST_PORT=9443

ADMIN put /ssls/1 -d '{
    "cert": "'"$(<${BURL_ROOT}/examples/certs/server.crt)"'",
    "key": "'"$(<${BURL_ROOT}/examples/certs/server.key)"'",
    "snis": [
        "localhost"
    ]
}'

ADMIN put /routes/1 -s -d '{
    "uri": "/httpbin/*",
    "upstream": {
        "scheme": "https",
        "type": "roundrobin",
        "nodes": {
            "nghttp2.org": 1
        }
    }
}'



TEST 1: POST JSON

# send request
jo -p foo=bar abc=17 parser=false | REQ /httpbin/anything -X POST --json @- --http3-only

# validate the response headers
HEADER -x "HTTP/3 200"

# validate the response body, e.g. JSON body
JQ '.json=={"foo":"bar","abc":17,"parser":false}'



TEST 2: PUT JSON

# send request
jo -p foo=bar abc=17 parser=false | REQ /httpbin/anything -X PUT --json @- --http3-only

# validate the response headers
HEADER -x "HTTP/3 200"

# validate the response body, e.g. JSON body
JQ '.method=="PUT"'
JQ '.json=={"foo":"bar","abc":17,"parser":false}'



TEST 3: POST FORM

# send request
REQ /httpbin/anything --http3 -d foo=bar -d hello=world

# validate the response headers
HEADER -x "HTTP/3 200"

# validate the response body, e.g. JSON body
JQ '.method=="POST"'
JQ '.form=={"foo":"bar","hello":"world"}'



TEST 4: DELETE

# send request
REQ /httpbin/anything -X DELETE --http3

# validate the response headers
HEADER -x "HTTP/3 200"

# validate the response body, e.g. JSON body
JQ '.method=="DELETE"'



TEST 5: POST files

file1=$(mktemp)
echo -n hello > $file1

file2=$(mktemp)
echo -n world > $file2

GC "rm -f $file1 $file2"

# send request
REQ /httpbin/anything --http3 -F file1=@${file1} -F file2=@${file2}

# validate the response headers
HEADER -x "HTTP/3 200"

# validate the response body, e.g. JSON body
JQ '.files.file1=="hello"'
JQ '.files.file2=="world"'
JQ '.headers["Content-Type"] | test("multipart/form-data; boundary=.*")'
