#!/usr/bin/env burl

# Configure and start Nginx
SET NGX_CONF_HTTP <<EOF
upstream test_backend {
    server $(dig +short nghttp2.org):443;

    keepalive 320;
    keepalive_requests 1000;
    keepalive_timeout 60s;
}
EOF

SET NGX_CONF <<'EOF'
location / {
    add_header Alt-Svc 'h3=":443"; ma=86400';
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host "nghttp2.org";
    proxy_pass https://test_backend;
}
EOF

START_NGX



TEST 1: POST JSON

# send request
jo -p foo=bar abc=17 parser=false | REQ /httpbin/anything -X POST --json @-

# validate the response headers
HEADER -x "HTTP/1.1 200 OK"

# validate the response body, e.g. JSON body
JQ '.json=={"foo":"bar","abc":17,"parser":false}'



TEST 2: PUT JSON

# send request
jo -p foo=bar abc=17 parser=false | REQ /httpbin/anything -X PUT --json @-

# validate the response headers
HEADER -x "HTTP/1.1 200 OK"

# validate the response body, e.g. JSON body
JQ '.method=="PUT"'
JQ '.json=={"foo":"bar","abc":17,"parser":false}'



TEST 3: POST FORM

# send request
REQ /httpbin/anything  -d foo=bar -d hello=world

# validate the response headers
HEADER -x "HTTP/1.1 200 OK"

# validate the response body, e.g. JSON body
JQ '.method=="POST"'
JQ '.form=={"foo":"bar","hello":"world"}'



TEST 4: DELETE

# send request
REQ /httpbin/anything -X DELETE

# validate the response headers
HEADER -x "HTTP/1.1 200 OK"

# validate the response body, e.g. JSON body
JQ '.method=="DELETE"'



TEST 5: POST files

file1=$(mktemp)
echo -n hello > $file1

file2=$(mktemp)
echo -n world > $file2

GC "rm -f $file1 $file2"

# send request
REQ /httpbin/anything -F file1=@${file1} -F file2=@${file2}

# validate the response headers
HEADER -x "HTTP/1.1 200 OK"

# validate the response body, e.g. JSON body
JQ '.files.file1=="hello"'
JQ '.files.file2=="world"'
JQ '.headers["Content-Type"] | test("multipart/form-data; boundary=.*")'
