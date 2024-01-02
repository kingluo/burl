# burl: bash + curl

A simple but flexible HTTP/3 testing framework based on bash and curl.

## Design

1. The test file contains one or more test cases, and an optional initial part of the file header, such as configuring nginx.conf and starting nginx via template rendering.
2. Each test case consists of three parts:
    1. Construct and send the request, and save the response header and response body to files for subsequent steps.
    2. Verify the response headers, for example using "grep".
    3. Parse and validate the response body, for example with the "jq" expression.
3. **Easily extensible**, you can validate responses (steps ii and iii) using any command or other advanced script, such as Python.
4. **Failure of any command will stop the testing process (enabled via the "set -euo pipefail" bash option).**
5. The test process is echoed by default (enabled via the "set -x" bash option).

## Installation

## Usage

Use shebang (`#!`) or run the burl command:

```
# specify the test files or dirs
# for dir, burl will find the test files recursively under the dir
burl <test-file1> <test-file2> <dir1> <dir2> ...

# run burl directly, it will try to find test files in ./t
burl
```

Test case template:

```bash
#!/usr/bin/env burl

# Optional initialization here...
# Before all test cases are executed.
# For example, render nginx.conf and start nginx.
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

TEST 1: test case

# Send request
# REQ is a curl wrapper so you can apply any curl options to suit your needs.
# Check https://curl.se/docs/manpage.html for details.
REQ /httpbin/anything --http3 -d foo=bar -d hello=world

# Validate the response headers
# HEADER is a grep wrapper so you can apply any grep options and regular expressions to suit your needs.
HEADER -x "HTTP/3 200"

# Validate the response body, e.g. JSON body
# JQ is a jq wrapper so you can apply any jq options and jq expression to suit your needs.
JQ '.method=="POST"'
JQ '.form=={"foo":"bar","hello":"world"}'

TEST 2: another test case
# ...

# More test cases...
```

## Examples

### APISIX

1. Test MTLS whitelist

```bash
TEST 2: route-level mtls, skip mtls

ADMIN put /ssls/1 -d '{
    "cert": "'"$(<${BURL_ROOT}/examples/certs/server.crt)"'",
    "key": "'"$(<${BURL_ROOT}/examples/certs/server.key)"'",
    "snis": [
        "localhost"
    ],
    "client": {
        "ca": "'"$(<${BURL_ROOT}/examples/certs/ca.crt)"'",
        "depth": 10,
        "skip_mtls_uri_regex": [
            "/httpbin/get"
        ]
    }
}'

sleep 1

REQ /httpbin/get --http3-only

# validate the response headers
HEADER -x "HTTP/3 200"

# validate the response body, e.g. JSON body
JQ '.headers["X-Forwarded-Host"] == "localhost"'
```

2. Test HTTP/3 Alt-Svc

```bash
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



TEST 1: check if alt-svc works

altsvc_cache=$(mktemp)
GC "rm -f ${altsvc_cache}"

REQ /httpbin/get -k --alt-svc ${altsvc_cache}
HEADER -x "HTTP/1.1 200 OK"

REQ /httpbin/get -k --alt-svc ${altsvc_cache}
HEADER -x "HTTP/3 200"

```

### SOAP

Send a SOAP request to the web service and verify the response.

Construct JSON input using `jo` and validate JSON output using `jq` expressions.

Powered by Python [zeep](https://docs.python-zeep.org/en/master/).

```bash
TEST 1: test a simple Web Service: Add two numbers: 1+2==3

SOAP_REQ \
    'https://ecs.syr.edu/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx?WSDL' \
    Add `jo a=1 b=2` '.==3'

```

### XML

Powered by [xmltodict](https://pypi.org/project/xmltodict/).

```bash
TEST 2: GET XML

# send request
REQ /httpbin/xml

# validate the response headers
HEADER -x "HTTP/1.1 200 OK"
HEADER -x "Content-Type: application/xml"

# validate the response XML body
XML '.slideshow["@author"]=="Yours Truly"'

```

## Common Functions

### REQ()

The curl wrapper function works similarly to the curl command, except that it saves the response headers and body into two temporary files for later use.
You can apply any [curl options](https://curl.se/docs/manpage.html) to it.

### HEADER()

grep wrapper to validate current response headers (`${CURL_RSP_HEADERS}`).

### BODY()

grep wrapper to validate current response headers (`${CURL_RSP_BODY}`).

### JQ()

[jq](https://jqlang.github.io/jq/) wrapper to validate current response headers (`${CURL_RSP_BODY}`).

### GC()

Put a code snippet or function into the global gc list so that it is executed at the end of the current test file execution, for example to clean up temporary files.

You can execute GC() multiple times to add multiple code snippets or functions.

```bash
# code snippet
GC "rm -f ${my_temp_files}"

# customized gc function
GC my_gc_func
```

### START_NGX()

Render the nginx.conf and start nginx. Assume you set the conf related variables.

### ADMIN()

Configure APISIX via admin API, which is simple curl wrapper, so you can apply any curl options to it.

### XML()

Parse and validate the XML response body (`${CURL_RSP_BODY}`).

### SOAP()

Execute SOAP operation on remote web service and validate the output via jq expression.

### SET()

Assign here-doc text to variable.

```bash
SET NGX_CONF <<'EOF'
location / {
    add_header Alt-Svc 'h3=":443"; ma=86400';
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host "nghttp2.org";
    proxy_pass https://test_backend;
}
EOF
```

### TEST()

echo the test case title.

## Global Variables

### BURL_ROOT

The root path of burl installation, i.e `/usr/local/burl`

### TEST_HOST

curl host, only set when you need to test the origin server directly.

default value: `localhost`.

### TEST_PORT

curl port, only set when you need to test the origin server directly.

default value: `443`.

### TEST_SCHEME

curl scehme, only set when you need to test the origin server directly.

default value: `https`.

### CURL_RSP_HEADERS

the file that contains the current response headers content, which will be changed after next `REQ()`.

### CURL_RSP_BODY

the file that contains the current response headers body content, which will be changed after next `REQ()`.

### NGX_CONF_MAIN

nginx main configuration directives, used by `START_NGX()`.

### NGX_CONF_HTTP

nginx http configuration directives, used by `START_NGX()`.

### NGX_CONF

nginx location configuration directives of the default server (80 and 443, including HTTP/3), used by `START_NGX()`.
